import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_note/src/data/models/folder.dart';
import 'package:simple_note/src/data/providers.dart';
import 'package:simple_note/src/features/common/presentation/empty_state_widget.dart';
import 'package:simple_note/src/features/notes/presentation/folder_notes_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _showAddFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('새 폴더 추가'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '폴더 이름'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final folder = Folder()..name = controller.text;
                  ref.read(folderRepositoryProvider).saveFolder(folder);
                  Navigator.pop(context);
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersStream = ref.watch(foldersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('폴더'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddFolderDialog(context, ref),
            tooltip: '새 폴더',
          )
        ],
      ),
      body: foldersStream.when(
        data: (folders) {
          if (folders.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.create_new_folder_outlined,
              message: '폴더가 없습니다.\n오른쪽 상단의 + 버튼을 눌러\n새 폴더를 추가해보세요.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return FolderCard(folder: folder);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
      ),
    );
  }
}

class FolderCard extends ConsumerStatefulWidget {
  const FolderCard({super.key, required this.folder});

  final Folder folder;

  @override
  ConsumerState<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends ConsumerState<FolderCard> {
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    final notesCountStream = ref.watch(notesInFolderProvider(widget.folder.id));

    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => setState(() => _isTapped = false),
      onTapCancel: () => setState(() => _isTapped = false),
      onTap: () {
        Future.delayed(const Duration(milliseconds: 100), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FolderNotesScreen(folder: widget.folder),
              ),
            );
        });
      },
      child: AnimatedScale(
        scale: _isTapped ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.folder_outlined, size: 40),
                const Spacer(),
                Text(
                  widget.folder.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                notesCountStream.when(
                  data: (notes) => Text('${notes.length}개 항목'),
                  loading: () => const Text('...'),
                  error: (_, __) => const Text('-'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
