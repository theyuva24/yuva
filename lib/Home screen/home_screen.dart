import 'package:flutter/material.dart';
import 'package:yuva/challenge/page/challenges_page.dart';
import '../connect/connect_page.dart';
import 'pages/post_page.dart';
import 'pages/chat_page.dart';
import 'pages/notification_page.dart';
import '../connect/hubs/page/hubs_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yuva/profile/profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ChallengesPage(),
    const ConnectPage(),
    const PostPage(),
    const ChatPage(),
    const NotificationPage(),
  ];

  final List<String> _pageTitles = [
    'Challenges',
    'Connect',
    'Post',
    'Chat',
    'Notifications',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePage(uid: user.uid),
                ),
              );
            }
          },
          icon: const CircleAvatar(
            backgroundColor: Color(0xFF6C63FF),
            child: Icon(Icons.person, color: Colors.white, size: 24),
          ),
        ),
        title: Text(
          _pageTitles[_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.groups),
              tooltip: 'Hubs',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HubsPage()),
                );
              },
            ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Connect'),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
