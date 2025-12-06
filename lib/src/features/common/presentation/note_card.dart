import 'dart:io';

import 'package:flutter/material.dart';
import 'package:novita/src/data/models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Badge and Pin
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: note.type == NoteType.checklist
                          ? const Color(0xFFFFF7ED) // Orange-50
                          : const Color(0xFFEFF6FF), // Blue-50
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          note.type == NoteType.checklist
                              ? Icons.check_circle_outline
                              : Icons.description_outlined,
                          size: 14,
                          color: note.type == NoteType.checklist
                              ? const Color(0xFFF97316) // Orange-500
                              : const Color(0xFF3B82F6), // Blue-500
                        ),
                        const SizedBox(width: 4),
                        Text(
                          note.type == NoteType.checklist ? '체크리스트' : '텍스트',
                          style: TextStyle(
                            color: note.type == NoteType.checklist
                                ? const Color(0xFFF97316)
                                : const Color(0xFF3B82F6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (note.isPinned)
                    Icon(
                      Icons.push_pin,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                note.title.isNotEmpty ? note.title : '제목 없음',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Image Preview
              if (note.attachments.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(note.attachments.first.url),
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Content or Checklist Preview
              if (note.type == NoteType.checklist) ...[
                if (note.checklistItems.isNotEmpty)
                  ...note.checklistItems.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              item.isCompleted
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              size: 14,
                              color: item.isCompleted
                                  ? const Color(0xFFF97316)
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.content,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: item.isCompleted
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                if (note.checklistItems.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '+ ${note.checklistItems.length - 3}개 더보기',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
              ] else if (note.content != null && note.content!.isNotEmpty)
                Text(
                  note.content!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 12),

              // Bottom Row: Date and Completion Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(note.updatedAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (note.type == NoteType.checklist &&
                      note.checklistItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${note.checklistItems.where((i) => i.isCompleted).length}/${note.checklistItems.length} 완료',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
