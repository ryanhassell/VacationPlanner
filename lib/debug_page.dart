import 'package:flutter/material.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'create_group_page.dart';
import 'view_groups_page.dart';
import 'profile_info_page.dart';
import 'create_random_trip.dart';
import 'chat_page.dart'; // <-- ADD THIS IMPORT

class DebugPage extends StatelessWidget {
  final String uid;

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
              Text(
                'Logged in as User ID: $uid',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
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
                    MaterialPageRoute(builder: (context) => GroupTripPage(uid: uid)),
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
              // New button to navigate to ChatPage
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
