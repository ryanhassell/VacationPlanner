import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vacation_planner/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VacationPlannerApp());
}

class VacationPlannerApp extends StatelessWidget {
  const VacationPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vacation Planner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.yellow),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// This widget listens to the authentication state changes
/// and routes the user to the appropriate page.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Check if the connection is active
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          // If the user is null, show the login page
          if (user == null) {
            return const LoginPage();
          }
          // Otherwise, navigate to HomePage with the user's UID
          return HomePage(uid: user.uid);
        }
        // Otherwise, show a loading indicator while waiting for auth state
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
