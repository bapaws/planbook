import 'package:planbook_api/database/database.dart';

extension NoteEntityX on Note {
  String get key => '${focusAt?.format(pattern: 'yyyy-MM-dd')}-${type?.name}';
}
