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
  MapboxMapController? mapController; // Mapbox controller
  LatLng? mapLocation; // Stores the LatLng based on fetched data

  Future<void> fetchGroupDetails() async {
    try {
      final response = await http.get(Uri.parse('http://$ip/groups/get/${widget.gid}'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Fetched group data: $data");

        setState(() {
          groupData = data;

          double? lat = (data['location_lat'] as num?)?.toDouble();
          double? long = (data['location_long'] as num?)?.toDouble();

          if (lat != null && long != null) {
            mapLocation = LatLng(lat, long);
            print("Map location set: $mapLocation");
          }

          isLoading = false;
        });

        // If the map is already created, update the camera position
        if (mapController != null && mapLocation != null) {
          mapController!.animateCamera(CameraUpdate.newLatLng(mapLocation!));
          _addMarker();
        }

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

  void _addMarker() {
    if (mapController != null && mapLocation != null) {
      // Add marker if mapController and mapLocation are both non-null
      mapController!.addSymbol(SymbolOptions(
        geometry: mapLocation!,
        iconImage: "marker-15", // Uses a built-in Mapbox marker
        iconSize: 1.5,
      ));
      print("Marker added at: ${mapLocation!.latitude}, ${mapLocation!.longitude}");
    } else {
      print("Failed to add marker: mapController or mapLocation is null");
    }
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

            // Display the Mapbox map if mapLocation is available
            mapLocation != null
                ? Container(
              height: 300,
              child: MapboxMap(
                accessToken: "sk.eyJ1IjoiY2hlZXNlZnJpZXMiLCJhIjoiY204bW55bWQ3MWp2aDJrcHgyaTltazI3aSJ9.5qZSf6JCMv1VWyB_lp5tFg", // Your Mapbox access token here
                initialCameraPosition: CameraPosition(
                  target: mapLocation!,
                  zoom: 14.0,
                ),
                onMapCreated: (MapboxMapController controller) {
                  setState(() {
                    mapController = controller;
                  });

                  print("Map created. Updating camera position...");
                  if (mapLocation != null) {
                    mapController!.animateCamera(CameraUpdate.newLatLng(mapLocation!));
                    _addMarker();
                  }
                },
              ),
            )
                : const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}