import 'package:flutter/material.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/shared/presentation/widgets/status_badge.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class ServicioCardShared extends StatelessWidget {
  final Servicio servicio;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const ServicioCardShared({super.key, required this.servicio, this.onTap, this.onEdit});

  String get precio {
    final s = servicio;
    if (s.precioMin != null && s.precioMax != null) return '\$${s.precioMin!.toStringAsFixed(0)} - \$${s.precioMax!.toStringAsFixed(0)}';
    if (s.precioMin != null) return 'Desde \$${s.precioMin!.toStringAsFixed(0)}';
    if (s.precioMax != null) return 'Hasta \$${s.precioMax!.toStringAsFixed(0)}';
    return 'A convenir';
  }

  @override
  Widget build(BuildContext context) {
    final fotos = servicio.fotosList;
    final img = fotos.isNotEmpty ? fotos.first : null;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: img != null
                    ? Image.network(img, width: 120, height: 80, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace)=> Container(width:120,height:80,color:Colors.grey[200],child: const Icon(Icons.broken_image)))
                    : Container(width:120,height:80,color:Colors.grey[100],child: const Icon(Icons.image, size: 36, color: Colors.grey)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(servicio.titulo, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height:6),
                    if (servicio.categoriaNombre != null) Text(servicio.categoriaNombre!, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height:8),
                    Row(
                      children: [
                        Text(precio, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
                        const SizedBox(width:12),
                        StatusBadge(label: servicio.status.toUpperCase(), color: Theme.of(context).colorScheme.primary),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined))
            ],
          ),
        ),
      ),
    );
  }
}
