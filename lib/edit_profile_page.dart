import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'global_vars.dart';
import 'home_page.dart';


class EditProfilePage extends StatefulWidget {
  final String uid; // user id passed to the page

  const EditProfilePage({Key? key, required this.uid}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ImagePicker _picker = ImagePicker(); // image picker instance
  bool _isUploading = false; // flag to show loading indicator
  String? _profileImageUrl; // stores profile image url
  final TextEditingController _firstNameController = TextEditingController(); // input for first name
  final TextEditingController _lastNameController  = TextEditingController(); // input for last name
  final TextEditingController _emailController     = TextEditingController(); // input for email
  final TextEditingController _phoneController     = TextEditingController(); // input for phone number

  // default profile pictures to choose from
  final List<String> _stockImages = [
    "https://upload.wikimedia.org/wikipedia/commons/thumb/4/48/Outdoors-man-portrait_%28cropped%29.jpg/1200px-Outdoors-man-portrait_%28cropped%29.jpg",
    "https://variety.com/wp-content/uploads/2024/06/5N7A0541-e1718042484447.jpg",
    "https://images.pexels.com/photos/2379005/pexels-photo-2379005.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500",
  ];

  // fetch user data from the backend
  Future<Map<String, dynamic>> _fetchUserData() async {
    final response = await http.get(Uri.parse("http://$ip/users/${widget.uid}"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("Failed to fetch user data");
    }
  }

  // load profile image from firebase storage
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

  // update firebase auth user profile with image url
  Future<void> _updateFirebaseUserProfile(String url) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateProfile(photoURL: url);
        await user.reload();
      }
    } catch (e) {
      print("Error updating Firebase Auth profile: $e");
    }
  }

  // pick an image from the gallery and upload it to firebase
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
      await _updateFirebaseUserProfile(url); // update firebase auth
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

  // show modal bottom sheet for profile picture options
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
                      onTap: () async {
                        setState(() {
                          _profileImageUrl = stockUrl;
                        });
                        await _updateFirebaseUserProfile(stockUrl); // update auth
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

  // save profile data to backend
  Future<void> _saveProfile(Map<String, dynamic> currentData) async {
    // use entered data or fall back to existing values
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
      "profile_image_url": _profileImageUrl ?? currentData['profile_image_url'] ?? "",
      "groups": currentData['groups'] ?? [],
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
  void initState() {
    super.initState();
    _loadProfileImage(); // fetch profile image on load
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
        future: _fetchUserData(), // get user data from API
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // loading spinner
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}")); // show error
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("User data not found.")); // no data
          }
          final data = snapshot.data!;
          // fill controllers if empty
          if (_firstNameController.text.isEmpty) _firstNameController.text = data['first_name'] ?? "";
          if (_lastNameController.text.isEmpty) _lastNameController.text = data['last_name'] ?? "";
          if (_emailController.text.isEmpty) _emailController.text = data['email_address'] ?? "";
          if (_phoneController.text.isEmpty) _phoneController.text = data['phone_number'] ?? "";
          _profileImageUrl = data['profile_image_url'] ?? _profileImageUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _showImageOptions, // open modal to change picture
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
                      if (_isUploading) const CircularProgressIndicator(), // show loader
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
                  onPressed: () => _saveProfile(data), // save updated info
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
