import 'package:flutter/material.dart';
import 'package:vacation_planner/edit_profile_page.dart';
import 'login_page.dart';
import 'create_group_page.dart';
import 'view_groups_page.dart';
import 'profile_info_page.dart';
import 'trip_page.dart'; // Import the new trip page

class HomePage extends StatelessWidget {
  final String uid;

  const HomePage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacation Planner Home Page'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Vacation Planner!',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(
              'Logged in as User ID: $uid',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Go to Login Page'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateGroupPage(uid: uid)),
                );
              },
              child: const Text('Create Group'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ViewGroupsPage(uid: uid)),
                );
              },
              child: const Text('View Groups'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileInfoPage(uid: uid)),
                );
              },
              child: const Text('Profile Info'),
            ),
            const SizedBox(height: 10),
            // New button to navigate to the Trip page
            ElevatedButton(
              onPressed: () {
                // For demonstration, we use sample values: group id = 1 and sample coordinates.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TripPage(
                      group: 1,
                      userLat: 37.7749,
                      userLong: -122.4194,
                    ),
                  ),
                );
              },
              child: const Text('Generate Trip'),
            ),
          ],
        ),
      ),
    );
  }
}
