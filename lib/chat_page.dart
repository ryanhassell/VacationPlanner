import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'global_vars.dart';

class ChatPage extends StatefulWidget {
  final int gid;
  final String senderUid;
  final String senderName;

  const ChatPage({
    Key? key,
    required this.gid,
    required this.senderUid,
    required this.senderName,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchMessages();  // fetch initial messages
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => fetchMessages());  // refresh messages every 5 seconds
  }

  @override
  void dispose() {
    _timer?.cancel();  // cancel timer when the widget is disposed
    _messageController.dispose();  // dispose message controller
    super.dispose();
  }

  Future<void> fetchMessages() async {
    final response = await http.get(
      Uri.parse('http://$ip/messages/get_messages/${widget.gid}'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _messages = data.cast<Map<String, dynamic>>();  // update messages list
      });
      await markMessagesAsRead();  // ensure read_by gets updated
    } else {
      print('Failed to fetch messages: ${response.body}');
    }
  }

  Future<void> sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;  // don't send empty messages

    final body = {
      "gid": widget.gid,
      "sender_uid": widget.senderUid,
      "sender_name": widget.senderName,
      "text": _messageController.text.trim(),
      "timestamp": DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        Uri.parse('http://$ip/messages/send_message'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        _messageController.clear();  // clear message input after sending
        fetchMessages();  // refresh messages list
      } else {
        print('Failed to send message: ${response.body}');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> markMessagesAsRead() async {
    print('Marking messages as read...');
    try {
      final response = await http.post(
        Uri.parse('http://$ip/messages/mark_read/${widget.gid}/${widget.senderUid}'),
      );

      print("Mark read status: ${response.statusCode} - ${response.body}");

      if (response.statusCode != 200) {
        print("Failed to mark messages as read: ${response.body}");
      }
    } catch (e) {
      print("Error marking messages as read: $e");
    }
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())  // show loading indicator if fetching messages
                : ListView.builder(
              reverse: true,  // show newest messages at the bottom
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];  // get the message for the current index
                final isOwnMessage = message['sender_uid'] == widget.senderUid;  // check if the message is sent by the current user
                return Container(
                  alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,  // align message based on sender
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isOwnMessage ? Colors.blue[100] : Colors.grey[300],  // message bubble color based on sender
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['sender_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(message['text']),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,  // send message when button is pressed
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
