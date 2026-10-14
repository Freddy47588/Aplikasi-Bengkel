import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isOutlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final button = icon == null
        ? ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isOutlined
                  ? Colors.transparent
                  : AppColors.primary,
              foregroundColor: isOutlined ? AppColors.primary : Colors.white,
              side: isOutlined
                  ? const BorderSide(color: AppColors.primary, width: 1.2)
                  : null,
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isOutlined
                  ? Colors.transparent
                  : AppColors.primary,
              foregroundColor: isOutlined ? AppColors.primary : Colors.white,
              side: isOutlined
                  ? const BorderSide(color: AppColors.primary, width: 1.2)
                  : null,
              minimumSize: const Size.fromHeight(52),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: Icon(icon),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );

    return button;
  }
}
