import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:simple_note/src/data/models/note.dart';
import 'package:simple_note/src/features/notes/presentation/note_editor_screen.dart';

class NoteCard extends ConsumerWidget {
  const NoteCard({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    note.attachments.loadSync(); // Ensure attachments are loaded
    final hasAttachments = note.attachments.isNotEmpty;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(note: note),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAttachments) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.file(
                  File(note.attachments.first.filePath),
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              note.title.isEmpty ? '(제목 없음)' : note.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                // Display checklist items or body text
                note.type == NoteType.checklist 
                    ? note.checklistItems.map((e) => '\u2022 ${e.text}').join('\n')
                    : note.body ?? '',
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
                maxLines: hasAttachments ? 2 : 5, // Adjust lines based on image presence
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('yyyy.MM.dd').format(note.updatedAt),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
