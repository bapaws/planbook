import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_planbook/core/redeem/redeem_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:planbook_core/data/page_status.dart';
import 'package:redeem_client/redeem_client.dart';

part 'app_activity_redeem_event.dart';
part 'app_activity_redeem_state.dart';

class AppActivityRedeemBloc
    extends Bloc<AppActivityRedeemEvent, AppActivityRedeemState> {
  AppActivityRedeemBloc({
    this.campaignId,
    this.locale,
    this.requireImages = true,
    this.requireLink = false,
    RedeemService? redeemService,
  }) : _redeemService = redeemService ?? RedeemService.instance,
       super(AppActivityRedeemState(
         requireImages: requireImages,
         requireLink: requireLink,
       )) {
    on<AppActivityRedeemStarted>(_onStarted, transformer: restartable());
    on<AppActivityRedeemImagesPicked>(_onImagesPicked);
    on<AppActivityRedeemProofUrlChanged>(_onProofUrlChanged);
    on<AppActivityRedeemSubmitted>(_onSubmitted, transformer: droppable());
    on<AppActivityRedeemStatusRefreshed>(
      _onStatusRefreshed,
      transformer: restartable(),
    );
    on<AppActivityRedeemRedeemTapped>(_onRedeemTapped);
    on<AppActivityRedeemResetTapped>(_onResetTapped);
  }

  final String? campaignId;
  final String? locale;
  final bool requireImages;
  final bool requireLink;
  final RedeemService _redeemService;

  Future<void> _onStarted(
    AppActivityRedeemStarted event,
    Emitter<AppActivityRedeemState> emit,
  ) async {
    final available = await _redeemService.isAvailable;
    if (!available) {
      emit(
        state.copyWith(
          phase: AppActivityRedeemPhase.unsupported,
          status: PageStatus.success,
        ),
      );
      return;
    }

    await _redeemService.loadSavedSubmissionId();
    final submissionId = _redeemService.savedSubmissionId;
    if (submissionId == null) return;

    emit(
      state.copyWith(
        status: PageStatus.loading,
        submissionId: submissionId,
      ),
    );
    await _applyStatus(emit, submissionId);
  }

  void _onImagesPicked(
    AppActivityRedeemImagesPicked event,
    Emitter<AppActivityRedeemState> emit,
  ) {
    emit(
      state.copyWith(
        imagePaths: event.paths.take(3).toList(),
        phase: AppActivityRedeemPhase.initial,
        clearRejectReason: true,
      ),
    );
  }

  void _onProofUrlChanged(
    AppActivityRedeemProofUrlChanged event,
    Emitter<AppActivityRedeemState> emit,
  ) {
    emit(state.copyWith(proofUrl: event.url));
  }

  Future<void> _onSubmitted(
    AppActivityRedeemSubmitted event,
    Emitter<AppActivityRedeemState> emit,
  ) async {
    if (!state.canSubmit) return;

    emit(state.copyWith(status: PageStatus.loading));

    try {
      final images = state.imagePaths.isEmpty
          ? <ReviewImage>[]
          : await _buildReviewImages(state.imagePaths);
      final packageInfo = await PackageInfo.fromPlatform();
      final submissionId = await _redeemService.submitReview(
        images: images,
        appVersion: packageInfo.version,
        campaignId: campaignId,
        locale: locale,
        proofUrl: state.proofUrl.trim().isEmpty ? null : state.proofUrl.trim(),
      );

      emit(
        state.copyWith(
          submissionId: submissionId,
          phase: AppActivityRedeemPhase.pending,
          status: PageStatus.success,
        ),
      );
    } on RedeemException catch (e) {
      emit(_mapException(e));
    } on Object {
      emit(state.copyWith(status: PageStatus.failure));
    }
  }

  Future<void> _onStatusRefreshed(
    AppActivityRedeemStatusRefreshed event,
    Emitter<AppActivityRedeemState> emit,
  ) async {
    final submissionId = state.submissionId ?? _redeemService.savedSubmissionId;
    if (submissionId == null) return;

    emit(
      state.copyWith(
        status: PageStatus.loading,
        submissionId: submissionId,
      ),
    );
    await _applyStatus(emit, submissionId);
  }

  Future<void> _onRedeemTapped(
    AppActivityRedeemRedeemTapped event,
    Emitter<AppActivityRedeemState> emit,
  ) async {
    final redeemUrl = state.redeemUrl;
    if (redeemUrl != null && redeemUrl.isNotEmpty) {
      await _redeemService.openRedeemURL(redeemUrl);
    } else {
      await _redeemService.presentOfferCodeRedeemSheet();
    }
  }

  Future<void> _onResetTapped(
    AppActivityRedeemResetTapped event,
    Emitter<AppActivityRedeemState> emit,
  ) async {
    await _redeemService.clearLocalState();
    emit(
      AppActivityRedeemState(
        requireImages: requireImages,
        requireLink: requireLink,
      ),
    );
  }

  Future<void> _applyStatus(
    Emitter<AppActivityRedeemState> emit,
    String submissionId,
  ) async {
    try {
      final status = await _redeemService.getSubmissionStatus(submissionId);
      switch (status) {
        case SubmissionPending():
          emit(
            state.copyWith(
              phase: AppActivityRedeemPhase.pending,
              submissionId: submissionId,
              status: PageStatus.success,
            ),
          );
        case SubmissionRejected(:final reason):
          emit(
            state.copyWith(
              phase: AppActivityRedeemPhase.rejected,
              submissionId: submissionId,
              rejectReason: reason,
              status: PageStatus.success,
            ),
          );
        case SubmissionApproved(:final code, :final redeemUrl):
          emit(
            state.copyWith(
              phase: AppActivityRedeemPhase.approved,
              submissionId: submissionId,
              code: code,
              redeemUrl: redeemUrl,
              status: PageStatus.success,
            ),
          );
        case SubmissionGrantFailed(:final reason):
          emit(
            state.copyWith(
              phase: AppActivityRedeemPhase.pending,
              submissionId: submissionId,
              rejectReason: reason,
              status: PageStatus.success,
            ),
          );
      }
    } on RedeemException catch (e) {
      emit(_mapException(e));
    } on Object {
      emit(state.copyWith(status: PageStatus.failure));
    }
  }

  AppActivityRedeemState _mapException(RedeemException e) {
    if (e.isAlreadyRewarded) {
      return state.copyWith(
        phase: AppActivityRedeemPhase.alreadyRewarded,
        status: PageStatus.success,
      );
    }
    if (e.isRateLimited) {
      return state.copyWith(
        phase: AppActivityRedeemPhase.rateLimited,
        status: PageStatus.success,
      );
    }
    return state.copyWith(status: PageStatus.failure);
  }

  Future<List<ReviewImage>> _buildReviewImages(List<String> paths) async {
    final images = <ReviewImage>[];
    for (final path in paths) {
      final file = File(path);
      final bytes = await file.readAsBytes();
      final ext = p.extension(path).toLowerCase();
      if (ext == '.png') {
        images.add(ReviewImage.png(bytes, filename: p.basename(path)));
      } else {
        images.add(ReviewImage.jpeg(bytes, filename: p.basename(path)));
      }
    }
    return images;
  }
}
