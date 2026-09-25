import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/login_type.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final loginType = await _userService.getLoginType();
    bool loggedIn = false;

    if (loginType == LoginType.firebase) {
      loggedIn = _userService.currentUser != null;
    } else {
      loggedIn = await _userService.isLoggedIn();
    }

    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: await _userService.getUser(),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/nubdexchange_logo.png',
              width: 180.w,
            ),
            SizedBox(height: 24.h),
            CustomText(
              text: 'Welcome to NubdExchange',
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
            ),
            SizedBox(height: 24.h),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}