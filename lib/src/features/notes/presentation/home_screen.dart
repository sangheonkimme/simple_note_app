import 'package:flutter/material.dart';
import 'package:simple_note/src/features/notes/presentation/note_editor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 노트'),
      ),
      body: const Center(
        child: Text('아직 노트가 없습니다.'), // TODO: 노트 목록 표시
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoteEditorScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: '새 노트',
      ),
    );
  }
}
