# 鸿蒙 (HarmonyOS NEXT / OHOS) 集成方案

> 分支：`ohos`。目标：在鸿蒙上编译通过、核心功能无问题，最终上架华为应用市场。
> 已确认的决策：支付复用 store 渠道（微信+支付宝）；桌面小组件首版跳过；发布对齐华为市场上架。

---

## 1. 背景与风险结论

对全仓库 33 处 `Platform.is*` 门控和全部原生插件做了盘点，结论：

- **启动即崩溃点**：`lib/core/purchases/revenue_cat_purchases.dart:53` 在非 Android/iOS 平台 `throw UnimplementedError()`，而 `AppPurchases.initialize()` 无条件调用它 —— 鸿蒙上启动即崩，必须最先处理。
- **静默行为变化**：`Platform.isAndroid` / `isIOS` 在鸿蒙上都为 `false`，多数位置优雅降级为 no-op（闹钟、保存图片、小组件桥），但有几处危险：
  - `lib/bootstrap.dart:79` 隐私合规弹窗被跳过（国内渠道合规风险）；
  - `lib/app/activity/repository/app_activity_repository.dart:185` 平台过滤在鸿蒙上全部放行；
  - `packages/planbook_api/lib/supabase/app_supabase.dart:224` Google 登录会误用 Android client ID。
- **死依赖可删**：`in_app_purchase`（根 pubspec，零引用）、`hive`（planbook_api，零引用）、`drift_flutter`（仅注释中出现）。
- **数据库是单点**：所有 SQLite 访问收敛在 `packages/planbook_api/lib/database/database.dart` 的 `_openConnection()` 一个函数，换掉底层 `sqlite3` / `sqlite3_flutter_libs` 即可，Drift 层零改动。
- **桌面小组件两个包（home_widget / planbook_widget）都是本地插件且无 ohos 实现**，但 Dart 侧都有 `AppHomeWidget` 门面 / `MissingPluginException` 兜底，首版可安全 no-op。

## 2. 阶段划分

| 阶段 | 内容 | 验收标准 |
|---|---|---|
| Phase 0 | 工具链与版本对齐 | `flutter --version` 显示 ohos 分支，`flutter devices` 能看到鸿蒙设备/模拟器 |
| Phase 1 | 原生工程创建 + 依赖替换，编译通过 | `flutter build hap --debug` 成功 |
| Phase 2 | Dart 平台门控修复，跑通核心功能 | 启动不崩；任务/笔记/标签 CRUD + 同步正常 |
| Phase 3 | 账号体系（隐藏三方登录后）+ 支付（微信/支付宝） | 验证码/邮箱/密码登录、购买、恢复购买全链路通过 |
| Phase 4 | release 签名 + 上架华为市场 | `flutter build app --release` 出包，AGC 上传成功 |
| Phase 5（后续迭代） | 桌面小组件 ArkTS 重写 | 卡片可添加、可完成任务 |

---

## 3. Phase 0：工具链 ✅（2026-08-07 已验证）

1. **DevEco Studio 5.x** + OpenHarmony SDK（API 12+，建议 API 14/15）、hvigor、node。
2. **OpenHarmony Flutter SDK 分支**：已通过 fvm 安装 `custom_3.35.7-ohos`（Flutter 3.35.8-ohos-1.0.4-beta / Dart 3.9.2，gitcode.com/openharmony-tpc/flutter_flutter）。
   - **仅 ohos 分支**提交项目根 `.fvmrc`（pin `custom_3.35.7-ohos`）与 `.vscode/settings.json`（`dart.flutterSdkPath: .fvm/flutter_sdk`）。
   - **main / 其他分支不使用项目级 fvm**：无 `.fvmrc`，IDE 走 PATH / 全局 Flutter；家目录 `~/.fvmrc` 保持 `stable`。
   - 切回 main 后若本地仍残留 `.fvm/` 目录可忽略（已 gitignore）；勿把 `.fvmrc` / 含 fvm 的 settings 合入 main。
3. ~~⚠️ 版本对齐风险~~：Dart 3.9.2 满足 `environment: sdk: ^3.8.1`，**无需降级任何依赖**。
4. `flutter doctor`：**HarmonyOS toolchain ✅**、已连接 1 台设备；两个 warning（unknown channel / Android Studio 版本探测）为分支版噪声，可忽略。
5. 在 ohos 分支所有 flutter 命令经 `fvm flutter ...` 执行（或 IDE 读 `.fvm/flutter_sdk`）。

## 4. Phase 1：原生工程与依赖替换

### 4.1 创建 ohos 原生工程 ✅（2026-08-07 已完成）

```bash
fvm flutter create --platforms=ohos --org com.bapaws .
```

已完成的配置：
- `ohos/AppScope/app.json5`：bundleName `com.bapaws.planbook`，versionName 3.1.5 / versionCode 136（与 pubspec 对齐）；
- `ohos/build-profile.json5`：product 下加 `buildOption.strictMode.useNormalizedOHMUrl: true`（否则 sqlite3 的 Bytecode HAR 报 `00306046`）；
- `ohos/entry/src/main/module.json5`：模板自带 `ohos.permission.INTERNET`；通知/相册等权限按需后续补；
- 删除了 `flutter create` 生成的 `test/widget_test.dart`（默认计数器测试，与本项目无关）。

**当前状态**：Dart 编译已通过，产出 `entry-default-unsigned.hap`。**待办：配置调试签名** —— 用 DevEco Studio 打开 `ohos/` 工程，File → Project Structure → Signing Configs，勾选 Automatically generate signature（需登录华为开发者账号）。签名后即可 `fvm flutter run` 到真机/模拟器。

**适配记录 ①：flex_color_picker（已解决）**
- 症状：`switch (platform)` 对 `TargetPlatform` 穷尽匹配，OHOS 分支 SDK 新增了 `TargetPlatform.ohos`，编译报"not exhaustively matched"。
- 排查：上游 3.8.0 未修复，且 3.8.0 要求 Flutter ≥3.38（ohos SDK 3.35.8 不满足），3.7.2 与现有依赖图兼容。
- 处理：vendor 3.7.2 到 `packages/flex_color_picker`，根 pubspec 加 path override。
- **关键手法**：补丁用 `default:` 分支而非 `case TargetPlatform.ohos:` —— 后者在官方 SDK 上不存在，会导致 iOS/Android 构建反向编译失败。后续遇到同类问题一律用 default 写法，保持单一代码库三端可编译。

**适配记录 ②：插件 ohos 实现的来源矩阵（已落地，2026-08-07）**

| 插件 | 最终来源 | 备注 |
|---|---|---|
| fluwx 5.7.7 / tobias 5.3.4 | **上游已内置 ohos**，零改动 | 微信/支付宝 SDK 仍需鸿蒙版原生 SDK 配置 |
| shared_preferences / path_provider / url_launcher / image_picker | `gitcode.com/openharmony-sig/flutter_packages` git 依赖（`_ohos` 子包，sdk <4.0.0） | 加在 dependencies，不影响其他平台 |
| app_links / fluttertoast | pub.dev `app_links_ohos` / `fluttertoast_ohos` | SDK 约束兼容 Dart 3.9 |
| connectivity_plus / device_info_plus / package_info_plus / permission_handler / app_settings / flutter_timezone | pub.dev `_ohos` 版 SDK 约束停留在 Dart 2.x，**vendor 到 `packages/ohos_vendor/` 放宽约束**（并删掉 example/test 避免分析报错）；connectivity_plus_ohos 的 platform_interface 约束放宽到 `<3.0.0` | 不升 plus_plugins 老版本主包（API 太旧） |
| sqlite3 | SageMik/sqlite3-ohos.dart **分支 `sqlite3-2.9.4`**（经 ghproxy.net） | 含 `PlatformUtils.isOhos` 加载逻辑，版本满足 drift ^2.6.0 |
| sqlite3_flutter_libs | 同仓库 **tag `sqlite3_flutter_libs-0.5.25-ohos`** | 提供 ohos 的 libsqlite3.so；2.9.4 分支该包无 ohos，故跨 ref 组合 |
| sqflite / sqflite_common | `gitcode.com/openharmony-sig/flutter_sqflite`（2.2.8+3，override flutter_cache_manager 的 ^2.3.3+1） | ⚠️ 本分支 iOS/Android 也会用到此版本 |
| drift_flutter / hive / in_app_purchase | **已删除**（零引用死依赖） | |
| flutter_local_notifications / share_plus / audioplayers | **暂无 ohos 版，首版降级** | 闹钟服务本就有平台守卫 no-op；分享/音效后续补 |

**适配记录 ③：Dart 侧平台门控（已落地）**
- 新增 `kIsOhos` 常量（`packages/planbook_core/lib/app/app_platform.dart`），`Platform.operatingSystem == 'ohos'`，官方 SDK 恒 false；
- `RevenueCatPurchases.configure()` 鸿蒙直接 return（消除 `UnimplementedError` 启动崩溃）；`AppPurchases.initialize` 鸿蒙跳过 RC 配置、`revenueCatAvailable` 恒 false；
- `AppPurchases.isAndroidChina` / `bootstrap.dart` 隐私合规门控并入 `kIsOhos`；
- 新增入口 `lib/main_ohos.dart`（`AppChannelType.store`）。

### 4.2 入口与渠道

- 新增 `lib/main_ohos.dart`（复制 `main_store.dart`），`AppChannel.instance.type = AppChannelType.store`。**复用 store 渠道**可自动获得：china 支付路由（`AppPurchases.initialize(enableChinaPay:)`）、隐私弹窗（修复 bootstrap 判断后）、关闭 RevenueCat。
- `AppChannelType` 不新增枚举值；OS 差异用运行时判断，渠道差异继续用 `AppChannel`。

### 4.3 平台判断辅助

新增一个集中辅助（建议放 `packages/planbook_core`）：

```dart
/// 鸿蒙平台判断。OpenHarmony Flutter 分支中 operatingSystem 返回 'ohos'。
final bool kIsOhos = !kIsWeb && Platform.operatingSystem == 'ohos';
```

全仓库的鸿蒙门控统一走它，不散落 `Platform.operatingSystem == 'ohos'` 字符串。

### 4.4 依赖分层处理

**第三层：插件 ohos 平台实现**

> ⚠️ 实际落地来源以 **适配记录 ②**（§4.1）为准。调研期结论与落地的关键差异：
> fluwx/tobias 上游已内置 ohos 无需 fork；pub.dev 多数 `_ohos` 包 SDK 约束过旧需 vendor 放宽；
> sqlite3 用 2.9.4 分支 + flutter_libs 0.5.25 tag 的跨 ref 组合。

**第一层：直接删除（死依赖）**
- 根 pubspec：`in_app_purchase`
- `packages/planbook_api`：`hive`、`drift_flutter`（确认仅注释引用后删）

**第二层：纯 Dart，零改动**
bloc/flutter_bloc/hydrated_bloc（内部 hive_ce 为纯 Dart）、auto_route、rxdart、equatable、pdf、screenshot、flutter_easyloading、flutter_svg、fl_chart、table_calendar、google_fonts、intl/jiffy、uuid、http、supabase_flutter（网络部分纯 Dart）等。UI 库基本全部免改。

**第三层：换 OpenHarmony SIG 适配版（`dependency_overrides` 指向 gitcode/gitee fork）**

| 原插件 | 用途 / 使用位置 | 适配版来源 |
|---|---|---|
| sqlite3 / sqlite3_flutter_libs | Drift 底层（唯一入口 `database.dart:406`） | `github.com/SageMik/sqlite3-ohos.dart`（path: sqlite3 / sqlite3_flutter_libs，选与现版本一致的 ref） |
| shared_preferences | 各仓库同步时间戳等 | openharmony-sig/flutter_packages |
| path_provider | DB 路径、hydrated storage、缓存 | 同上 |
| url_launcher | 散落 9 个文件，无包装 | 同上 |
| connectivity_plus | SyncEngine | 同上 |
| device_info_plus | AppImageSaver | 同上 |
| package_info_plus | 散落 5 个文件 | 同上 |
| share_plus | 2 个文件 | 同上 |
| fluttertoast | 散落 16 个文件 | 同上 |
| image_picker | 笔记/头像 | 同上 |
| audioplayers | 任务完成音效（TaskActionService 单点） | openharmony-sig/flutter_audioplayers |
| flutter_local_notifications + flutter_timezone | AlarmNotificationService（已有抽象 `TaskAlarmScheduler`） | openharmony-sig/flutter_local_notifications |
| sqflite | flutter_cache_manager → cached_network_image 的传递依赖 | openharmony-sig/flutter_sqflite |
| fluwx | 微信支付（登录 API 首版不使用） | openharmony-sig/flutter_fluwx（需微信鸿蒙版 OpenSDK） |
| tobias | 支付宝支付 | openharmony-sig/flutter_tobias（需支付宝鸿蒙版 SDK） |
| app_links | 深链/AppLinksHandler | sig fork 或降级（见 §5） |
| permission_handler / saver_gallery / app_settings / image_cropper / in_app_review | 均有单点包装或低频次使用 | 先查 sig 列表，无适配则降级 |

> pub.dev 上部分已有 `_ohos` 后缀正式发布版（如 `shared_preferences_ohos`、`path_provider_ohos`、`url_launcher_ohos`），优先用 pub.dev 版，没有再走 git fork。引用前逐个核对版本与 ohos Flutter 基线的兼容性。

**第四层：自实现 / 降级**
- **purchases_flutter（RevenueCat）**：无鸿蒙支持。因 store 渠道 `enableChinaPay: true` 时实际不使用 RC，保留依赖但加运行时门控（见 §5），Dart 层不参与鸿蒙流程即可编译通过。
- **home_widget / planbook_widget**：首版不动原生侧，靠现有 `MissingPluginException` 兜底 no-op；给 `AppHomeWidget` 门面加 `kIsOhos` 早退，避免无意义调用。
- **background_downloader / install_plugin_v3**：仅 cloud 渠道自更新用，鸿蒙首版（store 渠道）不会触达，`kIsOhos` 早退即可。

## 5. Phase 2：Dart 门控修复清单（2026-08-07 已全部落地 ✅）

按优先级（前 4 项不修则启动崩或合规风险）：

1. ✅ `lib/core/purchases/app_purchases.dart` —— `revenueCatAvailable` 排除 `kIsOhos` 且跳过 RC configure；`isAndroidChina` 并入 `kIsOhos`。
2. ✅ `lib/core/purchases/revenue_cat_purchases.dart` —— `configure()` 在 `kIsOhos` 时直接 return，非 Android/iOS 平台改为跳过而非 `throw`。
3. ✅ `lib/bootstrap.dart:79` —— 隐私合规判断改为 `(Platform.isAndroid || kIsOhos) && AppChannel.isAndroidChina`。
4. ✅ `lib/app/activity/repository/app_activity_repository.dart` —— 两处 `ActivityPlatform` 过滤均增加鸿蒙分支（按 android 类目过滤）。
5. ✅（核对无需改动）`packages/planbook_api/lib/database/database.dart:406-447` —— Android workaround 已有平台守卫；鸿蒙走 `getApplicationDocumentsDirectory()` 默认分支；`sqlite3.tempDirectory` 由 path_provider_ohos 提供。
6. ✅ **登录：首版隐藏所有第三方登录**（华为审核要求：引入三方登录须同时提供华为登录；首版不接华为 Account Kit，故三方登录全部隐藏，只保留手机验证码 / 邮箱 / 密码）：
   - `lib/sign/home/cubit/sign_home_cubit.dart` —— `kIsOhos` 时跳过 `isWeChatInstalled` 检测（保持 `false`，主按钮自动回退为验证码/邮箱登录）；
   - `lib/sign/welcome/view/sign_welcome_page.dart` —— 微信主按钮加 `!kIsOhos` 门控（双保险）；Apple 按钮本就 iOS-only，鸿蒙自动隐藏；Google 登录无 UI 入口，无需处理；
   - `lib/mine/profile/view/mine_profile_page.dart` —— 隐藏"微信绑定"行；
   - `packages/planbook_api/lib/supabase/app_supabase.dart` —— `signInWithGoogle` / `signInWithWeChat` 在 `kIsOhos` 时抛友好 `AuthException`（防误调双保险）；
   - ⚠️ 后续版本若要恢复微信登录，**必须同步接入华为账号登录（Account Kit）**，否则审核不通过。
7. ⏸️（降级）`packages/planbook_repository/lib/task/alarm_notification_service.dart` —— flutter_local_notifications 暂无 ohos 版，现有 `Platform.isAndroid || Platform.isIOS` 守卫使鸿蒙自动 no-op（提醒功能鸿蒙首版不可用，待插件适配后放开）。
8. ✅（核对无需改动）`lib/app/view/app.dart` —— edgeToEdge 保持 Android-only；iOS MethodChannel 不受影响。
9. ✅（核对无需改动）兑换码/评分等 iOS-only 功能鸿蒙自动隐藏。
10. ✅ 散落插件使用点：url_launcher / fluttertoast / package_info_plus / connectivity_plus 等已有 ohos 实现，零改动；`share_plus`（活动页分享按钮 `!kIsOhos` 隐藏；日志导出走 catch 显示失败提示）、`in_app_review`（两处 `_requestReview` 加 `kIsOhos` 早退）。
11. ✅ **启动卡死修复（2026-08-07 已验证进首页）**：`home_widget` 无 ohos 实现，`bootstrap() → _initApp()` 首行 `AppHomeWidget.setAppGroupId` 抛 `MissingPluginException`，导致 `_app` 永远不挂载、停在 `_BootstrapLoadingPage` 空白占位页。修复方式遵循"判断放在插件门面内，主流程不写平台分支"：
    - `packages/planbook_core/lib/app/app_home_widget.dart` —— `AppHomeWidget` 全部方法在 `kIsOhos` 时 no-op（save/get/remove/updateWidget/refreshQuadrantWidgets），SettingsRepository / UsersRepository / TasksRepository 中 20+ 处运行时调用点零改动；
    - `packages/planbook_widget/lib/src/planbook_widget.dart` —— `notifyReady()` 增加 `on MissingPluginException` 容错（与 `setAppGroupId`/`clearPendingCompletion` 一致）。
12. ✅ **应用图标与名称（2026-08-07）**：`ohos/AppScope/resources/base/element/string.json` `app_name` 与 `entry/src/main/resources/{base,en_US}/element/string.json` `EntryAbility_label` → "Planbook"，`zh_CN` → "计划本"；图标用 `assets/logos/logo.png`（1024×1024）覆盖 `AppScope/resources/base/media/app_icon.png` 与 `entry/src/main/resources/base/media/icon.png`（模拟器桌面已验证显示 logo + "计划本"）。
13. ✅ **深链 scheme 注册（2026-08-07）**：`ohos/entry/src/main/module.json5` skills 增加 `ohos.want.action.viewData` + `uris.scheme = planbook.bapaws`（与 `AppLinksHandler.kAppUrlScheme` 一致），否则系统不会把 `planbook.bapaws://` 链接路由到 App；同文件加 `querySchemes: ["weixin", "alipays"]`（fluwx/tobias 鸿蒙端要求）。

## 6. Phase 3：账号体系与支付联调

- **登录**：首版仅验证码 / 邮箱 / 密码三条链路（Supabase Auth 纯网络实现，无原生依赖），逐一回归；三方登录入口全部隐藏（见 §5.6）。
- **微信支付**：`fluwx` ohos fork + 微信鸿蒙 OpenSDK，在微信开放平台登记鸿蒙 bundleName；只调用支付相关 API，登录 API 首版不使用。
- **支付宝**：`tobias` ohos fork + 支付宝鸿蒙 SDK，更新 pubspec 中 `tobias:` 配置的 url scheme。
- **支付路由**：store 渠道 + china 支付已有 `WechatPurchases`/`AlipayPurchases`（`AppPurchasesInterface` 实现），服务端下单逻辑（Supabase）不变，只换客户端 SDK。
- 华为 IAP Kit 首版不接（已决策）；若上架审核对虚拟商品支付有要求再评估。

**2026-08-07 代码侧核查结果（已完成 ✅，联调待真机）**：

- 依赖：pubspec 解析的 fluwx 5.7.7 / tobias 5.3.4（pub.flutter-io.cn 镜像）**均已内置 ohos 实现**，fluwx 支持 `registerApp`/`isWeChatInstalled`/`payWithFluwx`，tobias 支持 `pay`/`isAliPayInstalled` 等，无需换 fork。
- 支付路由：`main_ohos.dart` → store 渠道 → `AppChannel.isAndroidChina` → `PurchaseChannel.chinaPay`，RevenueCat 在 ohos 上跳过初始化（`AppPurchases.initialize` 已门控）；付费墙按 `usesChinaPay`（渠道而非平台）展示支付宝/微信按钮，Dart 侧零改动。
- `AppSupabase.initialize()` 中 `registerWeChat()` 无条件调用且有 try/catch，微信支付前 fluwx 已完成注册。
- `ohos/entry/src/main/module.json5` 已加 `querySchemes: ["weixin", "alipays"]`（两插件鸿蒙端查安装/跳转的前提），重打包冒烟通过。

**真机联调清单（需装了微信/支付宝的鸿蒙真机 + 手动申请调试证书）**：微信支付下单 → 拉起微信 → 回调查单 → PRO 点亮；支付宝下单 → 拉起 → resultStatus 9000 → 查单；restore 补单；微信侧需先在开放平台登记 bundleName 并按 fluwx 提示使用手动申请的调试证书（IDE 自动签名微信校验不过）。

## 7. Phase 4：签名与上架

**当前签名状态（2026-08-07）**：DevEco 自动调试签名已配置（`~/.ohos/config/`，`appProvisionType: debug`），debug / release 包均可构建并安装到模拟器与已注册设备。`flutter build hap --release --target lib/main_ohos.dart` 已验证产出 48.4MB 签名 hap 并在模拟器正常运行（欢迎页第三方登录已隐藏 ✅）。

**⚠️ release 引擎包补丁（机器本地，不进仓库）**：fork 1.0.4-beta 的 `flutter_embedding_release.har` 内 `OhosAutoFillHelper.ets` 使用了 HarmonyOS API 26 才有的自动填充类型（`autoFillManager.AutoFillType`/`ViewData`/`FillRequest`），在本机 SDK（API 23，DevEco 自带 API 24 同样没有）下 release 编译报 15 个 ArkTS 错误；debug 包不受影响是因 2026-07-28 已对 `flutter_embedding_debug.har` 打过同款补丁（`autoFillType` 改用 `number`，注释 `use number for SDK<=24 compile`）。修复：把 debug har 中打补丁的 `OhosAutoFillHelper.ets` 覆盖进 release har（gzip tar 重打包，原件备份 `.bak`），位置 `~/fvm/versions/custom_3.35.7-ohos/bin/cache/artifacts/engine/ohos-arm64-release/`。**其他机器/CI 打 release 包需重复此补丁**，待 fork 官方修复后升级 SDK 可丢弃。

上架前还需（发布签名四件套不进仓库）：

1. 华为开发者联盟 + AppGallery Connect 创建应用（包名 `com.bapaws.planbook`）。
2. ~~DevEco Studio 生成密钥（p12）与 CSR，AGC 申请发布证书 + Profile~~ ✅（2026-08-07 已完成）：命令行 keytool 生成 `planbook.p12`（EC secp256r1 / SHA256withECDSA / alias `planbook_release` / 25 年）+ CSR，AGC 已签发发布证书与发布 Profile（主体：合肥八爪未来科技有限公司，有效期至 2029-08-07）。**签名材料全部在 `~/.ohos/sign/release/`（p12/cer/p7b/PASSWORDS.txt，chmod 600，不进仓库）；仓库内 `build-profile.json5` 只保留调试签名**。
3. 上架包构建 ✅（2026-08-07 已验证）：`tool/ohos_release_app.sh` 一键产出 —— 临时摘掉 product 的 signingConfig 构建未签名 .app，再用 SDK `hap-sign-tool.jar`（`-mode localSign`）以发布证书签名并 verify-app 校验，密码从 PASSWORDS.txt 运行时读取（不写入任何仓库文件，避免明文泄露）；产物 `build/ohos/outputs/planbook-<versionName>-<versionCode>-release.app`（签名材料仍在 `~/.ohos/sign/release/`），已验证签名为发布证书。日常 debug 开发不受影响的（脚本用 trap 恢复配置）。
4. 上架材料：隐私政策 URL（复用现有）、软著、ICP、应用截图（鸿蒙设备）。
5. Fastlane 无鸿蒙 lane，发布脚本后续再补；首版手工上传 AGC。

## 8. Phase 5（后续）：桌面小组件

鸿蒙卡片 = ArkTS `FormExtensionAbility` + ArkUI 卡片 UI，与现有 Android/iOS 实现完全不同栈：
- `packages/home_widget`：加 `ohos` 平台实现（MethodChannel ↔ ArkTS，数据经 Preferences/FormBindingData 传递）；
- `packages/planbook_widget`：同上，完成任务等 action 需要卡片点击事件回传 Flutter；
- Dart 门面 `AppHomeWidget` 接口保持不变。
届时单独立项，参照 `docs/widget_design.md`。

## 9. 功能降级对照表（首版，已按实际适配更新）

| 功能 | 鸿蒙首版状态 |
|---|---|
| 任务/笔记/标签 CRUD + Supabase 同步 | ✅ 完整 |
| 本地通知/闹钟提醒 | ❌ flutter_local_notifications 无 ohos 版，自动 no-op（待插件适配） |
| 手机验证码 / 邮箱 / 密码登录 | ✅ |
| 微信登录 | ❌ 首版隐藏（恢复时必须同步接入华为 Account Kit） |
| Google / Apple 登录 | ❌ 隐藏（无 GMS / 非 Apple 平台） |
| 微信绑定（个人资料页） | ❌ 首版隐藏 |
| 微信 / 支付宝支付 | ✅（fluwx/tobias 上游已内置 ohos） |
| RevenueCat 订阅 | ❌ 不参与（store 渠道逻辑） |
| 桌面小组件 | ❌ no-op，Phase 5 补 |
| APK 自更新 | ❌ 仅 cloud 渠道，鸿蒙不涉及 |
| 兑换码（redeem） | ❌ iOS-only，自动隐藏 |
| 应用内评分 | ❌ in_app_review 无 ohos 版，已加守卫；商店好评活动页在鸿蒙 release 下整页隐藏（`AppActivityRepository` 按 openURL 过滤 play.google.com / apps.apple.com，2026-08-07；debug 构建不过滤平台是既有行为） |
| 活动页分享 | ❌ share_plus 无 ohos 版，按钮隐藏 |
| 日志导出（PDF/图片） | ⚠️ 降级：导出后分享/保存失败提示（share_plus、saver_gallery 均无 ohos 版） |
| 任务完成音效 | ⚠️ audioplayers 有 gitcode 适配版但未接（接口版本差异大），首版静音 |
| 深链（app_links） | ✅ app_links_ohos + `module.json5` 注册 `planbook.bapaws` scheme（skills: viewData/browsable）；热启动已验证（`aa start -U "planbook.bapaws://task/new?priority=high"` 打开新建任务页并带上高优先级），冷启动与其他平台行为一致 |

## 10. 验证清单

```bash
flutter analyze
flutter test
flutter run --target lib/main_ohos.dart          # 鸿蒙设备/模拟器
flutter build hap --debug && flutter build app --release
```

真机回归：启动 → 隐私弹窗 → 登录（验证码/邮箱/密码）→ 任务 CRUD → 完成音效 → 本地提醒触发 → 同步（开关网络）→ 笔记 → 标签 → 购买/恢复 → 分享 → 深链打开。重点确认：全 App 不出现任何微信/Apple/Google 登录入口（含个人资料页微信绑定行）。

**2026-08-07 模拟器回归结果（debug 包，hdc uitest 驱动）**：`flutter analyze` 0 error / `flutter test` 全过 ✅；启动进首页 ✅；新建任务 → 勾选完成 → 自动打开笔记编辑 → 保存 ✅；搜索「回归」同时命中任务与笔记 ✅；四象限 / 时间轴视图渲染 ✅；抽屉标签列表（工作/学习/生活，含同步数据）+ 标签筛选 ✅；设置页 / 个人资料页（无微信绑定行）✅；深链热启动 ✅；**付费墙：商品从 Supabase 加载（1年¥48/3年¥98/终身¥128）、支付宝支付 + 微信支付按钮、恢复入口均正常 ✅**；release 包首启欢迎页仅验证码/手机/邮箱/密码 ✅；hilog 无任何 error/exception。待真机验证：三条登录链路的实际收发（验证码需真实手机号）、购买/恢复实际扣款与回调（需装微信/支付宝的真机）、隐私弹窗首启流程、release 构建下好评活动隐藏确认（需登录态）。

## 参考资料

- [OpenHarmony SIG Flutter 分支与适配插件（gitcode/gitee）](https://gitee.com/openharmony-sig/flutter_packages)
- [sqlite3 鸿蒙适配（SageMik/sqlite3-ohos.dart）](https://github.com/SageMik/sqlite3_simple/blob/master/README.md)
- [华为开发者联盟：sqlite3 组件适配说明](https://developer.huawei.com/consumer/cn/forum/topic/0202172957235111115)
- [Flutter 跨平台数据库 SQLite 鸿蒙化适配指南](https://openharmonycrossplatform.csdn.net/69c508f40a2f6a37c59acaf7.html)
- [drift 在 OpenHarmony 的持久化方案](https://blog.csdn.net/cannonjinx/article/details/157912989)
- [tobias 鸿蒙端支付宝支付适配实践](https://www.cnblogs.com/yangykaifa/p/19497752)
- [鸿蒙 Flutter 支付集成（华为支付+三方）](https://blog.csdn.net/2502_94138550/article/details/155529872)
- [Flutter 与 HarmonyOS NEXT IAPKit 避坑指南](https://juejin.cn/post/7489315969318961163)
