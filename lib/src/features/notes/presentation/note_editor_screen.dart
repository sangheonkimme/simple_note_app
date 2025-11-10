import 'package:flutter/material.dart';

class NoteEditorScreen extends StatelessWidget {
  const NoteEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: 노트 저장 로직 구현
            },
            tooltip: '저장',
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: '제목',
                border: InputBorder.none,
              ),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              maxLines: 1,
            ),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: '내용을 입력하세요...',
                  border: InputBorder.none,
                ),
                maxLines: null, // Allows for multiline input
                expands: true, // Fills the available space
              ),
            ),
          ],
        ),
      ),
    );
  }
}
