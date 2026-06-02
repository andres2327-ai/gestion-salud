import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void appSnackbar(
  BuildContext context,
  String msg, {
  bool error = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: error
          ? Theme.of(context).colorScheme.error
          : (isDark ? AppColors.darkJade : AppColors.brandJade),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
