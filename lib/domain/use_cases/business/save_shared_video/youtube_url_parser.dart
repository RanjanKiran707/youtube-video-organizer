final _idPattern = RegExp(r'^[A-Za-z0-9_-]{11}$');
final _urlPattern = RegExp(r'https?://[^\s]+');

/// Finds the first YouTube video id in shared text. The share sheet often sends
/// "Title https://youtu.be/ID", so the text is searched for URLs.
/// Returns null when there is no video link (a playlist or channel link has none).
String? parseYoutubeVideoId(String sharedText) {
  for (final match in _urlPattern.allMatches(sharedText)) {
    final uri = Uri.tryParse(match.group(0)!);
    if (uri == null) continue;
    final id = _idFromUri(uri);
    if (id != null) return id;
  }
  return null;
}

String? _idFromUri(Uri uri) {
  final host = uri.host.toLowerCase();
  String? candidate;

  if (host == 'youtu.be') {
    candidate = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  } else if (host == 'youtube.com' || host.endsWith('.youtube.com')) {
    final segments = uri.pathSegments;
    if (uri.path == '/watch') {
      candidate = uri.queryParameters['v'];
    } else if (segments.length >= 2 &&
        const {'shorts', 'embed', 'live', 'v'}.contains(segments.first)) {
      candidate = segments[1];
    }
  }

  return candidate != null && _idPattern.hasMatch(candidate) ? candidate : null;
}
