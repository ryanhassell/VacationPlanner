import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'global_vars.dart';
import 'edit_trip_page.dart';
import 'trip_landing_page.dart';

class TripDetailPage extends StatefulWidget {
  final int tripId;

  const TripDetailPage({Key? key, required this.tripId}) : super(key: key);

  @override
  _TripDetailPageState createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  MapboxMapController? mapController;
  Map<String, dynamic>? tripData;
  bool isLoading = true;
  bool _styleLoaded = false;

  late CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();
    _fetchTripData();
  }

  Future<void> _fetchTripData() async {
    final url = Uri.parse('http://$ip/trips/get_trip/${widget.tripId}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          tripData = data;
          isLoading = false;
          _initialPosition = CameraPosition(
            target: LatLng(data['location_lat'], data['location_long']),
            zoom: 14.0,
          );
        });
      } else {
        setState(() => isLoading = false);
        print('Failed to fetch trip: ${response.body}');
      }
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching trip: $e');
    }
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  void _onStyleLoadedCallback() async {
    _styleLoaded = true;
    if (tripData != null) {
      _addLandmarkMarkers();
    }
  }

  Future<void> _addLandmarkMarkers() async {
    final landmarks = tripData?['landmarks'] ?? [];
    for (var landmark in landmarks) {
      await mapController?.addSymbol(
        SymbolOptions(
          geometry: LatLng(landmark['lat'], landmark['long']),
          iconImage: _getIconForLandmark(landmark['type']),
          iconSize: 1.5,
          textField: landmark['name'],
          textSize: 16.0,
          textOffset: const Offset(0, 1.2),
          textAnchor: "top",
        ),
      );
    }
  }

  String _getIconForLandmark(String? type) {
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

  IconData _getMaterialIconForLandmark(String? type) {
    switch (type) {
      case "Food":
        return Icons.restaurant;
      case "Parks":
        return Icons.park;
      case "Historic":
      case "Memorials":
        return Icons.account_balance;
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

  void _focusOnLandmark(Map<String, dynamic> landmark) {
    mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(landmark['lat'], landmark['long']),
      ),
    );
  }

  void _navigateToEditPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTripPage(tripId: widget.tripId),
      ),
    ).then((_) => _fetchTripData());
  }

  void _confirmDeleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Trip"),
        content: const Text("Are you sure you want to delete this trip? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final url = Uri.parse('http://$ip/trips/delete_trip/${widget.tripId}');
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        if (!mounted) return;
        Navigator.of(context).pop(true); // <- pop with `true`
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip deleted successfully!")),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete trip.")),
        );
        print('Failed to delete trip: ${response.body}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final List landmarks = tripData?['landmarks'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Trip #${tripData?['tid'] ?? ''}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPage,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDeleteTrip,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MapboxMap(
                  accessToken: mapboxAccessToken,
                  initialCameraPosition: _initialPosition,
                  onMapCreated: _onMapCreated,
                  onStyleLoadedCallback: _onStyleLoadedCallback,
                  myLocationEnabled: false,
                  zoomGesturesEnabled: true,
                ),
              ),
            ),
          ),
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
                        _getMaterialIconForLandmark(landmark['type']),
                        color: Colors.blue,
                        size: 30,
                      ),
                      title: Text(
                        landmark['name'] ?? "Landmark",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Lat: ${landmark['lat']}, Long: ${landmark['long']}",
                        style: const TextStyle(fontSize: 14),
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
