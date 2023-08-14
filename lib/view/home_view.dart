import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notedown/view/note_viewer.dart';

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
  String noteDateView(DateTime dateTime) {
    return "Jun 18, 23";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("NoteDown"),
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
      floatingActionButtonLocation: ExpandableFab.location,
      floatingActionButton: ExpandableFab(
        type: ExpandableFabType.up,
        distance: 70,
        openButtonBuilder: RotateFloatingActionButtonBuilder(
          child: const Icon(
            Icons.add,
            size: 40,
          ),
          fabSize: ExpandableFabSize.regular,
        ),
        closeButtonBuilder: FloatingActionButtonBuilder(
          size: 70,
          builder: (BuildContext context, void Function()? onPressed,
              Animation<double> progress) {
            return IconButton(
              onPressed: onPressed,
              icon: const Icon(
                Icons.close,
                size: 40,
              ),
            );
          },
        ),
        children: [
          FloatingActionButton.extended(
            label: const Text("MarkDown"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const CreateNote(
                      isRichText: false,
                    );
                  },
                ),
              );
            },
          ),
          FloatingActionButton.extended(
            heroTag: null,
            label: const Text("Rich Text"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const CreateNote(
                      isRichText: true,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget notesWidget(List<Note> notes) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (Note note in notes)
              if (!(note.archived ?? true))
                Slidable(
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        // An action can be bigger than the others.

                        onPressed: (val) {
                          note.archive();
                        },
                        backgroundColor: Colors.grey.shade900,
                        foregroundColor: Colors.white,
                        icon: Icons.archive,
                        label: 'Archive',
                      ),
                      SlidableAction(
                        onPressed: (val) {
                          note.delete();
                        },
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      print("TAP TAP TAP");
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return NoteViewer(note: note);
                          },
                        ),
                      );
                    },
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.black12,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          RotatedBox(
                            quarterTurns: 3,
                            child: Text(noteDateView(note.createdOn)),
                          ),
                          const SizedBox(
                            width: 20,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Text(
                                note.archived ?? true
                                    ? "Archived"
                                    : "Not Archived",
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
