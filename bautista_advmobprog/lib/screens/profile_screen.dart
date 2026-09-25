import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_type.dart';
import '../providers/cart_provider.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  Map<String, dynamic> _userData = {};
  LoginType? _loginType;
  bool _isLoading = true;
  String? _loadError;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureDeletePassword = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await _userService.getUserData();
      final type = await _userService.getLoginType();

      if (!mounted) return;

      setState(() {
        _userData = data;
        _loginType = type;
        _loadError = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _userService.logout();

    if (!mounted) return;

    context.read<CartProvider>().clearCart();
    Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
  }

  Future<void> _updateUsername() async {
    final controller = TextEditingController(
      text: _userData['username']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final username = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20.w,
            20.h,
            20.w,
            MediaQuery.of(context).viewInsets.bottom + 20.h,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Update username',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Choose a username that will appear on your profile.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 20.h),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a username';
                    }
                    if (value.trim().length < 3) {
                      return 'Username must contain at least 3 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                FilledButton.icon(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(context, controller.text.trim());
                    }
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save username'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (username == null || username.isEmpty) return;

    try {
      await _userService.updateUsername(username: username);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', username);

      await _loadProfile();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update username: $error')),
      );
    }
  }

  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final passwords = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                20.h,
                20.w,
                MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Change password',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Verify your current password before choosing a new one.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    SizedBox(height: 20.h),
                    TextFormField(
                      controller: currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscureCurrentPassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            modalSetState(() {
                              _obscureCurrentPassword =
                                  !_obscureCurrentPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your current password';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        prefixIcon: const Icon(Icons.lock_reset),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscureNewPassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscureNewPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            modalSetState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Use at least one uppercase letter';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Use at least one number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12.h),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          tooltip: _obscureConfirmPassword
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            modalSetState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != newPasswordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16.h),
                    FilledButton.icon(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          Navigator.pop(context, [
                            currentPasswordController.text,
                            newPasswordController.text,
                          ]);
                        }
                      },
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Change password'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (passwords == null) return;

    try {
      await _userService.resetPasswordFromCurrentPassword(
        currentPassword: passwords[0],
        newPassword: passwords[1],
        email: _userData['email']?.toString() ?? '',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not change password: $error')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            size: 44.sp,
            color: colors.error,
          ),
          title: const Text('Delete account?'),
          content: const Text(
            'This permanently deletes your Firebase account. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final passwordController = TextEditingController();
    _obscureDeletePassword = true;

    final password = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20.w,
                20.h,
                20.w,
                MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Confirm account deletion',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8.h),
                  const Text(
                    'Enter your current password to confirm this action.',
                  ),
                  SizedBox(height: 20.h),
                  TextField(
                    controller: passwordController,
                    obscureText: _obscureDeletePassword,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _obscureDeletePassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          _obscureDeletePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          modalSetState(() {
                            _obscureDeletePassword =
                                !_obscureDeletePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                    ),
                    onPressed: () {
                      if (passwordController.text.isNotEmpty) {
                        Navigator.pop(context, passwordController.text);
                      }
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete account permanently'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (password == null || password.isEmpty) return;

    try {
      await _userService.deleteAccount(
        email: _userData['email']?.toString() ?? '',
        password: password,
      );

      if (!mounted) return;

      context.read<CartProvider>().clearCart();
      Navigator.pushNamedAndRemoveUntil(context, '/signin', (_) => false);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete account: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _userData.isEmpty) {
      return _errorState(context);
    }

    final username = _userData['username']?.toString().trim() ?? '';
    final firstName = _userData['firstName']?.toString().trim() ?? '';
    final lastName = _userData['lastName']?.toString().trim() ?? '';
    final dummyName = '$firstName $lastName'.trim();
    final isDummyJson = _loginType == LoginType.dummyJson;
    final firebaseUser = _userService.currentUser;
    final firebaseName = firebaseUser?.displayName?.trim() ?? '';

    final displayName = isDummyJson
        ? (dummyName.isNotEmpty ? dummyName : username)
        : (firebaseName.isNotEmpty ? firebaseName : username);

    final email = isDummyJson
        ? _userData['email']?.toString().trim() ?? ''
        : firebaseUser?.email?.trim() ??
              _userData['email']?.toString().trim() ??
              '';

    final image = _userData['image']?.toString().trim() ?? '';
    final photoUrl = firebaseUser?.photoURL?.trim() ?? '';
    final profileImage = isDummyJson
        ? image
        : (photoUrl.isNotEmpty ? photoUrl : image);

    final colors = Theme.of(context).colorScheme;
    final name = displayName.isEmpty ? 'Your profile' : displayName;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(22.w, 28.h, 22.w, 32.h),
        children: [
          Center(
            child: Column(
              children: [
                _profileAvatar(
                  imageUrl: profileImage,
                  displayName: name,
                ),
                SizedBox(height: 16.h),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  SizedBox(height: 5.h),
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 34.h),
          _sectionTitle(context, 'PERSONAL INFORMATION'),
          SizedBox(height: 6.h),
          _profileSetting(
            context,
            icon: Icons.person_outline,
            label: 'Username',
            value: username,
            onEdit: _loginType == LoginType.firebase
                ? _updateUsername
                : null,
          ),
          _profileSetting(
            context,
            icon: Icons.mail_outline,
            label: 'Email address',
            value: email,
          ),
          if (isDummyJson)
            _profileSetting(
              context,
              icon: Icons.wc_outlined,
              label: 'Gender',
              value: _userData['gender']?.toString() ?? '',
            ),
          if (_loginType == LoginType.firebase) ...[
            SizedBox(height: 26.h),
            _sectionTitle(context, 'SECURITY'),
            SizedBox(height: 6.h),
            _settingsAction(
              context,
              icon: Icons.lock_reset_outlined,
              title: 'Change password',
              subtitle: 'Update your account password',
              onTap: _changePassword,
            ),
            Divider(height: 1, indent: 52.w),
            _settingsAction(
              context,
              icon: Icons.delete_outline,
              title: 'Delete account',
              subtitle: 'Permanently remove your account',
              destructive: true,
              onTap: _deleteAccount,
            ),
          ],
          SizedBox(height: 28.h),
          const Divider(),
          SizedBox(height: 12.h),
          SizedBox(
            height: 52.h,
            child: TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 42.sp,
              color: colors.onSurfaceVariant,
            ),
            SizedBox(height: 12.h),
            Text(
              'Could not load your profile',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              'Check your connection and try again.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileAvatar({
    required String imageUrl,
    required String displayName,
  }) {
    final colors = Theme.of(context).colorScheme;
    final trimmedName = displayName.trim();
    final initial = trimmedName.isEmpty
        ? ''
        : trimmedName.substring(0, 1).toUpperCase();

    Widget fallback() {
      return ColoredBox(
        color: colors.primaryContainer,
        child: Center(
          child: initial.isEmpty
              ? Icon(
                  Icons.person_outline,
                  size: 44.sp,
                  color: colors.primary,
                )
              : Text(
                  initial,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
    }

    return Container(
      width: 108.r,
      height: 108.r,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.outlineVariant, width: 1.5),
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? fallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback(),
              ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _profileSetting(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    final colors = Theme.of(context).colorScheme;
    final displayValue = value.trim().isEmpty ? 'Not provided' : value.trim();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34.w,
            child: Icon(
              icon,
              size: 21.sp,
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  displayValue,
                  style: Theme.of(context).textTheme.bodyLarge,
                  softWrap: true,
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Update username',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
    );
  }

  Widget _settingsAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    final foreground = destructive ? colors.error : colors.onSurface;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: foreground),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: destructive ? colors.error : colors.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}