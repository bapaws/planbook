import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
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
    final placeholder = SvgPicture.asset(
      'assets/images/logo.svg',
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
    );
    if (url == null || url!.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: placeholder,
      );
    }

    Widget image;
    if (url!.startsWith('assets/')) {
      image = Image.asset(
        url!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else {
      final repo = context.read<AssetsRepository>();
      if (url!.contains(AssetsRepository.host)) {
        image = Image(
          image: SupaStorageImageProvider(url: url!, repository: repo),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : placeholder,
          errorBuilder: (context, error, stackTrace) => placeholder,
        );
      } else {
        image = CachedNetworkImage(
          imageUrl: url!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => placeholder,
          errorWidget: (context, url, error) => placeholder,
        );
      }
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
