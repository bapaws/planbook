import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/focus/bloc/discover_focus_bloc.dart';
import 'package:flutter_planbook/discover/focus/model/note_mind_map_entity.dart';
import 'package:jiffy/jiffy.dart';
import 'package:planbook_api/planbook_api.dart';
import 'package:planbook_core/data/page_status.dart';

@RoutePage()
class DiscoverFocusPage extends StatelessWidget {
  const DiscoverFocusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DiscoverFocusBloc(notesRepository: context.read())
            ..add(DiscoverFocusRequested(date: Jiffy.now())),
      child: BlocListener<DiscoverFocusBloc, DiscoverFocusState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == PageStatus.loading) {
            EasyLoading.show(maskType: EasyLoadingMaskType.clear);
          } else if (EasyLoading.isShow) {
            EasyLoading.dismiss();
          }
        },
        child: const _DiscoverFocusPage(),
      ),
    );
  }
}

class _DiscoverFocusPage extends StatelessWidget {
  const _DiscoverFocusPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoverFocusBloc, DiscoverFocusState>(
      builder: (context, state) {
        if (state.mindMap == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return InteractiveViewer(
              constrained: false,
              minScale: 0.1,
              maxScale: 5,
              boundaryMargin: EdgeInsets.all(
                constraints.biggest.longestSide,
              ),
              child: MindMapView(mindMap: state.mindMap!),
            );
          },
        );
      },
    );
  }
}

/// 思维导图视图 - 放射状圆形布局
class MindMapView extends StatelessWidget {
  const MindMapView({
    required this.mindMap,
    super.key,
  });

  final NoteMindMapEntity mindMap;

  @override
  Widget build(BuildContext context) {
    return _RadialMindMap(node: mindMap);
  }
}

/// 放射状思维导图 - 同心圆布局
class _RadialMindMap extends StatelessWidget {
  const _RadialMindMap({required this.node});

  final NoteMindMapEntity node;

  // 最大显示深度（0=年，1=月，2=周，3=天）
  static const int _maxDepth = 3;

  // 各层级到中心的半径（累加值）
  static const List<double> _cumulativeRadii = [0, 180, 320, 420, 500];
  // 各层级节点大小
  static const List<double> _nodeSizes = [90, 50, 36, 24];

  @override
  Widget build(BuildContext context) {
    // 计算整个画布大小
    final maxRadius = _cumulativeRadii[_maxDepth] + _nodeSizes[_maxDepth] / 2;
    final canvasSize = maxRadius * 2 + 100;
    final center = Offset(canvasSize / 2, canvasSize / 2);
    final daysInYear = _getDaysInYear(node.date.year);

    return SizedBox(
      width: canvasSize,
      height: canvasSize,
      child: Stack(
        children: [
          // 绘制连接线
          Positioned.fill(
            child: CustomPaint(
              painter: _RadialLinePainter(
                node: node,
                center: center,
                cumulativeRadii: _cumulativeRadii,
                nodeSizes: _nodeSizes,
                maxDepth: _maxDepth,
                daysInYear: daysInYear,
              ),
            ),
          ),
          // 递归绘制所有节点（所有节点都以中心为基准）
          ..._buildAllNodes(context, node, center, daysInYear),
        ],
      ),
    );
  }

  /// 递归构建所有节点（同心圆布局，所有节点基于中心定位）
  List<Widget> _buildAllNodes(
    BuildContext context,
    NoteMindMapEntity node,
    Offset center,
    int daysInYear, [
    int level = 0,
  ]) {
    // 超过最大深度则不渲染
    if (level > _maxDepth) return [];

    final widgets = <Widget>[];
    final nodeSize = _nodeSizes[level.clamp(0, _nodeSizes.length - 1)];
    final radius =
        _cumulativeRadii[level.clamp(0, _cumulativeRadii.length - 1)];

    // 计算当前节点的位置
    Offset nodePosition;
    if (level == 0) {
      // 年节点在中心
      nodePosition = center;
    } else {
      // 其他节点基于时间比例计算角度，从中心向外
      final angleInfo = _calculateAngle(node, daysInYear);
      final angle = angleInfo.centerAngle;
      nodePosition = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    }

    // 添加当前节点
    widgets.add(
      Positioned(
        left: nodePosition.dx - nodeSize / 2,
        top: nodePosition.dy - nodeSize / 2,
        child: _CircleNode(
          node: node,
          size: nodeSize,
          level: level,
        ),
      ),
    );

    // 递归添加子节点
    if (node.children.isNotEmpty && level < _maxDepth) {
      for (final child in node.children) {
        widgets.addAll(
          _buildAllNodes(context, child, center, daysInYear, level + 1),
        );
      }
    }

    return widgets;
  }
}

/// 角度信息
class _AngleInfo {
  const _AngleInfo({
    required this.startAngle,
    required this.sweepAngle,
  });

  final double startAngle;
  final double sweepAngle;

  double get centerAngle => startAngle + sweepAngle / 2;
}

/// 获取某年的天数（闰年366天，平年365天）
int _getDaysInYear(int year) {
  final isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  return isLeapYear ? 366 : 365;
}

/// 基于时间比例计算节点角度
/// 一年360度，一天约 360/365 度
_AngleInfo _calculateAngle(NoteMindMapEntity node, int daysInYear) {
  final date = node.date;
  final type = node.type;

  // 基准：从顶部开始（-π/2），顺时针方向
  const baseAngle = -math.pi / 2;
  final radiansPerDay = 2 * math.pi / daysInYear;

  switch (type) {
    case NoteType.monthlyFocus || NoteType.monthlySummary:
      // 月份：该月第一天到最后一天
      final startOfMonth = date.startOf(Unit.month);
      final dayOfYear = startOfMonth.dayOfYear - 1; // 0-indexed
      final daysInMonth = date.daysInMonth;
      return _AngleInfo(
        startAngle: baseAngle + dayOfYear * radiansPerDay,
        sweepAngle: daysInMonth * radiansPerDay,
      );

    case NoteType.weeklyFocus || NoteType.weeklySummary:
      // 周：7天
      final startOfWeek = date.startOf(Unit.week);
      final dayOfYear = startOfWeek.dayOfYear - 1;
      return _AngleInfo(
        startAngle: baseAngle + dayOfYear * radiansPerDay,
        sweepAngle: 7 * radiansPerDay,
      );

    case NoteType.dailyFocus || NoteType.dailySummary:
      // 天：1天
      final dayOfYear = date.dayOfYear - 1;
      return _AngleInfo(
        startAngle: baseAngle + dayOfYear * radiansPerDay,
        sweepAngle: radiansPerDay,
      );

    default:
      // 年或其他：整圆
      return const _AngleInfo(
        startAngle: baseAngle,
        sweepAngle: 2 * math.pi,
      );
  }
}

/// 圆形节点
class _CircleNode extends StatelessWidget {
  const _CircleNode({
    required this.node,
    required this.size,
    required this.level,
  });

  final NoteMindMapEntity node;
  final double size;
  final int level;

  bool get isRoot => level == 0;

  @override
  Widget build(BuildContext context) {
    final color = _getNodeColor(node.type);
    final textTheme = Theme.of(context).textTheme;
    final hasNote = node.note != null;
    final hasChildren = node.children.isNotEmpty;

    // 根据层级调整字体大小
    final fontSize = switch (level) {
      0 => 14.0,
      1 => 11.0,
      2 => 9.0,
      _ => 8.0,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            color.withValues(alpha: hasNote ? 1.0 : 0.5),
            color.withValues(alpha: hasNote ? 0.75 : 0.25),
          ],
        ),
        border: Border.all(
          color: hasNote
              ? Colors.white.withValues(alpha: 0.9)
              : color.withValues(alpha: 0.6),
          width: hasNote ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: hasNote ? 0.5 : 0.15),
            blurRadius: hasNote ? 12 : 4,
            spreadRadius: hasNote ? 1 : 0,
          ),
        ],
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.all(size * 0.1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 日期标签
                Text(
                  _getDateLabel(node),
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: hasNote ? Colors.white : color,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                    height: 1.1,
                  ),
                ),
                // 类型标签（仅根节点显示）
                if (isRoot) ...[
                  const SizedBox(height: 2),
                  Text(
                    _getTypeLabel(node.type),
                    style: textTheme.labelSmall?.copyWith(
                      color: (hasNote ? Colors.white : color).withValues(
                        alpha: 0.8,
                      ),
                      fontSize: 9,
                    ),
                  ),
                ],
                // 子节点数量提示（当有未展示的子节点时）
                if (hasChildren && level >= _RadialMindMap._maxDepth) ...[
                  Text(
                    '+${node.children.length}',
                    style: textTheme.labelSmall?.copyWith(
                      color: (hasNote ? Colors.white : color).withValues(
                        alpha: 0.7,
                      ),
                      fontSize: 8,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 放射状连接线绘制器 - 同心圆布局
class _RadialLinePainter extends CustomPainter {
  const _RadialLinePainter({
    required this.node,
    required this.center,
    required this.cumulativeRadii,
    required this.nodeSizes,
    required this.maxDepth,
    required this.daysInYear,
  });

  final NoteMindMapEntity node;
  final Offset center;
  final List<double> cumulativeRadii;
  final List<double> nodeSizes;
  final int maxDepth;
  final int daysInYear;

  @override
  void paint(Canvas canvas, Size size) {
    _drawAllConnections(canvas, node, 0);
  }

  void _drawAllConnections(
    Canvas canvas,
    NoteMindMapEntity node,
    int level,
  ) {
    // 超过最大深度则不绘制
    if (node.children.isEmpty || level >= maxDepth) return;

    final parentRadius =
        cumulativeRadii[level.clamp(0, cumulativeRadii.length - 1)];
    final childRadius =
        cumulativeRadii[(level + 1).clamp(0, cumulativeRadii.length - 1)];
    final parentNodeSize = nodeSizes[level.clamp(0, nodeSizes.length - 1)];
    final childNodeSize = nodeSizes[(level + 1).clamp(0, nodeSizes.length - 1)];

    for (final child in node.children) {
      // 基于时间比例计算角度
      final angleInfo = _calculateAngle(child, daysInYear);
      final childAngle = angleInfo.centerAngle;

      // 父节点位置（基于中心）
      Offset parentPos;
      if (level == 0) {
        parentPos = center;
      } else {
        final parentAngleInfo = _calculateAngle(node, daysInYear);
        parentPos = Offset(
          center.dx + parentRadius * math.cos(parentAngleInfo.centerAngle),
          center.dy + parentRadius * math.sin(parentAngleInfo.centerAngle),
        );
      }

      // 子节点位置（基于中心）
      final childPos = Offset(
        center.dx + childRadius * math.cos(childAngle),
        center.dy + childRadius * math.sin(childAngle),
      );

      // 计算连线方向（从父节点指向子节点）
      final dx = childPos.dx - parentPos.dx;
      final dy = childPos.dy - parentPos.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      if (distance < 0.01) continue; // 防止除零

      final dirX = dx / distance;
      final dirY = dy / distance;

      // 绘制从父节点边缘到子节点边缘的连接线
      final parentEdge = Offset(
        parentPos.dx + (parentNodeSize / 2) * dirX,
        parentPos.dy + (parentNodeSize / 2) * dirY,
      );
      final childEdge = Offset(
        childPos.dx - (childNodeSize / 2) * dirX,
        childPos.dy - (childNodeSize / 2) * dirY,
      );

      // 绘制直线连接
      final color = _getNodeColor(child.type);
      final hasNote = child.note != null;

      final paint = Paint()
        ..color = color.withValues(alpha: hasNote ? 0.6 : 0.2)
        ..strokeWidth = hasNote ? 1.5 : 0.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(parentEdge, childEdge, paint);

      // 递归绘制子节点的连接线
      _drawAllConnections(canvas, child, level + 1);
    }
  }

  @override
  bool shouldRepaint(covariant _RadialLinePainter oldDelegate) {
    return oldDelegate.node != node;
  }
}

/// 根据类型获取颜色
Color _getNodeColor(NoteType type) {
  return switch (type) {
    NoteType.yearlyFocus || NoteType.yearlySummary => const Color(0xFFE91E63),
    NoteType.monthlyFocus || NoteType.monthlySummary => const Color(0xFF9C27B0),
    NoteType.weeklyFocus || NoteType.weeklySummary => const Color(0xFF2196F3),
    NoteType.dailyFocus || NoteType.dailySummary => const Color(0xFF4CAF50),
    _ => const Color(0xFF607D8B),
  };
}

/// 获取类型标签
String _getTypeLabel(NoteType type) {
  return switch (type) {
    NoteType.yearlyFocus => '年度重点',
    NoteType.yearlySummary => '年度总结',
    NoteType.monthlyFocus => '月度重点',
    NoteType.monthlySummary => '月度总结',
    NoteType.weeklyFocus => '周重点',
    NoteType.weeklySummary => '周总结',
    NoteType.dailyFocus => '日重点',
    NoteType.dailySummary => '日总结',
    _ => '笔记',
  };
}

/// 获取日期标签
String _getDateLabel(NoteMindMapEntity node) {
  final date = node.date;
  return switch (node.type) {
    NoteType.yearlyFocus ||
    NoteType.yearlySummary => date.format(pattern: 'yyyy'),
    NoteType.monthlyFocus ||
    NoteType.monthlySummary => date.format(pattern: 'yyyy-MM'),
    NoteType.weeklyFocus || NoteType.weeklySummary => 'W${date.weekOfYear}',
    NoteType.dailyFocus ||
    NoteType.dailySummary => date.format(pattern: 'MM-dd'),
    _ => date.format(pattern: 'yyyy-MM-dd'),
  };
}
