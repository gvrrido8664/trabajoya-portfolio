import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:trabajoya_app/core/utils/csv_export.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/utils/colors.dart';

String _formatFecha(String iso) {
  if (iso.isEmpty) return '';
  try {
    final dt = DateTime.parse(iso);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}

class AdminUsuariosScreen extends StatefulWidget {
  final String? initialRol;
  const AdminUsuariosScreen({super.key, this.initialRol});

  @override
  State<AdminUsuariosScreen> createState() => _AdminUsuariosScreenState();
}

class _AdminUsuariosScreenState extends State<AdminUsuariosScreen> {
  final _searchCtrl = TextEditingController();
  String? _rolFilter;
  Timer? _debounce;
  final Set<String> _toggling = {};

  @override
  void initState() {
    super.initState();
    _rolFilter = widget.initialRol;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarUsuarios(rol: _rolFilter ?? '');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _search() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<AdminProvider>().cargarUsuarios(
        email: _searchCtrl.text.trim().isNotEmpty
            ? _searchCtrl.text.trim()
            : null,
        rol: _rolFilter,
      );
    });
  }

  Future<void> _toggleUsuario(
    String id,
    String nombre,
    bool currentActive,
  ) async {
    setState(() => _toggling.add(id));
    try {
      await context.read<AdminProvider>().toggleUsuarioActivo(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$nombre ${currentActive ? 'desactivado' : 'activado'}',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: currentActive ? AppColors.danger : AppColors.success,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar usuario'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling.remove(id));
    }
  }

  void _verDetalle(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      builder: (_) => _UserDetailSheet(
        user: user,
        onToggle: () {
          Navigator.pop(context);
          final id = user['id']?.toString() ?? '';
          final nombre = '${user['nombre'] ?? ''} ${user['apellido'] ?? ''}'
              .trim();
          _toggleUsuario(id, nombre, user['is_active'] as bool? ?? true);
        },
        onEdit: () {
          Navigator.pop(context);
          _showEditDialog(user);
        },
      ),
    );
  }

  void _showCreateDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nombreCtrl = TextEditingController();
    final apellidoCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    String rol = 'cliente';
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Crear usuario',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(ctx, 
                  controller: emailCtrl,
                  label: 'Email *',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                _field(ctx, 
                  controller: passCtrl,
                  label: 'Contraseña *',
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                _field(ctx, controller: nombreCtrl, label: 'Nombre *'),
                const SizedBox(height: 8),
                _field(ctx, controller: apellidoCtrl, label: 'Apellido *'),
                const SizedBox(height: 8),
                _field(ctx, 
                  controller: telefonoCtrl,
                  label: 'Teléfono',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _dropdown<String>(
                  ctx,
                  value: rol,
                  label: 'Rol',
                  items: [
                    DropdownMenuItem(
                      value: 'cliente',
                      child: Text(
                        'Cliente',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'proveedor',
                      child: Text(
                        'Proveedor',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text(
                        'Admin',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => rol = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (emailCtrl.text.isEmpty ||
                          passCtrl.text.isEmpty ||
                          nombreCtrl.text.isEmpty ||
                          apellidoCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Completa todos los campos requeridos (*)',
                            ),
                          ),
                        );
                        return;
                      }
                      setDialogState(() => saving = true);
                      try {
                        await context.read<AdminProvider>().crearUsuario({
                          'email': emailCtrl.text.trim(),
                          'password': passCtrl.text,
                          'nombre': nombreCtrl.text.trim(),
                          'apellido': apellidoCtrl.text.trim(),
                          'telefono': telefonoCtrl.text.trim().isNotEmpty
                              ? telefonoCtrl.text.trim()
                              : null,
                          'rol': rol,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario creado'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                  : const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> user) {
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final nombreCtrl = TextEditingController(text: user['nombre'] ?? '');
    final apellidoCtrl = TextEditingController(text: user['apellido'] ?? '');
    final telefonoCtrl = TextEditingController(text: user['telefono'] ?? '');
    String rol = user['rol'] as String? ?? 'cliente';
    bool saving = false;
    final id = user['id']?.toString() ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(
            'Editar usuario',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(ctx, 
                  controller: emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                _field(ctx, controller: nombreCtrl, label: 'Nombre'),
                const SizedBox(height: 8),
                _field(ctx, controller: apellidoCtrl, label: 'Apellido'),
                const SizedBox(height: 8),
                _field(ctx, 
                  controller: telefonoCtrl,
                  label: 'Teléfono',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _dropdown<String>(
                  ctx,
                  value: rol,
                  label: 'Rol',
                  items: [
                    DropdownMenuItem(
                      value: 'cliente',
                      child: Text(
                        'Cliente',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'proveedor',
                      child: Text(
                        'Proveedor',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text(
                        'Admin',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => rol = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      try {
                        final data = <String, dynamic>{
                          'email': emailCtrl.text.trim(),
                          'nombre': nombreCtrl.text.trim(),
                          'apellido': apellidoCtrl.text.trim(),
                          'rol': rol,
                        };
                        if (telefonoCtrl.text.trim().isNotEmpty) {
                          data['telefono'] = telefonoCtrl.text.trim();
                        }
                        await context.read<AdminProvider>().actualizarUsuario(
                          id,
                          data,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario actualizado'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportCsv() {
    final admin = context.read<AdminProvider>();
    exportCsv(
      context,
      'usuarios',
      ['Nombre', 'Email', 'Rol', 'Activo', 'Teléfono', 'Rating'],
      admin.usuarios
          .map(
            (u) => [
              '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim(),
              u['email'] as String? ?? '',
              u['rol'] as String? ?? '',
              (u['is_active'] as bool? ?? true) ? 'Sí' : 'No',
              u['telefono'] as String? ?? '',
              (u['avg_rating'] as num?)?.toStringAsFixed(1) ?? '0.0',
            ],
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
      body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _kpiCard(
                            title: 'TOTAL USUARIOS',
                            value: '${admin.usuarios.length}',
                            icon: Icons.people,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _kpiCard(
                            title: 'CLIENTES',
                            value: '${admin.usuarios.where((u) => u['rol'] == 'cliente').length}',
                            icon: Icons.person_outline,
                            color: AppColors.blueprint,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _kpiCard(
                            title: 'PROVEEDORES',
                            value: '${admin.usuarios.where((u) => u['rol'] == 'proveedor').length}',
                            icon: Icons.engineering_outlined,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar por email...',
                              hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        size: 18,
                                      ),
                                      tooltip: 'Limpiar búsqueda',
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        _search();
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Radii.md),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(Radii.md),
                                borderSide: BorderSide(
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            onChanged: (_) => _search(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 2,
                          child: SizedBox(
                            width: 140,
                            child: _dropdown<String?>(
                              context,
                              value: _rolFilter,
                              label: 'Rol',
                              hint: 'Todos',
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'Todos',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'cliente',
                                  child: Text(
                                    'Cliente',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'proveedor',
                                  child: Text(
                                    'Proveedor',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text(
                                    'Admin',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                              ],
                              onChanged: (v) {
                                setState(() => _rolFilter = v);
                                _search();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            Icons.file_download_outlined,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          tooltip: 'Exportar CSV',
                          onPressed: admin.usuarios.isNotEmpty
                              ? _exportCsv
                              : null,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: admin.loading && admin.usuarios.isEmpty
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : admin.usuarios.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No se encontraron usuarios',
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final isDesktop = constraints.maxWidth >= 800;

                              if (isDesktop) {
                                return SingleChildScrollView(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(Radii.md),
                                        side: BorderSide(
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                        headingRowColor:
                                            WidgetStateProperty.all(
                                              Theme.of(context).scaffoldBackgroundColor,
                                            ),
                                        columns: const [
                                          DataColumn(
                                            label: Text(
                                              'Usuario',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Rol',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Estado',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Registro',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataColumn(
                                            label: Text(
                                              'Acciones',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                        rows: admin.usuarios.map((u) {
                                          final id = u['id']?.toString() ?? '';
                                          final email =
                                              u['email'] as String? ?? '';
                                          final nombre =
                                              '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'
                                                  .trim();
                                          final rol =
                                              u['rol'] as String? ?? 'cliente';
                                          final isActive =
                                              u['is_active'] as bool? ?? true;
                                          final isToggling = _toggling.contains(
                                            id,
                                          );
                                          final createdAt =
                                              u['created_at'] as String? ?? '';

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 16,
                                                      backgroundColor:
                                                          (isActive
                                                                  ? _rolColor(
                                                                      rol,
                                                                    )
                                                                  : Colors.grey)
                                                              .withValues(
                                                                alpha: 0.15,
                                                              ),
                                                      child: Text(
                                                        nombre.isNotEmpty
                                                            ? nombre[0]
                                                                  .toUpperCase()
                                                            : '?',
                                                        style: TextStyle(
                                                          color: isActive
                                                              ? _rolColor(rol)
                                                              : Colors.grey,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          nombre.isNotEmpty
                                                              ? nombre
                                                              : 'Sin nombre',
                                                          style: TextStyle(
                                                            color: isActive
                                                                ? Theme.of(context).colorScheme.onSurface
                                                                : Colors.grey,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            decoration: isActive
                                                                ? null
                                                                : TextDecoration
                                                                      .lineThrough,
                                                          ),
                                                        ),
                                                        Text(
                                                          email,
                                                          style: TextStyle(
                                                            color: isActive
                                                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                                                : Colors.grey,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                _chip(
                                                  rol.toUpperCase(),
                                                  _rolColor(rol),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (isActive
                                                                ? AppColors
                                                                      .success
                                                                : AppColors
                                                                      .danger)
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          Radii.md,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    isActive
                                                        ? 'Activo'
                                                        : 'Inactivo',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isActive
                                                          ? AppColors.success
                                                          : AppColors.danger,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  _formatFecha(createdAt),
                                                  style: TextStyle(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.visibility,
                                                        size: 20,
                                                        color:
                                                            Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                      tooltip: 'Ver detalle',
                                                      onPressed: () =>
                                                          _verDetalle(u),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.edit,
                                                        size: 20,
                                                        color:
                                                            Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                      tooltip: 'Editar',
                                                      onPressed: () =>
                                                          _showEditDialog(u),
                                                    ),
                                                    isToggling
                                                        ? const Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  12,
                                                                ),
                                                            child: SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child: CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: AppColors
                                                                    .primary,
                                                              ),
                                                            ),
                                                          )
                                                        : IconButton(
                                                            icon: Icon(
                                                              isActive
                                                                  ? Icons.block
                                                                  : Icons
                                                                        .check_circle,
                                                              color: isActive
                                                                  ? AppColors
                                                                        .danger
                                                                  : AppColors
                                                                        .success,
                                                              size: 20,
                                                            ),
                                                            tooltip: isActive
                                                                ? 'Desactivar'
                                                                : 'Activar',
                                                            onPressed: () =>
                                                                _toggleUsuario(
                                                                  id,
                                                                  nombre,
                                                                  isActive,
                                                                ),
                                                          ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: admin.usuarios.length,
                                itemBuilder: (context, index) {
                                  final u = admin.usuarios[index];
                                  final id = u['id']?.toString() ?? '';
                                  final email = u['email'] as String? ?? '';
                                  final nombre =
                                      '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'
                                          .trim();
                                  final rol = u['rol'] as String? ?? 'cliente';
                                  final isActive =
                                      u['is_active'] as bool? ?? true;
                                  final isToggling = _toggling.contains(id);

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    child: Card(
                                      margin: EdgeInsets.zero,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              (isActive
                                                      ? _rolColor(rol)
                                                      : Colors.grey)
                                                  .withValues(alpha: 0.15),
                                          child: Text(
                                            nombre.isNotEmpty
                                                ? nombre[0].toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              color: isActive
                                                  ? _rolColor(rol)
                                                  : Colors.grey,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                nombre.isNotEmpty
                                                    ? nombre
                                                    : 'Sin nombre',
                                                style: TextStyle(
                                                  color: isActive
                                                      ? Theme.of(context).colorScheme.onSurface
                                                      : Colors.grey,
                                                  fontWeight: FontWeight.w600,
                                                  decoration: isActive
                                                      ? null
                                                      : TextDecoration
                                                            .lineThrough,
                                                ),
                                              ),
                                            ),
                                            _chip(
                                              rol.toUpperCase(),
                                              _rolColor(rol),
                                            ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          email,
                                          style: TextStyle(
                                            color: isActive
                                                ? Theme.of(context).colorScheme.onSurfaceVariant
                                                : Colors.grey,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit,
                                                size: 20,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                              tooltip: 'Editar',
                                              onPressed: () =>
                                                  _showEditDialog(u),
                                            ),
                                            isToggling
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              AppColors.primary,
                                                        ),
                                                  )
                                                : IconButton(
                                                    icon: Icon(
                                                      isActive
                                                          ? Icons.block
                                                          : Icons.check_circle,
                                                      color: isActive
                                                          ? AppColors.danger
                                                          : AppColors.success,
                                                    ),
                                                    tooltip: isActive
                                                        ? 'Desactivar'
                                                        : 'Activar',
                                                    onPressed: () =>
                                                        _toggleUsuario(
                                                          id,
                                                          nombre,
                                                          isActive,
                                                        ),
                                                  ),
                                          ],
                                        ),
                                        onTap: () => _verDetalle(u),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Color _rolColor(String rol) {
    switch (rol) {
      case 'admin':
        return AppColors.danger;
      case 'proveedor':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.lg,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
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
}

class _UserDetailSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  const _UserDetailSheet({
    required this.user,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  State<_UserDetailSheet> createState() => _UserDetailSheetState();
}

class _UserDetailSheetState extends State<_UserDetailSheet> {
  bool _loadingSub = false;

  @override
  void initState() {
    super.initState();
    if (widget.user['rol'] == 'proveedor') {
      _loadSub();
    }
  }

  Future<void> _loadSub() async {
    setState(() => _loadingSub = true);
    await context.read<AdminProvider>().cargarSuscripcionesAdmin();
    if (mounted) {
      setState(() => _loadingSub = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final id = user['id']?.toString() ?? '';
    final email = user['email'] as String? ?? '';
    final nombre = '${user['nombre'] ?? ''} ${user['apellido'] ?? ''}'.trim();
    final rol = user['rol'] as String? ?? 'cliente';
    final telefono = user['telefono'] as String? ?? '';
    final isActive = user['is_active'] as bool? ?? true;
    final verificado =
        (user['is_verified'] ?? user['email_verificado']) as bool? ?? false;
    final rating = (user['avg_rating'] as num?)?.toDouble() ?? 0.0;
    final createdAt = user['created_at'] as String? ?? '';

    final adminProvider = context.watch<AdminProvider>();
    final Map<String, dynamic>? sub = (rol == 'proveedor' && !_loadingSub)
        ? adminProvider.suscripciones.cast<Map<String, dynamic>>().firstWhere(
            (s) => s['usuario_id']?.toString() == id,
            orElse: () => <String, dynamic>{},
          )
        : null;

    final hasSub = sub != null && sub.isNotEmpty;

    final Color roleColor = switch (rol) {
      'admin' => AppColors.danger,
      'proveedor' => AppColors.success,
      _ => AppColors.primary,
    };

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: roleColor.withOpacity(0.15),
                      child: Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 32,
                          color: roleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nombre,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  
                  // Información General
                  _buildSectionTitle('Información General'),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _detailRow(Icons.badge_outlined, 'ID', id.length > 12 ? '${id.substring(0, 12)}...' : id),
                          const Divider(height: 24),
                          _detailRow(Icons.shield_outlined, 'Rol', rol.toUpperCase(), valueColor: roleColor),
                          if (telefono.isNotEmpty) ...[
                            const Divider(height: 24),
                            _detailRow(Icons.phone_outlined, 'Teléfono', telefono),
                          ],
                          const Divider(height: 24),
                          _detailRow(Icons.verified_user_outlined, 'Verificado', verificado ? 'Sí' : 'No', 
                            valueColor: verificado ? AppColors.success : Theme.of(context).colorScheme.onSurfaceVariant),
                          if (rol == 'proveedor') ...[
                            const Divider(height: 24),
                            _detailRow(Icons.star_outline, 'Rating', rating.toStringAsFixed(1)),
                          ],
                          const Divider(height: 24),
                          _detailRow(Icons.calendar_today_outlined, 'Registro', _formatFecha(createdAt)),
                        ],
                      ),
                    ),
                  ),

                  // Suscripción (Solo para proveedores)
                  if (rol == 'proveedor') ...[
                    const SizedBox(height: 24),
                    _buildSectionTitle('Suscripción'),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _loadingSub
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (hasSub) ...[
                                    _detailRow(Icons.card_membership, 'Plan', sub['plan_nombre']?.toString().toUpperCase() ?? 'DESCONOCIDO'),
                                    const Divider(height: 24),
                                    _detailRow(
                                      Icons.info_outline, 
                                      'Estado', 
                                      sub['status']?.toString() ?? 'DESCONOCIDO',
                                      valueColor: sub['status']?.toString().toUpperCase() == 'ACTIVA' ? AppColors.success : AppColors.danger,
                                    ),
                                    const Divider(height: 24),
                                    _detailRow(Icons.date_range, 'Inicio', _formatFecha(sub['fecha_inicio']?.toString() ?? '')),
                                  ] else ...[
                                    const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: AppColors.secondary),
                                        SizedBox(width: 8),
                                        Text('El proveedor no tiene ninguna suscripción.'),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: Icon(Icons.settings),
                                      label: const Text('Gestionar Suscripción'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: const BorderSide(color: AppColors.primary),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        context.go('/admin/suscripciones');
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.edit),
                          label: const Text('Editar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                          ),
                          onPressed: widget.onEdit,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(isActive ? Icons.block : Icons.check_circle),
                          label: Text(isActive ? 'Desactivar' : 'Activar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (isActive ? AppColors.danger : AppColors.success).withOpacity(0.12),
                            foregroundColor: isActive ? AppColors.danger : AppColors.success,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
                          ),
                          onPressed: widget.onToggle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

Widget _field(BuildContext context, {
  required TextEditingController controller,
  required String label,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
}) {
  return TextField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: const BorderSide(color: AppColors.ink, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

Widget _dropdown<T>(BuildContext context, {
  required T? value,
  required String label,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
  String? hint,
}) {
  return DropdownButtonFormField<T?>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.sm),
        borderSide: const BorderSide(color: AppColors.ink, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    hint: hint != null
        ? Text(hint, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
        : null,
    items: items,
    onChanged: onChanged,
  );
}
