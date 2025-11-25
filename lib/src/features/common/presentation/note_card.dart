import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/notes/presentation/note_editor_screen.dart';

class NoteCard extends ConsumerWidget {
  const NoteCard({super.key, required this.note});

  final Note note;

  static final List<(Color, Color)> _palette = [
    (const Color(0xFFC7D2FE), const Color(0xFFEDE9FE)),
    (const Color(0xFFD1FAE5), const Color(0xFFECFDF5)),
    (const Color(0xFFFFEDD5), const Color(0xFFFFFBEB)),
    (const Color(0xFFFDE68A), const Color(0xFFFFF7ED)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    note.attachments.loadSync(); // Ensure attachments are loaded
    final hasAttachments = note.attachments.isNotEmpty;
    final palette = note.type == NoteType.checklist 
        ? _palette[2]  // 체크리스트: 노랑 계열
        : _palette[0]; // 텍스트: 보라색 계열

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
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(26.0),
          border: Border.all(color: palette.$1.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: palette.$1.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded( // Use Expanded to force the chip to take only available space
                  child: _NoteTypeChip(
                    isChecklist: note.type == NoteType.checklist,
                    accent: palette.$1,
                  ),
                ),
                const SizedBox(width: 8),
                // Icons row stays as is, but now the chip will shrink/truncate if needed
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasAttachments) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
                        decoration: BoxDecoration(
                          color: palette.$1.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.photo_outlined, size: 14, color: palette.$1),
                            const SizedBox(width: 4),
                            Text(
                              '${note.attachments.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: palette.$1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4), // Reduced spacing
                    ],
                    GestureDetector(
                      onTap: () async {
                        await ref.read(noteRepositoryProvider).togglePinStatus(note.id);
                      },
                      child: Icon(
                        note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
                        size: 20,
                        color: note.pinned ? palette.$1 : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              note.title.isEmpty ? '(제목 없음)' : note.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Removed Expanded to allow intrinsic height for Masonry layout
            note.type == NoteType.checklist
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: note.checklistItems.take(4).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          children: [
                            Icon(
                              item.done
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 16,
                              color: item.done
                                  ? palette.$1.darken()
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: item.done
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade700,
                                      decoration: item.done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      height: 1.2,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : Text(
                    note.body ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                    maxLines: hasAttachments ? 3 : 6,
                    overflow: TextOverflow.ellipsis,
                  ),
            if (hasAttachments) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(18.0),
                child: Image.file(
                  File(note.attachments.first.filePath),
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  DateFormat('yyyy.MM.dd').format(note.updatedAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteTypeChip extends StatelessWidget {
  const _NoteTypeChip({required this.isChecklist, required this.accent});

  final bool isChecklist;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isChecklist ? Icons.checklist_rtl : Icons.text_snippet_outlined,
            size: 14,
            color: accent.darken(),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isChecklist ? '체크리스트' : '텍스트',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: accent.darken(),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = .2]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
