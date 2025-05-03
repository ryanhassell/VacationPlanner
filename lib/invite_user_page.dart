import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global_vars.dart';

class InviteUserPage extends StatefulWidget {
  final String uid;
  final int gid;

  const InviteUserPage({super.key, required this.uid, required this.gid});

  @override
  State<InviteUserPage> createState() => _InviteUserPageState();
}

class _InviteUserPageState extends State<InviteUserPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = 'Member';
  bool _isSubmitting = false;

  Future<void> _submitInvite() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      // lookup uid by email
      final lookupUrl = Uri.parse('http://$ip/users/invite/id/$email');
      final lookupResponse = await http.get(lookupUrl);

      if (lookupResponse.statusCode != 200) {
        throw Exception('User not found');
      }

      final userJson = jsonDecode(lookupResponse.body);
      final invitedUid = userJson['uid'];

      // submit the invite
      final inviteUrl = Uri.parse('http://$ip/invites');
      final inviteBody = {
        'uid': invitedUid,         // The user being invited
        'gid': widget.gid,
        'invited_by': widget.uid,  // The inviter
        'role': _selectedRole,
      };

      final inviteResponse = await http.post(
        inviteUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(inviteBody),
      );

      //checks if invite properly sent
      if (inviteResponse.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent!')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to send invite: ${inviteResponse.body}');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'User Email'), //makes input for email
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Email is required';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>( //select role u want invited member to have
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'Member', child: Text('Member')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                ],
                onChanged: (value) => setState(() => _selectedRole = value!),
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon( //press to submite the invite
                onPressed: _isSubmitting ? null : _submitInvite,
                icon: const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Sending...' : 'Send Invite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}