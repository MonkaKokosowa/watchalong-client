

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:watchalong_client/api_service.dart';


import 'discord_login_page.dart';
import 'queue.dart';
import 'ratings_page.dart';
import 'watchalong_home_page.dart';
import 'token_storage.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(const WatchalongApp());
}



class WatchalongApp extends StatefulWidget {
  const WatchalongApp({super.key});

  @override
  State<WatchalongApp> createState() => _WatchalongAppState();
}

class _WatchalongAppState extends State<WatchalongApp> with WidgetsBindingObserver {
  // Listen to app lifecycle to reconnect websocket if needed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && discordAccessToken != null) {
      if (!ApiService.instance.wsConnected) {
        ApiService.instance.connectWebSocket(accessToken: discordAccessToken);
      }
    }
  }
  String? discordAccessToken;
  int selectedIndex = 0;
  bool _loading = true;
  String error = '';
  // No longer storing movies/queue/ws state here; handled by widgets via ApiService

  @override
  void initState() {
    super.initState();
    _loadToken();
    ApiService.instance.connectWebSocket(accessToken: discordAccessToken);
    ApiService.instance.refreshAll(accessToken: discordAccessToken);
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  Future<void> _loadToken() async {
    final token = await TokenStorage.load();
    setState(() {
      discordAccessToken = token;
      _loading = false;
    });
  }

  Future<void> _saveToken(String token) async {
    await TokenStorage.save(token);
    setState(() {
      discordAccessToken = token;
    });
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    setState(() {
      discordAccessToken = null;
      selectedIndex = 0;
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    // Expressive Material You color schemes
    final ColorScheme lightColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.lightGreen,
      brightness: Brightness.light,
    );
    final ColorScheme darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Watchalong',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
      ),
      themeMode: ThemeMode.system, // Follows system dark/light mode
      home: Scaffold(
        appBar: discordAccessToken == null ? null : AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ),
        bottomNavigationBar: discordAccessToken == null ? null : BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review),
              label: 'Ratings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.queue),
              label: 'Queue',
            ),
          ],
        ),
        body: discordAccessToken == null
            ? DiscordLoginPage(
                onLogin: (token) {
                  _saveToken(token);
                },
              )
            : (selectedIndex == 0
                ? WatchalongHomePage(
                    accessToken: discordAccessToken!,
                  )
                : selectedIndex == 1
                    ? RatingsPage(accessToken: discordAccessToken!)
                    : QueueView()),
      ),
    );
  }
}
