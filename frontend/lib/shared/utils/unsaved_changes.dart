import 'package:flutter/material.dart';

/// Confirma con el usuario antes de descartar cambios sin guardar (FUN-32).
/// Devuelve `true` si debe procederse a salir (sin cambios, o el usuario
/// confirmó descartar), `false` si debe quedarse en la pantalla/diálogo.
Future<bool> confirmDiscardChanges(BuildContext context, {required bool hasChanges}) async {
  if (!hasChanges) return true;
  final descartar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('¿Descartar cambios?'),
      content: const Text('Tienes cambios sin guardar. Si sales ahora, se perderán.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Seguir editando'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Descartar'),
        ),
      ],
    ),
  );
  return descartar ?? false;
}
