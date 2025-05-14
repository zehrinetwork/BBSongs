import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import 'model.dart';

class MusicViewModel extends ChangeNotifier {
  final List<Song> _songs = [];
  final AudioPlayer _player = AudioPlayer();
  int _currentIndex = -1;
  bool _isLoading = false;
  bool _isPlayingLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;
  bool get isBuffering => _isBuffering;


  List<Song> get songs => _songs;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _player.playing;
  bool get isLoading => _isLoading;
  bool get isPlayingLoading => _isPlayingLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _songs.length ? _songs[_currentIndex] : null;

  MusicViewModel() {
    setupPositionListener();
  }

  Future<void> fetchSongs(String apiUrl) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _songs.clear();
        _songs.addAll(data.map((e) => Song.fromJson(e)));
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> play(int index) async {
    final isNewSong = _currentIndex != index;

    if (isNewSong) {
      _isPlayingLoading = true;
      notifyListeners();
    }

    try {
      if (isNewSong) {
        _currentIndex = index;
        await _player.setUrl(_songs[_currentIndex].url);
        await _player.seek(Duration.zero);
      }
      await _player.play();
    } finally {
      if (isNewSong) {
        _isPlayingLoading = false;
        notifyListeners();
      }
    }
  }



  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    notifyListeners();
  }

  Future<void> playNext() async {
    if (_songs.isEmpty) return;
    final nextIndex = (_currentIndex + 1) % _songs.length;
    await play(nextIndex);
  }

  Future<void> resume() async {
    await _player.play();
    notifyListeners();
  }


  Future<void> playPrevious() async {
    if (_currentIndex > 0) {
      await play(_currentIndex - 1);
    }
  }

  void seekTo(Duration position) {
    _player.seek(position);
  }

  void setupPositionListener() {
    _player.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        notifyListeners();
      }
    });
    _player.playerStateStream.listen((state) {
      _isBuffering = state.processingState == ProcessingState.buffering;
      notifyListeners();

      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });

    _player.playingStream.listen((isPlaying) {
      if (isPlaying && _isPlayingLoading) {
        _isPlayingLoading = false;
        notifyListeners();
      }
    });



  }
}