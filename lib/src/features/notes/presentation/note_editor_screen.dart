import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:novita/src/data/models/attachment.dart';
import 'package:novita/src/data/models/checklist_item.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/providers.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.note, this.folder, this.initialNoteType = NoteType.text});

  final Note? note;
  final Folder? folder;
  final NoteType initialNoteType;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late NoteType _noteType;
  late bool _isPinned;
  late List<ChecklistItem> _checklistItems;
  Folder? _selectedFolder;

  final List<Attachment> _existingAttachments = [];
  final List<Attachment> _newAttachments = [];
  final List<Attachment> _deletedAttachments = [];

  @override
  void initState() {
    super.initState();
    widget.note?.attachments.loadSync();

    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    _noteType = widget.note?.type ?? widget.initialNoteType;
    _isPinned = widget.note?.pinned ?? false;
    _checklistItems = widget.note?.checklistItems.map((item) => ChecklistItem()..text = item.text..done = item.done).toList() ?? [];
    _existingAttachments.addAll(widget.note?.attachments ?? []);
    _selectedFolder = widget.folder ?? widget.note?.folder.value;
    
    if (_selectedFolder == null) {
      _loadDefaultFolder();
    }
  }

  Future<void> _loadDefaultFolder() async {
    final folders = await ref.read(folderRepositoryProvider).watchAllFolders().first;
    if (mounted) {
      setState(() {
        _selectedFolder = folders.cast<Folder?>().firstWhere(
          (f) => f?.name == '기타',
          orElse: () => folders.isNotEmpty ? folders.first : null,
        );
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final attachmentService = ref.read(attachmentServiceProvider);
    final newAttachment = await attachmentService.pickImage(source);
    if (newAttachment != null && mounted) {
      setState(() {
        _newAttachments.add(newAttachment);
      });
    }
  }

  void _saveNote() {
    final title = _titleController.text;
    final body = _bodyController.text;

    if (title.isEmpty && body.isEmpty && _checklistItems.every((item) => item.text.isEmpty) && _existingAttachments.isEmpty && _newAttachments.isEmpty) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final noteRepository = ref.read(noteRepositoryProvider);
    final noteToSave = widget.note ?? Note();

    noteToSave.title = title;
    noteToSave.type = _noteType;
    noteToSave.pinned = _isPinned;
    if (_noteType == NoteType.text) {
      noteToSave.body = body;
    } else {
      noteToSave.checklistItems = _checklistItems.where((item) => item.text.isNotEmpty).toList();
      noteToSave.body = null;
    }
    noteToSave.updatedAt = DateTime.now();

    noteToSave.updatedAt = DateTime.now();
    
    final folder = _selectedFolder;

    noteRepository.saveNote(
      noteToSave, 
      _newAttachments, 
      _deletedAttachments,
      folder: _selectedFolder
    ).then((_) {
      if (widget.note == null) {
        ref.read(analyticsServiceProvider).logNoteCreated(
          folder: folder?.name ?? 'Uncategorized',
          hasImage: (_existingAttachments.isNotEmpty || _newAttachments.isNotEmpty),
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _addChecklistItem() => setState(() => _checklistItems.add(ChecklistItem()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.note == null ? '새 노트' : '노트 편집',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              '아이디어를 자유롭게 적어보세요',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton.filledTonal(
            tooltip: '이미지 첨부',
            onPressed: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              builder: (context) => SafeArea(
                child: Wrap(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.photo_library),
                      title: const Text('갤러리에서 선택'),
                      onTap: () {
                        _pickImage(ImageSource.gallery);
                        Navigator.of(context).pop();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.photo_camera),
                      title: const Text('카메라로 촬영'),
                      onTap: () {
                        _pickImage(ImageSource.camera);
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: _isPinned ? '고정 해제' : '고정',
            onPressed: () {
              // For an existing note, also update the database immediately
              if (widget.note != null) {
                ref.read(noteRepositoryProvider).togglePinStatus(widget.note!.id);
              }
              // For both new and existing notes, update the local UI state
              setState(() {
                _isPinned = !_isPinned;
              });
            },
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: '저장',
            onPressed: _saveNote,
            icon: const Icon(Icons.check_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            children: [
              _FolderSelector(
                selectedFolder: _selectedFolder,
                onFolderSelected: (folder) => setState(() => _selectedFolder = folder),
              ),
              const SizedBox(height: 8),
              _FrostedField(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: '제목을 입력하세요'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<NoteType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: NoteType.text, label: Text('텍스트'), icon: Icon(Icons.notes_rounded)),
                  ButtonSegment(value: NoteType.checklist, label: Text('체크리스트'), icon: Icon(Icons.checklist_rounded)),
                ],
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                  textStyle: WidgetStateProperty.all(const TextStyle(fontWeight: FontWeight.w600)),
                ),
                selected: {_noteType},
                onSelectionChanged: (value) => setState(() => _noteType = value.first),
              ),
              const SizedBox(height: 16),
              _AttachmentEditor( 
                existingAttachments: _existingAttachments,
                newAttachments: _newAttachments,
                onAttachmentDeleted: (attachment) => setState(() {
                  if (_newAttachments.contains(attachment)) {
                    _newAttachments.remove(attachment);
                  } else if (_existingAttachments.contains(attachment)) {
                    _existingAttachments.remove(attachment);
                    _deletedAttachments.add(attachment);
                  }
                }),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: _noteType == NoteType.text
                      ? _TextEditorBody(controller: _bodyController)
                      : _ChecklistEditorBody(
                          items: _checklistItems,
                          onAddItem: _addChecklistItem,
                          onItemChanged: (item, value) => setState(() => item.done = value),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _AttachmentEditor extends StatelessWidget {
  final List<Attachment> existingAttachments;
  final List<Attachment> newAttachments;
  final Function(Attachment) onAttachmentDeleted;

  const _AttachmentEditor({required this.existingAttachments, required this.newAttachments, required this.onAttachmentDeleted});

  @override
  Widget build(BuildContext context) {
    final allAttachments = [...existingAttachments, ...newAttachments];
    if (allAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allAttachments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final attachment = allAttachments[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(attachment.filePath),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: GestureDetector(
                  onTap: () => onAttachmentDeleted(attachment),
                  child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TextEditorBody extends StatelessWidget {
  final TextEditingController controller;
  const _TextEditorBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        hintText: '내용을 입력하세요...',
        border: InputBorder.none,
      ),
      style: const TextStyle(fontSize: 16, height: 1.6),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      autofocus: false,
    );
  }
}

class _ChecklistEditorBody extends StatelessWidget {
  final List<ChecklistItem> items;
  final VoidCallback onAddItem;
  final Function(ChecklistItem, bool) onItemChanged;

  const _ChecklistEditorBody({required this.items, required this.onAddItem, required this.onItemChanged});

  @override
  Widget build(BuildContext context) {
    final controller = ScrollController();
    return Scrollbar(
      controller: controller,
      child: ListView.separated(
        controller: controller,
        padding: EdgeInsets.zero,
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return OutlinedButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add),
              label: const Text('항목 추가'),
            );
          }
          final item = items[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: item.done,
                  onChanged: (value) => onItemChanged(item, value ?? false),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: item.text,
                    onChanged: (value) => item.text = value,
                    decoration: const InputDecoration(
                      hintText: '할 일을 입력하세요',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FrostedField extends StatelessWidget {
  const _FrostedField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: child,
      ),
    );
  }
}

class _FolderSelector extends ConsumerWidget {
  final Folder? selectedFolder;
  final Function(Folder) onFolderSelected;

  const _FolderSelector({required this.selectedFolder, required this.onFolderSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersStreamProvider);

    return foldersAsync.when(
      data: (folders) {
        if (folders.isEmpty) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.folder_open_rounded, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              PopupMenuButton<Folder>(
                initialValue: selectedFolder,
                onSelected: onFolderSelected,
                itemBuilder: (context) {
                  return folders.map((folder) {
                    return PopupMenuItem<Folder>(
                      value: folder,
                      child: Text(folder.name),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedFolder?.name ?? '폴더 선택',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down_rounded, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
