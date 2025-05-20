import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'music_view_model.dart';

class FullScreenPlayer extends StatelessWidget {
  const FullScreenPlayer({super.key});

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MusicViewModel>(context);
    final song = viewModel.currentSong;

    if (song == null) return const SizedBox();

    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(100),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(song.image, width: 300, height: 300, fit: BoxFit.cover),
          ),
          const SizedBox(height: 30),

          // Song Info
          Text(
            song.name,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            song.description,
            style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Slider
          Slider(
            value: viewModel.position.inSeconds.toDouble(),
            max: viewModel.duration.inSeconds.toDouble() > 0
                ? viewModel.duration.inSeconds.toDouble()
                : 1.0,
            onChanged: (value) =>
                viewModel.seekTo(Duration(seconds: value.toInt())),
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatTime(viewModel.position), style: const TextStyle(color: Colors.white)),
              Text(_formatTime(viewModel.duration), style: const TextStyle(color: Colors.white)),
            ],
          ),

          const SizedBox(height: 20),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 32),
                color: Colors.white,
                onPressed: viewModel.playPrevious,
              ),
              const SizedBox(width: 20),
              viewModel.isBuffering
                  ? const CircularProgressIndicator(color: Colors.white)
                  : IconButton(
                icon: Icon(
                  viewModel.isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 48,
                  color: Colors.white,
                ),
                onPressed: () {
                  viewModel.isPlaying
                      ? viewModel.pause()
                      : viewModel.play(viewModel.currentIndex);
                },
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 32),
                color: Colors.white,
                onPressed: viewModel.playNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
