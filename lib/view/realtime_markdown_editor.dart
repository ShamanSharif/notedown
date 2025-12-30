import 'package:flutter/material.dart';

class RealtimeMarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;

  const RealtimeMarkdownEditor({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  State<RealtimeMarkdownEditor> createState() => _RealtimeMarkdownEditorState();
}

class _RealtimeMarkdownEditorState extends State<RealtimeMarkdownEditor> {
  int _currentLineIndex = 0;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final currentText = widget.controller.text;

    // Check if a newline was just added (Enter pressed)
    if (currentText.length > _previousText.length) {
      final diff = currentText.length - _previousText.length;
      if (diff >= 1) {
        final cursorPos = widget.controller.selection.baseOffset;
        if (cursorPos > 0 && cursorPos <= currentText.length) {
          // Check if newline was inserted
          if (currentText[cursorPos - 1] == '\n') {
            _handleNewLine(cursorPos);
          }
        }
      }
    }

    _previousText = currentText;

    if (widget.onChanged != null) {
      widget.onChanged!(currentText);
    }
    _updateCurrentLine();
  }

  void _handleNewLine(int cursorPos) {
    final controller = widget.controller;
    final text = controller.text;

    // Find the previous line (before the newline we just added)
    int prevLineEnd = cursorPos - 1;
    int prevLineStart = text.lastIndexOf('\n', prevLineEnd - 1) + 1;
    if (prevLineStart < 0) prevLineStart = 0;

    String previousLine = text.substring(prevLineStart, prevLineEnd);

    // Check for list patterns
    final bulletMatch =
        RegExp(r'^(\s*)([-*+])\s(.*)$').firstMatch(previousLine);
    final numberedMatch =
        RegExp(r'^(\s*)(\d+)\.\s(.*)$').firstMatch(previousLine);

    String? prefix;
    bool wasEmpty = false;

    if (bulletMatch != null) {
      String indent = bulletMatch.group(1) ?? '';
      String bullet = bulletMatch.group(2) ?? '-';
      String content = bulletMatch.group(3) ?? '';
      wasEmpty = content.trim().isEmpty;
      prefix = '$indent$bullet ';
    } else if (numberedMatch != null) {
      String indent = numberedMatch.group(1) ?? '';
      int number = int.tryParse(numberedMatch.group(2) ?? '1') ?? 1;
      String content = numberedMatch.group(3) ?? '';
      wasEmpty = content.trim().isEmpty;
      prefix = '$indent${number + 1}. ';
    }

    if (prefix != null) {
      if (wasEmpty) {
        // Previous list item was empty - remove it and don't continue list
        final newText =
            '${text.substring(0, prevLineStart)}\n${text.substring(cursorPos)}';

        // Use WidgetsBinding to defer the update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: prevLineStart + 1),
          );
          _previousText = newText;
        });
      } else {
        // Continue the list
        final newText =
            text.substring(0, cursorPos) + prefix + text.substring(cursorPos);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.value = TextEditingValue(
            text: newText,
            selection:
                TextSelection.collapsed(offset: cursorPos + prefix!.length),
          );
          _previousText = newText;
        });
      }
    }
  }

  void _updateCurrentLine() {
    final controller = widget.controller;
    if (controller is MarkdownTextEditingController) {
      final text = controller.text;
      final cursorPos = controller.selection.baseOffset;

      if (cursorPos < 0 || cursorPos > text.length) {
        return;
      }

      // Count which line the cursor is on
      int lineIndex = 0;
      for (int i = 0; i < cursorPos && i < text.length; i++) {
        if (text[i] == '\n') {
          lineIndex++;
        }
      }

      if (lineIndex != _currentLineIndex) {
        setState(() {
          _currentLineIndex = lineIndex;
        });
      }

      controller.setActiveLine(lineIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: widget.controller,
        maxLines: null,
        minLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        onChanged: (text) {
          _updateCurrentLine();
        },
        onTap: () {
          _updateCurrentLine();
        },
        style: TextStyle(
          fontSize: 16,
          height: 1.8,
          color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText:
              "Start typing markdown...\n\n# Heading 1\n**Bold** *Italic*\n- List item\n```\ncode block\n```",
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}

/// A custom text editing controller that applies markdown styling in real-time
/// Hides syntax on non-active lines, shows it on the active (cursor) line
class MarkdownTextEditingController extends TextEditingController {
  int _activeLine = 0;

  MarkdownTextEditingController({super.text});

  void setActiveLine(int line) {
    if (_activeLine != line) {
      _activeLine = line;
      notifyListeners();
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final List<InlineSpan> children = [];
    final lines = text.split('\n');

    bool inCodeBlock = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final isActiveLine = i == _activeLine;

      if (i > 0) {
        children.add(const TextSpan(text: '\n'));
      }

      // Check for code block delimiters
      if (line.trimLeft().startsWith('```')) {
        inCodeBlock = !inCodeBlock;
        if (isActiveLine) {
          // Show the backticks on active line
          children.add(TextSpan(
            text: line,
            style: TextStyle(
              fontFamily: 'monospace',
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              fontSize: 14,
            ),
          ));
        } else {
          // Hide backticks, show subtle indicator
          children.add(TextSpan(
            text: inCodeBlock ? '┌─────────' : '└─────────',
            style: TextStyle(
              fontFamily: 'monospace',
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              fontSize: 14,
            ),
          ));
        }
        continue;
      }

      // Inside code block
      if (inCodeBlock) {
        children.add(TextSpan(
          text: line,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
            backgroundColor: isDark
                ? Colors.grey.shade900.withOpacity(0.5)
                : Colors.grey.shade100,
          ),
        ));
        continue;
      }

      // Process headings
      if (line.startsWith('### ')) {
        if (isActiveLine) {
          children.add(TextSpan(
            text: line,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        } else {
          children.add(TextSpan(
            text: line.substring(4), // Hide ###
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        }
      } else if (line.startsWith('## ')) {
        if (isActiveLine) {
          children.add(TextSpan(
            text: line,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        } else {
          children.add(TextSpan(
            text: line.substring(3), // Hide ##
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        }
      } else if (line.startsWith('# ')) {
        if (isActiveLine) {
          children.add(TextSpan(
            text: line,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        } else {
          children.add(TextSpan(
            text: line.substring(2), // Hide #
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        }
      } else if (line.startsWith('> ')) {
        // Blockquote
        if (isActiveLine) {
          children.add(TextSpan(
            text: line,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ));
        } else {
          children.add(TextSpan(
            text: '│ ${line.substring(2)}',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ));
        }
      } else if (line.startsWith('- ') ||
          line.startsWith('* ') ||
          line.startsWith('+ ')) {
        // Bullet list
        if (isActiveLine) {
          children.add(TextSpan(
            text: line,
            style: TextStyle(
              color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
            ),
          ));
        } else {
          children.add(TextSpan(
            text: '• ${line.substring(2)}',
            style: TextStyle(
              color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
            ),
          ));
        }
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        // Numbered list - keep as is (numbers are fine to show)
        children.add(TextSpan(
          text: line,
          style: TextStyle(
            color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
          ),
        ));
      } else if (line.startsWith('---') ||
          line.startsWith('***') ||
          line.startsWith('___')) {
        // Horizontal rule
        if (isActiveLine) {
          children.add(TextSpan(
            text: line,
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ));
        } else {
          children.add(TextSpan(
            text: '─────────────────',
            style: TextStyle(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ));
        }
      } else {
        // Parse inline styles
        children.addAll(_parseInlineStyles(
            line, style, isDark, primaryColor, isActiveLine));
      }
    }

    return TextSpan(style: style, children: children);
  }

  List<InlineSpan> _parseInlineStyles(
    String text,
    TextStyle? baseStyle,
    bool isDark,
    Color primaryColor,
    bool isActiveLine,
  ) {
    final List<InlineSpan> spans = [];

    if (isActiveLine) {
      // Show syntax on active line
      final RegExp pattern =
          RegExp(r'(\*\*\*(.+?)\*\*\*)|' // Bold italic ***text***
              r'(\*\*(.+?)\*\*)|' // Bold **text**
              r'(__(.+?)__)|' // Bold __text__
              r'(\*(.+?)\*)|' // Italic *text*
              r'(_(.+?)_)|' // Italic _text_
              r'(`(.+?)`)|' // Code `text`
              r'(\[(.+?)\]\((.+?)\))' // Link [text](url)
              );

      int lastEnd = 0;

      for (final match in pattern.allMatches(text)) {
        if (match.start > lastEnd) {
          spans.add(TextSpan(
            text: text.substring(lastEnd, match.start),
            style: baseStyle,
          ));
        }

        final fullMatch = match.group(0)!;

        if (match.group(1) != null) {
          spans.add(TextSpan(
            text: fullMatch,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        } else if (match.group(3) != null || match.group(5) != null) {
          spans.add(TextSpan(
            text: fullMatch,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        } else if (match.group(7) != null || match.group(9) != null) {
          spans.add(TextSpan(
            text: fullMatch,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ));
        } else if (match.group(11) != null) {
          spans.add(TextSpan(
            text: fullMatch,
            style: TextStyle(
              fontFamily: 'monospace',
              backgroundColor:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
            ),
          ));
        } else if (match.group(13) != null) {
          spans.add(TextSpan(
            text: fullMatch,
            style: TextStyle(
              color: primaryColor,
              decoration: TextDecoration.underline,
            ),
          ));
        }

        lastEnd = match.end;
      }

      if (lastEnd < text.length) {
        spans.add(TextSpan(
          text: text.substring(lastEnd),
          style: baseStyle,
        ));
      }

      if (spans.isEmpty) {
        spans.add(TextSpan(text: text, style: baseStyle));
      }
    } else {
      // Hide syntax on non-active lines
      final RegExp pattern =
          RegExp(r'(\*\*\*(.+?)\*\*\*)|' // Bold italic ***text***
              r'(\*\*(.+?)\*\*)|' // Bold **text**
              r'(__(.+?)__)|' // Bold __text__
              r'(\*(.+?)\*)|' // Italic *text*
              r'(_(.+?)_)|' // Italic _text_
              r'(`(.+?)`)|' // Code `text`
              r'(\[(.+?)\]\((.+?)\))' // Link [text](url)
              );

      int lastEnd = 0;

      for (final match in pattern.allMatches(text)) {
        if (match.start > lastEnd) {
          spans.add(TextSpan(
            text: text.substring(lastEnd, match.start),
            style: baseStyle,
          ));
        }

        if (match.group(1) != null) {
          // Bold italic - show only content
          spans.add(TextSpan(
            text: match.group(2),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        } else if (match.group(3) != null) {
          // Bold **text**
          spans.add(TextSpan(
            text: match.group(4),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        } else if (match.group(5) != null) {
          // Bold __text__
          spans.add(TextSpan(
            text: match.group(6),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ));
        } else if (match.group(7) != null) {
          // Italic *text*
          spans.add(TextSpan(
            text: match.group(8),
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ));
        } else if (match.group(9) != null) {
          // Italic _text_
          spans.add(TextSpan(
            text: match.group(10),
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ));
        } else if (match.group(11) != null) {
          // Code - show content only
          spans.add(TextSpan(
            text: match.group(12),
            style: TextStyle(
              fontFamily: 'monospace',
              backgroundColor:
                  isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              color: isDark ? Colors.orange.shade300 : Colors.orange.shade800,
            ),
          ));
        } else if (match.group(13) != null) {
          // Link - show only text part
          spans.add(TextSpan(
            text: match.group(14),
            style: TextStyle(
              color: primaryColor,
              decoration: TextDecoration.underline,
            ),
          ));
        }

        lastEnd = match.end;
      }

      if (lastEnd < text.length) {
        spans.add(TextSpan(
          text: text.substring(lastEnd),
          style: baseStyle,
        ));
      }

      if (spans.isEmpty) {
        spans.add(TextSpan(text: text, style: baseStyle));
      }
    }

    return spans;
  }
}
