part of 'note_tag_bloc.dart';

sealed class NoteTagState extends Equatable {
  const NoteTagState();
  
  @override
  List<Object> get props => [];
}

final class NoteTagInitial extends NoteTagState {}
