import 'package:flutter/material.dart';
import 'package:trabajoya_app/utils/colors.dart';

class CornerBorderContainer extends StatelessWidget {
  final Widget child;
  final double cornerLength;
  final double strokeWidth;
  final Color color;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  const CornerBorderContainer({
    super.key,
    required this.child,
    this.cornerLength = 12.0,
    this.strokeWidth = 2.0,
    this.color = AppColors.border,
    this.backgroundColor,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornerBorderPainter(
        cornerLength: cornerLength,
        strokeWidth: strokeWidth,
        color: color,
        backgroundColor: backgroundColor,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _CornerBorderPainter extends CustomPainter {
  final double cornerLength;
  final double strokeWidth;
  final Color color;
  final Color? backgroundColor;

  _CornerBorderPainter({
    required this.cornerLength,
    required this.strokeWidth,
    required this.color,
    this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor != null) {
      final bgPaint = Paint()
        ..color = backgroundColor!
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final path = Path();
    // Top-Left
    path.moveTo(0, cornerLength);
    path.lineTo(0, 0);
    path.lineTo(cornerLength, 0);

    // Top-Right
    path.moveTo(size.width - cornerLength, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, cornerLength);

    // Bottom-Left
    path.moveTo(0, size.height - cornerLength);
    path.lineTo(0, size.height);
    path.lineTo(cornerLength, size.height);

    // Bottom-Right
    path.moveTo(size.width - cornerLength, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBorderPainter oldDelegate) {
    return oldDelegate.cornerLength != cornerLength ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color;
  }
}
