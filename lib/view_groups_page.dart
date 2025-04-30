import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'global_vars.dart';
import 'create_group_page.dart';
import 'group_manage_page.dart';

class GroupTripPage extends StatefulWidget {
  final String uid;

  const GroupTripPage({super.key, required this.uid});

  @override
  State<GroupTripPage> createState() => _GroupTripPageState();
}

class _GroupTripPageState extends State<GroupTripPage> {
  List<Map<String, dynamic>> _groupsWithTrips = [];
  List<bool> _mapLoaded = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGroupsWithTrips();
  }

  Future<void> _fetchGroupsWithTrips() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('http://$ip/members/by_uid/${widget.uid}'));
      if (response.statusCode == 200) {
        final List groups = json.decode(response.body);
        final List<Map<String, dynamic>> combined = [];

        for (final group in groups) {
          final gid = group['gid'];

          // Fetch group details to get the group name
          final groupDetailRes = await http.get(Uri.parse('http://$ip/groups/$gid'));
          Map<String, dynamic>? groupDetails;
          if (groupDetailRes.statusCode == 200) {
            final decoded = json.decode(groupDetailRes.body);
            if (decoded is List && decoded.isNotEmpty) {
              groupDetails = decoded.first;
            }
          }

          // Fetch trip details
          final tripRes = await http.get(Uri.parse('http://$ip/trips/list_trips_by_group/$gid'));
          List trips = tripRes.statusCode == 200 ? json.decode(tripRes.body) : [];

          combined.add({
            'group': groupDetails ?? {'gid': gid, 'group_name': 'Unnamed Group'},
            'trip': trips.isNotEmpty ? trips.first : null,
          });
        }

        setState(() {
          _groupsWithTrips = combined;
          _mapLoaded = List.generate(combined.length, (_) => false);
        });
      }
    } catch (e) {
      print('Error fetching groups/trips: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Groups')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchGroupsWithTrips,
        child: _groupsWithTrips.isEmpty
            ? const Center(child: Text('No groups found.'))
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: _groupsWithTrips.length,
          itemBuilder: (context, index) {
            final group = _groupsWithTrips[index]['group'];
            final trip = _groupsWithTrips[index]['trip'];

            final groupName = group['group_name'] ?? 'Unnamed Group';
            final tripLat = trip != null ? trip['location_lat'] ?? 0.0 : 0.0;
            final tripLong = trip != null ? trip['location_long'] ?? 0.0 : 0.0;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupManagePage(uid: widget.uid, gid: group['gid']),
                  ),
                ).then((_) => _fetchGroupsWithTrips());
              },
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 150,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        child: trip != null
                            ? Stack(
                          children: [
                            MapboxMap(
                              accessToken: mapboxAccessToken,
                              initialCameraPosition: CameraPosition(
                                target: LatLng(tripLat, tripLong),
                                zoom: 12,
                              ),
                              myLocationEnabled: false,
                              compassEnabled: false,
                              zoomGesturesEnabled: false,
                              scrollGesturesEnabled: false,
                              tiltGesturesEnabled: false,
                              rotateGesturesEnabled: false,
                              onMapCreated: (_) {
                                setState(() => _mapLoaded[index] = true);
                              },
                              onStyleLoadedCallback: () {
                                setState(() => _mapLoaded[index] = true);
                              },
                            ),
                            if (!_mapLoaded[index])
                              Container(
                                color: Colors.white.withOpacity(0.7),
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                          ],
                        )
                            : Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Text("No trip yet", style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        groupName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateGroupPage(uid: widget.uid)),
          ).then((_) => _fetchGroupsWithTrips());
        },
        icon: const Icon(Icons.group_add),
        label: const Text('Add Group'),
      ),
    );
  }
}