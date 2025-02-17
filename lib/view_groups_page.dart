import 'package:flutter/material.dart';

class ViewGroupsPage extends StatelessWidget {
  const ViewGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Groups'),
      ),
      body: Center(
        child: const Text('List of your groups will be shown here!'),
      ),
    );
  }
}