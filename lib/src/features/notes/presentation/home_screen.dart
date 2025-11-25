import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/notes/presentation/folder_notes_screen.dart';
import 'package:novita/src/features/notes/presentation/note_editor_screen.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersStream = ref.watch(foldersStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: foldersStream.when(
          data: (folders) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: _HomeHeader(),
                        ),
                        const SizedBox(height: 32),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: AvailableSpaceCard(),
                        ),
                        const SizedBox(height: 32),
                        const _PinnedNotesSection(), // Pinned notes horizontal slider
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Folders',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              IconButton(
                                onPressed: () => _showCreateFolderDialog(context, ref),
                                icon: Icon(Icons.add_circle_outline_rounded, color: Theme.of(context).colorScheme.primary),
                                style: IconButton.styleFrom(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16.0,
                    crossAxisSpacing: 16.0,
                    childCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      return FolderCard(folder: folder);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 폴더 만들기'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '폴더 이름',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final folder = Folder()..name = name;
                await ref.read(folderRepositoryProvider).saveFolder(folder);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('만들기'),
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Novita',
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 24,
          backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=68'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
      ],
    );
  }
}

class AvailableSpaceCard extends ConsumerWidget {
  const AvailableSpaceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageInfo = ref.watch(storageInfoProvider);

    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withAlpha((255 * 0.25).round()),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            const Color(0xFF8E72FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha((255 * 0.1).round()),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha((255 * 0.08).round()),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: storageInfo.when(
              data: (info) {
                final usedSpace = info.usedSpaceGB.toStringAsFixed(1);
                final totalSpace = info.totalSpaceGB.toStringAsFixed(0);
                final percent = info.usedSpaceGB / info.totalSpaceGB;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((255 * 0.2).round()),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.cloud_queue_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cloud Storage',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withAlpha((255 * 0.9).round()),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'My Plan',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$usedSpace GB used',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '$totalSpace GB total',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withAlpha((255 * 0.8).round()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha((255 * 0.15).round()),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percent.clamp(0.0, 1.0),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withAlpha((255 * 0.4).round()),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  error: (_, __) => const Text('Unavailable', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
  }
}

class _PinnedNotesSection extends ConsumerWidget {
  const _PinnedNotesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinnedNotesAsync = ref.watch(pinnedNotesStreamProvider);
    
    return pinnedNotesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return const SizedBox.shrink(); // Don't show the section if there are no pinned notes
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Pinned Notes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140, // Height for the horizontal list
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 24 : 16,
                      right: index == notes.length - 1 ? 24 : 0,
                    ),
                    child: _PinnedNoteCard(note: note),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 140, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => const SizedBox.shrink(), // Don't show on error either
    );
  }
}

class _PinnedNoteCard extends StatelessWidget {
  const _PinnedNoteCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(note: note),
          ),
        );
      },
      child: Container(
        width: 160, // Width of each card
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha((255 * 0.5).round()),
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (note.body != null && note.body!.isNotEmpty)
              Expanded(
                child: Text(
                  note.body!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
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
  bool _isPressed = false;

  static const Map<String, ({IconData icon, Color color})> _folderStyles = {
    '개인': (icon: Icons.person_outline_rounded, color: Color(0xFF4E8EFF)),
    '업무': (icon: Icons.work_outline_rounded, color: Color(0xFF34C759)),
    '학업': (icon: Icons.school_outlined, color: Color(0xFFFF9F0A)),
    '기타': (icon: Icons.folder_open_rounded, color: Color(0xFFFF3B30)),
  };

  @override
  Widget build(BuildContext context) {
    final notesCountStream = ref.watch(notesInFolderProvider(widget.folder.id));
    
    final style = _folderStyles[widget.folder.name] ??
        (icon: Icons.folder_outlined, color: Theme.of(context).colorScheme.primary);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FolderNotesScreen(folder: widget.folder),
          ),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((255 * 0.03).round()),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: style.color.withAlpha((255 * 0.1).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 24),
              ),
              const SizedBox(height: 40), // Fixed height instead of Spacer for Masonry layout
              Text(
                widget.folder.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              notesCountStream.when(
                data: (notes) => Text(
                  '${notes.length} files',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                loading: () => const SizedBox(height: 14),
                error: (_, __) => const SizedBox(height: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
