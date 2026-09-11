import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../widgets/custom_text.dart';
import '../models/user.dart';
import '../providers/cart_provider.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatelessWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    await UserService().logout();

    if (!context.mounted) return;

    context.read<CartProvider>().clearCart();

    Navigator.pushNamedAndRemoveUntil(context, '/signin', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final displayName = user.fullName.isEmpty ? user.username : user.fullName;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48.r,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: user.image.isNotEmpty
                  ? NetworkImage(user.image)
                  : null,
              child: user.image.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 48.sp,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            ),
            SizedBox(height: 14.h),
            CustomText(
              text: displayName,
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            CustomText(
              text: '@${user.username}',
              fontSize: 13.sp,
              color: Colors.grey.shade600,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Card(
              elevation: 0,
              child: Column(
                children: [
                  _ProfileItem(
                    icon: Icons.badge_outlined,
                    label: 'User ID',
                    value: user.id.toString(),
                  ),
                  _ProfileItem(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user.email,
                  ),
                  _ProfileItem(
                    icon: Icons.person_outline,
                    label: 'Gender',
                    value: user.gender,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: CustomText(
                  text: 'Log Out',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: CustomText(
            text: label,
            fontSize: 12.sp,
            color: Colors.grey.shade600,
          ),
          subtitle: CustomText(
            text: value.isEmpty ? 'Not provided' : value,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}