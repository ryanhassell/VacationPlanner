import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  // controller to manage email input
  final TextEditingController _emailController = TextEditingController();

  // loading state for button
  bool _loading = false;

  // function to send password reset email
  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    // show message if email is empty
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email.")),
      );
      return;
    }

    // show loading indicator
    setState(() => _loading = true);

    try {
      // send password reset email using firebase auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent! Check your inbox.")),
      );

    } catch (e) {
      // log and show error
      print("Error sending reset email: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    // stop loading indicator
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // app bar title
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // input field for email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Enter your email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // show loading or reset button
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _sendPasswordResetEmail,
              child: const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}
