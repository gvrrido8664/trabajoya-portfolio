import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';

class ConversacionesScreen extends StatefulWidget {
  const ConversacionesScreen({super.key});

  @override
  State<ConversacionesScreen> createState() => _ConversacionesScreenState();
}

class _ConversacionesScreenState extends State<ConversacionesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().cargarConversaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Chats')),
          body: _buildBody(chat),
        );
      },
    );
  }

  Widget _buildBody(ChatProvider chat) {
    if (chat.loading && chat.conversaciones.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chat.conversaciones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes conversaciones',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Cuando contactes o te contacten por un servicio, apareceran aqui.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => chat.cargarConversaciones(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chat.conversaciones.length,
        separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final conv = chat.conversaciones[index];
          final contratacionId =
              conv['contratacion_id']?.toString() ??
              conv['id']?.toString() ??
              '';
          final otroNombre =
              conv['otro_usuario_nombre'] as String? ?? 'Usuario';
          final otroUsuario =
              conv['otro_usuario'] as Map<String, dynamic>? ?? {};
          final otroAvatar = otroUsuario['avatar_url'] as String?;
          final lastMsg = conv['ultimo_mensaje'] as String? ?? '';
          final lastTime = conv['ultimo_mensaje_fecha'] as String?;
          final unread = conv['no_leidos'] as int? ?? 0;

          DateTime? lastDate;
          if (lastTime != null) {
            try {
              lastDate = DateTime.parse(lastTime);
            } catch (_) {}
          }

          return ListTile(
            leading: CircleAvatar(
              radius: 26,
              backgroundImage: otroAvatar != null
                  ? NetworkImage(otroAvatar)
                  : null,
              child: otroAvatar == null
                  ? Text(
                      otroNombre != 'Usuario' && otroNombre.isNotEmpty
                          ? otroNombre[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            title: Text(
              otroNombre,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unread > 0 ? Colors.black87 : Colors.grey,
                fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastDate != null)
                  Text(
                    _formatDate(lastDate),
                    style: TextStyle(
                      fontSize: 12,
                      color: unread > 0
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      fontWeight: unread > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                if (unread > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(Radii.md),
                    ),
                    child: Text(
                      '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () => context.push('/chat/$contratacionId'),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return '${diff.inMinutes} min';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(date);
    if (diff.inDays < 7) {
      final days = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
      return days[date.weekday - 1];
    }
    return DateFormat('dd/MM/yy').format(date);
  }
}
