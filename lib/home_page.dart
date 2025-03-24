import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global_vars.dart'; // Contains your 'ip' variable
import 'login_page.dart';
import 'create_group_page.dart';
import 'view_groups_page.dart';
import 'profile_info_page.dart';
import 'trip_page.dart';
import 'debug_page.dart';

class HomePage extends StatefulWidget {
  final String uid;
  const HomePage({super.key, required this.uid});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      // Home Feed: Header with actual profile image, scrollable content, footer.
      HomeFeedPage(uid: widget.uid),
      // Groups Tab
      ViewGroupsPage(uid: widget.uid),
      // Trips Tab (Placeholder)
      const PlaceholderScreen(title: 'Trips'),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _screens[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_travel),
            label: 'Trips',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DebugPage(uid: widget.uid)),
          );
        },
        label: const Text('DEBUG'),
        icon: const Icon(Icons.bug_report),
      ),
    );
  }
}

/// The main Home feed screen with a header (showing the user's name + profile image),
/// a scrollable area for news feed items, and a footer.
class HomeFeedPage extends StatelessWidget {
  final String uid;
  const HomeFeedPage({super.key, required this.uid});

  /// Fetch user data from your backend.
  Future<Map<String, dynamic>> _fetchUserData() async {
    final response = await http.get(Uri.parse("http://$ip/users/$uid"));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to fetch user data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with user name and profile image
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Home',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: _fetchUserData(),
                builder: (context, snapshot) {
                  String displayName = "User";
                  String imageUrl = "";

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    displayName = "Loading...";
                  } else if (snapshot.hasData) {
                    final data = snapshot.data!;
                    displayName = data['first_name'] ?? "User";
                    imageUrl = data['profile_image_url'] ?? "";
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileInfoPage(uid: uid),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        // Display the name on the left
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Show user's actual profile image if available
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : const AssetImage('assets/images/profile_placeholder.png')
                          as ImageProvider,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(child: Text('News Feed Items Placeholder')),
                ),
                const SizedBox(height: 20),
                // More feed items can go here
              ],
            ),
          ),
        ),
        // Footer
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.white,
          child: Center(
            child: Text(
              '© 2025 Vacation Planner',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }
}

/// A simple placeholder screen for future tabs.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title Screen Placeholder',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
