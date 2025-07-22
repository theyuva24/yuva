import 'package:flutter/material.dart';
import '../model/submission_model.dart';
import '../../profile/services/profile_service.dart';
import '../../profile/models/profile_model.dart';
import '../service/challenge_service.dart';
import '../model/challenge_model.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../service/full_screen_functionality.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widget/challenge_comment.dart';

// --- ReelsVideoPlayer Widget ---
class ReelsVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool play;
  const ReelsVideoPlayer({required this.videoUrl, Key? key, this.play = true})
    : super(key: key);

  @override
  State<ReelsVideoPlayer> createState() => _ReelsVideoPlayerState();
}

class _ReelsVideoPlayerState extends State<ReelsVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isBuffering = true;
  bool _shouldPlay = true;

  @override
  void initState() {
    super.initState();
    _shouldPlay = widget.play;
    _initVideo();
  }

  @override
  void didUpdateWidget(covariant ReelsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _shouldPlay = widget.play;
      _initVideo();
    } else if (oldWidget.play != widget.play) {
      _shouldPlay = widget.play;
      if (_controller != null && _controller!.value.isInitialized) {
        if (_shouldPlay) {
          _controller!.play();
        } else {
          _controller!.pause();
        }
      }
    }
  }

  Future<void> _initVideo() async {
    try {
      print('Initializing video: ${widget.videoUrl}');
      if (widget.videoUrl.toLowerCase().endsWith('.m3u8') ||
          widget.videoUrl.toLowerCase().endsWith('.mpd')) {
        // Adaptive streaming: use network controller directly
        print('Using network controller for adaptive streaming');
        _controller = VideoPlayerController.network(widget.videoUrl);
      } else {
        // For .mp4/.mov, use cache manager
        print('Using cache manager for file playback');
        final file = await DefaultCacheManager().getSingleFile(widget.videoUrl);
        _controller = VideoPlayerController.file(file);
      }
      await _controller!.initialize();
      setState(() {
        _isBuffering = false;
      });
      _controller!.setLooping(true);
      if (_shouldPlay) {
        _controller!.play();
      }
      _controller!.addListener(() {
        if (_controller!.value.isBuffering != _isBuffering) {
          setState(() {
            _isBuffering = _controller!.value.isBuffering;
          });
        }
      });
    } catch (e) {
      print('Video load error: $e');
      setState(() {
        _isBuffering = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load video: $e')));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBuffering ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      },
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }
}

class FullScreenMediaPage extends StatefulWidget {
  final List<Submission> submissions;
  final int initialIndex;
  const FullScreenMediaPage({
    Key? key,
    required this.submissions,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<FullScreenMediaPage> createState() => _FullScreenMediaPageState();
}

class _FullScreenMediaPageState extends State<FullScreenMediaPage> {
  late PageController _pageController;
  late int _currentIndex;
  final ProfileService _profileService = ProfileService();
  final ChallengeService _challengeService = ChallengeService();
  final Map<String, Challenge?> _challengeCache = {};
  bool _showFullDesc = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<Challenge?> _getChallenge(String challengeId) async {
    if (_challengeCache.containsKey(challengeId)) {
      return _challengeCache[challengeId];
    }
    final challenge = await _challengeService.fetchChallengeById(challengeId);
    _challengeCache[challengeId] = challenge;
    return challenge;
  }

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m3u8') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.submissions.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _showFullDesc = false;
              });
            },
            itemBuilder: (context, index) {
              final submission = widget.submissions[index];
              // Prefetch next 2 media files
              for (int i = 1; i <= 2; i++) {
                if (index + i < widget.submissions.length) {
                  final next = widget.submissions[index + i];
                  if (next.isVideo &&
                      next.mediaUrl != null &&
                      next.mediaUrl!.isNotEmpty) {
                    DefaultCacheManager().downloadFile(next.mediaUrl!);
                    if (next.thumbnailUrl != null &&
                        next.thumbnailUrl!.isNotEmpty) {
                      CachedNetworkImageProvider(
                        next.thumbnailUrl!,
                      ).resolve(const ImageConfiguration());
                    }
                  } else if (!next.isVideo &&
                      next.mediaUrl != null &&
                      next.mediaUrl!.isNotEmpty) {
                    CachedNetworkImageProvider(
                      next.mediaUrl!,
                    ).resolve(const ImageConfiguration());
                  }
                }
              }
              print(
                'FullScreenMediaPage: mediaUrl = ${submission.mediaUrl}, thumbnailUrl = ${submission.thumbnailUrl}',
              );
              final user = _auth.currentUser;
              final challengeId = submission.challengeId;
              final submissionId = submission.id;
              return FutureBuilder<Challenge?>(
                future: _getChallenge(submission.challengeId),
                builder: (context, challengeSnap) {
                  final challengeTitle =
                      challengeSnap.data?.title ?? 'Challenge';
                  return FutureBuilder<ProfileModel?>(
                    future: _profileService.getProfile(submission.userId),
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      final String fullName = profile?.fullName ?? 'Full Name';
                      final String profileImageUrl =
                          profile?.profilePicUrl ?? '';
                      return StreamBuilder<
                        DocumentSnapshot<Map<String, dynamic>>
                      >(
                        stream:
                            FirebaseFirestore.instance
                                .collection('challenges')
                                .doc(challengeId)
                                .collection('challenge_submission')
                                .doc(submissionId)
                                .snapshots(),
                        builder: (context, snap) {
                          final data = snap.data?.data();
                          final likeCount = data?['likeCount'] ?? 0;
                          final commentCount = data?['commentCount'] ?? 0;
                          final shareCount = data?['shareCount'] ?? 0;
                          return StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>
                          >(
                            stream:
                                user == null
                                    ? null
                                    : FirebaseFirestore.instance
                                        .collection('challenges')
                                        .doc(challengeId)
                                        .collection('challenge_submission')
                                        .doc(submissionId)
                                        .collection('likeInteractions')
                                        .doc(user.uid)
                                        .snapshots(),
                            builder: (context, likeSnap) {
                              final liked = likeSnap.data?.exists ?? false;
                              return Stack(
                                children: [
                                  Center(
                                    child:
                                        submission.mediaUrl != null &&
                                                submission.mediaUrl!.isNotEmpty
                                            ? submission.isVideo
                                                ? Stack(
                                                  children: [
                                                    if (submission
                                                                .thumbnailUrl !=
                                                            null &&
                                                        submission
                                                            .thumbnailUrl!
                                                            .isNotEmpty)
                                                      Positioned.fill(
                                                        child: CachedNetworkImage(
                                                          imageUrl:
                                                              submission
                                                                  .thumbnailUrl!,
                                                          fit: BoxFit.cover,
                                                          placeholder:
                                                              (
                                                                context,
                                                                url,
                                                              ) => const Center(
                                                                child:
                                                                    CircularProgressIndicator(),
                                                              ),
                                                          errorWidget:
                                                              (
                                                                context,
                                                                url,
                                                                error,
                                                              ) => Container(
                                                                color:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                        ),
                                                      ),
                                                    ReelsVideoPlayer(
                                                      videoUrl:
                                                          submission.mediaUrl!,
                                                      play:
                                                          index ==
                                                          _currentIndex,
                                                    ),
                                                  ],
                                                )
                                                : CachedNetworkImage(
                                                  imageUrl:
                                                      submission.mediaUrl!,
                                                  fit: BoxFit.contain,
                                                  placeholder:
                                                      (
                                                        context,
                                                        url,
                                                      ) => const Center(
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                  errorWidget:
                                                      (
                                                        context,
                                                        url,
                                                        error,
                                                      ) => Container(
                                                        color: Colors.black,
                                                        child: const Icon(
                                                          Icons.broken_image,
                                                          color: Colors.white,
                                                          size: 80,
                                                        ),
                                                      ),
                                                )
                                            : const Icon(
                                              Icons.image,
                                              color: Colors.white,
                                              size: 80,
                                            ),
                                  ),
                                  // Bottom left: challenge title, description (max 2 lines), show more, and user name
                                  Positioned(
                                    left: 16,
                                    bottom: 32,
                                    right: 100,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Challenge title
                                        Text(
                                          challengeTitle,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 4,
                                                color: Colors.black54,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        // Description/caption with show more
                                        _DescriptionWithShowMore(
                                          description: submission.caption,
                                          onShowMore: () {
                                            showModalBottomSheet(
                                              context: context,
                                              // Use app theme background color
                                              shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            20,
                                                          ),
                                                        ),
                                                  ),
                                              builder:
                                                  (context) => Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          24.0,
                                                        ),
                                                    child: SingleChildScrollView(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Description',
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 18,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 16,
                                                          ),
                                                          Text(
                                                            submission.caption,
                                                            style:
                                                                const TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  fontSize: 16,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        // User name (full name)
                                        Text(
                                          fullName,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 4,
                                                color: Colors.black54,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Right: profile image above action buttons
                                  Positioned(
                                    right: 16,
                                    bottom: 180,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Profile image (for TikTok style)
                                        GestureDetector(
                                          onTap: () {
                                            FullScreenFunctionality.viewProfile(
                                              context: context,
                                              userId: submission.userId,
                                            );
                                          },
                                          child: CircleAvatar(
                                            radius: 28,
                                            backgroundColor: Colors.white24,
                                            backgroundImage:
                                                profileImageUrl.isNotEmpty
                                                    ? NetworkImage(
                                                      profileImageUrl,
                                                    )
                                                    : null,
                                            child:
                                                profileImageUrl.isEmpty
                                                    ? Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                      size: 32,
                                                    )
                                                    : null,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _ActionButton(
                                          icon:
                                              liked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                          label: 'Like',
                                          onTap: () async {
                                            await FullScreenFunctionality.likeSubmission(
                                              challengeId:
                                                  submission.challengeId,
                                              submissionId: submission.id,
                                              submissionOwnerId:
                                                  submission.userId,
                                              context: context,
                                            );
                                          },
                                          count: likeCount,
                                        ),
                                        const SizedBox(height: 24),
                                        // Comment button
                                        _ActionButton(
                                          icon: Icons.comment,
                                          label: 'Comment',
                                          onTap: () async {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled:
                                                  true, // Ensure modal resizes with keyboard
                                              shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            20,
                                                          ),
                                                        ),
                                                  ),
                                              builder:
                                                  (context) => SafeArea(
                                                    child: Container(
                                                      constraints:
                                                          BoxConstraints(
                                                            maxHeight:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.height *
                                                                0.95,
                                                            minHeight:
                                                                MediaQuery.of(
                                                                  context,
                                                                ).size.height *
                                                                0.4,
                                                          ),
                                                      child:
                                                          ChallengeCommentSection(
                                                            challengeId:
                                                                submission
                                                                    .challengeId,
                                                            submissionId:
                                                                submission.id,
                                                          ),
                                                    ),
                                                  ),
                                            );
                                          },
                                          count: commentCount,
                                        ),
                                        const SizedBox(height: 24),
                                        _ActionButton(
                                          icon: Icons.share,
                                          label: 'Share',
                                          onTap: () async {
                                            await FullScreenFunctionality.shareSubmission(
                                              challengeId:
                                                  submission.challengeId,
                                              submissionId: submission.id,
                                              submissionOwnerId:
                                                  submission.userId,
                                              context: context,
                                            );
                                          },
                                          count: shareCount,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DescriptionWithShowMore extends StatefulWidget {
  final String description;
  final VoidCallback onShowMore;
  const _DescriptionWithShowMore({
    required this.description,
    required this.onShowMore,
  });

  @override
  State<_DescriptionWithShowMore> createState() =>
      _DescriptionWithShowMoreState();
}

class _DescriptionWithShowMoreState extends State<_DescriptionWithShowMore> {
  bool _isOverflowing = false;
  final _key = GlobalKey();

  @override
  void didUpdateWidget(covariant _DescriptionWithShowMore oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  void _checkOverflow() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final size = renderBox.size;
      final textPainter = TextPainter(
        text: TextSpan(
          text: widget.description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
          ),
        ),
        maxLines: 2,
        textDirection: TextDirection.ltr,
        ellipsis: '...',
      )..layout(maxWidth: size.width);
      setState(() {
        _isOverflowing = textPainter.didExceedMaxLines;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.description,
            key: _key,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ),
        if (_isOverflowing)
          GestureDetector(
            onTap: widget.onShowMore,
            child: const Padding(
              padding: EdgeInsets.only(left: 8.0, top: 2),
              child: Text(
                'Show more',
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int? count;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
              if (count != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
