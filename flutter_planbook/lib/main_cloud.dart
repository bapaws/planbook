import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_planbook/bootstrap.dart';
import 'package:flutter_planbook/core/model/app_channel.dart';

void main() async {
  AppChannel.instance.type = AppChannelType.cloud;
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(<String>['assets/google_fonts'], license);
  });

  await bootstrap();
}
