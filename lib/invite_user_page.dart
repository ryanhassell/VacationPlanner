import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'global_vars.dart'; // Contains your backend IP and settings

class InviteUserPage extends StatefulWidget {
  final int groupId;
  const InviteUserPage({Key? key, required this.groupId}) : super(key: key);

  @override
  _InviteUserPageState createState() => _InviteUserPageState();
}

class _InviteUserPageState extends State<InviteUserPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> sendInvite() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    final url = Uri.parse("http://$ip/invites/send_invite");
    final payload = {
      "email": _emailController.text.trim(),
      "group": widget.groupId,
    };
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(payload),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _message =
          "Invite sent successfully! Invite link: ${data['invite_link']}";
        });
      } else {
        setState(() {
          _message = "Failed to send invite. Error: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _message = "Error sending invite: $e";
      });
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Invite User to Group"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Enter email address",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: sendInvite,
              child: const Text(
                "Send Invite",
                style: TextStyle(fontSize: 18),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 20),
              Text(_message!, style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
