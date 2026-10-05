import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

import 'package:trabajoya_app/core/utils/csv_export.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
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
      final a = context.read<AdminProvider>();
      a.cargarStats();
      a.cargarServicios();
      a.cargarPagos();
    });
  }

  void _exportCsv() {
    final admin = context.read<AdminProvider>();
    final stats = admin.stats;
    final usuarios = stats?['usuarios'] as Map<String, dynamic>? ?? {};
    final contrataciones =
        stats?['contrataciones'] as Map<String, dynamic>? ?? {};
    exportCsv(
      context,
      'dashboard',
      ['Métrica', 'Valor'],
      [
        ['Total Usuarios', '${usuarios['total'] ?? 0}'],
        ['Clientes', '${usuarios['clientes'] ?? 0}'],
        ['Proveedores', '${usuarios['proveedores'] ?? 0}'],
        ['Servicios Activos', '${stats?['servicios_activos'] ?? 0}'],
        ['Contratos (mes)', '${contrataciones['este_mes'] ?? 0}'],
        ['Volumen (CLP)', '${stats?['volumen_transaccionado_mes'] ?? 0}'],
        [
          'Servicios Activos (real)',
          '${admin.servicios.where((s) => s['status'] == 'ACTIVO').length}',
        ],
        [
          'Servicios Pausados',
          '${admin.servicios.where((s) => s['status'] == 'PAUSADO').length}',
        ],
        [
          'Pagos Pendientes',
          '${admin.pagos.where((p) => p['status'] == 'PENDIENTE').length}',
        ],
        [
          'Pagos Aprobados',
          '${admin.pagos.where((p) => p['status'] == 'APROBADO').length}',
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.stats;

    return Scaffold(
      body: admin.loading && stats == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Panel de control',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.file_download_outlined,
                              color: AppColors.textLight,
                            ),
                            tooltip: 'Exportar CSV',
                            onPressed: _exportCsv,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildStatsGrid(stats),
                      const SizedBox(height: 28),

                      Text(
                        'Gestión de plataforma',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAdminMenu(),
                      const SizedBox(height: 28),

                      if (stats != null &&
                          stats['contrataciones_por_mes'] != null) ...[
                        Text(
                          'Contrataciones por mes',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBarChart(
                          stats['contrataciones_por_mes'] as List<dynamic>,
                        ),
                        const SizedBox(height: 28),
                      ],

                      if (stats != null &&
                          stats['top_proveedores'] != null) ...[
                        Text(
                          'Top proveedores',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
                          'Top categorías',
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTopCategorias(
                          stats['top_categorias'] as List<dynamic>,
                        ),
                        const SizedBox(height: 28),
                      ],

                      Text(
                        'Servicios por estado',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildServiciosEstado(),
                      const SizedBox(height: 28),

                      Text(
                        'Transacciones recientes',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTransaccionesRecientes(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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
              'Total Usuarios',
              AppColors.primary,
            ),
            _statCard(
              Icons.person,
              (usuarios?['clientes'] ?? 0).toString(),
              'Clientes',
              AppColors.primary,
            ),
            _statCard(
              Icons.engineering,
              (usuarios?['proveedores'] ?? 0).toString(),
              'Proveedores',
              AppColors.success,
            ),
            _statCard(
              Icons.miscellaneous_services,
              (stats?['servicios_activos'] ?? 0).toString(),
              'Servicios activos',
              AppColors.success,
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
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
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
              'Usuarios',
              'Clientes y proveedores',
              () => context.go('/admin/usuarios'),
              AppColors.primary,
            ),
            _menuCard(
              Icons.work,
              'Servicios',
              'Gestión de servicios',
              () => context.go('/admin/servicios'),
              AppColors.success,
            ),
            _menuCard(
              Icons.category,
              'Categorías',
              'Gestionar rubros',
              () => context.go('/admin/categorias'),
              AppColors.secondary,
            ),
            _menuCard(
              Icons.payment,
              'Pagos',
              'Ver transacciones',
              () => context.go('/admin/pagos'),
              AppColors.success,
            ),
            _menuCard(
              Icons.support_agent,
              'Soporte',
              'Problemas y disputas',
              () => context.go('/admin/soporte'),
              AppColors.danger,
            ),
            _menuCard(
              Icons.feedback,
              'Feedback',
              'Reseñas y feedback',
              () => context.go('/admin/feedback'),
              AppColors.primary,
            ),
            _menuCard(
              Icons.verified_user,
              'Verificaciones',
              'Revisar identidad',
              () => context.push('/admin/verificaciones'),
              AppColors.secondary,
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
      margin: EdgeInsets.zero,
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
                      color: color.withValues(alpha: 0.12),
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
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
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
                    color: AppColors.textLight,
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
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
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: math.max(height, 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.blueprint,
                              AppColors.blueprint.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(Radii.sm),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blueprint.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d['mes'].toString().substring(5),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTopProveedores(List<dynamic> proveedores) {
    return Card(
      margin: EdgeInsets.zero,
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
                    backgroundColor: AppColors.blueprintTint,
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.blueprint,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    nombre.isNotEmpty ? nombre : 'Proveedor',
                    style: const TextStyle(color: AppColors.textDark),
                  ),
                  subtitle: Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      Text(
                        ' ${rating.toStringAsFixed(1)}',
                        style: const TextStyle(color: AppColors.textLight),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$contratos contratos',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) const Divider(height: 1, color: AppColors.border),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopCategorias(List<dynamic> categorias) {
    return Card(
      margin: EdgeInsets.zero,
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
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.category,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    nombre.isNotEmpty ? nombre : 'Categoría',
                    style: const TextStyle(color: AppColors.textDark),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Text(
                      '$total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (!isLast) const Divider(height: 1, color: AppColors.border),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildServiciosEstado() {
    final admin = context.read<AdminProvider>();
    final activos = admin.servicios
        .where((s) => s['status'] == 'ACTIVO')
        .length;
    final pausados = admin.servicios
        .where((s) => s['status'] == 'PAUSADO')
        .length;
    final eliminados = admin.servicios
        .where((s) => s['status'] == 'ELIMINADO')
        .length;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _estadoItem('$activos', 'Activos', AppColors.success),
            _estadoItem('$pausados', 'Pausados', AppColors.secondary),
            _estadoItem('$eliminados', 'Cancelados', AppColors.danger),
            _estadoItem(
              '${admin.servicios.length}',
              'Total',
              AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoItem(String value, String label, Color color) {
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
          style: const TextStyle(fontSize: 13, color: AppColors.textLight),
        ),
      ],
    );
  }

  Widget _buildTransaccionesRecientes() {
    final admin = context.read<AdminProvider>();
    final recientes = admin.pagos.take(3).toList();

    if (recientes.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'No hay transacciones recientes',
              style: TextStyle(color: AppColors.textLight),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: recientes.asMap().entries.map((entry) {
            final p = entry.value;
            final isLast = entry.key == recientes.length - 1;
            final monto = (p['monto'] as num?)?.toDouble() ?? 0;
            final status = p['status'] as String? ?? '';
            final gateway = p['metodo_pago'] as String? ?? '';
            final contrato = p['contratacion_id'] as String? ?? '';
            final color = status == 'APROBADO'
                ? AppColors.success
                : (status == 'RECHAZADO' || status == 'CANCELADO'
                      ? AppColors.danger
                      : AppColors.secondary);
            final icon = status == 'APROBADO'
                ? Icons.check
                : (status == 'RECHAZADO' || status == 'CANCELADO' ? Icons.close : Icons.pending);

            return Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  title: Text(
                    'Pago ${status == 'APROBADO'
                        ? 'aprobado'
                        : status == 'RECHAZADO'
                        ? 'rechazado'
                        : status == 'CANCELADO'
                        ? 'cancelado'
                        : 'pendiente'}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  subtitle: Text(
                    '$gateway — Contrato: $contrato',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                  trailing: Text(
                    '\$${monto.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (!isLast) const Divider(height: 1, color: AppColors.border),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatMonto(dynamic monto) {
    final val = (monto as num).toDouble();
    if (val >= 1000000) return '\$${(val / 1000000).toStringAsFixed(1)}M';
    if (val >= 1000) return '\$${(val / 1000).toStringAsFixed(0)}k';
    return '\$$val';
  }
}
