import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'create_group_page.dart';
import 'view_groups_page.dart';
import 'profile_info_page.dart';
import 'create_random_trip.dart';
import 'chat_page.dart';

class DebugPage extends StatelessWidget {
  final String uid;

  // Constructor to receive the user ID
  const DebugPage({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Page'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to the Vacation Planner Debug Page!',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              // Displaying the logged-in user ID
              Text(
                'Logged in as User ID: $uid',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Button to navigate to the Login Page
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('Go to Login Page'),
              ),
              const SizedBox(height: 10),
              // Button to navigate to CreateGroupPage with user ID
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
              // Button to navigate to ViewGroupsPage with user ID
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GroupTripPage(uid: uid)),
                  );
                },
                child: const Text('View Groups'),
              ),
              const SizedBox(height: 10),
              // Button to navigate to ProfileInfoPage with user ID
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
              // Button to navigate to CreateRandomTripPage with hardcoded group and user ID
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateRandomTripPage(
                        group: 1, uid: "1",
                      ),
                    ),
                  );
                },
                child: const Text('Generate Trip'),
              ),
              const SizedBox(height: 10),
              // New button to navigate to ChatPage with sender UID and group ID
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        senderUid: uid,
                        gid: 1,
                        senderName: "Ryan",
                      ),
                    ),
                  );
                },
                child: const Text('Go to Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
