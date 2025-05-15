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
    return Scaffold(
      appBar: AppBar(title: const Text('Music Player')),

      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !viewModel.hasInternet
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No internet connection'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                viewModel.fetchSongs(apiUrl); // retry
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Column(

      children: [

      Expanded(
            child: ListView.builder(
              itemCount: viewModel.songs.length,
              itemBuilder: (context, index) {
    final song = viewModel.songs[index];

    return   ListTile(
    leading: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(song.image, width: 50, height: 50, fit: BoxFit.cover),
    ),
    title: Text(song.name, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text(song.description, maxLines: 1, overflow: TextOverflow.ellipsis),






      trailing: Builder(
        builder: (_) {
          if (viewModel.currentIndex == index) {
            if (viewModel.isPlayingLoading || viewModel.isBuffering) {
              return const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            } else {
              return EqualizerAnimation(isPaused: !viewModel.isPlaying);
            }
          } else {
            return IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => viewModel.play(index),
            );
          }
        },
      ),









      onTap: () {
    viewModel.play(index);
    },
    );

              },
            ),
          ),
          if (viewModel.currentSong != null)
            Column(
              children: [
                Slider(
                  value: viewModel.position.inSeconds.toDouble(),
                  max: viewModel.duration.inSeconds.toDouble() > 0 ? viewModel.duration.inSeconds.toDouble() : 1.0,
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
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: viewModel.currentIndex > 0 ? viewModel.playPrevious : null,
                    ),
                    viewModel.isBuffering
                        ? const SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                        : IconButton(
                      icon: Icon(viewModel.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill),
                      iconSize: 40,
                      onPressed: () {
                        viewModel.isPlaying
                            ? viewModel.pause()
                            : viewModel.play(viewModel.currentIndex);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: viewModel.playNext,
                    ),
                  ],
                ),


              ],
            )
        ],
      ),
    );
  }
}