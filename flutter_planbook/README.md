```sh
# 请用 fvm（按分支 .fvmrc 锁定 SDK）；切分支后建议执行一次 fvm use

# iOS
$ fvm flutter build ipa --target lib/main.dart

# Google Play
$ fvm flutter build appbundle --target lib/main.dart --flavor store

# 国内应用市场（小米、VIVO）
$ fvm flutter build apk --flavor store --target lib/main_store.dart

# 自分发（腾讯云存储）
$ fvm flutter build apk --flavor cloud --target lib/main_cloud.dart
```
