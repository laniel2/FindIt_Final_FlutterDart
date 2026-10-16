import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/item_repository.dart';
import '../services/local_file_support.dart';
import '../theme.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? imagePath;
  final double radius;
  const UserAvatar(
      {super.key, required this.name, this.imagePath, this.radius = 40});

  @override
  Widget build(BuildContext context) {
    final hasDataImage =
        imagePath != null && ItemRepository.isDataUri(imagePath!);
    final hasLocalImage = !kIsWeb &&
        imagePath != null &&
        ItemRepository.isLocalFilePath(imagePath!) &&
        localFileExists(imagePath!);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    ImageProvider? backgroundImage;
    if (hasDataImage) {
      backgroundImage = MemoryImage(ItemRepository.decodeDataUri(imagePath!));
    } else if (hasLocalImage) {
      backgroundImage = localFileImageProvider(imagePath!);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySoft,
      backgroundImage: backgroundImage,
      child: backgroundImage == null
          ? Text(initial,
              style: TextStyle(
                  fontSize: radius * 0.9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary))
          : null,
    );
  }
}
