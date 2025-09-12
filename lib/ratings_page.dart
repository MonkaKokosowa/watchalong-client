
import 'package:flutter/material.dart';

import 'api_service.dart';


class RatingsPage extends StatefulWidget {
  final String accessToken;
  const RatingsPage({Key? key, required this.accessToken}) : super(key: key);

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {

  final Map<int, double> _ratings = {};

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
          body: ListView(
            children: movies
                .where((movie) => movie['watched'] == 1)
                .map<Widget>((movie) {
              final movieId = movie['id'] as int;
              final movieName = movie['name'] as String;
              final currentRating = _ratings[movieId] ?? 5;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(movieName, style: Theme.of(context).textTheme.titleMedium),
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
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
