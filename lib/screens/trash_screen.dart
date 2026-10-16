import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/item.dart';
import '../services/item_repository.dart';
import '../widgets/dialogs.dart';
import '../widgets/item_image.dart';
import '../widgets/type_badge.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  Future<List<Item>> _deleted = ItemRepository.instance.readDeleted();

  void _reload() {
    setState(() => _deleted = ItemRepository.instance.readDeleted());
  }

  Future<void> _restore(Item item) async {
    await ItemRepository.instance.restore(item.id);
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${item.title}" was restored.')),
    );
  }

  Future<void> _deleteForever(Item item) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Permanently delete this report?',
      message: '"${item.title}" and its photo will be permanently removed.',
      confirmLabel: 'Delete forever',
    );
    if (!confirmed || !mounted) return;
    await ItemRepository.instance.permanentlyDelete(item.id);
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${item.title}" was permanently deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recently Deleted')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: FutureBuilder<List<Item>>(
              future: _deleted,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Could not load deleted reports.'),
                        const SizedBox(height: 8),
                        TextButton(onPressed: _reload, child: const Text('Retry')),
                      ],
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'Deleted reports stay here for 30 days. Restore a report to return it to your list, or delete it permanently at any time.',
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('There are no deleted reports.'),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final item = items[index];
                                final deletedAt = item.deletedAt!;
                                final daysLeft =
                                    (ItemRepository.deletedRetentionDays -
                                            DateTime.now()
                                                .difference(deletedAt)
                                                .inDays)
                                        .clamp(1,
                                            ItemRepository.deletedRetentionDays);
                                return Card(
                                  color: Colors.white,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            ItemImage(
                                                image: item.image,
                                                width: 72,
                                                height: 72),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  TypeBadge(
                                                      type: item.type,
                                                      resolved: item.resolved),
                                                  const SizedBox(height: 6),
                                                  Text(item.title,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700)),
                                                  Text(
                                                    'Deleted ${DateFormat.yMMMd().format(deletedAt)}',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Permanently deleted in $daysLeft ${daysLeft == 1 ? 'day' : 'days'}',
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          alignment: WrapAlignment.end,
                                          spacing: 8,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _restore(item),
                                              icon: const Icon(Icons.restore),
                                              label: const Text('Restore'),
                                            ),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _deleteForever(item),
                                              style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.red.shade700),
                                              icon: const Icon(Icons.delete_forever_outlined),
                                              label:
                                                  const Text('Delete permanently'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
