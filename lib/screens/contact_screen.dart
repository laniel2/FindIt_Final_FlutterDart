import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/item.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, required this.item});

  final Item item;

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  late final TextEditingController _message = TextEditingController(
    text: 'Hi, I am contacting you about your ${widget.item.title} report.',
  );
  bool _openingMessage = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  bool get _isEmail => widget.item.contact.contains('@');

  Future<void> _copyContact() async {
    await Clipboard.setData(ClipboardData(text: widget.item.contact));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact copied to clipboard.')),
    );
  }

  Future<void> _messageOwner() async {
    final contact = widget.item.contact.trim();
    if (contact.isEmpty) return;
    setState(() => _openingMessage = true);
    try {
      final uri = _isEmail
          ? Uri(
              scheme: 'mailto',
              path: contact,
              queryParameters: {
                'subject': 'About your FindIt report: ${widget.item.title}',
                'body': _message.text.trim(),
              },
            )
          : Uri(
              scheme: 'sms',
              path: contact,
              queryParameters: {'body': _message.text.trim()},
            );
      final opened = await launchUrl(uri);
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEmail
                ? 'No email app is available to compose this message.'
                : 'No messaging app is available for this phone number.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open a message composer.')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingMessage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.item.contact.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Owner')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(widget.item.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Contact listed on this lost and found report'),
                const SizedBox(height: 20),
                SelectableText(
                  contact.isEmpty ? 'No contact information provided.' : contact,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (contact.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _copyContact,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy contact'),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _message,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openingMessage ? null : _messageOwner,
                    icon: _openingMessage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(_isEmail ? Icons.email_outlined : Icons.sms_outlined),
                    label: Text(_isEmail ? 'Open email app' : 'Open messaging app'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your email or messaging app will open with this message ready. Review and send it there.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
