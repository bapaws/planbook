import 'package:equatable/equatable.dart';
import 'package:planbook_api/database/color_scheme_converter.dart';
import 'package:planbook_api/planbook_api.dart';

const kTagSeparator = '/';

class TagEntity extends Equatable {
  const TagEntity({
    required this.tag,
    this.parent,
  });

  factory TagEntity.fromJson(Map<String, dynamic> json) {
    return TagEntity(
      tag: Tag.fromJson(json['tag'] as Map<String, dynamic>),
      parent: json['parent'] != null
          ? TagEntity.fromJson(json['parent'] as Map<String, dynamic>)
          : null,
    );
  }

  final Tag tag;
  final TagEntity? parent;

  String get id => tag.id;
  String get name => tag.name;
  String? get color => tag.color;
  String? get parentId => tag.parentId;
  int get order => tag.order;
  int get level => tag.level;
  ColorScheme? get light => tag.lightColorScheme;
  ColorScheme? get dark => tag.darkColorScheme;

  String get fullName {
    var fullName = name;
    var parent = this.parent;
    while (parent != null) {
      fullName = '${parent.name}$kTagSeparator$fullName';
      parent = parent.parent;
    }
    return fullName;
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag.toJson(),
      'parent': parent?.toJson(),
    };
  }

  @override
  List<Object?> get props => [tag, parent];

  TagEntity copyWith({
    Tag? tag,
    TagEntity? parent,
  }) {
    return TagEntity(
      tag: tag ?? this.tag,
      parent: parent ?? this.parent,
    );
  }
}
