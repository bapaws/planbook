import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_planbook/app/view/app_date_picker.dart';
import 'package:flutter_planbook/note/new/cubit/note_new_cubit.dart';
import 'package:jiffy/jiffy.dart';

class NoteNewTitleView extends StatelessWidget {
  const NoteNewTitleView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<NoteNewCubit, NoteNewState, Jiffy?>(
      selector: (state) => state.createdAt ?? Jiffy.now(),
      builder: (context, createdAt) => AppDatePicker(
        date: createdAt,
        onDateChanged: (date) {
          context.read<NoteNewCubit>().onCreatedAtChanged(date);
        },
      ),
    );
  }
}
