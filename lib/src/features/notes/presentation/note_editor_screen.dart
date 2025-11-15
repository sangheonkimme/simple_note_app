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
        actions: [
          IconButton(icon: const Icon(Icons.add_photo_alternate_outlined), onPressed: () => showModalBottomSheet(context: context, builder: (context) => SafeArea(child: Wrap(
            children: <Widget>[
              ListTile(leading: const Icon(Icons.photo_library), title: const Text('갤러리에서 선택'), onTap: () { _pickImage(ImageSource.gallery); Navigator.of(context).pop(); }),
              ListTile(leading: const Icon(Icons.photo_camera), title: const Text('카메라로 촬영'), onTap: () { _pickImage(ImageSource.camera); Navigator.of(context).pop(); }),
            ],
          ))), tooltip: '이미지 첨부'),
          IconButton(icon: Icon(_noteType == NoteType.text ? Icons.check_box_outline_blank : Icons.notes), onPressed: () => setState(() => _noteType = _noteType == NoteType.text ? NoteType.checklist : NoteType.text), tooltip: '모드 변경'),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveNote, tooltip: '저장'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: '제목', border: InputBorder.none),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            const Divider(height: 1),
            _TagEditor(selectedTags: _selectedTags, onTagDeleted: (tag) => setState(() => _selectedTags.remove(tag)), onAddTag: _showTagSelectionDialog),
            const Divider(height: 1),
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
            if (_existingAttachments.isNotEmpty || _newAttachments.isNotEmpty) const Divider(height: 1),
            Expanded(
              child: _noteType == NoteType.text
                  ? _TextEditorBody(controller: _bodyController)
                  : _ChecklistEditorBody(items: _checklistItems, onAddItem: _addChecklistItem, onItemChanged: (item, value) => setState(() => item.done = value)),
            ),
          ],
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
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: selectedTags.isEmpty
                ? Material(color: Colors.transparent, child: InkWell(onTap: onAddTag, child: Center(child: Text('태그 추가...', style: TextStyle(color: Colors.grey.shade600)))))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(spacing: 8.0, children: selectedTags.map((tag) => Chip(label: Text(tag.name), onDeleted: () => onTagDeleted(tag), visualDensity: VisualDensity.compact)).toList()),
                  ),
          ),
          IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onAddTag, tooltip: '태그 추가')
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
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allAttachments.length,
        itemBuilder: (context, index) {
          final attachment = allAttachments[index];
          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                width: 80, height: 80,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: FileImage(File(attachment.filePath)), fit: BoxFit.cover)),
              ),
              IconButton(
                constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                icon: const CircleAvatar(backgroundColor: Colors.black54, radius: 12, child: Icon(Icons.close, color: Colors.white, size: 14)),
                onPressed: () => onAttachmentDeleted(attachment),
              )
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
    return TextField(controller: controller, decoration: const InputDecoration(hintText: '내용을 입력하세요...', border: InputBorder.none), maxLines: null, expands: true, autofocus: false,);
  }
}

class _ChecklistEditorBody extends StatelessWidget {
  final List<ChecklistItem> items;
  final VoidCallback onAddItem;
  final Function(ChecklistItem, bool) onItemChanged;

  const _ChecklistEditorBody({required this.items, required this.onAddItem, required this.onItemChanged});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == items.length) {
          return TextButton.icon(icon: const Icon(Icons.add), label: const Text('항목 추가'), onPressed: onAddItem);
        }
        final item = items[index];
        return Row(
          children: [
            Checkbox(value: item.done, onChanged: (value) => onItemChanged(item, value ?? false)),
            Expanded(child: TextFormField(initialValue: item.text, onChanged: (value) => item.text = value, decoration: const InputDecoration(hintText: '할 일', border: InputBorder.none))),
          ],
        );
      },
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
