/// redeem_code 服务配置。
///
/// 上线前在 redeem 服务器执行：
/// ```bash
/// ./redeem seed-app -bundle com.bapaws.planbook -name "计划本" -apple-id 6737596725
/// ```
class RedeemConfig {
  static const baseUrl = String.fromEnvironment(
    'REDEEM_BASE_URL',
    defaultValue: 'https://redeemcode.bapaws.com',
  );

  static const apiKey = '5c949033c65e333a8b67efc57b884235db9fb957c417f64f';

  static bool get isConfigured => apiKey.isNotEmpty;
}
