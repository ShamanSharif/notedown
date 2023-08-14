import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../model/note.dart';

class NoteViewer extends StatefulWidget {
  final Note note;
  const NoteViewer({super.key, required this.note});

  @override
  State<NoteViewer> createState() => _NoteViewerState();
}

class _NoteViewerState extends State<NoteViewer> {
  quill.QuillController _controller = quill.QuillController.basic();

  late Note note;

  @override
  void initState() {
    note = widget.note;
    print(note.archived);
    if (!note.isMarkDown) {
      _controller = quill.QuillController(
        document: quill.Document.fromJson(
          jsonDecode(note.content!),
        ),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    super.initState();
  }

  void archiveNote() {
    note.archive();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("NoteDown"),
        actions: [
          PopupMenuButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.black,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 1,
                child: Text("Edit"),
              ),
              const PopupMenuItem(
                value: 2,
                child: Text("Archive"),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 2:
                  {
                    archiveNote();
                    break;
                  }
              }
            },
          ),
        ],
      ),
      body: note.isMarkDown
          ? Markdown(data: note.content!)
          : Padding(
              padding: const EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
              ),
              child: quill.QuillEditor.basic(
                controller: _controller,
                autoFocus: false,
                readOnly: true,
              ),
            ),
    );
  }
}
