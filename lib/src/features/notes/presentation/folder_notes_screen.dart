import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_note/src/data/models/folder.dart';
import 'package:simple_note/src/data/models/note.dart';
import 'package:simple_note/src/data/providers.dart';
import 'package:simple_note/src/features/notes/presentation/note_editor_screen.dart';

class FolderNotesScreen extends ConsumerWidget {
  const FolderNotesScreen({super.key, required this.folder});

  final Folder folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement a provider to get notes for this specific folder.
    // For now, we'll show an empty list.
    final notes = <Note>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
      ),
      body: notes.isEmpty
          ? const Center(
              child: Text('아직 노트가 없습니다.'),
            )
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  title: Text(note.title),
                  subtitle: Text(note.body ?? ''),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NoteEditorScreen(note: note),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteEditorScreen(folder: folder),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: '새 노트',
      ),
    );
  }
}
