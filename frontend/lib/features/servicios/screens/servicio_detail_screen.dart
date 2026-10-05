import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/features/servicios/data/models/servicio_model.dart';
import 'package:trabajoya_app/services/servicios_service.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class ServicioDetailScreen extends StatefulWidget {
  final String servicioId;
  const ServicioDetailScreen({super.key, required this.servicioId});

  @override
  State<ServicioDetailScreen> createState() => _ServicioDetailScreenState();
}

class _ServicioDetailScreenState extends State<ServicioDetailScreen> {
  final ServiciosService _service = ServiciosService();
  Servicio? _servicio;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      _servicio = await _service.getServicio(widget.servicioId);
    } catch (_) {
      _servicio = null;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del Servicio')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final s = _servicio;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle del Servicio')),
        body: const Center(child: Text('Servicio no encontrado')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.titulo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (s.fotosList.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: s.fotosList.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Radii.md),
                        color: Colors.grey.shade200,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.md),
                        child: Image.network(
                          s.fotosList[index],
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.image_not_supported, size: 48),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Text(
              s.titulo,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (s.precioMin != null)
              Row(
                children: [
                  Text(
                    '\$${s.precioMin!.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (s.precioMax != null) ...[
                    const Text(' - '),
                    Text(
                      '\$${s.precioMax!.toStringAsFixed(0)}',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ],
              ),
            const SizedBox(height: 16),
            Text(
              'Descripcion',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(s.descripcion, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(s.proveedorNombre ?? 'Proveedor'),
                subtitle: Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    Text(
                      ' ${s.proveedorRating?.toStringAsFixed(1) ?? "Nuevo"}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(
                  avatar: const Icon(Icons.location_on, size: 16),
                  label: Text('Cobertura: ${s.radioCoberturaKm} km'),
                ),
                if (s.direccionTexto != null && s.direccionTexto!.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.home, size: 16),
                    label: Text(s.direccionTexto!),
                  ),
                if (s.categoriaNombre != null && s.categoriaNombre!.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.category, size: 16),
                    label: Text(s.categoriaNombre!),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/solicitar/${s.id}'),
                child: const Text('Solicitar Servicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
