import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/theme/app_theme.dart';
import '../core/constants/api_constants.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatbotScreen extends StatefulWidget {
  final String token;
  const ChatbotScreen({super.key, required this.token});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text: 'Bonjour ! 👋 Posez-moi une question sur les lignes et '
            'horaires de bus, par exemple :\n'
            '"Quelles lignes disponibles ?"\n'
            '"Horaires ligne 10"\n'
            '"Y a-t-il des retards ?"',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isSending = true;
    });
    _inputCtrl.clear();
    _scrollToBottom();

    final reply = await _fetchReply(text);

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false));
      _isSending = false;
    });
    _scrollToBottom();
  }

  Future<String> _fetchReply(String message) async {
    try {
      final url = '${ApiConstants.passager}/chatbot';
      print('🤖 FLUTTER: POST $url');
      print('🤖 FLUTTER: token=${widget.token.substring(0, 20)}...');

      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${widget.token}',
            },
            body: jsonEncode({'message': message}),
          )
          .timeout(const Duration(seconds: 15));

      print('🤖 FLUTTER: status=${response.statusCode}');
      print('🤖 FLUTTER: body=${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ⬇️ نقرأ reponse أولاً، ثم message كـ fallback
        final reponse =
            data['reponse']?.toString() ?? data['message']?.toString();

        if (reponse != null && reponse.isNotEmpty) {
          return reponse;
        }
        return 'Réponse vide du serveur. (data=$data)';
      } else if (response.statusCode == 404) {
        return 'Service chatbot indisponible (404).';
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return 'Session expirée. Veuillez vous reconnecter.';
      } else {
        final data = jsonDecode(response.body);
        return data['message']?.toString() ??
            'Erreur serveur (${response.statusCode})';
      }
    } on FormatException catch (e) {
      return 'Erreur JSON : $e';
    } catch (e) {
      return 'Erreur de connexion : $e';
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: AppTheme.primary, size: 22),
            SizedBox(width: 8),
            Text('Assistant TransportDZ',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return _buildTypingBubble();
                }
                return _buildBubble(_messages[i]);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatMessage m) {
    final isUser = m.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 14),
          ),
          border: isUser
              ? null
              : Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser) ...[
              const Icon(Icons.smart_toy_outlined,
                  color: AppTheme.primary, size: 16),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                m.text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.white70,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
              color: AppTheme.primary, strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _inputCtrl,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _envoyer(),
                  decoration: const InputDecoration(
                    hintText: 'Écrivez votre question...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isSending ? null : _envoyer,
              child: Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
