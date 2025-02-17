import 'package:flutter/material.dart';
import 'home_page.dart';  // Import your actual HomePage class

void main() {
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
      home: const HomePage(), // Use the actual home page
    );
  }
}
