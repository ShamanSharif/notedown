import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:notedown/view/create_note.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../model/note.dart';

class NoteViewer extends StatefulWidget {
  final Note note;
  const NoteViewer({super.key, required this.note});

  @override
  State<NoteViewer> createState() => _NoteViewerState();
}

class _NoteViewerState extends State<NoteViewer> {
  quill.QuillController _controller = quill.QuillController.basic();
  bool _isExporting = false;

  late Note note;

  @override
  void initState() {
    note = widget.note;
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

  Future<void> _exportToPdf() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final pdf = pw.Document();
      
      // Get content as plain text
      String content = '';
      if (note.isMarkDown) {
        content = note.content ?? '';
      } else {
        // Extract text from Quill document
        final delta = _controller.document.toDelta();
        for (var op in delta.toList()) {
          if (op.data is String) {
            content += op.data as String;
          }
        }
      }

      // Parse content into styled elements
      final lines = content.split('\n');
      final List<pw.Widget> pdfWidgets = [];
      
      // Add title
      pdfWidgets.add(
        pw.Text(
          note.name,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
      pdfWidgets.add(pw.SizedBox(height: 8));
      pdfWidgets.add(
        pw.Text(
          'Created: ${_formatDate(note.createdOn)} • Updated: ${_formatDate(note.updatedOn)}',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      );
      pdfWidgets.add(pw.SizedBox(height: 20));
      pdfWidgets.add(pw.Divider(color: PdfColors.grey300));
      pdfWidgets.add(pw.SizedBox(height: 20));

      // Process content lines
      bool inCodeBlock = false;
      List<String> codeBlockLines = [];

      for (final line in lines) {
        if (line.trim().startsWith('```')) {
          if (inCodeBlock) {
            // End code block
            pdfWidgets.add(_buildCodeBlock(codeBlockLines.join('\n')));
            pdfWidgets.add(pw.SizedBox(height: 12));
            codeBlockLines.clear();
          }
          inCodeBlock = !inCodeBlock;
          continue;
        }

        if (inCodeBlock) {
          codeBlockLines.add(line);
          continue;
        }

        // Process markdown elements
        if (line.startsWith('# ')) {
          pdfWidgets.add(pw.SizedBox(height: 16));
          pdfWidgets.add(
            pw.Text(
              line.substring(2),
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          );
          pdfWidgets.add(pw.SizedBox(height: 8));
        } else if (line.startsWith('## ')) {
          pdfWidgets.add(pw.SizedBox(height: 14));
          pdfWidgets.add(
            pw.Text(
              line.substring(3),
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          );
          pdfWidgets.add(pw.SizedBox(height: 6));
        } else if (line.startsWith('### ')) {
          pdfWidgets.add(pw.SizedBox(height: 12));
          pdfWidgets.add(
            pw.Text(
              line.substring(4),
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
          );
          pdfWidgets.add(pw.SizedBox(height: 4));
        } else if (line.startsWith('> ')) {
          pdfWidgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              padding: const pw.EdgeInsets.only(left: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(color: PdfColors.grey400, width: 3),
                ),
              ),
              child: pw.Text(
                line.substring(2),
                style: pw.TextStyle(
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          );
        } else if (line.startsWith('- ') || line.startsWith('* ')) {
          pdfWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 12, top: 2, bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ', style: const pw.TextStyle(fontSize: 12)),
                  pw.Expanded(
                    child: pw.Text(
                      _parseInlineMarkdown(line.substring(2)),
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
          final match = RegExp(r'^(\d+)\. (.*)$').firstMatch(line);
          if (match != null) {
            pdfWidgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12, top: 2, bottom: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 20,
                      child: pw.Text('${match.group(1)}.', style: const pw.TextStyle(fontSize: 12)),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        _parseInlineMarkdown(match.group(2) ?? ''),
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        } else if (line.startsWith('---') || line.startsWith('***') || line.startsWith('___')) {
          pdfWidgets.add(pw.SizedBox(height: 8));
          pdfWidgets.add(pw.Divider(color: PdfColors.grey300));
          pdfWidgets.add(pw.SizedBox(height: 8));
        } else if (line.trim().isNotEmpty) {
          pdfWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(
                _parseInlineMarkdown(line),
                style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
              ),
            ),
          );
        } else {
          pdfWidgets.add(pw.SizedBox(height: 8));
        }
      }

      // Build PDF pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pdfWidgets,
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ),
        ),
      );

      // Save to downloads
      final directory = await getApplicationDocumentsDirectory();
      final sanitizedName = note.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
      final file = File('${directory.path}/${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;

      // Show success and offer to share
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('PDF Exported'),
          content: Text('Saved to:\n${file.path.split('/').last}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Done'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.share, size: 18),
              label: const Text('Share'),
            ),
          ],
        ),
      );

      if (result == true && mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: note.name,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  pw.Widget _buildCodeBlock(String code) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        code,
        style: pw.TextStyle(
          font: pw.Font.courier(),
          fontSize: 10,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  String _parseInlineMarkdown(String text) {
    // Remove inline markdown for plain text in PDF
    text = text.replaceAll(RegExp(r'\*\*\*(.+?)\*\*\*'), r'$1');
    text = text.replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1');
    text = text.replaceAll(RegExp(r'__(.+?)__'), r'$1');
    text = text.replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
    text = text.replaceAll(RegExp(r'_(.+?)_'), r'$1');
    text = text.replaceAll(RegExp(r'`(.+?)`'), r'$1');
    text = text.replaceAll(RegExp(r'\[(.+?)\]\((.+?)\)'), r'$1 ($2)');
    return text;
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
              PopupMenuItem(
                value: 1,
                enabled: !_isExporting,
                child: Row(
                  children: [
                    if (_isExporting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.picture_as_pdf_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(_isExporting ? "Exporting..." : "Export to PDF"),
                  ],
                ),
              ),
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
              if (value == 1) {
                _exportToPdf();
              } else if (value == 2) {
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade200
                        : Colors.grey.shade800,
                  ),
                  h1: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  h2: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  h3: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  code: TextStyle(
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade200
                        : Colors.black87,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  a: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  em: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade200
                        : Colors.grey.shade800,
                  ),
                  blockquote: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade800
                        : Colors.grey.shade100,
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 4,
                      ),
                    ),
                  ),
                  listBullet: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade200
                        : Colors.grey.shade800,
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
