import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trabajoya_app/features/chat/presentation/pages/chat_panel.dart';

class ChatScreen extends StatelessWidget {
  final String contratacionId;
  const ChatScreen({super.key, required this.contratacionId});

  @override
  Widget build(BuildContext context) {
    // El ciclo de vida del WebSocket lo gestiona ChatPanel (única fuente de
    // conexión); aquí solo se renderiza para evitar listeners duplicados.
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ChatPanel(
        contratacionId: contratacionId,
        embedded: false,
        onBack: () => context.pop(),
      ),
    );
  }
}
