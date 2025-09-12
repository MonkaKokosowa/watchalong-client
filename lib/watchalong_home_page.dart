
import 'package:flutter/material.dart';
import 'package:watchalong_client/alias_page.dart';
import 'package:watchalong_client/movie_details_dialog.dart';
import 'add_movie_dialog.dart';
import 'api_service.dart';

class WatchalongHomePage extends StatefulWidget {
  final String accessToken;
  const WatchalongHomePage({super.key, required this.accessToken});

  @override
  State<WatchalongHomePage> createState() => _WatchalongHomePageState();
}

class _WatchalongHomePageState extends State<WatchalongHomePage> {
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

  void showAddMovieDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddMovieDialog(
        onAdd: (data) async {
          await ApiService.addMovie(data);
        },
        accessToken: widget.accessToken,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => showAddMovieDialog(context),
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
                    : Card(
                        child: ListTile(
                          title: Text(queue[0]['name']),
                          subtitle: Text('Proposed by: ${queue[0]['proposed_by']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: ApiService.removeFromQueue,
                            tooltip: 'Remove from queue',
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                Text('All Movies', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: movies.length,
                    itemBuilder: (context, idx) {
                      final movie = movies[idx];
                      final isWatched = movie['watched'] == 1;
                      final alias = ApiService.instance.usernameToAlias(movie['proposed_by']);
                      return Card(
                        child: ListTile(
                          title: Text(movie['name']),
                          subtitle: Text('Type: ${movie['type']} | Proposed by: $alias'),
                          trailing: Checkbox(value: isWatched, onChanged: null),
                          onTap: () {
                            if (!isWatched && queue.isNotEmpty && queue.where((m) => m['id'] == movie['id']).isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('This ${movie['type']} is already in the queue')),
                              );
                            } else if (!isWatched) {
                              ApiService.addToQueue(movie['id']);
                            } else {
                              showMovieDetailsDialog(context, movie);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
