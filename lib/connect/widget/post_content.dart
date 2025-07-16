import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.postType == 'poll' && widget.pollData != null) {
      _pollData = Map<String, dynamic>.from(widget.pollData!);
      _getUserVote();
    }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.postType == 'text')
          Text(
            widget.postContent,
            style: const TextStyle(fontSize: 13),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        if (widget.postType == 'image' && widget.postImage != null) ...[
          GestureDetector(
            onTap: () {
              // Optionally show full image in a dialog or new screen
              showDialog(
                context: context,
                builder:
                    (_) => Dialog(
                      child: InteractiveViewer(
                        child: Image.network(widget.postImage!),
                      ),
                    ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  widget.postImage!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
        if (widget.postType == 'link' && widget.linkUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Card(
              color: const Color(0xFF232733),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: const Icon(Icons.link, color: Color(0xFF00F6FF)),
                title: Text(
                  widget.linkUrl!,
                  style: const TextStyle(
                    color: Color(0xFF00F6FF),
                    decoration: TextDecoration.underline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new, color: Color(0xFF00F6FF)),
                  onPressed: () async {
                    final url = Uri.tryParse(widget.linkUrl!);
                    if (url != null && await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open link.')),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        if (widget.postType == 'poll' && _pollData != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Poll:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...List.generate(
                  (_pollData!['options'] as List).length,
                  (idx) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: GestureDetector(
                      onTap:
                          _userVotedOptionIdx == null && !_isVoting
                              ? () => _votePollOption(idx)
                              : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color:
                              _userVotedOptionIdx == idx
                                  ? const Color(0xFF00F6FF).withOpacity(0.2)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                _userVotedOptionIdx == idx
                                    ? const Color(0xFF00F6FF)
                                    : Colors.grey[700]!,
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
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _pollData!['options'][idx],
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            if (_pollData!['votes'] != null)
                              Text(
                                ' (${_pollData!['votes'][idx]})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
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
          ),
      ],
    );
  }
}
