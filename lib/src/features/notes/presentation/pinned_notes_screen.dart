import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/common/presentation/note_list_tile.dart';

class PinnedNotesScreen extends ConsumerWidget {
  const PinnedNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedNotesStream = ref.watch(pinnedNotesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinned Notes'),
      ),
      body: pinnedNotesStream.when(
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.push_pin_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No pinned notes yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NoteListTile(note: note), // Reusing NoteListTile from folder_notes_screen.dart if available, otherwise I need to check
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
