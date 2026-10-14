import 'package:flutter/material.dart';

/// URL links sent as `links` on task create (replaces local file attachment for API).
class TaskLinksField extends StatelessWidget {
  const TaskLinksField({
    super.key,
    required this.links,
    required this.onAddLink,
    required this.onRemoveLink,
    this.borderColor,
  });

  final List<String> links;
  final Future<void> Function() onAddLink;
  final ValueChanged<int> onRemoveLink;
  final Color? borderColor;

  static const Color _primary = Color(0xFF173559);
  static const Color _defaultFieldBorder = Color(0xFFEEF4F2);
  static const Color _muted = Color(0xFF6A778B);

  @override
  Widget build(BuildContext context) {
    final fieldBorder = borderColor ?? _defaultFieldBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: fieldBorder, width: 0.5),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Add link',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _primary),
                ),
              ),
              IconButton(
                onPressed: () => onAddLink(),
                icon: const Icon(Icons.add_link_rounded, color: _primary),
                tooltip: 'Add URL',
              ),
            ],
          ),
        ),
        if (links.isNotEmpty) ...[
          const SizedBox(height: 10),
          ...List.generate(links.length, (index) {
            final link = links[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == links.length - 1 ? 0 : 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: fieldBorder, width: 0.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.link_rounded, size: 18, color: _muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        link,
                        style: const TextStyle(fontSize: 13, color: _primary, height: 1.3),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemoveLink(index),
                      icon: const Icon(Icons.close_rounded, size: 20, color: _muted),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Remove',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  static Future<String?> promptForLink(BuildContext context, {String? initial}) async {
    final controller = TextEditingController(text: initial ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        var errorText = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add link'),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  hintText: 'https://example.com',
                  errorText: errorText.isEmpty ? null : errorText,
                ),
                onSubmitted: (_) {
                  final normalized = normalizeLink(controller.text);
                  if (normalized == null) {
                    setDialogState(() => errorText = 'Enter a valid http or https URL');
                    return;
                  }
                  Navigator.of(ctx).pop(normalized);
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final normalized = normalizeLink(controller.text);
                    if (normalized == null) {
                      setDialogState(() => errorText = 'Enter a valid http or https URL');
                      return;
                    }
                    Navigator.of(ctx).pop(normalized);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return result;
  }

  static String? normalizeLink(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !uri.hasScheme) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    if (uri.host.isEmpty) return null;
    return uri.toString();
  }
}
