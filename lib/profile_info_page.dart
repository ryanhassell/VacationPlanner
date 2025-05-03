import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'global_vars.dart';

class ProfileInfoPage extends StatefulWidget {
  final String uid;

  const ProfileInfoPage({Key? key, required this.uid}) : super(key: key);

  @override
  _ProfileInfoPageState createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? profileImageUrl;

  // Fetch user data from backend
  Future<Map<String, dynamic>> _fetchUserData() async {
    final response =
    await http.get(Uri.parse("http://$ip/users/${widget.uid}"));
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to fetch user data");
    }
  }

  // Load profile picture from Firebase Storage.
  Future<void> _loadProfileImage() async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_pictures/${widget.uid}.jpg");
      final url = await ref.getDownloadURL();
      setState(() {
        profileImageUrl = url;
      });
    } catch (e) {
      print("No profile image found in Firebase Storage: $e");
    }
  }

  // Update the user's profile_image_url in the backend
  Future<void> _updateUserProfileImageUrl(String newUrl) async {
    try {
      final apiUrl = "http://$ip/users/${widget.uid}";
      final Map<String, dynamic> body = {
        "profile_image_url": newUrl,
        "groups": []
      };
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print("Profile image URL updated in DB.");
      } else {
        print("Error updating profile in DB: ${response.body}");
      }
    } catch (e) {
      print("Exception updating profile in DB: $e");
    }
  }

  // Let the user pick and upload a new profile picture to Firebase Storage
  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_pictures/${widget.uid}.jpg");
      await ref.putFile(file);

      final url = await ref.getDownloadURL();
      setState(() {
        profileImageUrl = url;
      });

      // Update the DB with the new profile_image_url.
      await _updateUserProfileImageUrl(url);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated!")),
      );
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image.")),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _changePassword() {
    print("Change Password button pressed");
  }

  // When pressed, sign out from Firebase Auth and navigate to the LoginPage.
  Future<void> _logOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Information"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage(uid: widget.uid)),
            );
          },
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("User data not found."));
          }

          final data = snapshot.data!;
          final firstName = data['first_name'] ?? '';
          final lastName = data['last_name'] ?? '';
          final email = data['email_address'] ?? '';
          final profileUrlFromDb = data['profile_image_url'] ?? '';

          final effectiveProfileUrl = profileImageUrl ?? profileUrlFromDb;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture with a blue pen icon at the bottom right.
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: effectiveProfileUrl.isNotEmpty
                            ? NetworkImage(effectiveProfileUrl)
                            : null,
                        child: effectiveProfileUrl.isEmpty
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      if (_isUploading) const CircularProgressIndicator(),
                      // Blue pen icon
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue,
                            child: const Icon(Icons.edit, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // User Details
                Text(
                  "$firstName $lastName",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                const SizedBox(height: 30),
                // Action Buttons
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("Change Password"),
                ),
                const SizedBox(height: 16),
                //Log Out button
                ElevatedButton(
                  onPressed: _logOut,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("Log Out"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
