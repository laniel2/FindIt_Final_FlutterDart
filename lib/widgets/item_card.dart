import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../theme.dart';
import 'item_image.dart';
import 'type_badge.dart';

enum ItemMenuAction { edit, resolve, delete }

/// One row in the lost & found list.
class ItemCard extends StatelessWidget {
  final Item item;
  final bool isOwner;
  final VoidCallback onTap;
  final ValueChanged<ItemMenuAction> onMenu;

  const ItemCard({
    super.key,
    required this.item,
    required this.isOwner,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ItemImage(image: item.image, width: 92, height: 92),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TypeBadge(type: item.type, resolved: item.resolved),
                    const SizedBox(height: 6),
                    Text(item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.place,
                          size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                      ),
                    ]),
                    const SizedBox(height: 2),
                    Text(
                        '${item.category} • ${DateFormat.MMMd().format(item.createdAt)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (isOwner) ...[
                IconButton(
                  tooltip: 'Delete report',
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => onMenu(ItemMenuAction.delete),
                ),
                PopupMenuButton<ItemMenuAction>(
                  tooltip: 'More options',
                  onSelected: onMenu,
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: ItemMenuAction.edit,
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: ItemMenuAction.resolve,
                      child: Text(item.resolved
                          ? 'Mark as active'
                          : 'Mark as resolved'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
