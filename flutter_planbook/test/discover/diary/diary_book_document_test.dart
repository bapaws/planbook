import 'package:flutter/material.dart';
import 'package:flutter_planbook/discover/diary/model/diary_book_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';

NoteEntity _note({
  String id = 'diary',
  String title = '一个平凡而美好的下午',
  String? content = '在树荫下读书，和朋友喝了一杯咖啡。',
  List<String> images = const [],
  String? cover,
}) => NoteEntity(
  note: Note(
    id: id,
    title: title,
    content: content,
    images: images,
    coverImage: cover,
    createdAt: Jiffy.parse('2026-10-23'),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('短日记各占一页，即使来自同一天也不合并', () {
    final document = DiaryBookDocument.fromNotes([
      _note(),
      _note(id: 'second'),
    ]);
    expect(document.pages, hasLength(2));
    expect(document.pages.map((page) => page.note.id), ['diary', 'second']);
  });

  test('容量预筛选后只精确测量少量候选，结果仍经过真实高度校验', () {
    final statistics = DiaryPaginationStatistics();
    final note = _note(
      title: '',
      content: '阳光洒在窗边。\n慢慢过一天。',
      images: ['photo'],
    );
    final document = DiaryBookDocument.fromNotes(
      [note],
      imageAspectRatios: {'photo': 1.2},
      statistics: statistics,
    );
    expect(document.pages, hasLength(1));
    expect(document.pages.single.text, note.content);
    expect(statistics.estimatedLayouts, greaterThan(10));
    expect(statistics.measuredLayouts, inInclusiveRange(1, 3));
  });

  test('超长正文只测量当前栏位附近的前缀，不在每页重复塑形全文', () {
    final statistics = DiaryPaginationStatistics();
    final content = '今天沿着河边慢慢走，记下细小的心情。\n' * 500;
    final document = DiaryBookDocument.fromNotes(
      [
        _note(title: '', content: content, images: ['a', 'b', 'c']),
      ],
      statistics: statistics,
    );
    expect(document.pages.length, greaterThan(10));
    expect(document.pages.map((p) => p.text).join(), content);
    expect(
      statistics.largestParagraph,
      lessThan(content.characters.length ~/ 2),
    );
    expect(
      statistics.measuredLayouts,
      lessThan(statistics.estimatedLayouts ~/ 2),
    );
  });

  test('未变化的日记复用页面对象，编辑一篇不会使其他篇目的缓存失效', () {
    final cache = DiaryBookPaginationCache();
    final first = _note(id: 'first');
    final second = _note(id: 'second');
    DiaryBookDocument build(List<NoteEntity> notes) => cache.paginate(
      notes,
      imageAspectRatios: {},
      textScaler: TextScaler.noScaling,
      textDirection: TextDirection.ltr,
    );
    final original = build([first, second]);
    final repeated = build([first, second]);
    expect(identical(original.pages.first, repeated.pages.first), isTrue);
    expect(identical(original.pages.last, repeated.pages.last), isTrue);
    final changed = build([_note(id: 'first', content: '更新今天的记录。'), second]);
    expect(identical(original.pages.first, changed.pages.first), isFalse);
    expect(identical(original.pages.last, changed.pages.last), isTrue);
  });

  test('不按二百字分组，短文也能用多栏构图，跨过旧门槛不会被强制拆页', () {
    for (final length in [180, 200, 201, 220]) {
      final seen = <bool>{};
      for (var id = 0; id < 24; id++) {
        final document = DiaryBookDocument.fromNotes([
          _note(id: 'space-$id', title: '', content: '记' * length),
        ]);
        expect(document.pages, hasLength(1));
        seen.add(document.pages.single.layout.isLongForm);
      }
      expect(seen, containsAll([true, false]));
    }
    final short = DiaryBookDocument.fromNotes([
      _note(title: '', content: '记' * 180, images: ['photo']),
    ]);
    expect(short.pages, hasLength(1));
    expect(short.pages.single.layout.isLongForm, isTrue);
  });

  test('相同字符数按实际换行和字号占用空间选版，只有放不下才续页', () {
    final compact = _note(title: '', content: '记录' * 90);
    final airy = _note(title: '', content: '记\n' * 90);
    final first = DiaryBookDocument.fromNotes([compact]);
    final second = DiaryBookDocument.fromNotes([airy]);
    final enlarged = DiaryBookDocument.fromNotes(
      [compact],
      textScaler: const TextScaler.linear(2.5),
    );
    expect(first.pages, hasLength(1));
    expect(second.pages.length, greaterThan(1));
    expect(enlarged.pages.length, greaterThan(1));
    expect(second.pages.map((p) => p.text).join(), airy.content);
    expect(enlarged.pages.map((p) => p.text).join(), compact.content);
  });

  test('任何候选的一块文字区域能放下全文时，不能为图片适配或构图额外分页', () {
    for (var count = 0; count <= 9; count++) {
      for (final length in [20, 60, 120, 180]) {
        for (final scale in [1.0, 1.6]) {
          final content = '记' * length;
          final scaler = TextScaler.linear(scale);
          final fits = DiaryPageLayout.candidatesForImageCount(count).any(
            (layout) => layout.textRects.any((rect) {
              final painter = TextPainter(
                text: TextSpan(text: content, style: layout.bodyStyle),
                textScaler: scaler,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: rect.width);
              final fits = painter.height <= rect.height;
              painter.dispose();
              return fits;
            }),
          );
          if (!fits) continue;
          final photos = List.generate(count, (i) => 'photo-$i');
          final document = DiaryBookDocument.fromNotes(
            [_note(title: '', content: content, images: photos)],
            textScaler: scaler,
            imageAspectRatios: {
              for (var i = 0; i < photos.length; i++)
                photos[i]: i.isEven ? 0.4 : 3.0,
            },
          );
          expect(
            document.pages,
            hasLength(1),
            reason: '$count / $length / $scale',
          );
          expect(document.pages.single.images, photos);
          expect(document.pages.single.text, content);
        }
      }
    }
  });

  test('长标题、正文、换行和组合 emoji 分页后完整保留且均能放入纸张', () {
    final note = _note(
      title: '很长的标题。' * 60,
      content: '今天的故事 👨‍👩‍👧‍👦 é\n\n每一次出发都值得记录。\n' * 100,
    );
    for (final scale in [1.0, 1.8, 2.5]) {
      final scaler = TextScaler.linear(scale);
      final document = DiaryBookDocument.fromNotes([note], textScaler: scaler);
      expect(document.pages.length, greaterThan(1));
      expect(
        document.pages.map((page) => page.text).join(),
        '${note.title}\n\n${note.content}',
      );
      for (final page in document.pages) {
        for (final frame in page.frames.where(
          (frame) => frame.text.isNotEmpty,
        )) {
          final painter = TextPainter(
            text: frame.span,
            textScaler: scaler,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: frame.rect.width);
          expect(painter.height, lessThanOrEqualTo(frame.rect.height));
          expect(frame.text.characters.first, isNot('‍'));
          expect(frame.text.characters.last, isNot('‍'));
          painter.dispose();
        }
      }
    }
  });

  test('多图跨页完整保留，封面图去重，不会丢失正文', () {
    final photos = List.generate(10, (index) => 'photo-$index.jpg');
    final note = _note(images: photos, cover: photos[2], content: '记录。' * 400);
    final document = DiaryBookDocument.fromNotes([note]);
    expect(document.pages.length, greaterThanOrEqualTo(2));
    expect(document.pages.first.images.length, inInclusiveRange(0, 9));
    expect(
      document.pages.where((page) => page.images.isNotEmpty).length,
      greaterThan(1),
    );
    final images = document.pages.expand((page) => page.images).toList();
    expect(images, hasLength(10));
    expect(images.toSet(), photos.toSet());
    expect(images.first, photos[2]);
    expect(
      document.pages.map((page) => page.text).join(),
      '${note.title}\n\n${note.content}',
    );
  });

  test('空白日记保留一页，版式由图片数量和稳定 ID 决定', () {
    expect(
      DiaryBookDocument.fromNotes([_note(title: '', content: '')]).pages,
      hasLength(1),
    );
    final note = _note(images: ['one.jpg']);
    final first = DiaryBookDocument.fromNotes([note]).pages.first;
    final second = DiaryBookDocument.fromNotes([note]).pages.first;
    expect(first.layout, second.layout);
    expect(first.identity, second.identity);
  });

  test('四到九图短日记整组展示，保持照片顺序且稳定选版', () {
    for (var count = 4; count <= 9; count++) {
      for (var seed = 0; seed < 4; seed++) {
        final photos = List.generate(count, (index) => 'photo-$index.jpg');
        final note = _note(
          id: 'layout-$seed',
          title: '春日',
          content: '记录此刻。',
          images: photos,
        );
        final document = DiaryBookDocument.fromNotes([note]);
        expect(document.pages, hasLength(1), reason: '$count 图 / $seed');
        final page = document.pages.single;
        expect(page.images, photos);
        expect(page.layout.imageRects, hasLength(count));
        expect(page.text, '${note.title}\n\n${note.content}');
        expect(
          DiaryBookDocument.fromNotes([note]).pages.single.layout,
          page.layout,
        );
      }
    }
  });

  test('零到九图的自适应分页保留全文，文字栏和照片互不遮挡', () {
    final candidates = <DiaryPageLayout>{};
    for (var count = 0; count <= 9; count++) {
      for (var seed = 0; seed < 10; seed++) {
        final note = _note(
          id: 'layout-$seed',
          content: '每一段日常都值得被认真收藏。👨‍👩‍👧‍👦\n' * 35,
          images: List.generate(count, (index) => 'photo-$index'),
        );
        final document = DiaryBookDocument.fromNotes([note]);
        candidates.addAll(DiaryPageLayout.candidatesForImageCount(count));
        expect(
          document.pages.map((page) => page.text).join(),
          '${note.title}\n\n${note.content}',
        );
        for (final page in document.pages) {
          expect(
            DiaryPageLayout.candidatesForImageCount(page.images.length),
            contains(page.layout),
          );
          expect(page.images, hasLength(page.layout.imageRects.length));
          final pageRect = Offset.zero & kDiaryPageSize;
          for (final rect in [
            ...page.layout.textRects,
            ...page.layout.imageRects,
          ]) {
            expect(pageRect.intersect(rect), rect);
          }
          final images = page.layout.imageRects;
          for (var i = 0; i < images.length; i++) {
            for (var j = i + 1; j < images.length; j++) {
              expect(images[i].overlaps(images[j]), isFalse);
            }
          }
          for (final frame in page.frames) {
            for (final image in page.layout.imageRects) {
              expect(frame.rect.overlaps(image), isFalse);
            }
            final painter = TextPainter(
              text: frame.span,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: frame.rect.width);
            expect(painter.height, lessThanOrEqualTo(frame.rect.height));
            painter.dispose();
          }
        }
      }
    }
    expect(candidates, DiaryPageLayout.values.toSet());
  });

  test('同一篇日记根据照片横竖比例选择网格，原图比例完整保留', () {
    final note = _note(images: ['photo'], title: '散步', content: '记下今天。');
    DiaryBookPage page(double ratio) => DiaryBookDocument.fromNotes(
      [note],
      imageAspectRatios: {'photo': ratio},
    ).pages.first;
    final landscape = page(3);
    final portrait = page(0.4);
    expect(landscape.layout, isNot(portrait.layout));
    expect(
      landscape.layout.imageRects.single.width /
          landscape.layout.imageRects.single.height,
      greaterThan(1),
    );
    expect(
      portrait.layout.imageRects.single.width /
          portrait.layout.imageRects.single.height,
      lessThan(1),
    );
    for (final ratio in [3.0, 0.4, 1.0, 8.0, 0.1]) {
      final rect = page(ratio).imageRects.single;
      expect(rect.width / rect.height, closeTo(ratio, 0.000001));
    }
  });

  test('六张横图与六张竖图选择不同拼版，混合比例不会重排照片', () {
    final photos = List.generate(6, (i) => 'photo-$i');
    final note = _note(images: photos, title: '旅行', content: '沿途风景。');
    DiaryBookPage page(double ratio) => DiaryBookDocument.fromNotes(
      [note],
      imageAspectRatios: {for (final path in photos) path: ratio},
    ).pages.first;
    final portrait = page(0.6);
    final landscape = page(2);
    expect(portrait.layout, isNot(landscape.layout));
    double averageRatio(DiaryBookPage page) =>
        page.layout.imageRects
            .map((rect) => rect.width / rect.height)
            .reduce((a, b) => a + b) /
        page.images.length;
    expect(averageRatio(portrait), lessThan(averageRatio(landscape)));
    final ratios = {
      for (var i = 0; i < photos.length; i++) photos[i]: i.isEven ? 0.4 : 3.0,
    };
    final mixed = DiaryBookDocument.fromNotes([
      note,
    ], imageAspectRatios: ratios).pages.first;
    expect(mixed.images, photos);
    for (var i = 0; i < photos.length; i++) {
      final rect = mixed.imageRects[i];
      expect(rect.width / rect.height, closeTo(ratios[photos[i]]!, 0.000001));
    }
  });

  test('正文长度参与选版，重排后阅读锚点落在包含原位置的纸页', () {
    final short = _note(id: 'adaptive-length');
    final long = _note(id: short.id, content: '沿着海岸慢慢走，把微小的心情收藏起来。\n' * 100);
    final compact = DiaryBookDocument.fromNotes([short]);
    final expanded = DiaryBookDocument.fromNotes([long]);
    expect(compact.pages.first.layout, isNot(expanded.pages.first.layout));
    final photoNote = _note(images: ['photo'], content: long.content);
    final before = DiaryBookDocument.fromNotes(
      [photoNote],
      imageAspectRatios: {'photo': 0.4},
    );
    final after = DiaryBookDocument.fromNotes(
      [photoNote],
      imageAspectRatios: {'photo': 3},
    );
    final anchor = before.pages[1];
    final index = after.indexForAnchor(anchor);
    final page = after.pages[index];
    expect(page.note.id, anchor.note.id);
    expect(page.textOffset, lessThanOrEqualTo(anchor.textOffset));
    expect(page.textOffset + page.text.length, greaterThan(anchor.textOffset));
  });

  test('无效或未知照片比例仍生成有限的安全栏位', () {
    final photos = ['a', 'b', 'c', 'd'];
    final page = DiaryBookDocument.fromNotes(
      [_note(images: photos)],
      imageAspectRatios: {
        'a': double.nan,
        'b': double.infinity,
        'c': -1,
        'd': 0,
      },
    ).pages.first;
    for (final rect in page.imageRects) {
      expect(rect.isFinite, isTrue);
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
    }
  });

  test('相同横图短文在不同日记间实际选出多种构图，同篇重开保持稳定', () {
    final layouts = <DiaryPageLayout>{};
    final compositions = <String>{};
    for (var id = 0; id < 80; id++) {
      final note = _note(
        id: 'short-$id',
        title: '',
        content: '醒得很晚，\n手机上没有任何消息。',
        images: ['photo'],
      );
      DiaryBookPage build() => DiaryBookDocument.fromNotes(
        [note],
        imageAspectRatios: {'photo': 1.4},
      ).pages.single;
      final first = build();
      expect(build().layout, first.layout);
      expect(first.text, note.content);
      layouts.add(first.layout);
      compositions.add(first.layout.composition);
    }
    expect(
      layouts,
      containsAll([
        DiaryPageLayout.quietBottomLeft,
        DiaryPageLayout.quietBottomRight,
        DiaryPageLayout.quietFloatingPhoto,
        DiaryPageLayout.quietPhotoTop,
      ]),
    );
    expect(compositions.length, greaterThanOrEqualTo(2));
  });

  test('参考图构图明确把短文与沉底照片分开，全部候选网格无图文遮挡', () {
    const left = DiaryPageLayout.quietBottomLeft;
    expect(
      left.textRects.single.left,
      greaterThan(left.imageRects.single.left),
    );
    expect(left.textRects.single.bottom, lessThan(left.imageRects.single.top));
    const right = DiaryPageLayout.quietBottomRight;
    expect(right.textRects.single.left, lessThan(right.imageRects.single.left));
    expect(
      right.textRects.single.bottom,
      lessThan(right.imageRects.single.top),
    );
    final bounds = Offset.zero & kDiaryPageSize;
    for (final layout in DiaryPageLayout.values) {
      final images = layout.imageRects;
      for (final rect in [...layout.textRects, ...images]) {
        expect(bounds.intersect(rect), rect, reason: layout.name);
        expect(rect.width, greaterThan(0));
        expect(rect.height, greaterThan(0));
      }
      for (var i = 0; i < images.length; i++) {
        for (var j = i + 1; j < images.length; j++) {
          expect(images[i].overlaps(images[j]), isFalse, reason: layout.name);
        }
        for (final text in layout.textRects) {
          expect(images[i].overlaps(text), isFalse, reason: layout.name);
        }
      }
    }
  });

  test('多图短文能够使用图片围绕文字和整组沉底的不同构图', () {
    final seen = <String>{};
    for (var count = 2; count <= 9; count++) {
      for (final ratio in [0.7, 1.5, 2.0]) {
        for (var id = 0; id < 12; id++) {
          final photos = List.generate(count, (i) => 'photo-$i');
          final note = _note(
            id: 'gallery-$id',
            title: '',
            content: '记下这一刻。',
            images: photos,
          );
          final document = DiaryBookDocument.fromNotes(
            [note],
            imageAspectRatios: {for (final path in photos) path: ratio},
          );
          expect(document.pages, hasLength(1));
          final page = document.pages.single;
          expect(page.images, photos);
          if (page.layout.isQuiet) seen.add(page.layout.composition);
        }
      }
    }
    expect(
      seen,
      containsAll([
        'lower-gallery',
        'surround-note',
        'diagonal-gallery',
        'split-gallery',
      ]),
    );
  });

  test('三张竖图的短文也实际覆盖围合、沉底和交错构图', () {
    final seen = <DiaryPageLayout>{};
    const photos = ['one', 'two', 'three'];
    for (var id = 0; id < 60; id++) {
      final note = _note(
        id: 'portrait-trio-$id',
        title: '',
        content: '风从窗边吹过，\n今天想把脚步放慢一点。',
        images: photos,
      );
      final page = DiaryBookDocument.fromNotes(
        [note],
        imageAspectRatios: {for (final path in photos) path: 0.7},
      ).pages.single;
      seen.add(page.layout);
    }
    expect(
      seen,
      containsAll([
        DiaryPageLayout.quietOrbit,
        DiaryPageLayout.quietTriptychBottom,
        DiaryPageLayout.quietSideTriptych,
      ]),
    );
  });

  test('按空间适配的长文实际选出分栏、图文穿插和错位构图', () {
    final compositions = <String>{};
    final layouts = <DiaryPageLayout>{};
    for (final count in [0, 1, 4, 9]) {
      for (var id = 0; id < 24; id++) {
        final photos = List.generate(count, (i) => 'photo-$i');
        final note = _note(
          id: 'long-composition-$id',
          content: '沿河走了很久，傍晚的光落在水面上。\n' * 25,
          images: photos,
        );
        final document = DiaryBookDocument.fromNotes(
          [note],
          imageAspectRatios: {for (final path in photos) path: 1.2},
        );
        expect(document.pages.length, greaterThan(1));
        expect(
          document.pages.map((p) => p.text).join(),
          '${note.title}\n\n${note.content}',
        );
        expect(document.pages.expand((p) => p.images), photos);
        final repeated = DiaryBookDocument.fromNotes(
          [note],
          imageAspectRatios: {for (final path in photos) path: 1.2},
        );
        expect(
          repeated.pages.map((p) => (p.layout, p.text, p.images.join(','))),
          document.pages.map((p) => (p.layout, p.text, p.images.join(','))),
        );
        for (final page in document.pages) {
          compositions.add(page.layout.composition);
          layouts.add(page.layout);
        }
      }
    }
    expect(
      compositions,
      containsAll(['prose-columns', 'prose-interleaved', 'prose-staggered']),
    );
    expect(layouts.length, greaterThanOrEqualTo(10));
  });

  test('九图长文把图片与正文分配到多页，保留顺序、原图比例和阅读位置', () {
    final photos = List.generate(9, (i) => 'photo-$i');
    final note = _note(
      images: photos,
      content: '早上出门的时候，天空还没有完全亮起来。\n\n' * 35,
    );
    DiaryBookDocument build(TextScaler scaler) => DiaryBookDocument.fromNotes(
      [note],
      textScaler: scaler,
      imageAspectRatios: {
        for (var i = 0; i < photos.length; i++)
          photos[i]: i.isEven ? 0.55 : 2.4,
      },
    );
    final normal = build(TextScaler.noScaling);
    for (final scale in [1.0, 1.8, 2.5]) {
      final scaler = TextScaler.linear(scale);
      final document = build(scaler);
      final illustrated = document.pages.where((p) => p.images.isNotEmpty);
      expect(illustrated.length, greaterThanOrEqualTo(1));
      expect(document.pages.expand((p) => p.images), photos);
      expect(
        document.pages.map((p) => p.text).join(),
        '${note.title}\n\n${note.content}',
      );
      for (final page in document.pages) {
        for (var i = 0; i < page.images.length; i++) {
          final rect = page.imageRects[i];
          final ratio = photos.indexOf(page.images[i]).isEven ? 0.55 : 2.4;
          expect(rect.width / rect.height, closeTo(ratio, 0.000001));
          expect(page.layout.imageRects[i].intersect(rect), rect);
        }
        for (final frame in page.frames) {
          final painter = TextPainter(
            text: frame.span,
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: frame.rect.width);
          expect(painter.height, lessThanOrEqualTo(frame.rect.height));
          painter.dispose();
        }
      }
      final anchor = normal.pages[1];
      final anchored = document.pages[document.indexForAnchor(anchor)];
      expect(anchored.textOffset, lessThanOrEqualTo(anchor.textOffset));
      expect(
        anchored.textOffset + anchored.text.length,
        greaterThan(anchor.textOffset),
      );
    }
  });

  test('九图中篇不再固定拆三页，新的日记始终另起一页', () {
    final photos = List.generate(9, (i) => 'photo-$i');
    final first = _note(title: '', content: '记下一路风景。' * 30, images: photos);
    final second = _note(id: 'next', content: '新的开始。');
    final document = DiaryBookDocument.fromNotes([first, second]);
    final firstPages = document.pages.where((p) => p.note.id == first.id);
    expect(firstPages.length, lessThanOrEqualTo(2));
    expect(firstPages.expand((p) => p.images), photos);
    expect(firstPages.map((p) => p.text).join(), first.content);
    expect(document.pages.last.note.id, second.id);
    expect(document.pages.last.part, 0);
  });

  test('容量估算接近两页边界时复核尾页，不留下只有几字的第三页', () {
    const paragraph = '沿着河边慢慢走，光线穿过树叶落在地上。坐下来喝一杯咖啡，记下今天细小的心情。\n\n';
    final photos = List.generate(9, (i) => 'photo-$i');
    for (final id in [19, 39]) {
      final note = _note(
        id: 'performance-$id',
        title: '',
        content: paragraph * 5,
        images: photos,
      );
      final document = DiaryBookDocument.fromNotes(
        [note],
        imageAspectRatios: {
          for (var i = 0; i < photos.length; i++)
            photos[i]: i.isEven ? 0.7 : 1.5,
        },
      );
      expect(document.pages.length, lessThanOrEqualTo(2));
      expect(document.pages.map((p) => p.text).join(), note.content);
      expect(document.pages.expand((p) => p.images), photos);
    }
  });

  test('英文长文栏末保持完整单词，换行与组合字素不丢失', () {
    final note = _note(
      title: 'A quiet afternoon',
      content:
          'Walking along the river, we collected small memories. '
              'Sunlight on the water 👨‍👩‍👧‍👦 é.\n\n' *
          45,
      images: ['one', 'two', 'three'],
    );
    final pages = DiaryBookDocument.fromNotes([note]).pages;
    expect(pages.map((p) => p.text).join(), '${note.title}\n\n${note.content}');
    final frames = pages
        .expand((p) => p.frames)
        .where((f) => f.text.isNotEmpty);
    final word = RegExp('[a-zA-Z]');
    final texts = frames.map((f) => f.text).toList();
    for (var i = 1; i < texts.length; i++) {
      expect(
        word.hasMatch(texts[i - 1].characters.last) &&
            word.hasMatch(texts[i].characters.first),
        isFalse,
      );
    }
  });
}
