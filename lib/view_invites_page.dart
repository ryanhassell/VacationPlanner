import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global_vars.dart';

class ViewInvitesPage extends StatefulWidget {
  final String uid;
  const ViewInvitesPage({super.key, required this.uid});

  @override
  _ViewInvitesPageState createState() => _ViewInvitesPageState();
}

class _ViewInvitesPageState extends State<ViewInvitesPage> {
  late Future<List<Map<String, dynamic>>> _invites;

  @override
  void initState() {
    super.initState();
    _loadInvites(); // load invites when widget initialized
  }

  // helper to load invites
  void _loadInvites() {
    _invites = _fetchInvitesWithUserNames(widget.uid);
  }

  // fetches invite data
  Future<List<Map<String, dynamic>>> _fetchInvitesWithUserNames(String uid) async {
    final response = await http.get(Uri.parse("http://$ip/invites/$uid"));

    if (response.statusCode != 200) {
      throw Exception("Failed to load invites");
    }

    final invites = json.decode(response.body) as List<dynamic>;

    // get each inviters name
    for (var invite in invites) {
      final inviterId = invite['invited_by'];
      try {
        final inviterRes = await http.get(Uri.parse("http://$ip/users/$inviterId"));
        if (inviterRes.statusCode == 200) {
          final inviterData = json.decode(inviterRes.body);
          invite['inviter_name'] = '${inviterData['first_name']} ${inviterData['last_name']}';
        } else {
          invite['inviter_name'] = inviterId;
        }
      } catch (_) {
        invite['inviter_name'] = inviterId;
      }
    }

    return invites.cast<Map<String, dynamic>>();
  }

  // accepts invite and adds user to group
  Future<void> _acceptInvite(Map<String, dynamic> invite) async {
    final uid = invite['uid'];
    final gid = invite['gid'];
    final role = invite['role'];

    final response = await http.post(
      Uri.parse("http://$ip/members"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({"uid": uid, "gid": gid, "role": role}),
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

  // Declines an invite
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

  // remove an invite
  Future<void> _deleteInvite(String uid, int gid) async {
    final response = await http.delete(
      Uri.parse("http://$ip/invites/$uid/$gid"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete invite");
    }
  }

  // Reloads the invites list
  void _refreshInvites() {
    setState(() {
      _loadInvites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Invites')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _invites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // checks for loading state
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}')); // checks for a error state
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No invites available.')); //  checks for empty state
          } else {
            final invites = snapshot.data!;
            return ListView.builder(
              itemCount: invites.length,
              itemBuilder: (context, index) {
                final invite = invites[index];
                return ListTile(
                  title: Text('Invite from ${invite['inviter_name']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Accept button
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptInvite(invite),
                      ),
                      // Decline button
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _declineInvite(invite),
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
