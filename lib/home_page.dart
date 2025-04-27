import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vacation_planner/trip_detail_page.dart';
import 'package:vacation_planner/trip_landing_page.dart';
import 'global_vars.dart';
import 'login_page.dart';
import 'create_group_page.dart';
import 'view_groups_page.dart';
import 'profile_info_page.dart';
import 'create_random_trip.dart';
import 'debug_page.dart';

class HomePage extends StatefulWidget {
  final String uid;
  const HomePage({super.key, required this.uid});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late List<Widget> _screens;
  bool showDebugButton = true;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeFeedPage(uid: widget.uid),
      ViewGroupsPage(uid: widget.uid),
      TripLandingPage(uid: widget.uid),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(child: _screens[_selectedIndex]),
          if (showDebugButton)
            Positioned(
              right: 10,
              top: MediaQuery.of(context).size.height * 0.4,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.redAccent,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DebugPage(uid: widget.uid),
                    ),
                  );
                },
                child: const Icon(Icons.bug_report),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.card_travel), label: 'Trips'),
        ],
      ),
    );
  }
}

class HomeFeedPage extends StatefulWidget {
  final String uid;
  const HomeFeedPage({super.key, required this.uid});

  @override
  _HomeFeedPageState createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  Timer? _inviteTimer;
  List<dynamic> invites = [];
  bool loading = false;
  Map<String, dynamic>? userData;
  bool userLoading = true;
  bool newInvitesAvailable = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchInvites();
    startInvitePolling();
  }

  void startInvitePolling() {
    _inviteTimer = Timer.periodic(const Duration(seconds: 30), (_) => checkForNewInvites());
  }

  Future<void> fetchUserData() async {
    setState(() => userLoading = true);
    try {
      final response = await http.get(Uri.parse("http://$ip/users/${widget.uid}"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            userData = data;
            userLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => userLoading = false);
      }
    } catch (e) {
      print("Error fetching user: $e");
      if (mounted) setState(() => userLoading = false);
    }
  }

  Future<void> fetchInvites() async {
    setState(() => loading = true);
    try {
      final response = await http.get(Uri.parse("http://$ip/invites/list_invites_by_user/${widget.uid}"));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted) {
          setState(() {
            invites = data;
            newInvitesAvailable = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching invites: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> checkForNewInvites() async {
    try {
      final response = await http.get(Uri.parse("http://$ip/invites/list_invites_by_user/${widget.uid}"));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (mounted && data.length != invites.length) {
          setState(() => newInvitesAvailable = true);
        }
      }
    } catch (e) {
      print("Error checking for new invites: $e");
    }
  }

  Future<void> respondToInvite(int inviteId, bool accepted) async {
    final url = Uri.parse("http://$ip/invites/respond_invite");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'invite_id': inviteId, 'accepted': accepted}),
      );
      if (response.statusCode == 200) {
        await fetchInvites();
      } else {
        print('Failed to respond to invite: ${response.body}');
      }
    } catch (e) {
      print('Error responding to invite: $e');
    }
  }

  @override
  void dispose() {
    _inviteTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Home',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              userLoading
                  ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2))
                  : GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileInfoPage(uid: widget.uid)),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      userData?['first_name'] ?? "User",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: (userData?['profile_image_url'] != null &&
                          userData!['profile_image_url'].isNotEmpty)
                          ? NetworkImage(userData!['profile_image_url'])
                          : const AssetImage('assets/images/profile_placeholder.png')
                      as ImageProvider,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        if (newInvitesAvailable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: MaterialBanner(
              content: const Text('New invites available! Tap to refresh.'),
              actions: [
                TextButton(
                  onPressed: fetchInvites,
                  child: const Text('Refresh'),
                ),
              ],
              backgroundColor: Colors.yellow[700],
            ),
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchInvites,
            child: Container(
              color: loading ? Colors.grey[200] : Colors.white,
              child: invites.isEmpty
                  ? const Center(child: Text("No invites at the moment."))
                  : ListView.builder(
                itemCount: invites.length,
                itemBuilder: (context, index) {
                  final invite = invites[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Group Invite: ${invite['group_name'] ?? 'Unknown Group'}'),
                      subtitle: Text('From: ${invite['sender_name'] ?? 'Someone'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => respondToInvite(invite['invite_id'], true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => respondToInvite(invite['invite_id'], false),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
