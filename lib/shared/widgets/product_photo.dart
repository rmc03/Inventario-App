import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_dimens.dart';
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
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.md)),
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.surfaceSecondary),
          child: _buildImage(imageUrl),
        ),
      ),
    );
  }

  Widget _buildImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return _placeholder();
    }

    if (!_isNetworkUrl(imageUrl)) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: SizedBox.square(
          dimension: 18,
          child: CupertinoActivityIndicator(radius: 9),
        ),
      ),
      errorWidget: (context, url, error) => _placeholder(),
    );
  }

  bool _isNetworkUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  Widget _placeholder() {
    return Icon(
      Icons.inventory_2_outlined,
      color: AppColors.muted,
      size: iconSize ?? size * 0.40,
    );
  }
}
