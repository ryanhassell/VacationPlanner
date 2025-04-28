import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'global_vars.dart';
import 'invite_user_page.dart'; // Check that this import is correct

class MembersListPage extends StatefulWidget {
  final String uid; // User ID
  final String gid; // Group ID

  const MembersListPage({super.key, required this.uid, required this.gid});

  @override
  _MembersListPageState createState() => _MembersListPageState();
}

class _MembersListPageState extends State<MembersListPage> {
  List<Member> _members = [];
  bool _isLoading = true;
  String? currentUserRole;

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _fetchCurrentUserRole();
  }

  Future<void> _fetchMembers() async {
    final String apiUrl = 'http://$ip/members/${widget.gid}';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print("Fetching members...");
      if (response.statusCode == 200) {
        final List<dynamic> memberList = jsonDecode(response.body);
        final members = memberList.map((memberJson) => Member.fromMap(memberJson)).toList();

        for (var member in members) {
          final userResponse = await _fetchUserDetails(member.uid);
          member.firstName = userResponse.firstName;
          member.lastName = userResponse.lastName;
        }

        setState(() {
          _members = members;
          _isLoading = false; // Stop loading once the data is fetched
        });
      } else {
        throw Exception('Failed to load members');
      }
    } catch (error) {
      print("Error fetching members: $error");
      setState(() {
        _isLoading = false; // Stop loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  Future<UserMember> _fetchUserDetails(String uid) async {
    final String apiUrl = 'http://$ip/users/$uid';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final userJson = jsonDecode(response.body);
        return UserMember.fromMap(userJson);
      } else {
        throw Exception('Failed to load user details');
      }
    } catch (error) {
      throw Exception('Error: $error');
    }
  }

  Future<void> _fetchCurrentUserRole() async {
    final String apiUrl = 'http://$ip/members/${widget.gid}/${widget.uid}';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      print("Fetching current user's role...");
      if (response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);

        if (decodedBody is List && decodedBody.isNotEmpty) {
          final memberData = decodedBody[0];
          setState(() {
            currentUserRole = memberData['role'];
            _isLoading = false; // Stop loading once the role is fetched
          });
        } else {
          throw Exception('Unexpected response format for role');
        }
      } else {
        throw Exception('Failed to load user role');
      }
    } catch (error) {
      print("Error fetching current user role: $error");
      setState(() {
        _isLoading = false; // Stop loading on error
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  Future<void> _editRole(Member member) async {
  if (currentUserRole != 'Admin' && currentUserRole != 'Owner') {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are not authorized to edit roles')));
    return;
  }

  if (member.role == 'Owner') {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot change the role of the Owner')));
    return;
  }

  // Show a dialog for selecting the new role (only Admin or Member)
  String newRole = member.role; // Default to the current role

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Select Role'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return DropdownButton<String>(
              value: newRole,
              onChanged: (String? newValue) {
                setState(() {
                  newRole = newValue!;
                });
              },
              items: <String>['Member', 'Admin']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            );
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Send the role change to the backend
              final response = await http.put(
                Uri.parse('http://$ip/members/${widget.gid}/${member.uid}'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({"role": newRole}),
              );

              if (response.statusCode == 200) {
                setState(() {
                  member.role = newRole;
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Role updated to $newRole')));
                Navigator.of(context).pop(); // Close the dialog
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update role')));
              }
            },
            child: const Text('Update Role'),
          ),
        ],
      );
    },
  );
}

  Future<void> _kickMember(Member member) async {
  if (currentUserRole != 'Admin' && currentUserRole != 'Owner') {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are not authorized to kick members')));
    return;
  }

  if (member.role == 'Owner') {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot kick the Owner')));
    return;
  }

  final response = await http.delete(
    Uri.parse('http://$ip/members/${widget.gid}/${member.uid}'),
  );

  if (response.statusCode == 200) {
    setState(() {
      _members.remove(member);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member kicked out')));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to kick member')));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Members'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
          ? const Center(child: Text('No members found'))
          : ListView.builder(
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          return ListTile(
            title: Text('${member.firstName ?? ''} ${member.lastName ?? ''}'),
            subtitle: Text('Role: ${member.role}'),
            trailing: (currentUserRole == 'Admin' || currentUserRole == 'Owner')
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editRole(member), // Trigger role editing
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle),
                  onPressed: () => _kickMember(member),
                ),
              ],
            )
                : null,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InviteUserPage(uid: widget.uid, gid: int.parse(widget.gid)),
            ),
          );
        },
        label: const Text("Invite User"),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}

class Member {
  final String uid;
  final int gid;
  String role;
  String? firstName;
  String? lastName;

  Member({required this.uid, required this.gid, required this.role});

  static Member fromMap(Map<String, dynamic> map) {
    return Member(
      uid: map['uid'],
      gid: map['gid'],
      role: map['role'],
    );
  }
}

class UserMember {
  final String uid;
  final String firstName;
  final String lastName;
  final String emailAddress;

  UserMember({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.emailAddress,
  });

  static UserMember fromMap(Map<String, dynamic> map) {
    return UserMember(
      uid: map['uid'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      emailAddress: map['email_address'],
    );
  }
}