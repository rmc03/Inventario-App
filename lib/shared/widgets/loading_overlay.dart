import 'package:flutter/cupertino.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.ink.withValues(alpha: AppAlphas.overlay),
              child: const Center(
                child: CupertinoActivityIndicator(radius: 14),
              ),
            ),
          ),
      ],
    );
  }
}
