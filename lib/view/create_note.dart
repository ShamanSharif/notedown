import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ionicons/ionicons.dart';
import 'package:notedown/controller/note_controller.dart';
import 'package:notedown/model/note.dart';

class CreateNote extends StatefulWidget {
  final Note? note;
  final bool isRichText;
  const CreateNote({
    super.key,
    this.note,
    this.isRichText = false,
  });

  @override
  State<CreateNote> createState() => _CreateNoteState();
}

class _CreateNoteState extends State<CreateNote> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final QuillController quillController = QuillController.basic();

  late bool isRichText;
  late Note? note;

  String title = "Untitled Document";

  @override
  void initState() {
    titleController.text = title;
    isRichText = widget.isRichText;
    note = widget.note;
    if (note == null) _saveToNote();
    titleController.addListener(_updateNote);
    contentController.addListener(_updateNote);
    quillController.addListener(_updateNote);
    super.initState();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    quillController.dispose();
    super.dispose();
  }

  _saveToNote() {
    final noteBox = Boxes.getNotes();
    if (isRichText) {
      Note newNote = Note(
        createdOn: DateTime.now(),
        updatedOn: DateTime.now(),
        name: titleController.text,
        content: jsonEncode(quillController.document.toDelta().toJson()),
        isMarkDown: !isRichText,
      );
      noteBox.add(newNote);
      setState(() => note = newNote);
    } else {
      Note newNote = Note(
        createdOn: DateTime.now(),
        updatedOn: DateTime.now(),
        name: titleController.text,
        content: contentController.text,
        isMarkDown: !isRichText,
      );
      noteBox.add(newNote);
      setState(() => note = newNote);
    }
  }

  _updateNote() {
    print("Note Update Called");
    if (note == null) {
      print("Note Is Null");
      return;
    }
    if (note!.isMarkDown) {
      print("MarkDown");
      note!.update(
        titleController.text,
        contentController.text,
        DateTime.now(),
      );
    } else {
      print("RichText");
      note!.update(
        titleController.text,
        jsonEncode(quillController.document.toDelta().toJson()),
        DateTime.now(),
      );
    }
    print("Note Is Updated");
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
        child: isRichText
            ? Column(
                children: [
                  Expanded(
                    child: Container(
                      child: QuillEditor.basic(
                        controller: quillController,
                        readOnly: false, // true for view only mode
                      ),
                    ),
                  ),
                  QuillToolbar.basic(
                    controller: quillController,
                    multiRowsDisplay: false,
                  ),
                ],
              )
            : MarkdownWriter(contentController: contentController),
      ),
    );
  }
}

class MarkdownWriter extends StatelessWidget {
  const MarkdownWriter({
    super.key,
    required this.contentController,
  });

  final TextEditingController contentController;

  @override
  Widget build(BuildContext context) {
    return Form(
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
    );
  }
}
