import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:ionicons/ionicons.dart';
import 'package:notedown/controller/note_controller.dart';
import 'package:notedown/model/note.dart';
import 'package:notedown/view/realtime_markdown_editor.dart';

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
  late TextEditingController contentController;
  final QuillController quillController = QuillController.basic();

  late bool isRichText;
  late Note? note;

  final String _defaultTitle = "Untitled Document";
  bool _titleManuallyEdited = false;

  @override
  void initState() {
    isRichText = widget.isRichText;
    
    // Always use MarkdownTextEditingController for markdown notes
    if (!isRichText) {
      contentController = MarkdownTextEditingController();
    } else {
      contentController = TextEditingController();
    }
    
    note = widget.note;
    if (note == null) {
      titleController.text = _defaultTitle;
      // Listen for title changes to detect manual edits
      titleController.addListener(_onTitleChanged);
    } else {
      _connectController();
      _titleManuallyEdited = true; // Existing notes have titles already
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

  void _onTitleChanged() {
    // Check if user has manually edited the title
    if (titleController.text != _defaultTitle && !_titleManuallyEdited) {
      _titleManuallyEdited = true;
    }
    // If user clears the title or sets it back to default, mark as not edited
    if (titleController.text.isEmpty || titleController.text == _defaultTitle) {
      _titleManuallyEdited = false;
    }
  }

  String _generateAutoTitle() {
    String content = '';
    
    if (isRichText) {
      // Extract text from Quill document
      final delta = quillController.document.toDelta();
      for (var op in delta.toList()) {
        if (op.data is String) {
          content += op.data as String;
        }
      }
    } else {
      content = contentController.text;
    }
    
    if (content.trim().isEmpty) {
      return _defaultTitle;
    }
    
    // Get first line or first 50 characters
    String firstLine = content.split('\n').first.trim();
    
    // Remove markdown syntax for cleaner title
    firstLine = firstLine.replaceAll(RegExp(r'^#+\s*'), ''); // Remove heading markers
    firstLine = firstLine.replaceAll(RegExp(r'^\s*[-*+]\s*'), ''); // Remove list markers
    firstLine = firstLine.replaceAll(RegExp(r'^\s*>\s*'), ''); // Remove blockquote
    firstLine = firstLine.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1'); // Remove bold
    firstLine = firstLine.replaceAll(RegExp(r'\*(.+?)\*'), r'$1'); // Remove italic
    firstLine = firstLine.replaceAll(RegExp(r'`(.+?)`'), r'$1'); // Remove code
    firstLine = firstLine.replaceAll(RegExp(r'\[(.+?)\]\(.+?\)'), r'$1'); // Remove links
    
    firstLine = firstLine.trim();
    
    if (firstLine.isEmpty) {
      return _defaultTitle;
    }
    
    // Limit to 50 characters
    if (firstLine.length > 50) {
      return '${firstLine.substring(0, 47)}...';
    }
    
    return firstLine;
  }

  void _ensureAutoTitleIfNeeded() {
    // If title wasn't manually edited and there's content, generate auto title
    if (!_titleManuallyEdited || 
        titleController.text.isEmpty || 
        titleController.text == _defaultTitle) {
      final autoTitle = _generateAutoTitle();
      titleController.text = autoTitle;
    }
  }

  void _saveAndGoBack() {
    _ensureAutoTitleIfNeeded();
    
    // Only save if there's content or it's an existing note
    if (contentController.text.isNotEmpty || 
        (isRichText && quillController.document.length > 1) ||
        note != null) {
      _saveToNote();
    }
    
    Navigator.of(context).pop();
  }

  _saveToNote() {
    _ensureAutoTitleIfNeeded();
    
    final noteBox = Boxes.getNotes();
    if (note == null) {
      // Create new note
      if (isRichText) {
        Note newNote = Note(
          createdOn: DateTime.now(),
          updatedOn: DateTime.now(),
          name: titleController.text.isEmpty ? _defaultTitle : titleController.text,
          content: jsonEncode(quillController.document.toDelta().toJson()),
          isMarkDown: false,
        );
        noteBox.add(newNote);
        setState(() {
          note = newNote;
          _titleManuallyEdited = true;
          // Add listeners after note is created for auto-save
          titleController.addListener(_updateNote);
          contentController.addListener(_updateNote);
          quillController.addListener(_updateNote);
        });
      } else {
        Note newNote = Note(
          createdOn: DateTime.now(),
          updatedOn: DateTime.now(),
          name: titleController.text.isEmpty ? _defaultTitle : titleController.text,
          content: contentController.text,
          isMarkDown: true,
        );
        noteBox.add(newNote);
        setState(() {
          note = newNote;
          _titleManuallyEdited = true;
          // Add listeners after note is created for auto-save
          titleController.addListener(_updateNote);
          contentController.addListener(_updateNote);
        });
      }
    } else {
      // Update existing note
      _updateNote();
    }
  }

  _connectController() {
    titleController.text = note!.name;
    if (note!.isMarkDown) {
      contentController.text = note!.content ?? "";
    } else {
      quillController.document = Document.fromJson(
        jsonDecode(note!.content!),
      );
    }
  }

  _updateNote() {
    if (note == null) {
      return;
    }
    
    String titleToSave = titleController.text;
    if (titleToSave.isEmpty || titleToSave == _defaultTitle) {
      titleToSave = _generateAutoTitle();
    }
    
    if (note!.isMarkDown) {
      note!.update(
        titleToSave,
        contentController.text,
        DateTime.now(),
      );
    } else {
      note!.update(
        titleToSave,
        jsonEncode(quillController.document.toDelta().toJson()),
        DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _saveAndGoBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _saveAndGoBack,
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
            onTap: () {
              // Select all text when tapping if it's the default title
              if (titleController.text == _defaultTitle) {
                titleController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: titleController.text.length,
                );
              }
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                _ensureAutoTitleIfNeeded();
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
              onPressed: () {},
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
                child: RealtimeMarkdownEditor(
                  controller: contentController,
                  onChanged: (text) {
                    if (note != null) {
                      _updateNote();
                    }
                  },
                ),
              ),
      ),
    );
  }
}
