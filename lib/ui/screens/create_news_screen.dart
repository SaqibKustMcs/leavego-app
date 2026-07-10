import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class CreateNewsScreen extends StatefulWidget {
  const CreateNewsScreen({super.key});

  @override
  State<CreateNewsScreen> createState() => _CreateNewsScreenState();
}

class _CreateNewsScreenState extends State<CreateNewsScreen> {
  late final AppController _appController;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  final titleError = ''.obs;
  final contentError = ''.obs;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    titleError.value = '';
    contentError.value = '';
  }

  Future<void> _submit() async {
    _clearErrors();
    var ok = true;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      titleError.value = 'Please enter title';
      ok = false;
    }
    if (content.isEmpty) {
      contentError.value = 'Please enter content';
      ok = false;
    }
    if (!ok) return;

    final response = await _appController.createNews(
      title: title,
      content: content,
    );

    if (!mounted) return;

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.message.isNotEmpty ? response.message : 'News created successfully',
          ),
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    final err = _appController.createNewsError ?? 'Failed to create news';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: const Text('Create News'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Announcement',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Publish company news for a specific audience.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6A778B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Obx(
                    () => TextField(
                      controller: _titleController,
                      onChanged: (_) => titleError.value = '',
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Office announcement',
                        errorText: titleError.value.isEmpty ? null : titleError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => TextField(
                      controller: _contentController,
                      maxLines: 6,
                      onChanged: (_) => contentError.value = '',
                      decoration: InputDecoration(
                        labelText: 'Content',
                        hintText: 'Write your announcement...',
                        errorText:
                            contentError.value.isEmpty ? null : contentError.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.navy, AppTheme.lightNavy]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: FilledButton(
                      onPressed: _appController.createNewsLoading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _appController.createNewsLoading
                          ? const AppButtonLoader(size: 22)
                          : const Text('Publish News'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
