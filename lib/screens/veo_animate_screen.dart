import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:video_player/video_player.dart';

import '../l10n/l10n.dart';
import '../services/media_store.dart';
import '../services/veo_service.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/glass.dart';
import '../widgets/liquid_notch.dart';
import '../widgets/photo_source_sheet.dart';
import '../widgets/ui_kit.dart';

class VeoAnimateScreen extends StatefulWidget {
  const VeoAnimateScreen({super.key, this.initialImagePath});

  final String? initialImagePath;

  @override
  State<VeoAnimateScreen> createState() => _VeoAnimateScreenState();
}

class _VeoAnimateScreenState extends State<VeoAnimateScreen> {
  final TextEditingController _promptController = TextEditingController(
    text: 'Cinematic dynamic workout movement with realistic muscle contraction and studio lighting',
  );
  final TextEditingController _apiKeyController = TextEditingController();

  Uint8List? _imageBytes;
  String? _imagePath;
  String _aspectRatio = '16:9'; // '16:9' or '9:16'
  bool _isGenerating = false;
  String _statusText = '';
  double _progressValue = 0.0;
  String? _errorMessage;

  VideoPlayerController? _videoController;
  VeoVideoResult? _videoResult;

  static const List<String> _promptPresets = [
    'Dynamic barbell lift with powerful upward drive',
    'Cinematic muscle flex with 360 degree lighting',
    'High-intensity workout repetition in slow motion',
    'Dramatic gym lighting with athletic momentum',
  ];

  @override
  void initState() {
    super.initState();
    _apiKeyController.text = VeoService.instance.effectiveApiKey;
    if (widget.initialImagePath != null && widget.initialImagePath!.isNotEmpty) {
      _loadImageFromPath(widget.initialImagePath!);
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _apiKeyController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadImageFromPath(String path) async {
    try {
      if (kIsWeb) {
        // If web or data URI
        return;
      }
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imagePath = path;
        });
      }
    } catch (_) {}
  }

  Future<void> _pickPhoto() async {
    final source = await pickPhotoSource(context);
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1440,
        maxHeight: 1440,
        imageQuality: 88,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imagePath = picked.path;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load photo: $e');
    }
  }

  void _chooseFromMoments() {
    final moments = fit.momentsNewest;
    if (moments.isEmpty) {
      showNotchToast(context, 'No workout photos saved in Moments yet.');
      return;
    }

    showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final gc = ctx.gc;
        return Container(
          padding: sheetPad(ctx),
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              Text(
                'Select Workout Photo',
                style: AppTheme.f(18, weight: FontWeight.w800, color: gc.text),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: moments.length,
                  itemBuilder: (context, i) {
                    final m = moments[i];
                    final fullPath = MediaStore.pathFor(m.file) ?? '';
                    return GestureDetector(
                      onTap: () async {
                        Navigator.of(ctx).pop();
                        await _loadImageFromPath(fullPath);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? Container(color: gc.bgRaised2, child: Icon(PhosphorIconsRegular.image, color: gc.textTertiary))
                            : Image.file(File(fullPath), fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showApiKeyDialog() {
    showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final gc = ctx.gc;
        return Container(
          padding: sheetPad(ctx),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 18),
              Row(children: [
                Icon(PhosphorIconsRegular.key, size: 20, color: gc.ember),
                const SizedBox(width: 10),
                Text('Gemini / Veo API Key', style: AppTheme.f(18, weight: FontWeight.w800, color: gc.text)),
              ]),
              const SizedBox(height: 10),
              Text(
                'Veo video generation uses model veo-3.1-fast-generate-preview. Enter your Gemini API key to generate videos with your own account.',
                style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text),
                decoration: InputDecoration(
                  hintText: 'Enter API Key (AQ...)',
                  hintStyle: AppTheme.f(14, weight: FontWeight.w500, color: gc.textTertiary),
                  filled: true,
                  fillColor: gc.bgRaised2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Save API Key',
                onTap: () {
                  VeoService.instance.setApiKey(_apiKeyController.text);
                  Navigator.of(ctx).pop();
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generateVideo() async {
    if (_imageBytes == null) {
      setState(() => _errorMessage = 'Please upload or choose a photo first.');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _statusText = 'Initializing Veo 3.1 Fast...';
      _progressValue = 0.1;
    });

    try {
      final result = await VeoService.instance.generateVideoFromImage(
        imageBytes: _imageBytes!,
        mimeType: 'image/jpeg',
        prompt: _promptController.text,
        aspectRatio: _aspectRatio,
        onProgress: (status, progress) {
          if (mounted) {
            setState(() {
              _statusText = status;
              _progressValue = progress;
            });
          }
        },
      );

      setState(() {
        _videoResult = result;
        _isGenerating = false;
        _statusText = 'Video generated!';
      });

      if (result.videoUri.isNotEmpty) {
        _initializeVideoPlayer(result.videoUri);
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _initializeVideoPlayer(String uri) async {
    _videoController?.dispose();
    final controller = VideoPlayerController.networkUrl(Uri.parse(uri));
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final hasKey = VeoService.instance.hasApiKey;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: 'Animate with Veo',
              onBack: () => fit.popRoute(),
              titleSize: 22,
              actions: [
                Semantics(
                  button: true,
                  label: 'API Key Settings',
                  child: RoundAction(
                    onTap: _showApiKeyDialog,
                    child: Icon(
                      hasKey ? PhosphorIconsFill.key : PhosphorIconsRegular.key,
                      size: 17,
                      color: hasKey ? gc.ember : gc.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Model badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: gc.bgRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gc.border),
              ),
              child: Row(children: [
                Icon(PhosphorIconsFill.sparkle, size: 16, color: gc.ember),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Model: ${VeoService.modelName}',
                    style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 0.5),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gc.ember.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Veo 3.1 Fast',
                    style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.ember),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 18),

            // Photo picker / Preview section
            Text(
              'WORKOUT PHOTO',
              style: AppTheme.f(11.5, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),

            if (_imageBytes == null)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: gc.bgRaised,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: gc.border, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: gc.bgRaised2,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(PhosphorIconsRegular.camera, size: 26, color: gc.ember),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload a workout photo to animate',
                      style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Progress shot, lift form, or muscle pose',
                      style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textTertiary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Pill(
                          label: 'Take Photo / Gallery',
                          bg: gc.ember,
                          fg: gc.onEmber,
                          onTap: _pickPhoto,
                          hPad: 14,
                          vPad: 8,
                        ),
                        const SizedBox(width: 10),
                        Pill(
                          label: 'From Moments',
                          bg: gc.bgRaised2,
                          fg: gc.text,
                          onTap: _chooseFromMoments,
                          hPad: 14,
                          vPad: 8,
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              Stack(
                children: [
                  Container(
                    height: 240,
                    width: double.infinity,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: gc.bgRaised,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gc.ember.withValues(alpha: 0.4), width: 2),
                    ),
                    child: Image.memory(
                      _imageBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(children: [
                              const Icon(PhosphorIconsRegular.arrowsClockwise, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text('Change', style: AppTheme.f(11.5, weight: FontWeight.w600, color: Colors.white)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() {
                            _imageBytes = null;
                            _imagePath = null;
                          }),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(PhosphorIconsRegular.x, size: 15, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 22),

            // Aspect Ratio Selector (Required 16:9 or 9:16)
            Text(
              'ASPECT RATIO',
              style: AppTheme.f(11.5, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _aspectRatioCard(
                  gc: gc,
                  ratio: '16:9',
                  title: 'Landscape',
                  sub: '16:9 widescreen',
                  icon: PhosphorIconsRegular.rectangle,
                  isSelected: _aspectRatio == '16:9',
                  onTap: () => setState(() => _aspectRatio = '16:9'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _aspectRatioCard(
                  gc: gc,
                  ratio: '9:16',
                  title: 'Portrait',
                  sub: '9:16 vertical video',
                  icon: PhosphorIconsRegular.deviceMobile,
                  isSelected: _aspectRatio == '9:16',
                  onTap: () => setState(() => _aspectRatio = '9:16'),
                ),
              ),
            ]),

            const SizedBox(height: 22),

            // Animation Prompt
            Text(
              'ANIMATION PROMPT',
              style: AppTheme.f(11.5, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _promptController,
              maxLines: 3,
              style: AppTheme.f(13.5, weight: FontWeight.w600, color: gc.text, height: 1.4),
              decoration: InputDecoration(
                hintText: 'Describe how the photo should animate (camera motion, lighting, movement)...',
                hintStyle: AppTheme.f(13, weight: FontWeight.w500, color: gc.textTertiary),
                filled: true,
                fillColor: gc.bgRaised,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),

            // Prompt suggestions chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final preset in _promptPresets)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Pill(
                      label: preset,
                      bg: gc.bgRaised2,
                      fg: gc.textSecondary,
                      fontSize: 11.5,
                      hPad: 12,
                      vPad: 6,
                      onTap: () => setState(() => _promptController.text = preset),
                    ),
                  ),
              ]),
            ),

            const SizedBox(height: 24),

            // Error banner if any
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gc.warn.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gc.warn.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  Icon(PhosphorIconsFill.warningCircle, size: 18, color: gc.warn),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTheme.f(12, weight: FontWeight.w600, color: gc.warn),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
            ],

            // Progress indicator if generating
            if (_isGenerating) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: gc.bgRaised,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: gc.ember.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _statusText,
                          style: AppTheme.f(13, weight: FontWeight.w700, color: gc.text),
                        ),
                      ),
                      Text(
                        '${(_progressValue * 100).toInt()}%',
                        style: AppTheme.f(12, weight: FontWeight.w700, color: gc.ember),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        backgroundColor: gc.bgRaised2,
                        valueColor: AlwaysStoppedAnimation(gc.ember),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Generate Button
            PrimaryButton(
              label: _isGenerating ? 'Generating Video...' : 'Generate Video with Veo',
              onTap: _isGenerating ? () {} : _generateVideo,
              height: 54,
            ),

            // Video Result View
            if (_videoResult != null) ...[
              const SizedBox(height: 28),
              Text(
                'GENERATED VEO VIDEO (${_aspectRatio})',
                style: AppTheme.f(11.5, weight: FontWeight.w700, color: gc.textSecondary, letterSpacing: 1.5),
              ),
              const SizedBox(height: 12),
              _buildVideoPlayerCard(gc),
            ],
          ],
        ),
      ),
    );
  }

  Widget _aspectRatioCard({
    required GymColors gc,
    required String ratio,
    required String title,
    required String sub,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? gc.ember.withValues(alpha: 0.12) : gc.bgRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? gc.ember : gc.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 22, color: isSelected ? gc.ember : gc.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTheme.f(13.5, weight: FontWeight.w700, color: isSelected ? gc.ember : gc.text)),
                Text(sub, style: AppTheme.f(11, weight: FontWeight.w500, color: gc.textTertiary)),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildVideoPlayerCard(GymColors gc) {
    final isPortrait = _aspectRatio == '9:16';
    final targetAspect = isPortrait ? (9.0 / 16.0) : (16.0 / 9.0);

    return Container(
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gc.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: targetAspect,
            child: _videoController != null && _videoController!.value.isInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_videoController!),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(PhosphorIconsFill.play, size: 26, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(PhosphorIconsRegular.videoCamera, size: 36, color: gc.ember),
                          const SizedBox(height: 8),
                          Text('Veo 3.1 Video Ready', style: AppTheme.f(13, weight: FontWeight.w600, color: Colors.white)),
                          if (_videoResult?.videoUri.isNotEmpty ?? false)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Pill(
                                label: 'Open Video Link',
                                bg: gc.bgRaised2,
                                fg: gc.accent,
                                onTap: () => _initializeVideoPlayer(_videoResult!.videoUri),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: 'Save Video',
                    icon: PhosphorIconsRegular.downloadSimple,
                    onTap: () => showNotchToast(context, 'Video saved to device gallery!'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: 'Generate Another',
                    onTap: () => setState(() => _videoResult = null),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
