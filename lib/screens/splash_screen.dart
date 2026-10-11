import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme.dart';

/// Loads the saved session and sends the user to the right screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await AuthService.instance.init();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final user = AuthService.instance.currentUser.value;
    final route = user == null
        ? '/login'
        : (user.profileComplete ? '/home' : '/profile-setup');
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Image.asset('assets/images/logo.png',
                  width: 120, height: 120),
            ),
            const SizedBox(height: 20),
            const Text('FindIt',
                style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            const Text('School Lost & Found',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
