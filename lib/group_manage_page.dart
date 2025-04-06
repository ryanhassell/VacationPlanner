import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapbox_gl/mapbox_gl.dart'; // Import Mapbox

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
  bool isLoading = true;
  String? errorMessage;

  late MapboxMapController mapController; // Mapbox controller for controlling the map

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

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    super.initState();
    fetchGroupDetails();
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

            // Hardcoded Mapbox Map (San Francisco)
            SizedBox(
              height: 300,
              child: MapboxMap(
                accessToken: "sk.eyJ1IjoiY2hlZXNlZnJpZXMiLCJhIjoiY204bmJjc2toMDBnMjJ5cHpkaWQ0aWVldSJ9.j3l4E43PL3P1MKT_KtjUTw", // Replace with your actual Mapbox token
                initialCameraPosition: const CameraPosition(
                  target: LatLng(37.7749, -122.4194), // San Francisco
                  zoom: 10.0,
                ),
                onMapCreated: _onMapCreated,
              ),
            ),
          ],
        ),
      ),
    );
  }
}