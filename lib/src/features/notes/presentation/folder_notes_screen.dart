import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/common/presentation/empty_state_widget.dart';
import 'package:novita/src/features/common/presentation/note_card.dart';
import 'package:novita/src/features/notes/presentation/note_editor_screen.dart';
import 'package:novita/src/features/search/presentation/search_screen.dart';

class FolderNotesScreen extends ConsumerWidget {
  const FolderNotesScreen({
    super.key,
    required this.folder,
    this.color,
  });

  final Folder folder;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesStream = ref.watch(notesInFolderProvider(folder.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // Navigate to the global search screen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            icon: const Icon(Icons.search),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notesStream.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const EmptyStateWidget(message: '노트가 없습니다.\n새 노트를 추가해보세요.', icon: Icons.note_add_outlined),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: NewNoteCard(folder: folder),
                  ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.8,
            ),
            itemCount: notes.length + 1, // +1 for the "New note" card
            itemBuilder: (context, index) {
              if (index == 0) {
                return NewNoteCard(folder: folder);
              }
              final note = notes[index - 1];
              return NoteCard(note: note);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => EmptyStateWidget(icon: Icons.error_outline, message: '오류가 발생했습니다.\n$error'),
      ),
    );
  }
}

class NewNoteCard extends StatelessWidget {
  const NewNoteCard({super.key, this.folder});

  final Folder? folder;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteEditorScreen(folder: folder)),
        );
      },
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 40, color: Theme.of(context).colorScheme.onPrimaryContainer),
              const SizedBox(height: 8),
              Text('New note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
            ],
          ),
        ),
      ),
    );
  }
}
