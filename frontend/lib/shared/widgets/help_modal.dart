import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

// ── Configuración de soporte (editar estos valores) ──
const _kWhatsAppNumber = '56998604170';
const _kSupportEmail = 'admin@somostrabajoya.cl';
const _kWhatsAppMessage = 'Hola, necesito ayuda con TrabajoYa.';

/// Muestra el modal de ayuda y soporte.
void showHelpModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HelpModalContent(),
  );
}

class _HelpModalContent extends StatelessWidget {
  const _HelpModalContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
          ),
          const SizedBox(height: 20),

          // ── Título ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.support_agent, size: 28, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Necesitas ayuda?',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Elige una opción para contactarnos o resolver tu duda.',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Opciones de soporte ──
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _SupportOption(
                    icon: Icons.help_outline,
                    iconColor: AppColors.blueprint,
                    bgColor: AppColors.blueprint.withValues(alpha: 0.15),
                    title: 'Preguntas frecuentes',
                    subtitle: 'Respuestas rápidas a las dudas más comunes.',
                    onTap: () {
                      Navigator.pop(context);
                      _showFaqDialog(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _SupportOption(
                    icon: Icons.chat,
                    iconColor: AppColors.success,
                    bgColor: AppColors.success.withValues(alpha: 0.15),
                    title: 'WhatsApp',
                    subtitle: 'Chatea con nosotros directamente.',
                    onTap: () async {
                      Navigator.pop(context);
                      final url = Uri.parse(
                        'https://wa.me/$_kWhatsAppNumber?text=${Uri.encodeComponent(_kWhatsAppMessage)}',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _SupportOption(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primary.withValues(alpha: 0.15),
                    title: 'Correo de soporte',
                    subtitle: _kSupportEmail,
                    onTap: () async {
                      Navigator.pop(context);
                      final url = Uri.parse(
                        'mailto:$_kSupportEmail?subject=Soporte%20TrabajoYa',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _SupportOption(
                    icon: Icons.bug_report_outlined,
                    iconColor: Theme.of(context).colorScheme.error,
                    bgColor: Theme.of(context).colorScheme.error.withValues(alpha: 0.15),
                    title: 'Reportar un problema',
                    subtitle: 'Cuéntanos qué salió mal y te ayudamos.',
                    onTap: () {
                      Navigator.pop(context);
                      _showReportDialog(context);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportOption({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── FAQ Dialog ───────────────────

void _showFaqDialog(BuildContext context) {
  showDialog(context: context, builder: (_) => const _FaqDialog());
}

class _FaqDialog extends StatelessWidget {
  const _FaqDialog();

  static const _faqs = [
    {
      'q': '¿Cómo contrato un servicio?',
      'a':
          'Publica una solicitud describiendo lo que necesitas. Los proveedores cercanos te enviarán propuestas con presupuestos. Elige la que más te convenga y coordina directamente por el chat.',
    },
    {
      'q': '¿Cómo publico un servicio como proveedor?',
      'a':
          'Ve a la sección "Mis servicios" y presiona "Crear servicio". Completa el título, descripción, precio referencial y categoría. Tu servicio será visible para los clientes de tu zona.',
    },
    {
      'q': '¿Cómo funciona el sistema de calificación?',
      'a':
          'Al finalizar una contratación, ambas partes pueden calificarse mutuamente con estrellas (1 a 5). La calificación promedio se muestra en tu perfil público.',
    },
    {
      'q': '¿Es gratis usar TrabajoYa?',
      'a':
          'Crear una cuenta y publicar solicitudes es completamente gratis. Los proveedores pueden acceder a planes de suscripción para expandir su alcance y recibir más propuestas.',
    },
    {
      'q': '¿Cómo verifico mi identidad?',
      'a':
          'Ve a tu perfil → Seguridad y verificaciones → "Verificar identidad". Sube una foto de tu documento de identidad (cédula o pasaporte) y nuestro equipo lo revisará en 24-48 horas.',
    },
    {
      'q': '¿Cómo contacto al soporte?',
      'a':
          'Puedes escribirnos por WhatsApp, enviar un correo a admin@somostrabajoya.cl o reportar un problema directamente desde la app usando el botón de ayuda.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 500 fijo desbordaba en pantallas angostas (<500+64 de insetPadding).
    final maxDialogWidth = MediaQuery.sizeOf(context).width - 64;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      title: Row(
        children: [
          Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(width: 10),
          Text(
            'Preguntas frecuentes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: SizedBox(
        width: maxDialogWidth < 500 ? maxDialogWidth : 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _faqs
                .map((faq) => _FaqTile(question: faq['q']!, answer: faq['a']!))
                .toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.answer,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────── Report Dialog ───────────────────

void _showReportDialog(BuildContext context) {
  showDialog(context: context, builder: (_) => const _ReportDialog());
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _descripcionCtrl = TextEditingController();
  String _tipo = 'Error técnico';
  static const _tipos = [
    'Error técnico',
    'Problema con un usuario',
    'Problema de pago',
    'Sugerencia',
    'Otro',
  ];

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 440 fijo desbordaba en pantallas angostas (<440+64 de insetPadding).
    final maxDialogWidth = MediaQuery.sizeOf(context).width - 64;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      title: Row(
        children: [
          Icon(Icons.bug_report_outlined, color: Theme.of(context).colorScheme.error, size: 24),
          const SizedBox(width: 10),
          Text(
            'Reportar un problema',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: SizedBox(
        width: maxDialogWidth < 440 ? maxDialogWidth : 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de problema',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              items: _tipos
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _tipo = v);
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Descripción',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descripcionCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Describe el problema con el mayor detalle posible...',
                hintStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () async {
            if (_descripcionCtrl.text.trim().isEmpty) return;
            final subject = Uri.encodeComponent(
              '[$_tipo] Reporte desde TrabajoYa',
            );
            final body = Uri.encodeComponent(
              'Tipo: $_tipo\n\nDescripción:\n${_descripcionCtrl.text.trim()}\n\n---\nEnviado desde la app TrabajoYa',
            );
            final url = Uri.parse(
              'mailto:$_kSupportEmail?subject=$subject&body=$body',
            );
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
            if (context.mounted) Navigator.pop(context);
          },
          icon: const Icon(Icons.send, size: 16),
          label: Text(
            'Enviar reporte',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.md),
            ),
          ),
        ),
      ],
    );
  }
}
