import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AliasPage extends StatefulWidget {
  final String accessToken;
  const AliasPage({super.key, required this.accessToken});

  @override
  State<AliasPage> createState() => _AliasPageState();
}

class _AliasPageState extends State<AliasPage> {
  bool _loading = true;
  String? _error;
  Map<String, String> aliases = {};
  String get apiUrl => dotenv.env['API_URL']?.replaceAll(RegExp(r'/+$'), '') ?? 'http://localhost:3000';
  String userAlias = "";


  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('$apiUrl/alias')
      );
      if (res.statusCode == 200) {
        setState(() {
          aliases = jsonDecode(res.body).cast<String, String>();
          _loading = false;

          userAlias = aliases['${widget.accessToken}'] ?? '';
        });
      } else {
        setState(() {
          _error = 'Failed to fetch aliases: ${res.body}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _submitAlias() {
    final Map<String, String> body = {
      'username': widget.accessToken,
      'alias': userAlias,
    };

    http.post(
      Uri.parse('$apiUrl/alias'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).then((res) {
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alias saved!')),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save alias: ${res.body}')),
        );
      }
    }).catchError((e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving alias: $e')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Alias'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading)
              const CircularProgressIndicator()
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else
              TextField(
                decoration: const InputDecoration(labelText: 'Alias'),
                onChanged: (v) => userAlias = v,
                controller: TextEditingController(text: userAlias),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submitAlias,
              child: const Text('Save Alias'),
            ),
            const SizedBox(height: 20),
            ListView.builder(itemBuilder: (context, index) {
              final entry = aliases.entries.elementAt(index);
              return ListTile(
                title: Text(entry.value),
                subtitle: Text(entry.key),
              );
            }, itemCount: aliases.length, shrinkWrap: true, physics: const NeverScrollableScrollPhysics()),
          ],
        ),
      ),
    );
  }
}