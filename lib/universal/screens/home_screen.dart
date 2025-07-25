import 'package:flutter/material.dart';
import 'package:yuva/challenge/page/challenges_page.dart';
import '../../connect/pages/connect_page.dart';
import '../../connect/pages/post_page.dart';
import 'notification_page.dart';
import '../../connect/pages/hubs_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yuva/profile/owner_profile_page.dart';
import '../../../chat/page/chats_page.dart'; // Import ChatsPage
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../profile/controllers/profile_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:yuva/universal/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                            child: OwnerProfilePage(uid: user.uid),
                          ),
                    ),
                  );
                }
              },
              icon: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.w,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  backgroundImage:
                      (url.isNotEmpty) ? CachedNetworkImageProvider(url) : null,
                  child:
                      (url.isEmpty)
                          ? Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (_currentIndex == 1)
            IconButton(
              icon: Icon(
                Icons.groups,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Hubs',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HubsPage()),
                );
              },
            ),
          if (_currentIndex != 1)
            IconButton(
              icon: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Share',
              onPressed: () {
                Share.share(
                  "Connect, grow, and shine with India’s youth-focused social media app.\nDownload now: https://play.google.com/store/apps/details?id=com.yuva.uniqueapp",
                );
              },
            ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar:
          user == null
              ? BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppThemeDark.navIconUnselected
                        : AppThemeLight.navIconUnselected,
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 12,
                selectedLabelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Theme.of(context).colorScheme.primary,
                ),
                unselectedLabelStyle: TextStyle(
                  letterSpacing: 1,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? AppThemeDark.navIconUnselected
                          : AppThemeLight.navIconUnselected,
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
              )
              : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance
                        .collection('chats')
                        .where('participants', arrayContains: user.uid)
                        .snapshots(),
                builder: (context, snapshot) {
                  final chatDocs = snapshot.data?.docs ?? [];
                  return FutureBuilder<int>(
                    future: () async {
                      int totalUnread = 0;
                      for (final chatDoc in chatDocs) {
                        final chatData = chatDoc.data();
                        final chatId = chatDoc.id;
                        final lastReadTimestamps =
                            chatData['lastReadTimestamps'] ?? {};
                        final lastRead =
                            lastReadTimestamps[user.uid] != null &&
                                    lastReadTimestamps[user.uid] is Timestamp
                                ? (lastReadTimestamps[user.uid] as Timestamp)
                                    .toDate()
                                : DateTime.fromMillisecondsSinceEpoch(0);
                        final unreadQuery =
                            await FirebaseFirestore.instance
                                .collection('chats')
                                .doc(chatId)
                                .collection('messages')
                                .where('timestamp', isGreaterThan: lastRead)
                                .where('senderId', isNotEqualTo: user.uid)
                                .get();
                        totalUnread += unreadQuery.docs.length;
                      }
                      return totalUnread;
                    }(),
                    builder: (context, unreadSnapshot) {
                      final totalUnread = unreadSnapshot.data ?? 0;
                      final showBadge = _currentIndex != 2 && totalUnread > 0;
                      return BottomNavigationBar(
                        type: BottomNavigationBarType.fixed,
                        currentIndex: _currentIndex,
                        onTap: (index) {
                          setState(() {
                            _currentIndex = index;
                          });
                        },
                        selectedItemColor:
                            Theme.of(context).colorScheme.primary,
                        unselectedItemColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppThemeDark.navIconUnselected
                                : AppThemeLight.navIconUnselected,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        elevation: 12,
                        selectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        unselectedLabelStyle: TextStyle(
                          letterSpacing: 1,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? AppThemeDark.navIconUnselected
                                  : AppThemeLight.navIconUnselected,
                        ),
                        items: [
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.emoji_events_outlined),
                            label: 'Challenges',
                          ),
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.people_outline),
                            label: 'Connect',
                          ),
                          BottomNavigationBarItem(
                            icon: Stack(
                              children: [
                                const Icon(Icons.chat_bubble_outline),
                                if (showBadge)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Theme.of(context).colorScheme.error,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        totalUnread.toString(),
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            label: 'Chats',
                          ),
                          const BottomNavigationBarItem(
                            icon: Icon(Icons.notifications_outlined),
                            label: 'Notifications',
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
    );
  }
}
