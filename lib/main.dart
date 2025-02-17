import 'package:flutter/material.dart';
import 'package:vacation_planner/firebase_options.dart';
import 'home_page.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(VacationPlannerApp());
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
      home: const HomePage(uid: -1), // Use the actual home page
    );
  }
}
