import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'global_vars.dart';
import 'trip_detail_page.dart';

class EditTripPage extends StatefulWidget {
  final int tripId;

  const EditTripPage({Key? key, required this.tripId}) : super(key: key);

  @override
  _EditTripPageState createState() => _EditTripPageState();
}

class _EditTripPageState extends State<EditTripPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedPlaces = [];
  bool _isSearching = false;
  bool _isSaving = false;
  Timer? _debounceTimer;

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
        final landmarks = List<Map<String, dynamic>>.from(data['landmarks'] ?? []);
        setState(() {
          _selectedPlaces = landmarks;
        });
      } else {
        print('Failed to fetch trip: ${response.body}');
      }
    } catch (e) {
      print('Error fetching trip: $e');
    }
  }

  void _searchPlaces(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _searchResults.clear());
        return;
      }

      setState(() => _isSearching = true);

      final url = Uri.parse(
          'https://api.mapbox.com/search/searchbox/v1/forward?q=$query&types=poi,address,place&access_token=$mapboxAccessToken');

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final features = data['features'] ?? [];
          setState(() {
            _searchResults = features.map<Map<String, dynamic>>((f) {
              final coords = f['geometry']['coordinates'];
              return {
                'name': f['properties']['name'] ?? 'Unnamed',
                'lat': coords[1],
                'long': coords[0],
                'type': 'custom',
              };
            }).toList();
          });
        } else {
          setState(() => _searchResults.clear());
          print('Error searching places: ${response.body}');
        }
      } catch (e) {
        setState(() => _searchResults.clear());
        print('Error searching places: $e');
      }

      setState(() => _isSearching = false);
    });
  }

  void _addPlace(Map<String, dynamic> place) {
    if (!_selectedPlaces.any((p) => p['name'] == place['name'])) {
      setState(() => _selectedPlaces.add(place));
    }
  }

  void _removePlace(int index) {
    setState(() => _selectedPlaces.removeAt(index));
  }

  Future<void> _updateTrip() async {
    if (_selectedPlaces.isEmpty) return;

    setState(() => _isSaving = true);

    final url = Uri.parse('http://$ip/trips/update_trip/${widget.tripId}');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(_selectedPlaces),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TripDetailPage(tripId: widget.tripId),
          ),
        );
      } else {
        print('Failed to update trip: ${response.body}');
      }
    } catch (e) {
      print('Error updating trip: $e');
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Trip')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchPlaces,
              decoration: InputDecoration(
                hintText: 'Search places...',
                suffixIcon: _isSearching
                    ? const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
                    : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchResults.clear();
                    setState(() {});
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(child: Text('No search results'))
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  title: Text(place['name']),
                  subtitle: Text('Lat: ${place['lat']}, Long: ${place['long']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addPlace(place),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Selected Places', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _selectedPlaces.isEmpty
                ? const Center(child: Text('No places added yet.'))
                : ListView.builder(
              itemCount: _selectedPlaces.length,
              itemBuilder: (context, index) {
                final place = _selectedPlaces[index];
                return ListTile(
                  title: Text(place['name']),
                  subtitle: Text('Lat: ${place['lat']}, Long: ${place['long']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removePlace(index),
                  ),
                );
              },
            ),
          ),
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          )
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _updateTrip,
              child: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );
  }
}
