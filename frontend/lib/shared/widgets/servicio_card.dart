import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/cliente/presentation/widgets/cli_ui.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/shared/widgets/status_badge.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class ServicioCardShared extends StatefulWidget {
  final Servicio servicio;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const ServicioCardShared({
    super.key,
    required this.servicio,
    this.onTap,
    this.onEdit,
  });

  @override
  State<ServicioCardShared> createState() => _ServicioCardSharedState();
}

class _ServicioCardSharedState extends State<ServicioCardShared> {
  bool _isHovered = false;

  String get precio {
    final s = widget.servicio;
    if (s.precioMin == null) return 'A convenir';
    if (s.precioMax == 1.0) return '\$${_fmt(s.precioMin!)} / hora';
    if (s.precioMax == 2.0) return '\$${_fmt(s.precioMin!)} / servicio';
    return 'Desde \$${_fmt(s.precioMin!)}';
  }

  String _fmt(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final fotos = widget.servicio.fotosList;
    final img = fotos.isNotEmpty ? fotos.first : null;
    return Semantics(
      label:
          'Servicio: ${widget.servicio.titulo}, Categoría: ${widget.servicio.categoriaNombre ?? "sin categoría"}, Precio: $precio, Estado: ${widget.servicio.status}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.onTap != null || widget.onEdit != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()..scale(_isHovered ? 1.01 : 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(
                color: _isHovered ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(Radii.md),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.sm),
                      child: ExcludeSemantics(
                        child: img != null
                            ? Image.network(
                                img,
                                width: 120,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 120,
                                      height: 80,
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.broken_image, color: AppColors.textLight),
                                    ),
                              )
                            : Container(
                                width: 120,
                                height: 80,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(
                                  Icons.image,
                                  size: 36,
                                  color: AppColors.textLight,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.servicio.titulo,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          if (widget.servicio.categoriaNombre != null)
                            Text(
                              widget.servicio.categoriaNombre!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          if (widget.servicio.proveedorNombre != null && widget.servicio.proveedorNombre!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 14, color: AppColors.textLight),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.servicio.proveedorNombre!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.textLight,
                                          fontWeight: FontWeight.w500,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.servicio.proveedorDocEstado == 'approved') ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified, size: 14, color: AppColors.primary),
                                ],
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                precio,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color:
                                          CliColors.accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const Spacer(),
                              StatusBadge.forStatus(widget.servicio.status),
                              if (widget.onEdit != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Editar servicio',
                                  onPressed: widget.onEdit,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
