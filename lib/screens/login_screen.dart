import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _draftKey = 'login_form_draft';
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _draftReady = false;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _email.addListener(_scheduleDraftSave);
    _password.addListener(_scheduleDraftSave);
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw != null) {
      try {
        final draft = jsonDecode(raw) as Map<String, dynamic>;
        _email.text = draft['email'] as String? ?? '';
        _password.text = draft['password'] as String? ?? '';
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
      'email': _email.text,
      'password': _password.text,
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
    _email.removeListener(_scheduleDraftSave);
    _password.removeListener(_scheduleDraftSave);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService.instance.login(_email.text, _password.text);
      await _clearDraft();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
          context, user.profileComplete ? '/home' : '/profile-setup');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset('assets/images/logo.png',
                            width: 90, height: 90),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Welcome back!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const Text('Log in to report or find lost items.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMuted)),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _email,
                      label: 'School email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _login(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Please enter your password'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style:
                                      TextStyle(color: Colors.red.shade800))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                        label: 'Log in', loading: _loading, onPressed: _login),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/register'),
                          child: const Text('Create one'),
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
