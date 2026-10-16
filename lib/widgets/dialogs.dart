import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/item_repository.dart';

/// Asks for confirmation, then moves the report to Recently Deleted.
/// Returns true if the item was moved to the trash.
Future<bool> confirmAndDeleteItem(BuildContext context, Item item) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.delete_forever, color: Colors.red, size: 40),
      title: const Text('Move this report to Recently Deleted?'),
      content: Text(
          'You can restore "${item.title}" for 30 days before it is permanently deleted.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Move to Recently Deleted'),
        ),
      ],
    ),
  );
  if (ok != true) return false;
  await ItemRepository.instance.delete(item.id);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${item.title}" moved to Recently Deleted.')));
  }
  return true;
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel)),
      ],
    ),
  );
  return ok == true;
}
