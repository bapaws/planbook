import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/diary/model/diary_page_layout.dart';
import 'package:planbook_api/planbook_api.dart';

export 'diary_page_layout.dart';

/// 固定纸张坐标排版，阅读器缩放整张纸，分页与渲染共用相同度量。
const kDiaryPageSize = Size(420, 594);

/// 不使用运行时 hashCode，保证重启后相同内容仍选择相同版式。
int diaryLayoutSeed(String id) =>
    id.runes.fold(0, (hash, rune) => (hash * 31 + rune) & 0x7fffffff);

List<String> diaryPhotos(NoteEntity note) => <String>{
  if (note.coverImage case final String cover when cover.isNotEmpty) cover,
  ...note.images.where((image) => image.isNotEmpty),
}.toList();

class DiaryTextFrame {
  const DiaryTextFrame({
    required this.rect,
    required this.text,
    required this.titleLength,
    required this.layout,
  });

  final Rect rect;
  final String text;
  final int titleLength;
  final DiaryPageLayout layout;

  TextSpan get span {
    final title = text.substring(0, titleLength);
    final heading = title.replaceFirst(RegExp(r'\n+$'), '');
    return TextSpan(
      style: layout.bodyStyle,
      children: [
        if (heading.isNotEmpty)
          TextSpan(text: heading, style: layout.titleStyle),
        // 标题后的段间留白沿用正文字号，避免大标题空行挤掉正文。
        TextSpan(text: title.substring(heading.length)),
        TextSpan(text: text.substring(titleLength)),
      ],
    );
  }
}

class DiaryBookPage {
  const DiaryBookPage({
    required this.note,
    required this.part,
    required this.layout,
    required this.images,
    required this.frames,
    this.imageAspectRatios = const {},
    this.textOffset = 0,
  });

  final NoteEntity note;
  final int part;
  final DiaryPageLayout layout;
  final List<String> images;
  final List<DiaryTextFrame> frames;
  final Map<String, double> imageAspectRatios;
  final int textOffset;

  String get identity => '${note.id}:$part';
  String get text => frames.map((frame) => frame.text).join();

  /// 在网格内按原图比例居中，空出来的区域保留为纸张，不补色、不裁切。
  List<Rect> get imageRects {
    final slots = layout.imageRects;
    return [
      for (var i = 0; i < images.length; i++)
        if (_validRatio(imageAspectRatios[images[i]]) case final double ratio)
          layout
              .imageAlignment(i)
              .inscribe(
                applyBoxFit(
                  BoxFit.contain,
                  Size(ratio, 1),
                  slots[i].size,
                ).destination,
                slots[i],
              )
        else
          slots[i],
    ];
  }
}

double? _validRatio(double? ratio) =>
    ratio != null && ratio.isFinite && ratio > 0 ? ratio : null;

class DiaryBookDocument {
  const DiaryBookDocument(this.pages);

  factory DiaryBookDocument.fromNotes(
    List<NoteEntity> notes, {
    Map<String, double> imageAspectRatios = const {},
    TextScaler textScaler = TextScaler.noScaling,
    TextDirection textDirection = TextDirection.ltr,
    DiaryPaginationStatistics? statistics,
  }) {
    final pages = <DiaryBookPage>[];
    final ratios = Map<String, double>.unmodifiable(imageAspectRatios);
    for (final note in notes) {
      final seed = diaryLayoutSeed(note.id);
      final photos = diaryPhotos(note);
      final title = note.title.isEmpty ? '' : '${note.title}\n\n';
      final characters = '$title${note.content ?? ''}'.characters.toList();
      var offset = 0;
      var photoOffset = 0;
      var part = 0;
      String? previousComposition;
      int? pageBudget;
      _ScoredDraft? plannedPage;
      do {
        final remainingPhotos = photos.sublist(photoOffset);
        final titleRemaining = math.max(0, title.length - offset);
        List<_ScoredDraft> estimate(
          int imageCount, {
          bool continuation = false,
        }) => _measureCandidates(
          images: remainingPhotos.take(imageCount).toList(),
          characters: characters,
          titleRemaining: titleRemaining,
          ratios: ratios,
          textScaler: textScaler,
          textDirection: textDirection,
          prioritizeCapacity: continuation,
          statistics: statistics,
        );
        _ScoredDraft resolve(_ScoredDraft candidate) => candidate.measured
            ? candidate
            : _measureCandidates(
                images: remainingPhotos.take(candidate.imageCount).toList(),
                characters: characters,
                titleRemaining: titleRemaining,
                ratios: ratios,
                textScaler: textScaler,
                textDirection: textDirection,
                exact: true,
                layouts: [candidate.draft.layout],
                statistics: statistics,
              ).last;
        final maximumPhotos = math.min(9, remainingPhotos.length);
        final candidates = estimate(maximumPhotos);
        var selected = plannedPage;
        plannedPage = null;
        if (selected == null && remainingPhotos.length <= 9) {
          selected = _trySinglePage(
            candidates: candidates,
            characters: characters,
            titleRemaining: titleRemaining,
            textScaler: textScaler,
            textDirection: textDirection,
            seed: diaryLayoutSeed('$seed:$part'),
            imageCount: remainingPhotos.length,
            previousComposition: previousComposition,
            resolve: resolve,
            statistics: statistics,
          );
        }
        if (selected == null) {
          for (var count = 0; count < maximumPhotos; count++) {
            candidates.addAll(estimate(count, continuation: true));
          }
          if (characters.isNotEmpty &&
              candidates
                  .where((c) => c.imageCount == 0)
                  .every((c) => c.draft.count == 0)) {
            final empty = candidates.firstWhere((c) => c.imageCount == 0);
            candidates[candidates.indexOf(empty)] = resolve(empty);
          }
          // 用两个高容量、不同构图的正文模板校准续页容量。
          // 后续页数预测不能把估算偏大的容量反复当作余量，否则会多拆末页。
          final leaders = candidates.where((c) => c.imageCount == 0).toList()
            ..sort((a, b) => b.draft.count.compareTo(a.draft.count));
          final calibrated = <int, int>{};
          final families = <String>{};
          for (final leader in leaders) {
            if (!families.add(leader.draft.layout.composition)) continue;
            final actual = resolve(leader);
            candidates[candidates.indexOf(leader)] = actual;
            calibrated[0] = math.max(calibrated[0] ?? 0, actual.draft.count);
            if (families.length == 2) break;
          }
          final capacities = _PageCapacities(
            candidates,
            characters: characters.length,
            images: remainingPhotos.length,
            calibrated: calibrated,
          );
          int pagesAfter(_ScoredDraft c) =>
              1 +
              capacities.pagesFor(
                characters.length - c.draft.count,
                remainingPhotos.length - c.imageCount,
              );
          final estimateBudget = candidates.map(pagesAfter).reduce(math.min);
          final budget = math.min(pageBudget ?? estimateBudget, estimateBudget);
          var current = resolve(
            _selectDraft(
              candidates,
              seed: diaryLayoutSeed('$seed:$part'),
              characterCount: characters.length,
              imageCount: remainingPhotos.length,
              previousComposition: previousComposition,
              calibratedCapacities: calibrated,
            ),
          );
          // 估算的剩余页数也是翻页预算，精确测量后不能继续透支同一份余量。
          final alternatives = [...candidates]
            ..sort((a, b) => b.draft.count.compareTo(a.draft.count));
          for (final candidate in alternatives.take(3)) {
            if (pagesAfter(current) <= budget) break;
            final actual = resolve(candidate);
            if (pagesAfter(actual) < pagesAfter(current)) current = actual;
          }
          if (budget <= 2) {
            _ScoredDraft? tailFor(_ScoredDraft first) {
              final images = remainingPhotos.skip(first.imageCount).toList();
              if (images.length > 9) return null;
              final text = characters.skip(first.draft.count).toList();
              final heading = math.max(
                0,
                titleRemaining -
                    first.draft.frames
                        .map((f) => f.text.length)
                        .fold<int>(0, (a, b) => a + b),
              );
              final options = _measureCandidates(
                images: images,
                characters: text,
                titleRemaining: heading,
                ratios: ratios,
                textScaler: textScaler,
                textDirection: textDirection,
                statistics: statistics,
              );
              return _trySinglePage(
                candidates: options,
                characters: text,
                titleRemaining: heading,
                textScaler: textScaler,
                textDirection: textDirection,
                seed: diaryLayoutSeed('$seed:${part + 1}'),
                imageCount: images.length,
                previousComposition: first.draft.layout.composition,
                statistics: statistics,
                resolve: (c) => c.measured
                    ? c
                    : _measureCandidates(
                        images: images,
                        characters: text,
                        titleRemaining: heading,
                        ratios: ratios,
                        textScaler: textScaler,
                        textDirection: textDirection,
                        layouts: [c.draft.layout],
                        exact: true,
                        statistics: statistics,
                      ).last,
              );
            }

            plannedPage = tailFor(current);
            if (plannedPage == null) {
              // 两页方案实际复核尾页，避免临界的几行文字再多拆一页。
              final triedCounts = <int>{};
              for (final candidate in alternatives) {
                if (candidate.imageCount == current.imageCount &&
                    candidate.draft.layout == current.draft.layout) {
                  continue;
                }
                if (!triedCounts.add(candidate.imageCount)) continue;
                final actual = resolve(candidate);
                final tail = tailFor(actual);
                if (tail != null) {
                  current = actual;
                  plannedPage = tail;
                  break;
                }
              }
            }
          }
          pageBudget = math.max(budget, pagesAfter(current)) - 1;
          selected = current;
        }
        final draft = selected.draft;
        final images = remainingPhotos.take(selected.imageCount).toList();
        final page = DiaryBookPage(
          note: note,
          part: part,
          layout: draft.layout,
          images: images,
          frames: draft.frames,
          imageAspectRatios: ratios,
          textOffset: offset,
        );
        pages.add(page);
        previousComposition = draft.layout.composition;
        characters.removeRange(0, draft.count);
        offset += page.text.length;
        photoOffset += images.length;
        part++;
      } while (characters.isNotEmpty || photoOffset < photos.length);
    }
    return DiaryBookDocument(pages);
  }

  final List<DiaryBookPage> pages;

  /// 比例读取或笔记更新导致重排时，以正文位置定位，避免跳过正在阅读的内容。
  int indexForAnchor(DiaryBookPage? anchor, {int fallback = 0}) {
    if (pages.isEmpty) return 0;
    if (anchor != null) {
      final sameNote = pages.indexed.where(
        (entry) => entry.$2.note.id == anchor.note.id,
      );
      for (final (index, page) in sameNote) {
        if (anchor.text.isNotEmpty &&
            page.textOffset <= anchor.textOffset &&
            page.textOffset + page.text.length > anchor.textOffset) {
          return index;
        }
        if (anchor.text.isEmpty &&
            anchor.images.isNotEmpty &&
            page.images.contains(anchor.images.first)) {
          return index;
        }
      }
      if (sameNote.isNotEmpty) return sameNote.last.$1;
    }
    return fallback.clamp(0, pages.length - 1);
  }
}

_ScoredDraft? _trySinglePage({
  required List<_ScoredDraft> candidates,
  required List<String> characters,
  required int titleRemaining,
  required TextScaler textScaler,
  required TextDirection textDirection,
  required int seed,
  required int imageCount,
  required String? previousComposition,
  required _ScoredDraft Function(_ScoredDraft) resolve,
  DiaryPaginationStatistics? statistics,
}) {
  // 容量预估先挑构图，只精确试排被选中的模板；估算偏差时才换下一个。
  while (candidates.any((c) => c.draft.count == characters.length)) {
    final choice = _selectDraft(
      candidates,
      seed: seed,
      characterCount: characters.length,
      imageCount: imageCount,
      previousComposition: previousComposition,
    );
    final actual = resolve(choice);
    candidates[candidates.indexOf(choice)] = actual;
    if (actual.draft.count == characters.length) {
      return actual;
    }
  }
  // 不凭估算判定「放不下」：用同字体下更宽、更高的虚拟栏位排除整组，
  // 临界组才回退到逐个精确检查，避免多拆一页。
  {
    final groups = <(TextStyle, TextStyle), List<_ScoredDraft>>{};
    for (final candidate in candidates.where((c) => !c.measured)) {
      final layout = candidate.draft.layout;
      (groups[(layout.bodyStyle, layout.titleStyle)] ??= []).add(
        candidate,
      );
    }
    for (final group in groups.values) {
      final rects = group.expand((c) => c.draft.layout.textRects);
      final width = rects.map((r) => r.width).reduce(math.max);
      final height = group
          .map(
            (c) => c.draft.layout.textRects.fold<double>(
              0,
              (sum, rect) => sum + rect.height,
            ),
          )
          .reduce(math.max);
      final bound = _PageDraft.measure(
        layout: group.first.draft.layout,
        characters: characters,
        titleRemaining: titleRemaining,
        textScaler: textScaler,
        textDirection: textDirection,
        textRects: [Rect.fromLTWH(0, 0, width, height)],
        statistics: statistics,
      );
      statistics?.boundChecks++;
      if (bound.count < characters.length) continue;
      group.sort((a, b) => b.draft.count.compareTo(a.draft.count));
      for (final candidate in group) {
        final actual = resolve(candidate);
        candidates[candidates.indexOf(candidate)] = actual;
        if (actual.draft.count == characters.length) {
          return actual;
        }
      }
    }
  }

  return null;
}

List<_ScoredDraft> _measureCandidates({
  required List<String> images,
  required List<String> characters,
  required int titleRemaining,
  required Map<String, double> ratios,
  required TextScaler textScaler,
  required TextDirection textDirection,
  bool prioritizeCapacity = false,
  bool exact = false,
  List<DiaryPageLayout>? layouts,
  DiaryPaginationStatistics? statistics,
}) {
  final candidates = <_ScoredDraft>[];
  layouts ??= DiaryPageLayout.candidatesForImageCount(images.length);
  double capacity(DiaryPageLayout layout) =>
      layout.textRects.fold<double>(
        0,
        (area, rect) => area + rect.width * rect.height,
      ) /
      math.pow(textScaler.scale(layout.bodyStyle.fontSize!), 2) /
      layout.bodyStyle.height!;
  final largestCapacity = layouts.map(capacity).reduce(math.max);
  for (final layout in layouts) {
    // 完整图片组合已做单页校验；尝试拆分时先排除容量明显过小的文字区域。
    if (prioritizeCapacity && capacity(layout) < largestCapacity * 0.6) {
      continue;
    }
    final draft = exact
        ? _PageDraft.measure(
            layout: layout,
            characters: characters,
            titleRemaining: titleRemaining,
            textScaler: textScaler,
            textDirection: textDirection,
            statistics: statistics,
          )
        : _PageDraft.estimate(
            layout: layout,
            characters: characters,
            titleRemaining: titleRemaining,
            textScaler: textScaler,
          );
    if (exact) {
      statistics?.measuredLayouts++;
    } else {
      statistics?.estimatedLayouts++;
    }
    var mismatch = 0.0;
    var orientationMismatch = 0;
    var known = 0;
    var imageArea = 0.0;
    final slots = layout.imageRects;
    for (var i = 0; i < images.length; i++) {
      final ratio = _validRatio(ratios[images[i]]);
      final slot = slots[i];
      if (ratio == null) {
        imageArea += slot.width * slot.height;
        continue;
      }
      final slotRatio = slot.width / slot.height;
      if ((ratio < 0.65 && slotRatio >= 1) || (ratio > 1.8 && slotRatio <= 1)) {
        orientationMismatch++;
      }
      final fit = math.min(ratio / slotRatio, slotRatio / ratio);
      mismatch += 1 - fit;
      imageArea += slot.width * slot.height * fit;
      known++;
    }
    final photoMismatch = known == 0 ? 0.0 : mismatch / known;
    // 只以实际占用空间评分：空栏过多时优先更紧凑的构图，不按字数分组。
    final emptyFrames = draft.frames.where((f) => f.text.isEmpty).length;
    final spaceCost = characters.isEmpty
        ? 0.0
        : emptyFrames / draft.frames.length * 0.3 +
              math.max(0, 0.3 - draft.textFill) * 0.4;
    final progressCost = characters.isEmpty
        ? 0.0
        : (characters.length - draft.count) / characters.length * 0.35;
    candidates.add(
      _ScoredDraft(
        draft: draft,
        imageCount: images.length,
        score:
            photoMismatch * 1.2 +
            (known == 0 ? 0 : orientationMismatch / known * 0.65) +
            spaceCost +
            progressCost +
            (layout.isQuiet ? 0 : 0.35),
        imageArea: imageArea,
        photoMismatch: photoMismatch,
        measured: exact,
      ),
    );
  }
  if (exact &&
      images.isEmpty &&
      characters.isNotEmpty &&
      candidates.every((c) => c.draft.count == 0)) {
    // 极端字号下仍向前推进，避免空白续页死循环。
    candidates.add(
      _ScoredDraft(
        draft: _PageDraft.measure(
          layout: DiaryPageLayout.ruled,
          characters: characters,
          titleRemaining: titleRemaining,
          textScaler: textScaler,
          textDirection: textDirection,
          forceProgress: true,
        ),
        imageCount: 0,
        score: 10,
        imageArea: 0,
        photoMismatch: 0,
        measured: true,
      ),
    );
  }
  return candidates;
}

class _ScoredDraft {
  const _ScoredDraft({
    required this.draft,
    required this.imageCount,
    required this.score,
    required this.imageArea,
    required this.photoMismatch,
    required this.measured,
  });

  final _PageDraft draft;
  final int imageCount;
  final double score;
  final double imageArea;
  final double photoMismatch;
  final bool measured;
}

_ScoredDraft _selectDraft(
  List<_ScoredDraft> choices, {
  required int seed,
  required int characterCount,
  required int imageCount,
  required String? previousComposition,
  Map<int, int> calibratedCapacities = const {},
}) {
  var candidates = choices;
  var pool = candidates
      .where(
        (c) => c.draft.count == characterCount && c.imageCount == imageCount,
      )
      .toList();
  if (pool.isEmpty) {
    // 已确定要续页时，避免反复选用容量过小的文字块，消耗后续页面的余量。
    final largest = <int, int>{};
    for (final c in candidates) {
      largest[c.imageCount] = math.max(
        largest[c.imageCount] ?? 0,
        math.min(
          c.draft.count,
          calibratedCapacities[c.imageCount] ?? c.draft.count,
        ),
      );
    }
    candidates = candidates
        .where(
          (c) => c.draft.count >= largest[c.imageCount]! * 0.7,
        )
        .toList();
    final capacities = _PageCapacities(
      candidates,
      characters: characterCount,
      images: imageCount,
      calibrated: calibratedCapacities,
    );
    var fewestPages = characterCount + imageCount + 1;
    for (final c in candidates) {
      if (c.draft.count == 0 && c.imageCount == 0) continue;
      final pages =
          1 +
          capacities.pagesFor(
            characterCount -
                math.min(
                  c.draft.count,
                  calibratedCapacities[c.imageCount] ?? c.draft.count,
                ),
            imageCount - c.imageCount,
          );
      if (pages < fewestPages) {
        fewestPages = pages;
        pool = [c];
      } else if (pages == fewestPages) {
        pool.add(c);
      }
    }
  }
  // 页数优先级高于构图和照片适配度；仅在同样省页的方案中比较留白和变化。
  final bestPhotoFit = <int, double>{};
  for (final c in pool) {
    bestPhotoFit[c.imageCount] = math.min(
      bestPhotoFit[c.imageCount] ?? double.infinity,
      c.photoMismatch,
    );
  }
  pool = pool
      .where(
        (c) => c.photoMismatch <= bestPhotoFit[c.imageCount]! + 0.4,
      )
      .toList();
  final largestPhotoArea = pool.map((c) => c.imageArea).reduce(math.max);
  double quality(_ScoredDraft c) =>
      c.score +
      (largestPhotoArea == 0
          ? 0
          : math.max(0, 0.6 - c.imageArea / largestPhotoArea) * 0.7) +
      (imageCount > 0 && c.imageCount == 0 ? 0.15 : 0) +
      (characterCount > 0 &&
              c.draft.count == characterCount &&
              c.imageCount < imageCount
          ? 0.25
          : 0);
  final bestScore = pool.map(quality).reduce(math.min);
  pool = pool.where((c) => quality(c) <= bestScore + 0.5).toList();
  final groups = <String, List<_ScoredDraft>>{};
  for (final candidate in pool) {
    (groups[candidate.draft.layout.composition] ??= []).add(candidate);
  }
  // 近似适配的方案先轮换构图，再选变体；相邻续页尽量不重复同一种关系。
  if (groups.length > 1) groups.remove(previousComposition);
  final families = groups.values.toList();
  int stableIndex(int value, int length) {
    var hash = value;
    hash = ((hash ^ (hash >> 16)) * 0x45d9f3b) & 0x7fffffff;
    hash ^= hash >> 16;
    return hash % length;
  }

  final family = families[stableIndex(seed, families.length)];
  return family[stableIndex(diaryLayoutSeed('$seed:variant'), family.length)];
}

/// 用预估容量和少量精确校准，比较不同图文分组的预计总页数。
/// 每生成一页后按剩余正文更新，换行、标题和字号变化也进入下一轮计算。
class _PageCapacities {
  _PageCapacities(
    List<_ScoredDraft> candidates, {
    required int characters,
    required int images,
    required Map<int, int> calibrated,
  }) {
    final capacities = <int, int>{};
    for (final c in candidates) {
      capacities[c.imageCount] = math.max(
        capacities[c.imageCount] ?? 0,
        math.min(c.draft.count, calibrated[c.imageCount] ?? c.draft.count),
      );
    }
    _pages.add([0, ...List.filled(images, -1)]);
    while (_pages.last[images] < characters) {
      final previous = _pages.last;
      _pages.add([
        for (var photos = 0; photos <= images; photos++)
          capacities.entries
              .where((c) => c.key <= photos && previous[photos - c.key] >= 0)
              .fold(
                -1,
                (best, c) => math.max(best, previous[photos - c.key] + c.value),
              ),
      ]);
    }
  }

  final List<List<int>> _pages = [];

  int pagesFor(int characters, int images) =>
      _pages.indexWhere((page) => page[images] >= characters);
}

class _PageDraft {
  const _PageDraft(this.layout, this.frames, this.count, this.textFill);

  factory _PageDraft.measure({
    required DiaryPageLayout layout,
    required List<String> characters,
    required int titleRemaining,
    required TextScaler textScaler,
    required TextDirection textDirection,
    bool forceProgress = false,
    List<Rect>? textRects,
    DiaryPaginationStatistics? statistics,
  }) {
    var count = 0;
    var offset = 0;
    final frames = <DiaryTextFrame>[];
    var textArea = 0.0;
    var availableArea = 0.0;
    for (final rect in textRects ?? layout.textRects) {
      DiaryTextFrame frameFor(String text) => DiaryTextFrame(
        rect: rect,
        layout: layout,
        text: text,
        titleLength: math.min(
          text.length,
          math.max(0, titleRemaining - offset),
        ),
      );
      if (count == characters.length) {
        frames.add(frameFor(''));
        availableArea += rect.width * rect.height;
        continue;
      }
      // 按栏位尺寸限制初始试排长度，避免对完整长文反复塑形。
      final fontSize = math.max(
        1,
        math.min(
          textScaler.scale(layout.bodyStyle.fontSize!),
          textScaler.scale(layout.titleStyle.fontSize!),
        ),
      );
      var low = 0;
      var high = math.min(
        characters.length - count,
        math.max(
          16,
          (rect.width / fontSize * rect.height / fontSize * 2).ceil(),
        ),
      );
      final painter = TextPainter(
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: (rect.height / fontSize).ceil() + 2,
      );
      bool fits(int length) {
        painter
          ..text = frameFor(characters.skip(count).take(length).join()).span
          ..layout(maxWidth: rect.width);
        statistics?.paragraphLayouts++;
        if (statistics != null) {
          statistics.largestParagraph = math.max(
            statistics.largestParagraph,
            length,
          );
        }
        return !painter.didExceedMaxLines && painter.height <= rect.height;
      }

      // 长文只取当前栏位附近的前缀；全篇越来越长也不会反复塑形全文。
      while (fits(high)) {
        low = high;
        if (high == characters.length - count) break;
        high = math.min(
          characters.length - count,
          math.max(high + 1, high * 2),
        );
      }
      // 在实测范围内按字素二分，保留换行、emoji 和全部正文。
      while (low < high) {
        final mid = (low + high + 1) ~/ 2;
        if (fits(mid)) {
          low = mid;
        } else {
          high = mid - 1;
        }
      }
      // 单独的换行也可能占两行；窄栏放不下时留空，交给后续栏位或续页。
      low = _readingBreak(characters, count, low);
      final length = forceProgress && count < characters.length
          ? math.max(1, low)
          : low;
      final text = characters.skip(count).take(length).join();
      final frame = frameFor(text);
      frames.add(frame);
      availableArea += rect.width * rect.height;
      if (text.isNotEmpty) {
        painter
          ..text = frame.span
          ..layout(maxWidth: rect.width);
        statistics?.paragraphLayouts++;
        textArea += painter.height * rect.width;
      }
      painter.dispose();
      count += length;
      offset += text.length;
    }
    return _PageDraft(layout, frames, count, textArea / availableArea);
  }

  factory _PageDraft.estimate({
    required DiaryPageLayout layout,
    required List<String> characters,
    required int titleRemaining,
    required TextScaler textScaler,
  }) {
    var count = 0;
    var units = 0;
    var occupiedArea = 0.0;
    var availableArea = 0.0;
    final frames = <DiaryTextFrame>[];
    final bodySize = textScaler.scale(layout.bodyStyle.fontSize!);
    final titleSize = textScaler.scale(layout.titleStyle.fontSize!);
    for (final rect in layout.textRects) {
      var width = 0.0;
      var height = 0.0;
      var lineHeight = 0.0;
      final start = count;
      final startUnits = units;
      while (count < characters.length) {
        final character = characters[count];
        final heading = units < titleRemaining;
        final size = heading ? titleSize : bodySize;
        final nextHeight =
            size *
            (heading ? layout.titleStyle.height! : layout.bodyStyle.height!);
        final advance = size * _characterWidth(character);
        if (width > 0 && width + advance > rect.width) {
          height += lineHeight;
          width = 0;
          lineHeight = 0;
        }
        if (height + math.max(lineHeight, nextHeight) > rect.height) break;
        lineHeight = math.max(lineHeight, nextHeight);
        units += character.length;
        count++;
        if (character == '\n') {
          height += lineHeight;
          width = 0;
          lineHeight = 0;
        } else {
          width += advance;
        }
      }
      count = start + _readingBreak(characters, start, count - start);
      final text = characters.skip(start).take(count - start).join();
      units = startUnits + text.length;
      frames.add(
        DiaryTextFrame(
          rect: rect,
          text: text,
          layout: layout,
          titleLength: math.min(
            text.length,
            math.max(0, titleRemaining - startUnits),
          ),
        ),
      );
      occupiedArea += (height + lineHeight) * rect.width;
      availableArea += rect.width * rect.height;
    }
    return _PageDraft(layout, frames, count, occupiedArea / availableArea);
  }

  final DiaryPageLayout layout;
  final List<DiaryTextFrame> frames;
  final int count;
  final double textFill;
}

/// 汉字、拉丁字母、空格和标点按不同字宽估算，只用于候选排序，不决定裁切。
double _characterWidth(String character) {
  final code = character.runes.first;
  if (character == '\n') return 0;
  if (character == ' ' || character == '\t') {
    return character == '\t' ? 1.3 : 0.33;
  }
  if (code < 128) {
    if ("ilI.,:;!|'`".contains(character)) return 0.28;
    if ('MWmw@%'.contains(character)) return 0.85;
    return 0.55;
  }
  if (code >= 0x00c0 && code < 0x0530) return 0.6;
  return 1;
}

/// 供性能回归检查统计工作量，不参与布局选择。
@visibleForTesting
class DiaryPaginationStatistics {
  int estimatedLayouts = 0;
  int measuredLayouts = 0;
  int paragraphLayouts = 0;
  int boundChecks = 0;
  int largestParagraph = 0;
}

/// 在已测量的范围内优先结束于段落或句尾，英文栏末避免截断普通单词。
int _readingBreak(List<String> characters, int start, int count) {
  final end = start + count;
  if (count < 8 || end == characters.length) return count;
  final lower = start + (count * 0.8).ceil();
  for (var i = end - 1; i >= lower; i--) {
    if (characters[i] == '\n') return i + 1 - start;
  }
  const punctuation = ['。', '！', '？', '；', '.', '!', '?', ';'];
  for (var i = end - 1; i >= lower; i--) {
    if (punctuation.contains(characters[i])) return i + 1 - start;
  }
  final word = RegExp('[a-zA-Z0-9]');
  if (word.hasMatch(characters[end - 1]) && word.hasMatch(characters[end])) {
    for (var i = end - 1; i >= math.max(start + 1, end - 40); i--) {
      if (characters[i].trim().isEmpty) return i + 1 - start;
    }
  }
  return count;
}

/// 只重排内容或图片比例发生变化的篇目，翻到下一篇时不重复测量整本日记。
class DiaryBookPaginationCache {
  final Map<String, _CachedNotePages> _notes = {};

  DiaryBookDocument paginate(
    List<NoteEntity> notes, {
    required Map<String, double> imageAspectRatios,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    final ids = notes.map((note) => note.id).toSet();
    _notes.removeWhere((id, _) => !ids.contains(id));
    final pages = <DiaryBookPage>[];
    for (final note in notes) {
      final ratios = <String, double>{
        for (final path in diaryPhotos(note))
          if (imageAspectRatios[path] case final ratio?) path: ratio,
      };
      var cached = _notes[note.id];
      if (cached == null ||
          cached.note != note ||
          cached.scaler != textScaler ||
          cached.direction != textDirection ||
          !mapEquals(cached.ratios, ratios)) {
        cached = _CachedNotePages(
          note,
          textScaler,
          textDirection,
          ratios,
          DiaryBookDocument.fromNotes(
            [note],
            imageAspectRatios: ratios,
            textScaler: textScaler,
            textDirection: textDirection,
          ).pages,
        );
        _notes[note.id] = cached;
      }
      pages.addAll(cached.pages);
    }
    return DiaryBookDocument(pages);
  }
}

class _CachedNotePages {
  const _CachedNotePages(
    this.note,
    this.scaler,
    this.direction,
    this.ratios,
    this.pages,
  );

  final NoteEntity note;
  final TextScaler scaler;
  final TextDirection direction;
  final Map<String, double> ratios;
  final List<DiaryBookPage> pages;
}
