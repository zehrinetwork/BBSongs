import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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
    return

      Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
      decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white24),
      boxShadow: [
      BoxShadow(
      color: Colors.white24,
      blurRadius: 12,
      offset: const Offset(0, 4),
      ),
      ],
      ),
      child: InkWell(
      onTap: () {
      if (viewModel.currentIndex == index) {
      viewModel.isPlaying ? viewModel.pause() : viewModel.play(index);
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
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
      imageUrl: song.image,
      width: 60,
      height: 60,
      fit: BoxFit.cover,
      placeholder: (context, url) => const SizedBox(
      width: 60,
      height: 60,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
      ),
      const SizedBox(width: 14),
      Expanded(
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      if (viewModel.isPlayingLoading || viewModel.isBuffering) {
      return const SizedBox(
      height: 24,
      width: 24,
      child: CircularProgressIndicator(
      strokeWidth: 2,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
      );
      } else {
      return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
      if (viewModel.isPlaying) {
      viewModel.pause();
      } else {
      viewModel.play(index);
      }
      },
      child: Padding(
      padding: const EdgeInsets.all(4.0),
      child: EqualizerAnimation(isPaused: !viewModel.isPlaying),
      ),
      );
      }
      } else {
      return IconButton(
      icon: const Icon(Icons.play_arrow, size: 28, color: Colors.white),
      onPressed: () => viewModel.play(index),
      );
      }
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


  }
}