import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/common/presentation/empty_state_widget.dart';
import 'package:novita/src/features/common/presentation/note_card.dart';
import 'package:novita/src/features/notes/presentation/note_editor_screen.dart';
import 'package:novita/src/features/search/presentation/search_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
        title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        actions: [
          IconButton.filledTonal(
            onPressed: () {
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
          return MasonryGridView.count(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            crossAxisCount: 2,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
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
        height: 200, // Fixed height for Masonry layout
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26.0),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, size: 44, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                'New note',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
