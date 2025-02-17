import 'package:flutter/material.dart';

class ProfileInfoPage extends StatelessWidget {
  const ProfileInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Information'),
      ),
      body: Center(
        child: const Text('Your profile details will be displayed here!'),
      ),
    );
  }
}