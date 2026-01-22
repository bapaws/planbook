import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/discover/focus/bloc/discover_focus_bloc.dart';
import 'package:flutter_planbook/discover/focus/model/note_mind_map_entity.dart';
import 'package:flutter_planbook/root/discover/bloc/root_discover_bloc.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/database/note_type.dart';

class DiscoverMindMapPage<T extends DiscoverFocusBloc> extends StatefulWidget {
  const DiscoverMindMapPage({
    required this.mindMap,
    required this.isExpanded,
    super.key,
  });

  final NoteMindMapEntity mindMap;
  final bool isExpanded;

  @override
  State<DiscoverMindMapPage<T>> createState() => _DiscoverMindMapPageState<T>();
}

class _DiscoverMindMapPageState<T extends DiscoverFocusBloc>
    extends State<DiscoverMindMapPage<T>>
    with TickerProviderStateMixin {
  double _maxWidth = 0;
  double _maxHeight = 0;
  TransformationController? _controller;
  late AnimationController? _animationController;

  double get bottomPadding =>
      kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;
  double get scale => widget.isExpanded ? 1.0 : 0.8;

  StreamSubscription<RootDiscoverState>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Durations.medium1,
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    _animationController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.isExpanded
        ? kMonthlyMindMapExpandedRadius * 1.8 +
              kWeeklyMindMapExpandedRadius +
              kDailyMindMapExpandedRadius +
              kDailyNodeExpandedRadius
        : kDailyMindMapRadius + kDailyNodeRadius;
    final height = (radius + bottomPadding) * 2;
    final width = (radius + kDailyNodeRadius) * 2;
    final center = Offset(width / 2, height / 2);
    return LayoutBuilder(
      builder: (context, constraints) {
        _maxWidth = constraints.maxWidth;
        _maxHeight = constraints.maxHeight;
        _initController(center);

        return InteractiveViewer(
          constrained: false,
          minScale: 0.1,
          maxScale: 5,
          transformationController: _controller,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              // clipBehavior: Clip.none,
              children: [
                // 绘制连接线
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RadialLinePainter(
                      colorScheme: Theme.of(context).colorScheme,
                      center: center,
                      node: widget.mindMap,
                      isExpanded: widget.isExpanded,
                    ),
                  ),
                ),
                // 递归绘制所有节点（所有节点都以中心为基准）
                ..._buildAllNodes(context, center, widget.mindMap),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 递归构建所有节点（同心圆布局，所有节点基于中心定位）
  List<Widget> _buildAllNodes(
    BuildContext context,
    Offset center,
    NoteMindMapEntity node,
  ) {
    final widgets = <Widget>[];
    for (final child in node.children) {
      widgets.addAll(
        _buildAllNodes(context, center, child),
      );
    }
    final offset = node.getOffset(isExpanded: widget.isExpanded);
    final nodeCenter = center + offset;
    return widgets..add(
      AnimatedPositioned(
        key: ValueKey(node.key),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        left: nodeCenter.dx - node.size / 2,
        top: nodeCenter.dy - node.size / 2,
        child: _CircleNode(
          key: ValueKey(node.key),
          node: node,
          isExpanded: widget.isExpanded,
          onTap: (node) {
            if (node.isSelected) {
              switch (node.type) {
                case NoteType.yearlyFocus ||
                    NoteType.yearlySummary ||
                    NoteType.monthlyFocus ||
                    NoteType.monthlySummary:
                  _animateToNode(widget.mindMap, center);
                case NoteType.weeklyFocus || NoteType.weeklySummary:
                  final startOfMonth = node.date.startOf(Unit.month);
                  final monthlySelectedNode = widget.mindMap.children
                      .firstWhere(
                        (element) => element.date.isSame(
                          startOfMonth,
                          unit: Unit.month,
                        ),
                      );
                  _animateToNode(monthlySelectedNode, center);

                case NoteType.dailyFocus || NoteType.dailySummary:
                  final startOfWeek = node.date.startOf(Unit.week);
                  final startOfMonth = node.date.startOf(Unit.month);
                  final selectedNode = widget.mindMap.children.firstWhere(
                    (element) => element.date.isSame(
                      startOfMonth,
                      unit: Unit.month,
                    ),
                  );
                  final weeklySelectedNode = selectedNode.children.firstWhere(
                    (element) =>
                        element.date.isSame(startOfWeek, unit: Unit.week),
                  );
                  _animateToNode(weeklySelectedNode, center);

                case _:
                  break;
              }
            } else {
              _animateToNode(node.copyWith(isSelected: true), center);
            }
            context.read<T>().add(DiscoverFocusNodeSelected(node: node));
          },
        ),
      ),
    );
  }

  void _initController(Offset center) {
    if (_controller != null) return;
    _controller = TransformationController(
      Matrix4.identity()
        ..translateByDouble(
          _maxWidth / 2,
          _maxHeight / 2 - bottomPadding,
          0,
          1,
        )
        ..scaleByDouble(scale, scale, 1, 1)
        ..translateByDouble(-center.dx, -center.dy, 0, 1),
    );

    final bloc = context.read<RootDiscoverBloc>();
    _listenRootDiscoverBloc(bloc.state, center);
    _streamSubscription = bloc.stream.listen((state) {
      _listenRootDiscoverBloc(state, center);
    });
  }

  void _listenRootDiscoverBloc(
    RootDiscoverState state,
    Offset center,
  ) {
    // 根据 Bloc 的 isSummary 属性决定监听哪种状态变化
    final bloc = context.read<T>() as DiscoverFocusBloc;
    final isSummary = bloc.isSummary;

    if (!isSummary && state.focusDate != null && state.focusType != null) {
      _selectNode(state.focusDate!, state.focusType!, center);
      context.read<RootDiscoverBloc>().add(
        const RootDiscoverFocusDateChanged(
          date: null,
          type: null,
        ),
      );
    } else if (isSummary &&
        state.summaryDate != null &&
        state.summaryType != null) {
      _selectNode(state.summaryDate!, state.summaryType!, center);
      context.read<RootDiscoverBloc>().add(
        const RootDiscoverSummaryDateChanged(
          date: null,
          type: null,
        ),
      );
    }
  }

  Future<void> _selectNode(Jiffy date, NoteType noteType, Offset center) async {
    final yearlyNode = widget.mindMap;
    final bloc = context.read<T>();

    Future.delayed(Durations.medium4, () async {
      if (!yearlyNode.isSelected) {
        bloc.add(DiscoverFocusNodeSelected(node: yearlyNode));
      }
      await _animateToNode(yearlyNode, center);
      if (noteType.index >= NoteType.yearlyFocus.index) return;

      final monthlyNode = yearlyNode.children.firstWhere(
        (element) => element.date.isSame(date, unit: Unit.month),
      );
      Future.delayed(Durations.medium4, () async {
        if (!monthlyNode.isSelected) {
          bloc.add(DiscoverFocusNodeSelected(node: monthlyNode));
        }
        await _animateToNode(monthlyNode, center);
        if (noteType.index >= NoteType.monthlyFocus.index) return;

        final weeklyNode = monthlyNode.children.firstWhere(
          (element) => element.date.isSame(date, unit: Unit.week),
        );
        Future.delayed(Durations.medium4, () async {
          if (!weeklyNode.isSelected) {
            bloc.add(DiscoverFocusNodeSelected(node: weeklyNode));
          }
          await _animateToNode(weeklyNode, center);
          if (noteType.index >= NoteType.weeklyFocus.index) return;

          final dailyNode = weeklyNode.children.firstWhere(
            (element) => element.date.isSame(date, unit: Unit.day),
          );
          Future.delayed(Durations.medium4, () async {
            if (!dailyNode.isSelected) {
              bloc.add(DiscoverFocusNodeSelected(node: dailyNode));
            }
            await _animateToNode(dailyNode, center);
          });
        });
      });
    });
  }

  Future<void> _animateToNode(NoteMindMapEntity node, Offset center) async {
    if (_controller == null || _animationController == null) return;
    // 计算节点中心点，先触发点击事件，再修改选中状态
    final nodeCenter =
        center +
        (node.isSelected ? node.unselectedOffset : node.selectedOffset);
    final scale = switch (node.type) {
      NoteType.yearlyFocus ||
      NoteType.yearlySummary => node.isSelected ? 0.8 : 1.2,
      NoteType.monthlyFocus ||
      NoteType.monthlySummary => node.isSelected ? 1.0 : 0.9,
      NoteType.weeklyFocus ||
      NoteType.weeklySummary => node.isSelected ? 0.8 : 1.0,
      NoteType.dailyFocus ||
      NoteType.dailySummary => node.isSelected ? 2.0 : 0.8,
      _ => 1.0,
    };
    // 正确处理缩放和平移的组合变换
    // 变换顺序：translate(屏幕中心) * scale * translate(-节点中心)
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(
        _maxWidth / 2,
        _maxHeight / 2 - bottomPadding,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-nodeCenter.dx, -nodeCenter.dy, 0, 1);

    final animation =
        Matrix4Tween(
          begin: _controller!.value,
          end: targetMatrix,
        ).animate(
          CurvedAnimation(
            parent: _animationController!,
            curve: Curves.easeInOut,
          ),
        );

    animation.addListener(() {
      if (_controller != null) {
        _controller!.value = animation.value;
      }
    });

    await _animationController!.forward(from: 0);
  }
}

/// 圆形节点
class _CircleNode extends StatelessWidget {
  const _CircleNode({
    required this.node,
    required this.isExpanded,
    required this.onTap,
    super.key,
  });

  final NoteMindMapEntity node;
  final bool isExpanded;

  final ValueChanged<NoteMindMapEntity> onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = node.getColorScheme(context);
    final radius = isExpanded ? node.expandedSize : node.size;

    final contentIsNotEmpty =
        node.note?.content != null && node.note!.content!.isNotEmpty;
    final color = node.type.isYearly || node.type.isMonthly
        ? colorScheme.primaryContainer
        : node.type.isWeekly
        ? colorScheme.tertiaryContainer
        : colorScheme.secondaryContainer;
    return GestureDetector(
      onTap: () {
        onTap(node);
      },
      child: Container(
        width: radius,
        height: radius,
        padding: EdgeInsets.all((radius * 0.06).roundToDouble()),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular((radius / 6).roundToDouble()),
          boxShadow: node.isSelected
              ? [
                  BoxShadow(
                    color: color,
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: contentIsNotEmpty ? 0 : null,
              bottom: contentIsNotEmpty ? 0 : null,
              child: AnimatedDefaultTextStyle(
                duration: Durations.medium1,
                style: TextStyle(
                  color: contentIsNotEmpty
                      ? colorScheme.surfaceBright
                      : node.type.isYearly || node.type.isMonthly
                      ? colorScheme.primary
                      : node.type.isWeekly
                      ? colorScheme.tertiary
                      : colorScheme.secondary,
                  fontWeight: node.isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: contentIsNotEmpty
                      ? (radius * 0.1).roundToDouble()
                      : (radius * 0.2).roundToDouble(),
                  shadows: contentIsNotEmpty
                      ? [
                          Shadow(
                            color: colorScheme.outlineVariant,
                            blurRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  node.dateLabel,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (contentIsNotEmpty)
              Text(
                node.note!.content!,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: node.type.isYearly || node.type.isMonthly
                      ? colorScheme.onPrimaryContainer
                      : node.type.isWeekly
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onSecondaryContainer,
                  fontSize: (radius * 0.1).roundToDouble(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 放射状连接线绘制器 - 同心圆布局
class _RadialLinePainter extends CustomPainter {
  const _RadialLinePainter({
    required this.colorScheme,
    required this.center,
    required this.node,
    required this.isExpanded,
  });

  final NoteMindMapEntity node;
  final ColorScheme colorScheme;
  final Offset center;
  final bool isExpanded;

  @override
  void paint(Canvas canvas, Size size) {
    drawAllConnections(canvas, node, 0);
  }

  void drawAllConnections(
    Canvas canvas,
    NoteMindMapEntity node,
    int level,
  ) {
    // 超过最大深度则不绘制
    if (node.children.isEmpty) return;

    final parentOffset = node.getOffset(isExpanded: isExpanded) + center;
    for (final child in node.children) {
      // 子节点位置（基于中心）
      final childOffset = child.getOffset(isExpanded: isExpanded) + center;

      final paint = Paint()
        ..color = child.isSelected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest
        ..strokeWidth = child.isSelected ? 1.5 : 0.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(parentOffset, childOffset, paint);

      // 递归绘制子节点的连接线
      drawAllConnections(canvas, child, level + 1);
    }
  }

  @override
  bool shouldRepaint(_RadialLinePainter oldDelegate) {
    return oldDelegate.node != node;
  }
}
