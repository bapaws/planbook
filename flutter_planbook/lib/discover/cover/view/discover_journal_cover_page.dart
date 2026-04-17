import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_planbook/core/view/app_scaffold.dart';
import 'package:flutter_planbook/discover/cover/bloc/discover_cover_bloc.dart';
import 'package:flutter_planbook/discover/cover/repository/discover_cover_repository.dart';
import 'package:flutter_planbook/discover/daily/view/journal_daily_page.dart';
import 'package:flutter_planbook/discover/journal/view/discover_journal_cover.dart';
import 'package:planbook_core/data/page_status.dart';

@RoutePage()
class DiscoverJournalCoverPage extends StatelessWidget {
  const DiscoverJournalCoverPage({
    required this.year,
    this.currentCoverImage,
    super.key,
  });
  final int year;
  final String? currentCoverImage;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DiscoverCoverBloc(
        coverRepository: context.read<DiscoverCoverRepository>(),
        year: year,
        currentCoverImage: currentCoverImage,
      )..add(const DiscoverCoverRequested()),
      child: BlocListener<DiscoverCoverBloc, DiscoverCoverState>(
        listener: (context, state) {
          if (state.status == PageStatus.loading) {
            EasyLoading.show(maskType: EasyLoadingMaskType.clear);
          } else {
            EasyLoading.dismiss();
          }
          if (state.status == PageStatus.dispose) {
            context.router.pop();
          }
        },
        child: const _DiscoverJournalCoverPage(),
      ),
    );
  }
}

class _DiscoverJournalCoverPage extends StatelessWidget {
  const _DiscoverJournalCoverPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiscoverCoverBloc, DiscoverCoverState>(
      builder: (context, state) {
        return AppScaffold(
          appBar: AppBar(
            forceMaterialTransparency: true,
            title: Text('${state.year} 年封面设置'),
          ),
          body: GridView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            itemCount: state.builtinCovers.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio:
                  kDiscoverJournalDailyPageWidth /
                  kDiscoverJournalDailyPageHeight,
            ),
            itemBuilder: (context, index) {
              final path = state.builtinCovers[index];
              final selected = state.selectedCoverPath == path;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  context.read<DiscoverCoverBloc>().add(
                    DiscoverCoverSelected(coverPath: path),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      child: JournalCover(
                        year: state.year,
                        backgroundImage: path,
                        colorScheme: state.builtinColorSchemes[index],
                      ),
                    ),
                    if (selected)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
