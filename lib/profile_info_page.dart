import 'package:flutter/material.dart';
import 'home_page.dart';

class ProfileInfoPage extends StatelessWidget {
  final int uid;

  const ProfileInfoPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Information'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate back to HomePage, passing the uid
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage(uid: uid)),
            );
          },
        ),
      ),
      body: Center(
        child: const Text('Your profile details will be displayed here!'),
      ),
    );
  }
}