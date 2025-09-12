
import 'dart:convert';

import 'package:flutter/material.dart';

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
      title: Text(movie['name']),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Proposed By: ${movie['proposedBy']}'),
          Text('Ratings:'),
          if (ratingsMap.isEmpty)
            const Text('No ratings yet')
          else
            ...ratingsMap.entries.map((entry) => Text('${entry.key}: ${entry.value}')).toList(),
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