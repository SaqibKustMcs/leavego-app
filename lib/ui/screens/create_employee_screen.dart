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
  late final AppController _appController;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedRole = 'employee';
  int? _selectedDepartmentId;
  bool _isActive = true;
  bool _obscurePassword = true;

  static const _roles = <String>[
    'employee',
    'developer',
    'hod',
    'hr',
    'operations_manager',
    'admin',
    'ceo',
  ];

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
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final departmentId = _selectedDepartmentId;
    if (departmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department')),
      );
      return;
    }

    final Map<String, dynamic>? response;
    if (_isEditing) {
      response = await _appController.updateEmployee(
        employeeId: widget.employee!.id,
        name: _nameController.text.trim(),
        role: _selectedRole,
        departmentId: departmentId,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        isActive: _isActive,
      );
    } else {
      response = await _appController.createEmployee(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        departmentId: departmentId,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        isActive: _isActive,
      );
    }

    if (!mounted) return;
    if (response != null) {
      final fallback =
          _isEditing ? 'Employee updated successfully' : 'Employee created successfully';
      final message = (response['message'] ?? fallback).toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
      return;
    }

    final error = _isEditing
        ? (_appController.updateEmployeeError ?? 'Failed to update employee')
        : (_appController.createEmployeeError ?? 'Failed to create employee');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
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
    final selectedDepartmentId =
        departments.any((d) => d.id == _selectedDepartmentId) ? _selectedDepartmentId : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit User' : 'Create User'),
        leading: const AppBackButton(),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                _isEditing ? 'Update Employee' : 'New Employee',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? 'Update user details and department access'
                    : 'Create a user account and assign department access',
                style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF6A778B)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_isEditing)
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Email'),
                )
              else
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Please enter email';
                    if (!email.contains('@') || !email.contains('.')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              if (!_isEditing) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: _roles
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(_toLabel(role)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 12),
              if (departmentsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: AppLoader(),
                )
              else if (departmentsError != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      departmentsError,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                    TextButton(
                      onPressed: _appController.loadDepartments,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              else
                DropdownButtonFormField<int>(
                  value: selectedDepartmentId,
                  decoration: const InputDecoration(labelText: 'Department'),
                  items: departments
                      .map(
                        (department) => DropdownMenuItem(
                          value: department.id,
                          child: Text(department.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedDepartmentId = value);
                  },
                  validator: (value) {
                    if (value == null) return 'Please select department';
                    return null;
                  },
                ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Active',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  _isActive ? 'User can sign in' : 'User is inactive',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6A778B),
                  ),
                ),
                value: _isActive,
                activeThumbColor: AppTheme.navy,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.navy, AppTheme.lightNavy],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FilledButton(
                  onPressed: submitting || departmentsLoading || departments.isEmpty
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: submitting
                      ? const AppButtonLoader(size: 22)
                      : Text(_isEditing ? 'Update User' : 'Create User'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
