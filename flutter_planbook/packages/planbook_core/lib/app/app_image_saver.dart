import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';

class AppImageSaver {
  static Future<bool> checkAndRequestPermissions({
    required bool skipIfExists,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return false; // Only Android and iOS platforms are supported
    }

    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = deviceInfo.version.sdkInt;

      if (skipIfExists) {
        // Read permission is required to check if the file already exists
        return sdkInt >= 33
            ? await Permission.photos.request().isGranted
            : await Permission.storage.request().isGranted;
      } else {
        // No read permission required for Android SDK 29 and above
        return sdkInt >= 29 || (await Permission.storage.request().isGranted);
      }
    } else if (Platform.isIOS) {
      // iOS permission for saving images to the gallery
      return skipIfExists
          ? await Permission.photos.request().isGranted
          : await Permission.photosAddOnly.request().isGranted;
    }

    return false; // Unsupported platforms
  }

  static Future<SaveResult> saveImage(
    Uint8List imageBytes, {
    required String fileName,
    bool skipIfExists = false,
    int quality = 100,
    String? extension,
    String? androidRelativePath,
  }) async {
    final isGranted = await checkAndRequestPermissions(
      skipIfExists: skipIfExists,
    );
    if (!isGranted) {
      return SaveResult.fromMap({
        'isSuccess': false,
        'errorMessage': 'Permission denied',
      });
    }
    return SaverGallery.saveImage(
      imageBytes,
      quality: quality,
      extension: extension,
      fileName: fileName,
      androidRelativePath: androidRelativePath,
      skipIfExists: skipIfExists,
    );
  }
}
