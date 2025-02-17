import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'global_vars.dart';

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  _CreateUserPageState createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _areaCodeController = TextEditingController();
  final TextEditingController _prefixController = TextEditingController();
  final TextEditingController _lineNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _prefixFocusNode = FocusNode();
  final FocusNode _lineNumberFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _areaCodeController.text = "";
    _prefixController.text = "";
    _lineNumberController.text = "";
  }

  String getFormattedPhoneNumber() {
    if (_areaCodeController.text.length != 3 ||
        _prefixController.text.length != 3 ||
        _lineNumberController.text.length != 4) {
      return "";
    }
    return "+1${_areaCodeController.text}${_prefixController.text}${_lineNumberController.text}";
  }

  Future<void> _createUser() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _areaCodeController.text.isEmpty ||
        _prefixController.text.isEmpty ||
        _lineNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields must be filled out!')),
      );
      return;
    }

    String formattedPhone = getFormattedPhoneNumber();
    if (formattedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number.')),
      );
      return;
    }

    const String apiUrl = 'http://$ip/users';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'email_address': _emailController.text,
        'phone_number': formattedPhone,
        'password': _passwordController.text,
        'groups': []
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User created successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create User')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),

              // Segmented Phone Number Input
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text("+1", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _areaCodeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      textAlign: TextAlign.center,
                      buildCounter: (context, {int? currentLength, bool? isFocused, int? maxLength}) => null,
                      onChanged: (value) {
                        if (value.length == 3) {
                          FocusScope.of(context).requestFocus(_prefixFocusNode);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _prefixController,
                      focusNode: _prefixFocusNode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 3,
                      textAlign: TextAlign.center,
                      buildCounter: (context, {int? currentLength, bool? isFocused, int? maxLength}) => null,
                      onChanged: (value) {
                        if (value.length == 3) {
                          FocusScope.of(context).requestFocus(_lineNumberFocusNode);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _lineNumberController,
                      focusNode: _lineNumberFocusNode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      buildCounter: (context, {int? currentLength, bool? isFocused, int? maxLength}) => null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createUser,
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
