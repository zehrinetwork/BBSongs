import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'equalizer_animation.dart';
import 'music_view_model.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final String apiUrl = 'https://mocki.io/v1/290de512-4dfb-4bd2-9696-d13de5439a00'; // Replace with your actual API URL

  @override
  void initState() {
    super.initState();
    Provider.of<MusicViewModel>(context, listen: false).fetchSongs(apiUrl);
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MusicViewModel>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (viewModel.hasInternet && !viewModel.isLoading && viewModel.songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Back online. Reloading songs...')),
        );
      }
    });




    return Scaffold(
      appBar: AppBar(title: const Text('Music Player')),

    body: Stack(
    children: [
    Column(
    children: [
    if (!viewModel.hasInternet)
    Container(
    width: double.infinity,
    color: Colors.red,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: const Center(
    child: Text(
    'You are offline',
    style: TextStyle(color: Colors.white),
    ),
    ),
    ),
    Expanded(
    child: viewModel.isLoading && viewModel.songs.isEmpty
    ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
    itemCount: viewModel.songs.length,
    itemBuilder: (context, index) {
    final song = viewModel.songs[index];
    return


      ListTile(
        leading: Image.network(
          song.image,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),

        title: Text(song.name),
        subtitle: Text(song.description),

        // 🔑 Whole row toggles play / pause
        onTap: () {
          if (viewModel.currentIndex == index) {
            // Same song – toggle
            viewModel.isPlaying ? viewModel.pause() : viewModel.play(index);
          } else {
            // New song – start playing
            viewModel.play(index);
          }
        },

        // 🎛 Shows state only (no extra tap action needed here)
        trailing: (viewModel.currentIndex == index)
            ? (viewModel.isPlayingLoading || viewModel.isBuffering)
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : EqualizerAnimation(isPaused: !viewModel.isPlaying)
            : const Icon(Icons.play_arrow),
      );


    },
    ),
    ),
    if (viewModel.currentSong != null)
    // your bottom player UI (slider, duration, controls)
    // keep it as you already have
    ...[
    Slider(
    value: viewModel.position.inSeconds.toDouble(),
    max: viewModel.duration.inSeconds.toDouble() > 0
    ? viewModel.duration.inSeconds.toDouble()
        : 1.0,
    onChanged: (value) => viewModel.seekTo(Duration(seconds: value.toInt())),
    ),
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20.0),
    child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Text(_formatTime(viewModel.position)),
    Text(_formatTime(viewModel.duration)),
    ],
    ),
    ),
    Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    IconButton(icon: const Icon(Icons.skip_previous), onPressed: viewModel.playPrevious),
    viewModel.isBuffering
    ? const SizedBox(
    height: 40,
    width: 40,
    child: CircularProgressIndicator(strokeWidth: 3),
    )
        : IconButton(
    icon: Icon(
    viewModel.isPlaying
    ? Icons.pause_circle_filled
        : Icons.play_circle_fill,
    ),
    iconSize: 40,
    onPressed: () {
    viewModel.isPlaying
    ? viewModel.pause()
        : viewModel.play(viewModel.currentIndex);
    },
    ),
    IconButton(icon: const Icon(Icons.skip_next), onPressed: viewModel.playNext),
    ],
    ),
    ],
    ],
    ),
    ],
    ));


  }
}