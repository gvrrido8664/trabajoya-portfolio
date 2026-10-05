import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? color;

  const StatCard({super.key, required this.icon, required this.title, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.12),
              child: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
