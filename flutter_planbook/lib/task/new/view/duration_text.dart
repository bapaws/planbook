import 'package:flutter/material.dart';
import 'package:flutter_planbook/l10n/l10n.dart';

enum DurationTextMode {
  short,
  full,
}

class DurationText extends StatelessWidget {
  const DurationText({
    required this.duration,
    this.style,
    this.mode = DurationTextMode.short,
    this.separator = '',
    super.key,
  });

  final Duration duration;
  final TextStyle? style;
  final DurationTextMode mode;
  final String separator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Text(
      _formatDuration(duration, l10n),
      style:
          style ??
          theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
    );
  }

  String _formatDuration(Duration duration, AppLocalizations l10n) {
    final totalSeconds = duration.inSeconds;

    if (totalSeconds == 0) {
      return l10n.durationSeconds(0);
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final parts = <String>[];

    if (hours > 0) {
      parts.add(
        mode == DurationTextMode.full ? l10n.durationHours(hours) : '${hours}h',
      );
    }
    if (minutes > 0) {
      parts.add(
        mode == DurationTextMode.full
            ? l10n.durationMinutes(minutes)
            : '${minutes}m',
      );
    }
    // 只有在没有小时的情况下才显示秒
    if (seconds > 0 && hours == 0) {
      parts.add(
        mode == DurationTextMode.full
            ? l10n.durationSeconds(seconds)
            : '${seconds}s',
      );
    }

    return parts.join(separator);
  }
}
