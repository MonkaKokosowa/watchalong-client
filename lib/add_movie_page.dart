import 'package:flutter/material.dart';
import 'tmdb_service.dart';

class AddMoviePage extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onAdd;
  final String accessToken;
  const AddMoviePage({super.key, required this.onAdd, required this.accessToken});

  @override
  State<AddMoviePage> createState() => _AddMoviePageState();
}

class _AddMoviePageState extends State<AddMoviePage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String type = 'show';
  String get proposedBy => widget.accessToken;
  bool watched = false;
  bool submitting = false;
  List<dynamic> tmdbResults = [];
  dynamic selectedTmdb;
  bool searching = false;


  bool shouldPickProposedBy = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Movie/Show'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Search TMDB',
                  suffixIcon: searching
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            if (name.isEmpty) return;
                            setState(() => searching = true);
                            try {
                              final results = await TMDBService.searchMovies(name);
                              setState(() {
                                tmdbResults = results;
                              });
                            } finally {
                              setState(() => searching = false);
                            }
                          },
                        ),
                ),
                onChanged: (v) => setState(() { name = v; }),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              if (tmdbResults.isNotEmpty)
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: tmdbResults.length,
                    itemBuilder: (context, i) {
                      final item = tmdbResults[i];
                      final title = item['title'] ?? item['name'] ?? '';
                      final poster = TMDBService.getPosterUrl(item['poster_path']);
                      return ListTile(
                        leading: poster != null ? Image.network(poster, width: 40, height: 60, fit: BoxFit.cover) : null,
                        title: Text(title),
                        subtitle: Text(item['media_type'] ?? ''),
                        selected: selectedTmdb == item,
                        onTap: () {
                          setState(() {
                            selectedTmdb = item;
                            name = title;
                            type = (item['media_type'] == 'tv') ? 'show' : 'movie';
                          });
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              SegmentedButton(segments: [
                ButtonSegment(
                  value: 'movie',
                  icon: Icon(Icons.ondemand_video),
                  label: Text('Movie')),
                ButtonSegment(
                  value: 'show',
                  icon: Icon(Icons.dvr),
                  label: Text('Show')),
              ], selected: {type}, onSelectionChanged: (newSelection) {
                setState(() {
                  type = newSelection.first;
                });
              }),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Proposed By'),
                initialValue: !shouldPickProposedBy ? proposedBy : '',
                readOnly: !shouldPickProposedBy,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: submitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: submitting
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => submitting = true);
                              final movieData = {
                                'name': selectedTmdb != null && selectedTmdb['id'] != null
                                    ? 'tmdb:${selectedTmdb['id']}'
                                    : name,
                                'type': type,
                                'proposed_by': proposedBy,
                                'watched': watched,
                              };
                              await widget.onAdd(movieData);
                              if (mounted) Navigator.of(context).pop();
                            }
                          },
                    child: submitting
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
