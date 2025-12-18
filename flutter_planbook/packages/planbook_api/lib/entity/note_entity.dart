import 'package:equatable/equatable.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/database.dart';
import 'package:planbook_api/entity/tag_entity.dart';

enum NoteListMode { all, written, task }

class NoteEntity extends Equatable {
  const NoteEntity({
    required this.note,
    this.tags = const [],
    this.task,
  });

  final Note note;
  final List<TagEntity> tags;
  final Task? task;

  String get id => note.id;
  String get title => note.title;
  String? get content => note.content;
  List<String> get images => note.images;
  String? get coverImage => note.coverImage;
  Jiffy get createdAt => note.createdAt;
  Jiffy? get updatedAt => note.updatedAt;
  Jiffy? get deletedAt => note.deletedAt;

  @override
  List<Object?> get props => [note, tags, task, coverImage];

  NoteEntity copyWith({
    Note? note,
    List<TagEntity>? tags,
    Task? task,
  }) {
    return NoteEntity(
      note: note ?? this.note,
      tags: tags ?? this.tags,
      task: task ?? this.task,
    );
  }
}
