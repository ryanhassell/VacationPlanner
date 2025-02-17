import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacation Planner Temporary Home Page'),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Vacation Planner!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}