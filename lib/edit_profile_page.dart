import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'global_vars.dart';
import 'home_page.dart';

class EditProfilePage extends StatefulWidget {
  final String uid;

  const EditProfilePage({Key? key, required this.uid}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _profileImageUrl;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController  = TextEditingController();
  final TextEditingController _emailController     = TextEditingController();
  final TextEditingController _phoneController     = TextEditingController();

  // Stock images for profile picture selection
  final List<String> _stockImages = [
    "https://example.com/stock1.jpg",
    "https://example.com/stock2.jpg",
    "https://example.com/stock3.jpg",
  ];

  Future<Map<String, dynamic>> _fetchUserData() async {
    final response = await http.get(Uri.parse("http://$ip/users/${widget.uid}"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to fetch user data");
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final ref = FirebaseStorage.instance.ref().child("profile_pictures/${widget.uid}.jpg");
      final url = await ref.getDownloadURL();
      setState(() {
        _profileImageUrl = url;
      });
    } catch (e) {
      print("No profile image found in Storage: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _isUploading = true;
    });
    final file = File(pickedFile.path);
    try {
      final ref = FirebaseStorage.instance.ref().child("profile_pictures/${widget.uid}.jpg");
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setState(() {
        _profileImageUrl = url;
      });
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

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Upload from Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImageFromGallery();
                },
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Choose a Stock Image",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              SizedBox(
                height: 150,
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _stockImages.length,
                  itemBuilder: (context, index) {
                    final stockUrl = _stockImages[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _profileImageUrl = stockUrl;
                        });
                        Navigator.pop(context);
                      },
                      child: Image.network(stockUrl, fit: BoxFit.cover),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile(Map<String, dynamic> currentData) async {
    // Prepare updated data by taking values from the controllers,
    // or using the existing data if the controller is empty.
    final Map<String, dynamic> updatedData = {
      "first_name": _firstNameController.text.isNotEmpty
          ? _firstNameController.text
          : currentData['first_name'],
      "last_name": _lastNameController.text.isNotEmpty
          ? _lastNameController.text
          : currentData['last_name'],
      "email_address": _emailController.text.isNotEmpty
          ? _emailController.text
          : currentData['email_address'],
      "phone_number": _phoneController.text.isNotEmpty
          ? _phoneController.text
          : currentData['phone_number'],
      "profile_image_url": _profileImageUrl ?? currentData['profile_image_url'] ?? ""
    };

    try {
      final response = await http.put(
        Uri.parse("http://$ip/users/${widget.uid}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updatedData),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating profile: ${response.body}")),
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
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
          // Populate controllers with current data if they are empty.
          if (_firstNameController.text.isEmpty) _firstNameController.text = data['first_name'] ?? "";
          if (_lastNameController.text.isEmpty) _lastNameController.text = data['last_name'] ?? "";
          if (_emailController.text.isEmpty) _emailController.text = data['email_address'] ?? "";
          if (_phoneController.text.isEmpty) _phoneController.text = data['phone_number'] ?? "";

          // If profile image URL is not set locally, use the value from the database.
          _profileImageUrl = data['profile_image_url'] ?? _profileImageUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _showImageOptions,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      if (_isUploading) const CircularProgressIndicator(),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.edit, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: "First Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: "Last Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _saveProfile(data),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text("Save Changes"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
