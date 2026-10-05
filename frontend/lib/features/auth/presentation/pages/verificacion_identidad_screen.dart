import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/auth/presentation/widgets/auth_ui.dart';
import 'package:trabajoya_app/shared/theme/ticket_border.dart';
import 'package:trabajoya_app/utils/colors.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/eyebrow.dart';
import 'package:trabajoya_app/shared/widgets/ticket_card.dart';

/// Verificación de identidad (Fase 3): el usuario sube selfie + documento, que
/// quedan en revisión manual del admin. Muestra el estado actual.
class VerificacionIdentidadScreen extends StatefulWidget {
  const VerificacionIdentidadScreen({super.key});

  @override
  State<VerificacionIdentidadScreen> createState() =>
      _VerificacionIdentidadScreenState();
}

class _VerificacionIdentidadScreenState
    extends State<VerificacionIdentidadScreen> {
  final _picker = ImagePicker();
  XFile? _selfie;
  XFile? _documento;
  Uint8List? _selfieBytes;
  Uint8List? _docBytes;
  bool _sending = false;

  Future<void> _pick(bool selfie) async {
    // Sin try/catch: si el navegador deniega el permiso de cámara,
    // pickImage() lanza (no devuelve null) y quedaba sin ningún aviso
    // (EDGE-12) -- el botón parecía no hacer nada.
    XFile? x;
    try {
      x = await _picker.pickImage(
        source: selfie ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selfie
                  ? 'No se pudo acceder a la cámara. Revisa los permisos del navegador.'
                  : 'No se pudo acceder a los archivos: ${formatError(e)}',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() {
        if (selfie) {
          _selfie = x;
          _selfieBytes = bytes;
        } else {
          _documento = x;
          _docBytes = bytes;
        }
      });
    }
  }

  void _showImagePreview(String title, Uint8List bytes) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    tooltip: 'Cerrar',
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                top: 45,
                left: 20,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        );
      },
    );
  }

  Future<void> _enviar() async {
    if (_selfie == null || _documento == null) return;
    setState(() => _sending = true);
    try {
      final sb = _selfieBytes ?? await _selfie!.readAsBytes();
      final db = _docBytes ?? await _documento!.readAsBytes();
      await ApiClient().uploadDocumentos(
        selfieBytes: sb,
        selfieName: _selfie!.name,
        selfieType: _selfie!.mimeType ?? 'image/jpeg',
        docBytes: db,
        docName: _documento!.name,
        docType: _documento!.mimeType ?? 'image/jpeg',
      );
      if (!mounted) return;
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documentos enviados. Quedan en revisión.'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        _selfie = null;
        _selfieBytes = null;
        _documento = null;
        _docBytes = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar: ${formatError(e)}'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AuthProvider>().usuario?.docEstado ?? 'none';

    return AuthScaffold(
      maxWidth: 480,
      onHome: () => context.go('/'),
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/cliente');
        }
      },
      child: AuthPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Eyebrow(label: 'Verificación de identidad'),
            ),
            const SizedBox(height: Spacing.xl),
            _buildBody(estado),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String estado) {
    if (estado == 'approved') {
      return _statusCard(
        Icons.verified,
        AppColors.success,
        'Identidad verificada',
        'Tu identidad fue aprobada. Ya cuentas con la insignia de verificado.',
      );
    }
    if (estado == 'pending') {
      return _statusCard(
        Icons.hourglass_top,
        AppColors.secondary,
        'En revisión',
        'Recibimos tus documentos. Un administrador los revisará pronto.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (estado == 'rejected')
          _statusCard(
            Icons.error_outline,
            AppColors.danger,
            'Rechazada',
            'Tu verificación anterior fue rechazada. Vuelve a enviar fotos claras.',
          ),
        const SizedBox(height: 8),
        Text(
          'Sube una selfie y una foto de tu documento de identidad (cédula o pasaporte). '
          'Se usan solo para verificar tu identidad y se guardan de forma privada.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        _pickTile(
          'Selfie',
          _selfie,
          _selfieBytes,
          () => _pick(true),
          Icons.camera_alt_outlined,
        ),
        const SizedBox(height: 12),
        _pickTile(
          'Documento de identidad',
          _documento,
          _docBytes,
          () => _pick(false),
          Icons.badge_outlined,
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: (_selfie != null && _documento != null && !_sending)
                ? _enviar
                : null,
            child: _sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enviar para revisión'),
          ),
        ),
      ],
    );
  }

  Widget _pickTile(
    String label,
    XFile? file,
    Uint8List? bytes,
    VoidCallback onTap,
    IconData icon,
  ) {
    return TicketCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: TicketBorder(
        marks: false,
        line: file != null ? AppColors.verified : AppColors.line,
        ink: AppColors.ink,
      ),
      child: Row(
        children: [
          Icon(
            file != null ? Icons.check_circle : icon,
            color: file != null
                ? AppColors.success
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              file != null ? '$label · Listo' : 'Agregar $label',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: file != null ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (file != null && bytes != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showImagePreview(label, bytes),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Container(
                  width: 44,
                  height: 44,
                  color: Colors.grey.shade200,
                  child: Image.memory(bytes, fit: BoxFit.cover),
                ),
              ),
            ),
          ] else
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        ],
      ),
    );
  }

  Widget _statusCard(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
