import 'package:flutter/material.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

/// Revisión manual de verificaciones de identidad pendientes (admin).
class AdminVerificacionesScreen extends StatefulWidget {
  const AdminVerificacionesScreen({super.key});

  @override
  State<AdminVerificacionesScreen> createState() =>
      _AdminVerificacionesScreenState();
}

class _AdminVerificacionesScreenState extends State<AdminVerificacionesScreen> {
  final _api = ApiClient();
  List<dynamic> _items = [];
  bool _loading = true;
  String? _procesando;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  // LOGICA INTACTA
  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final r = await _api.get(
        '/admin/verificaciones',
        queryParams: {'estado': 'pending'},
      );

      // Aquí agregué un salvavidas: si tu backend usa 'data' en vez de 'items', lo atrapará igual.
      final list = (r is Map ? (r['items'] ?? r['data']) : r) as List? ?? [];

      setState(() => _items = list);
    } catch (e) {
      setState(() => _items = []);
    }
    if (mounted) setState(() => _loading = false);
  }

  // LOGICA INTACTA
  Future<void> _resolver(String id, bool aprobar) async {
    setState(() => _procesando = id);
    try {
      await _api.post(
        '/admin/verificaciones/$id/${aprobar ? 'aprobar' : 'rechazar'}',
        body: {},
      );
      setState(() => _items.removeWhere((x) => x['id'] == id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              aprobar ? 'Verificación aprobada' : 'Verificación rechazada',
            ),
            backgroundColor: aprobar ? AppColors.success : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Verificaciones pendientes',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w800,
            fontFamily: 'Manrope',
          ),
        ),
        shape: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
        actions: [
          IconButton(
            onPressed: _cargar,
            icon: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onSurface),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            )
          : _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No hay verificaciones pendientes',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Center(
              // Centra y limita el ancho máximo para que se vea bien en web/desktop también
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 24),
                  itemBuilder: (_, i) => _card(_items[i]),
                ),
              ),
            ),
    );
  }

  Widget _card(Map<String, dynamic> u) {
    final id = u['id'].toString();
    final procesando = _procesando == id;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(Radii.md),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del usuario
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${u['nombre']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${u['email']}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  '${u['rol']}'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: Theme.of(context).colorScheme.outline),
          ),

          // Sección de fotos
          Row(
            children: [
              Expanded(child: _foto('Selfie', u['selfie_url'] as String?)),
              const SizedBox(width: 16),
              Expanded(
                child: _foto('Documento', u['documento_url'] as String?),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: procesando ? null : () => _resolver(id, false),
                  style:
                      OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: AppColors.danger,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Radii.md),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.all(
                          AppColors.danger.withValues(alpha: 0.08),
                        ),
                      ),
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: AppColors.danger,
                  ),
                  label: const Text(
                    'Rechazar',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: procesando ? null : () => _resolver(id, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                  ),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text(
                    'Aprobar',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _foto(String label, String? url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: url == null ? null : () => _verFotoCompleta(url, label),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: Container(
                  height:
                      220, // Aumentamos la altura un poco para darle más aire a la foto
                  width: double.infinity,
                  decoration: BoxDecoration(
                    // Le damos un fondo oscuro (slate-900) para que el "espacio vacío" se vea como un marco de cine/galería
                    color: AppColors.ink,
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: url == null
                      ? const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white54,
                            size: 32,
                          ),
                        )
                      : Image.network(
                          url,
                          // CONTAIN: Asegura que la foto completa entre dentro del cuadro sin cortar NADA
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white54,
                              size: 32,
                            ),
                          ),
                        ),
                ),
              ),
              if (url != null)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(Radii.sm),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Ampliar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _verFotoCompleta(String url, String label) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // InteractiveViewer = zoom/pan; foto completa real
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      padding: const EdgeInsets.all(40),
                      color: Colors.black87,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.6),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
