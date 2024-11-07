// lib/main.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const ChatSPAApp());
}

class ChatSPAApp extends StatelessWidget {
  const ChatSPAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat SPA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatMessage {
  final String text;
  final MessageType type;
  final String? imageUrl;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.type,
    this.imageUrl,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum MessageType { user, system, bot }

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  String? _expandedImageUrl;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    bool available = await _speechToText.initialize();
    if (mounted) {
      setState(() {
        _isListening = available;
      });
    }
  }

  void _startListening() async {
    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          _handleSubmitted(result.recognizedWords);
        }
      },
    );
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: text,
          type: MessageType.user,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat SPA'),
      ),
      body: Column(
        children: [
          _buildCategories(),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final categories = ['General', 'Support', 'FAQ', 'Products'];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _messages.insert(
                    0,
                    ChatMessage(
                      text: 'Selected category: ${categories[index]}',
                      type: MessageType.system,
                    ),
                  );
                });
              },
              child: Text(categories[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageItem(message);
      },
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: message.type == MessageType.user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.type == MessageType.user
                    ? Colors.blue[100]
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.text),
                  if (message.imageUrl != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _expandedImageUrl = _expandedImageUrl == message.imageUrl
                              ? null
                              : message.imageUrl;
                        });
                      },
                      child: Image.network(
                        message.imageUrl!,
                        fit: BoxFit.cover,
                        width: _expandedImageUrl == message.imageUrl
                            ? double.infinity
                            : 200,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                _handleSubmitted(_textController.text);
              }
            },
          ),
          IconButton(
            icon: Icon(_speechToText.isListening ? Icons.mic_off : Icons.mic),
            onPressed: _speechToText.isListening ? _stopListening : _startListening,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _speechToText.cancel();
    _flutterTts.stop();
    super.dispose();
  }
}