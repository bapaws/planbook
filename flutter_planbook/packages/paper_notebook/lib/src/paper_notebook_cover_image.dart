import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_notebook/src/paper_notebook_pattern.dart';

/// 封面底图。稳定 id 存库；包内只带少量兜底，其余按需下载。
///
/// [none] 走纯色 + 纹理。非法 id（含 `file:` / `https:`）回落到 [none]。
class PaperNotebookCoverImage {
  const PaperNotebookCoverImage._(this.id, {this.assetPath});

  final String id;
  final String? assetPath;

  /// 兼容旧调用（测试 key、存储名）。
  String get name => id;

  static const packageName = PaperNotebookPattern.packageName;

  /// 包内没有的封面图从这里取原图和缩略图。
  static const cdnBase = 'https://covers.jotbook.minchaozhang.cn';

  static final _idPattern = RegExp(r'^[a-z][a-z0-9_]*$');

  static const none = PaperNotebookCoverImage._('none');
  static const wheat = PaperNotebookCoverImage._(
    'wheat',
    assetPath: 'assets/covers/wheat.jpg',
  );
  static const bridge = PaperNotebookCoverImage._(
    'bridge',
    assetPath: 'assets/covers/bridge.jpg',
  );
  static const moonlight = PaperNotebookCoverImage._(
    'moonlight',
    assetPath: 'assets/covers/moonlight.jpg',
  );
  static const bouquet = PaperNotebookCoverImage._(
    'bouquet',
    assetPath: 'assets/covers/bouquet.jpg',
  );

  /// 离线/未拉到远程目录时的兜底轮换。
  static const bundled = [wheat, bridge, moonlight, bouquet];

  bool get isNone => id == none.id;

  bool get hasAsset => assetPath != null;

  /// 封面大图。包内四张走资源，其余走 CDN。
  ImageProvider? get image {
    final path = assetPath;
    if (path != null) return AssetImage(path, package: packageName);
    if (isNone) return null;
    return NetworkImage('$cdnBase/$id.jpg');
  }

  /// 按目标像素解码。缩略图不要走 [image]，否则会把整张 1200×1714 送进内存。
  ImageProvider? resized({required int width, required int height}) {
    if (isNone) return null;
    final path = assetPath;
    if (path != null) {
      return resize(
        AssetImage(path, package: packageName),
        width: width,
        height: height,
      );
    }
    return NetworkImage('$cdnBase/$id.thumb.jpg');
  }

  static ImageProvider? resize(
    ImageProvider? source, {
    required int width,
    required int height,
  }) {
    if (source == null) return null;
    return ResizeImage(
      source,
      width: width < 1 ? 1 : width,
      height: height < 1 ? 1 : height,
      policy: ResizeImagePolicy.fit,
    );
  }

  /// 叠在图上的主文字：一律纯白。无图时由皮革亮度决定。
  Color get onCover => Colors.white;

  static PaperNotebookCoverImage parse(String? name) {
    if (name == null || name.isEmpty || name == none.id) return none;
    if (!_idPattern.hasMatch(name)) return none;
    for (final bundled in PaperNotebookCoverImage.bundled) {
      if (bundled.id == name) return bundled;
    }
    return PaperNotebookCoverImage._(name);
  }

  @override
  bool operator ==(Object other) =>
      other is PaperNotebookCoverImage && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PaperNotebookCoverImage.$id';
}

/// 目录里的一张封面，带中英文名。
class PaperNotebookCoverSpec {
  const PaperNotebookCoverSpec({
    required this.image,
    required this.zh,
    required this.en,
  });

  final PaperNotebookCoverImage image;
  final String zh;
  final String en;

  String labelFor(Locale locale) {
    return locale.languageCode.startsWith('zh') ? zh : en;
  }
}

/// 读取包内封面目录。图片本体按需从 CDN 下载。
class PaperNotebookCoverCatalog {
  static List<PaperNotebookCoverSpec>? _cached;

  static Future<List<PaperNotebookCoverSpec>> load() async {
    final cached = _cached;
    if (cached != null) return cached;
    final raw = await _read();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final covers = <PaperNotebookCoverSpec>[
      for (final item in json['covers']! as List<dynamic>)
        _spec(item as Map<String, dynamic>),
    ];
    return _cached = covers;
  }

  static PaperNotebookCoverSpec _spec(Map<String, dynamic> json) {
    final id = json['id']! as String;
    return PaperNotebookCoverSpec(
      image: PaperNotebookCoverImage.parse(id),
      zh: json['zh'] as String? ?? id,
      en: json['en'] as String? ?? id,
    );
  }

  static Future<String> _read() async {
    for (final key in const [
      'packages/paper_notebook/assets/covers/catalog.json',
      'assets/covers/catalog.json',
    ]) {
      try {
        return await rootBundle.loadString(key);
      } on FlutterError {
        continue;
      }
    }
    throw StateError('cover catalog missing');
  }
}
