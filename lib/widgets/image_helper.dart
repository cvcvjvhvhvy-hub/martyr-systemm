import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

class ImageHelper {
  static Widget buildImage(String? imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return errorWidget ?? _defaultErrorWidget(width, height);
    }
    
    if (imageUrl.startsWith('data:image')) {
      // Base64 image
      try {
        final base64String = imageUrl.contains(',') ? imageUrl.split(',').last : imageUrl;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => errorWidget ?? _defaultErrorWidget(width, height),
        );
      } catch (e) {
        return errorWidget ?? _defaultErrorWidget(width, height);
      }
    } else if (imageUrl.startsWith('http')) {
      // Network image
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF0D9488),
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => errorWidget ?? _defaultErrorWidget(width, height),
      );
    } else {
      return errorWidget ?? _defaultErrorWidget(width, height);
    }
  }

  static Widget _defaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.image, color: Color(0xFF94A3B8)),
    );
  }
}