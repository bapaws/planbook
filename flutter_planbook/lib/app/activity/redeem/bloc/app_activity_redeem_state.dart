part of 'app_activity_redeem_bloc.dart';

/// 兑换流程阶段。
enum AppActivityRedeemPhase {
  initial,
  pending,
  approved,
  rejected,
  alreadyRewarded,
  rateLimited,
  unsupported,
}

final class AppActivityRedeemState extends Equatable {
  const AppActivityRedeemState({
    this.phase = AppActivityRedeemPhase.initial,
    this.status = PageStatus.success,
    this.imagePaths = const [],
    this.proofUrl = '',
    this.requireImages = true,
    this.requireLink = false,
    this.submissionId,
    this.code,
    this.redeemUrl,
    this.rejectReason,
  });

  final AppActivityRedeemPhase phase;
  final PageStatus status;
  final List<String> imagePaths;
  final String proofUrl;
  final bool requireImages;
  final bool requireLink;
  final String? submissionId;
  final String? code;
  final String? redeemUrl;
  final String? rejectReason;

  bool get canSubmit {
    if (status == PageStatus.loading) return false;
    if (phase != AppActivityRedeemPhase.initial &&
        phase != AppActivityRedeemPhase.rejected) {
      return false;
    }
    if (requireImages && imagePaths.isEmpty) return false;
    if (requireLink && proofUrl.trim().isEmpty) return false;
    return true;
  }

  bool get canRedeem =>
      phase == AppActivityRedeemPhase.approved && code != null;

  @override
  List<Object?> get props => [
    phase,
    status,
    imagePaths,
    proofUrl,
    requireImages,
    requireLink,
    submissionId,
    code,
    redeemUrl,
    rejectReason,
  ];

  AppActivityRedeemState copyWith({
    AppActivityRedeemPhase? phase,
    PageStatus? status,
    List<String>? imagePaths,
    String? proofUrl,
    bool? requireImages,
    bool? requireLink,
    String? submissionId,
    String? code,
    String? redeemUrl,
    String? rejectReason,
    bool clearRejectReason = false,
    bool clearSubmission = false,
    bool clearCode = false,
  }) {
    return AppActivityRedeemState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      imagePaths: imagePaths ?? this.imagePaths,
      proofUrl: proofUrl ?? this.proofUrl,
      requireImages: requireImages ?? this.requireImages,
      requireLink: requireLink ?? this.requireLink,
      submissionId: clearSubmission
          ? null
          : (submissionId ?? this.submissionId),
      code: clearCode ? null : (code ?? this.code),
      redeemUrl: clearCode ? null : (redeemUrl ?? this.redeemUrl),
      rejectReason: clearRejectReason
          ? null
          : (rejectReason ?? this.rejectReason),
    );
  }
}
