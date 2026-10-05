import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class AdminUsuariosScreen extends StatefulWidget {
  const AdminUsuariosScreen({super.key});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarUsuarios();
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
          backgroundColor: currentActive ? AppTheme.danger : AppTheme.success,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar usuario'),
            backgroundColor: AppTheme.danger,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          title: const Text('Crear usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(labelText: 'Contraseña *'),
                  obscureText: true,
                ),
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre *'),
                ),
                TextField(
                  controller: apellidoCtrl,
                  decoration: const InputDecoration(labelText: 'Apellido *'),
                ),
                TextField(
                  controller: telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                    DropdownMenuItem(
                      value: 'proveedor',
                      child: Text('Proveedor'),
                    ),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setDialogState(() => rol = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
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
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
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
          title: const Text('Editar usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: apellidoCtrl,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                ),
                TextField(
                  controller: telefonoCtrl,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: rol,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: const [
                    DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                    DropdownMenuItem(
                      value: 'proveedor',
                      child: Text('Proveedor'),
                    ),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setDialogState(() => rol = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
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
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppTheme.danger,
                            ),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar por email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(Radii.md),
                      ),
                    ),
                    onChanged: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _rolFilter,
                  hint: const Text('Rol'),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Todos')),
                    DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                    DropdownMenuItem(
                      value: 'proveedor',
                      child: Text('Proveedor'),
                    ),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) {
                    setState(() => _rolFilter = v);
                    _search();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: admin.loading && admin.usuarios.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : admin.usuarios.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No se encontraron usuarios',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: admin.usuarios.length,
                    itemBuilder: (context, index) {
                      final u = admin.usuarios[index];
                      final id = u['id']?.toString() ?? '';
                      final email = u['email'] as String? ?? '';
                      final nombre =
                          '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
                      final rol = u['rol'] as String? ?? 'cliente';
                      final isActive = u['is_active'] as bool? ?? true;
                      final isToggling = _toggling.contains(id);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? _rolColor(rol).withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            child: Text(
                              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: isActive ? _rolColor(rol) : Colors.grey,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  nombre.isNotEmpty ? nombre : 'Sin nombre',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? null : Colors.grey,
                                    decoration: isActive
                                        ? null
                                        : TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  rol.toUpperCase(),
                                  style: const TextStyle(fontSize: 10),
                                ),
                                visualDensity: VisualDensity.compact,
                                backgroundColor: _rolColor(
                                  rol,
                                ).withValues(alpha: 0.15),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            email,
                            style: TextStyle(
                              color: isActive ? null : Colors.grey,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: 'Editar',
                                onPressed: () => _showEditDialog(u),
                              ),
                              isToggling
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(
                                        isActive
                                            ? Icons.block
                                            : Icons.check_circle,
                                        color: isActive
                                            ? AppTheme.danger
                                            : AppTheme.success,
                                      ),
                                      tooltip: isActive
                                          ? 'Desactivar'
                                          : 'Activar',
                                      onPressed: () =>
                                          _toggleUsuario(id, nombre, isActive),
                                    ),
                            ],
                          ),
                          onTap: () => _verDetalle(u),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _rolColor(String rol) {
    switch (rol) {
      case 'admin':
        return AppTheme.danger;
      case 'proveedor':
        return AppTheme.secondary;
      default:
        return AppTheme.primary;
    }
  }
}

class _UserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _UserDetailSheet({
    required this.user,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final id = user['id']?.toString() ?? '';
    final email = user['email'] as String? ?? '';
    final nombre = '${user['nombre'] ?? ''} ${user['apellido'] ?? ''}'.trim();
    final rol = user['rol'] as String? ?? 'cliente';
    final telefono = user['telefono'] as String? ?? '';
    final isActive = user['is_active'] as bool? ?? true;
    final verificado = user['email_verificado'] as bool? ?? false;
    final rating = (user['avg_rating'] as num?)?.toDouble() ?? 0.0;
    final createdAt = user['created_at'] as String? ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: scrollCtrl,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: _rolColor(rol).withValues(alpha: 0.15),
              child: Text(
                nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                style: TextStyle(fontSize: 28, color: _rolColor(rol)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              nombre,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              email,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _detailRow('ID', id.length > 12 ? '${id.substring(0, 12)}...' : id),
            _detailRow('Rol', rol.toUpperCase()),
            if (telefono.isNotEmpty) _detailRow('Telefono', telefono),
            _detailRow('Rating', rating.toStringAsFixed(1)),
            _detailRow('Verificado', verificado ? 'Si' : 'No'),
            _detailRow('Registro', _formatFecha(createdAt)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onEdit,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(isActive ? Icons.block : Icons.check_circle),
                    label: Text(isActive ? 'Desactivar' : 'Activar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? AppTheme.danger
                          : AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onToggle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    ),
  );

  Color _rolColor(String rol) {
    switch (rol) {
      case 'admin':
        return AppTheme.danger;
      case 'proveedor':
        return AppTheme.secondary;
      default:
        return AppTheme.primary;
    }
  }

  String _formatFecha(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
