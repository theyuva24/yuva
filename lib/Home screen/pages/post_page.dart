import 'package:flutter/material.dart';
import '../../connect/create_post_screen.dart';
import '../home_screen.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate to CreatePostScreen and return to Connect tab when done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CreatePostScreen()),
      ).then((_) {
        // When CreatePostScreen is closed, switch to Connect tab
        if (context.mounted) {
          // Find the HomeScreen and switch to Connect tab (index 1)
          final homeScreen = context.findAncestorStateOfType<HomeScreenState>();
          if (homeScreen != null) {
            homeScreen.switchToTab(1); // Switch to Connect tab
          }
        }
      });
    });

    // Return a loading screen while navigating
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
