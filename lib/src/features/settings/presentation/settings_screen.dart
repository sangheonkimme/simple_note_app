import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
              // Add other settings items here in the future
              // e.g., ListTile(title: const Text('다크 모드 설정')),
            ],
          );
        },
      ),
    );
  }
}
