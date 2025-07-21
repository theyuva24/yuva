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
import '../models/education_model.dart';
import 'dart:io';
import '../../registration/widgets/interests_picker.dart';

typedef BioChangedCallback = Future<void> Function(String newBio);
typedef EducationChangedCallback =
    Future<void> Function(
      List<EducationModel> educationList,
      String educationLevel,
      String college,
      String course,
      String year,
      String? idCardUrl,
    );
typedef InterestsChangedCallback =
    Future<void> Function(List<String> interests);

class ProfileTabs extends StatefulWidget {
  final ProfileModel profile;
  final BioChangedCallback? onBioChanged;
  final EducationChangedCallback? onEducationChanged;
  final InterestsChangedCallback? onInterestsChanged;
  final Future<void> Function(ProfileModel updatedProfile)?
  onPersonalInfoChanged;
  const ProfileTabs({
    Key? key,
    required this.profile,
    this.onBioChanged,
    this.onEducationChanged,
    this.onInterestsChanged,
    this.onPersonalInfoChanged,
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

  List<EducationModel> _educationList = [];

  bool _editingInterests = false;
  List<String> _interestsDraft = [];

  @override
  void initState() {
    super.initState();
    _bioDraft = widget.profile.bio;
    _educationList = List<EducationModel>.from(widget.profile.education);
    _interestsDraft = List<String>.from(widget.profile.interests);
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
        _educationList,
        _educationLevelDraft,
        _collegeDraft,
        _courseDraft,
        _yearDraft,
        _idCardDraft,
      );
      setState(() {
        _editingEducation = false;
      });
    }
  }

  void _showEducationDialog({EducationModel? initial, int? index}) async {
    final isEdit = initial != null && index != null;
    String schoolName = initial?.schoolName ?? '';
    String degree = initial?.degree ?? '';
    String fieldOfStudy = initial?.fieldOfStudy ?? '';
    DateTime? startDate = initial?.startDate;
    DateTime? endDate = initial?.endDate;
    String activities = initial?.activities ?? '';
    String description = initial?.description ?? '';
    String schoolLogoUrl = initial?.schoolLogoUrl ?? '';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Education' : 'Add Education'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'School/College Name',
                      ),
                      controller: TextEditingController(text: schoolName),
                      onChanged: (val) => setState(() => schoolName = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Degree'),
                      controller: TextEditingController(text: degree),
                      onChanged: (val) => setState(() => degree = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Field of Study',
                      ),
                      controller: TextEditingController(text: fieldOfStudy),
                      onChanged: (val) => setState(() => fieldOfStudy = val),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(1970),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => startDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                              ),
                              child: Text(
                                startDate != null
                                    ? '${startDate!.year}-${startDate!.month.toString().padLeft(2, '0')}'
                                    : 'Select',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: DateTime(1970),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null)
                                setState(() => endDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                              ),
                              child: Text(
                                endDate != null
                                    ? '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}'
                                    : 'Select',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Activities',
                      ),
                      controller: TextEditingController(text: activities),
                      onChanged: (val) => setState(() => activities = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      controller: TextEditingController(text: description),
                      onChanged: (val) => setState(() => description = val),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'School/College Logo',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    IdCardPicker(
                      imagePath: schoolLogoUrl,
                      onImagePicked:
                          (path) => setState(() => schoolLogoUrl = path ?? ''),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEdit)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () {
                      setState(() {
                        _educationList.removeAt(index!);
                      });
                      Navigator.of(context).pop();
                      if (widget.onEducationChanged != null) {
                        widget.onEducationChanged!(
                          _educationList,
                          '',
                          '',
                          '',
                          '',
                          null,
                        );
                      }
                    },
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      schoolName.trim().isEmpty
                          ? null
                          : () {
                            final newEdu = EducationModel(
                              schoolName: schoolName.trim(),
                              degree: degree.trim(),
                              fieldOfStudy: fieldOfStudy.trim(),
                              startDate: startDate,
                              endDate: endDate,
                              activities: activities.trim(),
                              description: description.trim(),
                              schoolLogoUrl: schoolLogoUrl,
                            );
                            setState(() {
                              if (isEdit) {
                                _educationList[index!] = newEdu;
                              } else {
                                _educationList.add(newEdu);
                              }
                            });
                            Navigator.of(context).pop();
                            if (widget.onEducationChanged != null) {
                              widget.onEducationChanged!(
                                _educationList,
                                '',
                                '',
                                '',
                                '',
                                null,
                              );
                            }
                          },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (widget.onEducationChanged != null) {
      await widget.onEducationChanged!(_educationList, '', '', '', '', null);
    }
    setState(() {}); // Refresh the list after dialog closes
  }

  @override
  Widget build(BuildContext context) {
    final PostService postService = PostService();
    final double verticalCardSpacing =
        MediaQuery.of(context).size.height * 0.008; // ~0.8% of screen height
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
                          margin: EdgeInsets.only(bottom: verticalCardSpacing),
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
                      // Education Section (multi-entry)
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          margin: EdgeInsets.only(bottom: verticalCardSpacing),
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
                                          child: Builder(
                                            builder: (context) {
                                              final url =
                                                  widget.profile.idCardUrl;
                                              print(
                                                'DEBUG: College ID image url: ' +
                                                    url,
                                              );
                                              if (url.startsWith('http') ||
                                                  url.startsWith('https')) {
                                                return Image.network(
                                                  url,
                                                  width: double.infinity,
                                                  height: 120,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        width: double.infinity,
                                                        height: 120,
                                                        color: Colors.grey[200],
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: const [
                                                            Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 40,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            SizedBox(height: 8),
                                                            Text(
                                                              'Failed to load image',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                );
                                              } else {
                                                final file = File(url);
                                                return file.existsSync()
                                                    ? Image.file(
                                                      file,
                                                      width: double.infinity,
                                                      height: 120,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Container(
                                                            width:
                                                                double.infinity,
                                                            height: 120,
                                                            color:
                                                                Colors
                                                                    .grey[200],
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: const [
                                                                Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                  size: 40,
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                ),
                                                                SizedBox(
                                                                  height: 8,
                                                                ),
                                                                Text(
                                                                  'Failed to load image',
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colors
                                                                            .grey,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                    )
                                                    : Container(
                                                      width: double.infinity,
                                                      height: 120,
                                                      color: Colors.grey[200],
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: const [
                                                          Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            'No image found',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                              }
                                            },
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
                      // Interests Section as Card with in-place editing
                      SizedBox(height: verticalCardSpacing),
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          margin: EdgeInsets.zero,
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
                                      "Interests",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                    if (!_editingInterests)
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 20),
                                        tooltip: 'Edit Interests',
                                        onPressed: () {
                                          setState(() {
                                            _editingInterests = true;
                                            _interestsDraft = List<String>.from(
                                              widget.profile.interests,
                                            );
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (_editingInterests)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InterestsPicker(
                                        initialSelected: _interestsDraft,
                                        maxSelection: 5,
                                        onChanged:
                                            (list) => setState(
                                              () => _interestsDraft = list,
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(
                                                () => _editingInterests = false,
                                              );
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed:
                                                _interestsDraft.isEmpty
                                                    ? null
                                                    : () async {
                                                      if (widget
                                                              .onInterestsChanged !=
                                                          null) {
                                                        await widget
                                                            .onInterestsChanged!(
                                                          _interestsDraft,
                                                        );
                                                      }
                                                      setState(
                                                        () =>
                                                            _editingInterests =
                                                                false,
                                                      );
                                                    },
                                            child: const Text('Save'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                else if (widget.profile.interests.isNotEmpty)
                                  Wrap(
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
                                                    .withAlpha(38),
                                                labelStyle: const TextStyle(
                                                  color: Colors.blue,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  side: const BorderSide(
                                                    color: Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  )
                                else
                                  const Text(
                                    'No interests added yet.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Personal Info Section as Card with in-place editing
                      SizedBox(height: verticalCardSpacing),
                      _PersonalInfoCard(
                        profile: widget.profile,
                        onPersonalInfoChanged: widget.onPersonalInfoChanged,
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

class _PersonalInfoCard extends StatefulWidget {
  final ProfileModel profile;
  final Future<void> Function(ProfileModel updatedProfile)?
  onPersonalInfoChanged;
  const _PersonalInfoCard({
    Key? key,
    required this.profile,
    this.onPersonalInfoChanged,
  }) : super(key: key);

  @override
  State<_PersonalInfoCard> createState() => _PersonalInfoCardState();
}

class _PersonalInfoCardState extends State<_PersonalInfoCard> {
  bool _editing = false;
  late TextEditingController _locationController;
  late TextEditingController _emailController;
  late TextEditingController _linkedInController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _locationController = TextEditingController(text: widget.profile.location);
    _emailController = TextEditingController(
      text: widget.profile.contactInfo.email,
    );
    _linkedInController = TextEditingController(
      text: widget.profile.contactInfo.linkedInUrl,
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _emailController.dispose();
    _linkedInController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _editing = true;
      _initControllers();
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _initControllers();
    });
  }

  Future<void> _save() async {
    final updatedProfile = widget.profile.copyWith(
      location: _locationController.text.trim(),
      contactInfo: widget.profile.contactInfo.copyWith(
        email: _emailController.text.trim(),
        linkedInUrl: _linkedInController.text.trim(),
      ),
    );
    if (widget.onPersonalInfoChanged != null) {
      await widget.onPersonalInfoChanged!(updatedProfile);
    }
    setState(() {
      _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Personal Info",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                if (!_editing)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    tooltip: 'Edit Personal Info',
                    onPressed: _startEditing,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_editing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Phone', value: widget.profile.phone),
                  _InfoRow(label: 'Gender', value: widget.profile.gender),
                  _InfoRow(
                    label: 'Date of Birth',
                    value:
                        widget.profile.dob != null
                            ? '${widget.profile.dob!.year}-${widget.profile.dob!.month.toString().padLeft(2, '0')}-${widget.profile.dob!.day.toString().padLeft(2, '0')}'
                            : '',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _linkedInController,
                    decoration: const InputDecoration(
                      labelText: 'LinkedIn URL',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _cancelEditing,
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              )
            else ...[
              _InfoRow(label: 'Phone', value: widget.profile.phone),
              _InfoRow(label: 'Gender', value: widget.profile.gender),
              _InfoRow(
                label: 'Date of Birth',
                value:
                    widget.profile.dob != null
                        ? '${widget.profile.dob!.year}-${widget.profile.dob!.month.toString().padLeft(2, '0')}-${widget.profile.dob!.day.toString().padLeft(2, '0')}'
                        : '',
              ),
              _InfoRow(label: 'Location', value: widget.profile.location),
              _InfoRow(label: 'Email', value: widget.profile.contactInfo.email),
              _InfoRow(
                label: 'LinkedIn',
                value: widget.profile.contactInfo.linkedInUrl,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({Key? key, required this.label, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
