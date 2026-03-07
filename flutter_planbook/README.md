```sh
# iOS
$ flutter build ipa --target lib/main.dart

# Google Play
$ flutter build appbundle --target lib/main.dart --flavor store

# 国内应用市场（小米、VIVO）
$ flutter build apk --flavor store --target lib/main_store.dart

# 自分发（腾讯云存储）
$ flutter build apk --flavor cloud --target lib/main_cloud.dart
```op