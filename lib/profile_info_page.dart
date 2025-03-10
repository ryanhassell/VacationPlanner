import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'home_page.dart';
import 'edit_profile_page.dart'; // Make sure you have this page implemented
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

  // Fetch user data from your backend (Postgres)
  Future<Map<String, dynamic>> _fetchUserData() async {
    final response = await http.get(Uri.parse("http://$ip/users/${widget.uid}"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch user data");
    }
  }

  // Load profile picture from Firebase Storage
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
      print("No profile image found: $e");
    }
  }

  // Let the user pick and upload a new profile picture
  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _isUploading = true;
    });
    final file = File(pickedFile.path);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child("profile_pictures/${widget.uid}.jpg");
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setState(() {
        profileImageUrl = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile picture updated!")),
      );
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image.")),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _changePassword() {
    // Implement your change password functionality or navigation here.
    print("Change Password button pressed");
  }

  void _editProfile() {
    // Navigate to the EditProfilePage, passing the current uid.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(uid: widget.uid),
      ),
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
        title: Text("Profile Information"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
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
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return Center(child: Text("User data not found."));
          }

          final data = snapshot.data!;
          final firstName = data['first_name'] ?? '';
          final lastName = data['last_name'] ?? '';
          final email = data['email_address'] ?? '';

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Picture (tappable to update)
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : null,
                        child: profileImageUrl == null
                            ? Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      if (_isUploading) CircularProgressIndicator(),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                // User Details
                Text(
                  "$firstName $lastName",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  email,
                  style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                ),
                SizedBox(height: 30),
                // Action Buttons
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                  child: Text("Change Password"),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _editProfile,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                  ),
                  child: Text("Edit Profile"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
