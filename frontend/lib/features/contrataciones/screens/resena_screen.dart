import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/contrataciones/providers/contrataciones_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class ResenaScreen extends StatefulWidget {
  final String contratacionId;

  const ResenaScreen({super.key, required this.contratacionId});

  @override
  State<ResenaScreen> createState() => _ResenaScreenState();
}

class _ResenaScreenState extends State<ResenaScreen> {
  final _comentarioCtrl = TextEditingController();
  int _puntuacion = 0;
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dejar Rese\u00f1a')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const Text(
              '\u00bfQu\u00e9 tal fue tu experiencia?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu rese\u00f1a ayuda a otros usuarios',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return GestureDetector(
                  onTap: () => setState(() => _puntuacion = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      star <= _puntuacion ? Icons.star : Icons.star_border,
                      size: 48,
                      color: star <= _puntuacion
                          ? AppColors.secondary
                          : Colors.grey[400],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _puntuacion > 0
                  ? '$_puntuacion / 5'
                  : 'Selecciona una puntuaci\u00f3n',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _puntuacion > 0
                    ? AppColors.secondary
                    : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _comentarioCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Cu\u00e9ntanos m\u00e1s sobre tu experiencia...',
                alignLabelWithHint: true,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Radii.md),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _puntuacion == 0 || _enviando ? null : _enviar,
                icon: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.star),
                label: Text(_enviando ? 'Enviando...' : 'Enviar Rese\u00f1a'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);

    final provider = context.read<ContratacionesProvider>();
    final exito = await provider.crearResena(
      contratacionId: widget.contratacionId,
      puntuacion: _puntuacion,
      comentario: _comentarioCtrl.text.trim().isNotEmpty
          ? _comentarioCtrl.text.trim()
          : null,
    );

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rese\u00f1a enviada, \u00a1gracias!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error al enviar rese\u00f1a'),
          backgroundColor: AppColors.danger,
        ),
      );
    }

    setState(() => _enviando = false);
  }
}
