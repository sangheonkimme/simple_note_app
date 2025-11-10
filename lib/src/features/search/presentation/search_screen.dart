import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: '노트 제목, 내용, 태그 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                // TODO: 검색 로직 실행
              },
            ),
            const Expanded(
              child: Center(
                child: Text('검색 결과를 여기에 표시합니다.'), // TODO: 검색 결과 목록 표시
              ),
            ),
          ],
        ),
      ),
    );
  }
}
