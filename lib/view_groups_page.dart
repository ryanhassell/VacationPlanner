import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vacation_planner/global_vars.dart';
import 'group_manage_page.dart';

class ViewGroupsPage extends StatefulWidget {
  final String uid;
  const ViewGroupsPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<ViewGroupsPage> createState() => _ViewGroupsPageState();
}

class _ViewGroupsPageState extends State<ViewGroupsPage> {
  late Future<List<Map<String, dynamic>>> _groupsFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = fetchUserGroups(widget.uid);
  }

  Future<List<Map<String, dynamic>>> fetchUserGroups(String uid) async {
    final url = Uri.parse('http://$ip/members/by_uid/$uid');  // Your existing endpoint
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> memberData = jsonDecode(response.body);
      List<Map<String, dynamic>> groups = [];

      // Fetch each group by gid
      for (var member in memberData) {
        final gid = member['gid'];

        final groupUrl = Uri.parse('http://$ip/groups/$gid');
        final groupResponse = await http.get(groupUrl);

        if (groupResponse.statusCode == 200) {
          final groupData = jsonDecode(groupResponse.body);

          // Check if the group data is a map, add it to the groups list
          if (groupData is Map<String, dynamic>) {
            groups.add(groupData);
          } else if (groupData is List) {
            // If the response is a list, check each item is a map and add it
            for (var groupItem in groupData) {
              if (groupItem is Map<String, dynamic>) {
                groups.add(groupItem);
              }
            }
          } else {
            print('Unexpected response format for group: $groupData');
          }
        } else {
          print('Failed to load group data for gid $gid');
        }
      }

      return groups;
    } else {
      throw Exception('Failed to load member data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            color: Colors.white,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Your Groups',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _groupsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No groups found.'));
                }

                final groups = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _groupsFuture = fetchUserGroups(widget.uid);
                    });
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            group["group_name"] ?? 'Unnamed Group',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupManagePage(
                                  uid: widget.uid,
                                  gid: group["gid"],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


