import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 按 [interval] 依次轮播 [messages]，同一时刻只显示一条；单条或无数据时不启动定时器。
class SequentialRotatingText extends StatefulWidget {
  const SequentialRotatingText({
    required this.messages,
    required this.style,
    this.interval = const Duration(seconds: 5),
    super.key,
  });

  /// 按数组顺序循环播放的文案；建议传入不可变列表或由调用方保持稳定引用。
  final List<String> messages;
  final TextStyle? style;
  final Duration interval;

  @override
  State<SequentialRotatingText> createState() =>
      _SequentialRotatingTextState();
}

class _SequentialRotatingTextState extends State<SequentialRotatingText> {
  Timer? _timer;
  var _index = 0;

  void _restartTimer() {
    _timer?.cancel();
    if (widget.messages.length <= 1) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() {
        _index = (_index + 1) % widget.messages.length;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  @override
  void didUpdateWidget(covariant SequentialRotatingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final listChanged = !listEquals(widget.messages, oldWidget.messages);
    final intervalChanged = widget.interval != oldWidget.interval;
    if (listChanged || intervalChanged) {
      setState(() => _index = 0);
      _restartTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const SizedBox.shrink();
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(widget.messages.first, style: widget.style);
    }

    if (widget.messages.length == 1) {
      return Text(widget.messages.single, style: widget.style);
    }

    final text = widget.messages[_index];
    return AnimatedSwitcher(
      duration: Durations.medium2,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: Text(
        text,
        key: ValueKey<int>(_index),
        style: widget.style,
      ),
    );
  }
}
