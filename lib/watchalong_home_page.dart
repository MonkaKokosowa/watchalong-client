
import 'package:flutter/material.dart';
import 'package:watchalong_client/alias_page.dart';
import 'package:watchalong_client/movie_details_dialog.dart';
import 'add_movie_page.dart';
import 'api_service.dart';
import 'tmdb_service.dart';
import 'tmdb_image.dart';
import 'package:flutter/foundation.dart';

class WatchalongHomePage extends StatefulWidget {
  final String accessToken;
  const WatchalongHomePage({super.key, required this.accessToken});

  @override
  State<WatchalongHomePage> createState() => _WatchalongHomePageState();
}

class _WatchalongHomePageState extends State<WatchalongHomePage> {
  String _searchQuery = '';
  bool _filterWatched = false;
  bool _filterMovie = false;
  bool _filterShow = false;
  final Map<int, String> _resolvedTitles = {};
  final Map<int, String?> _resolvedPosters = {};
  final Map<int, dynamic> _lastMovies = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _preloadTmdbData();
  }

  void _preloadTmdbData() async {
    final movies = ApiService.instance.appData.value['movies'] ?? [];
    final queue = ApiService.instance.appData.value['queue'] ?? [];
    final all = [...movies, ...queue.take(1)];
    final Map<int, String> newTitles = {};
    final Map<int, String?> newPosters = {};
    setState(() { _loading = true; });
    await Future.wait(all.where((movie) => movie['name'] != null && movie['name'].toString().startsWith('tmdb:')).map<Future<void>>((movie) async {
      final movieId = movie['id'] as int;
      final movieName = movie['name'] as String;
      final type = movie['type'] ?? 'movie';
      final id = movieName.substring(5);
      final title = await TMDBService.fetchTmdbTitle(id, type);
      newTitles[movieId] = title;
      final posterPath = await TMDBService.fetchTmdbPosterPath(id, type);
      newPosters[movieId] = posterPath != null && posterPath.isNotEmpty ? TMDBService.getPosterUrl(posterPath) : null;
    }));
    setState(() {
      _resolvedTitles.clear();
      _resolvedTitles.addAll(newTitles);
      _resolvedPosters.clear();
      _resolvedPosters.addAll(newPosters);
      _loading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ApiService.instance.appData.addListener(_onAppDataChanged);
  }

  @override
  void dispose() {
    ApiService.instance.appData.removeListener(_onAppDataChanged);
    super.dispose();
  }

  void _onAppDataChanged() {
    final movies = ApiService.instance.appData.value['movies'] ?? [];
    if (!mapEquals(_lastMovies, movies)) {
      _preloadTmdbData();
    }
  }
  // Helper to fetch TMDB title by id



  // No local state for movies/queue; use global notifier

  void openAliasPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AliasPage(accessToken: widget.accessToken),
      ),
    );
  }

  void showMovieDetailsDialog(BuildContext context, Map<String, dynamic> movie) {
    showDialog(context: context, builder: (context) => MovieDetailsDialog(movie: movie));
  }

  void showAddMoviePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddMoviePage(
          onAdd: (data) async {
            await ApiService.addMovie(data);
          },
          accessToken: widget.accessToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    
    bool isLowestQueuePosition(Map<String, dynamic> item, List<dynamic> queue) {
      if (queue.isEmpty) return false;
      final minPosition = queue.map<int>((e) => e['queue_position'] as int).reduce((a, b) => a < b ? a : b);
      return item['queue_position'] == minPosition;
    }

    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: ApiService.instance.appData,
      builder: (context, data, _) {
        final movies = data['movies'] ?? [];
        final queue = data['queue'] ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Watchalong'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ApiService.instance.refreshAll(accessToken: widget.accessToken),
                tooltip: 'Refresh',
              ),
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () => openAliasPage(context),
                tooltip: 'Alias',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showAddMoviePage(context),
            child: const Icon(Icons.add),
            tooltip: 'Add Movie',
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ApiService.instance.wsConnected
                        ? const Icon(Icons.wifi, color: Colors.green)
                        : const Icon(Icons.wifi_off, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(ApiService.instance.wsConnected ? 'Connected' : 'Disconnected'),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Next watch!', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                queue.isEmpty
                    ? const Text('Queue is empty')
                    : SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: queue.length,
                          separatorBuilder: (context, i) => const SizedBox(width: 12),
                          itemBuilder: (context, i) {
                            final item = queue[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: Container(
                                width: 100,
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (item['name'] != null && item['name'].toString().startsWith('tmdb:'))
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 4.0),
                                        child: TMDBImage(
                                          id: item['name'].toString().substring(5),
                                          type: item['type'] ?? 'movie',
                                          width: 60,
                                          height: 80,
                                        ),
                                      ),
                                    if (item['name'] != null && item['name'].toString().startsWith('tmdb:'))
                                      Text(_resolvedTitles[item['id']] ?? '', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)
                                    else
                                      Text(item['name'] ?? '', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    if (isLowestQueuePosition(item, queue)) 
                                      TextButton(
                                      onPressed: () => ApiService.removeFromQueue(),
                                      child: const Text('Remove'),
                                    ),
                                    
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 24),
                Text('All Movies', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                // Search and filter controls
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search movies...'
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Watched'),
                      selected: _filterWatched,
                      onSelected: (v) => setState(() => _filterWatched = v),
                    ),
                    const SizedBox(width: 4),
                    FilterChip(
                      label: const Text('Movie'),
                      selected: _filterMovie,
                      onSelected: (v) => setState(() => _filterMovie = v),
                    ),
                    const SizedBox(width: 4),
                    FilterChip(
                      label: const Text('Show'),
                      selected: _filterShow,
                      onSelected: (v) => setState(() => _filterShow = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Builder(
                          builder: (context) {
                            // Apply filters and search
                            List<dynamic> filtered = movies;
                            if (_searchQuery.isNotEmpty) {
                              filtered = filtered.where((movie) {
                                final title = (movie['name'] != null && movie['name'].toString().startsWith('tmdb:'))
                                    ? (_resolvedTitles[movie['id']] ?? '')
                                    : (movie['name'] ?? '');
                                return title.toLowerCase().contains(_searchQuery.toLowerCase());
                              }).toList();
                            }
                            if (_filterWatched) {
                              filtered = filtered.where((movie) => movie['watched'] == 1).toList();
                            }
                            if (_filterMovie) {
                              filtered = filtered.where((movie) => movie['type'] == 'movie').toList();
                            }
                            if (_filterShow) {
                              filtered = filtered.where((movie) => movie['type'] == 'show').toList();
                            }
                            return GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.7,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, idx) {
                                final movie = filtered[idx];
                                return GestureDetector(
                                  onTap: () {
                                    showMovieDetailsDialog(context, movie);
                                  },
                                  onLongPress: () {
                                    // add to queue
                                    ApiService.addToQueue(movie['id']);
                                    // show snackbar
                                    if (movie['name'] != null && movie['name'].toString().startsWith('tmdb:')) {
                                      final title = _resolvedTitles[movie['id']] ?? '';
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Added "$title" to queue')),
                                      );
                                      return;
                                    }
                                  },
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (movie['name'] != null && movie['name'].toString().startsWith('tmdb:'))
                                            TMDBImage(
                                              key: ValueKey(movie['id']),
                                              id: movie['name'].toString().substring(5),
                                              type: movie['type'] ?? 'movie',
                                              width: 60,
                                              height: 90,
                                            ),
                                          if (movie['name'] != null && movie['name'].toString().startsWith('tmdb:'))
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                _resolvedTitles[movie['id']] ?? '',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )
                                          else
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                movie['name'] ?? '',
                                                style: Theme.of(context).textTheme.bodyMedium,
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
            ]
            )
          )
        );
      },
    );
  }
}
