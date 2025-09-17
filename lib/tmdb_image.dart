import 'package:flutter/material.dart';
import 'tmdb_service.dart';

class TMDBImage extends StatefulWidget {
  final String id;
  final String type;
  final double width;
  final double height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const TMDBImage({
    super.key,
    required this.id,
    required this.type,
    this.width = 60,
    this.height = 90,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<TMDBImage> createState() => _TMDBImageState();
}

class _TMDBImageState extends State<TMDBImage> {
  String? _posterUrl;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetchPoster();
  }

  void _fetchPoster() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final posterPath = await TMDBService.fetchTmdbPosterPath(widget.id, widget.type);
      if (posterPath != null && posterPath.isNotEmpty) {
        setState(() {
          _posterUrl = TMDBService.getPosterUrl(posterPath);
          _loading = false;
        });
      } else {
        setState(() {
          _posterUrl = null;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.placeholder ?? const SizedBox(width: 60, height: 90, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_error || _posterUrl == null) {
      return widget.errorWidget ?? const SizedBox(width: 60, height: 90, child: Icon(Icons.broken_image));
    }
    return Image.network(
      _posterUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: (context, error, stack) => widget.errorWidget ?? const Icon(Icons.broken_image),
    );
  }
}
