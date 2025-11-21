import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/common/presentation/empty_state_widget.dart';
import 'package:novita/src/features/common/presentation/note_card.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultProvider);

    final suggestionChips = ['회의록', '아이디어', '태그:업무', '체크리스트'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('노트 검색'),
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '제목, 내용, 태그로 검색',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                        )
                      : null,
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
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final chipLabel = suggestionChips[index];
                  final isSelected = chipLabel == searchQuery;
                  return ChoiceChip(
                    label: Text(chipLabel),
                    selected: isSelected,
                    showCheckmark: false,
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.onPrimaryContainer 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: isSelected ? BorderSide.none : BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                    onSelected: (_) {
                      ref.read(searchQueryProvider.notifier).state = chipLabel;
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: suggestionChips.length,
              ),
            ),
            const SizedBox(height: 12),
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
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.82,
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
      ),
    );
  }
}
