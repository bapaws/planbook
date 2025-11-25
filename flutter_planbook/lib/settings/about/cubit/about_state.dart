part of 'about_cubit.dart';

class AboutState extends Equatable {
  const AboutState({
    this.appName,
    this.appVersion,
    this.builderNumber,
  });

  final String? appName;
  final String? appVersion;
  final String? builderNumber;

  @override
  List<Object?> get props => [appName, appVersion, builderNumber];

  AboutState copyWith({
    ValueGetter<String?>? appName,
    ValueGetter<String?>? appVersion,
    ValueGetter<String?>? builderNumber,
  }) {
    return AboutState(
      appName: appName != null ? appName() : this.appName,
      appVersion: appVersion != null ? appVersion() : this.appVersion,
      builderNumber:
          builderNumber != null ? builderNumber() : this.builderNumber,
    );
  }
}
