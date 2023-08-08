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
  final quill.QuillController _controller = quill.QuillController.basic();

  late Note note;

  @override
  void initState() {
    note = widget.note;
    if (note.isMarkDown) {
      // _controller.document
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("NoteDown"),
      ),
      body: note.isMarkDown
          ? Markdown(data: note.content!)
          : Expanded(
              child: Container(
                child: quill.QuillEditor.basic(
                  controller: _controller,
                  readOnly: true, // true for view only mode
                ),
              ),
            ),
    );
  }
}
