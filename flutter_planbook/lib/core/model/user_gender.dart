import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/entity/user_entity.dart';

extension UserGenderExtension on UserGender {
  String getTitle(BuildContext context) => switch (this) {
    UserGender.male => context.l10n.male,
    UserGender.female => context.l10n.female,
    UserGender.unknown => context.l10n.secret,
  };
}
