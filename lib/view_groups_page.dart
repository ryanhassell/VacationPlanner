import 'package:flutter/material.dart';

class ViewGroupsPage extends StatelessWidget {
  final int uid;

  const ViewGroupsPage({super.key, required this.uid});

  Future<List<String>> fetchUserGroups(int uid) async {
    // This function is a placeholder to simulate fetching groups based on user ID.
    // Replace with real API calls or data fetching logic
    await Future.delayed(Duration(seconds: 2)); // Simulate network delay
    return ['Group 1', 'Group 2', 'Group 3']; // Example groups
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Groups"),
      ),
      body: FutureBuilder<List<String>>(
        future: fetchUserGroups(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No groups available'));
          }

          List<String> groups = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two bubbles per row
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // Handle group tap, possibly navigate to a group details page
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tapped on ${groups[index]}')));
                  },
                  child: Chip(
                    label: Text(groups[index]),
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: StadiumBorder(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}