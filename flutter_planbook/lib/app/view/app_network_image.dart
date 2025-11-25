import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/assets/assets_repository.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    this.url,
    this.width = 22,
    this.height = 22,
    this.bucket = ResBucket.noteImages,
    this.placeholderIcon,
    this.placeholderColor,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? url;
  final double width;
  final double height;
  final ResBucket bucket;
  final BoxFit fit;

  final IconData? placeholderIcon;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final errorWidget = ColoredBox(
      color: Colors.grey.shade100,
      child: SizedBox(
        width: width,
        height: height,
        child: Icon(
          placeholderIcon ?? FontAwesomeIcons.image,
          color:
              placeholderColor ??
              Theme.of(context).colorScheme.onSurfaceVariant,
          size: min(width, height) / 4,
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
      image = CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => errorWidget,
        errorWidget: (context, url, error) => FutureBuilder(
          future: context.read<AssetsRepository>().downloadImage(url),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: width,
                height: height,
                fit: fit,
              );
            }
            return Image.file(
              File(url),
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) => errorWidget,
            );
          },
        ),
      );
    }

    return image;
  }
}
