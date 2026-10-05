import 'package:flutter/material.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final EdgeInsets padding;

  const StatusBadge({super.key, required this.label, required this.color, this.padding = const EdgeInsets.symmetric(horizontal:12, vertical:4)});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Text(label, style: textStyle),
    );
  }
}
