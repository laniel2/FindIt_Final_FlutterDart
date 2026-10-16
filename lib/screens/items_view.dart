import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/item_repository.dart';
import '../theme.dart';
import '../widgets/dialogs.dart';
import '../widgets/item_card.dart';
import '../widgets/state_views.dart';
import 'add_item_screen.dart';
import 'item_detail_screen.dart';

enum _Filter { all, lost, found }

/// List of reports with search + filter. Used for "Browse" (all items)
/// and "My Reports" (onlyMine = true).
class ItemsView extends StatefulWidget {
  final bool onlyMine;
  const ItemsView({super.key, this.onlyMine = false});

  @override
  State<ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<ItemsView> {
  final _repo = ItemRepository.instance;
  final _searchCtrl = TextEditingController();

  List<Item> _items = [];
  bool _loading = true;
  String? _error;
  String? _warning;
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _load();
    _repo.changes.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _repo.changes.removeListener(_onDataChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onDataChanged() => _load(showSpinner: false);

  Future<void> _load({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await _repo.loadItems();
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _warning = result.warning;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unexpected error while loading items.';
        _loading = false;
      });
    }
  }

  List<Item> get _visible {
    final me = AuthService.instance.currentUser.value?.id;
    final q = _query.trim().toLowerCase();
    return _items.where((i) {
      if (widget.onlyMine && i.ownerId != me) return false;
      if (_filter == _Filter.lost && i.type != ItemType.lost) return false;
      if (_filter == _Filter.found && i.type != ItemType.found) return false;
      if (q.isEmpty) return true;
      return i.title.toLowerCase().contains(q) ||
          i.location.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _onMenu(Item item, ItemMenuAction action) async {
    if (action == ItemMenuAction.delete) {
      await confirmAndDeleteItem(context, item);
    } else if (action == ItemMenuAction.edit) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AddItemScreen(item: item),
        ),
      );
    } else {
      await _repo.toggleResolved(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(item.resolved
              ? 'Marked as active again'
              : 'Great! Marked as resolved')));
    }
  }

  Widget _filterChip(String label, _Filter f) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == f,
          onSelected: (_) => setState(() => _filter = f),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search item, place or category',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [
            _filterChip('All', _Filter.all),
            _filterChip('Lost', _Filter.lost),
            _filterChip('Found', _Filter.found),
          ]),
        ),
        if (_warning != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('$_warning Showing saved items.',
                      style: const TextStyle(fontSize: 12))),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ]),
          ),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView(message: 'Loading reports...');
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    final list = _visible;
    if (list.isEmpty) {
      final searching = _query.isNotEmpty || _filter != _Filter.all;
      return RefreshIndicator(
        onRefresh: () => _load(showSpinner: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 420,
              child: EmptyView(
                title: searching ? 'No matches found' : 'Nothing here yet',
                message: searching
                    ? 'Try a different search or filter.'
                    : (widget.onlyMine
                        ? 'You have not reported anything yet.\nTap “Report item” to add one.'
                        : 'No lost or found items have been reported.'),
              ),
            ),
          ],
        ),
      );
    }

    final me = AuthService.instance.currentUser.value?.id;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _load(showSpinner: false),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 96),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return ItemCard(
            item: item,
            isOwner: item.ownerId == me,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ItemDetailScreen(item: item)),
            ),
            onMenu: (a) => _onMenu(item, a),
          );
        },
      ),
    );
  }
}
