import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/cliente/presentation/widgets/cli_ui.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/servicios/data/models/categoria_model.dart';
import 'package:trabajoya_app/features/servicios/presentation/providers/servicios_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/empty_state.dart';

class CategoriasListScreen extends StatefulWidget {
  const CategoriasListScreen({super.key});

  @override
  State<CategoriasListScreen> createState() => _CategoriasListScreenState();
}

class _CategoriasListScreenState extends State<CategoriasListScreen> {
  final Set<String> _expandidos = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiciosProvider>().cargarCategorias();
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ServiciosProvider>();
    final raices = prov.categoriasRaiz;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        foregroundColor: CliColors.textPrimary(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          'Todas las categorias',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CliColors.textPrimary(context),
          ),
        ),
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : raices.isEmpty
          ? const AppEmptyState(
              icon: Icons.category_outlined,
              title: 'Aún no hay categorías',
              description: 'Estamos trabajando en añadir nuevas categorías de servicios. Vuelve más tarde.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(Spacing.xl2),
              itemCount: raices.length,
              itemBuilder: (context, i) {
                final raiz = raices[i];
                final hijas = prov.subcategoriasDe(raiz.id);
                final expandida = _expandidos.contains(raiz.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.sm),
                  child: CliCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(Radii.md),
                          onTap: () {
                            setState(() {
                              if (expandida) {
                                _expandidos.remove(raiz.id);
                              } else {
                                _expandidos.add(raiz.id);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.md,
                              vertical: Spacing.sm,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: CliColors.accent.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      Radii.md,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      raiz.icono ??
                                          raiz.nombre
                                              .substring(0, 1)
                                              .toUpperCase(),
                                      
                                    ),
                                  ),
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Text(
                                    raiz.nombre,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: CliColors.textPrimary(context),
                                    ),
                                  ),
                                ),
                                Text(
                                  '${hijas.length}',
                                  style: TextStyle(
                                    color: CliColors.textSecondary(context),
                                  ),
                                ),
                                const SizedBox(width: Spacing.xs),
                                Icon(
                                  expandida
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  color: CliColors.textSecondary(context),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (expandida && hijas.isNotEmpty)
                          ...hijas.map((h) => _HijaTile(hija: h)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _HijaTile extends StatelessWidget {
  final Categoria hija;
  const _HijaTile({required this.hija});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    return InkWell(
      onTap: () {
        if (isLoggedIn) {
          context.go('/cliente/buscar?q=${hija.nombre}');
        } else {
          context.go('/buscar?q=${hija.nombre}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(
          left: 64,
          right: Spacing.md,
          top: 4,
          bottom: 4,
        ),
        child: Row(
          children: [
            Text(hija.icono ?? '•', ),
            const SizedBox(width: Spacing.sm),
            Expanded(
              child: Text(
                hija.nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: CliColors.textPrimary(context),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: CliColors.textSecondary(context).withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
