import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';

class AvatarEditor extends StatefulWidget {
  final String? avatarUrl;
  final double radius;
  
  const AvatarEditor({
    super.key,
    this.avatarUrl,
    this.radius = 56.0,
  });

  @override
  State<AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<AvatarEditor> {
  bool _uploading = false;
  final _picker = ImagePicker();

  Future<void> _pickAndUpload() async {
    try {
      final xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (xFile == null) return;

      setState(() => _uploading = true);
      
      final bytes = await xFile.readAsBytes();
      final mimeType = xFile.mimeType ?? 'image/jpeg';
      
      await ApiClient().uploadAvatar(
        fileBytes: bytes,
        fileName: xFile.name,
        fileType: mimeType,
      );
      
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        await context.read<AuthProvider>().refreshUser();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir foto: ${formatError(e)}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: widget.radius * 2,
          height: widget.radius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 6),
            color: AppColors.background,
          ),
          child: ClipOval(
            child: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                ? Image.network(
                    widget.avatarUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, _, __) => const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.textLight,
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.textLight,
                  ),
          ),
        ),
        if (_uploading)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
          ),
        Positioned(
          bottom: 4,
          right: 4,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 2),
            ),
            elevation: 2,
            child: InkWell(
              onTap: _uploading ? null : _pickAndUpload,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.photo_camera,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
