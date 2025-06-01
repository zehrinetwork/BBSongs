import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'background_painter.dart';
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
        appBar: AppBar(title: const Text('Brahvi & Balochi Songs')),
        body:

        Stack(
          children: [
            // ─── Wave Background ───
            Positioned.fill(
              child: CustomPaint(
                painter: WaveBackgroundPainter(),
              ),
            ),

            // ─── Your Main Content ───
            Container(
              padding: const EdgeInsets.all(16),



        child:





        Stack(children: [
          Column(children: [
            if (!viewModel.hasInternet)
              Container(
                width: double.infinity,
                color: Colors.orange.withAlpha(100),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Center(
                  child: Text(
                    'You are offline',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),

  /*
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
                                            if (viewModel.currentIndex ==
                                                index) {
                                              if (viewModel.isPlayingLoading ||
                                                  viewModel.isBuffering) {
                                                return const SizedBox(
                                                  height: 24,
                                                  width: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<
                                                        Color>(Colors.white),
                                                  ),
                                                );
                                              }

                                              // list song

                                              if (viewModel.isPlaying &&
                                                  !viewModel.isBuffering &&
                                                  viewModel.playerState ==
                                                      ProcessingState.ready) {
                                                return GestureDetector(
                                                  behavior: HitTestBehavior
                                                      .translucent,
                                                  onTap: () =>
                                                      viewModel.pause(),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .all(4.0),
                                                    child: EqualizerAnimation(
                                                        isPaused: false),
                                                  ),
                                                );
                                              }



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
*/

    Expanded(
    child: Builder(
    builder: (context) {
    // 1️⃣  Loading spinner
    if (viewModel.isLoading && viewModel.songs.isEmpty) {
    return const Center(child: CircularProgressIndicator());
    }

    //------------------------------------------------------------
    // 2️⃣  Decide which song list to show
    //------------------------------------------------------------
    final bool offline         = !viewModel.hasInternet;
    final bool hasCachedSongs  = viewModel.cachedSongs.isNotEmpty;
    final songsToDisplay       = offline && hasCachedSongs
    ? viewModel.cachedSongs        // show cached list when offline
        : viewModel.songs;             // otherwise use normal list

    //------------------------------------------------------------
    // 3️⃣  Nothing to show – present friendly message
    //------------------------------------------------------------
    if (songsToDisplay.isEmpty) {
    return Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    const Icon(Icons.music_off, size: 64, color: Colors.white54),
    const SizedBox(height: 16),
    Text(
    offline
    ? 'You\'re offline and no songs are cached.'
        : 'No songs available.',
    style: const TextStyle(color: Colors.white70, fontSize: 16),
    textAlign: TextAlign.center,
    ),
    ],
    ),
    );
    }

    //------------------------------------------------------------
    // 4️⃣  Render the list (all your original row UI unchanged)
    //------------------------------------------------------------
    return ListView.builder(
    itemCount: songsToDisplay.length,
    itemBuilder: (context, index) {
    final song      = songsToDisplay[index];
    final isCurrent = viewModel.currentIndex == index;
    final isCached  = viewModel.cachedSongs.contains(song);

    /* ----- keep your existing row widget below -----
             The only extra we add is a tiny “cached” badge,
             but you can remove it if you prefer.            */

    return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
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
    // album art with default fallback
    ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: CachedNetworkImage(
    imageUrl: song.image,
    width: 60,
    height: 60,
    fit: BoxFit.cover,
    placeholder: (c, u) => const SizedBox(
    width: 60,
    height: 60,
    child: Center(
    child: CircularProgressIndicator(strokeWidth: 2),
    ),
    ),
    errorWidget: (c, u, e) => Image.asset(
    'assets/default_cover.png',
    width: 60,
    height: 60,
    fit: BoxFit.cover,
    ),
    ),
    ),

    const SizedBox(width: 14),

    // title + description (+ cached badge)
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    Expanded(
    child: Text(
    song.name,
    style: GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    ),
    ),
    ),
    if (isCached)
    const Icon(Icons.download_done,
    size: 16, color: Colors.greenAccent),
    ],
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

    // play / equalizer / spinner (unchanged logic)
    Builder(
    builder: (_) {
    if (isCurrent) {
    if (viewModel.isPlayingLoading ||
    viewModel.isBuffering) {
    return const SizedBox(
    height: 24,
    width: 24,
    child: CircularProgressIndicator(
    strokeWidth: 2,
    valueColor: AlwaysStoppedAnimation<Color>(
    Colors.white),
    ),
    );
    }
    if (viewModel.isPlaying &&
    !viewModel.isBuffering &&
    viewModel.playerState ==
    ProcessingState.ready) {
    return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: () => viewModel.pause(),
    child: const Padding(
    padding: EdgeInsets.all(4.0),
    child: EqualizerAnimation(isPaused: false),
    ),
    );
    }
    }
    return IconButton(
    icon: const Icon(Icons.play_arrow,
    size: 28, color: Colors.white),
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
    );
    },
    ),
    ),




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
                          color: Color(0xFF131B1E),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF20323A),
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
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/default_cover.png',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      );
                                    },
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

                      /*
                            Slider(
                              value: viewModel.position.inSeconds.toDouble(),
                              max: viewModel.duration.inSeconds > 0
                                  ? viewModel.duration.inSeconds.toDouble()
                                  : 1.0,
                              onChanged: (v) => viewModel
                                  .seekTo(Duration(seconds: v.toInt())),
                              activeColor: Colors.orange,
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
        ]))]));
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
