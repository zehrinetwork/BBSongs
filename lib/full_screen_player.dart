import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
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

    return
      Stack(
      children: [
        // Blur layer
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black.withAlpha(166), // Dim the background
          ),
        ),

        // Foreground UI
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Album Art
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

              // Stylish Playback Controls (Above Slider)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(Icons.skip_previous, onTap: viewModel.playPrevious),
                  const SizedBox(width: 20),
                 ( viewModel.playerState == ProcessingState.buffering )
                      ? const SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                      : _buildControlButton(
                    viewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 60,
                    iconColor: Colors.black,
                    backgroundColor: Colors.white,
                    onTap: () {
                      viewModel.isPlaying
                          ? viewModel.pause()
                          : viewModel.play(viewModel.currentIndex);
                    },
                  ),
                  const SizedBox(width: 20),
                  _buildControlButton(Icons.skip_next, onTap: viewModel.playNext),
                ],
              ),
              const SizedBox(height: 30),


            ],
          ),
        ),
      ],
    );

  }

  Widget _buildControlButton(
      IconData icon, {
        required VoidCallback onTap,
        double size = 30,
        Color backgroundColor = Colors.white24,
        Color iconColor = Colors.white,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size + 20,
        height: size + 20,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: size, color: iconColor),
      ),
    );
  }

}
