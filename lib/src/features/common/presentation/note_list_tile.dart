import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/features/notes/presentation/note_editor_screen.dart';

class NoteListTile extends StatelessWidget {
  const NoteListTile({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(note: note),
            ),
          );
        },
        title: Text(
          note.title.isNotEmpty ? note.title : '(제목 없음)',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.body != null && note.body!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  note.body!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  note.type == NoteType.checklist ? Icons.checklist : Icons.text_snippet_outlined,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('yyyy.MM.dd').format(note.updatedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                if (note.pinned) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                ],
              ],
            ),
          ],
        ),
        trailing: note.attachments.isNotEmpty
            ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(File(note.attachments.first.filePath)),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
