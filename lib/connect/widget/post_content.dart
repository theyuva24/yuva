import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';

/// Widget to display ONLY the post content (text, image, link, poll) and direct interactions (open image, open link, vote poll, show poll results).
/// No header, no interaction bar, no share/report/vote/comment logic.
class PostContent extends StatefulWidget {
  final String postId;
  final String postContent;
  final String? postImage;
  final String postType; // text, image, link, poll
  final String? linkUrl;
  final Map<String, dynamic>? pollData;

  const PostContent({
    Key? key,
    required this.postId,
    required this.postContent,
    this.postImage,
    required this.postType,
    this.linkUrl,
    this.pollData,
  }) : super(key: key);

  @override
  State<PostContent> createState() => _PostContentState();
}

class _PostContentState extends State<PostContent> {
  int? _userVotedOptionIdx;
  bool _isVoting = false;
  Map<String, dynamic>? _pollData;
  TapGestureRecognizer? _linkTapRecognizer;

  @override
  void initState() {
    super.initState();
    if (widget.postType == 'poll' && widget.pollData != null) {
      _pollData = Map<String, dynamic>.from(widget.pollData!);
      _getUserVote();
    }
    _linkTapRecognizer = TapGestureRecognizer();
  }

  @override
  void dispose() {
    _linkTapRecognizer?.dispose();
    super.dispose();
  }

  Future<void> _getUserVote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.pollData == null) return;
    final postId = widget.postId;
    final voteDoc =
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('pollVotes')
            .doc(user.uid)
            .get();
    if (voteDoc.exists) {
      setState(() {
        _userVotedOptionIdx = voteDoc.data()?['optionIdx'];
      });
    }
  }

  Future<void> _votePollOption(int idx) async {
    if (_isVoting || _userVotedOptionIdx != null) return;
    setState(() {
      _isVoting = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to vote.')),
      );
      setState(() {
        _isVoting = false;
      });
      return;
    }
    try {
      final postRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId);
      final pollVotesRef = postRef.collection('pollVotes').doc(user.uid);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postSnap = await transaction.get(postRef);
        if (!postSnap.exists) throw Exception('Post not found');
        final pollData = Map<String, dynamic>.from(
          postSnap.data()!['pollData'] ?? {},
        );
        final votes = List<int>.from(pollData['votes'] ?? []);
        votes[idx] = (votes[idx] ?? 0) + 1;
        pollData['votes'] = votes;
        transaction.update(postRef, {'pollData': pollData});
        transaction.set(pollVotesRef, {'optionIdx': idx});
        setState(() {
          _pollData = pollData;
        });
      });
      setState(() {
        _userVotedOptionIdx = idx;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to vote: $e')));
    } finally {
      setState(() {
        _isVoting = false;
      });
    }
  }

  Future<void> _openUrlWithFallback(String urlString) async {
    debugPrint('Attempting to open URL: $urlString');
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) {
      debugPrint('Invalid URL: $urlString');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid URL.')));
      }
      return;
    }
    try {
      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('launchUrl externalApplication success: $success');
        if (!success) {
          // Fallback to in-app webview
          debugPrint('Falling back to in-app webview for $urlString');
          final webviewSuccess = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
          debugPrint('launchUrl inAppWebView success: $webviewSuccess');
          if (!webviewSuccess && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open link.')),
            );
          }
        }
      } else {
        debugPrint('canLaunchUrl returned false for $urlString');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
        }
      }
    } catch (e) {
      debugPrint('Error opening URL $urlString: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Always show text content if present
        if (widget.postContent.trim().isNotEmpty)
          _buildTextContent(widget.postContent),
        // Show image if present
        if (widget.postImage != null && widget.postImage!.isNotEmpty) ...[
          _buildImageContent(widget.postImage!),
        ],
        // Show link if present
        if (widget.linkUrl != null && widget.linkUrl!.isNotEmpty)
          _buildLinkContent(widget.linkUrl!),
        // Show poll if present and data loaded
        if (widget.postType == 'poll' && _pollData != null) _buildPollContent(),
      ],
    );
  }

  Widget _buildTextContent(String text) {
    final urlRegex = RegExp(r'(https?:\/\/[^\s]+)');
    final spans = <TextSpan>[];
    int start = 0;
    urlRegex.allMatches(text).forEach((match) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: const TextStyle(
            color: Color(0xFF00F6FF),
            decoration: TextDecoration.underline,
          ),
          recognizer:
              _linkTapRecognizer!
                ..onTap = () async {
                  await _openUrlWithFallback(url);
                },
        ),
      );
      start = match.end;
    });
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text.rich(
        TextSpan(children: spans),
        style: const TextStyle(fontSize: 13),
        maxLines: 6,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImageContent(String imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder:
                (_) => Dialog(
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      placeholder:
                          (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                      errorWidget:
                          (context, url, error) => Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                    ),
                  ),
                ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder:
                  (context, url) =>
                      const Center(child: CircularProgressIndicator()),
              errorWidget:
                  (context, url, error) => Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkContent(String urlString) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: GestureDetector(
        onTap: () async {
          await _openUrlWithFallback(urlString);
        },
        child: Text(
          urlString,
          style: const TextStyle(
            color: Color(0xFF00F6FF),
            decoration: TextDecoration.underline,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildPollContent() {
    final options = List<String>.from(_pollData!['options'] ?? []);
    final votes = List<int>.from(
      _pollData!['votes'] ?? List.filled(options.length, 0),
    );
    final totalVotes = votes.fold<int>(0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Poll:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...List.generate(
            options.length,
            (idx) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: GestureDetector(
                onTap:
                    _userVotedOptionIdx == null && !_isVoting
                        ? () => _votePollOption(idx)
                        : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color:
                        _userVotedOptionIdx == idx
                            ? const Color(0xFF00F6FF).withAlpha(51)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _userVotedOptionIdx == idx
                              ? const Color(0xFF00F6FF)
                              : Colors.grey[700]!,
                      width: _userVotedOptionIdx == idx ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _userVotedOptionIdx == idx
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color:
                            _userVotedOptionIdx == idx
                                ? const Color(0xFF00F6FF)
                                : Colors.grey,
                        semanticLabel:
                            _userVotedOptionIdx == idx
                                ? 'Selected'
                                : 'Not selected',
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          options[idx],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (votes.isNotEmpty)
                        Text(
                          ' (${votes[idx]})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      if (_userVotedOptionIdx != null && totalVotes > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            width: 60,
                            child: LinearProgressIndicator(
                              value: votes[idx] / totalVotes,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _userVotedOptionIdx == idx
                                    ? const Color(0xFF00F6FF)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isVoting)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(),
            ),
          if (_userVotedOptionIdx != null)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'You have voted.',
                style: TextStyle(color: Color(0xFF00F6FF)),
              ),
            ),
        ],
      ),
    );
  }
}
