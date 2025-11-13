import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter/painting.dart'; // for image cache clearing

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Box _settingsBox;
  bool _darkTheme = false;
  String _language = 'English';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings');
    _darkTheme = (_settingsBox.get('theme', defaultValue: 'light') as String) == 'dark';
    _language = (_settingsBox.get('language', defaultValue: 'English') as String);
  }

  Future<void> _setTheme(bool dark) async {
    setState(() => _darkTheme = dark);
    await _settingsBox.put('theme', dark ? 'dark' : 'light');
    // Note: to apply theme app-wide you'll need to read this setting in your top-level widget
    // and rebuild MaterialApp with the selected ThemeMode (Provider / Riverpod / setState at top).
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
      setState(() => _language = selected);
      await _settingsBox.put('language', selected);
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
      // clear watchlist (if present)
      if (Hive.isBoxOpen('watchlist')) {
        final box = Hive.box('watchlist');
        await box.clear();
      }
      // clear other app boxes if desired
      // clear image cache
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to clear cache: $e')));
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _signIn() async {
    // Placeholder sign-in flow
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sign in'),
        content: const Text('Sign-in not implemented yet.'),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              value: _darkTheme,
              onChanged: _setTheme,
            ),
            ListTile(
              title: const Text('Language'),
              subtitle: Text(_language),
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