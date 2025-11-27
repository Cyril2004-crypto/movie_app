import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'watchlist_screen.dart';
import 'favorites_screen.dart';
import 'change_password_screen.dart'; // added import

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final username = auth.username ?? 'Guest';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'G';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(radius: 40, child: Text(initial, style: const TextStyle(fontSize: 32))),
            const SizedBox(height: 12),
            Text(username, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Watchlist'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WatchlistScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit username'),
              subtitle: Text(auth.username ?? 'Guest'),
              onTap: () async {
                final newName = await showDialog<String>(
                  context: context,
                  builder: (c) {
                    final ctrl = TextEditingController(text: auth.username);
                    return AlertDialog(
                      title: const Text('Edit username'),
                      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Username')),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('Save')),
                      ],
                    );
                  },
                );
                if (newName != null && newName.isNotEmpty) {
                  await context.read<AuthProvider>().updateUsername(newName);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Change password'),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text('Export data'),
              onTap: () async {
                // call provider helper to export user data (implements later)
                final path = await context.read<AuthProvider>().exportUserData();
                // StatelessWidget — show snackbar directly
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported to $path')));
              },
            ),
            // Show linked providers + unlink action
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Linked accounts'),
              subtitle: Text(auth.provider ?? 'local'),
              onTap: () {
                // navigate to linked accounts screen or show dialog
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug: list users'),
              onTap: () {
                final users = context.read<AuthProvider>().debugListUsers();
                showDialog(context: context, builder: (_) => AlertDialog(content: Text(users.toString())));
              },
            ),
          ],
        ),
      ),
    );
  }
}