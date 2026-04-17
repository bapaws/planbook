import 'package:package_info_plus/package_info_plus.dart';

/// 将 [PackageInfo] 写入 `mailto:` 的 subject / body，便于客服识别客户端环境。
Future<Uri> mailtoWithAppInfo(Uri mailto) async {
  final path = mailto.path.isNotEmpty ? mailto.path : mailto.authority;
  if (path.isEmpty) return mailto;

  final info = await PackageInfo.fromPlatform();
  final params = Map<String, String>.from(mailto.queryParameters);
  final tag = '${info.appName} v${info.version} (${info.buildNumber})';
  final prevSubject = params['subject'];
  params['subject'] = (prevSubject == null || prevSubject.isEmpty)
      ? tag
      : '$prevSubject — $tag';

  final bodyIntro = 'App: ${info.appName}\n'
      'Version: ${info.version}\n'
      'Build: ${info.buildNumber}\n\n';
  final prevBody = params['body'] ?? '';
  params['body'] = prevBody.isEmpty ? bodyIntro : '$bodyIntro$prevBody';

  return Uri(
    scheme: 'mailto',
    path: path,
    queryParameters: params,
  );
}
