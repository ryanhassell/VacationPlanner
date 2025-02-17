import 'package:flutter/material.dart';

class ViewGroupsPage extends StatelessWidget {
  const ViewGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy list of groups
    final List<String> groups = ['Group 1', 'Group 2', 'Group 3'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Groups'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: () {
                // Handle navigation to group details
              },
              child: Text(groups[index]),
            ),
          );
        },
      ),
    );
  }
}