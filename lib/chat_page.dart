import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'global_vars.dart';

class ChatPage extends StatefulWidget {
  final int gid;     // group id
  final String uid;  // current user's uid
  final String name; // current user's name (for sending)

  const ChatPage({Key? key, required this.gid, required this.uid, required this.name}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  Timer? _pollingTimer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchMessages());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final url = Uri.parse('http://$ip/messages/get_messages/${widget.gid}');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          messages = data.cast<Map<String, dynamic>>();
        });
      } else {
        print('Failed to fetch messages: ${response.body}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);

    try {
      final url = Uri.parse('http://$ip/messages/send_message');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'gid': widget.gid,
          'sender_uid': widget.uid,
          'sender_name': widget.name,
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        _messageController.clear();
        await _fetchMessages();
      } else {
        print('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  bool _isMyMessage(Map<String, dynamic> message) {
    return message['sender_uid'] == widget.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet.'))
                : ListView.builder(
              reverse: true, // Show newest at bottom
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[messages.length - 1 - index];
                final bool isMine = _isMyMessage(message);

                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blueAccent : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isMine)
                          Text(
                            message['sender_name'] ?? '',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          message['text'] ?? '',
                          style: TextStyle(
                            color: isMine ? Colors.white : Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: _loading ? const CircularProgressIndicator() : const Icon(Icons.send),
                  onPressed: _loading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
