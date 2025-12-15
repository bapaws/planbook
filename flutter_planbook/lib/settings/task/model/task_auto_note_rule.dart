import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';
import 'package:planbook_api/planbook_api.dart';

extension TaskAutoNoteTypeExtension on TaskAutoNoteType {
  String getTitle(BuildContext context) {
    return switch (this) {
      TaskAutoNoteType.create => context.l10n.create,
      TaskAutoNoteType.edit => context.l10n.edit,
      TaskAutoNoteType.createAndEdit => context.l10n.createAndEdit,
      TaskAutoNoteType.none => context.l10n.none,
    };
  }

  String getDescription(BuildContext context) {
    return switch (this) {
      TaskAutoNoteType.create => context.l10n.createDescription,
      TaskAutoNoteType.edit => context.l10n.editDescription,
      TaskAutoNoteType.createAndEdit => context.l10n.createAndEditDescription,
      TaskAutoNoteType.none => context.l10n.noneDescription,
    };
  }
}
