import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';

class AdminFullDashboardScreen extends StatefulWidget {
  const AdminFullDashboardScreen({super.key});

  @override
  State<AdminFullDashboardScreen> createState() =>
      _AdminFullDashboardScreenState();
}

class _AdminFullDashboardScreenState extends State<AdminFullDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarStats();
    });
  }

  /// Centra el [child] con ancho máximo de 1200px.
  Widget centered(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.stats;

    return admin.loading && stats == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Stats Cards ----
                    _buildStatsGrid(stats),
                    const SizedBox(height: 28),

                    // ---- Menú Admin ----
                    const Text(
                      'Gestión de plataforma',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildAdminMenu(),
                    const SizedBox(height: 28),

                    // ---- Gráficos ----
                    if (stats != null &&
                        stats['contrataciones_por_mes'] != null) ...[
                      _buildSectionTitle('Contrataciones por mes'),
                      const SizedBox(height: 12),
                      _buildBarChart(
                        stats['contrataciones_por_mes'] as List<dynamic>,
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ---- Top Proveedores ----
                    if (stats != null && stats['top_proveedores'] != null) ...[
                      _buildSectionTitle('Top Proveedores'),
                      const SizedBox(height: 12),
                      _buildTopProveedores(
                        stats['top_proveedores'] as List<dynamic>,
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ---- Top Categorías ----
                    if (stats != null && stats['top_categorias'] != null) ...[
                      _buildSectionTitle('Top Categorías'),
                      const SizedBox(height: 12),
                      _buildTopCategorias(
                        stats['top_categorias'] as List<dynamic>,
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ---- Servicios por estado ----
                    _buildSectionTitle('Servicios por estado'),
                    const SizedBox(height: 12),
                    _buildServiciosEstado(),
                    const SizedBox(height: 28),

                    // ---- Transacciones recientes ----
                    _buildSectionTitle('Transacciones recientes'),
                    const SizedBox(height: 12),
                    _buildTransaccionesRecientes(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              'Total Usuarios',
              AppTheme.primary,
            ),
            _statCard(
              Icons.person,
              (usuarios?['clientes'] ?? 0).toString(),
              'Clientes',
              AppTheme.secondary,
            ),
            _statCard(
              Icons.engineering,
              (usuarios?['proveedores'] ?? 0).toString(),
              'Proveedores',
              AppTheme.success,
            ),
            _statCard(
              Icons.miscellaneous_services,
              (stats?['servicios_activos'] ?? 0).toString(),
              'Servicios activos',
              AppColors.blueprint,
            ),
            _statCard(
              Icons.description,
              (contrataciones?['este_mes'] ?? 0).toString(),
              'Contratos (mes)',
              AppColors.secondary,
            ),
            _statCard(
              Icons.attach_money,
              _formatMonto(stats?['volumen_transaccionado_mes'] ?? 0),
              'Volumen (CLP)',
              AppColors.success,
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

  Widget _buildAdminMenu() {
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
          childAspectRatio: 2.5,
          children: [
            _menuCard(
              Icons.people,
              'Clientes',
              'Ver clientes',
              () => context.go('/admin/clientes'),
              AppColors.blueprint,
            ),
            _menuCard(
              Icons.engineering,
              'Proveedores',
              'Ver proveedores',
              () => context.go('/admin/proveedores'),
              AppTheme.success,
            ),
            _menuCard(
              Icons.payment,
              'Transacciones',
              'Ver pagos',
              () => context.go('/admin/transacciones'),
              AppColors.secondary,
            ),
            _menuCard(
              Icons.check_circle,
              'Realizados',
              'Servicios realizados',
              () => context.go('/admin/realizados'),
              AppColors.success,
            ),
            _menuCard(
              Icons.cancel,
              'Cancelados',
              'Servicios cancelados',
              () => context.go('/admin/cancelados'),
              AppTheme.danger,
            ),
            _menuCard(
              Icons.miscellaneous_services,
              'Cobrados',
              'Servicios cobrados',
              () => context.go('/admin/cobrados'),
              AppColors.blueprint,
            ),
            _menuCard(
              Icons.error,
              'Fallidos',
              'Servicios fallidos',
              () => context.go('/admin/fallidos'),
              AppColors.danger,
            ),
            _menuCard(
              Icons.feedback,
              'Feedback',
              'Reseñas y feedback',
              () => context.go('/admin/feedback'),
              AppColors.blueprint,
            ),
          ],
        );
      },
    );
  }

  Widget _menuCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    Color color,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
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
                    height: math.max(height, 4),
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

  Widget _buildServiciosEstado() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _estadoItem('Activos', '24', AppTheme.success),
            _estadoItem('Pausados', '5', AppColors.secondary),
            _estadoItem('Cancelados', '2', AppTheme.danger),
            _estadoItem('Eliminados', '1', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _estadoItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTransaccionesRecientes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.success.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.check,
                  color: AppTheme.success,
                  size: 18,
                ),
              ),
              title: const Text(
                'Pago aprobado',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'María G. → Carlos P.',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Text(
                '+\$25.000',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success,
                  fontSize: 13,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.pending,
                  color: AppColors.secondary,
                  size: 18,
                ),
              ),
              title: const Text(
                'Pago pendiente',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Juan R. → Ana M.',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Text(
                '\$45.000',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                  fontSize: 13,
                ),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.gavel,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              title: const Text(
                'Disputa abierta',
                style: TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Contratación #mock-contr-1',
                style: TextStyle(fontSize: 11),
              ),
              trailing: const Text(
                'En revisión',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMonto(dynamic monto) {
    final val = (monto as num).toDouble();
    if (val >= 1000000) {
      return '\$${(val / 1000000).toStringAsFixed(1)}M';
    } else if (val >= 1000) {
      return '\$${(val / 1000).toStringAsFixed(0)}k';
    }
    return '\$$val';
  }

  void showLogoutDialog(BuildContext context) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (!ctx.mounted) return;
              ctx.go('/');
            },
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}
