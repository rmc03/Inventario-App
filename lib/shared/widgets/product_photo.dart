import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class ProductPhoto extends StatelessWidget {
  const ProductPhoto({super.key, this.url, this.size = 64, this.iconSize});

  final String? url;
  final double size;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url;

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFF0F4FA)),
          child: imageUrl == null || imageUrl.isEmpty
              ? Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primaryDark.withValues(alpha: 0.55),
                  size: iconSize ?? size * 0.42,
                )
              : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primaryDark.withValues(alpha: 0.55),
                    size: iconSize ?? size * 0.42,
                  ),
                ),
        ),
      ),
    );
  }
}
