import 'package:flutter/material.dart';
import 'package:trabajoya_app/utils/colors.dart';

class TicketBorder extends OutlinedBorder {
  final double radius;
  final bool marks;
  final Color line;
  final Color ink;

  TicketBorder({
    this.radius = 8,
    this.marks = true,
    this.line = AppColors.border,
    this.ink = AppColors.textDark,
    double side = 1,
  }) : super(
         side: BorderSide(color: line, width: side),
       );

  @override
  TicketBorder copyWith({BorderSide? side}) {
    final nextSide = side ?? this.side;
    return TicketBorder(
      radius: radius,
      marks: marks,
      line: nextSide.color,
      ink: ink,
      side: nextSide.width,
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final inset = side.width;
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        rect.deflate(inset),
        Radius.circular((radius - inset).clamp(0, radius)),
      ),
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final bounds = rect.deflate(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(radius)),
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width
        ..isAntiAlias = true,
    );

    if (!marks) return;

    const arm = 9.0;
    final markPaint = Paint()
      ..color = ink.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square
      ..isAntiAlias = true;

    canvas
      ..drawLine(
        bounds.topLeft,
        bounds.topLeft + const Offset(arm, 0),
        markPaint,
      )
      ..drawLine(
        bounds.topLeft,
        bounds.topLeft + const Offset(0, arm),
        markPaint,
      )
      ..drawLine(
        bounds.bottomRight,
        bounds.bottomRight - const Offset(arm, 0),
        markPaint,
      )
      ..drawLine(
        bounds.bottomRight,
        bounds.bottomRight - const Offset(0, arm),
        markPaint,
      );
  }

  @override
  TicketBorder scale(double t) => TicketBorder(
    radius: radius * t,
    marks: marks,
    line: line,
    ink: ink,
    side: side.width * t,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is TicketBorder ? _lerp(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is TicketBorder ? _lerp(this, b, t) : super.lerpTo(b, t);

  static TicketBorder _lerp(TicketBorder a, TicketBorder b, double t) =>
      TicketBorder(
        radius: a.radius + (b.radius - a.radius) * t,
        marks: t < 0.5 ? a.marks : b.marks,
        line: Color.lerp(a.line, b.line, t)!,
        ink: Color.lerp(a.ink, b.ink, t)!,
        side: a.side.width + (b.side.width - a.side.width) * t,
      );

  @override
  bool operator ==(Object other) =>
      other is TicketBorder &&
      other.radius == radius &&
      other.marks == marks &&
      other.line == line &&
      other.ink == ink &&
      other.side == side;

  @override
  int get hashCode => Object.hash(radius, marks, line, ink, side);
}
