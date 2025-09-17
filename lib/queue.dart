import 'package:flutter/material.dart';
import 'api_service.dart';
import 'tmdb_service.dart';

class QueueView extends StatefulWidget {
  const QueueView({Key? key}) : super(key: key);

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  // No local state for queue; use global notifier

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: ApiService.instance.appData,
      builder: (context, data, _) {
        final queueItems = data['queue'] ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Queue'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ApiService.instance.refreshAll(),
                tooltip: 'Refresh',
              ),
            ],
          ),
          body: queueItems.isEmpty
              ? const Center(child: Text('Queue is empty'))
              : ListView.separated(
                  itemCount: queueItems.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = queueItems[index];
                    final poster = (item is Map && item['poster_path'] != null)
                        ? TMDBService.getPosterUrl(item['poster_path'])
                        : null;
                    return ListTile(
                      leading: poster != null
                          ? Image.network(poster, width: 40, height: 60, fit: BoxFit.cover)
                          : Text('${index + 1}'),
                      title: FutureBuilder<String>(
                        future: TMDBService.fetchTmdbTitle(item['name'].toString().substring(5), item['type']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text('Loading...');
                          } else if (snapshot.hasError) {
                            return Text('Error loading title');
                          } else {
                            return Text(snapshot.data == "Unknown TMDB" ? item['name'] : snapshot.data);
                          }
                        },
                    ));
                  },
                ),
        );
      },
    );
  }
}