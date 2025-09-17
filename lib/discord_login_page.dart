import 'package:flutter/material.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DiscordLoginPage extends StatefulWidget {
  final void Function(String accessToken) onLogin;
  const DiscordLoginPage({super.key, required this.onLogin});

  @override
  State<DiscordLoginPage> createState() => _DiscordLoginPageState();
}

class _DiscordLoginPageState extends State<DiscordLoginPage> {
  static String get clientId => dotenv.env['DISCORD_CLIENT_ID'] ?? '';
  static const String customSchemeRedirectUri = 'watchalong://callback';
  static String get httpRedirectUri => dotenv.env['DISCORD_HTTP_REDIRECT_URI'] ?? 'https://yourdomain.com/callback';
  static const String scope = 'identify email';

  bool useCustomScheme = false;

  StreamSubscription<Uri>? _sub;
  AppLinks? _appLinks;
  bool _launched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _sub = _appLinks!.uriLinkStream.listen((Uri uri) async {
      final uriStr = uri.toString();
      if (uriStr.startsWith(customSchemeRedirectUri) || uriStr.startsWith(httpRedirectUri)) {
        final fragment = uri.fragment;
        final params = Uri.splitQueryString(fragment);
        final token = params['access_token'];
        if (token != null && token.isNotEmpty) {
          // Fetch Discord username
          try {
            final username = await _fetchDiscordUsername(token);
            if (username != null) {
              // ignore: avoid_print
              print('Discord username: $username');
              widget.onLogin(username);
            } else {
              print(token);
              print('Failed to fetch Discord username');
            }
          } catch (e) {
            print('Error fetching Discord username: $e');
          }
          
        } else {
          setState(() => _error = 'No access token found in redirect.');
        }
      }
    }, onError: (err) {
      setState(() => _error = 'Error listening for redirect: $err');
    });
  }

  Future<String?> _fetchDiscordUsername(String accessToken) async {
    try {
      final uri = Uri.https('discord.com', '/api/users/@me');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $accessToken'},
      );
      print(response);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        return data['username'];
      } 
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _appLinks = null;
    super.dispose();
  }

  Future<void> _loginWithDiscord() async {
    if (clientId.isEmpty) {
      setState(() => _error = 'Discord client ID is not set.');
      return;
    }
    final redirectUri = useCustomScheme ? customSchemeRedirectUri : httpRedirectUri;
    final url = Uri.https('discord.com', '/api/oauth2/authorize', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'token',
      'scope': scope,
      'prompt': 'consent',
    });
    if (await canLaunchUrl(url)) {
      setState(() => _launched = true);
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      setState(() => _error = 'Could not launch Discord login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _launched ? null : _loginWithDiscord,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Log in with Discord'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ]
          ],
        ),
      ),
    );
  }
}
