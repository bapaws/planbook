import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/discover/diary/bloc/diary_notebook_bloc.dart';
import 'package:flutter_planbook/discover/diary/model/diary_notebook_look.dart';

/// 书架和阅读页共用当年日记本外观。没有 bloc 时用预制皮面，测试不用先注册。
class DiaryNotebookThemeBuilder extends StatelessWidget {
  const DiaryNotebookThemeBuilder({required this.builder, super.key});

  final Widget Function(int year, DiaryNotebookLook look) builder;

  @override
  Widget build(BuildContext context) {
    final bloc = _maybeOf(context);
    if (bloc == null) {
      final year = DateTime.now().year;
      return builder(year, DiaryNotebookLook.prefabFor(year));
    }
    return BlocBuilder<DiaryNotebookBloc, DiaryNotebookState>(
      bloc: bloc,
      builder: (context, state) =>
          builder(state.selectedYear, state.lookFor(state.selectedYear)),
    );
  }

  static DiaryNotebookBloc? _maybeOf(BuildContext context) {
    try {
      return context.read<DiaryNotebookBloc>();
    } on ProviderNotFoundException {
      return null;
    }
  }
}
