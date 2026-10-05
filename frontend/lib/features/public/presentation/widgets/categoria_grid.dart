import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/servicios/data/models/categoria_model.dart';
import 'package:trabajoya_app/features/servicios/presentation/providers/servicios_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class CategoriaGrid extends StatelessWidget {
  final void Function(String nombre)? onSelect;
  final List<Categoria>? categorias;

  const CategoriaGrid({super.key, this.onSelect, this.categorias});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ServiciosProvider?>(context, listen: false);
    final data = categorias ?? prov?.categorias ?? [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 5 : constraints.maxWidth > 500 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 24,
            crossAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          itemCount: data.length,
          itemBuilder: (context, i) {
            final cat = data[i];
            return _CategoriaCardFromModel(
              categoria: cat,
              onTap: () => onSelect?.call(cat.nombre),
            );
          },
        );
      },
    );
  }
}

class _CategoriaCardFromModel extends StatelessWidget {
  final Categoria categoria;
  final VoidCallback onTap;
  const _CategoriaCardFromModel({required this.categoria, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(Radii.md),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.08),
            child: Text(
              categoria.icono ?? categoria.nombre.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            categoria.nombre,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
