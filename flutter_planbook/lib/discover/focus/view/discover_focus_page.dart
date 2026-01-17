import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/focus/bloc/discover_focus_bloc.dart';
import 'package:flutter_planbook/discover/focus/model/note_mind_map_entity.dart';
import 'package:flutter_planbook/note/type/model/note_type_x.dart';
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
        child: BlocBuilder<DiscoverFocusBloc, DiscoverFocusState>(
          builder: (context, state) => AnimatedSwitcher(
            duration: Durations.medium1,
            child: state.mindMap == null
                ? const SizedBox.shrink()
                : _DiscoverFocusPage(
                    mindMap: state.mindMap!,
                    isExpanded: state.isExpandedAllNodes,
                  ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverFocusPage extends StatefulWidget {
  const _DiscoverFocusPage({required this.mindMap, required this.isExpanded});

  final NoteMindMapEntity mindMap;
  final bool isExpanded;

  @override
  State<_DiscoverFocusPage> createState() => _DiscoverFocusPageState();
}

class _DiscoverFocusPageState extends State<_DiscoverFocusPage>
    with TickerProviderStateMixin {
  double _maxWidth = 0;
  double _maxHeight = 0;
  TransformationController? _controller;
  late AnimationController? _animationController;

  double get bottomPadding =>
      kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom;

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
        final scale = widget.isExpanded ? 1.0 : 0.8;
        _controller ??= TransformationController(
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
            if (_controller == null || _animationController == null) return;
            // 计算节点中心点，先触发点击事件，再修改选中状态
            final nodeCenter =
                center +
                (node.isSelected ? node.unselectedOffset : node.selectedOffset);
            final scale = node.scale;
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

            _animationController!.forward(from: 0);
          },
        ),
      ),
    );
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
    final color = node.type.getColorScheme(context);
    final textTheme = Theme.of(context).textTheme;

    final radius = isExpanded ? node.expandedSize : node.size;
    // 根据层级调整字体大小
    final fontSize = switch (node.type) {
      NoteType.yearlyFocus || NoteType.yearlySummary => 14.0,
      NoteType.monthlyFocus || NoteType.monthlySummary => 11.0,
      NoteType.weeklyFocus || NoteType.weeklySummary => 9.0,
      NoteType.dailyFocus || NoteType.dailySummary => 8.0,
      _ => 8.0,
    };

    return GestureDetector(
      onTap: () {
        onTap(node);
        if (node.type.isYearly) {
          context.read<DiscoverFocusBloc>().add(
            DiscoverFocusRequested(date: node.date),
          );
        } else {
          context.read<DiscoverFocusBloc>().add(
            DiscoverFocusNodeSelected(node: node),
          );
        }
      },
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          color: color.primaryContainer,
          shape: BoxShape.circle,
          // borderRadius: BorderRadius.circular(node.size / 4),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: EdgeInsets.all(radius * 0.1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日期标签
                  Text(
                    node.dateLabel,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: color.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: fontSize,
                      height: 1.1,
                    ),
                  ),
                  if (node.note?.content != null &&
                      node.note!.content!.isNotEmpty)
                    Text(
                      node.note!.content!,
                      // textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: color.onSurface,
                        fontSize: fontSize,
                      ),
                    ),
                ],
              ),
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
    required this.center,
    required this.node,
    required this.isExpanded,
  });

  final NoteMindMapEntity node;
  final Offset center;
  final bool isExpanded;

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
    if (node.children.isEmpty) return;

    final parentOffset = node.getOffset(isExpanded: isExpanded) + center;
    for (final child in node.children) {
      // 子节点位置（基于中心）
      final childOffset = child.getOffset(isExpanded: isExpanded) + center;

      // 绘制直线连接
      final color = _getNodeColor(child.type);
      final hasNote = child.note != null;

      final paint = Paint()
        ..color = color.withValues(alpha: hasNote ? 0.6 : 0.2)
        ..strokeWidth = hasNote ? 1.5 : 0.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(parentOffset, childOffset, paint);

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
