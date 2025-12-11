import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:planbook_repository/planbook_repository.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    this.onTap,
    this.url,
    this.radius = 22,
    this.bucket = ResBucket.userAvatars,
    super.key,
  });

  final String? url;
  final double radius;
  final ResBucket bucket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final errorWidget = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Icon(
          FontAwesomeIcons.user,
          color: Theme.of(context).disabledColor,
          size: radius,
        ),
      ),
    );
    if (url == null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: errorWidget,
      );
    }

    Widget image;
    if (url!.startsWith('assets/')) {
      image = Image.asset(
        url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => errorWidget,
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (context, url) => errorWidget,
        errorWidget: (context, url, error) => FutureBuilder(
          future: context.read<AssetsRepository>().downloadImage(url),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
              );
            }
            return Image.file(
              File(url),
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => errorWidget,
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: image,
      ),
    );
  }
}
