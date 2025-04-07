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
    _invites = _fetchInvites(widget.uid);
  }

  // Fetch invites for the user
  Future<List<dynamic>> _fetchInvites(String uid) async {
    final response = await http.get(Uri.parse("http://$ip/invites/$uid"));
    if (response.statusCode == 200) {
      return json.decode(response.body) as List<dynamic>;
    } else {
      throw Exception("Failed to load invites");
    }
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
                  trailing: IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      // Handle accept invite
                      // You can add logic for accepting invites here.
                    },
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
