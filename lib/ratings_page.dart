

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';
import 'tmdb_service.dart';
import 'tmdb_image.dart';


class RatingsPage extends StatefulWidget {
  final String accessToken;
  const RatingsPage({Key? key, required this.accessToken}) : super(key: key);

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}



class _RatingsPageState extends State<RatingsPage> {
  final Map<int, double> _ratings = {};
  final Map<int, String> _resolvedTitles = {};
  final Map<int, String?> _resolvedPosters = {};
  Map<int, dynamic> _lastMovies = {};
  bool _loadingTitles = false;

  @override
  void initState() {
    super.initState();
    _preloadTitles();
  }

  void _preloadTitles() async {
    final movies = ApiService.instance.appData.value['movies'] ?? [];
    final Map<int, String> newTitles = {};
    final Map<int, String?> newPosters = {};
    setState(() { _loadingTitles = true; });
    await Future.wait(movies.where((movie) => movie['watched'] == 1).map<Future<void>>((movie) async {
      final movieId = movie['id'] as int;
      final movieName = movie['name'] as String;
      if (movieName.startsWith('tmdb:')) {
        final type = movie['type'] ?? 'movie';
        final id = movieName.substring(5);
        final title = await TMDBService.fetchTmdbTitle(id, type);
        newTitles[movieId] = title;
        final posterPath = await TMDBService.fetchTmdbPosterPath(id, type);
        newPosters[movieId] = posterPath != null && posterPath.isNotEmpty ? TMDBService.getPosterUrl(posterPath) : null;
      } else {
        newTitles[movieId] = movieName;
        newPosters[movieId] = null;
      }
    }));
    setState(() {
      _resolvedTitles.clear();
      _resolvedTitles.addAll(newTitles);
      _resolvedPosters.clear();
      _resolvedPosters.addAll(newPosters);
      _loadingTitles = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen for movie list changes and refetch titles if needed
    ApiService.instance.appData.addListener(_onAppDataChanged);
  }

  @override
  void dispose() {
    ApiService.instance.appData.removeListener(_onAppDataChanged);
    super.dispose();
  }

  void _onAppDataChanged() {
    final movies = ApiService.instance.appData.value['movies'] ?? [];
    // Only reload if the movie list actually changed
    if (!mapEquals(_lastMovies, movies)) {
      _lastMovies = Map<int, dynamic>.fromIterable(movies, key: (m) => m['id'] as int, value: (m) => m);
      _preloadTitles();
    }
  }

  Future<void> _submitRating(int movieId, int rating) async {
    try {
      await ApiService.submitRating(movieId, rating, accessToken: widget.accessToken);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rating submitted!')),
      );
      // No need to manually refresh; global notifier will update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting rating: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: ApiService.instance.appData,
      builder: (context, data, _) {
        final movies = data['movies'] ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Rate Watched Movies'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ApiService.instance.refreshAll(accessToken: widget.accessToken),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: _loadingTitles
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: movies
                      .where((movie) => movie['watched'] == 1)
                      .map<Widget>((movie) {
                    final movieId = movie['id'] as int;
                    final movieName = movie['name'] as String;
                    final currentRating = _ratings[movieId] ?? 5;
                    final displayTitle = _resolvedTitles[movieId] ?? movieName;
                    final isTmdb = movieName.startsWith('tmdb:');
                    final tmdbId = isTmdb ? movieName.substring(5) : null;
                    final tmdbType = movie['type'] ?? 'movie';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isTmdb && tmdbId != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: TMDBImage(
                                  id: tmdbId,
                                  type: tmdbType,
                                  height: 120,
                                  width: 80,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayTitle, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.left),
                                  const SizedBox(height: 8),
                                  Slider(
                                    value: currentRating,
                                    min: 1,
                                    max: 10,
                                    divisions: 9,
                                    label: currentRating.toStringAsFixed(0),
                                    onChanged: (value) {
                                      setState(() {
                                        _ratings[movieId] = value;
                                      });
                                    },
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          _submitRating(movieId, currentRating.toInt());
                                        },
                                        child: const Text('Submit'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}
