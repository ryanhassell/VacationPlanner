import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:vacation_planner/trip_detail_page.dart';
import 'create_random_trip.dart';
import 'custom_trip_page.dart';
import 'members_list_page.dart';
import 'chat_page.dart';  // Import the ChatPage
import 'global_vars.dart';

class GroupManagePage extends StatefulWidget {
  final String uid;
  final int gid;

  const GroupManagePage({super.key, required this.uid, required this.gid});

  @override
  _GroupManagePageState createState() => _GroupManagePageState();
}

class _GroupManagePageState extends State<GroupManagePage> {
  Map<String, dynamic>? groupData;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;

  late MapboxMapController mapController;

  Future<void> fetchGroupDetails() async {
    try {
      final response = await http.get(Uri.parse('http://$ip/groups/get/${widget.gid}'));

      if (response.statusCode == 200) {
        setState(() {
          groupData = jsonDecode(response.body);
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

  Future<void> fetchUserData() async {
    final response = await http.get(Uri.parse("http://$ip/users/${widget.uid}"));
    if (response.statusCode == 200) {
      setState(() => userData = json.decode(response.body));
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
    fetchUserData();
  }
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
                      builder: (_) => CustomTripPage(uid: widget.uid, group: 1),
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
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Group Name: ${groupData!['group_name']}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Owner: ${groupData!['owner']}"),
            Text("Type: ${groupData!['group_type']}"),
            const SizedBox(height: 10),
            Text("Latitude: ${groupData!['location_lat']}"),
            Text("Longitude: ${groupData!['location_long']}"),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: MapboxMap(
                accessToken: "YOUR_MAPBOX_TOKEN",
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    double.parse(groupData!['location_lat'].toString()),
                    double.parse(groupData!['location_long'].toString()),
                  ),
                  zoom: 10.0,
                ),
                onMapCreated: _onMapCreated,
              ),
            ),
            const SizedBox(height: 20),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailPage(tripId: groupTrip['trip_id']),
                      ),
                    );
                  } else {
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