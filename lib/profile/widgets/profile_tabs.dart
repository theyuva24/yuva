import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import 'interests_section.dart';
import '../../connect/widget/post_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../universal/theme/app_theme.dart';
import '../../connect/service/post_service.dart';
import '../../connect/models/post_model.dart';
import '../../connect/pages/post_details_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../registration/widgets/college_autocomplete_field.dart';
import '../../registration/widgets/course_autocomplete_field.dart';
import '../../registration/widgets/id_card_picker.dart';

typedef BioChangedCallback = Future<void> Function(String newBio);
typedef EducationChangedCallback =
    Future<void> Function(
      String college,
      String course,
      String year,
      String educationLevel,
      String idCardUrl,
    );

class ProfileTabs extends StatefulWidget {
  final ProfileModel profile;
  final BioChangedCallback? onBioChanged;
  final EducationChangedCallback? onEducationChanged;
  const ProfileTabs({
    Key? key,
    required this.profile,
    this.onBioChanged,
    this.onEducationChanged,
  }) : super(key: key);

  @override
  State<ProfileTabs> createState() => _ProfileTabsState();
}

class _ProfileTabsState extends State<ProfileTabs> {
  bool _editingBio = false;
  String _bioDraft = '';
  TextEditingController? _bioController;

  bool _editingEducation = false;
  String _collegeDraft = '';
  String _educationLevelDraft = '';
  String _courseDraft = '';
  String _yearDraft = '';
  String? _idCardDraft;

  @override
  void initState() {
    super.initState();
    _bioDraft = widget.profile.bio;
  }

  @override
  void dispose() {
    _bioController?.dispose();
    super.dispose();
  }

  int get _bioCharCount => _bioDraft.length;

  void _startEditingBio() {
    setState(() {
      _editingBio = true;
      _bioDraft = widget.profile.bio;
      _bioController = TextEditingController(text: _bioDraft);
    });
  }

  void _cancelEditingBio() {
    setState(() {
      _editingBio = false;
      _bioDraft = widget.profile.bio;
      _bioController?.dispose();
      _bioController = null;
    });
  }

  Future<void> _saveBio() async {
    if (_bioDraft.trim().isNotEmpty && widget.onBioChanged != null) {
      await widget.onBioChanged!(_bioDraft.trim());
      setState(() {
        _editingBio = false;
        _bioController?.dispose();
        _bioController = null;
      });
    }
  }

  void _startEditingEducation() {
    setState(() {
      _editingEducation = true;
      _collegeDraft = widget.profile.college;
      _educationLevelDraft =
          widget.profile.educationLevel.isNotEmpty
              ? widget.profile.educationLevel
              : 'Under Graduation';
      _courseDraft = widget.profile.course;
      _yearDraft = widget.profile.year;
      _idCardDraft = widget.profile.idCardUrl;
    });
  }

  void _cancelEditingEducation() {
    setState(() {
      _editingEducation = false;
      _collegeDraft = widget.profile.college;
      _educationLevelDraft =
          widget.profile.educationLevel.isNotEmpty
              ? widget.profile.educationLevel
              : 'Under Graduation';
      _courseDraft = widget.profile.course;
      _yearDraft = widget.profile.year;
      _idCardDraft = widget.profile.idCardUrl;
    });
  }

  Future<void> _saveEducation() async {
    if (widget.onEducationChanged != null) {
      await widget.onEducationChanged!(
        _collegeDraft.trim(),
        _courseDraft.trim(),
        _yearDraft.trim(),
        _educationLevelDraft,
        _idCardDraft ?? '',
      );
      setState(() {
        _editingEducation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final PostService postService = PostService();
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppThemeLight.background,
            child: const TabBar(
              indicatorColor: AppThemeLight.primary,
              labelColor: AppThemeLight.textDark,
              unselectedLabelColor: AppThemeLight.textLight,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: [Tab(text: "About Me"), Tab(text: "Posts")],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // About Me Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bio Card
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 20.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Bio",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                    if (!_editingBio)
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        tooltip: 'Edit Bio',
                                        onPressed: _startEditingBio,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_editingBio)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextField(
                                        maxLength: 160,
                                        maxLines: 4,
                                        minLines: 1,
                                        autofocus: true,
                                        controller: _bioController,
                                        onChanged:
                                            (val) =>
                                                setState(() => _bioDraft = val),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black87,
                                        ),
                                        decoration: InputDecoration(
                                          hintText:
                                              'Write something about yourself',
                                          counterText: '${_bioCharCount}/160',
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          disabledBorder: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: _cancelEditingBio,
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                _bioDraft.trim().isEmpty
                                                    ? null
                                                    : _saveBio,
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    widget.profile.bio.isNotEmpty
                                        ? widget.profile.bio
                                        : 'No bio added yet.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontStyle: FontStyle.italic,
                                      color:
                                          widget.profile.bio.isNotEmpty
                                              ? Colors.black87
                                              : Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Education Card
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 20.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Education",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                    if (!_editingEducation)
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        tooltip: 'Edit Education',
                                        onPressed: _startEditingEducation,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (_editingEducation)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CollegeAutocompleteField(
                                        initialValue: _collegeDraft,
                                        onSelected:
                                            (val) => setState(
                                              () => _collegeDraft = val,
                                            ),
                                      ),
                                      const SizedBox(height: 20),
                                      DropdownButtonFormField<String>(
                                        value: _educationLevelDraft,
                                        items:
                                            [
                                                  'Under Graduation',
                                                  'Post Graduation',
                                                ]
                                                .map(
                                                  (level) => DropdownMenuItem(
                                                    value: level,
                                                    child: Text(level),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (val) {
                                          if (val != null)
                                            setState(
                                              () => _educationLevelDraft = val,
                                            );
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Education Level',
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      CourseAutocompleteField(
                                        initialValue: _courseDraft,
                                        onSelected:
                                            (val) => setState(
                                              () => _courseDraft = val,
                                            ),
                                        educationLevel: _educationLevelDraft,
                                      ),
                                      const SizedBox(height: 20),
                                      DropdownButtonFormField<String>(
                                        value:
                                            _yearDraft.isNotEmpty
                                                ? _yearDraft
                                                : null,
                                        items:
                                            (_educationLevelDraft ==
                                                        'Post Graduation'
                                                    ? [
                                                      '1st year',
                                                      '2nd year',
                                                      'Alumni',
                                                    ]
                                                    : [
                                                      '1st year',
                                                      '2nd year',
                                                      '3rd year',
                                                      '4th year',
                                                      '5th year',
                                                      'Alumni',
                                                    ])
                                                .map(
                                                  (y) => DropdownMenuItem(
                                                    value: y,
                                                    child: Text(y),
                                                  ),
                                                )
                                                .toList(),
                                        onChanged: (val) {
                                          if (val != null)
                                            setState(() => _yearDraft = val);
                                        },
                                        decoration: const InputDecoration(
                                          labelText: 'Year',
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      Text(
                                        'College ID Image',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      IdCardPicker(
                                        imagePath: _idCardDraft,
                                        onImagePicked:
                                            (path) => setState(
                                              () => _idCardDraft = path,
                                            ),
                                      ),
                                      const SizedBox(height: 18),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: _cancelEditingEducation,
                                            child: const Text('Cancel'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed:
                                                _collegeDraft.trim().isEmpty ||
                                                        _courseDraft
                                                            .trim()
                                                            .isEmpty ||
                                                        _yearDraft
                                                            .trim()
                                                            .isEmpty ||
                                                        _educationLevelDraft
                                                            .isEmpty ||
                                                        (_idCardDraft == null ||
                                                            _idCardDraft!
                                                                .isEmpty)
                                                    ? null
                                                    : _saveEducation,
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else ...[
                                  Text(
                                    'College:  ${widget.profile.college}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Education Level:  ${widget.profile.educationLevel}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Course:  ${widget.profile.course}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Year:  ${widget.profile.year}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (widget.profile.idCardUrl.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'College ID Image:',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.network(
                                            widget.profile.idCardUrl,
                                            width: double.infinity,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Interests Section
                      const SizedBox(height: 24),
                      const Text(
                        "Interests",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 8),
                      widget.profile.interests.isNotEmpty
                          ? Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children:
                                widget.profile.interests
                                    .map(
                                      (interest) => Chip(
                                        label: Text(
                                          interest,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: Colors.blue
                                            .withOpacity(0.15),
                                        labelStyle: const TextStyle(
                                          color: Colors.blue,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          side: const BorderSide(
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          )
                          : const Text(
                            'No interests added yet.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                    ],
                  ),
                ),
                // Posts Tab
                RefreshIndicator(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 800));
                  },
                  color: AppThemeLight.primary,
                  child: StreamBuilder<List<Post>>(
                    stream: postService.getPostsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppThemeLight.primary,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppThemeLight.primary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading posts',
                                style: TextStyle(
                                  color: AppThemeLight.primary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  (context as Element).markNeedsBuild();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;
                      final userPosts =
                          (snapshot.data ?? [])
                              .where(
                                (post) =>
                                    post.postOwnerId == widget.profile.uid,
                              )
                              .where((post) {
                                // Only show anonymous posts to the owner
                                if (widget.profile.uid == currentUserId) {
                                  return true;
                                } else {
                                  return !post.isAnonymous;
                                }
                              })
                              .toList();
                      if (userPosts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.forum_outlined,
                                size: 64,
                                color: AppThemeLight.textLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No posts yet',
                                style: TextStyle(
                                  color: AppThemeLight.textLight,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: userPosts.length,
                        itemBuilder: (context, index) {
                          final post = userPosts[index];
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: PostCard(
                              key: ValueKey(post.id),
                              postId: post.id,
                              userName: post.userName,
                              userProfileImage: post.userProfileImage,
                              hubName: post.hubName,
                              hubProfileImage: post.hubProfileImage,
                              postContent: post.postContent,
                              timestamp: post.timestamp,
                              upvotes: post.upvotes,
                              downvotes: post.downvotes,
                              commentCount: post.commentCount,
                              shareCount: post.shareCount,
                              postImage: post.postImage,
                              postOwnerId: post.postOwnerId,
                              postType: post.postType,
                              linkUrl: post.linkUrl,
                              pollData: post.pollData,
                              hubId: post.hubId,
                              onCardTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => PostDetailsPage(
                                          postId: post.id,
                                          userName: post.userName,
                                          userProfileImage:
                                              post.userProfileImage,
                                          hubName: post.hubName,
                                          hubProfileImage: post.hubProfileImage,
                                          postContent: post.postContent,
                                          timestamp: post.timestamp,
                                          upvotes: post.upvotes,
                                          downvotes: post.downvotes,
                                          commentCount: post.commentCount,
                                          shareCount: post.shareCount,
                                          postImage: post.postImage,
                                          postOwnerId: post.postOwnerId,
                                          postType: post.postType,
                                          linkUrl: post.linkUrl,
                                          pollData: post.pollData,
                                        ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
