import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vacation_planner/global_vars.dart';

class ViewGroupsPage extends StatelessWidget {
  final String uid;

  const ViewGroupsPage({super.key, required this.uid});

  Future<List<Map<String, dynamic>>> fetchUserGroups(String uid) async {
    final url = Uri.parse('http://$ip/groups/identify/$uid'); // Replace with your actual FastAPI URL
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();  // Directly return list of maps
    }   else {
      throw Exception('Failed to load user groups');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Groups")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUserGroups(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No groups available'));
          }

          List<Map<String, dynamic>> groups = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tapped on ${groups[index]["group_name"]}')),
                    );
                  },
                  child: Chip(
                    label: Text(groups[index]["group_name"]),  // ✅ Directly access group_name
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: StadiumBorder(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}