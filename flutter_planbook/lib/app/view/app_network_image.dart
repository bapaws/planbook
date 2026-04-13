import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/assets/assets_repository.dart';
import 'package:planbook_repository/assets/supa_storage_image_provider.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    this.url,
    this.width,
    this.height,
    this.bucket = ResBucket.noteImages,
    this.placeholderIcon,
    this.placeholderColor,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? url;
  final double? width;
  final double? height;
  final ResBucket bucket;
  final BoxFit fit;

  final IconData? placeholderIcon;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final iconSize = min(width ?? 22, height ?? 22) / 4;
    final errorWidget = ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        width: width ?? height ?? 56,
        height: height ?? width ?? 56,
        child: Icon(
          placeholderIcon ?? FontAwesomeIcons.image,
          color:
              placeholderColor ??
              Theme.of(context).colorScheme.onSurfaceVariant,
          size: iconSize,
        ),
      ),
    );
    if (url == null) {
      return errorWidget;
    }

    Widget image;
    if (url!.startsWith('assets/')) {
      image = Image.asset(
        url!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    } else {
      final repo = context.read<AssetsRepository>();

      // These URLs usually need authenticated access to Supabase storage.
      // Use SupaStorageImageProvider directly, instead of "network fetch
      // -> error -> downloadImage()" fallback.
      if (url!.contains(AssetsRepository.host)) {
        image = Image(
          image: SupaStorageImageProvider(url: url!, repository: repo),
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : errorWidget,
          errorBuilder: (context, error, stackTrace) => errorWidget,
        );
      } else {
        image = CachedNetworkImage(
          imageUrl: url!,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => errorWidget,
          errorWidget: (context, url, error) => errorWidget,
        );
      }
    }

    return Hero(tag: url!, child: image);
  }
}
