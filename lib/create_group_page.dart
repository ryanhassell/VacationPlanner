import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global_vars.dart';

class CreateGroupPage extends StatefulWidget {
  final String uid;

  const CreateGroupPage({super.key, required this.uid});

  @override
  _CreateGroupPageState createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  String _selectedGroupType = 'Planned';

  Future<void> _createGroup() async {
    const String apiUrl = 'http://$ip/groups';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'owner': widget.uid,
        'group_name': _groupNameController.text,
        'group_type': _selectedGroupType,
      }),
    );

    // If group creation is successful
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final int gid = responseData['gid'];

      await _createMember(gid); // add the user as a member of the new group

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group and member created successfully!')),
      );

      Navigator.pop(context); // return to previous screen
    } else {
      // Show error if creation fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  // adds the creator as a member
  Future<void> _createMember(int gid) async {
    const String apiUrl = 'http://$ip/members';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uid': widget.uid,
        'gid': gid,
        'role': "Owner", // assign the user as the groups owner
      }),
    );

    if (response.statusCode != 200) {
      // error check
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating member: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'), // Title in app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // input for group name
            TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // dropdown to choose planned or random
            DropdownButtonFormField<String>(
              value: _selectedGroupType,
              items: ['Planned', 'Random']
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroupType = value!;
                });
              },
              decoration: InputDecoration(
                labelText: 'Group Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // submit button
            ElevatedButton(
              onPressed: _createGroup,
              child: const Text('Create Group'),
            ),
            const SizedBox(height: 20),

            // back button
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Go back without creating a group
              },
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}