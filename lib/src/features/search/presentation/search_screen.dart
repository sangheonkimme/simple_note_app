import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_note/src/data/providers.dart';
import 'package:simple_note/src/features/common/presentation/empty_state_widget.dart';
import 'package:simple_note/src/features/common/presentation/note_card.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('노트 검색'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              autofocus: true, // Immediately focus the search bar
              decoration: InputDecoration(
                hintText: '제목, 내용, 태그로 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none, // No border
                ),
              ),
              onChanged: (query) {
                ref.read(searchQueryProvider.notifier).state = query;
              },
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  ref.read(analyticsServiceProvider).logSearch(query);
                }
              },
            ),
          ),
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
                // Use a GridView for consistency
                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return NoteCard(note: note);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => EmptyStateWidget(
                icon: Icons.error_outline,
                message: '오류가 발생했습니다.\n$error',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
