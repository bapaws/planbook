/// 仅供可放弃的首屏预加载使用；普通业务查询不传入此预算。
class TaskPreparationBudget {
  TaskPreparationBudget({
    required bool Function() isCurrent,
    required Duration Function() elapsed,
    this.maxDuration = const Duration(milliseconds: 600),
  }) : _isCurrent = isCurrent,
       _elapsed = elapsed;

  static const maxRows = 256;
  static const maxLinks = 256;
  static const maxTags = 256;
  static const maxParentDepth = 24;
  static const maxEntities = 512;
  static const int maxTextUnits = 128 * 1024;
  static const batchSize = 32;

  final bool Function() _isCurrent;
  final Duration Function() _elapsed;
  final Duration maxDuration;
  int _links = 0;
  int _tags = 0;
  int _entities = 0;
  int _textUnits = 0;

  int get remainingLinks => maxLinks - _links;

  void check() {
    if (!_isCurrent() || _elapsed() >= maxDuration) {
      throw const TaskPreparationAborted(interrupted: true);
    }
  }

  Future<void> yieldAndCheck() async {
    check();
    await Future<void>.delayed(Duration.zero);
    check();
  }

  void addText(String? value) {
    _textUnits += value?.length ?? 0;
    _limit(_textUnits > maxTextUnits);
  }

  void addLinks(int count) {
    check();
    _links += count;
    _limit(_links > maxLinks);
  }

  void addTags(int count) {
    check();
    _tags += count;
    _limit(_tags > maxTags);
  }

  void checkDepth(int depth) {
    check();
    _limit(depth > maxParentDepth);
  }

  void addEntity() {
    check();
    _entities++;
    _limit(_entities > maxEntities);
  }

  void _limit(bool exceeded) {
    if (exceeded) throw const TaskPreparationAborted(interrupted: false);
  }
}

/// 超限丢弃整组，取消或超时则停止本次准备；不对业务查询返回部分结果。
class TaskPreparationAborted implements Exception {
  const TaskPreparationAborted({required this.interrupted});

  final bool interrupted;
}
