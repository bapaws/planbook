part of 'root_discover_bloc.dart';

final class RootDiscoverState extends Equatable {
  const RootDiscoverState({
    this.autoPlayCount = 0,
    this.focusDate,
    this.focusType,
    this.summaryDate,
    this.summaryType,
  });

  final int autoPlayCount;

  final Jiffy? focusDate;
  final NoteType? focusType;

  final Jiffy? summaryDate;
  final NoteType? summaryType;

  @override
  List<Object?> get props => [
    autoPlayCount,
    focusDate,
    focusType,
    summaryDate,
    summaryType,
  ];

  RootDiscoverState copyWith({
    int? autoPlayCount,
    ValueGetter<Jiffy?>? focusDate,
    ValueGetter<NoteType?>? focusType,
    ValueGetter<Jiffy?>? summaryDate,
    ValueGetter<NoteType?>? summaryType,
  }) {
    return RootDiscoverState(
      autoPlayCount: autoPlayCount ?? this.autoPlayCount,
      focusDate: focusDate != null ? focusDate() : this.focusDate,
      focusType: focusType != null ? focusType() : this.focusType,
      summaryDate: summaryDate != null ? summaryDate() : this.summaryDate,
      summaryType: summaryType != null ? summaryType() : this.summaryType,
    );
  }
}
