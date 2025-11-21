import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novita/src/data/providers.dart';
import 'package:novita/src/features/auth/data/auth_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<PackageInfo>? _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: FutureBuilder<PackageInfo>(
        future: _packageInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('정보를 불러올 수 없습니다.'));
          }

          final packageInfo = snapshot.data!;
          final appName = packageInfo.appName;
          final version = packageInfo.version;
          final buildNumber = packageInfo.buildNumber;

          return ListView(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    // Placeholder for App Icon
                    const Icon(Icons.note_alt_rounded, size: 80),
                    const SizedBox(height: 16),
                    Text(appName, style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ListTile(
                title: const Text('버전 정보'),
                subtitle: Text('$version ($buildNumber)'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.sync),
                title: const Text('지금 동기화'),
                onTap: () async {
                  final syncService = ref.read(syncServiceProvider);
                  await syncService.sync();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('동기화가 완료되었습니다.')),
                    );
                  }
                },
              ),
              const Divider(),
              FutureBuilder<bool>(
                future: ref.read(authRepositoryProvider).isGuest(),
                builder: (context, snapshot) {
                  final isGuest = snapshot.data ?? false;
                  return ListTile(
                    leading: Icon(isGuest ? Icons.login : Icons.logout, color: isGuest ? Colors.blue : Colors.red),
                    title: Text(
                      isGuest ? '로그인 / 회원가입' : '로그아웃',
                      style: TextStyle(color: isGuest ? Colors.blue : Colors.red),
                    ),
                    onTap: () async {
                      await ref.read(authStateProvider.notifier).logout();
                      // Navigation to AuthScreen is handled by main.dart's authState listener
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
