import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/item_repository.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/info_row.dart';
import '../widgets/item_image.dart';
import '../widgets/type_badge.dart';
import 'add_item_screen.dart';
import 'contact_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late Item _item = widget.item;

  bool get _isOwner =>
      _item.ownerId == AuthService.instance.currentUser.value?.id;

  Future<void> _toggleResolved() async {
    await ItemRepository.instance.toggleResolved(_item.id);
    if (!mounted) return;
    setState(() => _item = _item.copyWith(resolved: !_item.resolved));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_item.resolved
            ? 'Marked as resolved'
            : 'Marked as active again')));
  }

  Future<void> _delete() async {
    final deleted = await confirmAndDeleteItem(context, _item);
    if (deleted && mounted) Navigator.pop(context);
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AddItemScreen(item: _item),
      ),
    );
    if (saved != true || !mounted) return;
    final items = await ItemRepository.instance.readLocal();
    final updated = items.where((item) => item.id == _item.id).firstOrNull;
    if (updated != null && mounted) setState(() => _item = updated);
  }

  void _contactOwner() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ContactScreen(item: _item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemImage(
                image: _item.image,
                width: double.infinity,
                height: 240,
                radius: 18),
            const SizedBox(height: 16),
            TypeBadge(type: _item.type, resolved: _item.resolved),
            const SizedBox(height: 8),
            Text(_item.title,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(_item.description.isEmpty
                ? 'No description provided.'
                : _item.description,
                style: const TextStyle(
                    fontSize: 15, height: 1.5, color: AppColors.textDark)),
            const SizedBox(height: 12),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    InfoRow(
                        icon: Icons.place,
                        label: _item.isLost ? 'Last seen at' : 'Found at',
                        value: _item.location),
                    InfoRow(
                        icon: Icons.category,
                        label: 'Category',
                        value: _item.category),
                    InfoRow(
                        icon: Icons.event,
                        label: 'Reported on',
                        value: DateFormat.yMMMMd().format(_item.createdAt)),
                    InfoRow(
                        icon: Icons.person,
                        label: 'Reported by',
                        value: _item.ownerName),
                    InfoRow(
                        icon: Icons.contact_phone,
                        label: 'Contact',
                        value: _item.contact),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_item.contact.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _contactOwner,
                icon: const Icon(Icons.message_outlined),
                label: const Text('Contact owner'),
              ),
            if (_isOwner) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                onPressed: _edit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit report'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                onPressed: _toggleResolved,
                icon: Icon(_item.resolved ? Icons.undo : Icons.check_circle),
                label: Text(
                    _item.resolved ? 'Mark as active' : 'Mark as resolved'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade700),
                ),
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete report'),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
