part of 'root_discover_bloc.dart';

final class RootDiscoverState extends Equatable {
  const RootDiscoverState({
    this.autoPlayFrom,
    this.autoPlayTo,
    this.focusDate,
    this.focusType,
    this.summaryDate,
    this.summaryType,
  });

  final Jiffy? autoPlayFrom;
  final Jiffy? autoPlayTo;

  final Jiffy? focusDate;
  final NoteType? focusType;

  final Jiffy? summaryDate;
  final NoteType? summaryType;

  @override
  List<Object?> get props => [
    autoPlayFrom,
    autoPlayTo,
    focusDate,
    focusType,
    summaryDate,
    summaryType,
  ];

  RootDiscoverState copyWith({
    Jiffy? autoPlayFrom,
    Jiffy? autoPlayTo,
    ValueGetter<Jiffy?>? focusDate,
    ValueGetter<NoteType?>? focusType,
    ValueGetter<Jiffy?>? summaryDate,
    ValueGetter<NoteType?>? summaryType,
  }) {
    return RootDiscoverState(
      autoPlayFrom: autoPlayFrom ?? this.autoPlayFrom,
      autoPlayTo: autoPlayTo ?? this.autoPlayTo,
      focusDate: focusDate != null ? focusDate() : this.focusDate,
      focusType: focusType != null ? focusType() : this.focusType,
      summaryDate: summaryDate != null ? summaryDate() : this.summaryDate,
      summaryType: summaryType != null ? summaryType() : this.summaryType,
    );
  }
}
