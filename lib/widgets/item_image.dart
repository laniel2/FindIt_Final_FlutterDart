import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/item_repository.dart';
import '../services/local_file_support.dart';
import '../theme.dart';

/// Displays a network image (from the API) or a local file (user's photo),
/// with loading and error placeholders.
class ItemImage extends StatelessWidget {
  final String? image;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;

  const ItemImage({
    super.key,
    required this.image,
    this.width,
    this.height,
    this.radius = 12,
    this.fit = BoxFit.cover,
  });

  Widget _placeholder(IconData icon) => Container(
        width: width,
        height: height,
        color: AppColors.primarySoft,
        child: Icon(icon, color: AppColors.primary, size: 32),
      );

  @override
  Widget build(BuildContext context) {
    Widget child;
    final img = image;
    if (img == null || img.isEmpty) {
      child = _placeholder(Icons.image_not_supported_outlined);
    } else if (img.startsWith('http')) {
      child = Image.network(
        img,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, w, progress) => progress == null
            ? w
            : Container(
                width: width,
                height: height,
                color: AppColors.primarySoft,
                child: const Center(
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))),
              ),
        errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image_outlined),
      );
    } else if (ItemRepository.isDataUri(img)) {
      child = Image.memory(
        ItemRepository.decodeDataUri(img),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => _placeholder(Icons.broken_image_outlined),
      );
    } else if (kIsWeb) {
      child = _placeholder(Icons.image_not_supported_outlined);
    } else {
      final provider = localFileImageProvider(img);
      child = provider == null
          ? _placeholder(Icons.image_not_supported_outlined)
          : Image(
              image: provider,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) =>
                  _placeholder(Icons.broken_image_outlined),
            );
    }
    return ClipRRect(borderRadius: BorderRadius.circular(radius), child: child);
  }
}
