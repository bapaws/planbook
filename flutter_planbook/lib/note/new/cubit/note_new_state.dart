part of 'note_new_cubit.dart';

final class NoteNewState extends Equatable {
  const NoteNewState({
    this.createdAt,
    this.initialNote,
    this.status = PageStatus.initial,
    this.title = '',
    this.content = '',
    this.images = const [],
    this.tags = const [],
    this.task,
  });

  factory NoteNewState.fromData({NoteEntity? note, TaskEntity? task}) {
    return NoteNewState(
      initialNote: note,
      title: note?.title ?? task?.title ?? '',
      content: note?.content ?? '',
      task: note?.task ?? task?.task,
      tags: note?.tags ?? task?.tags ?? const [],
      createdAt: note?.createdAt ?? Jiffy.now(),
    );
  }

  factory NoteNewState.fromJson(Map<String, dynamic> json) {
    return NoteNewState(
      status: PageStatus.values.byName(json['status'] as String),
      title: json['title'] as String,
      content: json['content'] as String,
      images: json['images'] as List<String>,
      tags: (json['tags'] as List<dynamic>)
          .map((tag) => TagEntity.fromJson(tag as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? Jiffy.parse(json['createdAt'] as String)
          : Jiffy.now(),
      task: json['task'] != null
          ? Task.fromJson(json['task'] as Map<String, dynamic>)
          : null,
    );
  }

  final PageStatus status;
  final NoteEntity? initialNote;

  final String title;
  final String content;
  final List<String> images;
  final List<TagEntity> tags;
  final Jiffy? createdAt;

  final Task? task;

  @override
  List<Object?> get props => [
    status,
    initialNote,
    title,
    content,
    images,
    tags,
    task,
    createdAt,
  ];

  NoteNewState copyWith({
    PageStatus? status,
    NoteEntity? initialNote,
    String? title,
    String? content,
    List<String>? images,
    List<TagEntity>? tags,
    ValueGetter<Task?>? task,
    Jiffy? createdAt,
  }) {
    return NoteNewState(
      status: status ?? this.status,
      initialNote: initialNote ?? this.initialNote,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      task: task == null ? this.task : task(),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'title': title,
      'content': content,
      'images': images,
      'tags': tags.map((tag) => tag.toJson()).toList(),
      'task': task?.toJson(),
      'createdAt': createdAt?.format(),
    };
  }
}
