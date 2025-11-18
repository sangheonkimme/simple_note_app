import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:novita/src/data/models/attachment.dart';
import 'package:novita/src/data/models/checklist_item.dart';
import 'package:novita/src/data/models/folder.dart';
import 'package:novita/src/data/models/note.dart';
import 'package:novita/src/data/models/tag.dart';
import 'package:novita/src/data/providers.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.note, this.folder});

  final Note? note;
  final Folder? folder;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late NoteType _noteType;
  late List<ChecklistItem> _checklistItems;
  late List<Tag> _selectedTags;

  final List<Attachment> _existingAttachments = [];
  final List<Attachment> _newAttachments = [];
  final List<Attachment> _deletedAttachments = [];

  @override
  void initState() {
    super.initState();
    widget.note?.tags.loadSync();
    widget.note?.attachments.loadSync();

    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    _noteType = widget.note?.type ?? NoteType.text;
    _checklistItems = widget.note?.checklistItems.map((item) => ChecklistItem()..text = item.text..done = item.done).toList() ?? [];
    _selectedTags = widget.note?.tags.toList() ?? [];
    _existingAttachments.addAll(widget.note?.attachments ?? []);
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
    if (_noteType == NoteType.text) {
      noteToSave.body = body;
    } else {
      noteToSave.checklistItems = _checklistItems.where((item) => item.text.isNotEmpty).toList();
      noteToSave.body = null;
    }
    noteToSave.updatedAt = DateTime.now();

    final folder = widget.folder ?? widget.note?.folder.value;

    noteRepository.saveNote(
      noteToSave, 
      _newAttachments, 
      _deletedAttachments,
      folder: folder, 
      tags: _selectedTags
    ).then((_) {
       // Log note creation event
      if (widget.note == null) { // Only log for new notes
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

  void _showTagSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('태그 선택'),
        contentPadding: const EdgeInsets.all(16.0),
        content: TagSelectionContent(
          allTagsProvider: tagsStreamProvider,
          selectedTags: _selectedTags,
          onTagSelected: (tag) => setState(() {
            if (_selectedTags.any((t) => t.id == tag.id)) {
              _selectedTags.removeWhere((t) => t.id == tag.id);
            } else {
              _selectedTags.add(tag);
            }
          }),
          onTagCreated: (tagName) async {
            final tag = await ref.read(tagRepositoryProvider).getOrCreateTag(tagName);
            setState(() {
              if (!_selectedTags.any((t) => t.id == tag.id)) _selectedTags.add(tag);
            });
          },
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('완료'))],
      ),
    );
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
              _FrostedField(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: '제목을 입력하세요'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  maxLines: 1,
                ),
              ),
              const SizedBox(height: 16),
              _TagEditor(
                selectedTags: _selectedTags,
                onTagDeleted: (tag) => setState(() => _selectedTags.remove(tag)),
                onAddTag: _showTagSelectionDialog,
              ),
              const SizedBox(height: 12),
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

class _TagEditor extends StatelessWidget {
  final List<Tag> selectedTags;
  final Function(Tag) onTagDeleted;
  final VoidCallback onAddTag;

  const _TagEditor({required this.selectedTags, required this.onTagDeleted, required this.onAddTag});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: selectedTags.isEmpty
          ? TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              onPressed: onAddTag,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('태그 추가...'),
            )
          : Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ...selectedTags.map(
                  (tag) => Chip(
                    label: Text(tag.name),
                    onDeleted: () => onTagDeleted(tag),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('추가'),
                  onPressed: onAddTag,
                ),
              ],
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

class TagSelectionContent extends ConsumerWidget {
  final StreamProvider<List<Tag>> allTagsProvider;
  final List<Tag> selectedTags;
  final Function(Tag) onTagSelected;
  final Function(String) onTagCreated;

  const TagSelectionContent({super.key, required this.allTagsProvider, required this.selectedTags, required this.onTagSelected, required this.onTagCreated});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsStream = ref.watch(allTagsProvider);
    final newTagController = TextEditingController();

    return SizedBox(
      width: double.maxFinite,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: newTagController, decoration: InputDecoration(hintText: '새 태그 생성 또는 검색', suffixIcon: IconButton(icon: const Icon(Icons.add), onPressed: () {
            if (newTagController.text.isNotEmpty) { onTagCreated(newTagController.text); newTagController.clear(); }
          }))),
          const SizedBox(height: 16),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
              child: tagsStream.when(
                data: (tags) => ListView.builder(shrinkWrap: true, itemCount: tags.length, itemBuilder: (context, index) {
                  final tag = tags[index];
                  return CheckboxListTile(title: Text(tag.name), value: selectedTags.any((t) => t.id == tag.id), onChanged: (_) => onTagSelected(tag));
                }),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => const Center(child: Text('태그를 불러올 수 없습니다.')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
