import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/custom_text.dart';
import '../services/user_service.dart';

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

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final user = await _userService.getUser();

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/home', arguments: user);
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/nubdexchange_logo.png',
                    width: 180.w,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 32.h),
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 20.h),
                  CustomText(
                    text: 'Welcome to NubdExchange',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 8.h),
                  CustomText(
                    text: 'Your shopping experience starts here',
                    fontSize: 13.sp,
                    textAlign: TextAlign.center,
                    color: Colors.grey.shade600,
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: 28.w,
                    height: 28.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
