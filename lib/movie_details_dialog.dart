
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:watchalong_client/api_service.dart';
import 'package:watchalong_client/tmdb_service.dart';

class MovieDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> movie;

  const MovieDetailsDialog({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    Map<String, int> ratingsMap = {};
    print(movie['ratings']);
    if (movie['ratings'] != "" && movie['ratings'] != "\"{}\"" && movie['ratings'] != "{}" && movie['ratings'] != null) {
      ratingsMap = jsonDecode(movie['ratings'] ?? '{}').cast<String, int>();
    }
  


    return AlertDialog(
      title: FutureBuilder<String>(
        future: TMDBService.fetchTmdbTitle(movie['name'].toString().substring(5), movie['type']),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text('Loading...');
          } else if (snapshot.hasError) {
            return const Text('Error loading title');
          } else {
            return Text(snapshot.data ?? 'Unknown Title');
          }
        },
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Proposed By: ${ApiService.instance.usernameToAlias(movie['proposed_by'])}'),
          Text('Ratings:'),
          if (ratingsMap.isEmpty)
            const Text('No ratings yet')
          else
            ...ratingsMap.entries.map((entry) => Text('${ApiService.instance.usernameToAlias(entry.key)}: ${entry.value}')).toList(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}