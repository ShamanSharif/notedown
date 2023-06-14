import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:notedown/controller/note_controller.dart';
import 'package:notedown/model/note.dart';

class CreateNote extends StatefulWidget {
  const CreateNote({super.key});

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  String title = "Untitled Document";

  @override
  void initState() {
    titleController.text = title;
    super.initState();
  }

  _saveToNote() {
    final noteBox = Boxes.getNotes();
    noteBox.add(
      Note(
        createdOn: DateTime.now(),
        updatedOn: DateTime.now(),
        name: titleController.text,
        content: contentController.text,
        isMarkDown: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            border: InputBorder.none,
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _saveToNote,
            icon: const Icon(Ionicons.save),
          ),
          IconButton(
            onPressed: () => print("menu"),
            icon: const Icon(Ionicons.ellipsis_vertical),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          child: TextFormField(
            controller: contentController,
            maxLines: 999,
            minLines: 999,
            // expands: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Write",
              hintStyle: TextStyle(),
            ),
          ),
        ),
      ),
    );
  }
}
