import 'package:equatable/equatable.dart';
import 'package:jiffy/jiffy.dart';

class NoteImageEntity extends Equatable {
  const NoteImageEntity({
    required this.id,
    required this.image,
    required this.createdAt,
  });

  final String id;
  final String image;
  final Jiffy createdAt;

  @override
  List<Object?> get props => [id, image, createdAt];

  NoteImageEntity copyWith({
    String? id,
    String? image,
    Jiffy? createdAt,
  }) {
    return NoteImageEntity(
      id: id ?? this.id,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
