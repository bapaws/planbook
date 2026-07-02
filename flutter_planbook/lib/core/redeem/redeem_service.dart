import 'package:flutter_planbook/core/redeem/redeem_config.dart';
import 'package:redeem_client/redeem_client.dart';

/// 好评截图兑换码服务单例，封装 [RedeemClient]。
class RedeemService {
  RedeemService._();

  static final RedeemService instance = RedeemService._();

  RedeemClient? _client;
  bool? _supported;

  RedeemClient? get client => _client;

  /// 是否可用：已配置 api_key 且当前平台支持（iOS）。
  Future<bool> get isAvailable async {
    if (!RedeemConfig.isConfigured) return false;
    _supported ??= await RedeemClient.isSupported;
    return _supported!;
  }

  Future<RedeemClient> _ensureClient() async {
    if (!RedeemConfig.isConfigured) {
      throw RedeemException('not_configured');
    }
    if (_client == null) {
      _client = RedeemClient(
        baseUrl: RedeemConfig.baseUrl,
        apiKey: RedeemConfig.apiKey,
      );
      await _client!.loadSavedSubmissionId();
    }
    return _client!;
  }

  Future<void> loadSavedSubmissionId() async {
    if (!RedeemConfig.isConfigured) return;
    final c = await _ensureClient();
    await c.loadSavedSubmissionId();
  }

  String? get savedSubmissionId => _client?.savedSubmissionId;

  Future<String> submitReview({
    required List<ReviewImage> images,
    required String appVersion,
    String? idfv,
  }) async {
    final c = await _ensureClient();
    return c.submitReview(
      images: images,
      appVersion: appVersion,
      idfv: idfv,
    );
  }

  Future<SubmissionStatus> getSubmissionStatus(String submissionId) async {
    final c = await _ensureClient();
    return c.getSubmissionStatus(submissionId);
  }

  Future<void> presentOfferCodeRedeemSheet() async {
    final c = await _ensureClient();
    await c.presentOfferCodeRedeemSheet();
  }

  Future<void> openRedeemURL(String url) async {
    final c = await _ensureClient();
    await c.openRedeemURL(url);
  }

  /// 清空本地保存的兑换提交记录，用于 Debug 重测。
  Future<void> clearLocalState() async {
    if (!RedeemConfig.isConfigured) {
      _client = null;
      return;
    }
    (_client ?? await _ensureClient()).savedSubmissionId = null;
  }
}
