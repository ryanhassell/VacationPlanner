import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'global_vars.dart';
import 'invite_user_page.dart'; // Ensure this import is correct

class MembersListPage extends StatefulWidget {
  final String uid; // User ID
  final String gid; // Group ID

  const MembersListPage({super.key, required this.uid, required this.gid});

  @override
  _MembersListPageState createState() => _MembersListPageState();
}

class _MembersListPageState extends State<MembersListPage> {
  List<Member> _members = []; // List to hold members
  bool _isLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  // Fetch members from the backend
  Future<void> _fetchMembers() async {
    final String apiUrl = 'http://$ip/members/${widget.gid}'; // Endpoint to fetch members

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Parse the response into a list of Member objects
        final List<dynamic> memberList = jsonDecode(response.body);
        final members = memberList.map((memberJson) => Member.fromMap(memberJson)).toList();

        // Fetch user details (first and last name) for each member
        for (var member in members) {
          final userResponse = await _fetchUserDetails(member.uid);
          member.firstName = userResponse.firstName;
          member.lastName = userResponse.lastName;
        }

        setState(() {
          _members = members;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load members');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  // Fetch user details from the backend using uid
  Future<UserMember> _fetchUserDetails(String uid) async {
    final String apiUrl = 'http://$ip/users/$uid'; // Endpoint to fetch user details

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Members'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : _members.isEmpty
          ? const Center(child: Text('No members found'))
          : ListView.builder(
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          return ListTile(
            title: Text('${member.firstName} ${member.lastName}'),
            subtitle: Text('Role: ${member.role}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to InviteUserPage, converting gid to int
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InviteUserPage(uid: widget.uid,
                      gid: int.parse(widget.gid)),
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
  final String role;
  String? firstName;
  String? lastName;

  Member({required this.uid, required this.gid, required this.role});

  // Convert JSON to Member object manually
  static Member fromMap(Map<String, dynamic> map) {
    return Member(
      uid: map['uid'],
      gid: map['gid'],
      role: map['role'], // Assumed role is a string, adapt if it's an enum
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

  // Convert JSON to UserMember object manually
  static UserMember fromMap(Map<String, dynamic> map) {
    return UserMember(
      uid: map['uid'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      emailAddress: map['email_address'],
    );
  }
}
