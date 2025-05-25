import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'equalizer_animation.dart';
import 'full_screen_player.dart';
import 'music_view_model.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final String apiUrl =
      'https://mocki.io/v1/290de512-4dfb-4bd2-9696-d13de5439a00'; // Replace with your actual API URL

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
      if (viewModel.hasInternet &&
          !viewModel.isLoading &&
          viewModel.songs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Back online. Reloading songs...')),
        );
      }
    });

    return Scaffold(
        appBar: AppBar(title: const Text('Music Player')),
        body: Stack(children: [
          Column(children: [
            if (!viewModel.hasInternet)
              Container(
                width: double.infinity,
                color: Colors.orangeAccent,
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white24.withAlpha(70),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12.withAlpha(70),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () {
                                    if (viewModel.currentIndex == index) {
                                      viewModel.isPlaying
                                          ? viewModel.pause()
                                          : viewModel.play(index);
                                    } else {
                                      viewModel.play(index);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: CachedNetworkImage(
                                            imageUrl: song.image,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const SizedBox(
                                              width: 60,
                                              height: 60,
                                              child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2)),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(Icons.error),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                song.name,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                song.description,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 13,
                                                  color: Colors.white70,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Builder(
                                          builder: (_) {


                                                if (viewModel.currentIndex == index) {
                                                  if (viewModel.isPlayingLoading || viewModel.isBuffering ) {
                                                    return const SizedBox(
                                                      height: 24,
                                                      width: 24,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                      ),
                                                    );
                                                  }

                                                  // Show equalizer only if the song is fully loaded and playing
                                                  if (viewModel.isPlaying) {
                                                    return GestureDetector(
                                                      behavior: HitTestBehavior.translucent,
                                                      onTap: () => viewModel.pause(),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(4.0),
                                                        child: EqualizerAnimation(isPaused: false),
                                                      ),
                                                    );
                                                  }

                                                  // Song is ready but paused
                                                  return IconButton(
                                                    icon: const Icon(Icons.play_arrow, size: 28, color: Colors.white),
                                                    onPressed: () => viewModel.play(index),
                                                  );
                                                }

                                                // For all other songs
                                                return IconButton(
                                                  icon: const Icon(Icons.play_arrow, size: 28, color: Colors.white),
                                                  onPressed: () => viewModel.play(index),
                                                );
                                              },




                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            /*
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
        : viewModel.currentSong != null ? viewModel.resume()
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
*/

/*
    if (viewModel.currentSong != null)

      Positioned(
        left: 16,
        right: 16,
        bottom: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white12.withAlpha(70), // modern semi-transparent dark
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Song Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  viewModel.currentSong!.image,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 12),

              // Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      viewModel.currentSong!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      viewModel.currentSong!.description,
                      style: TextStyle(
                        color: Colors.white.withAlpha(160),
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Controls: Previous - Play/Pause - Next
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.white),
                onPressed: viewModel.playPrevious,
              ),
              viewModel.isBuffering
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : IconButton(
                icon: Icon(
                  viewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  viewModel.isPlaying
                      ? viewModel.pause()
                      : viewModel.play(viewModel.currentIndex);
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.white),
                onPressed: viewModel.playNext,
              ),
            ],
          ),
        ),
      ),


    ]
    ),
    ]));


 */

            // ───────── Mini-Player Widget (place inside Stack) ─────────
            if (viewModel.currentSong != null)
              AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                offset: Offset.zero, // slides up from bottom
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: 1.0, // fades in
                  child: Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onVerticalDragUpdate: (d) {
                        if (d.primaryDelta! < -10) _openFullPlayer(context);
                      },
                      onTap: () => _openFullPlayer(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.95),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ─── Controls Row ───
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    viewModel.currentSong!.image,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        viewModel.currentSong!.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        viewModel.currentSong!.description,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_previous,
                                      color: Colors.white),
                                  onPressed: viewModel.playPrevious,
                                ),


    (viewModel.isPlayingLoading || viewModel.isBuffering)
    ? const SizedBox(
    height: 24,
    width: 24,
    child: CircularProgressIndicator(
    strokeWidth: 2,
    color: Colors.white,
    ),
    )
        : IconButton(
    icon: Icon(
    viewModel.isActuallyPlaying ? Icons.pause : Icons.play_arrow,
    color: Colors.white,
    ),
    onPressed: () {
    viewModel.isPlaying
    ? viewModel.pause()
        : viewModel.play(viewModel.currentIndex);
    },
    ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next,
                                      color: Colors.white),
                                  onPressed: viewModel.playNext,
                                ),
                              ],
                            ),

                            // ─── Slider ───
                            Slider(
                              value: viewModel.position.inSeconds.toDouble(),
                              max: viewModel.duration.inSeconds > 0
                                  ? viewModel.duration.inSeconds.toDouble()
                                  : 1.0,
                              onChanged: (v) => viewModel
                                  .seekTo(Duration(seconds: v.toInt())),
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                            ),

                            // ─── Timer Text ───
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(viewModel.position),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                Text(
                                  _formatTime(viewModel.duration),
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ])
        ]));
  }

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: true,
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 1.0,
          builder: (_, controller) => SingleChildScrollView(
            controller: controller,
            child: FullScreenPlayer(), // from full_screen_player.dart
          ),
        );
      },
    );
  }
}
