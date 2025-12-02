import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/common/presentation/empty_state_widget.dart';
import 'package:novita/src/features/common/presentation/note_card.dart';
import 'package:novita/src/features/notes/presentation/note_editor_screen.dart';

class FolderNotesScreen extends ConsumerWidget {
  final Folder folder;

  const FolderNotesScreen({super.key, required this.folder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesStream = ref.watch(notesInFolderProvider(folder.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement folder options
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: notesStream.when(
        data: (notes) {
          if (notes.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.note_add_outlined,
              title: '메모가 없습니다',
              subtitle: '새로운 메모를 추가해보세요',
              action: FilledButton.icon(
                onPressed: () => _createNewNote(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('메모 추가'),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return NoteCard(
                  note: note,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteEditorScreen(note: note),
                      ),
                    );
                  },
                  onLongPress: () => _showNoteOptions(context, ref, note),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewNote(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _createNewNote(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(folder: folder),
      ),
    );
  }

  void _showNoteOptions(BuildContext context, WidgetRef ref, Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(note.isPinned ? '고정 해제' : '고정'),
              onTap: () {
                ref.read(noteRepositoryProvider).togglePinStatus(note.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(note.isFavorite ? Icons.star_outline : Icons.star),
              title: Text(note.isFavorite ? '즐겨찾기 해제' : '즐겨찾기'),
              onTap: () {
                ref.read(noteRepositoryProvider).toggleFavoriteStatus(note.id);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('삭제'),
              onTap: () {
                ref.read(noteRepositoryProvider).softDeleteNote(note.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
