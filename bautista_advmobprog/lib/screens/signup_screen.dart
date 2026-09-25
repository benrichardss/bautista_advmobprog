import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/user_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fNameController = TextEditingController();
  final _lNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _contactController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fNameController.dispose();
    _lNameController.dispose();
    _ageController.dispose();
    _contactController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your $field';
    }

    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your age';
    }

    final age = int.tryParse(value);

    if (age == null || age < 13 || age > 120) {
      return 'Enter a valid age';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter your email';
    }

    final validEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!validEmail.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Password must contain at least 8 characters';
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain an uppercase letter';
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain a number';
    }

    return null;
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await UserService().createAccount(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw Exception('Account was not created');
      }

      final token = await firebaseUser.getIdToken();
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('firstName', _fNameController.text.trim());
      await prefs.setString('lastName', _lNameController.text.trim());
      await prefs.setString('age', _ageController.text.trim());
      await prefs.setString('contactNo', _contactController.text.trim());

      await UserService().saveUserData({
        'id': 0,
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'firstName': _fNameController.text.trim(),
        'lastName': _lNameController.text.trim(),
        'gender': '',
        'image': '',
        'accessToken': token ?? '',
        'refreshToken': '',
        'token': token ?? '',
      });

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (_) => false,
        arguments: await UserService().getUser(),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _field(
                  controller: _fNameController,
                  label: 'First name',
                  icon: Icons.person_outline,
                  validator: (value) => _required(value, 'first name'),
                ),
                _field(
                  controller: _lNameController,
                  label: 'Last name',
                  icon: Icons.person_outline,
                  validator: (value) => _required(value, 'last name'),
                ),
                _field(
                  controller: _ageController,
                  label: 'Age',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: _validateAge,
                ),
                _field(
                  controller: _contactController,
                  label: 'Contact number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) => _required(value, 'contact number'),
                ),
                _field(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.account_circle_outlined,
                  validator: (value) => _required(value, 'username'),
                ),
                _field(
                  controller: _emailController,
                  label: 'Email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                _field(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _signup,
                    child: Text(
                      _isLoading ? 'Creating account...' : 'Create account',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}