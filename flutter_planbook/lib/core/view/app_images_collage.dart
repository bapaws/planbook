import 'package:flutter/material.dart';
import 'package:flutter_planbook/app/view/app_network_image.dart';

/// 图片拼贴（展示多张图片，而非仅提示）
class AppImagesCollage extends StatelessWidget {
  const AppImagesCollage({
    required this.images,
    super.key,
    this.aspectRatio = 1,
    this.borderRadius,
  });

  final List<String> images;
  final double aspectRatio;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    final display = images.take(4).toList();
    final more = images.length - display.length;

    final child = AspectRatio(
      aspectRatio: aspectRatio,
      child: _buildLayout(display, more),
    );
    if (borderRadius == null) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius!),
      child: child,
    );
  }

  Widget _buildLayout(List<String> display, int more) {
    if (display.length == 1) {
      return AppNetworkImage(
        url: display[0],
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (display.length == 2) {
      return Row(
        children: [
          Expanded(child: _tile(display[0])),
          const SizedBox(width: 4),
          Expanded(child: _tile(display[1])),
        ],
      );
    }
    // 3 或 4 张：2x2 拼贴，最后一张可带更多提示
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisCount: 2,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
      children: [
        for (int i = 0; i < display.length; i++)
          Stack(
            fit: StackFit.expand,
            children: [
              _tile(display[i]),
              if (i == display.length - 1 && more > 0)
                Container(
                  color: Colors.black45,
                  alignment: Alignment.center,
                  child: Text(
                    '+$more',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _tile(String url) {
    return AppNetworkImage(
      url: url,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
