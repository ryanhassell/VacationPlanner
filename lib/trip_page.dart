import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'global_vars.dart';

class TripPage extends StatefulWidget {
  // These values come from location services
  final int group;
  final double userLat;
  final double userLong;

  const TripPage({
    Key? key,
    required this.group,
    required this.userLat,
    required this.userLong,
  }) : super(key: key);

  @override
  _TripPageState createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  Map<String, dynamic>? tripData;
  bool isLoading = false;

  Future<void> generateTrip() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse(
        "http://$ip/trips/generate_trip?group=${widget.group}&location_lat=${widget.userLat}&location_long=${widget.userLong}"
    );

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        setState(() {
          tripData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error generating trip"))
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Generator"),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : tripData == null
            ? ElevatedButton(
          onPressed: generateTrip,
          child: const Text("Generate Trip"),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Trip ID: ${tripData!['trip_id']}"),
            Text("Group: ${tripData!['group']}"),
            Text("Latitude: ${tripData!['location_lat']}"),
            Text("Longitude: ${tripData!['location_long']}"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: generateTrip,
              child: const Text("Generate Another Trip"),
            ),
          ],
        ),
      ),
    );
  }
}
