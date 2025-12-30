import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:notedown/controller/note_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String? appVersion;
  String? appName;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = packageInfo.version;
        appName = packageInfo.appName;
      });
    } catch (e) {
      // Handle error gracefully
      setState(() {
        appVersion = '1.0.0';
        appName = 'NoteDown';
      });
    }
  }

  int getTotalNotes() {
    return Boxes.getNotes().length;
  }

  int getArchivedNotes() {
    return Boxes.getNotes()
        .values
        .where((note) => note.archived == true)
        .length;
  }

  int getActiveNotes() {
    return Boxes.getNotes()
        .values
        .where((note) => !(note.archived ?? false))
        .length;
  }

  String getTotalCharacters() {
    int total = 0;
    for (var note in Boxes.getNotes().values) {
      if (note.content != null) {
        total += note.content!.length;
      }
    }
    if (total > 1000) {
      return '${(total / 1000).toStringAsFixed(1)}K';
    }
    return total.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Analytics Section
          _buildSectionHeader('Analytics'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _buildStatTile(
                  icon: Icons.note_outlined,
                  title: 'Total Notes',
                  value: getTotalNotes().toString(),
                ),
                const Divider(height: 1),
                _buildStatTile(
                  icon: Icons.folder_outlined,
                  title: 'Active Notes',
                  value: getActiveNotes().toString(),
                ),
                const Divider(height: 1),
                _buildStatTile(
                  icon: Icons.archive_outlined,
                  title: 'Archived Notes',
                  value: getArchivedNotes().toString(),
                ),
                const Divider(height: 1),
                _buildStatTile(
                  icon: Icons.text_fields,
                  title: 'Total Characters',
                  value: getTotalCharacters(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Theme Section
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _buildThemeOption(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Info Section
          _buildSectionHeader('About'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                if (appName != null)
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('App Name'),
                    subtitle: Text(appName!),
                  ),
                if (appVersion != null) const Divider(height: 1),
                if (appVersion != null)
                  ListTile(
                    leading: const Icon(Icons.tag_outlined),
                    title: const Text('Version'),
                    subtitle: Text('v$appVersion'),
                  ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Description'),
                  subtitle: Text('A simple and elegant note-taking app'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeOption() {
    return ValueListenableBuilder<Box>(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, box, _) {
        final themeMode =
            box.get('themeMode', defaultValue: 'system') as String;
        final isAutoMode = themeMode == 'system';

        return Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.brightness_auto_outlined),
              title: const Text('Auto Light/Dark Mode'),
              subtitle: const Text('Follow system theme'),
              value: isAutoMode,
              onChanged: (value) {
                box.put('themeMode', value ? 'system' : 'light');
              },
            ),
            if (!isAutoMode) ...[
              const Divider(height: 1),
              RadioListTile<String>(
                secondary: const Icon(Icons.light_mode_outlined),
                title: const Text('Light Mode'),
                value: 'light',
                groupValue: themeMode,
                onChanged: (value) {
                  if (value != null) {
                    box.put('themeMode', value);
                  }
                },
              ),
              const Divider(height: 1),
              RadioListTile<String>(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                value: 'dark',
                groupValue: themeMode,
                onChanged: (value) {
                  if (value != null) {
                    box.put('themeMode', value);
                  }
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
