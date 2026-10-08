import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class CreateNewsScreen extends StatefulWidget {
  const CreateNewsScreen({super.key});

  @override
  State<CreateNewsScreen> createState() => _CreateNewsScreenState();
}

class _CreateNewsScreenState extends State<CreateNewsScreen> {
  static const Color _primary = Color(0xFF173559);
  static const Color _fieldBorder = Color(0xFFEEEEEE);
  static const double _fieldHeight = 54;
  static const double _fieldRadius = 8;
  static const double _fieldBorderWidth = 0.5;

  late final AppController _appController;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? _titleError;
  String? _contentError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onControllerUpdate);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _titleError = null;
      _contentError = null;
      _submitError = null;
    });
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    _clearErrors();

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    var ok = true;

    if (title.isEmpty) {
      _titleError = 'Please enter title';
      ok = false;
    }
    if (content.isEmpty) {
      _contentError = 'Please enter description';
      ok = false;
    }
    if (!ok) {
      setState(() {});
      return;
    }

    final response = await _appController.createNews(title: title, content: content);

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

    setState(() {
      _submitError = _appController.createNewsError ?? 'Failed to create news';
    });
  }

  InputDecoration _fieldDecoration({required String hint}) {
    final borderRadius = BorderRadius.circular(_fieldRadius);
    final border = BorderSide(color: _fieldBorder, width: _fieldBorderWidth);
    final focusedBorder = BorderSide(color: _primary, width: 1);

    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF6E6E6E), fontWeight: FontWeight.w400),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      border: OutlineInputBorder(borderRadius: borderRadius, borderSide: border),
      enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: border),
      focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: focusedBorder),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _fieldBox({required Widget child, double? height}) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(_fieldRadius)),
      child: height == null ? child : SizedBox(height: height, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(color: _primary),
        title: Text(
          'Create News',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Announcement',
              style: TextStyle(color: _primary, fontWeight: FontWeight.w500, fontSize: 18),
            ),
            const SizedBox(height: 20),
            _fieldBox(
              height: _fieldHeight,
              child: TextField(
                controller: _titleController,
                style: const TextStyle(fontSize: 16, height: 1.2),
                decoration: _fieldDecoration(hint: 'Title'),
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_titleError != null) setState(() => _titleError = null);
                },
              ),
            ),
            if (_titleError != null) ...[
              const SizedBox(height: 6),
              Text(
                _titleError!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            _fieldBox(
              child: TextField(
                controller: _contentController,
                minLines: 5,
                maxLines: 8,
                style: const TextStyle(fontSize: 16, height: 1.35),
                decoration: _fieldDecoration(hint: 'Description'),
                textInputAction: TextInputAction.newline,
                onChanged: (_) {
                  if (_contentError != null) setState(() => _contentError = null);
                },
              ),
            ),
            if (_contentError != null) ...[
              const SizedBox(height: 6),
              Text(
                _contentError!,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (_submitError != null) ...[
              const SizedBox(height: 12),
              Text(
                _submitError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _appController.createNewsLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                disabledBackgroundColor: _primary.withValues(alpha: 0.6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.controlRadius),
                ),
                elevation: 0,
              ),
              child: _appController.createNewsLoading
                  ? const AppButtonLoader(size: 22)
                  : const Text(
                      'Publish',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
