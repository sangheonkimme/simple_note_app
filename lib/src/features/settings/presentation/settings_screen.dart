import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/auth/data/auth_provider.dart';
import 'package:novita/src/features/auth/presentation/auth_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final isLoggedIn = user != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // Profile Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: isLoggedIn && user.picture != null
                          ? NetworkImage(user.picture!)
                          : null,
                      child: isLoggedIn && user.picture != null
                          ? null
                          : const Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn ? user.name : 'Guest',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (isLoggedIn)
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    if (!isLoggedIn)
                      FilledButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                          );
                        },
                        child: const Text('로그인'),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(),

          // Storage Section
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('저장 공간'),
            subtitle: Consumer(
              builder: (context, ref, child) {
                final storageInfo = ref.watch(storageInfoProvider);
                return storageInfo.when(
                  data: (info) => Text(
                    '${info.usedSpaceGB.toStringAsFixed(2)} GB / ${info.totalSpaceGB.toStringAsFixed(0)} GB 사용 중',
                  ),
                  loading: () => const Text('로딩 중...'),
                  error: (e, _) => const Text('정보를 불러올 수 없습니다'),
                );
              },
            ),
          ),

          // Sync Section
          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.sync_outlined),
              title: const Text('동기화'),
              subtitle: const Text('마지막 동기화: 방금 전'),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  try {
                    await ref.read(syncServiceProvider).sync();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('동기화 완료')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('동기화 실패: $e')),
                      );
                    }
                  }
                },
              ),
            ),

          const Divider(),

          // App Info Section
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: const Text('앱 정보'),
            subtitle: const Text('버전 1.0.0'),
          ),

          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('도움말'),
            onTap: () {
              // TODO: Open help page
            },
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보 처리방침'),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),

          const Divider(),

          // Logout Section
          if (isLoggedIn)
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('정말 로그아웃 하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(authStateProvider.notifier).logout();
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('로그아웃'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
