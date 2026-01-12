import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';

class ImageHelper {
  static Widget buildImage(String imageUrl, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? errorWidget,
  }) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 image
      try {
        final bytes = base64Decode(imageUrl.split(',').last);
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
    } else {
      // Network image
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => errorWidget ?? _defaultErrorWidget(width, height),
      );
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