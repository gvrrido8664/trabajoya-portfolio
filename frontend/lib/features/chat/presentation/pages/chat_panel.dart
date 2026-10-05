import 'dart:async';
import 'package:trabajoya_app/shared/theme/tokens.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/core/api/api_client.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/chat/data/models/mensaje_model.dart';
import 'package:trabajoya_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:trabajoya_app/utils/colors.dart';

const _emojis = [
  '😀',
  '😃',
  '😄',
  '😁',
  '😅',
  '😂',
  '🤣',
  '😊',
  '😇',
  '🙂',
  '😉',
  '😌',
  '😍',
  '🥰',
  '😘',
  '😗',
  '😙',
  '😚',
  '😋',
  '😛',
  '😜',
  '🤪',
  '😝',
  '🤑',
  '🤗',
  '🤭',
  '🤫',
  '🤔',
  '🤐',
  '🤨',
  '😐',
  '😑',
  '😶',
  '😏',
  '😒',
  '🙄',
  '😬',
  '😮',
  '😯',
  '😲',
  '😳',
  '🥺',
  '😢',
  '😭',
  '😤',
  '😡',
  '🤬',
  '😈',
  '👿',
  '💀',
  '☠️',
  '💩',
  '🤡',
  '👹',
  '👺',
  '👻',
  '👽',
  '👾',
  '🤖',
  '🎃',
  '👍',
  '👎',
  '👊',
  '✊',
  '🤛',
  '🤜',
  '👏',
  '🙌',
  '👐',
  '🤲',
  '🤝',
  '🙏',
  '✌️',
  '🤞',
  '🤟',
  '🤘',
  '🤙',
  '👈',
  '👉',
  '👆',
  '❤️',
  '🧡',
  '💛',
  '💚',
  '💙',
  '💜',
  '🖤',
  '🤍',
  '🤎',
  '💔',
  '🔥',
  '✨',
  '⭐',
  '🌟',
  '💫',
  '🎉',
  '🎊',
  '🎈',
  '🎁',
  '🏆',
  '💰',
  '💎',
  '🔔',
  '📢',
  '📣',
  '💬',
  '🗨️',
  '🗯️',
  '💭',
  '🕐',
];

class ChatPanel extends StatefulWidget {
  final String contratacionId;
  final VoidCallback? onBack;
  final bool embedded;

  const ChatPanel({
    super.key,
    required this.contratacionId,
    this.onBack,
    this.embedded = false,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  bool _sending = false;
  bool _uploading = false;
  ChatProvider? _chat;
  Timer? _pollTimer;
  Timer? _convTimer;

  bool _inputFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _inputFocused = _focusNode.hasFocus;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final chat = context.read<ChatProvider>();
      final auth = context.read<AuthProvider>();
      _chat = chat;
      if (auth.usuario?.id != null && auth.usuario!.id.isNotEmpty) {
        chat.currentUserId = auth.usuario!.id;
      }
      final token = await ApiClient().token;
      if (token != null) {
        try {
          await chat.connectToChat(widget.contratacionId, token);
        } catch (e) {
          debugPrint('ChatPanel connection failed: $e');
        }
      }
      if (!mounted) return;
      context.read<AuthProvider>().addListener(_onAuthChanged);

      await chat.cargarConversaciones();
      await chat.marcarLeidos(widget.contratacionId);
      await chat.cargarMensajes(widget.contratacionId, reset: true);

      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) {
          _pollTimer?.cancel();
          return;
        }
        context.read<ChatProvider>().pollMensajes(widget.contratacionId);
      });
      _convTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (!mounted) {
          _convTimer?.cancel();
          return;
        }
        context.read<ChatProvider>().cargarConversaciones();
      });

      _scrollCtrl.addListener(() {
        if (!_scrollCtrl.hasClients) return;
        final pos = _scrollCtrl.position;
        if (pos.pixels >= pos.maxScrollExtent - 100) {
          chat.cargarMasMensajes(widget.contratacionId);
        }
      });
    });
  }

  @override
  void didUpdateWidget(ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contratacionId != widget.contratacionId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final chat = context.read<ChatProvider>();
        final token = await ApiClient().token;
        if (token != null) {
          chat.disconnectFromChat();
          try {
            await chat.connectToChat(widget.contratacionId, token);
          } catch (e) {
            debugPrint('ChatPanel connection on update failed: $e');
          }
        }
        await chat.cargarConversaciones();
        await chat.marcarLeidos(widget.contratacionId);
        await chat.cargarMensajes(widget.contratacionId, reset: true);
      });
    }
  }

  void _onAuthChanged() {
    final auth = context.read<AuthProvider>();
    if (auth.usuario?.id != null && auth.usuario!.id.isNotEmpty) {
      final chat = context.read<ChatProvider>();
      chat.currentUserId = auth.usuario!.id;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _convTimer?.cancel();
    try {
      context.read<AuthProvider>().removeListener(_onAuthChanged);
    } catch (_) {}
    _chat?.disconnectFromChat();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getOtroInfo(
    ChatProvider chat,
    String miRol,
    String miId,
  ) {
    // Buscar la conversación exacta en la lista
    Map<String, dynamic>? foundOtro;
    for (final conv in chat.conversaciones) {
      final id = (conv['contratacion_id'] ?? conv['id']).toString();
      final otro = conv['otro_usuario'] as Map<String, dynamic>?;
      if (id == widget.contratacionId) {
        foundOtro = {
          'nombre': (conv['otro_usuario_nombre'] as String?) ?? 'Chat',
          'avatar':
              (otro?['avatar_url'] as String?) ??
              (conv['otro_usuario_avatar'] as String?),
          'isOnline':
              (otro?['is_online'] as bool?) ??
              (conv['otro_usuario_online'] as bool?) ??
              false,
          'rol':
              otro?['rol'] as String? ??
              (miRol.isEmpty
                  ? ''
                  : (miRol == 'cliente' ? 'proveedor' : 'cliente')),
        };
        break;
      }
    }

    // Si no se encontró la conversación exacta (dedup), extraer otro_id de los mensajes
    if (foundOtro == null) {
      String? otroId;
      for (final msg in chat.mensajes) {
        if (msg.emisorId.trim().toLowerCase() != miId) {
          otroId = msg.emisorId.trim().toLowerCase();
          break;
        }
      }
      // Buscar en la lista de conversaciones por otro_id
      if (otroId != null) {
        for (final conv in chat.conversaciones) {
          final otro = conv['otro_usuario'] as Map<String, dynamic>?;
          final otroConvId = (otro?['id'] as String?)?.trim().toLowerCase();
          if (otroConvId == otroId) {
            foundOtro = {
              'nombre': (conv['otro_usuario_nombre'] as String?) ?? 'Chat',
              'avatar':
                  (otro?['avatar_url'] as String?) ??
                  (conv['otro_usuario_avatar'] as String?),
              'isOnline':
                  (otro?['is_online'] as bool?) ??
                  (conv['otro_usuario_online'] as bool?) ??
                  false,
              'rol':
                  otro?['rol'] as String? ??
                  (miRol.isEmpty
                      ? ''
                      : (miRol == 'cliente' ? 'proveedor' : 'cliente')),
            };
            break;
          }
        }
      }
    }

    if (foundOtro != null) return foundOtro;

    // Último recurso: inferir por el rol propio
    return {
      'nombre': 'Chat',
      'avatar': null,
      'isOnline': false,
      'rol': miRol.isEmpty
          ? ''
          : (miRol == 'cliente' ? 'proveedor' : 'cliente'),
    };
  }

  void _insertEmoji(String emoji) {
    final idx = _msgCtrl.selection.baseOffset;
    if (idx < 0) {
      _msgCtrl.text += emoji;
    } else {
      final text = _msgCtrl.text;
      _msgCtrl.text = '${text.substring(0, idx)}$emoji${text.substring(idx)}';
      _msgCtrl.selection = TextSelection.collapsed(offset: idx + emoji.length);
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.md)),
      ),
      builder: (ctx) => Container(
        height: 320,
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Emojis',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Cerrar',
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: _emojis.length,
                itemBuilder: (_, i) => InkWell(
                  onTap: () {
                    _insertEmoji(_emojis[i]);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(Radii.sm),
                  child: Center(
                    child: Text(
                      _emojis[i],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendFile() async {
    final picker = ImagePicker();
    try {
      final xFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (xFile == null) return;
      await _uploadAndSend(xFile);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al seleccionar archivo'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _uploadAndSend(XFile xFile) async {
    setState(() => _uploading = true);
    try {
      final api = ApiClient();
      final bytes = await xFile.readAsBytes();
      final result = await api.uploadMultipartFromBytes(
        '/upload/chat',
        bytes: bytes,
        filename: xFile.name,
        contentType: xFile.mimeType ?? 'image/jpeg',
      );
      final url = result['url'] as String?;
      if (url == null) throw Exception('No se obtuvo URL');
      if (!mounted) return;

      final chat = context.read<ChatProvider>();
      final auth = context.read<AuthProvider>();
      final miId = auth.usuario?.id ?? '';

      // Always add locally first (optimistic)
      final localId = 'local_img_${DateTime.now().millisecondsSinceEpoch}';
      chat.addMensaje(
        Mensaje(
          id: localId,
          contratacionId: widget.contratacionId,
          emisorId: miId,
          contenido: url,
          leido: false,
          createdAt: DateTime.now(),
        ),
      );

      final ok = await chat.sendMessage(widget.contratacionId, url);
      if (mounted && !ok) {
        chat.removeMensaje(localId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo enviar la imagen. Revisa tu conexión e intenta de nuevo.',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar archivo: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    final chat = context.read<ChatProvider>();
    final auth = context.read<AuthProvider>();
    final miId = auth.usuario?.id;
    if (miId == null) {
      if (mounted) setState(() => _sending = false);
      return;
    }

    // Always add locally first (optimistic), regardless of send method.
    // WS echo or REST refetch will dedup via addMensaje near-dup check.
    final localId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    chat.addMensaje(
      Mensaje(
        id: localId,
        contratacionId: widget.contratacionId,
        emisorId: miId,
        contenido: text,
        leido: false,
        createdAt: DateTime.now(),
      ),
    );
    _msgCtrl.clear();
    if (mounted) {
      setState(() {}); // Forzar rebuild inmediato para mostrar la burbuja
    }

    // sendMessage NO lanza: devuelve false si falla (ej. sin conexión).
    final ok = await chat.sendMessage(widget.contratacionId, text);
    if (!mounted) return;
    if (!ok) {
      // Revertir la burbuja optimista y devolver el texto para reintentar,
      // así no queda un mensaje que parece enviado pero nunca llegó.
      chat.removeMensaje(localId);
      _msgCtrl.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo enviar. Revisa tu conexión e intenta de nuevo.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final chat = context.watch<ChatProvider>();
    final miId = (auth.usuario?.id ?? chat.currentUserId).trim().toLowerCase();
    final miRol = (auth.usuario?.rol ?? '').toLowerCase();

    final otro = _getOtroInfo(chat, miRol, miId);
    final nombre = otro['nombre'] as String;
    final avatar = otro['avatar'] as String?;
    final isOnline = otro['isOnline'] as bool;
    final rolOtro = otro['rol'] as String;

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.fromLTRB(
            12,
            widget.embedded ? 14 : MediaQuery.of(context).padding.top + 6,
            16,
            14,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border),
            ),
          ),
          child: Row(
            children: [
              if (widget.onBack != null)
                IconButton(
                  tooltip: 'Volver',
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  onPressed: widget.onBack,
                )
              else if (!widget.embedded)
                const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.sidebarBottom,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null
                    ? Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isOnline ? AppColors.verified : AppColors.inkSoft,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'En línea' : 'Desconectado',
                        style: TextStyle(
                          color: isOnline ? AppColors.verified : AppColors.inkSoft,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        // Messages Area
        Expanded(
          child: Container(
            color: AppColors.background,
            child: chat.mensajes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum_outlined,
                          size: 44,
                          color: AppColors.inkSoft.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Sin mensajes aún',
                          style: TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    itemCount: chat.mensajes.length,
                    itemBuilder: (context, index) {
                      final msg = chat.mensajes[index];
                      final isMine = msg.emisorId.trim().toLowerCase() == miId;
                      return _ChatBubble(msg: msg, isMine: isMine);
                    },
                  ),
          ),
        ),
        // Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.border),
            ),
          ),
          child: SafeArea(
            top: false,
            child: _uploading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Subiendo archivo...',
                          style: TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(Radii.pill),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _msgCtrl,
                                  focusNode: _focusNode,
                                  textCapitalization: TextCapitalization.sentences,
                                  maxLines: 4,
                                  minLines: 1,
                                  style: const TextStyle(fontSize: 14),
                                  onSubmitted: (_) => _sendMessage(),
                                  decoration: const InputDecoration(
                                    hintText: 'Escribe un mensaje...',
                                    hintStyle: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'Emojis',
                                icon: const Icon(Icons.emoji_emotions_outlined, color: AppColors.inkSoft, size: 20),
                                onPressed: _showEmojiPicker,
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                                tooltip: 'Adjuntar archivo / imagen',
                                icon: const Icon(Icons.attach_file, color: AppColors.ink, size: 22),
                                onPressed: _pickAndSendFile,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _sending ? null : _sendMessage,
                        borderRadius: BorderRadius.circular(Radii.pill),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.rust,
                            shape: BoxShape.circle,
                          ),
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(11),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final Mensaje msg;
  final bool isMine;
  const _ChatBubble({required this.msg, required this.isMine});

  static final _imageExtRe = RegExp(
    r'\.(jpg|jpeg|png|gif|webp|avif|bmp|svg|heic|heif)([?#]|$)',
    caseSensitive: false,
  );
  static final _imageCdnRe = RegExp(
    r'(supabase|storage\.googleapis|s3\.amazonaws|cloudinary|imgix|bunnycdn|imagekit)',
    caseSensitive: false,
  );

  bool get _isImage {
    final c = msg.contenido;
    if (!c.startsWith('http')) return false;
    return _imageExtRe.hasMatch(c) || _imageCdnRe.hasMatch(c);
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    try {
      return DateFormat('HH:mm').format(local);
    } catch (_) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(msg.createdAt);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width > 700 ? 420 : 280,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.sidebarBottom
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(Radii.md),
            topRight: const Radius.circular(Radii.md),
            bottomLeft: Radius.circular(isMine ? Radii.md : 2),
            bottomRight: Radius.circular(isMine ? 2 : Radii.md),
          ),
          border: isMine
              ? null
              : Border.all(color: AppColors.border),
          boxShadow: isMine
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 260,
                    minHeight: 80,
                  ),
                  child: Image.network(
                    msg.contenido,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    semanticLabel: 'Imagen adjunta en el chat',
                    loadingBuilder: (_, child, progress) => progress != null
                        ? const SizedBox(
                            height: 120,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : child,
                    errorBuilder: (_, _, _) => Text(
                      msg.contenido,
                      style: TextStyle(
                        height: 1.4,
                        color: isMine ? Colors.white : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              )
            else
              Text(
                msg.contenido,
                style: TextStyle(
                  height: 1.4,
                  fontSize: 14,
                  color: isMine ? Colors.white : AppColors.ink,
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine ? Colors.white.withValues(alpha: 0.7) : AppColors.inkSoft,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.leido ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 13,
                    color: msg.leido ? AppColors.verified : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
