import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:vacation_planner/trip_detail_page.dart';
import 'create_random_trip.dart';
import 'custom_trip_page.dart';
import 'global_vars.dart';

class TripLandingPage extends StatefulWidget {
  final String uid;
  const TripLandingPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<TripLandingPage> createState() => _TripLandingPageState();
}

class _TripLandingPageState extends State<TripLandingPage> {
  late Future<List<Map<String, dynamic>>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _tripsFuture = fetchTrips();
  }

  Future<List<Map<String, dynamic>>> fetchTrips() async {
    final url = Uri.parse('http://$ip/trips/list_trips_by_user/${widget.uid}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load trips');
    }
  }

  void _navigateToCreateTrip() {
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
                      builder: (_) => CreateRandomTripPage(uid: widget.uid, group: 1),
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
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Trips',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _navigateToCreateTrip,
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _tripsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No trips found.'));
                }

                final trips = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _tripsFuture = fetchTrips();
                    });
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TripDetailPage(tripId: trip['trip_id']),
                            ),
                          );
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
                                  child: MapboxMap(
                                    accessToken: mapboxAccessToken,
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(trip['location_lat'], trip['location_long']),
                                      zoom: 12,
                                    ),
                                    myLocationEnabled: false,
                                    compassEnabled: false,
                                    zoomGesturesEnabled: false,
                                    scrollGesturesEnabled: false,
                                    tiltGesturesEnabled: false,
                                    rotateGesturesEnabled: false,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Trip ${trip['trip_id']}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 18),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
