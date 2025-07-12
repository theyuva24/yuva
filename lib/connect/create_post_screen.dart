import 'package:flutter/material.dart';
import 'post_service.dart';
import 'hubs/service/hub_service.dart';
import 'hubs/model/hub_model.dart';

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
    super.dispose();
  }

  Future<void> _createPost() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter post content')),
      );
      return;
    }

    if (_hubController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter hub name')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _postService.createPost(
        hubName: _hubController.text.trim(),
        postContent: _contentController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 120, // enough space for the dropdown
              child: Stack(
                children: [
                  TextField(
                    controller: _hubController,
                    decoration: const InputDecoration(
                      labelText: 'Hub Name',
                      hintText: 'Enter the hub where you want to post',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_showDropdown)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 60,
                      child: Material(
                        elevation: 2,
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          height: 60, // or more for more items
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredHubs.length,
                            itemBuilder: (context, index) {
                              final hub = _filteredHubs[index];
                              return ListTile(
                                title: Text(hub.name),
                                subtitle: Text(hub.description),
                                onTap: () {
                                  _hubController.text = hub.name;
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
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Post Content',
                  hintText: 'What\'s on your mind?',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Create Post',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
