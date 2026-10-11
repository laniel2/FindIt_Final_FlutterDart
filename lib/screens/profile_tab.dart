import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/item_repository.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/info_row.dart';
import '../widgets/user_avatar.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _logout(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to log in again to use FindIt.',
      confirmLabel: 'Log out',
    );
    if (!ok) return;
    await AuthService.instance.logout();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppUser?>(
      valueListenable: AuthService.instance.currentUser,
      builder: (context, user, _) {
        if (user == null) return const SizedBox.shrink();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              UserAvatar(
                  name: user.fullName, imagePath: user.avatarPath, radius: 54),
              const SizedBox(height: 12),
              Text(user.fullName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700)),
              Text(user.email,
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ValueListenableBuilder<int>(
                valueListenable: ItemRepository.instance.changes,
                builder: (context, _, __) => FutureBuilder<List<Item>>(
                  future: ItemRepository.instance.readLocal(),
                  builder: (context, snap) {
                    final mine = (snap.data ?? [])
                        .where((i) => i.ownerId == user.id)
                        .toList();
                    final lost = mine.where((i) => i.isLost).length;
                    return Row(
                      children: [
                        _Stat(label: 'Reports', value: mine.length),
                        _Stat(label: 'Lost', value: lost),
                        _Stat(label: 'Found', value: mine.length - lost),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(children: [
                    InfoRow(
                        icon: Icons.badge,
                        label: 'Student ID',
                        value: user.studentId),
                    InfoRow(
                        icon: Icons.school,
                        label: 'Course / Year',
                        value: user.course),
                    InfoRow(
                        icon: Icons.phone,
                        label: 'Contact number',
                        value: user.phone),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                    context, '/profile-setup',
                    arguments: true),
                icon: const Icon(Icons.edit),
                label: const Text('Edit profile'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade700),
                ),
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Log out'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: AppColors.primarySoft,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            Text('$value',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
      ),
    );
  }
}
