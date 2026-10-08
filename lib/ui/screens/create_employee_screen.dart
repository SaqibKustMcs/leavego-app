import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:leavego_app/controllers/app_controller.dart';
import 'package:leavego_app/models/users_response.dart';
import 'package:leavego_app/ui/theme/app_theme.dart';
import 'package:leavego_app/ui/widgets/app_back_button.dart';
import 'package:leavego_app/ui/widgets/app_loader.dart';

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key, this.employee});

  final AppUserItem? employee;

  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  static const Color _primary = Color(0xFF173559);
  static const Color _fieldBorder = Color(0xFFEEF4F2);
  static const double _fieldHeight = 54;
  static const double _fieldRadius = 8;
  static const double _fieldBorderWidth = 0.5;

  late final AppController _appController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'employee';
  int? _selectedDepartmentId;
  bool _isActive = true;
  bool _obscurePassword = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _departmentError;
  String? _submitError;

  static const _roles = <String>['employee', 'hr', 'operations_manager', 'ceo'];

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    _appController = Get.find<AppController>();
    _appController.addListener(_onUpdate);
    _appController.loadDepartments();
    _prefillFromEmployee();
  }

  void _prefillFromEmployee() {
    final employee = widget.employee;
    if (employee == null) return;

    _nameController.text = employee.name;
    _emailController.text = employee.email;
    _phoneController.text = employee.phone?.trim() ?? '';
    _isActive = employee.isActive;

    final role = employee.role.trim().toLowerCase();
    _selectedRole = _roles.contains(role) ? role : 'employee';

    final departmentId = int.tryParse(employee.departmentId ?? '');
    if (departmentId != null && departmentId > 0) {
      _selectedDepartmentId = departmentId;
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _appController.removeListener(_onUpdate);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _toLabel(String raw) {
    if (raw.trim().isEmpty) return '-';
    return raw
        .split('_')
        .map(
          (part) =>
              part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  InputDecoration _fieldDecoration({String? hint, String? label, Widget? suffixIcon}) {
    final borderRadius = BorderRadius.circular(_fieldRadius);
    final border = BorderSide(color: _fieldBorder, width: _fieldBorderWidth);
    final focusedBorder = BorderSide(color: _primary, width: 1);

    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: const TextStyle(color: Color(0xFF6E6E6E), fontWeight: FontWeight.w400),

      labelStyle: const TextStyle(
        color: Color(0xFF6E6E6E),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(color: Color(0xff6E6E6E), fontWeight: FontWeight.w500),
      filled: true,
      fillColor: Color(0xffFFFFFF),
      isDense: true,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: borderRadius, borderSide: border),
      enabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: border),
      focusedBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: focusedBorder),
      disabledBorder: OutlineInputBorder(borderRadius: borderRadius, borderSide: border),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  Widget _singleLineField({required Widget child}) {
    return SizedBox(height: _fieldHeight, child: child);
  }

  bool _validate() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _departmentError = null;
      _submitError = null;
    });

    var ok = true;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty) {
      _nameError = 'Please enter name';
      ok = false;
    }

    if (!_isEditing) {
      if (email.isEmpty) {
        _emailError = 'Please enter email';
        ok = false;
      } else if (!email.contains('@') || !email.contains('.')) {
        _emailError = 'Please enter a valid email';
        ok = false;
      }
      if (password.isEmpty) {
        _passwordError = 'Please enter password';
        ok = false;
      } else if (password.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
        ok = false;
      }
    }

    if (_selectedDepartmentId == null) {
      _departmentError = 'Please select department';
      ok = false;
    }

    setState(() {});
    return ok;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validate()) return;

    final departmentId = _selectedDepartmentId!;

    final Map<String, dynamic>? response;
    if (_isEditing) {
      response = await _appController.updateEmployee(
        employeeId: widget.employee!.id,
        name: _nameController.text.trim(),
        role: _selectedRole,
        departmentId: departmentId,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        isActive: _isActive,
      );
    } else {
      response = await _appController.createEmployee(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        departmentId: departmentId,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        isActive: _isActive,
      );
    }

    if (!mounted) return;
    if (response != null) {
      final fallback = _isEditing
          ? 'Employee updated successfully'
          : 'Employee created successfully';
      final message = (response['message'] ?? fallback).toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _submitError = _isEditing
          ? (_appController.updateEmployeeError ?? 'Failed to update employee')
          : (_appController.createEmployeeError ?? 'Failed to create employee');
    });
  }

  Widget _errorText(String? message) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final departments = _appController.departments.where((d) => d.isActive).toList();
    final departmentsLoading = _appController.departmentsLoading;
    final departmentsError = _appController.departmentsError;
    final submitting = _isEditing
        ? _appController.updateEmployeeLoading
        : _appController.createEmployeeLoading;
    final selectedDepartmentId = departments.any((d) => d.id == _selectedDepartmentId)
        ? _selectedDepartmentId
        : null;

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.appBackground,

        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(color: _primary),
        title: Text(
          _isEditing ? 'Edit User' : 'Create User',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _singleLineField(
              child: TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(fontSize: 16, height: 1.2),
                decoration: _fieldDecoration(hint: 'Name'),
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
              ),
            ),
            _errorText(_nameError),
            const SizedBox(height: 20),
            if (_isEditing)
              _singleLineField(
                child: TextField(
                  controller: _emailController,
                  enabled: false,
                  style: const TextStyle(fontSize: 16, height: 1.2),
                  decoration: _fieldDecoration(hint: 'Email'),
                ),
              )
            else
              _singleLineField(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(fontSize: 16, height: 1.2),
                  decoration: _fieldDecoration(hint: 'Email'),
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                ),
              ),
            _errorText(_emailError),
            if (!_isEditing) ...[
              const SizedBox(height: 20),
              _singleLineField(
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 16, height: 1.2),
                  decoration: _fieldDecoration(
                    hint: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _primary,
                        size: 22,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onChanged: (_) {
                    if (_passwordError != null) setState(() => _passwordError = null);
                  },
                ),
              ),
              _errorText(_passwordError),
            ],
            const SizedBox(height: 20),
            _singleLineField(
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16, height: 1.2),
                decoration: _fieldDecoration(hint: 'Phone (optional)'),
              ),
            ),
            const SizedBox(height: 20),
            _singleLineField(
              child: DropdownButtonFormField<String>(
                value: _selectedRole,
                isExpanded: true,
                decoration: _fieldDecoration(label: 'Role'),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary, size: 30),
                items: _roles
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(
                          _toLabel(role),
                          style: TextStyle(
                            fontSize: 14,
                            color: _primary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedRole = value);
                },
              ),
            ),
            const SizedBox(height: 20),
            if (departmentsLoading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: AppLoader())
            else if (departmentsError != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    departmentsError,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                  TextButton(onPressed: _appController.loadDepartments, child: const Text('Retry')),
                ],
              )
            else
              _singleLineField(
                child: DropdownButtonFormField<int>(
                  value: selectedDepartmentId,
                  isExpanded: true,
                  decoration: _fieldDecoration(label: 'Department'),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _primary),
                  items: departments
                      .map(
                        (department) =>
                            DropdownMenuItem(value: department.id, child: Text(department.name)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartmentId = value;
                      _departmentError = null;
                    });
                  },
                ),
              ),
            _errorText(_departmentError),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active',
                        style: TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isActive ? 'User can sign in' : 'User is inactive',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xff747D7A),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 40,
                  height: 25,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Switch(
                      value: _isActive,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeTrackColor: const Color(0xFF55957F),
                      activeThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFD1D5DB),
                      inactiveThumbColor: Colors.white,
                      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ),
                ),
              ],
            ),
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
            const SizedBox(height: 30),
            FilledButton(
              onPressed: submitting || departmentsLoading || departments.isEmpty ? null : _submit,
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
              child: submitting
                  ? const AppButtonLoader(size: 22)
                  : Text(
                      _isEditing ? 'Update User' : 'Create User',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
