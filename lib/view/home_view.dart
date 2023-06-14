import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../controller/note_controller.dart';
import '../model/note.dart';
import 'create_note.dart';

class HomeView extends StatefulWidget {
  const HomeView({
    super.key,
  });
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("NoteDown"),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Note>>(
          valueListenable: Boxes.getNotes().listenable(),
          builder: (context, box, _) {
            final notes = box.values.toList().cast<Note>();
            return notesWidget(notes);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return const CreateNote();
              },
            ),
          );
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget notesWidget(List<Note> notes) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          for (Note note in notes)
            InkWell(
              onTap: () {},
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              child: Text(note.name),
            )
        ],
      ),
    );
  }
}
