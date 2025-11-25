import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'note_tag_event.dart';
part 'note_tag_state.dart';

class NoteTagBloc extends Bloc<NoteTagEvent, NoteTagState> {
  NoteTagBloc() : super(NoteTagInitial()) {
    on<NoteTagEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
