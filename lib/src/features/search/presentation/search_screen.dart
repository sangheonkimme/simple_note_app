import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/common/presentation/empty_state_widget.dart';
import 'package:novita/src/features/common/presentation/note_card.dart';
import 'package:novita/src/features/notes/presentation/note_editor_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '메모 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),
          Expanded(
            child: searchResults.when(
              data: (notes) {
                if (_searchController.text.isEmpty) {
                  // Show all notes when search is empty
                  return Consumer(
                    builder: (context, ref, child) {
                      final allNotesAsync = ref.watch(allNotesStreamProvider);
                      return allNotesAsync.when(
                        data: (notes) => ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            final note = notes[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: NoteCard(
                                note: note,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NoteEditorScreen(note: note),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      );
                    },
                  );
                }

                if (notes.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.search_off,
                    title: '검색 결과가 없습니다',
                    subtitle: '"${_searchController.text}"에 대한 결과를 찾을 수 없습니다',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: NoteCard(
                        note: note,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteEditorScreen(note: note),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
