import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

final Map<String, Path> _svgPathCache = {};
Path svgPath(String d) => _svgPathCache.putIfAbsent(d, () => parseSvgPathData(d));

class IconPath {
  const IconPath(this.d, {this.fill = false, this.strokeWidth = 2});
  final String d;
  final bool fill;
  final double strokeWidth;
}

class SvgPathIcon extends StatelessWidget {
  const SvgPathIcon(
    this.paths, {
    super.key,
    required this.size,
    required this.color,
    this.viewBox = 24,
  });

  final List<IconPath> paths;
  final double size;
  final Color color;
  final double viewBox;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _IconPainter(paths, color, viewBox)),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.paths, this.color, this.viewBox);
  final List<IconPath> paths;
  final Color color;
  final double viewBox;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / viewBox;
    canvas.save();
    canvas.scale(scale);
    for (final p in paths) {
      final path = svgPath(p.d);
      final paint = Paint()..color = color;
      if (p.fill) {
        paint.style = PaintingStyle.fill;
      } else {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = p.strokeWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
      }
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.color != color || old.paths != paths || old.viewBox != viewBox;
}

class Ic {
  Ic._();
  static const flame = [IconPath('M12 2c1 4-3 5-3 9a3 3 0 0 0 6 0c0-1.5-.5-2-1-3 2 1 3 3 3 5a5 5 0 0 1-10 0c0-5 4-6 5-11z', fill: true)];
  static const play = [IconPath('M8.2 6.1v11.8a1.4 1.4 0 0 0 2.1 1.2l9.2-5.9a1.4 1.4 0 0 0 0-2.4l-9.2-5.9a1.4 1.4 0 0 0-2.1 1.2z', fill: true)];
  static const barbell = [IconPath('M6 4v16M18 4v16M2 9h4M18 9h4M2 15h4M18 15h4M6 12h12', strokeWidth: 2)];
  static const barbellThin = [IconPath('M6 7v10M18 7v10M2 12h4M18 12h4M9 9v6M15 9v6', strokeWidth: 1.8)];
  static const wrench = [IconPath('M14.7 6.3a1 1 0 000 1.4l1.6 1.6a1 1 0 001.4 0l3.77-3.77a6 6 0 01-7.94 7.94l-6.91 6.91a2.12 2.12 0 01-3-3l6.91-6.91a6 6 0 017.94-7.94l-3.76 3.77z', strokeWidth: 2)];
  static const checkBold = [IconPath('M4 12l5 5L20 6', strokeWidth: 3)];
  static const close = [IconPath('M6 6l12 12M18 6L6 18', strokeWidth: 2.5)];
  static const closeThin = [IconPath('M6 6l12 12M18 6L6 18', strokeWidth: 3)];
  static const chevronLeft = [IconPath('M15 18l-6-6 6-6', strokeWidth: 2.5)];
  static const chevronRight = [IconPath('M9 18l6-6-6-6', strokeWidth: 2)];
  static const chevronRightBold = [IconPath('M9 18l6-6-6-6', strokeWidth: 2.5)];
  static const search = [IconPath('M11 11m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0', strokeWidth: 2), IconPath('M21 21l-4.35-4.35', strokeWidth: 2)];
  static const star = [IconPath('M12 2l3.09 6.26L22 9.27l-5 4.87L18.18 21 12 17.77 5.82 21 7 14.14l-5-4.87 6.91-1.01z', strokeWidth: 1.8)];
  static const trendUp = [IconPath('M4 16l6-6 4 4 6-8', strokeWidth: 3)];
  static const house = [IconPath('M3 11l9-8 9 8M5 10v10h14V10', strokeWidth: 2)];
  static const bars = [IconPath('M4 20V10M12 20V4M20 20v-7', strokeWidth: 2)];
  static const gear = [
    IconPath('M12 12m-3 0a3 3 0 1 0 6 0a3 3 0 1 0 -6 0', strokeWidth: 2),
    IconPath('M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 11-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 11-2.83-2.83l.06-.06A1.65 1.65 0 004.68 15a1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 112.83-2.83l.06.06A1.65 1.65 0 009 4.6a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09A1.65 1.65 0 0015.4 4.6a1.65 1.65 0 001.82.33l.06-.06a2 2 0 112.83 2.83l-.06.06A1.65 1.65 0 0019.4 9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z', strokeWidth: 2),
  ];
  static const toolCard = [IconPath('M4 4h16v16H4z'), IconPath('M8 9h8M8 13h5')];
  static const layers = [IconPath('M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5', strokeWidth: 2)];
  static const clock = [IconPath('M12 2a10 10 0 100 20 10 10 0 000-20zM12 6v6l4 2', strokeWidth: 2)];
  static const noAds = [IconPath('M4.9 4.9l14.2 14.2M12 2v2M12 20v2M2 12h2M20 12h2', strokeWidth: 2)];
  static const plus = [IconPath('M12 5v14M5 12h14', strokeWidth: 2.5)];

  // --- openGym Hand-Crafted Equipment & Workout Glyph Suite ---
  static const dumbbell = [
    IconPath('M5.9 7.9h3.2v8.2H5.9z', strokeWidth: 1.7),
    IconPath('M14.9 7.9h3.2v8.2h-3.2z', strokeWidth: 1.7),
    IconPath('M9.1 12h5.8M3.6 9.9v4.2M20.4 9.9v4.2', strokeWidth: 1.7),
  ];
  static const kettlebell = [
    IconPath('M9.5 11V9.6a2.5 2.5 0 0 1 5 0V11', strokeWidth: 1.7),
    IconPath('M14.9 11.8c2.2 1.5 3.6 3.9 3.6 6.4a1.6 1.6 0 0 1-1.6 1.6H7.1a1.6 1.6 0 0 1-1.6-1.6c0-2.5 1.4-4.9 3.6-6.4Z', strokeWidth: 1.7),
  ];
  static const plate = [
    IconPath('M12 3.8a8.2 8.2 0 1 0 0 16.4a8.2 8.2 0 1 0 0-16.4z', strokeWidth: 1.7),
    IconPath('M12 9.3a2.7 2.7 0 1 0 0 5.4a2.7 2.7 0 1 0 0-5.4z', strokeWidth: 1.7),
  ];
  static const machine = [
    IconPath('M12 3.6v3.1', strokeWidth: 1.7),
    IconPath('M6.6 6.7h10.8v12.9H6.6z', strokeWidth: 1.7),
    IconPath('M9 10.1h6M9 13.2h6M9 16.3h6', strokeWidth: 1.7),
  ];
  static const figureStrength = [
    IconPath('M12 3.2a2 2 0 1 0 0 4a2 2 0 1 0 0-4z', strokeWidth: 1.7),
    IconPath('M12 8.4v5.6M12 14 9.2 20.5M12 14l2.8 6.5M8 10.6h8M5.4 9.1v3M18.6 9.1v3', strokeWidth: 1.7),
  ];
  static const figureRun = [
    IconPath('M14.2 3a1.9 1.9 0 1 0 0 3.8a1.9 1.9 0 1 0 0-3.8z', strokeWidth: 1.7),
    IconPath('M13.4 9.1 9.6 11.4l1.7 3.3-2.4 5.4M13.4 9.1l3.4 1.5 1.4 3.4M11.3 14.7l4.3.9 1.5 4.5M9.6 11.4 6 10.2', strokeWidth: 1.7),
  ];
  static const arm = [
    IconPath('M7 3.9a1.9 1.9 0 1 0 0 3.8a1.9 1.9 0 1 0 0-3.8z', strokeWidth: 1.7),
    IconPath('M7 8.8v4.6l-1.2 6.2M7 11.4l4.4 1.9M14.5 13.3h1.4', strokeWidth: 1.7),
    IconPath('M12.2 10.8h2.3v5h-2.3z', strokeWidth: 1.7),
    IconPath('M15.9 10.8h2.3v5h-2.3z', strokeWidth: 1.7),
  ];
  static const abs = [
    IconPath('M7.8 4.4h8.4v10.4a4.2 4.2 0 0 1-8.4 0Z', strokeWidth: 1.7),
    IconPath('M12 6.2v9M9 8.9h2.2M12.8 8.9h2.2M9 11.6h2.2M12.8 11.6h2.2M9.3 14.2h1.9M12.9 14.2h1.9', strokeWidth: 1.7),
  ];
  static const legs = [
    IconPath('M8.4 4.2h7.2', strokeWidth: 1.7),
    IconPath('M9.9 4.2v4.9l-1.3 4.4.9 6.3M14.1 4.2v4.9l1.3 4.4-.9 6.3', strokeWidth: 1.7),
    IconPath('M7.7 19.8h2.6M13.7 19.8h2.6', strokeWidth: 1.7),
  ];
  static const pullup = [
    IconPath('M3.6 5.1h16.8M8.5 5.5v2.3M15.5 5.5v2.3', strokeWidth: 1.7),
    IconPath('M12 7.8a1.8 1.8 0 1 0 0 3.6a1.8 1.8 0 1 0 0-3.6z', strokeWidth: 1.7),
    IconPath('m8.5 7.8 3.5 5 3.5-5M12 13.3v3.9M12 17.2l-2.1 3.2M12 17.2l2.1 3.2', strokeWidth: 1.7),
  ];
  static const boxing = [
    IconPath('M7.6 8.6A4.6 4.6 0 0 1 12.2 4h1.6a5.4 5.4 0 0 1 5.4 5.4v2.4a3 3 0 0 1-3 3H7.6Z', strokeWidth: 1.7),
    IconPath('M7.6 14.8v2.3a2.6 2.6 0 0 0 2.6 2.6h5.2a2.6 2.6 0 0 0 2.6-2.6v-2.3', strokeWidth: 1.7),
    IconPath('M7.6 9.8H6.3a1.8 1.8 0 0 0 0 3.6h1.3', strokeWidth: 1.7),
  ];
  static const bike = [
    IconPath('M6.2 12.7a3.5 3.5 0 1 0 0 7a3.5 3.5 0 1 0 0-7z', strokeWidth: 1.7),
    IconPath('M17.8 12.7a3.5 3.5 0 1 0 0 7a3.5 3.5 0 1 0 0-7z', strokeWidth: 1.7),
    IconPath('m6.2 16.2 4.3-7.4h4.9l2.4 7.4M9.3 8.8h4.5M13.8 8.8l-2.6 7.4', strokeWidth: 1.7),
  ];
  static const swim = [
    IconPath('M8.8 6.4a1.8 1.8 0 1 0 0 3.6a1.8 1.8 0 1 0 0-3.6z', strokeWidth: 1.7),
    IconPath('m10.9 10 4.6-2.2 3.3 3.4', strokeWidth: 1.7),
    IconPath('M3.5 15.6c1.6-1.3 3.1-1.3 4.7 0s3.1 1.3 4.7 0 3.1-1.3 4.7 0c.9.7 1.7.9 2.6.5', strokeWidth: 1.7),
  ];
  static const stretch = [
    IconPath('M14.4 3.5a1.9 1.9 0 1 0 0 3.8a1.9 1.9 0 1 0 0-3.8z', strokeWidth: 1.7),
    IconPath('M14.4 8.2c-3 1.4-5 4-5.8 7.4M8.6 15.6 6.2 20M8.6 15.6l4.6 4.4M12.6 9.6 18 12', strokeWidth: 1.7),
  ];
  static const scale = [
    IconPath('M3.4 4.4h17.2v16.2H3.4z', strokeWidth: 1.7),
    IconPath('M8.3 9.2a3.9 3.9 0 0 1 7.4 0M12 9.2v2.5M8.9 16.2h6.2', strokeWidth: 1.7),
  ];
  static const trophy = [
    IconPath('M7.6 4h8.8v4.6a4.4 4.4 0 0 1-8.8 0Z', strokeWidth: 1.7),
    IconPath('M7.6 5.6H4.9v1.5a3 3 0 0 0 2.9 3M16.4 5.6h2.7v1.5a3 3 0 0 1-2.9 3M12 13v3.4M8.6 20.4h6.8l-.7-4H9.3Z', strokeWidth: 1.7),
  ];
  static const medal = [
    IconPath('M12 9.6a5.2 5.2 0 1 0 0 10.4a5.2 5.2 0 1 0 0-10.4z', strokeWidth: 1.7),
    IconPath('M12 12.9a1.9 1.9 0 1 0 0 3.8a1.9 1.9 0 1 0 0-3.8z', strokeWidth: 1.7),
    IconPath('M9.1 9.9 6.4 3.6M14.9 9.9l2.7-6.3', strokeWidth: 1.7),
  ];
  static const target = [
    IconPath('M12 3.8a8.2 8.2 0 1 0 0 16.4a8.2 8.2 0 1 0 0-16.4z', strokeWidth: 1.7),
    IconPath('M12 7.4a4.6 4.6 0 1 0 0 9.2a4.6 4.6 0 1 0 0-9.2z', strokeWidth: 1.7),
    IconPath('M12 10.9a1.1 1.1 0 1 0 0 2.2a1.1 1.1 0 1 0 0-2.2z', strokeWidth: 1.7),
  ];
  static const crown = [
    IconPath('M4.2 17.6h15.6M4.2 17.6 3.4 7.2l4.6 3.2L12 4.6l4 5.8 4.6-3.2-.8 10.4Z', strokeWidth: 1.7),
  ];
  static const bolt = [
    IconPath('M13.4 3.4 5.6 13.6h5.2l-.2 7 7.8-10.2h-5.2Z', strokeWidth: 1.7),
  ];
  static const shield = [
    IconPath('M12 3.6 5 6.2v5.5c0 4 2.9 7.5 7 8.7 4.1-1.2 7-4.7 7-8.7V6.2Z', strokeWidth: 1.7),
  ];
  static const rocket = [
    IconPath('M12 3.6c2.8 2.5 4.2 5.7 4.2 9.1v4.5H7.8v-4.5c0-3.4 1.4-6.6 4.2-9.1Z', strokeWidth: 1.7),
    IconPath('M12 8.5a1.8 1.8 0 1 0 0 3.6a1.8 1.8 0 1 0 0-3.6z', strokeWidth: 1.7),
    IconPath('M7.8 14 5.2 16.6v3.8l2.6-2M16.2 14l2.6 2.6v3.8l-2.6-2', strokeWidth: 1.7),
  ];
  static const sparkles = [
    IconPath('m8.4 3.8 1.1 2.9 2.9 1.1-2.9 1.1-1.1 2.9-1.1-2.9L4.4 7.8l2.9-1.1Z', strokeWidth: 1.7),
    IconPath('m16.2 12.4.8 2.1 2.1.8-2.1.8-.8 2.1-.8-2.1-2.1-.8 2.1-.8Z', strokeWidth: 1.7),
  ];
}
