import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Indicador de progreso de páginas (dots)
class PageIndicator extends StatelessWidget {
  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  final int currentPage;
  final int pageCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        pageCount,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentPage == index
                ? colors.primary
                : colors.primary.withAlpha(51), // 0.2 * 255
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
