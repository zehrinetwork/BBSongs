import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'background_painter.dart';
import 'equalizer_animation.dart';
import 'full_screen_player.dart';
import 'model.dart';
import 'music_view_model.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final String apiUrl =
      'https://mocki.io/v1/6e31b91c-6fd8-40bf-9ebe-9908c305aeb1';

  // --- ADMOB STATE VARIABLES ---
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;
  final String _bannerAdUnitId = "ca-app-pub-3940256099942544/6300978111"; // Test ID
  final String _nativeAdUnitId = "ca-app-pub-3940256099942544/2247696110"; // Test ID

  // --- LIST STATE ---
  List<Object> _listItems = [];
  final int _adInterval = 4; // Show an ad after every 4 songs
  bool _isLoading = true; // Add a local loading state


  @override
  void initState() {
    super.initState();
    // Start the sequential loading process
    _loadData();
    _loadBannerAd();
  }

  void _loadData() async {
    final viewModel = Provider.of<MusicViewModel>(context, listen: false);

    // 1. Wait for songs to be fetched
    await viewModel.fetchSongs(apiUrl);

    // If the widget is still mounted after the async call, proceed
    if (mounted) {
      // 2. Now that songs are available, load the ad
      _loadNativeAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _nativeAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }


  void _loadNativeAd() {
    // If there are no songs, don't bother loading an ad.
    // Just build the list with what we have (which is nothing).
    final songs = Provider
        .of<MusicViewModel>(context, listen: false)
        .songs;
    if (songs.isEmpty) {
      _updateListWithAds(); // Will build an empty list and show the message
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: _nativeAdUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          // Ad loaded successfully
          setState(() {
            _nativeAd = ad as NativeAd;
            _isNativeAdLoaded = true;
            _updateListWithAds(); // Rebuild list with the loaded ad
          });
        },
        onAdFailedToLoad: (ad, error) {
          // Ad failed, so we don't have an ad to show.
          ad.dispose();
          _isNativeAdLoaded = false;
          // IMPORTANT: Still update the list, but now it will only contain songs.
          _updateListWithAds();
        },
      ),
    );
    _nativeAd!.load();
  }

  void _updateListWithAds() {
    final viewModel = Provider.of<MusicViewModel>(context, listen: false);
    List<Object> mixedList = [];
    final songsToDisplay = viewModel.songs; // Use the normal song list

    for (int i = 0; i < songsToDisplay.length; i++) {
      mixedList.add(songsToDisplay[i]);
      // Insert an ad at the specified interval, ONLY if it's loaded
      if (_isNativeAdLoaded && (i + 1) % _adInterval == 0 &&
          i < songsToDisplay.length - 1) {
        mixedList.add(_nativeAd!);
      }
    }

    setState(() {
      _listItems = mixedList;
      _isLoading = false; // Turn off the loading indicator
    });
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
        appBar: AppBar(
          title: const Text('Brahvi & Balochi Songs'),
        ),

        bottomNavigationBar: (_bannerAd != null && _isBannerAdLoaded)
            ? SafeArea(
          child: Container(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            alignment: Alignment.center,
            child: AdWidget(ad: _bannerAd!),
          ),
        )
            : null, // If ad is not loaded, show nothing

        body: Stack(children: [
          Positioned.fill(
            child: CustomPaint(
              painter: WaveBackgroundPainter(),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(top: 16),
            // Remove horizontal padding
            child: Stack(children: [
              Column(children: [
                if (!viewModel.hasInternet)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.withAlpha(100),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Center(
                      child: Text('You are offline',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      // Use our local loading state
                      if (_isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (_listItems.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.music_off,
                                  size: 64, color: Colors.white54),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Text(
                                  !viewModel.hasInternet
                                      ? 'You\'re offline and no songs are cached.'
                                      : 'No songs available. Please try again later.',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // RENDER THE LIST WITH SONGS AND ADS
                      return ListView.builder(
                        itemCount: _listItems.length,
                        itemBuilder: (context, index) {
                          final item = _listItems[index];

                          // ---- NATIVE AD WIDGET ----
                          if (item is NativeAd) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter:
                                  ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    height: 100, // Adjust height as needed
                                    decoration: BoxDecoration(
                                      color: Colors.white24.withAlpha(70),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: AdWidget(ad: item),
                                  ),
                                ),
                              ),
                            );
                          }

                          // ---- SONG TILE WIDGET ----
                          if (item is Song) {
                            final song = item;
                            // Find the original index for the player logic
                            final originalIndex = viewModel.songs.indexOf(song);
                            final isCurrent = viewModel.currentIndex ==
                                originalIndex;
                            final isCached = viewModel.cachedSongs.contains(
                                song);

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 10, sigmaY: 10),
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
                                        if (isCurrent) {
                                          viewModel.isPlaying
                                              ? viewModel.pause()
                                              : viewModel.play(originalIndex);
                                        } else {
                                          viewModel.play(originalIndex);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius
                                                  .circular(14),
                                              child: CachedNetworkImage(
                                                imageUrl: song.image,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                placeholder: (c, u) =>
                                                const SizedBox(
                                                  width: 60,
                                                  height: 60,
                                                  child: Center(
                                                      child: CircularProgressIndicator(
                                                          strokeWidth: 2)),
                                                ),
                                                errorWidget: (c, u, e) =>
                                                    Image.asset(
                                                      'assets/default_cover.png',
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          song.name,
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight
                                                                .w600,
                                                            color: Colors.white,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      if (isCached)
                                                        const Icon(
                                                            Icons.download_done,
                                                            size: 16,
                                                            color: Colors
                                                                .greenAccent),
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
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Builder(
                                              builder: (_) {
                                                if (isCurrent) {
                                                  if (viewModel
                                                      .isPlayingLoading ||
                                                      viewModel.isBuffering) {
                                                    return const SizedBox(
                                                      height: 24,
                                                      width: 24,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<
                                                            Color>(
                                                            Colors.white),
                                                      ),
                                                    );
                                                  }
                                                  if (viewModel.isPlaying &&
                                                      !viewModel.isBuffering &&
                                                      viewModel.playerState ==
                                                          ProcessingState
                                                              .ready) {
                                                    return GestureDetector(
                                                      behavior: HitTestBehavior
                                                          .translucent,
                                                      onTap: () =>
                                                          viewModel.pause(),
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(
                                                            4.0),
                                                        child: EqualizerAnimation(
                                                            isPaused: false),
                                                      ),
                                                    );
                                                  }
                                                }
                                                return IconButton(
                                                  icon: const Icon(
                                                      Icons.play_arrow,
                                                      size: 28,
                                                      color: Colors.white),
                                                  onPressed: () =>
                                                      viewModel.play(
                                                          originalIndex),
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
                          }
                          // Return an empty container for any other case
                          return Container();
                        },
                      );
                    },
                  ),
                ),
                // The mini-player logic remains the same
                if (viewModel.currentSong != null)
                  _buildMiniPlayer(context, viewModel),
              ]),
            ]),
          )
        ]));
  }

  Widget _buildMiniPlayer(BuildContext context, MusicViewModel viewModel) {
    // This method remains unchanged from your original code
    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      offset: Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: 1.0,
        child: GestureDetector(
          onVerticalDragUpdate: (d) {
            if (d.primaryDelta! < -10) _openFullPlayer(context);
          },
          onTap: () => _openFullPlayer(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF507180), Color(0xFF10232B)],
              ),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: const Color.fromARGB(255, 62, 66, 67),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
                const BoxShadow(
                  color: Color.fromARGB(51, 0, 0, 0),
                  blurRadius: 4,
                  spreadRadius: -2,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: const Color.fromARGB(13, 255, 255, 255),
                width: 0.6,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                      icon: const Icon(
                          Icons.skip_previous, color: Colors.white),
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
                        viewModel.isActuallyPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
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
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6,
                    activeTrackColor: const Color(0xFF235C70),
                    inactiveTrackColor: const Color(0xFF54676E),
                    trackShape: const RoundedRectSliderTrackShape(),
                    thumbColor: const Color(0xFF72C7E3),
                    thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayColor: Colors.orangeAccent,
                    overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 10),
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
                    Text(_formatTime(viewModel.position),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                    Text(_formatTime(viewModel.duration),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          builder: (_, controller) =>
              SingleChildScrollView(
                controller: controller,
                child: FullScreenPlayer(),
              ),
        );
      },
    );
  }
}