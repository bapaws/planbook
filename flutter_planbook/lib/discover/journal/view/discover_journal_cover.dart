import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/discover/cover/repository/discover_cover_repository.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';

class JournalCover extends StatelessWidget {
  const JournalCover({
    required this.year,
    this.backgroundImage,
    this.colorScheme,
    super.key,
  });

  final int year;

  /// 封皮底图资源路径（如 `assets/images/paper.jpg`）；为 `null` 或空字符串时仅纯色。
  final String? backgroundImage;

  final ColorScheme? colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = colorScheme ?? Theme.of(context).colorScheme;

    return _JournalNotebookShell(
      isFront: true,
      backgroundImage: backgroundImage,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'PLANBOOK',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: <Widget>[
                        // Stroked text as border.
                        Text(
                          '$year',
                          style: TextStyle(
                            fontSize: 81,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 8
                              ..color = cs.primary,
                          ),
                        ),
                        // Solid text as fill.
                        Text(
                          '$year',
                          style: TextStyle(
                            fontSize: 81,
                            color: cs.primaryContainer,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                    // Text(
                    //   '$year',
                    //   style: TextStyle(
                    //     fontSize: 81,
                    //     color: cs.primary,
                    //     fontWeight: FontWeight.bold,
                    //     letterSpacing: 4,
                    //   ),
                    // ),
                    // const SizedBox(height: 10),
                    Container(
                      width: kDiscoverJournalDailyPageWidth / 8,
                      height: 4,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'DAILY NOTES',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class JournalBackCover extends StatelessWidget {
  const JournalBackCover({
    required this.year,
    this.backgroundImage,
    this.colorScheme,
    super.key,
  });

  final int year;

  /// 与 [JournalCover.backgroundImage] 一致；封底与封面共用同一套底图逻辑。
  final String? backgroundImage;

  final ColorScheme? colorScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = colorScheme ?? Theme.of(context).colorScheme;
    return _JournalNotebookShell(
      isFront: false,
      backgroundImage: backgroundImage,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'JOURNAL ARCHIVE',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$year',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JournalNotebookShell extends StatelessWidget {
  const _JournalNotebookShell({
    required this.isFront,
    required this.child,
    this.backgroundImage,
  });

  final bool isFront;

  /// 非空且非空字符串时，在 [ColorScheme.primaryContainer] 上叠 `BoxFit.cover` 资源图。
  final String? backgroundImage;

  final Widget child;

  bool get _useBackgroundImage =>
      backgroundImage != null && backgroundImage!.isNotEmpty;

  BorderRadius get _borderRadius => BorderRadius.horizontal(
    left: Radius.circular(isFront ? 0 : 24),
    right: Radius.circular(isFront ? 24 : 0),
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coverColor = cs.primaryContainer;
    const w = kDiscoverJournalDailyPageWidth;
    const h = kDiscoverJournalDailyPageHeight;

    return SizedBox(
      width: w,
      height: h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _borderRadius,
          color: coverColor,
          image: _useBackgroundImage
              ? DecorationImage(
                  image: context
                      .read<DiscoverCoverRepository>()
                      .imageProviderFor(backgroundImage!),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: _borderRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.55),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: isFront ? 0 : null,
                  right: isFront ? null : 0,
                  width: 8,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isFront ? 44 : 30,
                      18,
                      isFront ? 30 : 44,
                      18,
                    ),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
