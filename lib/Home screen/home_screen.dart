import 'package:flutter/material.dart';
import 'package:yuva/challenge/page/challenges_page.dart';
import '../connect/pages/connect_page.dart';
import 'pages/post_page.dart';
import 'pages/notification_page.dart';
import '../connect/pages/hubs_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yuva/profile/profile_page.dart';
import '../../chat/page/chats_page.dart'; // Import ChatsPage
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Getter to access current index
  int get currentIndex => _currentIndex;

  // Method to switch tabs
  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _pages = [
    const ChallengesPage(),
    const ConnectPage(),
    const PostPage(),
    const ChatsPage(), // Add ChatsPage here
    const NotificationPage(),
  ];

  final List<String> _pageTitles = [
    'Challenges',
    'Connect',
    'Post',
    'Chats', // Add Chats title
    'Notifications',
  ];

  @override
  Widget build(BuildContext context) {
    // Ensure _currentIndex is always valid
    final maxIndex = _pages.length - 1;
    if (_currentIndex > maxIndex) {
      _currentIndex = maxIndex;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF181C23),
        elevation: 0,
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
          icon: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF00F6FF), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF00F6FF).withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const CircleAvatar(
              backgroundColor: Color(0xFF181C23),
              child: Icon(Icons.person, color: Color(0xFF00F6FF), size: 24),
            ),
          ),
        ),
        title: Text(
          _pageTitles[_currentIndex],
          style: GoogleFonts.orbitron(
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              color: Color(0xFF00F6FF),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  blurRadius: 16,
                  color: Color(0xFF00F6FF),
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.groups, color: Color(0xFF00F6FF)),
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
        selectedItemColor: const Color(0xFF00F6FF),
        unselectedItemColor: Colors.white70,
        backgroundColor: const Color(0xFF181C23),
        elevation: 12,
        selectedLabelStyle: GoogleFonts.orbitron(
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
        unselectedLabelStyle: GoogleFonts.orbitron(letterSpacing: 1),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
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
