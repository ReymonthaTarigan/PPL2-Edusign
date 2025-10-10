import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeService {
  final String apiKey = "AIzaSyB24ecz331QG4MCuwISfmkI6XefcT8UWtY";

  Future<Map<String, dynamic>?> fetchVideoDetails(String videoUrl) async {
    try {
      // Ambil ID video dari URL
      final videoId = _extractVideoId(videoUrl);
      if (videoId == null) return null;

      final url = Uri.parse(
        "https://www.googleapis.com/youtube/v3/videos"
            "?part=snippet,statistics&id=$videoId&key=$apiKey",
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["items"].isEmpty) return null;

        final snippet = data["items"][0]["snippet"];
        final stats = data["items"][0]["statistics"];

        return {
          "title": snippet["title"],
          "description": snippet["description"],
          "channel": snippet["channelTitle"],
          "thumbnail": snippet["thumbnails"]["high"]["url"],
          "views": stats["viewCount"],
        };
      } else {
        print("Error: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Failed to fetch YouTube data: $e");
      return null;
    }
  }

  // Helper untuk ambil ID video dari URL
  String? _extractVideoId(String url) {
    final uri = Uri.parse(url);
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    } else if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    return null;
  }
}
