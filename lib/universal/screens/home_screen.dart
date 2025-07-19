import 'package:flutter/material.dart';
import 'package:yuva/challenge/page/challenges_page.dart';
import '../../connect/pages/connect_page.dart';
import '../../connect/pages/post_page.dart';
import 'notification_page.dart';
import '../../connect/pages/hubs_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yuva/profile/profile_page.dart';
import '../../../chat/page/chats_page.dart'; // Import ChatsPage
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../profile/controllers/profile_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yuva/universal/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final int initialTabIndex;
  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  // Getter to access current index
  int get currentIndex => _currentIndex;

  // Method to switch tabs
  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    // Load the current user's profile on startup
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Use addPostFrameCallback to avoid calling notifyListeners during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final controller = Provider.of<ProfileController>(
          context,
          listen: false,
        );
        controller.loadProfile(user.uid);
      });
    }
  }

  final List<Widget> _pages = [
    const ChallengesPage(),
    const ConnectPage(),
    const ChatsPage(), // Add ChatsPage here
    const NotificationPage(),
  ];

  final List<String> _pageTitles = [
    'Challenges',
    'Connect',
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
        backgroundColor: AppThemeLight.surface,
        elevation: 0,
        centerTitle: true,
        leading: Consumer<ProfileController>(
          builder: (context, controller, _) {
            final url = controller.profilePicUrl;
            return IconButton(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChangeNotifierProvider(
                            create: (_) => ProfileController(),
                            child: ProfilePage(uid: user.uid),
                          ),
                    ),
                  );
                }
              },
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppThemeLight.primary, width: 2.w),
                ),
                child: CircleAvatar(
                  backgroundColor: AppThemeLight.surface,
                  backgroundImage: (url.isNotEmpty) ? NetworkImage(url) : null,
                  child:
                      (url.isEmpty)
                          ? Icon(
                            Icons.person,
                            color: AppThemeLight.primary,
                            size: 24,
                          )
                          : null,
                ),
              ),
            );
          },
        ),
        title: Text(
          _pageTitles[_currentIndex],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: AppThemeLight.textDark,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: const Icon(Icons.groups, color: AppThemeLight.primary),
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
        selectedItemColor: AppThemeLight.primary,
        unselectedItemColor: AppThemeLight.textLight,
        backgroundColor: AppThemeLight.surface,
        elevation: 12,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: AppThemeLight.primary,
        ),
        unselectedLabelStyle: const TextStyle(
          letterSpacing: 1,
          color: AppThemeLight.textLight,
        ),
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
