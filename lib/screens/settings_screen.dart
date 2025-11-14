import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:flutter/painting.dart'; // for image cache clearing
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Box _settingsBox;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
  }

  Future<void> _pickLanguage() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('Choose language'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(c, 'English'), child: const Text('English')),
          SimpleDialogOption(onPressed: () => Navigator.pop(c, 'Spanish'), child: const Text('Spanish')),
          SimpleDialogOption(onPressed: () => Navigator.pop(c, 'French'), child: const Text('French')),
        ],
      ),
    );
    if (selected != null) {
      await _settingsBox.put('language', selected);
      // optional: inform ThemeProvider or other listeners if needed
      if (mounted) setState(() {});
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clear cache'),
        content: const Text('This will clear local watchlist and cached images. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _busy = true);
    try {
      if (Hive.isBoxOpen('watchlist')) {
        final box = Hive.box('watchlist');
        await box.clear();
      }
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to clear cache: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
    // navigate to the app's Login screen (uses the '/login' route in main.dart)
    await Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final language = (_settingsBox.get('language', defaultValue: 'English') as String);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            SwitchListTile(
              title: const Text('Dark theme'),
              subtitle: const Text('Toggle light / dark appearance'),
              value: themeProv.isDark,
              onChanged: (_) => context.read<ThemeProvider>().toggleDark(),
            ),
            ListTile(
              title: const Text('Language'),
              subtitle: Text(language),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickLanguage,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear cache'),
              subtitle: const Text('Removes local watchlist and cached images'),
              onTap: _clearCache,
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Sign in'),
              subtitle: const Text('Sign in to sync watchlist (not implemented)'),
              onTap: _signIn,
            ),
            if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}