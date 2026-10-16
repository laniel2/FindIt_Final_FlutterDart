import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _draftKey = 'register_form_draft_v2';
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _draftReady = false;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _email, _password, _confirm]) {
      controller.addListener(_scheduleDraftSave);
    }
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    // Remove earlier drafts, which included passwords in plain text.
    await prefs.remove('register_form_draft');
    final raw = prefs.getString(_draftKey);
    if (raw != null) {
      try {
        final draft = jsonDecode(raw) as Map<String, dynamic>;
        _name.text = draft['name'] as String? ?? '';
        _email.text = draft['email'] as String? ?? '';
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
    if (!_draftReady || _loading) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 250), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!_draftReady || _loading) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode({
      'name': _name.text,
      'email': _email.text,
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
    for (final controller in [_name, _email, _password, _confirm]) {
      controller.removeListener(_scheduleDraftSave);
    }
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.register(
        fullName: _name.text,
        email: _email.text,
        password: _password.text,
      );
      await _clearDraft();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Account created! Let’s set up your profile.')));
      Navigator.pushReplacementNamed(context, '/profile-setup');
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: Colors.red.shade700));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to login',
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
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
                    const Text('Join FindIt',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const Text('Create an account to post lost and found items.',
                        style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 24),
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
                      controller: _email,
                      label: 'School email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) return 'Please enter your email';
                        final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
                        return ok ? null : 'Enter a valid email address';
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _password,
                      label: 'Password (min. 6 characters)',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirm,
                      label: 'Confirm password',
                      icon: Icons.lock_reset,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _register(),
                      validator: (v) =>
                          v != _password.text ? 'Passwords do not match' : null,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                        label: 'Create account',
                        loading: _loading,
                        onPressed: _register),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already registered?'),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/login'),
                          child: const Text('Log in'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
