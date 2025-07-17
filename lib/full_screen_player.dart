import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'ad_helper.dart';
import 'music_view_model.dart';

class FullScreenPlayer extends StatefulWidget {
  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
//  const FullScreenPlayer({super.key});
  final AdHelper _adHelper = AdHelper();

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }


  @override
  void initState() {
    super.initState();
    // Load the ad as soon as the screen is opened
    _adHelper.createInterstitialAd();
  }

  // This function will be called when the user tries to pop the screen
  Future<bool> _onWillPop() async {
    // Show the ad (the helper class handles the frequency logic)
    await _adHelper.showInterstitialAd();
    // Allow the pop to happen
    return true;
  }
  //


  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MusicViewModel>(context);
    final song = viewModel.currentSong;

    if (song == null) return const SizedBox();

    return
      PopScope(
        canPop: false,

          onPopInvokedWithResult: (bool didPop, dynamic result) async {
            // If didPop is true, the pop has already happened, so we just return.
            if (didPop) {
              return;
            }

            // 1. Show the ad. Our AdHelper class contains the frequency logic.
            await _adHelper.showInterstitialAd();

            // 2. Once the ad logic is complete, we manually pop the screen.
            // We check if the widget is still in the tree with `context.mounted`.
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },


        child: Stack(
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
                  child: Image.network(
                    viewModel.currentSong!.image,
                    width: 300,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/default_cover.png',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),



                const SizedBox(height: 150),

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
             /*   Slider(
                  value: viewModel.position.inSeconds.toDouble(),
                  max: viewModel.duration.inSeconds.toDouble() > 0
                      ? viewModel.duration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) =>
                      viewModel.seekTo(Duration(seconds: value.toInt())),
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                ),*/

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: Color(0xFF235C70),
                    inactiveTrackColor: Color(0xFF54676E),
                    trackShape: const RoundedRectSliderTrackShape(),
                    thumbColor: Color(0xFF72C7E3),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayColor: Colors.orangeAccent,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                  ),
                  child: Slider(
                    value: viewModel.position.inSeconds.toDouble(),
                    max: viewModel.duration.inSeconds > 0
                        ? viewModel.duration.inSeconds.toDouble()
                        : 1.0,
                    onChanged: (v) =>
                        viewModel.seekTo(Duration(seconds: v.toInt())),
                  ),
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
                      size: 50,
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
            ),
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
