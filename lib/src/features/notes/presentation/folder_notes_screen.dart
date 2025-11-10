import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_note/src/data/models/folder.dart';
import 'package:simple_note/src/data/providers.dart';
import 'package:simple_note/src/features/common/presentation/empty_state_widget.dart';
import 'package:simple_note/src/features/notes/presentation/home_screen.dart'; // For NoteCard
import 'package:simple_note/src/features/notes/presentation/note_editor_screen.dart';

class FolderNotesScreen extends ConsumerWidget {
  const FolderNotesScreen({super.key, required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesStream = ref.watch(notesInFolderProvider(folder.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
      ),
      body: notesStream.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.note_add_outlined,
              message: '아직 노트가 없습니다.\n아래 버튼을 눌러 새 노트를 추가해보세요.',
            );
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Dismissible(
                key: Key(note.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  ref.read(noteRepositoryProvider).deleteNote(note.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('\"${note.title}\" 노트를 삭제했습니다.')),
                  );
                },
                child: NoteCard(note: note), // Re-using the NoteCard from HomeScreen
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(note: null, folder: folder),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: '새 노트',
      ),
    );
  }
}
