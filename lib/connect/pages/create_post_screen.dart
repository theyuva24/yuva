import 'package:flutter/material.dart';
import '../service/post_service.dart';
import '../service/hub_service.dart';
import '../models/hub_model.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/gradient_button.dart';
import '../../registration/widgets/profile_image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

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
  bool _isLoading = false;
  List<Hub> _allHubs = [];
  List<Hub> _filteredHubs = [];
  bool _showDropdown = false;
  Hub? _selectedHub;
  String _postType = 'text';
  String? _imagePath;
  String? _uploadedImageUrl;
  final TextEditingController _linkController = TextEditingController();
  List<TextEditingController> _pollOptionControllers = [
    TextEditingController(),
  ];

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
  }

  void _onHubTextChanged() {
    final input = _hubController.text.trim().toLowerCase();
    print('User typed: ${input}');
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
    try {
      await _postService.createPost(
        hubId: _selectedHub!.id,
        hubName: _selectedHub!.name,
        postContent: _postType == 'text' ? _contentController.text.trim() : '',
        postImageUrl: imageUrl,
        pollData: pollData,
        linkUrl: _postType == 'link' ? _linkController.text.trim() : null,
        postType: _postType,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
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
        _buildTypeButton('text', Icons.text_fields, 'Text'),
        _buildTypeButton('image', Icons.image, 'Image'),
        _buildTypeButton('link', Icons.link, 'Link'),
        _buildTypeButton('poll', Icons.poll, 'Poll'),
      ],
    );
  }

  Widget _buildTypeButton(String type, IconData icon, String label) {
    final selected = _postType == type;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF00F6FF) : Colors.grey[800],
        foregroundColor: selected ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._pollOptionControllers.asMap().entries.map((entry) {
          final idx = entry.key;
          final controller = entry.value;
          return Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Option ${idx + 1}',
                    labelStyle: const TextStyle(color: Color(0xFF00F6FF)),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed:
                    _pollOptionControllers.length > 1
                        ? () {
                          setState(() {
                            _pollOptionControllers.removeAt(idx);
                          });
                        }
                        : null,
              ),
            ],
          );
        }),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _pollOptionControllers.add(TextEditingController());
            });
          },
          icon: const Icon(Icons.add, color: Color(0xFF00F6FF)),
          label: const Text(
            'Add Option',
            style: TextStyle(color: Color(0xFF00F6FF)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181C23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181C23),
        elevation: 0,
        title: Text(
          'Create Post',
          style: GoogleFonts.orbitron(
            textStyle: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00F6FF),
              letterSpacing: 2,
              shadows: [
                Shadow(
                  blurRadius: 24,
                  color: Color(0xFF00F6FF),
                  offset: Offset(0, 0),
                ),
              ],
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF00F6FF)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: Stack(
                children: [
                  TextField(
                    controller: _hubController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.hub,
                        color: Color(0xFF00F6FF),
                      ),
                      labelText: 'Hub Name',
                      labelStyle: const TextStyle(color: Color(0xFF00F6FF)),
                      hintText: 'Enter the hub where you want to post',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: const Color(0xFF232733),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Color(0xFF00F6FF),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF00F6FF),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF00F6FF),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                    ),
                  ),
                  if (_showDropdown)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 60,
                      child: Material(
                        color: const Color(0xFF232733),
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 60,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredHubs.length,
                            itemBuilder: (context, index) {
                              final hub = _filteredHubs[index];
                              return ListTile(
                                title: Text(
                                  hub.name,
                                  style: const TextStyle(
                                    color: Color(0xFF00F6FF),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  hub.description,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                onTap: () {
                                  _hubController.text = hub.name;
                                  _selectedHub = hub;
                                  setState(() {
                                    _showDropdown = false;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_postType == 'text')
              Expanded(
                child: TextField(
                  controller: _contentController,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.edit,
                      color: Color(0xFF00F6FF),
                    ),
                    labelText: 'Post Content',
                    labelStyle: const TextStyle(color: Color(0xFF00F6FF)),
                    hintText: 'What\'s on your mind?',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFF232733),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF00F6FF),
                        width: 1.5,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF00F6FF),
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF00F6FF),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                ),
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
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Image selected',
                        style: TextStyle(color: Colors.green[300]),
                      ),
                    ),
                ],
              ),
            if (_postType == 'link')
              TextField(
                controller: _linkController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.link, color: Color(0xFF00F6FF)),
                  labelText: 'Link URL',
                  labelStyle: const TextStyle(color: Color(0xFF00F6FF)),
                  hintText: 'Paste your link here',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFF232733),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF00F6FF),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF00F6FF),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF00F6FF),
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
            const SizedBox(height: 16),
            GradientButton(
              onPressed: _isLoading ? null : _createPost,
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00F6FF),
                          ),
                        ),
                      )
                      : const Text(
                        'Create Post',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: 1.2,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
