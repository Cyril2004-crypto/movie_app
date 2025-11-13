import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TrailerPlayer extends StatelessWidget {
  final String videoKey;
  const TrailerPlayer({super.key, required this.videoKey});

  Uri get _youtubeUri => Uri.parse('https://www.youtube.com/watch?v=$videoKey');

  Future<void> _openExternal() async {
    final uri = _youtubeUri;
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // ignore: avoid_print
      print('Could not open $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simple UI that opens the trailer externally on desktop where iframe player may not be available.
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Open Trailer on YouTube'),
          onPressed: _openExternal,
        ),
      ),
    );
  }
}