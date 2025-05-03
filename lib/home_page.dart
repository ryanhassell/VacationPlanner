import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chat_page.dart';
import 'global_vars.dart';
import 'trip_landing_page.dart';
import 'view_groups_page.dart';
import 'view_invites_page.dart';
import 'profile_info_page.dart';
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

  @override
  void initState() {
    super.initState();
    // create list of screens for each tab
    _screens = [
      HomeFeedPage(uid: widget.uid),
      GroupTripPage(uid: widget.uid),
      ViewInvitesPage(uid: widget.uid),
      ProfileInfoPage(uid: widget.uid)
    ];
  }

  // handle bottom nav tap
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // show selected screen
      body: Stack(
        children: [
          SafeArea(child: _screens[_selectedIndex]),
        ],
      ),
      // bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'Invites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
  Timer? _messageTimer;
  bool userLoading = true;
  Map<String, dynamic>? userData;
  Map<String, dynamic>? unreadMessage;

  @override
  void initState() {
    super.initState();
    // load user data and start message polling
    fetchUserData();
    checkForNewMessages();
    _messageTimer = Timer.periodic(const Duration(seconds: 15), (_) => checkForNewMessages());
  }

  // fetch user info from backend
  Future<void> fetchUserData() async {
    final response = await http.get(Uri.parse("http://$ip/users/${widget.uid}"));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() => userData = data);
    }
    setState(() => userLoading = false);
  }

  // check for unread messages
  Future<void> checkForNewMessages() async {
    final response = await http.get(Uri.parse("http://$ip/messages/unread/${widget.uid}"));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      if (data.isNotEmpty) {
        // show first unread message
        setState(() {
          unreadMessage = data.first;
        });
      } else {
        setState(() => unreadMessage = null);
      }
    }
  }

  @override
  void dispose() {
    // cancel message timer
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // header with title and user info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Home', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              userLoading
                  ? const SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2))
                  : GestureDetector(
                onTap: () {
                  // go to profile page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileInfoPage(uid: widget.uid)),
                  );
                },
                child: Row(
                  children: [
                    Text(userData?['first_name'] ?? "User", style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // show unread message banner if exists
        if (unreadMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: MaterialBanner(
              content: Text('You have unread chat messages in Group (${unreadMessage!['group_name']}).'),
              actions: [
                TextButton(
                  onPressed: () {
                    // go to chat page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          gid: unreadMessage!['gid'],
                          senderUid: widget.uid,
                          senderName: userData?['first_name'] ?? 'User',
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Chat'),
                ),
              ],
              backgroundColor: Colors.blue[100],
            ),
          ),
        // no notifications message
        Expanded(
          child: Center(
            child: Text('No new notifications.', style: TextStyle(color: Colors.grey[600])),
          ),
        ),
      ],
    );
  }
}
