import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/servicios/data/models/categoria_model.dart';
import 'package:trabajoya_app/services/servicios_service.dart';

class CrearEditarServicioScreen extends StatefulWidget {
  final String? servicioId;
  const CrearEditarServicioScreen({super.key, this.servicioId});

  @override
  State<CrearEditarServicioScreen> createState() =>
      _CrearEditarServicioScreenState();
}

class _CrearEditarServicioScreenState extends State<CrearEditarServicioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _precioMinCtrl = TextEditingController();
  final _precioMaxCtrl = TextEditingController();
  final _radioCtrl = TextEditingController(text: '10');
  final _direccionCtrl = TextEditingController();
  final ServiciosService _service = ServiciosService();
  String _categoriaId = '';
  List<Categoria> _categorias = [];
  bool _loading = false;
  bool _saving = false;
  bool get _isEditing => widget.servicioId != null;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    if (_isEditing) _cargarServicio();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _precioMinCtrl.dispose();
    _precioMaxCtrl.dispose();
    _radioCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCategorias() async {
    final apiClient = ApiClient();
    try {
      final resp = await apiClient.get('/categorias');
      List<dynamic> data = resp is List ? resp : (resp['items'] ?? []);
      setState(() {
        _categorias = data.map((e) => Categoria.fromJson(e)).toList();
        if (_categorias.isNotEmpty) _categoriaId = _categorias.first.id;
      });
    } catch (_) {}
  }

  Future<void> _cargarServicio() async {
    setState(() => _loading = true);
    try {
      final s = await _service.getServicio(widget.servicioId!);
      _tituloCtrl.text = s.titulo;
      _descCtrl.text = s.descripcion;
      if (s.precioMin != null) {
        _precioMinCtrl.text = s.precioMin!.toStringAsFixed(0);
      }
      if (s.precioMax != null) {
        _precioMaxCtrl.text = s.precioMax!.toStringAsFixed(0);
      }
      _radioCtrl.text = s.radioCoberturaKm.toString();
      _direccionCtrl.text = s.direccionTexto ?? '';
      _categoriaId = s.categoriaId;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await _service.actualizarServicio(widget.servicioId!, {
          'categoria_id': _categoriaId,
          'titulo': _tituloCtrl.text.trim(),
          'descripcion': _descCtrl.text.trim(),
          if (_precioMinCtrl.text.isNotEmpty)
            'precio_min': double.tryParse(_precioMinCtrl.text),
          if (_precioMaxCtrl.text.isNotEmpty)
            'precio_max': double.tryParse(_precioMaxCtrl.text),
          'radio_cobertura_km': int.tryParse(_radioCtrl.text) ?? 10,
          if (_direccionCtrl.text.isNotEmpty)
            'direccion_texto': _direccionCtrl.text.trim(),
        });
      } else {
        await _service.crearServicio(
          _categoriaId,
          _tituloCtrl.text.trim(),
          _descCtrl.text.trim(),
          precioMin: _precioMinCtrl.text.isNotEmpty
              ? double.tryParse(_precioMinCtrl.text)
              : null,
          precioMax: _precioMaxCtrl.text.isNotEmpty
              ? double.tryParse(_precioMaxCtrl.text)
              : null,
          radioKm: int.tryParse(_radioCtrl.text) ?? 10,
          direccion: _direccionCtrl.text.isNotEmpty
              ? _direccionCtrl.text.trim()
              : null,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Servicio actualizado' : 'Servicio creado',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Editar' : 'Crear')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Servicio' : 'Crear Servicio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _categoriaId.isNotEmpty ? _categoriaId : null,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: _categorias
                    .map(
                      (c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _categoriaId = v!),
                validator: (v) => v == null ? 'Selecciona una categoria' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(labelText: 'Titulo'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa un titulo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Descripcion'),
                maxLines: 4,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Ingresa una descripcion'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precioMinCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio Min',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _precioMaxCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Precio Max',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _radioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Radio de cobertura (km)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _direccionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Direccion (opcional)',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _guardar,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Guardar Cambios' : 'Crear Servicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
