import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global_vars.dart'; // Contains your 'ip' variable

class ViewInvitesPage extends StatefulWidget {
  final String uid;
  const ViewInvitesPage({super.key, required this.uid});

  @override
  _ViewInvitesPageState createState() => _ViewInvitesPageState();
}

class _ViewInvitesPageState extends State<ViewInvitesPage> {
  late Future<List<dynamic>> _invites;

  @override
  void initState() {
    super.initState();
    _loadInvites();
  }

  void _loadInvites() {
    _invites = _fetchInvites(widget.uid);
  }

  Future<List<dynamic>> _fetchInvites(String uid) async {
    final response = await http.get(Uri.parse("http://$ip/invites/$uid"));
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception("Failed to load invites");
    }
  }

  Future<void> _acceptInvite(Map<String, dynamic> invite) async {
    final uid = invite['uid'];
    final gid = invite['gid'];
    final role = invite['role'];

    final response = await http.post(
      Uri.parse("http://$ip/members"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({
        "uid": uid,
        "gid": gid,
        "role": role,
      }),
    );
      try {
        await _deleteInvite(uid, gid);
      } catch (e) {
        print("Warning: Failed to delete invite after accepting: $e");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite accepted!')),
      );
      _refreshInvites();
  }

  Future<void> _declineInvite(Map<String, dynamic> invite) async {
    final uid = invite['uid'];
    final gid = invite['gid'];

    try {
      await _deleteInvite(uid, gid);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invite declined.')),
      );
      _refreshInvites();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline invite: $e')),
      );
    }
  }

  Future<void> _deleteInvite(String uid, int gid) async {
    final response = await http.delete(
      Uri.parse("http://$ip/invites/$uid/$gid"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete invite");
    }
  }

  void _refreshInvites() {
    setState(() {
      _loadInvites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Invites')),
      body: FutureBuilder<List<dynamic>>(
        future: _invites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No invites available.'));
          } else {
            final invites = snapshot.data!;
            return ListView.builder(
              itemCount: invites.length,
              itemBuilder: (context, index) {
                final invite = invites[index];
                return ListTile(
                  title: Text('Invite from ${invite['invited_by']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          _acceptInvite(invite);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          _declineInvite(invite);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
