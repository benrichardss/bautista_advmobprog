import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/login_type.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final UserService _userService = UserService();

  LoginType _loginType = LoginType.dummyJson;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_loginType == LoginType.dummyJson) {
        await _loginWithDummyJson();
      } else {
        await _loginWithFirebase();
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: await _userService.getUser(),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: $error'),
        ),
      );
    }
  }

  Future<void> _loginWithDummyJson() async {
    await _userService.loginUser(
      _usernameController.text.trim(),
      _passwordController.text,
    );
  }

  Future<void> _loginWithFirebase() async {
    final credential = await _userService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('Firebase user was not found');
    }

    final token = await firebaseUser.getIdToken();

    await _userService.saveUserData({
      'id': 0,
      'username': firebaseUser.displayName ?? '',
      'email': firebaseUser.email ?? '',
      'firstName': firebaseUser.displayName ?? '',
      'lastName': '',
      'gender': '',
      'image': firebaseUser.photoURL ?? '',
      'accessToken': token ?? '',
      'refreshToken': '',
      'token': token ?? '',
    });
  }

  String? _validateUsername(String? value) {
    if (_loginType != LoginType.dummyJson) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'Enter your username';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (_loginType != LoginType.firebase) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'Enter your email';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Enter your password';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isFirebase = _loginType == LoginType.firebase;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 32.h,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/nubdexchange_logo.png',
                  height: 90.h,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 24.h),
                CustomText(
                  text: 'Welcome Back',
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(height: 6.h),
                CustomText(
                  text: 'Sign in to continue shopping',
                  fontSize: 13.sp,
                  textAlign: TextAlign.center,
                  color: Colors.grey.shade600,
                ),
                SizedBox(height: 28.h),
                SegmentedButton<LoginType>(
                  segments: const [
                    ButtonSegment<LoginType>(
                      value: LoginType.dummyJson,
                      label: Text('DummyJSON'),
                    ),
                    ButtonSegment<LoginType>(
                      value: LoginType.firebase,
                      label: Text('Firebase'),
                    ),
                  ],
                  selected: {_loginType},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _loginType = selection.first;
                    });

                    _formKey.currentState?.reset();
                  },
                ),
                SizedBox(height: 20.h),
                if (!isFirebase)
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: _validateUsername,
                  ),
                if (!isFirebase) SizedBox(height: 14.h),
                if (isFirebase)
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: _validateEmail,
                  ),
                if (isFirebase) SizedBox(height: 14.h),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
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
                  validator: _validatePassword,
                ),
                SizedBox(height: 24.h),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _login,
                  icon: _isLoading
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: CustomText(
                    text: _isLoading ? 'Signing In...' : 'Sign In',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12.h),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}