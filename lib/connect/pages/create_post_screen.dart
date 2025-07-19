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

// Placeholder GradientButton widget (replace with actual implementation if available)
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const GradientButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeLight.theme;
    final colorScheme = theme.colorScheme;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: colorScheme.primary,
      ),
      onPressed: onTap,
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
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

  @override
  void initState() {
    super.initState();
    _hubService.getHubsStream().listen((hubs) {
      print('Fetched hubs: ${hubs.map((h) => h.name).toList()}');
      setState(() {
        _allHubs = hubs;
      });
    });
    _hubController.addListener(_onHubTextChanged);
    _fetchProfile();
  }

  void _onHubTextChanged() {
    final input = _hubController.text.trim().toLowerCase();
    print('User typed: $input');
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
      print('Filtered hubs: ${_filteredHubs.map((h) => h.name).toList()}');
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
    for (var c in _pollOptionControllers) {
      c.dispose();
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a hub from the dropdown')),
      );
      return;
    }
    if (_postType == 'text' && _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter post content')),
      );
      return;
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
      imageUrl = await _uploadImage(_imagePath!);
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
        postContent: _postType == 'text' ? _contentController.text.trim() : '',
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
          const SnackBar(content: Text('Post created successfully!')),
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
    final theme = AppThemeLight.theme;
    final colorScheme = theme.colorScheme;
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
                : BorderSide(color: AppThemeLight.border, width: 1),
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
    final theme = AppThemeLight.theme;
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
            color: colorScheme.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppThemeLight.border),
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
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.redAccent,
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
    final theme = AppThemeLight.theme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _hubController,
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
              vertical: 20,
              horizontal: 20,
            ),
          ),
        ),
        if (_showDropdown && _filteredHubs.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.08),
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

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeLight.theme;
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
        ),
        body:
            _profileLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User info row
                      if (_profile != null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage:
                                    _profile!.profilePicUrl.isNotEmpty
                                        ? NetworkImage(_profile!.profilePicUrl)
                                        : null,
                                backgroundColor: colorScheme.primary
                                    .withOpacity(0.1),
                                child:
                                    _profile!.profilePicUrl.isEmpty
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              Switch(
                                value: _postAnonymously,
                                onChanged: (val) {
                                  setState(() {
                                    _postAnonymously = val;
                                  });
                                },
                                activeColor: colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text('Anonymous', style: textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      if (_profile != null) const SizedBox(height: 12),
                      Divider(
                        thickness: 1.2,
                        color: colorScheme.primary.withOpacity(0.12),
                      ),
                      const SizedBox(height: 10),
                      _buildHubSelector(),
                      const SizedBox(height: 18),
                      _buildTypeSelector(),
                      const SizedBox(height: 18),
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        color: colorScheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 22,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_postType == 'text')
                                TextField(
                                  controller: _contentController,
                                  style: textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.edit,
                                      color: colorScheme.primary,
                                    ),
                                    labelText: 'Post Content',
                                    labelStyle: textTheme.labelLarge,
                                    hintText: 'What\'s on your mind?',
                                    hintStyle: textTheme.bodyMedium,
                                    filled: true,
                                    fillColor: colorScheme.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                      horizontal: 20,
                                    ),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: 5,
                                  minLines: 3,
                                ),
                              if (_postType == 'image')
                                Column(
                                  children: [
                                    ProfileImagePicker(
                                      imagePath: _imagePath,
                                      onImagePicked: (path) {
                                        setState(() {
                                          _imagePath = path;
                                        });
                                      },
                                    ),
                                    if (_imagePath != null)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 8.0,
                                        ),
                                        child: Text(
                                          'Image selected',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              if (_postType == 'link')
                                TextField(
                                  controller: _linkController,
                                  style: textTheme.bodyLarge,
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(
                                      Icons.link,
                                      color: colorScheme.primary,
                                    ),
                                    labelText: 'Link URL',
                                    labelStyle: textTheme.labelLarge,
                                    hintText: 'Paste your link here',
                                    hintStyle: textTheme.bodyMedium,
                                    filled: true,
                                    fillColor: colorScheme.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                      horizontal: 20,
                                    ),
                                  ),
                                ),
                              if (_postType == 'poll') _buildPollOptions(),
                              const SizedBox(height: 18),
                              GradientButton(
                                text: _isLoading ? 'Posting...' : 'Create Post',
                                onTap: _isLoading ? () {} : _createPost,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
