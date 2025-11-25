import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
// import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

const _imageQuality = 80;

Future<String?> showImagePicker(
  BuildContext context, {
  bool isEditable = false,
}) {
  return showCupertinoModalPopup<String>(
    context: context,
    builder: (_) {
      final l10n = context.l10n;
      return CupertinoActionSheet(
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: Text(Platform.isIOS ? l10n.photos : l10n.gallery),
            onPressed: () async {
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.gallery,
                imageQuality: _imageQuality,
              );
              if (!context.mounted) return;

              Navigator.of(context).pop(file?.path);
            },
          ),
          CupertinoActionSheetAction(
            child: Text(l10n.camera),
            onPressed: () async {
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: _imageQuality,
              );

              if (!context.mounted) return;

              // if (isEditable && file != null) {
              //   final path = showImageCropper(context, path: file.path);
              //   if (!context.mounted) return;

              //   Navigator.of(context).pop(path);
              // } else {
              Navigator.of(context).pop(file?.path);
              // }
            },
          ),
        ],
      );
    },
  );
}

Future<List<String>?> showMuiltiImagePicker(BuildContext context) {
  return showCupertinoModalPopup<List<String>>(
    context: context,
    builder: (_) {
      final l10n = context.l10n;
      return CupertinoActionSheet(
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(l10n.cancel),
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: Text(Platform.isIOS ? l10n.photos : l10n.gallery),
            onPressed: () async {
              final picker = ImagePicker();
              final files = await picker.pickMultiImage(
                limit: 9,
                imageQuality: _imageQuality,
              );
              if (!context.mounted) return;

              final paths = files.map((file) => file.path).toList();
              Navigator.of(context).pop(paths);
            },
          ),
          CupertinoActionSheetAction(
            child: Text(l10n.camera),
            onPressed: () async {
              final picker = ImagePicker();
              final file = await picker.pickImage(
                source: ImageSource.camera,
                imageQuality: _imageQuality,
              );

              if (!context.mounted || file == null) return;

              Navigator.of(context).pop([file.path]);
            },
          ),
        ],
      );
    },
  );
}

// Future<String?> showImageCropper(
//   BuildContext context, {
//   required String path,
// }) async {
//   final theme = Theme.of(context);
//   final file = await ImageCropper().cropImage(
//     sourcePath: path,
//     aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
//     uiSettings: [
//       AndroidUiSettings(
//         toolbarTitle: '',
//         toolbarColor: theme.colorScheme.surface,
//         toolbarWidgetColor: Colors.white,
//         cropStyle: CropStyle.circle,
//         aspectRatioPresets: [
//           CropAspectRatioPreset.square,
//         ],
//       ),
//       IOSUiSettings(
//         title: '',
//         hidesNavigationBar: true,
//         rotateClockwiseButtonHidden: true,
//         cropStyle: CropStyle.circle,
//         aspectRatioPresets: [
//           CropAspectRatioPreset.square,
//         ],
//       ),
//       WebUiSettings(
//         context: context,
//       ),
//     ],
//   );
//   return file?.path;
// }
