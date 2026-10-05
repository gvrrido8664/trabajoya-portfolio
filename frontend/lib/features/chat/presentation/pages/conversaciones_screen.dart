import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:trabajoya_app/app/theme.dart';
import 'package:trabajoya_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:trabajoya_app/features/chat/presentation/providers/chat_provider.dart';
import 'package:trabajoya_app/features/chat/presentation/pages/chat_panel.dart';
import 'package:trabajoya_app/shared/theme/tokens.dart';
import 'package:trabajoya_app/shared/widgets/corner_border_container.dart';
import 'package:trabajoya_app/utils/colors.dart';

class ConversacionesScreen extends StatefulWidget {
  const ConversacionesScreen({super.key});

  @override
  State<ConversacionesScreen> createState() => _ConversacionesScreenState();
}

class _ConversacionesScreenState extends State<ConversacionesScreen> {
  String? _selectedContratacionId;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().cargarConversaciones();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatProv = context.watch<ChatProvider>();
    final authProv = context.watch<AuthProvider>();
    final miId = authProv.usuario?.id ?? '';

    final width = MediaQuery.of(context).size.width;
    final isWideScreen = width > 850;

    if (isWideScreen &&
        _selectedContratacionId == null &&
        chatProv.conversaciones.isNotEmpty) {
      final firstConv = chatProv.conversaciones.first;
      _selectedContratacionId =
          (firstConv['contratacion_id'] ?? firstConv['id']).toString();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: isWideScreen
              ? const EdgeInsets.all(Spacing.lg)
              : EdgeInsets.zero,
          child: isWideScreen
              ? CornerBorderContainer(
                  color: AppColors.border,
                  backgroundColor: Colors.white,
                  strokeWidth: 2,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 320,
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                          ),
                          child: _ConversationListPanel(
                            chatProv: chatProv,
                            miId: miId,
                            selectedContratacionId: _selectedContratacionId,
                            searchCtrl: _searchCtrl,
                            onChatSelected: (id) =>
                                setState(() => _selectedContratacionId = id),
                            isWideScreen: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _selectedContratacionId != null
                            ? ChatPanel(
                                key: ValueKey(_selectedContratacionId),
                                contratacionId: _selectedContratacionId!,
                                embedded: true,
                              )
                            : const Center(
                                child: Text(
                                  'Selecciona un chat para empezar',
                                  style: TextStyle(
                                    color: AppColors.inkSoft,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                )
              : _ConversationListPanel(
                  chatProv: chatProv,
                  miId: miId,
                  selectedContratacionId: null,
                  searchCtrl: _searchCtrl,
                  onChatSelected: (id) => context.push('/chat/$id'),
                  isWideScreen: false,
                ),
        ),
      ),
    );
  }
}

String _formatTimestamp(String? raw) {
  if (raw == null) return '';
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return '';
  final now = DateTime.now();
  if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (dt.year == yesterday.year &&
      dt.month == yesterday.month &&
      dt.day == yesterday.day) {
    return 'Ayer';
  }
  return '${dt.day}/${dt.month}';
}

String _formatUltimoMensaje(String? raw) {
  if (raw == null || raw.isEmpty) return 'Sin mensajes';
  final c = raw.toLowerCase();
  if ((c.startsWith('http://') || c.startsWith('https://')) &&
      (c.endsWith('.jpg') ||
          c.endsWith('.png') ||
          c.endsWith('.webp') ||
          c.endsWith('.jpeg') ||
          c.endsWith('.gif') ||
          c.endsWith('.avif') ||
          c.endsWith('.bmp') ||
          c.endsWith('.svg') ||
          c.contains('supabase') ||
          c.contains('storage.googleapis') ||
          c.contains('s3.amazonaws'))) {
    return '📷 Imagen';
  }
  return raw;
}

class _ConversationListPanel extends StatelessWidget {
  final ChatProvider chatProv;
  final String miId;
  final String? selectedContratacionId;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onChatSelected;
  final bool isWideScreen;

  const _ConversationListPanel({
    required this.chatProv,
    required this.miId,
    required this.selectedContratacionId,
    required this.searchCtrl,
    required this.onChatSelected,
    required this.isWideScreen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final query = searchCtrl.text.trim().toLowerCase();
    final itemsFiltrados = chatProv.conversaciones.where((conv) {
      final nombre = (conv['otro_usuario_nombre'] ?? '')
          .toString()
          .toLowerCase();
      final otroUsuario = conv['otro_usuario'] as Map<String, dynamic>?;
      final rol = (otroUsuario?['rol'] ?? '').toString().toLowerCase();
      return nombre.contains(query) || rol.contains(query);
    }).toList();

    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(
            18,
            isWideScreen ? 18 : MediaQuery.of(context).padding.top + 10,
            18,
            18,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Chats',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (chatProv.loading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Bandeja de entrada centralizada de tus servicios.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline),
            ),
          ),
          child: TextField(
            controller: searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar conversación',
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.md),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
          ),
        ),

        Expanded(
          child: itemsFiltrados.isEmpty && !chatProv.loading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 44,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No se encontraron conversaciones',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: itemsFiltrados.length,
                  separatorBuilder: (context, index) => Divider(
                    color: theme.colorScheme.outlineVariant,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final conv = itemsFiltrados[index];
                    final id = (conv['contratacion_id'] ?? conv['id'])
                        .toString();
                    final nombre = conv['otro_usuario_nombre'] ?? 'Usuario';
                    final raw =
                        conv['ultimo_mensaje_contenido'] as String? ??
                        conv['ultimo_mensaje'] as String?;
                    final ultimoMsg = _formatUltimoMensaje(raw);
                    final noLeidos =
                        conv['mensajes_no_leidos_count'] as int? ??
                        conv['mensajes_no_leidos'] as int? ??
                        0;

                    final otroUsuario =
                        conv['otro_usuario'] as Map<String, dynamic>?;
                    final avatarUrl =
                        otroUsuario?['avatar_url'] as String? ??
                        conv['otro_usuario_avatar'] as String?;
                    final isOnline =
                        otroUsuario?['is_online'] as bool? ??
                        conv['otro_usuario_online'] as bool? ??
                        false;
                    final rol =
                        otroUsuario?['rol'] as String? ??
                        conv['otro_usuario_rol'] as String? ??
                        '';
                    final categoria = rol.isNotEmpty
                        ? '${rol[0].toUpperCase()}${rol.substring(1)}'
                        : '';
                    final ts =
                        conv['ultimo_mensaje_at'] ??
                        conv['ultimo_mensaje_fecha'];
                    final timestamp = _formatTimestamp(ts as String?);

                    final statusContratacion =
                        conv['status_contratacion'] as String? ?? '';

                    return _ConversationTile(
                      id: id,
                      name: nombre,
                      category: categoria,
                      lastMessage: ultimoMsg,
                      timestamp: timestamp,
                      avatarUrl: avatarUrl,
                      unreadCount: noLeidos,
                      isOnline: isOnline,
                      isSelected: id == selectedContratacionId,
                      statusContratacion: statusContratacion,
                      onTap: () => onChatSelected(id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String id;
  final String name;
  final String category;
  final String lastMessage;
  final String timestamp;
  final String? avatarUrl;
  final int unreadCount;
  final bool isOnline;
  final bool isSelected;
  final String statusContratacion;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.id,
    required this.name,
    required this.category,
    required this.lastMessage,
    required this.timestamp,
    required this.avatarUrl,
    required this.unreadCount,
    required this.isOnline,
    required this.isSelected,
    required this.statusContratacion,
    required this.onTap,
  });

  Widget _buildStatusChip(String status) {
    Color bgColor = AppTheme.statusColor(status).withValues(alpha: 0.15);
    Color textColor = AppTheme.statusColor(status);
    String label = AppTheme.statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blueprint.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.blueprintTint, AppColors.blueprint],
                    ),
                    image: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(avatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (statusContratacion.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _buildStatusChip(statusContratacion),
                            ],
                          ],
                        ),
                      ),
                      if (timestamp.isNotEmpty)
                        Text(
                          timestamp,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: unreadCount > 0
                                ? AppColors.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w800
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: unreadCount > 0
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blueprint.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Text(
                            category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(Radii.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blueprint.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
