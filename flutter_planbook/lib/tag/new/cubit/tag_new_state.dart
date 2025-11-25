part of 'tag_new_cubit.dart';

final class TagNewState extends Equatable {
  const TagNewState({
    this.initialTag,
    this.status = PageStatus.initial,
    this.name = '',
    this.color,
    this.parentTag,
    this.light,
    this.dark,
  });

  factory TagNewState.fromData({TagEntity? tag}) {
    return TagNewState(
      initialTag: tag,
      name: tag?.name ?? '',
      color: tag?.color,
      light: tag?.light,
      dark: tag?.dark,
    );
  }

  final TagEntity? initialTag;

  final PageStatus status;
  final String name;
  final String? color;
  final ColorScheme? light;
  final ColorScheme? dark;

  final TagEntity? parentTag;

  @override
  List<Object?> get props => [
    initialTag,
    status,
    name,
    color,
    parentTag,
    light,
    dark,
  ];

  TagNewState copyWith({
    TagEntity? initialTag,
    PageStatus? status,
    String? name,
    String? color,
    TagEntity? parentTag,
    ColorScheme? light,
    ColorScheme? dark,
  }) {
    return TagNewState(
      initialTag: initialTag ?? this.initialTag,
      status: status ?? this.status,
      name: name ?? this.name,
      color: color ?? this.color,
      parentTag: parentTag ?? this.parentTag,
      light: light ?? this.light,
      dark: dark ?? this.dark,
    );
  }
}
