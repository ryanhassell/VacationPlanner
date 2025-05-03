import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'global_vars.dart';
import 'trip_detail_page.dart';

class CreateRandomTripPage extends StatefulWidget {
  final int group;
  final String uid;

  const CreateRandomTripPage({
    Key? key,
    required this.group,
    required this.uid,
  }) : super(key: key);

  @override
  _TripTabPageState createState() => _TripTabPageState();
}

class _TripTabPageState extends State<CreateRandomTripPage> with SingleTickerProviderStateMixin {
  bool isLoading = false;  // tracks loading state for trip generation
  MapboxMapController? mapController;  // controller for the map
  CameraPosition? _initialPosition;  // initial camera position for the map

  double? currentLat;  // user's current latitude
  double? currentLong;  // user's current longitude
  final TextEditingController _addressController = TextEditingController();  // controller for address input
  List<String> suggestions = [];  // list of address suggestions

  final List<String> availableCategories = [
    "Food", "Parks", "Historic", "Memorials", "Museums", "Art", "Entertainment"
  ];  // categories available for trip selection
  Set<String> selectedCategories = {};  // categories selected by the user

  double _maxTripDistance = 50.0;  // maximum trip distance in km
  double _maxInterlandmarkDistance = 20.0;  // maximum distance between landmarks
  int _numDestinations = 6;  // number of destinations in the trip

  late AnimationController _animationController;  // controller for animations
  late Animation<Offset> _slideAnimation;  // slide animation for address input

  @override
  void initState() {
    super.initState();
    _determinePosition();  // get the current position of the user
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

    // listen to address input changes to fetch suggestions
    _addressController.addListener(() {
      if (_addressController.text.trim().isEmpty) return;
      _fetchSuggestions(_addressController.text.trim());
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    final url = Uri.parse(
      'https://api.mapbox.com/search/searchbox/v1/suggest?q=$query&access_token=$mapboxAccessToken',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        suggestions = List<String>.from(data['suggestions'].map((s) => s['name'] ?? ''));
      });
    }
  }

  // use the provided address to get coordinates and update map position
  Future<void> _useAddress(String query) async {
    if (query.isEmpty) return;
    final url = Uri.parse(
        'https://api.mapbox.com/search/searchbox/v1/forward?q=$query&limit=1&access_token=$mapboxAccessToken');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final coords = data['features'][0]['geometry']['coordinates'];
      setState(() {
        currentLong = coords[0];
        currentLat = coords[1];
        _initialPosition = CameraPosition(
          target: LatLng(currentLat!, currentLong!),
          zoom: 10.0,
        );
      });
      if (mapController != null) {
        mapController!.animateCamera(CameraUpdate.newLatLng(
          LatLng(currentLat!, currentLong!),
        ));
      }
    }
  }

  // determine the user's current location using Geolocator
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
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

  // generate a random trip based on user selections
  Future<void> generateTrip() async {
    if (selectedCategories.length < 3) {  // ensure at least 3 categories are selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least 3 categories.")),
      );
      return;
    }
    if (currentLat == null || currentLong == null) {  // ensure location is set
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location not set.")),
      );
      return;
    }

    setState(() => isLoading = true);

    String landmarkTypes = selectedCategories.join(",");
    final url = Uri.parse(
        "http://$ip/trips/generate_trip"
            "?group=${widget.group}"
            "&uid=${widget.uid}"
            "&location_lat=$currentLat"
            "&location_long=$currentLong"
            "&landmark_types=$landmarkTypes"
            "&max_distance=$_maxTripDistance"
            "&max_interlandmark_distance=$_maxInterlandmarkDistance"
            "&num_destinations=$_numDestinations"
    );

    try {
      final response = await http.post(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tripId = data['tid'];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Trip successfully created!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error generating trip.")),
        );
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Random Trip")),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())  // show loading indicator while generating
            : SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: generateTrip,  // trigger trip generation on button press
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Generate Trip", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      body: _initialPosition == null
          ? const Center(child: CircularProgressIndicator())  // show loading while map position is being determined
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: SizedBox(
                height: 250,
                child: MapboxMap(
                  accessToken: mapboxAccessToken,
                  initialCameraPosition: _initialPosition!,
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    TextField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Enter Address (Leave blank to use current location)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () => _useAddress(_addressController.text),
                        ),
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: suggestions.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(suggestions[index]),
                        onTap: () {
                          _addressController.text = suggestions[index];
                          suggestions.clear();
                          _useAddress(suggestions[index]);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Select Categories:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: availableCategories.map((cat) => _buildCategoryButton(cat)).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSlider("Max Trip Distance:", _maxTripDistance, 1, 50, (v) => setState(() => _maxTripDistance = v)),
                            const SizedBox(height: 16),
                            _buildSlider("Max Distance Between Landmarks:", _maxInterlandmarkDistance, 1, 20, (v) => setState(() => _maxInterlandmarkDistance = v)),
                            const SizedBox(height: 16),
                            _buildSlider("Number of Destinations:", _numDestinations.toDouble(), 1, 20, (v) => setState(() => _numDestinations = v.round())),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // build category button for each category
  Widget _buildCategoryButton(String category) {
    bool isSelected = selectedCategories.contains(category);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blueAccent : Colors.white,
          side: const BorderSide(color: Colors.blueAccent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () {
          setState(() {
            if (isSelected) {
              selectedCategories.remove(category);
            } else {
              selectedCategories.add(category);
            }
          });
        },
        child: Text(
          category,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blueAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // build slider for trip settings like distance and destinations
  Widget _buildSlider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
            Text(value.toStringAsFixed(1)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
          activeColor: Colors.blueAccent,
        ),
      ],
    );
  }
}
