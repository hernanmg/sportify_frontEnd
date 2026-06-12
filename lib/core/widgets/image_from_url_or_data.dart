import 'dart:convert';

import 'package:flutter/material.dart';

/// Muestra imagen desde URL HTTP(S) o data-URI base64.
/// Preparado para migrar a CDN sin cambiar los consumidores.
class ImageFromUrlOrData extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ImageFromUrlOrData({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  static ImageProvider? provider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('data:image')) {
      try {
        final b64 = imageUrl.split(',').last;
        return MemoryImage(base64Decode(b64));
      } catch (_) {
        return null;
      }
    }
    if (imageUrl.startsWith('http')) {
      return NetworkImage(imageUrl);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = ImageFromUrlOrData.provider(imageUrl);
    if (provider == null) {
      return SizedBox(
        width: width,
        height: height,
        child: placeholder ??
            errorWidget ??
            Icon(Icons.image_not_supported, size: (height ?? 40) * 0.5),
      );
    }

    return Image(
      image: provider,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          errorWidget ??
          Icon(Icons.broken_image, size: (height ?? 40) * 0.5),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: width,
          height: height,
          child: placeholder ??
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }
}
