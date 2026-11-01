import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_colors.dart';

/// Circular white back button identical to the PrayerTimesScreen back button.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;

  const AppBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor = Colors.white,
    this.iconColor = AppColors.primaryDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (onPressed != null) {
              onPressed!();
            } else if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.arrowLeft,
              color: iconColor,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

