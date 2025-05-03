import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:vacation_planner/trip_detail_page.dart';
import 'create_random_trip.dart';
import 'custom_trip_page.dart';
import 'members_list_page.dart';
import 'chat_page.dart';
import 'global_vars.dart';


class GroupManagePage extends StatefulWidget {
  final String uid; // uid
  final int gid; // gid

  const GroupManagePage({super.key, required this.uid, required this.gid});

  @override
  _GroupManagePageState createState() => _GroupManagePageState();
}

class _GroupManagePageState extends State<GroupManagePage> {
  Map<String, dynamic>? groupData;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
    fetchUserData();
  }

  // fetches group details including the owner’s name
  Future<void> fetchGroupDetails() async {
    try {
      final groupRes = await http.get(Uri.parse('http://$ip/groups/get/${widget.gid}'));

      if (groupRes.statusCode == 200) {
        final group = jsonDecode(groupRes.body);
        final ownerId = group['owner'];

        // fetches owners first name using their uid
        final userRes = await http.get(Uri.parse('http://$ip/users/$ownerId'));

        if (userRes.statusCode == 200) {
          final ownerData = jsonDecode(userRes.body);
          group['owner_name'] = ownerData['first_name'];
        } else {
          group['owner_name'] = ownerId; // fallback to ID if fails
        }

        setState(() {
          groupData = group;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load group details';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error: $error';
        isLoading = false;
      });
    }
  }

  // fetches the current user’s data
  Future<void> fetchUserData() async {
    final response = await http.get(Uri.parse("http://$ip/users/${widget.uid}"));
    if (response.statusCode == 200) {
      setState(() => userData = json.decode(response.body));
    }
  }

  // options to create a trip
  void _promptTripCreationModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.shuffle),
                title: const Text('Randomly Generate Trip'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateRandomTripPage(uid: widget.uid, group: widget.gid),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.create),
                title: const Text('Create Your Own Trip'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomTripPage(uid: widget.uid, group: widget.gid),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Group")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading spinner
          : errorMessage != null
              ? Center(child: Text(errorMessage!)) // Show error message
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // displays the group name
                      Text(
                        "Group Name: ${groupData!['group_name']}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      // display owner name and group type
                      Text("Owner: ${groupData!['owner_name']}"),
                      Text("Type: ${groupData!['group_type']}"),
                      const SizedBox(height: 20),

                      // navigate to members list page
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MembersListPage(
                                uid: widget.uid,
                                gid: widget.gid.toString(),
                              ),
                            ),
                          );
                        },
                        child: const Text("View Members"),
                      ),
                      const SizedBox(height: 10),

                      // navigate to group chat page
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                gid: widget.gid,
                                senderUid: widget.uid,
                                senderName: userData?['first_name'] ?? 'User',
                              ),
                            ),
                          );
                        },
                        child: const Text("Open Group Chat"),
                      ),

                      // check for existing trip or offer creation
                      ElevatedButton(
                        onPressed: () async {
                          final tripUrl = Uri.parse("http://$ip/trips/list_trips_by_user/${widget.uid}");
                          final response = await http.get(tripUrl);

                          if (response.statusCode == 200) {
                            final trips = json.decode(response.body);
                            final groupTrip = trips.firstWhere(
                              (trip) => trip['group'] == widget.gid,
                              orElse: () => null,
                            );

                            if (groupTrip != null) {
                              // navigates to existing trip page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TripDetailPage(tripId: groupTrip['trip_id']),
                                ),
                              );
                            } else {
                              // create new trip
                              _promptTripCreationModal();
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Failed to check group trip.")),
                            );
                          }
                        },
                        child: const Text("View/Create Group Trip"),
                      ),
                    ],
                  ),
                ),
    );
  }
}
