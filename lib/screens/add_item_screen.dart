import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/item_repository.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/image_picker_box.dart';
import '../widgets/primary_button.dart';

/// Form to report a LOST or FOUND item, with photo upload.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key, this.item});

  final Item? item;

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  late final TextEditingController _contact;

  ItemType _type = ItemType.lost;
  String _category = kCategories.first;
  String? _imagePath;
  bool _saving = false;
  bool _draftReady = false;
  Timer? _draftTimer;
  late final String _draftKey;

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser.value!;
    final item = widget.item;
    _draftKey = item == null
        ? 'add_item_draft_${user.id}'
        : 'edit_item_draft_${user.id}_${item.id}';
    _title.text = item?.title ?? '';
    _description.text = item?.description ?? '';
    _location.text = item?.location ?? '';
    if (item != null) {
      _type = item.type;
      _category = item.category;
      _imagePath = item.image;
    }
    _contact =
        TextEditingController(
            text: item?.contact ??
                (user.phone.isNotEmpty ? user.phone : user.email));
    for (final controller in [_title, _description, _location, _contact]) {
      controller.addListener(_scheduleDraftSave);
    }
    _restoreDraft();
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw != null) {
      try {
        final draft = jsonDecode(raw) as Map<String, dynamic>;
        _title.text = draft['title'] as String? ?? widget.item?.title ?? '';
        _description.text =
            draft['description'] as String? ?? widget.item?.description ?? '';
        _location.text = draft['location'] as String? ?? widget.item?.location ?? '';
        _contact.text = draft['contact'] as String? ?? _contact.text;
        final type = draft['type'] as String?;
        final category = draft['category'] as String?;
        if (type == ItemType.lost.name) _type = ItemType.lost;
        if (type == ItemType.found.name) _type = ItemType.found;
        if (kCategories.contains(category)) _category = category!;
        _imagePath = draft['image'] as String?;
      } on FormatException {
        await prefs.remove(_draftKey);
      } on TypeError {
        await prefs.remove(_draftKey);
      }
    }
    _draftReady = true;
    if (mounted) setState(() {});
  }

  void _scheduleDraftSave() {
    if (!_draftReady || _saving) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 300), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!_draftReady || _saving) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode({
      'title': _title.text,
      'description': _description.text,
      'location': _location.text,
      'contact': _contact.text,
      'type': _type.name,
      'category': _category,
      'image': _imagePath,
    }));
  }

  Future<void> _clearDraft() async {
    _draftTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // A direct browser link to the form has no previous route.
      navigator.pushNamedAndRemoveUntil('/home', (_) => false);
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    for (final controller in [_title, _description, _location, _contact]) {
      controller.removeListener(_scheduleDraftSave);
    }
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await chooseImage(context);
    if (file == null) return;
    final saved = await ItemRepository.instance.savePickedImage(file);
    setState(() => _imagePath = saved);
    _scheduleDraftSave();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = AuthService.instance.currentUser.value!;
      final item = widget.item;
      final updated = Item(
        id: item?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category,
        location: _location.text.trim(),
        type: _type,
        image: _imagePath,
        ownerId: item?.ownerId ?? user.id,
        ownerName: item?.ownerName ?? user.fullName,
        contact: _contact.text.trim(),
        createdAt: item?.createdAt ?? DateTime.now(),
        resolved: item?.resolved ?? false,
      );
      if (item == null) {
        await ItemRepository.instance.add(updated);
      } else {
        await ItemRepository.instance.update(updated);
      }
      // Saving the report is the important operation. A stale draft should
      // never keep the user stranded after the report was already saved.
      try {
        await _clearDraft();
      } catch (_) {
        // The next form open can overwrite or clear the stale draft.
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(item != null
              ? 'Report updated successfully.'
              : (_type == ItemType.lost
                  ? 'Lost item reported. We hope it turns up!'
                  : 'Found item posted. Thank you for helping!'))));
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(true);
      } else {
        // A browser reload directly on /add-item has no previous route.
        navigator.pushNamedAndRemoveUntil('/home', (_) => false);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Could not save the report. Please try again.'),
          backgroundColor: Colors.red.shade700));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLost = _type == ItemType.lost;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: Text(widget.item == null ? 'Report an Item' : 'Edit Report'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('What happened?',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                SegmentedButton<ItemType>(
                  segments: const [
                    ButtonSegment(
                        value: ItemType.lost,
                        icon: Icon(Icons.search),
                        label: Text('I lost it')),
                    ButtonSegment(
                        value: ItemType.found,
                        icon: Icon(Icons.inventory_2),
                        label: Text('I found it')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) {
                    setState(() => _type = s.first);
                    _scheduleDraftSave();
                  },
                ),
                const SizedBox(height: 20),
                const Text('Photo',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ImagePickerBox(
                  imagePath: _imagePath,
                  onPick: _pickImage,
                  onRemove: () {
                    setState(() => _imagePath = null);
                    _scheduleDraftSave();
                  },
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _title,
                  label: 'Item name (e.g. Blue water bottle)',
                  icon: Icons.label_outline,
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Please enter at least 3 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text('Category',
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: kCategories
                      .map((c) => ChoiceChip(
                            label: Text(c),
                            selected: _category == c,
                            onSelected: (_) {
                              setState(() => _category = c);
                              _scheduleDraftSave();
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _location,
                  label: isLost ? 'Where did you lose it?' : 'Where did you find it?',
                  icon: Icons.place_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a location'
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _description,
                  label: 'Description (color, brand, marks...)',
                  icon: Icons.notes,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  validator: (v) => (v == null || v.trim().length < 5)
                      ? 'Please add a short description'
                      : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _contact,
                  label: 'How can people reach you?',
                  icon: Icons.contact_phone_outlined,
                  textInputAction: TextInputAction.done,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Contact info is required'
                      : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: widget.item != null
                      ? 'Save changes'
                      : (isLost ? 'Submit lost report' : 'Post found item'),
                  icon: widget.item != null ? Icons.save : Icons.send,
                  loading: _saving,
                  onPressed: _submit,
                ),
              ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
