import 'package:flutter/material.dart';
import '../models/item.dart';
import '../theme.dart';

/// Small coloured label: LOST (orange) or FOUND (green) or RESOLVED (grey).
class TypeBadge extends StatelessWidget {
  final ItemType type;
  final bool resolved;
  const TypeBadge({super.key, required this.type, this.resolved = false});

  @override
  Widget build(BuildContext context) {
    final isLost = type == ItemType.lost;
    final Color fg = resolved
        ? Colors.grey.shade700
        : (isLost ? AppColors.lost : AppColors.found);
    final Color bg = resolved
        ? Colors.grey.shade200
        : (isLost ? AppColors.lostSoft : AppColors.foundSoft);
    final text = resolved ? 'RESOLVED' : (isLost ? 'LOST' : 'FOUND');
    final icon = resolved
        ? Icons.check_circle
        : (isLost ? Icons.search : Icons.inventory_2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}
