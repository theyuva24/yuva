import 'package:flutter/material.dart';
import 'models/profile_model.dart';
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

extension _ProfileModelCopyWith on ProfileModel {
  ProfileModel copyWith({
    String? fullName,
    String? phone,
    String? gender,
    DateTime? dob,
    String? college,
    String? course,
    String? year,
    String? location,
    List<String>? interests,
    String? profilePicUrl,
    String? idCardUrl,
    List<String>? followers,
    List<String>? following,
    String? uniqueName,
  }) {
    return ProfileModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      college: college ?? this.college,
      course: course ?? this.course,
      year: year ?? this.year,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      idCardUrl: idCardUrl ?? this.idCardUrl,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      uniqueName: uniqueName ?? this.uniqueName,
    );
  }
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _collegeController;
  late TextEditingController _courseController;
  late TextEditingController _yearController;
  late TextEditingController _mobileController;
  DateTime? _dob;
  File? _imageFile;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _locationController = TextEditingController(text: widget.profile.location);
    _collegeController = TextEditingController(text: widget.profile.college);
    _courseController = TextEditingController(text: widget.profile.course);
    _yearController = TextEditingController(text: widget.profile.year);
    _mobileController = TextEditingController(text: widget.profile.phone);
    _dob = widget.profile.dob;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _collegeController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _mobileController.dispose();
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
      location: _locationController.text,
      college: _collegeController.text,
      course: _courseController.text,
      year: _yearController.text,
      phone: _mobileController.text,
      dob: _dob,
      profilePicUrl: newProfilePicUrl,
      uniqueName: widget.profile.uniqueName,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage:
                      _imageFile != null
                          ? FileImage(_imageFile!)
                          : (widget.profile.profilePicUrl != null &&
                              widget.profile.profilePicUrl!.isNotEmpty)
                          ? NetworkImage(widget.profile.profilePicUrl!)
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
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
                validator:
                    (v) =>
                        v == null || v.isEmpty ? 'Enter mobile number' : null,
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
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _collegeController,
                decoration: const InputDecoration(labelText: 'College'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _courseController,
                decoration: const InputDecoration(labelText: 'Course'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year'),
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
