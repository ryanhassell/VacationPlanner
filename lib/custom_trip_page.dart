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

  // Constructor to receive the user ID and group ID
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

  // Function to search for places based on user input
  void _searchPlaces(String query) {
    // Cancel the previous search if it's still running
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    // Start a new search after a 500ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() {
          _searchResults.clear(); // Clear results if the query is empty
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
        // Make an API call to fetch search results
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final features = data['features'] ?? [];

          setState(() {
            // Map the search results into a list of places with names and coordinates
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
            _searchResults.clear(); // Clear results if the request fails
          });
          print('Error fetching search results: ${response.body}');
        }
      } catch (e) {
        setState(() {
          _searchResults.clear(); // Clear results if an error occurs
        });
        print('Error searching places: $e');
      }

      setState(() => _isSearching = false);
    });
  }

  // Function to add a selected place to the list
  void _addPlace(Map<String, dynamic> place) {
    if (!_selectedPlaces.any((p) => p['name'] == place['name'])) {
      setState(() => _selectedPlaces.add(place)); // Add place if it's not already selected
    }
  }

  // Function to remove a place from the selected list
  void _removePlace(int index) {
    setState(() => _selectedPlaces.removeAt(index)); // Remove place at the given index
  }

  // Function to save the custom trip
  Future<void> _saveTrip() async {
    if (_selectedPlaces.isEmpty) return; // Do nothing if no places are selected

    setState(() => _isSaving = true);

    // Prepare the data to send to the server
    final landmarks = _selectedPlaces.map((place) => {
      'name': place['name'],
      'lat': place['lat'],
      'long': place['long'],
      'type': 'custom'
    }).toList();

    final url = Uri.parse('http://$ip/trips/custom_trip'
        '?group=${widget.group}&uid=${widget.uid}&num_destinations=${landmarks.length}');

    try {
      // Send the data to the server to save the trip
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(landmarks),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tripId = data['tid'];

        Navigator.pop(context); // Return to group page after saving
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
              onChanged: _searchPlaces, // Trigger search on text change
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
                    _searchResults.clear(); // Clear search results on clear button press
                    setState(() {});
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(child: Text('No search results')) // Display if no results
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final place = _searchResults[index];
                return ListTile(
                  title: Text(place['name']),
                  subtitle: Text('Lat: ${place['lat']}, Long: ${place['long']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addPlace(place), // Add place on button press
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
                ? const Center(child: Text('No places added yet.')) // Display if no places selected
                : ListView.builder(
              itemCount: _selectedPlaces.length,
              itemBuilder: (context, index) {
                final place = _selectedPlaces[index];
                return ListTile(
                  title: Text(place['name']),
                  subtitle: Text('Lat: ${place['lat']}, Long: ${place['long']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removePlace(index), // Remove place on delete button press
                  ),
                );
              },
            ),
          ),
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(), // Show a loading spinner when saving
          )
              : Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveTrip, // Save trip when button pressed
              child: const Text('Save Custom Trip'),
            ),
          ),
        ],
      ),
    );
  }
}
