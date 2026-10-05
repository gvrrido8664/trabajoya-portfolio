import 'package:flutter/material.dart';
import 'package:trabajoya_app/shared/theme/ticket_border.dart';

class TicketCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final TicketBorder? border;

  const TicketCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final shape = border ?? TicketBorder();
    return Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
