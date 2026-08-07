# app_settings_ohos

https://pub.dev/packages/app_settings_ohos

A Flutter plugin for accessing phone settings on ohos devices from a Flutter application.

## Installation

First, add `app_settings_ohos` as a [dependency in your pubspec.yaml file](https://pub.dev/packages/app_settings_ohos).

```dart
flutter pub add app_settings_ohos
```

Next, import 'app_settings_ohos.dart' into your dart code.

```dart
import 'package:app_settings_ohos/app_settings_ohos.dart';
```

```pod
target 'Runner' do
  use_frameworks!
```

## Usage

```yaml
dependencies:
  app_settings: 5.1.1
  app_settings_ohos: 1.0.4
```

Open the settings of the application using `AppSettings.openAppSettings()`.
By default, `AppSettingsType.settings` is used as the type, which opens the general application settings.
If the given type is not supported on the current platform, the general settings are opened instead.

**ohos** If 'asOtherTask' is set to true, the settings page will open in another 'ability'.

```dart
Widget build(BuildContext context) {
  return ElevatedButton(
    onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.location,asAnotherTask: true),
    child: const Text('Open Location Settings'),
  );
}
```

Settings panels are not supported on ohos platforms.

