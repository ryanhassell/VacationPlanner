import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'global_vars.dart';
import 'trip_detail_page.dart';

class TripTabPage extends StatefulWidget {
  final int group;

  const TripTabPage({
    Key? key,
    required this.group,
  }) : super(key: key);

  @override
  _TripTabPageState createState() => _TripTabPageState();
}

class _TripTabPageState extends State<TripTabPage> {
  bool isLoading = false;
  MapboxMapController? mapController;
  late CameraPosition _initialPosition;

  // We'll store the user's current location here.
  double? currentLat;
  double? currentLong;

  // Expanded list of categories.
  final List<String> availableCategories = [
    "Food",
    "Parks",
    "Historic",
    "Memorials",
    "Museums",
    "Art",
    "Entertainment"
  ];
  Set<String> selectedCategories = {};

  // Slider for maximum trip distance (miles).
  double _maxTripDistance = 50.0;
  // Slider for maximum distance between landmarks (miles).
  double _maxInterlandmarkDistance = 20.0;
  // Slider for number of destinations (1 to 20).
  int _numDestinations = 1;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permissions are denied.")),
        );
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permissions are permanently denied.")),
      );
      return;
    }

    try {
      // Try to get the last known position first.
      Position? lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        setState(() {
          currentLat = lastPosition.latitude;
          currentLong = lastPosition.longitude;
          _initialPosition = CameraPosition(
            target: LatLng(currentLat!, currentLong!),
            zoom: 10.0,
          );
        });
      }
      // Now get an updated, current position.
      final Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentLat = position.latitude;
        currentLong = position.longitude;
        _initialPosition = CameraPosition(
          target: LatLng(currentLat!, currentLong!),
          zoom: 10.0,
        );
      });
    } catch (e) {
      print("Error getting current position: $e");
    }
  }


  /// Build a FilterChip for each category.
  Widget _buildCategoryChip(String category) {
    bool isSelected = selectedCategories.contains(category);
    return FilterChip(
      label: Text(
        category,
        style: const TextStyle(fontSize: 14),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          if (selected) {
            selectedCategories.add(category);
          } else {
            selectedCategories.remove(category);
          }
        });
      },
      selectedColor: Colors.blueAccent,
      checkmarkColor: Colors.white,
    );
  }

  /// Generate a trip by calling your backend API.
  Future<void> generateTrip() async {
    if (selectedCategories.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least 3 categories.")),
      );
      return;
    }
    if (currentLat == null || currentLong == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current location not available.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    String landmarkTypes = selectedCategories.join(",");
    final url = Uri.parse(
        "http://$ip/trips/generate_trip"
            "?group=${widget.group}"
            "&location_lat=$currentLat"
            "&location_long=$currentLong"
            "&landmark_types=$landmarkTypes"
            "&max_distance=$_maxTripDistance"
            "&max_interlandmark_distance=$_maxInterlandmarkDistance"
            "&num_destinations=$_numDestinations"
    );

    print("Generating trip with URL: $url");

    try {
      final response = await http.post(url);
      print("Trip generation response status: ${response.statusCode}");
      if (response.statusCode == 200) {
        setState(() {
          isLoading = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TripDetailPage(
              group: widget.group,
              userLat: currentLat!,
              userLong: currentLong!,
              landmarkTypes: landmarkTypes,
              maxDistance: _maxTripDistance,
              maxInterlandmarkDistance: _maxInterlandmarkDistance,
              numDestinations: _numDestinations,
            ),
          ),
        );
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error generating trip")),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error generating trip: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // If current location is not available, show a progress indicator.
    if (currentLat == null || currentLong == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Creator"),
      ),
      body: Column(
        children: [
          // Map section showing current location.
          Expanded(
            flex: 2,
            child: MapboxMap(
              accessToken: mapboxAccessToken, // Replace with your Mapbox token.
              initialCameraPosition: _initialPosition,
              onMapCreated: (controller) {
                print("Map created with initial position: $_initialPosition");
              },
            ),
          ),
          // Controls for category selection, sliders, and button.
          Container(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Categories:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: availableCategories
                        .map((cat) => _buildCategoryChip(cat))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  // Max Trip Distance slider.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Max Trip Distance (miles):",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text("${_maxTripDistance.toStringAsFixed(1)}"),
                    ],
                  ),
                  Slider(
                    value: _maxTripDistance,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: "${_maxTripDistance.toStringAsFixed(1)} miles",
                    onChanged: (value) {
                      setState(() {
                        _maxTripDistance = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Max Distance Between Landmarks slider.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Max Distance Between Landmarks (miles):",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text("${_maxInterlandmarkDistance.toStringAsFixed(1)}"),
                    ],
                  ),
                  Slider(
                    value: _maxInterlandmarkDistance,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: "${_maxInterlandmarkDistance.toStringAsFixed(1)} miles",
                    onChanged: (value) {
                      setState(() {
                        _maxInterlandmarkDistance = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // New slider: Number of Destinations.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Number of Destinations:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text("$_numDestinations"),
                    ],
                  ),
                  Slider(
                    value: _numDestinations.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: "$_numDestinations",
                    onChanged: (value) {
                      setState(() {
                        _numDestinations = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: generateTrip,
                      child: const Text(
                        "Generate Trip",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
