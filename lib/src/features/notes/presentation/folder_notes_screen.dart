import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/providers.dart';
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
          print('🔍 DEBUG FolderNotesScreen: Got ${notes.length} notes for folder ${folder.name} (id: ${folder.id})');
          for (var i = 0; i < notes.length && i < 3; i++) {
            print('🔍 DEBUG Note $i: id=${notes[i].id}, title="${notes[i].title}"');
          }
          
          if (notes.isEmpty) {
            print('🔍 DEBUG: Showing empty state message');
            return const Center(
              child: Text('작성된 노트가 없습니다.'),
            );
          }
          
          print('🔍 DEBUG: Rendering grid with ${notes.length} notes');
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
        loading: () {
          print('🔍 DEBUG FolderNotesScreen: Stream is LOADING for folder ${folder.name} (id: ${folder.id})');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('🔍 DEBUG FolderNotesScreen: Stream ERROR for folder ${folder.name} (id: ${folder.id})');
          print('🔍 DEBUG Error: $error');
          print('🔍 DEBUG Stack: $stack');
          return Center(child: Text('Error: $error'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewNote(context, ref),
        backgroundColor: const Color(0xFF7A5CFF),
        child: const Icon(Icons.add, color: Colors.white),
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
