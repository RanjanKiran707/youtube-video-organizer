import 'package:flutter/material.dart';

enum AppIconData { folder, folderPlus, share }

/// The line icons of the mockup (24x24 grid, 1.6 stroke, round caps), drawn from
/// the same paths as its SVG symbols.
class AppIcon extends StatelessWidget {
  final AppIconData icon;
  final double size;
  final Color color;

  const AppIcon(this.icon, {super.key, this.size = 20, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(icon, color),
    );
  }
}

class _IconPainter extends CustomPainter {
  final AppIconData icon;
  final Color color;

  _IconPainter(this.icon, this.color);

  static const _corner = Radius.circular(2);

  Path _folder() => Path()
    ..moveTo(3, 7)
    ..arcToPoint(const Offset(5, 5), radius: _corner)
    ..lineTo(9, 5)
    ..lineTo(11, 7)
    ..lineTo(19, 7)
    ..arcToPoint(const Offset(21, 9), radius: _corner)
    ..lineTo(21, 17)
    ..arcToPoint(const Offset(19, 19), radius: _corner)
    ..lineTo(5, 19)
    ..arcToPoint(const Offset(3, 17), radius: _corner)
    ..close();

  Path _path() {
    switch (icon) {
      case AppIconData.folder:
        return _folder();
      case AppIconData.folderPlus:
        return _folder()
          ..moveTo(12, 10)
          ..lineTo(12, 16)
          ..moveTo(9, 13)
          ..lineTo(15, 13);
      case AppIconData.share:
        return Path()
          ..moveTo(12, 4)
          ..lineTo(12, 15)
          ..moveTo(8, 8)
          ..lineTo(12, 4)
          ..lineTo(16, 8)
          ..moveTo(5, 13)
          ..lineTo(5, 19)
          ..lineTo(19, 19)
          ..lineTo(19, 13);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    canvas.drawPath(
      _path(),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color;
}
