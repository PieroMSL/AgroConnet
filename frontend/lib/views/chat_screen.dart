import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/chat_viewmodel.dart';
import '../models/chat_message.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.isEmpty) return;

    final viewModel = context.read<ChatViewModel>();
    viewModel.sendMessage(text);
    _controller.clear();

    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // MVVM: La UI escucha al ViewModel
    final viewModel = context.watch<ChatViewModel>();
    final colorScheme = Theme.of(context).colorScheme;

    // Paleta AgroConnect constante para el Chat
    const kPrimary = Color(0xFF1B5E20);
    const kVerdeVivo = Color(0xFF2E7D32);
    const kBgChat = Color(0xFFF4F7F4); // Fondo muy suave verdoso

    return Scaffold(
      backgroundColor: kBgChat,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Asistente AgroConnect',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            // Selector de Modelo IA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: viewModel.selectedModel,
                dropdownColor: kPrimary,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                isDense: true,
                underline: const SizedBox.shrink(),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 18,
                ),
                items: const [
                  DropdownMenuItem(value: 'gpt-4o', child: Text('GPT-4o')),
                  DropdownMenuItem(
                    value: 'DeepSeek-V3-0324',
                    child: Text('DeepSeek V3'),
                  ),
                  DropdownMenuItem(
                    value: 'gemini-2.5-flash',
                    child: Text('Gemini Flash'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    context.read<ChatViewModel>().setModel(value);
                  }
                },
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: kVerdeVivo,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onSelected: (value) async {
              if (value == 'clear') {
                context.read<ChatViewModel>().clearChat();
              } else if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Cerrar Sesión"),
                    content: const Text("¿Estás seguro de que quieres salir?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancelar"),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Salir"),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  // Cerrar sesión
                  final authService = AuthService();
                  await authService.signOut();
                  // El AuthWrapper en main.dart detectará el cambio y redirigirá a Login
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Limpiar chat'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: viewModel.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.agriculture_rounded,
                            size: 56,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '🌱 Asistente AgroConnect',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pregúntame sobre productos,\nprecios o recibe consejos agrícolas.\n¡Estoy aquí para ayudarte!',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ).animate().fade().scale(),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        viewModel.messages.length +
                        (viewModel.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == viewModel.messages.length) {
                        return _TypingIndicator(); // Muestra "Escribiendo..." al final
                      }

                      final message = viewModel.messages[index];
                      return _MessageBubble(message: message);
                    },
                  ),
          ),
          if (viewModel.errorMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: colorScheme.errorContainer,
              width: double.infinity,
              child: Text(
                viewModel.errorMessage!,
                style: TextStyle(color: colorScheme.onErrorContainer),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(),

          _InputArea(
            controller: _controller,
            onSend: _sendMessage,
            enabled: !viewModel.isLoading,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width *
              0.85, // Un poco más ancho para código
        ),
        decoration: BoxDecoration(
          color: isUser ? null : Colors.white,
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            if (isUser)
              BoxShadow(
                color: const Color(0xFF2E7D32).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser
                ? const Radius.circular(20)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(20),
          ),
        ),
        child: isUser
            // Usuario: Texto simple
            ? Text(
                message.text,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              )
            // IA: Markdown Render
            : MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.outfit(
                    color: Colors.black87,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  strong: GoogleFonts.outfit(
                    color: const Color(0xFF1B5E20),
                    fontWeight: FontWeight.w700,
                  ),
                  h1: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  h2: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  code: GoogleFonts.firaCode(
                    backgroundColor: Colors.grey.shade100,
                    color: Colors.red.shade800,
                    fontSize: 13,
                  ),
                  codeblockPadding: const EdgeInsets.all(12),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                ),
              ),
      ),
    ).animate().fade().slideY(begin: 0.3, end: 0, duration: 300.ms);
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 4,
              height: 4,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              "IA escribiendo...",
              style: GoogleFonts.outfit(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    ).animate().fade();
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _InputArea({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors
            .white, // Antes: colorScheme.surface (causaba negro en algunos themes)
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAF4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFB2DFDB), width: 1),
              ),
              child: TextField(
                controller: controller,
                enabled: enabled,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.outfit(color: Colors.black87, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  hintStyle: GoogleFonts.outfit(
                    color: const Color(0xFF9E9E9E),
                    fontSize: 15,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
                onPressed: enabled ? onSend : null,
                elevation: enabled ? 3 : 0,
                backgroundColor: enabled
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFCFD8DC),
                child: Icon(
                  Icons.send_rounded,
                  color: enabled ? Colors.white : Colors.grey.shade500,
                ),
              )
              .animate(target: enabled ? 0 : 1)
              .scale(begin: const Offset(1, 1), end: const Offset(0.9, 0.9)),
        ],
      ),
    );
  }
}
