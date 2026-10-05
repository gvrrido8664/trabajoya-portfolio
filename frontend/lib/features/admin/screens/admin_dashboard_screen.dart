import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Estás seguro de que quieres salir?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<AuthProvider>().logout();
                        context.go('/login');
                      },
                      child: const Text(
                        'Salir',
                        style: TextStyle(color: AppTheme.danger),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: admin.loading && stats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsGrid(stats),
                  const SizedBox(height: 28),
                  if (stats != null &&
                      stats['contrataciones_por_mes'] != null) ...[
                    Text(
                      'Contratos por mes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBarChart(
                      stats['contrataciones_por_mes'] as List<dynamic>,
                    ),
                    const SizedBox(height: 28),
                  ],
                  if (stats != null && stats['top_proveedores'] != null) ...[
                    Text(
                      'Top Proveedores',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTopProveedores(
                      stats['top_proveedores'] as List<dynamic>,
                    ),
                    const SizedBox(height: 28),
                  ],
                  if (stats != null && stats['top_categorias'] != null) ...[
                    Text(
                      'Top Categorías',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTopCategorias(
                      stats['top_categorias'] as List<dynamic>,
                    ),
                    const SizedBox(height: 28),
                  ],
                  Text(
                    'Gestión',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNavCard(
                    Icons.people,
                    'Usuarios',
                    'Gestionar usuarios de la plataforma',
                    () => context.push('/admin/usuarios'),
                  ),
                  _buildNavCard(
                    Icons.miscellaneous_services,
                    'Servicios',
                    'Revisar servicios publicados',
                    () => context.push('/admin/servicios'),
                  ),
                  _buildNavCard(
                    Icons.payment,
                    'Pagos',
                    'Ver historial de transacciones',
                    () => context.push('/admin/pagos'),
                  ),
                  _buildNavCard(
                    Icons.gavel,
                    'Disputas',
                    'Resolver disputas pendientes',
                    () => context.push('/admin/disputas'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic>? stats) {
    final usuarios = stats?['usuarios'] as Map<String, dynamic>?;
    final contrataciones = stats?['contrataciones'] as Map<String, dynamic>?;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600
            ? 2
            : constraints.maxWidth < 900
            ? 3
            : 4;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.5,
          children: [
            _statCard(
              Icons.people,
              (usuarios?['total'] ?? 0).toString(),
              'Usuarios',
              AppTheme.primary,
            ),
            _statCard(
              Icons.miscellaneous_services,
              (stats?['servicios_activos'] ?? 0).toString(),
              'Servicios activos',
              AppTheme.success,
            ),
            _statCard(
              Icons.description,
              (contrataciones?['este_mes'] ?? 0).toString(),
              'Contratos (mes)',
              AppTheme.secondary,
            ),
            _statCard(
              Icons.attach_money,
              (stats?['volumen_transaccionado_mes'] ?? 0).toString(),
              'Volumen CLP',
              AppTheme.danger,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> data) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data
        .map((e) => e['total'] as int)
        .reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final total = d['total'] as int;
          final height = maxVal > 0
              ? (total / maxVal * 80).ceilToDouble()
              : 0.0;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: max(height, 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    d['mes'].toString().substring(5),
                    style: const TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopProveedores(List<dynamic> proveedores) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: proveedores.asMap().entries.map((entry) {
            final p = entry.value;
            final nombre =
                p['nombre'] as String? ??
                p['proveedor_nombre'] as String? ??
                '';
            final rating =
                (p['rating'] as num? ?? p['proveedor_rating'] as num? ?? 0)
                    .toDouble();
            final contratos =
                p['total_contratos'] as int? ?? p['contratos'] as int? ?? 0;
            final isLast = entry.key == proveedores.length - 1;
            return Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(nombre.isNotEmpty ? nombre : 'Proveedor'),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(' ${rating.toStringAsFixed(1)}'),
                      const SizedBox(width: 8),
                      Text(
                        '$contratos contratos',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopCategorias(List<dynamic> categorias) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: categorias.asMap().entries.map((entry) {
            final c = entry.value;
            final nombre =
                c['nombre'] as String? ??
                c['categoria_nombre'] as String? ??
                '';
            final total = c['total'] as int? ?? 0;
            final isLast = entry.key == categorias.length - 1;
            return Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.category,
                      color: AppTheme.secondary,
                      size: 20,
                    ),
                  ),
                  title: Text(nombre.isNotEmpty ? nombre : 'Categoría'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Text(
                      '$total',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (!isLast) const Divider(height: 1),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNavCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppTheme.textSecondary,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
