import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'watchlist_screen.dart';
import 'favorites_screen.dart';

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
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}