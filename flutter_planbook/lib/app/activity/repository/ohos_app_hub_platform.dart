import 'package:app_hub/app_hub.dart';
import 'package:app_hub/src/app_hub_platform.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

/// App Hub 暂未提供鸿蒙原生插件，使用已有鸿蒙 Preferences 实现本地状态。
///
/// 活动拉取、提交与状态轮询由 App Hub 的 Dart HTTP 客户端负责；这里仅替代
/// Android/iOS 原生层承担的设备标识、本地键值存储与外链打开能力。
final class OhosAppHubPlatform extends AppHubPlatform {
  static const _keyPrefix = 'app_hub.';
  static const _clientIdKey = '${_keyPrefix}client_id';
  static const _submissionIdKey = 'submission_id';

  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> initialize({
    required String baseUrl,
    required String apiKey,
    bool requireSign = true,
    int maxImages = 3,
    String clientIDAccount = 'default',
  }) async {}

  @override
  Future<String> getClientId() async {
    final preferences = await _preferences;
    final current = preferences.getString(_clientIdKey);
    if (current != null && current.isNotEmpty) return current;
    final created = const Uuid().v4();
    await preferences.setString(_clientIdKey, created);
    return created;
  }

  @override
  Future<String?> getSavedSubmissionId() => readValue(_submissionIdKey);

  @override
  Future<void> setSavedSubmissionId(String? id) {
    return persistValue(_submissionIdKey, id);
  }

  @override
  Future<void> clearLocalState() async {
    final preferences = await _preferences;
    final keys = preferences.getKeys().where(
      (key) => key.startsWith(_keyPrefix) || key.startsWith('redeem.'),
    );
    for (final key in keys) {
      await preferences.remove(key);
    }
  }

  @override
  Future<void> persistValue(String key, String? value) async {
    final preferences = await _preferences;
    final namespacedKey = '$_keyPrefix$key';
    if (value == null) {
      await preferences.remove(namespacedKey);
    } else {
      await preferences.setString(namespacedKey, value);
    }
  }

  @override
  Future<String?> readValue(String key) async {
    final preferences = await _preferences;
    return preferences.getString('$_keyPrefix$key');
  }

  @override
  Future<String> submitReview({
    required List<ReviewImage> images,
    required String appVersion,
    String? idfv,
    String? campaignId,
    String? locale,
    String? externalUserId,
  }) {
    throw UnsupportedError('App Hub 使用 Dart HTTP 客户端提交活动资料');
  }

  @override
  Future<SubmissionStatus> getSubmissionStatus(String submissionId) async {
    return const SubmissionPending();
  }

  @override
  Future<SubmissionStatus> pollUntilComplete({
    required String submissionId,
    Duration initialInterval = const Duration(seconds: 5),
    Duration maxInterval = const Duration(seconds: 30),
    Duration timeout = const Duration(minutes: 10),
  }) async {
    return const SubmissionPending();
  }

  @override
  Future<SubmissionStatus> submitAndWait({
    required List<ReviewImage> images,
    required String appVersion,
    String? idfv,
    String? campaignId,
    String? locale,
    String? externalUserId,
    Duration timeout = const Duration(minutes: 10),
  }) async {
    return const SubmissionPending();
  }

  @override
  Future<void> presentOfferCodeRedeemSheet() async {}

  @override
  Future<void> openRedeemURL(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Future<String?> getIdfv() async => null;
}
