import 'package:flutter/material.dart';
import 'package:trabajoya_app/utils/colors.dart';

class Eyebrow extends StatelessWidget {
  final String label;
  final Color color;

  const Eyebrow({
    super.key,
    required this.label,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, color: color),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'IBMPlexMono',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.54,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
