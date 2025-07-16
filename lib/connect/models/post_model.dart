class Post {
  final String id;
  final String userName;
  final String userProfileImage;
  final String hubId;
  final String hubName;
  final String hubProfileImage;
  final String postContent;
  final String timestamp;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final int shareCount;
  final String? postImage;
  final String postOwnerId;
  final String postType; // text, image, link, poll
  final String? linkUrl;
  final Map<String, dynamic>? pollData;

  Post({
    required this.id,
    required this.userName,
    required this.userProfileImage,
    required this.hubId,
    required this.hubName,
    required this.hubProfileImage,
    required this.postContent,
    required this.timestamp,
    required this.upvotes,
    required this.downvotes,
    required this.commentCount,
    required this.shareCount,
    this.postImage,
    required this.postOwnerId,
    required this.postType,
    this.linkUrl,
    this.pollData,
  });
}
