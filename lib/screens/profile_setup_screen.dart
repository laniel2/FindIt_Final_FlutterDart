import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/item_repository.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/image_picker_box.dart';
import '../widgets/primary_button.dart';
import '../widgets/user_avatar.dart';

/// Used twice:
///  * right after registration (first-time profile setup), and
///  * from the Profile tab (edit profile) when route argument `true` is passed.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final AppUser _user;
  late final TextEditingController _name;
  late final TextEditingController _studentId;
  late final TextEditingController _course;
  late final TextEditingController _phone;
  String? _avatarPath;
  bool _saving = false;
  bool _isEditing = false;
  bool _initialised = false;
  bool _draftReady = false;
  Timer? _draftTimer;
  late String _draftKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    _isEditing = ModalRoute.of(context)?.settings.arguments == true;
    _user = AuthService.instance.currentUser.value!;
    _draftKey = 'profile_draft_${_user.id}_${_isEditing ? 'edit' : 'setup'}';
    _name = TextEditingController(text: _user.fullName);
    _studentId = TextEditingController(text: _user.studentId);
    _course = TextEditingController(text: _user.course);
    _phone = TextEditingController(text: _user.phone);
    _avatarPath = _user.avatarPath;
    for (final controller in [_name, _studentId, _course, _phone]) {
      controller.addListener(_scheduleDraftSave);
    }
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw != null) {
      try {
        final draft = jsonDecode(raw) as Map<String, dynamic>;
        _name.text = draft['name'] as String? ?? _name.text;
        _studentId.text = draft['studentId'] as String? ?? _studentId.text;
        _course.text = draft['course'] as String? ?? _course.text;
        _phone.text = draft['phone'] as String? ?? _phone.text;
        _avatarPath = draft['avatar'] as String? ?? _avatarPath;
      } on FormatException {
        await prefs.remove(_draftKey);
      } on TypeError {
        await prefs.remove(_draftKey);
      }
    }
    _draftReady = true;
    if (mounted) setState(() {});
  }

  void _scheduleDraftSave() {
    if (!_draftReady || _saving) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 250), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!_draftReady || _saving) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode({
      'name': _name.text,
      'studentId': _studentId.text,
      'course': _course.text,
      'phone': _phone.text,
      'avatar': _avatarPath,
    }));
  }

  Future<void> _clearDraft() async {
    _draftTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    if (_initialised) {
      for (final controller in [_name, _studentId, _course, _phone]) {
        controller.removeListener(_scheduleDraftSave);
      }
    }
    _name.dispose();
    _studentId.dispose();
    _course.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await chooseImage(context);
    if (file == null) return;
    final saved = await ItemRepository.instance.savePickedImage(file);
    setState(() => _avatarPath = saved);
    _scheduleDraftSave();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await AuthService.instance.updateProfile(_user.copyWith(
        fullName: _name.text.trim(),
        studentId: _studentId.text.trim(),
        course: _course.text.trim(),
        phone: _phone.text.trim(),
        avatarPath: _avatarPath,
        profileComplete: true,
      ));
      await _clearDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
      if (_isEditing) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _isEditing, // first-time setup cannot be skipped by going back
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Profile' : 'Set Up Your Profile'),
          automaticallyImplyLeading: _isEditing,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isEditing) ...[
                        const Text('Tell us about yourself',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w700)),
                        const Text(
                            'This helps others contact you when an item is found.',
                            style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 20),
                      ],
                      Center(
                        child: Stack(
                          children: [
                            UserAvatar(
                                name: _name.text,
                                imagePath: _avatarPath,
                                radius: 56),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Material(
                                color: AppColors.primary,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: 'Change profile photo',
                                  icon: const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 20),
                                  onPressed: _pickAvatar,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Profile photo (optional)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 20),
                      AppTextField(
                        controller: _name,
                        label: 'Full name',
                        icon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Please enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _studentId,
                        label: 'Student ID',
                        icon: Icons.badge_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Student ID is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _course,
                        label: 'Course / Year level',
                        icon: Icons.school_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter your course or year level'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _phone,
                        label: 'Contact number (optional)',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null;
                          return RegExp(r'^[0-9+\-\s]{7,15}$').hasMatch(t)
                              ? null
                              : 'Enter a valid phone number';
                        },
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: _isEditing ? 'Save changes' : 'Finish setup',
                        icon: Icons.check,
                        loading: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
