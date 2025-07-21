import 'package:flutter/material.dart';
import 'models/profile_model.dart';
import 'models/experience_model.dart';
import 'models/education_model.dart';
import 'services/profile_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditProfilePage extends StatefulWidget {
  final ProfileModel profile;
  const EditProfilePage({Key? key, required this.profile}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _headlineController;
  late TextEditingController _emailController;
  late TextEditingController _linkedInController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  File? _imageFile;
  DateTime? _dob;
  List<ExperienceModel> _experience = [];
  List<EducationModel> _education = [];
  List<String> _skills = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.fullName);
    _headlineController = TextEditingController(text: p.headline);
    _emailController = TextEditingController(text: p.contactInfo.email);
    _linkedInController = TextEditingController(
      text: p.contactInfo.linkedInUrl,
    );
    _phoneController = TextEditingController(
      text: p.contactInfo.phone.isNotEmpty ? p.contactInfo.phone : p.phone,
    );
    _bioController = TextEditingController(text: p.bio);
    _locationController = TextEditingController(text: p.location);
    _dob = p.dob;
    _experience = List<ExperienceModel>.from(p.experience);
    _education = List<EducationModel>.from(p.education);
    _skills = List<String>.from(p.skills);
    // Map old registration data to new education if needed
    if (_education.isEmpty && (p.college.isNotEmpty || p.course.isNotEmpty)) {
      _education.add(
        EducationModel(
          schoolName: p.college,
          fieldOfStudy: p.course,
          degree: '',
          startDate: null,
          endDate: null,
          activities: '',
          description: '',
          schoolLogoUrl: '',
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _emailController.dispose();
    _linkedInController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob = picked;
      });
    }
  }

  void _addExperience() {
    setState(() {
      _experience.add(ExperienceModel(jobTitle: '', companyName: ''));
    });
  }

  void _removeExperience(int index) {
    setState(() {
      _experience.removeAt(index);
    });
  }

  void _addEducation() {
    setState(() {
      _education.add(EducationModel(schoolName: ''));
    });
  }

  void _removeEducation(int index) {
    setState(() {
      _education.removeAt(index);
    });
  }

  void _addSkill(String skill) {
    setState(() {
      if (skill.isNotEmpty && !_skills.contains(skill)) _skills.add(skill);
    });
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    String newProfilePicUrl = widget.profile.profilePicUrl;
    if (_imageFile != null) {
      newProfilePicUrl = await ProfileService().uploadProfileImage(
        widget.profile.uid,
        _imageFile!.path,
      );
    }
    final updatedProfile = widget.profile.copyWith(
      fullName: _nameController.text,
      headline: _headlineController.text,
      contactInfo: ContactInfo(
        email: _emailController.text,
        linkedInUrl: _linkedInController.text,
        phone: _phoneController.text,
      ),
      bio: _bioController.text,
      location: _locationController.text,
      dob: _dob,
      profilePicUrl: newProfilePicUrl,
      experience: _experience,
      education: _education,
      skills: _skills,
    );
    await ProfileService().updateProfile(updatedProfile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context, updatedProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillController = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      _imageFile != null
                          ? FileImage(_imageFile!)
                          : (widget.profile.profilePicUrl.isNotEmpty)
                          ? NetworkImage(widget.profile.profilePicUrl)
                              as ImageProvider
                          : const AssetImage('assets/avatar_placeholder.png'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _headlineController,
                decoration: const InputDecoration(labelText: 'Headline'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkedInController,
                decoration: const InputDecoration(labelText: 'LinkedIn URL'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  _dob != null
                      ? DateFormat('yyyy-MM-dd').format(_dob!)
                      : 'Select Date of Birth',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDob,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'About Me',
                  hintText: 'Write something about yourself',
                ),
                maxLines: 4,
                maxLength: 160,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 24),
              // Experience Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Experience',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _addExperience,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              ..._experience.asMap().entries.map((entry) {
                final i = entry.key;
                final exp = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: exp.jobTitle,
                          decoration: const InputDecoration(
                            labelText: 'Job Title',
                          ),
                          onChanged:
                              (v) => _experience[i] = exp.copyWith(jobTitle: v),
                        ),
                        TextFormField(
                          initialValue: exp.companyName,
                          decoration: const InputDecoration(
                            labelText: 'Company Name',
                          ),
                          onChanged:
                              (v) =>
                                  _experience[i] = exp.copyWith(companyName: v),
                        ),
                        TextFormField(
                          initialValue: exp.location,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                          ),
                          onChanged:
                              (v) => _experience[i] = exp.copyWith(location: v),
                        ),
                        TextFormField(
                          initialValue: exp.description,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          onChanged:
                              (v) =>
                                  _experience[i] = exp.copyWith(description: v),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    exp.startDate != null
                                        ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(exp.startDate!)
                                        : '',
                                decoration: const InputDecoration(
                                  labelText: 'Start Date (yyyy-MM-dd)',
                                ),
                                onChanged:
                                    (v) =>
                                        _experience[i] = exp.copyWith(
                                          startDate: DateTime.tryParse(v),
                                        ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    exp.endDate != null
                                        ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(exp.endDate!)
                                        : '',
                                decoration: const InputDecoration(
                                  labelText: 'End Date (yyyy-MM-dd)',
                                ),
                                onChanged:
                                    (v) =>
                                        _experience[i] = exp.copyWith(
                                          endDate: DateTime.tryParse(v),
                                        ),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeExperience(i),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              // Education Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Education',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _addEducation,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              ..._education.asMap().entries.map((entry) {
                final i = entry.key;
                final edu = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        TextFormField(
                          initialValue: edu.schoolName,
                          decoration: const InputDecoration(
                            labelText: 'School Name',
                          ),
                          onChanged:
                              (v) =>
                                  _education[i] = edu.copyWith(schoolName: v),
                        ),
                        TextFormField(
                          initialValue: edu.degree,
                          decoration: const InputDecoration(
                            labelText: 'Degree',
                          ),
                          onChanged:
                              (v) => _education[i] = edu.copyWith(degree: v),
                        ),
                        TextFormField(
                          initialValue: edu.fieldOfStudy,
                          decoration: const InputDecoration(
                            labelText: 'Field of Study',
                          ),
                          onChanged:
                              (v) =>
                                  _education[i] = edu.copyWith(fieldOfStudy: v),
                        ),
                        TextFormField(
                          initialValue: edu.activities,
                          decoration: const InputDecoration(
                            labelText: 'Activities',
                          ),
                          onChanged:
                              (v) =>
                                  _education[i] = edu.copyWith(activities: v),
                        ),
                        TextFormField(
                          initialValue: edu.description,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                          onChanged:
                              (v) =>
                                  _education[i] = edu.copyWith(description: v),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    edu.startDate != null
                                        ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(edu.startDate!)
                                        : '',
                                decoration: const InputDecoration(
                                  labelText: 'Start Date (yyyy-MM-dd)',
                                ),
                                onChanged:
                                    (v) =>
                                        _education[i] = edu.copyWith(
                                          startDate: DateTime.tryParse(v),
                                        ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    edu.endDate != null
                                        ? DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(edu.endDate!)
                                        : '',
                                decoration: const InputDecoration(
                                  labelText: 'End Date (yyyy-MM-dd)',
                                ),
                                onChanged:
                                    (v) =>
                                        _education[i] = edu.copyWith(
                                          endDate: DateTime.tryParse(v),
                                        ),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeEducation(i),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
              // Skills Section
              const Text(
                'Skills',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children:
                    _skills.asMap().entries.map((entry) {
                      final i = entry.key;
                      final skill = entry.value;
                      return Chip(
                        label: Text(skill),
                        onDeleted: () => _removeSkill(i),
                      );
                    }).toList(),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: skillController,
                      decoration: const InputDecoration(labelText: 'Add Skill'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      _addSkill(skillController.text.trim());
                      skillController.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
