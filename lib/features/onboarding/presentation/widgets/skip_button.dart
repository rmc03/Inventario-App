import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';

/// Botón para omitir el onboarding
class SkipButton extends StatelessWidget {
  const SkipButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TextButton(
      onPressed: () {
        Haptics.tap(context);
        onPressed();
      },
      style: TextButton.styleFrom(
        foregroundColor: colors.muted,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: const Text(
        'Omitir',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
