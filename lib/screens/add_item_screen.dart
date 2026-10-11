import 'package:flutter/material.dart';
import '../models/item.dart';
import '../services/auth_service.dart';
import '../services/item_repository.dart';
import '../theme.dart';
import '../widgets/app_text_field.dart';
import '../widgets/image_picker_box.dart';
import '../widgets/primary_button.dart';

/// Form to report a LOST or FOUND item, with photo upload.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    final user = AuthService.instance.currentUser.value!;
    _contact =
        TextEditingController(text: user.phone.isNotEmpty ? user.phone : user.email);
  }

  @override
  void dispose() {
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
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final user = AuthService.instance.currentUser.value!;
      await ItemRepository.instance.add(Item(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category,
        location: _location.text.trim(),
        type: _type,
        image: _imagePath,
        ownerId: user.id,
        ownerName: user.fullName,
        contact: _contact.text.trim(),
        createdAt: DateTime.now(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_type == ItemType.lost
              ? 'Lost item reported. We hope it turns up!'
              : 'Found item posted. Thank you for helping!')));
      Navigator.pop(context);
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
      appBar: AppBar(title: const Text('Report an Item')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                  onSelectionChanged: (s) => setState(() => _type = s.first),
                ),
                const SizedBox(height: 20),
                const Text('Photo',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                ImagePickerBox(
                  imagePath: _imagePath,
                  onPick: _pickImage,
                  onRemove: () => setState(() => _imagePath = null),
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
                            onSelected: (_) => setState(() => _category = c),
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
                  label: isLost ? 'Submit lost report' : 'Post found item',
                  icon: Icons.send,
                  loading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
