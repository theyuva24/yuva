import 'package:flutter/material.dart';
import '../service/post_service.dart';
import '../service/hub_service.dart';
import '../models/hub_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../universal/theme/app_theme.dart';
import '../../registration/widgets/profile_image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../profile/services/profile_service.dart';
import '../../profile/models/profile_model.dart';
import '../../initial pages/auth_service.dart';
import '../../connect/pages/connect_page.dart';
import '../../universal/screens/home_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// Placeholder GradientButton widget (replace with actual implementation if available)
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const GradientButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: colorScheme.primary,
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final PostService _postService = PostService();
  final HubService _hubService = HubService();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _hubController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  late FocusNode _contentFocusNode; // Add this line
  bool _isLoading = false;
  List<Hub> _allHubs = [];
  List<Hub> _filteredHubs = [];
  bool _showDropdown = false;
  Hub? _selectedHub;
  String _postType = 'text';
  String? _imagePath;
  List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
  ];
  bool _postAnonymously = false;
  ProfileModel? _profile;
  bool _profileLoading = true;
  String? _originalImagePath;
  String? _compressedImagePath;
  Future<void>? _compressionFuture;
  List<String> _joinedHubIds = [];
  late FocusNode _hubFocusNode;

  // 1. Add canPost logic
  bool get _canPost {
    return _contentController.text.trim().isNotEmpty ||
        _imagePath != null ||
        _linkController.text.trim().isNotEmpty ||
        _pollOptionControllers.any((c) => c.text.trim().isNotEmpty);
  }

  @override
  void initState() {
    super.initState();
    _hubFocusNode = FocusNode();
    _contentFocusNode = FocusNode(); // Add this line
    _hubService.getHubsStream().listen((hubs) {
      setState(() {
        _allHubs = hubs;
      });
    });
    _hubService.getJoinedHubsStream().listen((joinedIds) {
      setState(() {
        _joinedHubIds = joinedIds;
      });
    });
    _hubController.addListener(_onHubTextChanged);
    _hubFocusNode.addListener(_onHubFocusChanged);
    _contentController.addListener(() {
      setState(() {});
    });
    _fetchProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentFocusNode
          .requestFocus(); // Add this line to request focus after build
    });
  }

  void _onHubFocusChanged() {
    if (_hubFocusNode.hasFocus && _hubController.text.trim().isEmpty) {
      // Show joined hubs or trending hubs
      List<Hub> hubsToShow = [];
      if (_joinedHubIds.isNotEmpty) {
        hubsToShow =
            _allHubs.where((hub) => _joinedHubIds.contains(hub.id)).toList();
      } else {
        hubsToShow = List<Hub>.from(_allHubs);
        hubsToShow.sort(
          (a, b) => (b.popularityScore ?? 0).compareTo(a.popularityScore ?? 0),
        );
        // No .take(10) here; show all, but limit visible items via maxHeight
      }
      setState(() {
        _filteredHubs = hubsToShow;
        _showDropdown = _filteredHubs.isNotEmpty;
      });
    }
  }

  void _onHubTextChanged() {
    final input = _hubController.text.trim().toLowerCase();
    if (input.isEmpty) {
      setState(() {
        _filteredHubs = [];
        _showDropdown = false;
      });
      return;
    }
    setState(() {
      _filteredHubs =
          _allHubs
              .where((hub) => hub.name.toLowerCase().startsWith(input))
              .toList();
      _showDropdown = _filteredHubs.isNotEmpty;
    });
  }

  Future<void> _fetchProfile() async {
    final user = AuthService().currentUser;
    if (user != null) {
      final profile = await ProfileService().getProfile(user.uid);
      if (mounted) {
        setState(() {
          _profile = profile;
          _profileLoading = false;
        });
      }
    } else {
      setState(() {
        _profileLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _hubController.dispose();
    _linkController.dispose();
    _contentFocusNode.dispose(); // Add this line
    for (var c in _pollOptionControllers) {
      c.dispose();
    }
    _hubFocusNode.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(String path) async {
    final file = File(path);
    final fileName =
        'posts/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> _createPost() async {
    if (_selectedHub == null) {
      _selectedHub = Hub(
        id: 'yUZnv3EFKPBjNP8GHPyN',
        name: 'Random thoughts',
        description: 'For posts without intent',
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/yuva-1263.firebasestorage.app/o/hubs%2F1752985519021%2Fhub_image.jpg?alt=media&token=75330cca-cb10-497a-aaf6-55e134b11128',
      );
    }
    if (_postType == 'image' && _imagePath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }
    if (_postType == 'link' && _linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a link')));
      return;
    }
    if (_postType == 'poll' &&
        _pollOptionControllers.any((c) => c.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all poll options')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    String? imageUrl;
    if (_postType == 'image' && _imagePath != null) {
      final imagePathToUpload = await _getImageForUpload();
      if (imagePathToUpload != null) {
        imageUrl = await _uploadImage(imagePathToUpload);
      }
    }
    Map<String, dynamic>? pollData;
    if (_postType == 'poll') {
      pollData = {
        'options': _pollOptionControllers.map((c) => c.text.trim()).toList(),
        'votes': List.filled(_pollOptionControllers.length, 0),
      };
    }
    String userName = '';
    String? userProfileImage;
    if (_profile != null) {
      if (_postAnonymously) {
        userName =
            _profile!.uniqueName.isNotEmpty
                ? _profile!.uniqueName
                : 'Anonymous';
        userProfileImage = null;
      } else {
        userName = _profile!.fullName;
        userProfileImage = _profile!.profilePicUrl;
      }
    }
    try {
      await _postService.createPost(
        hubId: _selectedHub!.id,
        hubName: _selectedHub!.name,
        postContent: _contentController.text.trim(),
        postImageUrl: imageUrl,
        pollData: pollData,
        linkUrl: _postType == 'link' ? _linkController.text.trim() : null,
        postType: _postType,
        userName: userName,
        userProfileImage: userProfileImage,
        anonymous: _postAnonymously, // <-- pass the flag explicitly
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Posted in ${_selectedHub!.name} successfully!'),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomeScreen(initialTabIndex: 1),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTypeSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildTypeButton('text', Icons.text_fields, 'Text')),
        Expanded(child: _buildTypeButton('image', Icons.image, 'Image')),
        Expanded(child: _buildTypeButton('link', Icons.link, 'Link')),
        Expanded(child: _buildTypeButton('poll', Icons.poll, 'Poll')),
      ],
    );
  }

  Widget _buildTypeButton(String type, IconData icon, String label) {
    final selected = _postType == type;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? colorScheme.primary : colorScheme.surface,
        foregroundColor:
            selected ? colorScheme.onPrimary : colorScheme.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: selected ? 2 : 0,
        side:
            selected
                ? BorderSide(color: colorScheme.primary, width: 2)
                : BorderSide(color: colorScheme.outline, width: 1),
      ),
      onPressed: () {
        setState(() {
          _postType = type;
        });
      },
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildPollOptions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Poll Options',
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pollOptionControllers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final controller = _pollOptionControllers[idx];
              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Option ${idx + 1}',
                        labelStyle: textTheme.labelLarge,
                        filled: true,
                        fillColor: colorScheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colorScheme.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      style: textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        _pollOptionControllers.length > 1
                            ? IconButton(
                              key: ValueKey('remove_$idx'),
                              icon: Icon(
                                Icons.remove_circle,
                                color: Theme.of(context).colorScheme.error,
                                size: 28,
                              ),
                              onPressed: () {
                                setState(() {
                                  _pollOptionControllers.removeAt(idx);
                                });
                              },
                            )
                            : const SizedBox(width: 28),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _pollOptionControllers.add(TextEditingController());
                });
              },
              icon: Icon(Icons.add_circle_outline, color: colorScheme.primary),
              label: Text(
                'Add Option',
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _hubController,
          focusNode: _hubFocusNode,
          style: textTheme.bodyLarge,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
            labelText: 'Select Hub',
            labelStyle: textTheme.labelLarge,
            hintText: 'Search for a hub...',
            hintStyle: textTheme.bodyMedium,
            filled: true,
            fillColor: colorScheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 20,
            ),
          ),
        ),
        if (_showDropdown && _filteredHubs.isNotEmpty)
          Container(
            constraints: const BoxConstraints(
              maxHeight: 300,
            ), // 5 items * 60px each = 300px
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(20),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredHubs.length,
              itemBuilder: (context, index) {
                final hub = _filteredHubs[index];
                return ListTile(
                  title: Text(hub.name, style: textTheme.bodyLarge),
                  onTap: () {
                    setState(() {
                      _selectedHub = hub;
                      _hubController.text = hub.name;
                      _showDropdown = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _pickPostImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        _postType = 'image';
        _originalImagePath = picked.path;
        _imagePath = picked.path; // Show original immediately
        _compressedImagePath = null;
      });
      // Start compression in background
      _compressionFuture = _compressImageInBackground(picked.path);
    }
  }

  Future<void> _compressImageInBackground(String path) async {
    final compressed = await FlutterImageCompress.compressAndGetFile(
      path,
      '${path}_compressed.jpg',
      quality: 70,
    );
    if (compressed != null) {
      if (mounted && _originalImagePath == path) {
        setState(() {
          _compressedImagePath = compressed.path;
        });
      } else {
        _compressedImagePath = compressed.path;
      }
    }
  }

  Future<String?> _getImageForUpload() async {
    // Wait for compression if it's running
    if (_compressionFuture != null) {
      await _compressionFuture;
    }
    return _compressedImagePath ?? _originalImagePath;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Create Post',
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.2,
            ),
          ),
          iconTheme: IconThemeData(color: colorScheme.primary),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor:
                      _canPost && !_isLoading
                          ? colorScheme.primary
                          : Colors.transparent,
                  foregroundColor:
                      _canPost && !_isLoading
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withAlpha(153),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                ),
                onPressed: _isLoading || !_canPost ? null : _createPost,
                child:
                    _isLoading
                        ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                        : Text(
                          'Post',
                          style: textTheme.bodyLarge?.copyWith(
                            color:
                                _canPost && !_isLoading
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface.withAlpha(153),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
        body:
            _profileLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // User info row (no card), profile image logic, anonymous toggle label below
                            if (_profile != null)
                              Row(
                                children: [
                                  // Profile image or icon based on anonymous mode
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage:
                                        !_postAnonymously &&
                                                _profile!
                                                    .profilePicUrl
                                                    .isNotEmpty
                                            ? NetworkImage(
                                              _profile!.profilePicUrl,
                                            )
                                            : null,
                                    backgroundColor: colorScheme.primary
                                        .withOpacity(0.1),
                                    child:
                                        (_postAnonymously ||
                                                _profile!.profilePicUrl.isEmpty)
                                            ? Icon(
                                              Icons.person,
                                              color: colorScheme.primary,
                                              size: 32,
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _postAnonymously
                                              ? (_profile!.uniqueName.isNotEmpty
                                                  ? _profile!.uniqueName
                                                  : 'Anonymous')
                                              : _profile!.fullName,
                                          style: textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _postAnonymously
                                              ? 'Posting Anonymously'
                                              : 'Posting as yourself',
                                          style: textTheme.bodyMedium?.copyWith(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Switch(
                                        value: _postAnonymously,
                                        onChanged: (val) {
                                          setState(() {
                                            _postAnonymously = val;
                                          });
                                        },
                                        activeColor: colorScheme.primary,
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        _postAnonymously
                                            ? 'Switch to real ID'
                                            : 'Switch to anonymous',
                                        style: textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            if (_profile != null) const SizedBox(height: 12),
                            Divider(
                              thickness: 1.2,
                              color: colorScheme.primary.withAlpha(31),
                            ),
                            const SizedBox(height: 10),
                            _buildHubSelector(),
                            const SizedBox(height: 18),
                            // 6. Open post content input, poll/image/link buttons below
                            // Minimal, natural look for the text field
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: TextField(
                                controller: _contentController,
                                focusNode: _contentFocusNode, // Add this line
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.start,
                                decoration: InputDecoration(
                                  hintText: 'What’s on your mind?',
                                  hintStyle: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withAlpha(153),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  filled: false,
                                ),
                                maxLines: null,
                                minLines: 1,
                              ),
                            ),
                            if (_postType == 'image')
                              Column(
                                children: [
                                  if (_imagePath != null)
                                    Column(
                                      children: [
                                        Image.file(
                                          File(_imagePath!),
                                          height: 180,
                                          fit: BoxFit.cover,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            'Image selected',
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'No image selected',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withAlpha(153),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            if (_postType == 'link')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: TextField(
                                  controller: _linkController,
                                  style: textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    hintText: 'Paste your link here',
                                    hintStyle: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withAlpha(
                                        153,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 0,
                                    ),
                                  ),
                                ),
                              ),
                            if (_postType == 'poll')
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: _buildPollOptions(),
                              ),
                            const SizedBox(height: 18),
                            // GradientButton removed as 'Post' button is already in AppBar
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          bottom: 8,
                          top: 4,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.poll,
                                color: colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _postType = 'poll';
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.image,
                                color: colorScheme.primary,
                              ),
                              onPressed: _pickPostImage,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.link,
                                color: colorScheme.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _postType = 'link';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
