import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:vacation_planner/trip_detail_page.dart';
import 'create_random_trip.dart';
import 'global_vars.dart';
import 'custom_trip_page.dart';

class TripLandingPage extends StatefulWidget {
  final String uid;

  const TripLandingPage({Key? key, required this.uid}) : super(key: key);

  @override
  _TripLandingPageState createState() => _TripLandingPageState();
}

class _TripLandingPageState extends State<TripLandingPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _trips = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchTrips() async {
    try {
      final url = Uri.parse('http://$ip/trips/list_trips_by_user/${widget.uid}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _trips = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        print('Failed to fetch trips: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching trips: $e');
      setState(() => _isLoading = false);
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

  String _generateStaticMapUrl(double lat, double lng) {
    return 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/static/'
        '$lng,$lat,13,0/500x300'
        '?access_token=$mapboxAccessToken';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Trips')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
          ? const Center(child: Text('No trips found.'))
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: RefreshIndicator(
          onRefresh: _fetchTrips,
          child: Scrollbar(
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(10),
            child: ListView.builder(
              padding: const EdgeInsets.only(right: 8.0),
              itemCount: _trips.length,
              itemBuilder: (context, index) {
                final trip = _trips[index];
                final staticMapUrl = _generateStaticMapUrl(
                  trip['location_lat'],
                  trip['location_long'],
                );

                return GestureDetector(
                  onTap: () async {
                    final shouldRefresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailPage(tripId: trip['trip_id']),
                      ),
                    );
                    if (shouldRefresh == true) {
                      _fetchTrips(); // <--- Reload trips automatically after deletion
                    }
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                          child: Image.network(
                            staticMapUrl,
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.white.withOpacity(0.8),
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            'Trip ${trip['trip_id']}',
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateTrip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
