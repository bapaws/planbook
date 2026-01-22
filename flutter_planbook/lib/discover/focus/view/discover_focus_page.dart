import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/app/app_router.dart';
import 'package:flutter_planbook/discover/focus/bloc/discover_focus_bloc.dart';
import 'package:flutter_planbook/discover/focus/view/discover_mind_map_page.dart';
import 'package:flutter_planbook/note/gallery/view/note_gallery_calendar_view.dart';
import 'package:planbook_core/data/page_status.dart';

@RoutePage()
class DiscoverFocusPage extends StatelessWidget {
  const DiscoverFocusPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<DiscoverFocusBloc, DiscoverFocusState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == PageStatus.loading) {
          EasyLoading.show(maskType: EasyLoadingMaskType.clear);
        } else if (EasyLoading.isShow) {
          EasyLoading.dismiss();
        }
      },
      child: BlocBuilder<DiscoverFocusBloc, DiscoverFocusState>(
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
                        context.read<DiscoverFocusBloc>().add(
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
                    : DiscoverMindMapPage<DiscoverFocusBloc>(
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
