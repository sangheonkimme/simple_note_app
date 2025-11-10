import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_note/src/data/providers.dart';
import 'package:simple_note/src/features/common/presentation/empty_state_widget.dart';
import 'package:simple_note/src/features/notes/presentation/home_screen.dart'; // For NoteCard

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: '노트 제목, 내용, 태그 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                ref.read(searchQueryProvider.notifier).state = query;
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: searchResults.when(
                data: (notes) {
                  if (searchQuery.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.search_outlined,
                      message: '노트의 제목, 내용 또는\n태그를 검색하여 노트를 찾아보세요.',
                    );
                  }
                  if (notes.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.search_off_outlined,
                      message: '검색 결과가 없습니다.',
                    );
                  }
                  return ListView.builder(
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return NoteCard(note: note);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
