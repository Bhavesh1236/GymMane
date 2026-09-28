import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class VeoVideoResult {
  const VeoVideoResult({
    required this.videoUri,
    this.videoBytes,
    this.aspectRatio = '16:9',
    this.prompt = '',
    this.isDemo = false,
  });

  final String videoUri;
  final Uint8List? videoBytes;
  final String aspectRatio;
  final String prompt;
  final bool isDemo;
}

class VeoService {
  VeoService._();
  static final VeoService instance = VeoService._();

  static const String modelName = 'veo-3.1-fast-generate-preview';
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  String? _userApiKey;

  void setApiKey(String key) {
    _userApiKey = key.trim();
  }

  String get effectiveApiKey {
    if (_userApiKey != null && _userApiKey!.isNotEmpty) {
      return _userApiKey!;
    }
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.isNotEmpty) return envKey;
    try {
      if (!kIsWeb) {
        final key = Platform.environment['GEMINI_API_KEY'];
        if (key != null && key.isNotEmpty) return key;
      }
    } catch (_) {}
    return '';
  }

  bool get hasApiKey => effectiveApiKey.isNotEmpty;

  /// Generate a video from an image using veo-3.1-fast-generate-preview
  /// [aspectRatio] must be either '16:9' or '9:16'
  Future<VeoVideoResult> generateVideoFromImage({
    required Uint8List imageBytes,
    required String mimeType,
    required String prompt,
    required String aspectRatio,
    void Function(String status, double progress)? onProgress,
  }) async {
    final cleanRatio = aspectRatio == '9:16' ? '9:16' : '16:9';
    final apiKey = effectiveApiKey;

    onProgress?.call('Preparing image and prompt...', 0.15);

    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini API key is missing. Please configure your GEMINI_API_KEY in settings or the prompt dialog to generate videos with Veo 3.1.',
      );
    }

    final base64Image = base64Encode(imageBytes);

    final requestBody = {
      'prompt': prompt.trim().isEmpty
          ? 'Animate this workout photo with realistic dynamic fitness movement and cinematic lighting'
          : prompt.trim(),
      'image': {
        'imageBytes': base64Image,
        'mimeType': mimeType.isEmpty ? 'image/jpeg' : mimeType,
      },
      'config': {
        'aspectRatio': cleanRatio,
        'numberOfVideos': 1,
        'resolution': '720p',
      },
    };

    onProgress?.call('Submitting to Veo 3.1 model ($modelName)...', 0.30);

    final url = Uri.parse('$baseUrl/models/$modelName:generateVideos?key=$apiKey');

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      try {
        final errJson = jsonDecode(response.body);
        final errMsg = errJson['error']?['message'] ?? response.body;
        throw Exception('Veo API Error (${response.statusCode}): $errMsg');
      } catch (e) {
        if (e is Exception && e.toString().contains('Veo API Error')) rethrow;
        throw Exception('Failed to initiate Veo video generation (${response.statusCode}): ${response.body}');
      }
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final operationName = data['name'] as String?;

    if (operationName == null || operationName.isEmpty) {
      throw Exception('Veo API did not return an operation ID: ${response.body}');
    }

    onProgress?.call('Synthesizing video motion with Veo...', 0.45);

    // Poll the Long Running Operation
    final pollUrl = Uri.parse('$baseUrl/$operationName?key=$apiKey');
    var attempts = 0;
    const maxAttempts = 60; // Up to ~3 minutes

    while (attempts < maxAttempts) {
      await Future<void>.delayed(const Duration(seconds: 3));
      attempts++;

      final progressRatio = (0.45 + (attempts / maxAttempts) * 0.45).clamp(0.45, 0.92);
      onProgress?.call('Synthesizing video motion (${attempts * 3}s)...', progressRatio);

      final pollResponse = await http.get(pollUrl).timeout(const Duration(seconds: 25));
      if (pollResponse.statusCode != 200) continue;

      final pollData = jsonDecode(pollResponse.body) as Map<String, dynamic>;
      final done = pollData['done'] as bool? ?? false;

      if (done) {
        if (pollData['error'] != null) {
          final err = pollData['error']['message'] ?? 'Veo video generation failed';
          throw Exception(err.toString());
        }

        final res = pollData['response'] as Map<String, dynamic>?;
        final generatedVideos = res?['generatedVideos'] as List<dynamic>?;
        if (generatedVideos != null && generatedVideos.isNotEmpty) {
          final first = generatedVideos.first as Map<String, dynamic>;
          final videoObj = first['video'] as Map<String, dynamic>?;
          final videoUri = videoObj?['uri'] as String? ?? '';
          final bytesB64 = videoObj?['bytesBase64Encoded'] as String?;

          Uint8List? rawBytes;
          if (bytesB64 != null && bytesB64.isNotEmpty) {
            rawBytes = base64Decode(bytesB64);
          }

          onProgress?.call('Video ready!', 1.0);

          return VeoVideoResult(
            videoUri: videoUri.isNotEmpty ? '$videoUri?key=$apiKey' : '',
            videoBytes: rawBytes,
            aspectRatio: cleanRatio,
            prompt: prompt,
          );
        }
      }
    }

    throw Exception('Veo generation timed out. Please try again with a shorter prompt.');
  }
}
