import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'global_vars.dart';
import 'trip_detail_page.dart';
import 'dart:async';

class CustomTripPage extends StatefulWidget {
  final String uid;
  final int group;

  const CustomTripPage({
    Key? key,
    required this.uid,
    required this.group,
  }) : super(key: key);


  @override
  _CustomTripPageState createState() => _CustomTripPageState();
}

class _CustomTripPageState extends State<CustomTripPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedPlaces = [];
  bool _isSearching = false;
  bool _isSaving = false;
  Timer? _debounceTimer;


  void _searchPlaces(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults.clear();
        });
        return;
      }

      setState(() => _isSearching = true);

      final url = Uri.parse(
          'https://api.mapbox.com/search/searchbox/v1/forward'
              '?q=$query'
              '&types=poi,address,place'
              '&access_token=$mapboxAccessToken'
      );

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
              };
            }).toList();
          });
        } else {
          setState(() {
            _searchResults.clear();
          });
          print('Error fetching search results: ${response.body}');
        }
      } catch (e) {
        setState(() {
          _searchResults.clear();
        });
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

  Future<void> _saveTrip() async {
    if (_selectedPlaces.isEmpty) return;

    setState(() => _isSaving = true);

    final landmarks = _selectedPlaces.map((place) => {
      'name': place['name'],
      'lat': place['lat'],
      'long': place['long'],
      'type': 'custom'
    }).toList();

    final url = Uri.parse('http://$ip/trips/custom_trip'
        '?group=${widget.group}&uid=${widget.uid}&num_destinations=${landmarks.length}');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(landmarks),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tripId = data['tid'];

        Navigator.pop(context); // Return to group page
      } else {
        print('Failed to save trip: ${response.body}');
      }
    } catch (e) {
      print('Error saving trip: $e');
    }

    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Custom Trip')),
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
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
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
              onPressed: _saveTrip,
              child: const Text('Save Custom Trip'),
            ),
          ),
        ],
      ),
    );
  }
}
