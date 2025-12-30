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
    isRichText = widget.isRichText;
    note = widget.note;
    if (note == null) {
      titleController.text = title;
    } else {
      _connectController();
      // Only add listeners for existing notes to auto-save changes
      titleController.addListener(_updateNote);
      contentController.addListener(_updateNote);
      quillController.addListener(_updateNote);
    }
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
    if (note == null) {
      // Create new note
      if (isRichText) {
        Note newNote = Note(
          createdOn: DateTime.now(),
          updatedOn: DateTime.now(),
          name: titleController.text.isEmpty ? title : titleController.text,
          content: jsonEncode(quillController.document.toDelta().toJson()),
          isMarkDown: !isRichText,
        );
        noteBox.add(newNote);
        setState(() {
          note = newNote;
          // Add listeners after note is created for auto-save
          titleController.addListener(_updateNote);
          contentController.addListener(_updateNote);
          quillController.addListener(_updateNote);
        });
      } else {
        Note newNote = Note(
          createdOn: DateTime.now(),
          updatedOn: DateTime.now(),
          name: titleController.text.isEmpty ? title : titleController.text,
          content: contentController.text,
          isMarkDown: !isRichText,
        );
        noteBox.add(newNote);
        setState(() {
          note = newNote;
          // Add listeners after note is created for auto-save
          titleController.addListener(_updateNote);
          contentController.addListener(_updateNote);
          quillController.addListener(_updateNote);
        });
      }
    } else {
      // Update existing note
      _updateNote();
    }
  }

  _connectController() {
    print("Connecting Controller");
    titleController.text = note!.name;
    if (note!.isMarkDown) {
      print("MarkDown Controller");
      contentController.text = note!.content ?? "";
    } else {
      print("RichText Controller");
      quillController.document = Document.fromJson(
        jsonDecode(note!.content!),
      );
    }
  }

  _updateNote() {
    if (note == null) {
      return;
    }
    // Debounce updates to prevent excessive saves
    if (note!.isMarkDown) {
      note!.update(
        titleController.text.isEmpty ? title : titleController.text,
        contentController.text,
        DateTime.now(),
      );
    } else {
      note!.update(
        titleController.text.isEmpty ? title : titleController.text,
        jsonEncode(quillController.document.toDelta().toJson()),
        DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: titleController,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Untitled Document",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _saveToNote();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(note == null ? 'Note saved' : 'Note updated'),
                    ],
                  ),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.fixed,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Ionicons.save_outline),
            tooltip: 'Save',
          ),
          IconButton(
            onPressed: () => print("menu"),
            icon: const Icon(Ionicons.ellipsis_vertical),
            tooltip: 'More options',
          ),
        ],
      ),
      body: isRichText
          ? Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: QuillEditor.basic(
                        controller: quillController,
                        config: QuillEditorConfig(
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: QuillSimpleToolbar(
                    controller: quillController,
                    config: const QuillSimpleToolbarConfig(
                      multiRowsDisplay: false,
                    ),
                  ),
                ),
              ],
            )
          : Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MarkdownWriter(contentController: contentController),
              ),
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
        maxLines: null,
        minLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Write your markdown here...",
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
          ),
        ),
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }
}
