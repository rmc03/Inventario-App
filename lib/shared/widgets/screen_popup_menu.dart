import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_theme.dart';

class ScreenMenuItem {
  const ScreenMenuItem({
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.enabled = true,
  });

  final String value;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
}

class ScreenPopupMenu extends StatelessWidget {
  const ScreenPopupMenu({
    super.key,
    required this.items,
    required this.onSelected,
  });

  final List<ScreenMenuItem> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      offset: const Offset(0, 8),
      elevation: 8,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem<String>(
            value: item.value,
            enabled: item.enabled,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Opacity(
              opacity: item.enabled ? 1.0 : 0.45,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.iconColor.withValues(alpha: AppAlphas.fill),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      color: item.iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.enabled
                              ? item.subtitle
                              : 'Pr\u00f3ximamente',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
