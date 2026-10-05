import 'package:flutter/material.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  bool _loading = false;
  List<dynamic> _resenas = [];

  @override
  void initState() {
    super.initState();
    _loadResenas();
  }

  Future<void> _loadResenas() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient().get('/resenas/admin');
      setState(() => _resenas = res as List<dynamic>);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildStars(int calificacion) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < calificacion ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Feedback y Reseñas', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
            tooltip: 'Actualizar',
            onPressed: _loadResenas,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _resenas.isEmpty
              ? Center(child: Text('No hay reseñas registradas', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)))
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _resenas.length,
                  itemBuilder: (context, index) {
                    final resena = _resenas[index];
                    final contratacionId = resena['contratacion_id'] ?? '';
                    final calificacion = resena['calificacion'] as int? ?? 0;
                    final comentario = resena['comentario'] ?? '';
                    final fecha = resena['created_at'] != null 
                        ? resena['created_at'].toString().split('T')[0]
                        : '';
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: Theme.of(context).dividerColor)),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStars(calificacion),
                                Text(fecha, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comentario.isEmpty ? 'Sin comentario' : comentario,
                              style: TextStyle(
                                color: comentario.isEmpty ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
                                fontStyle: comentario.isEmpty ? FontStyle.italic : FontStyle.normal,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(Radii.sm),
                              ),
                              child: Text('ID Contratación: $contratacionId', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
