
import 'package:flutter/material.dart';

class AddMovieDialog extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onAdd;
  final String accessToken;
  const AddMovieDialog({super.key, required this.onAdd, required this.accessToken});

  @override
  State<AddMovieDialog> createState() => _AddMovieDialogState();
}

class _AddMovieDialogState extends State<AddMovieDialog> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String type = 'show';
  String get proposedBy => widget.accessToken;
  bool watched = false;

  bool submitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Movie'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (v) => name = v,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
              // TextFormField(
              //   decoration: const InputDecoration(labelText: 'Type'),
              //   onChanged: (v) => type = v,
              //   validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              // ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Proposed By'),
                initialValue: proposedBy,
                readOnly: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: submitting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: submitting
              ? null
              : () async {
                  if (_formKey.currentState!.validate()) {
                    setState(() => submitting = true);
                    await widget.onAdd({
                      'name': name,
                      'type': type,
                      'proposed_by': proposedBy,
                      'watched': watched,
                    });
                    if (mounted) Navigator.of(context).pop();
                  }
                },
          child: submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Add'),
        ),
      ],
    );
  }
}
