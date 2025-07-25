import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../challenge/service/challenge_service.dart';
import '../challenge/model/challenge_model.dart';
import '../registration/widgets/profile_image_picker.dart';
import 'dart:io';
import '../universal/theme/app_theme.dart';

class ChallengeAdminPage extends StatefulWidget {
  const ChallengeAdminPage({Key? key}) : super(key: key);

  @override
  State<ChallengeAdminPage> createState() => _ChallengeAdminPageState();
}

class _ChallengeAdminPageState extends State<ChallengeAdminPage> {
  final ChallengeService _challengeService = ChallengeService();
  late Future<List<Challenge>> _challengesFuture;

  @override
  void initState() {
    super.initState();
    _refreshChallenges();
  }

  void _refreshChallenges() {
    setState(() {
      _challengesFuture = _challengeService.fetchAllChallenges();
    });
  }

  void _openChallengeForm({Challenge? challenge}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChallengeFormPage(
              challenge: challenge,
              challengeService: _challengeService,
            ),
      ),
    );
    if (result == true) _refreshChallenges();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data:
          Theme.of(context).brightness == Brightness.dark
              ? AppThemeDark.theme
              : AppThemeLight.theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Challenge Admin'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.primary,
          ),
          titleTextStyle: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: FutureBuilder<List<Challenge>>(
          future: _challengesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading challenges',
                  style: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppThemeDark.errorText
                            : AppThemeLight.errorText,
                  ),
                ),
              );
            }
            final challenges = snapshot.data ?? [];
            if (challenges.isEmpty) {
              return Center(
                child: Text(
                  'No challenges available.',
                  style: TextStyle(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? AppThemeDark.textSecondary
                            : AppThemeLight.textSecondary,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: challenges.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return Card(
                  child: ListTile(
                    title: Text(
                      challenge.title,
                      style: TextStyle(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppThemeDark.textPrimary
                                : AppThemeLight.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      challenge.description,
                      style: TextStyle(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? AppThemeDark.textSecondary
                                : AppThemeLight.textSecondary,
                      ),
                    ),
                    onTap: () => _openChallengeForm(challenge: challenge),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _openChallengeForm(),
          child: const Icon(Icons.add),
          tooltip: 'Create Challenge',
        ),
      ),
    );
  }
}

class ChallengeFormPage extends StatefulWidget {
  final Challenge? challenge;
  final ChallengeService challengeService;
  const ChallengeFormPage({
    Key? key,
    this.challenge,
    required this.challengeService,
  }) : super(key: key);

  @override
  State<ChallengeFormPage> createState() => _ChallengeFormPageState();
}

class _ChallengeFormPageState extends State<ChallengeFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _skillsController;
  late TextEditingController _postTypeController;
  late TextEditingController _rewardController;
  late TextEditingController _whoCanWinController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late TextEditingController _linkController;
  late TextEditingController _descriptionController;
  String? _imagePath;
  String? _imageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final c = widget.challenge;
    _titleController = TextEditingController(text: c?.title ?? '');
    _skillsController = TextEditingController(text: c?.skills ?? '');
    _postTypeController = TextEditingController(text: c?.postType ?? '');
    _rewardController = TextEditingController(text: c?.prize ?? '');
    _whoCanWinController = TextEditingController(text: c?.whoCanWin ?? '');
    _startDateController = TextEditingController(text: c?.startDate ?? '');
    _endDateController = TextEditingController(text: c?.endDate ?? '');
    _linkController = TextEditingController(text: c?.link ?? '');
    _descriptionController = TextEditingController(text: c?.description ?? '');
    _imageUrl = c?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _skillsController.dispose();
    _postTypeController.dispose();
    _rewardController.dispose();
    _whoCanWinController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _linkController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(String? path, String challengeId) async {
    if (path == null) return null;
    try {
      final ref = FirebaseStorage.instance.ref().child(
        'challenges/$challengeId/image.jpg',
      );
      await ref.putFile(File(path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Failed to upload challenge image: $e');
      return null;
    }
  }

  Future<void> _saveChallenge() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      String challengeId =
          widget.challenge?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();
      String imageUrl = _imageUrl ?? '';
      if (_imagePath != null) {
        final uploadedUrl = await _uploadImage(_imagePath, challengeId);
        if (uploadedUrl != null) imageUrl = uploadedUrl;
      }
      final challenge = Challenge(
        id: widget.challenge?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        deadline:
            _endDateController.text.trim().isNotEmpty
                ? Timestamp.fromDate(
                  DateTime.parse(_endDateController.text.trim()),
                )
                : Timestamp.now(),
        prize: _rewardController.text.trim(),
        createdBy: '', // Set as needed
        skills: _skillsController.text.trim(),
        postType: _postTypeController.text.trim(),
        whoCanWin: _whoCanWinController.text.trim(),
        startDate: _startDateController.text.trim(),
        endDate: _endDateController.text.trim(),
        link: _linkController.text.trim(),
      );
      if (widget.challenge == null) {
        await widget.challengeService.addChallenge(challenge);
      } else {
        await widget.challengeService.updateChallenge(challenge);
      }
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save challenge: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data:
          Theme.of(context).brightness == Brightness.dark
              ? AppThemeDark.theme
              : AppThemeLight.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.challenge == null ? 'Create Challenge' : 'Edit Challenge',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                ProfileImagePicker(
                  imagePath: _imagePath ?? _imageUrl,
                  onImagePicked: (path) => setState(() => _imagePath = path),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Title',
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _skillsController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Skills',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _postTypeController,
                  decoration: const InputDecoration(labelText: 'Post Type'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _rewardController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Reward',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _whoCanWinController,
                  decoration: const InputDecoration(labelText: 'Who Can Win'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startDateController,
                  decoration: const InputDecoration(labelText: 'Start Date'),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _startDateController.text =
                          picked.toIso8601String().split('T').first;
                    }
                  },
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _endDateController,
                  decoration: const InputDecoration(labelText: 'End Date'),
                  onTap: () async {
                    FocusScope.of(context).requestFocus(FocusNode());
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      _endDateController.text =
                          picked.toIso8601String().split('T').first;
                    }
                  },
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Link',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : _saveChallenge,
                  child:
                      isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            widget.challenge == null
                                ? 'Create Challenge'
                                : 'Save Changes',
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
