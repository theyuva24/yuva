import 'package:flutter/material.dart';
import '../model/submission_model.dart';
import '../../profile/services/profile_service.dart';
import '../../profile/models/profile_model.dart';
import '../service/challenge_service.dart';
import '../model/challenge_model.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
              print(
                'FullScreenMediaPage: mediaUrl = ${submission.mediaUrl}, thumbnailUrl = ${submission.thumbnailUrl}',
              );
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
                      return Stack(
                        children: [
                          Center(
                            child:
                                submission.mediaUrl != null &&
                                        submission.mediaUrl!.isNotEmpty
                                    ? submission.isVideo
                                        ? ReelsVideoPlayer(
                                          videoUrl: submission.mediaUrl!,
                                          play: index == _currentIndex,
                                        )
                                        : Image.network(
                                          submission.mediaUrl!,
                                          fit: BoxFit.contain,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                      backgroundColor: Colors.black87,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder:
                                          (context) => Padding(
                                            padding: const EdgeInsets.all(24.0),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    'Description',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    submission.caption,
                                                    style: const TextStyle(
                                                      color: Colors.white,
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
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.white24,
                                  backgroundImage:
                                      profileImageUrl.isNotEmpty
                                          ? NetworkImage(profileImageUrl)
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
                                const SizedBox(height: 24),
                                _ActionButton(
                                  icon: Icons.favorite_border,
                                  label: 'Like',
                                  onTap: () {},
                                ),
                                const SizedBox(height: 24),
                                _ActionButton(
                                  icon: Icons.comment,
                                  label: 'Comment',
                                  onTap: () {},
                                ),
                                const SizedBox(height: 24),
                                _ActionButton(
                                  icon: Icons.share,
                                  label: 'Share',
                                  onTap: () {},
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
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
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
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        ],
      ),
    );
  }
}
