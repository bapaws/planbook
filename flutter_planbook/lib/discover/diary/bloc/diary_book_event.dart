part of 'diary_book_bloc.dart';

sealed class DiaryBookEvent extends Equatable {
  const DiaryBookEvent();

  @override
  List<Object?> get props => [];
}

final class DiaryBookRequested extends DiaryBookEvent {
  const DiaryBookRequested();
}
