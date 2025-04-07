import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global_vars.dart';

class TripDetailPage extends StatefulWidget {
  final int group;
  final double userLat;
  final double userLong;
  final String landmarkTypes;
  final double maxDistance;
  final double maxInterlandmarkDistance;

  const TripDetailPage({
    Key? key,
    required this.group,
    required this.userLat,
    required this.userLong,
    required this.landmarkTypes,
    required this.maxDistance,
    required this.maxInterlandmarkDistance,
  }) : super(key: key);

  @override
  _TripDetailPageState createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  MapboxMapController? mapController;
  Map<String, dynamic>? tripData;
  bool isLoading = false;
  bool _styleLoaded = false;

  late CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();
    // Increase zoom for better marker visibility.
    _initialPosition = CameraPosition(
      target: LatLng(widget.userLat, widget.userLong),
      zoom: 14.0,
    );
    _fetchTripData();
  }

  Future<void> _fetchTripData() async {
    setState(() => isLoading = true);

    final url = Uri.parse(
        "http://$ip/trips/generate_trip"
            "?group=${widget.group}"
            "&location_lat=${widget.userLat}"
            "&location_long=${widget.userLong}"
            "&landmark_types=${widget.landmarkTypes}"
            "&max_distance=${widget.maxDistance}"
            "&max_interlandmark_distance=${widget.maxInterlandmarkDistance}"
    );

    print("Fetching trip data from: $url");

    try {
      final response = await http.post(url);
      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          tripData = data;
          isLoading = false;
        });
        if (_styleLoaded) {
          _addLandmarkMarkers();
        }
      } else {
        setState(() => isLoading = false);
        print("Error fetching trip: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Network error: $e");
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  void _onStyleLoadedCallback() async {
    _styleLoaded = true;
    print("Map style loaded");
    // Using default style, so no need to hide layers here.
    if (tripData != null) {
      _addLandmarkMarkers();
    }
  }

  String _getIconForLandmark(String type) {
    switch (type) {
      case "Parks":
        return "park-15";
      case "Food":
        return "restaurant-15";
      case "Museums":
        return "museum-15";
      case "Historic":
      case "Memorials":
        return "monument-15";
      case "Entertainment":
        return "theatre-15";
      case "Art":
        return "art-gallery-15";
      default:
        return "marker-15";
    }
  }

  /// Returns a Material icon for the list items based on landmark type.
  IconData _getMaterialIconForLandmark(String type) {
    switch (type) {
      case "Food":
        return Icons.restaurant;
      case "Parks":
        return Icons.park;
      case "Historic":
        return Icons.account_balance;
      case "Memorials":
        return Icons.museum;
      case "Museums":
        return Icons.museum;
      case "Art":
        return Icons.art_track;
      case "Entertainment":
        return Icons.movie;
      default:
        return Icons.place;
    }
  }

  Future<void> _addLandmarkMarkers() async {
    if (tripData == null || tripData?['landmarks'] == null) {
      print("No landmarks to add.");
      return;
    }
    final landmarks = tripData!['landmarks'] as List;
    print("Adding ${landmarks.length} landmarks");
    for (var landmark in landmarks) {
      final lat = double.parse(landmark['lat'].toString());
      final lng = double.parse(landmark['long'].toString());
      final name = landmark['name'] ?? 'Unnamed';
      final iconName = _getIconForLandmark(landmark['type'] ?? "");
      print("Adding marker for '$name' at ($lat, $lng) with icon '$iconName'");
      await mapController?.addSymbol(
        SymbolOptions(
          geometry: LatLng(lat, lng),
          iconImage: iconName,
          iconSize: 1.5,
          textField: name,
          textSize: 18.0,
          textOffset: Offset(0, 1.0),
          textAnchor: "top",
        ),
      );
    }
  }

  void _focusOnLandmark(Map landmark) {
    final lat = double.parse(landmark['lat'].toString());
    final lng = double.parse(landmark['long'].toString());
    mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  }

  @override
  Widget build(BuildContext context) {
    // Calculate deltas for bounding box based on maxDistance
    final double milesPerDegreeLat = 69.0;
    final double milesPerDegreeLon = 69.0 * cos(widget.userLat * pi / 180);
    final double latDelta = widget.maxDistance / milesPerDegreeLat;
    final double lonDelta = widget.maxDistance / milesPerDegreeLon;

    if (tripData == null && isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final tripId = tripData?['trip_id'];
    final List landmarks = tripData?['landmarks'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(tripId != null ? "Trip #$tripId Details" : "Loading Trip..."),
      ),
      body: Column(
        children: [
          // Top section: A square map with rounded edges and padding from the sides.
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width - 32,
                  child: MapboxMap(
                    accessToken: "$mapboxAccessToken",
                    initialCameraPosition: _initialPosition,
                    onMapCreated: _onMapCreated,
                    onStyleLoadedCallback: _onStyleLoadedCallback,
                    cameraTargetBounds: CameraTargetBounds(
                      LatLngBounds(
                        southwest: LatLng(widget.userLat - latDelta, widget.userLong - lonDelta),
                        northeast: LatLng(widget.userLat + latDelta, widget.userLong + lonDelta),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom section: List of landmarks in Cards.
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: landmarks.isEmpty
                  ? const Center(child: Text("No landmarks available."))
                  : ListView.builder(
                itemCount: landmarks.length,
                itemBuilder: (context, index) {
                  final landmark = landmarks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      onTap: () => _focusOnLandmark(landmark),
                      leading: Icon(
                        _getMaterialIconForLandmark(landmark['type'] ?? ""),
                        color: Colors.blue,
                        size: 30,
                      ),
                      title: Text(
                        landmark['name'] ?? "Landmark ${index + 1}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Lat: ${landmark['lat']}, Long: ${landmark['long']}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
