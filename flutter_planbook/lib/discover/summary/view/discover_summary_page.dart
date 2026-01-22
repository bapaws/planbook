import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/focus/bloc/discover_focus_bloc.dart';
import 'package:flutter_planbook/discover/focus/view/discover_mind_map_page.dart';
import 'package:flutter_planbook/discover/summary/bloc/discover_summary_bloc.dart';
import 'package:flutter_planbook/note/gallery/view/note_gallery_calendar_view.dart';
import 'package:planbook_core/data/page_status.dart';

@RoutePage()
class DiscoverSummaryPage extends StatelessWidget {
  const DiscoverSummaryPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscoverSummaryBloc, DiscoverFocusState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == PageStatus.loading) {
          EasyLoading.show(maskType: EasyLoadingMaskType.clear);
        } else if (EasyLoading.isShow) {
          EasyLoading.dismiss();
        }
      },
      child: BlocBuilder<DiscoverSummaryBloc, DiscoverFocusState>(
        builder: (context, state) => Column(
          children: [
            AnimatedSwitcher(
              duration: Durations.medium1,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  child: child,
                ),
              ),
              child: state.isCalendarExpanded
                  ? NoteGalleryCalendarView(
                      date: state.date,
                      onDateSelected: (date) {
                        context.read<DiscoverSummaryBloc>().add(
                          DiscoverFocusCalendarDateSelected(date: date),
                        );
                      },
                    )
                  : null,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: Durations.medium1,
                child: state.mindMap == null
                    ? const SizedBox.shrink()
                    : DiscoverMindMapPage<DiscoverSummaryBloc>(
                        mindMap: state.mindMap!,
                        isExpanded: state.isExpandedAllNodes,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
