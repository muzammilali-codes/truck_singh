import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_service.dart';
import '../../config/theme.dart';

class AdminUserManagementPage extends StatefulWidget {
  const AdminUserManagementPage({super.key});

  @override
  State<AdminUserManagementPage> createState() =>
      _AdminUserManagementPageState();
}

class _AdminUserManagementPageState extends State<AdminUserManagementPage>
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  late TabController _tabController;

  // User list
  List<Map<String, dynamic>> allUsers = [];
  bool isLoadingUsers = true;

  // Create admin form
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  DateTime? _selectedDate;
  bool _isCreatingAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsers() async {
    try {
      setState(() => isLoadingUsers = true);

      final users = await AdminService.getAllUsers();

      // Remove duplicates based on custom_user_id
      final uniqueUsers = <String, Map<String, dynamic>>{};
      for (final user in users) {
        final customUserId = user['custom_user_id'];
        if (customUserId != null) {
          uniqueUsers[customUserId] = user;
        }
      }

      setState(() {
        allUsers = uniqueUsers.values.toList();
        isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => isLoadingUsers = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading users: $e')));
      }
    }
  }

  Future<void> _createAdminUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreatingAdmin = true);

    try {
      // Handle type conversions for compatibility
      final dateOfBirthValue =
          _selectedDate?.toIso8601String() ??
              DateTime(1990, 1, 1).toIso8601String();
      final mobileNumberValue = _mobileController.text.trim();

      final result = await AdminService.createAdminUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        dateOfBirth: dateOfBirthValue,
        mobileNumber: mobileNumberValue,
      );

      if (mounted) {
        final success = result['success'] as bool? ?? false;
        if (success == true) {
          // Clear form on success
          _emailController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          _nameController.clear();
          _mobileController.clear();
          setState(() => _selectedDate = null);

          // Refresh user list to show new admin
          await _loadAllUsers();

          final requiresReauth = result['requires_reauth'] as bool? ?? false;
          if (requiresReauth == true) {
            // Session was lost, show reauth dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text('⚠️ Admin Created - Reauth Required'),
                content: Text(
                  'Admin ${result['admin_id'] as String? ?? 'N/A'} was created successfully, but you were logged out. '
                      'Please log back in to continue.',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text('Go to Login'),
                  ),
                ],
              ),
            );
          } else {
            // Success! Admin is still logged in
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ ${result['message'] as String? ?? 'Admin created successfully!'}\n'
                      'Method: ${result['method'] as String? ?? 'unknown'}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error creating admin: ${result['error'] as String? ?? 'Unknown error'}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating admin: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isCreatingAdmin = false);
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('user_management'.tr()),
      /*  backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,*/
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.admin_panel_settings), text: 'My Admins'),
            Tab(icon: Icon(Icons.person_add), text: 'create_admin'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildUserListTab(), _buildCreateAdminTab()],
      ),
    );
  }

  Widget _buildUserListTab() {
    if (isLoadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAllUsers,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(16),
            //color: Colors.blue[50],
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'My Created Admins: ${allUsers.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAllUsers,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allUsers.length,
              itemBuilder: (context, index) {
                final user = allUsers[index];
                final isDisabled = user['account_disable'] ?? false;

                return Card(
                  color: Theme.of(context).cardColor,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(user['role']),
                      child: Text(
                        user['role']?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          //color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      user['name'] ?? 'No Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${user['custom_user_id']}'),
                        Text('Email: ${user['email'] ?? 'N/A'}'),
                        Text('Role: ${_formatRole(user['role'])}'),
                        if (isDisabled)
                          Text(
                            'account_disabled'.tr(),
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user['role'] == 'admin')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'admin'.tr(),
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            isDisabled ? Icons.toggle_off : Icons.toggle_on,
                            color: isDisabled ? Colors.grey : Colors.green,
                          ),
                          onPressed: () => _toggleUserStatus(user),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateAdminTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  //color: AppColors.background,
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.teal.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppColors.teal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'create_admin'.tr(),
                            style: TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'create_admin_account_info'.tr(),
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'full_name'.tr(),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'enter_full_name'.tr();
                  }
                  if (value.trim().length < 2) {
                    return 'name_min_chars'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Date of Birth field
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'date_of_birth'.tr(),
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'select_dob'.tr(),
                    style: TextStyle(
                      color: _selectedDate != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Mobile Number field
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'mobile_number'.tr(),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'mobile_hint'.tr(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'enter_mobile'.tr();
                  if (value.trim().length != 10) return 'mobile_invalid'.tr();
                  if (!RegExp(r'^[0-9]+$').hasMatch(value.trim()))
                    return 'mobile_digits_only'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'admin_email'.tr(),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'enter_email'.tr();
                  if (!value.contains('@')) return 'enter_valid_email'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Password
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'password'.tr(),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'enter_password'.tr();
                  if (value.length < 6) return 'password_min_chars'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'confirm_password'.tr(),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'confirm_password_enter'.tr();
                  if (value != _passwordController.text)
                    return 'passwords_not_match'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Create Admin Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isCreatingAdmin ? null : _createAdminUser,
                  icon: _isCreatingAdmin
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Icon(Icons.admin_panel_settings),
                  label: Text(
                    _isCreatingAdmin
                        ? 'creating_admin'.tr()
                        : 'create_admin_user'.tr(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return const Color(0xFF6A1B9A);
      case 'agent':
        return AppColors.tealBlue;
      case 'truckowner':
        return Colors.green;
      case 'driver':
        return Colors.orange;
      case 'shipper':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String? role) {
    if (role == null) return 'unknown'.tr();
    return role.substring(0, 1).toUpperCase() + role.substring(1).toLowerCase();
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final isCurrentlyDisabled = user['account_disable'] ?? false;
    final action = isCurrentlyDisabled ? 'enable'.tr() : 'disable'.tr();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action ${'user_account'.tr()}'),
        content: Text(
          'confirm_user_action'.tr(
            namedArgs: {'action': action, 'name': user['name']},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // await AdminService.toggleUserStatus(user['custom_user_id']); // TODO: Implement in fixed service
        await _loadAllUsers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'user_account_success'.tr(namedArgs: {'action': action}),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}
