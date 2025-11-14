import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_note/src/data/models/folder.dart';
import 'package:simple_note/src/data/providers.dart';
import 'package:simple_note/src/features/notes/presentation/folder_notes_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersStream = ref.watch(foldersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
            Text('Novita', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              child: const Icon(Icons.person_outline),
            ),
          ),
        ],
      ),
      body: foldersStream.when(
        data: (folders) {
          return CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: AvailableSpaceCard(),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: folders.length,
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
        error: (error, stack) => Center(child: Text('오류가 발생했습니다: $error')),
      ),
    );
  }
}

class AvailableSpaceCard extends ConsumerWidget {
  const AvailableSpaceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageInfo = ref.watch(storageInfoProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: storageInfo.when(
              data: (info) {
                final usedSpace = info.usedSpaceGB.toStringAsFixed(2);
                final totalSpace = info.totalSpaceGB.toStringAsFixed(0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.pie_chart_outline, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Space',
                              style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$usedSpace GB of $totalSpace GB Used',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: info.usedSpaceGB / info.totalSpaceGB,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (err, stack) => const Text('Storage info not available', style: TextStyle(color: Colors.white)),
            ),
          ),
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
  bool _isTapped = false;

  // Define styles for default folders
  static const Map<String, ({IconData icon, Color color})> _folderStyles = {
    '개인': (icon: Icons.person_outline, color: Colors.blue),
    '업무': (icon: Icons.business_center_outlined, color: Colors.green),
    '학업': (icon: Icons.school_outlined, color: Colors.orange),
    '기타': (icon: Icons.inbox_outlined, color: Colors.purple),
  };

  @override
  Widget build(BuildContext context) {
    final notesCountStream = ref.watch(notesInFolderProvider(widget.folder.id));

    // Get style for the current folder, or a default if not found
    final style = _folderStyles[widget.folder.name] ??
        (icon: Icons.folder_open_outlined, color: Theme.of(context).colorScheme.primary);
    
    final iconColor = style.color;
    final backgroundColor = style.color.withOpacity(0.1);

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
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24.0),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(style.icon, size: 40, color: iconColor),
              const Spacer(),
              Text(
                widget.folder.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              notesCountStream.when(
                data: (notes) => Text('${notes.length} files', style: Theme.of(context).textTheme.bodySmall),
                loading: () => Text('...', style: Theme.of(context).textTheme.bodySmall),
                error: (_, __) => Text('-', style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
