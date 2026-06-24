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

    // Decode at 2× the display size for retina sharpness — avoids full-res
    // decode which can waste 40-50× more texture memory on a 56×56 display.
    final cacheSize = (size * 2).ceil();

    if (_isAssetPath(imageUrl)) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: size,
        height: size,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    if (!_isNetworkUrl(imageUrl)) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        width: size,
        height: size,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheWidth: cacheSize,
      memCacheHeight: cacheSize,
      placeholder: (context, url) => const Center(
        child: SizedBox.square(
          dimension: 18,
          child: CupertinoActivityIndicator(radius: 9),
        ),
      ),
      errorWidget: (context, url, error) => _placeholder(),
    );
  }

  bool _isAssetPath(String value) {
    return value.startsWith('assets/');
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
