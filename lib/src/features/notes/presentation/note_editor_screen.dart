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
  const NoteEditorScreen({
    super.key,
    this.note,
    this.folder,
    this.initialNoteType = NoteType.text,
  });

  final Note? note;
  final Folder? folder;
  final NoteType initialNoteType;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final FocusNode _contentFocusNode;
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
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

    _contentFocusNode = FocusNode();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _noteType = widget.note?.type ?? widget.initialNoteType;
    _isPinned = widget.note?.isPinned ?? false;
    _checklistItems = widget.note?.checklistItems
            .map((item) => ChecklistItem()
              ..content = item.content
              ..isCompleted = item.isCompleted)
            .toList() ??
        [];
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
    _contentController.dispose();
    _contentFocusNode.dispose();
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
    final content = _contentController.text;

    if (title.isEmpty &&
        content.isEmpty &&
        _checklistItems.every((item) => item.content.isEmpty) &&
        _existingAttachments.isEmpty &&
        _newAttachments.isEmpty) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final noteRepository = ref.read(noteRepositoryProvider);
    final noteToSave = widget.note ?? Note();

    noteToSave.title = title.isNotEmpty ? title : '제목 없음';
    noteToSave.type = _noteType;
    noteToSave.isPinned = _isPinned;
    if (_noteType == NoteType.text) {
      noteToSave.content = content;
    } else {
      noteToSave.checklistItems =
          _checklistItems.where((item) => item.content.isNotEmpty).toList();
      noteToSave.content = null;
    }
    noteToSave.updatedAt = DateTime.now();

    final folder = _selectedFolder;

    noteRepository
        .saveNote(
      noteToSave,
      _newAttachments,
      _deletedAttachments,
      folder: _selectedFolder,
    )
        .then((_) async {
      if (widget.note == null) {
        ref.read(analyticsServiceProvider).logNoteCreated(
              folder: folder?.name ?? 'Uncategorized',
              hasImage: (_existingAttachments.isNotEmpty || _newAttachments.isNotEmpty),
            );
      }

      // Auto sync after saving note
      try {
        await ref.read(syncServiceProvider).sync();
      } catch (e) {
        debugPrint('Auto sync failed: $e');
      }

      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _addChecklistItem() => setState(() => _checklistItems.add(ChecklistItem()));

  void _toggleNoteType() {
    setState(() {
      if (_noteType == NoteType.text) {
        _noteType = NoteType.checklist;
        if (_checklistItems.isEmpty && _contentController.text.isNotEmpty) {
          final lines = _contentController.text.split('\n');
          _checklistItems = lines.map((l) => ChecklistItem()..content = l).toList();
        }
      } else {
        _noteType = NoteType.text;
        if (_contentController.text.isEmpty && _checklistItems.isNotEmpty) {
          _contentController.text = _checklistItems.map((i) => i.content).join('\n');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saveNote,
        ),
        actions: [
          IconButton(
            tooltip: _isPinned ? '고정 해제' : '고정',
            onPressed: () {
              if (widget.note != null) {
                ref.read(noteRepositoryProvider).togglePinStatus(widget.note!.id);
              }
              setState(() {
                _isPinned = !_isPinned;
              });
            },
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
          IconButton(
            tooltip: '저장',
            onPressed: _saveNote,
            icon: const Icon(Icons.check),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _FolderSelector(
                selectedFolder: _selectedFolder,
                onFolderSelected: (folder) => setState(() => _selectedFolder = folder),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: '제목',
                              border: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintStyle: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey),
                            ),
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                            maxLines: null,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 8),
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
                        ],
                      ),
                    ),
                  ),
                  if (_noteType == NoteType.text)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverFillRemaining(
                        hasScrollBody: false,
                        child: GestureDetector(
                          onTap: () => _contentFocusNode.requestFocus(),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: _TextEditorBody(
                              controller: _contentController,
                              focusNode: _contentFocusNode,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverToBoxAdapter(
                        child: _ChecklistEditorBody(
                          items: _checklistItems,
                          onAddItem: _addChecklistItem,
                          onItemChanged: (item, value) =>
                              setState(() => item.isCompleted = value),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          children: [
            IconButton(
              tooltip: '이미지 첨부',
              icon: const Icon(Icons.add_photo_alternate_outlined),
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
            ),
            IconButton(
              tooltip: _noteType == NoteType.text ? '체크리스트로 변경' : '텍스트로 변경',
              icon: Icon(_noteType == NoteType.text
                  ? Icons.checklist_rtl_rounded
                  : Icons.notes_rounded),
              onPressed: _toggleNoteType,
            ),
            const Spacer(),
            Text(
              '편집 중...',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _AttachmentEditor extends StatelessWidget {
  final List<Attachment> existingAttachments;
  final List<Attachment> newAttachments;
  final Function(Attachment) onAttachmentDeleted;

  const _AttachmentEditor({
    required this.existingAttachments,
    required this.newAttachments,
    required this.onAttachmentDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final allAttachments = [...existingAttachments, ...newAttachments];
    if (allAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: allAttachments.length,
        separatorBuilder: (_, i) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final attachment = allAttachments[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(attachment.url),
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: GestureDetector(
                  onTap: () => onAttachmentDeleted(attachment),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
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
  final FocusNode focusNode;

  const _TextEditorBody({required this.controller, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: const InputDecoration(
        hintText: '내용을 입력하세요...',
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(fontSize: 16, height: 1.5),
      maxLines: null,
      scrollPhysics: const NeverScrollableScrollPhysics(),
    );
  }
}

class _ChecklistEditorBody extends StatelessWidget {
  final List<ChecklistItem> items;
  final VoidCallback onAddItem;
  final Function(ChecklistItem, bool) onItemChanged;

  const _ChecklistEditorBody({
    required this.items,
    required this.onAddItem,
    required this.onItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: item.isCompleted,
                      onChanged: (value) => onItemChanged(item, value ?? false),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      initialValue: item.content,
                      onChanged: (value) => item.content = value,
                      decoration: const InputDecoration(
                        hintText: '할 일',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        color: item.isCompleted ? Colors.grey : null,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        TextButton.icon(
          onPressed: onAddItem,
          icon: const Icon(Icons.add),
          label: const Text('항목 추가'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.primary,
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
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
          margin: const EdgeInsets.only(bottom: 0),
          child: Row(
            children: [
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
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
    );
  }
}
