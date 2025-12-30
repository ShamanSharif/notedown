import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:notedown/view/create_note.dart';

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
        readOnly: true,
      );
    }
    super.initState();
  }

  void archiveNote() {
    note.archive();
    Navigator.pop(context);
  }

  void editNote(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNote(
          note: note,
          isRichText: !note.isMarkDown,
        ),
      ),
    ).then((_) {
      // Refresh the note when returning from edit
      setState(() {
        note = widget.note;
        if (!note.isMarkDown && note.content != null) {
          _controller = quill.QuillController(
            document: quill.Document.fromJson(
              jsonDecode(note.content!),
            ),
            selection: const TextSelection.collapsed(offset: 0),
            readOnly: true,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          note.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => editNote(note),
            tooltip: 'Edit',
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 2,
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 20),
                    SizedBox(width: 12),
                    Text("Archive"),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 2) {
                archiveNote();
              }
            },
          ),
        ],
      ),
      body: note.isMarkDown
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: MarkdownBody(
                  data: note.content ?? '',
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      color: Colors.grey.shade800,
                    ),
                    h1: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    h2: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    h3: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    code: TextStyle(
                      backgroundColor: Colors.grey.shade100,
                      fontFamily: 'monospace',
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            )
          : Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: quill.QuillEditor.basic(
                  controller: _controller,
                  config: const quill.QuillEditorConfig(
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
    );
  }
}
