import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/movie_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart'; // added import
import '../providers/connectivity_provider.dart';
import '../widgets/movie_card.dart';
import 'movie_details_screen.dart';
import '../screens/watchlist_screen.dart';
import '../screens/person_screen.dart';
import 'person_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final prov = context.read<MovieProvider>();
    prov.fetchPopularMovies();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        prov.loadMoreIfNeeded();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<MovieProvider>();
    final auth = context.watch<AuthProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final conn = context.watch<ConnectivityProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Popular Movies'),
        actions: [
          // Theme toggle
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(themeProv.isDark ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => context.read<ThemeProvider>().toggleDark(),
          ),

          // Watchlist button (navigates to watchlist screen)
          IconButton(
            tooltip: 'Watchlist',
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => Navigator.pushNamed(context, '/watchlist'),
          ),

          // Person / Actor quick open (asks for ID then opens PersonScreen)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search people',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonSearchScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.explore),
            tooltip: 'Explore',
            onPressed: () => Navigator.pushNamed(context, '/explore'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),

          // Favorites (existing)
          IconButton(
            tooltip: 'Favorites',
            icon: const Icon(Icons.bookmarks),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),

          if (auth.isLoggedIn)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text(auth.username ?? '', style: const TextStyle(fontSize: 14))),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
            tooltip: 'Logout',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search movies...', border: OutlineInputBorder()),
              onChanged: (v) => prov.search(v),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (!conn.isOnline)
            Container(
              width: double.infinity,
              color: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              child: const Text('Offline — showing cached data when available', style: TextStyle(color: Colors.white)),
            ),
          Expanded(
            child: Builder(builder: (ctx) {
              if (prov.loading && prov.movies.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (prov.error != null && prov.movies.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: ${prov.error}'),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: prov.fetchPopularMovies, child: const Text('Retry')),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: prov.refresh,
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: prov.movies.length + (prov.loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= prov.movies.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final movie = prov.movies[index];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailsScreen(movieId: movie.id, heroTag: 'poster_${movie.id}'))),
                      child: MovieCard(movie: movie, heroTag: 'poster_${movie.id}'),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
