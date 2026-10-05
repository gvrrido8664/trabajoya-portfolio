import 'package:flutter/material.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/contrataciones/data/datasources/contrataciones_remote_datasource.dart';

class ResenaScreen extends StatefulWidget {
  final String contratacionId;
  final ContratacionesService? service; // inyectable para tests
  const ResenaScreen({super.key, required this.contratacionId, this.service});

  @override
  State<ResenaScreen> createState() => _ResenaScreenState();
}

class _ResenaScreenState extends State<ResenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioCtrl = TextEditingController();
  late final ContratacionesService _service;
  int _puntuacion = 5;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ContratacionesService();
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.crearResena(
        widget.contratacionId,
        _puntuacion,
        comentario: _comentarioCtrl.text.trim().isNotEmpty
            ? _comentarioCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reseña enviada')));
      // Devolver true para indicar que se creó una reseña
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(formatError(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dejar Resena')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Califica tu experiencia',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    tooltip: '${i + 1} estrella${i == 0 ? '' : 's'}',
                    icon: Icon(
                      i < _puntuacion ? Icons.star : Icons.star_border,
                      size: 44,
                      color: AppTheme.secondary,
                    ),
                    onPressed: () => setState(() => _puntuacion = i + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Text(
                '$_puntuacion / 5',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _comentarioCtrl,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  hintText: 'Cuentanos tu experiencia...',
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _enviar,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Enviar Resena'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
