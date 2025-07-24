import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_details_page.dart';

class PostDetailsPageLoader extends StatelessWidget {
  final String postId;
  const PostDetailsPageLoader({required this.postId, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('posts').doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        return PostDetailsPage(
          postId: postId,
          userName: data['userName'] ?? 'Anonymous',
          userProfileImage: data['userProfileImage'] ?? '',
          hubName: data['hubName'] ?? '',
          hubProfileImage: data['hubProfileImage'] ?? '',
          postContent: data['postContent'] ?? '',
          timestamp: data['postingTime']?.toString() ?? '',
          upvotes: data['upvotes'] ?? 0,
          downvotes: data['downvotes'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
          shareCount: data['shareCount'] ?? 0,
          postImage: data['postImageUrl'],
          postOwnerId: data['userId'] ?? '',
          postType: data['postType'] ?? 'text',
          linkUrl: data['linkUrl'],
          pollData: data['pollData'],
        );
      },
    );
  }
}
