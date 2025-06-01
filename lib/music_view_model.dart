import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'model.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MusicViewModel extends ChangeNotifier {
  final List<Song> _songs = [];
  final AudioPlayer _player = AudioPlayer();
  int _currentIndex = -1;
  bool _isLoading = false;
  bool _isPlayingLoading = false;
  String? _errorMessage;
  int? _retryIndex; // for retrying song when internet is restored
  Timer? _throttleTimer;
  bool _isOffline = false;
  late final StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  ProcessingState _playerState = ProcessingState.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;
  bool get isBuffering => _isBuffering;
  bool _hasInternet = true;
  bool get hasInternet => _hasInternet;
  final List<Song> _cachedSongs = [];





  List<Song> get cachedSongs => _cachedSongs;
  List<Song> get songs => _songs;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _player.playing;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;
  bool get isPlayingLoading => _isPlayingLoading;
  ProcessingState get playerState => _playerState;
  Duration get position => _position;
  Duration get duration => _duration;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _songs.length ? _songs[_currentIndex] : null;
  bool get isActuallyPlaying => _player.playing && _playerState == ProcessingState.ready;


  MusicViewModel() {
    setupPositionListener();
    monitorConnectivity();
  }



/*
  Future<void> fetchSongs(String apiUrl) async {
    _isLoading = true;
    notifyListeners();

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      _hasInternet = false;
      _isLoading = false;
      notifyListeners();
      return;
    } else {
      _hasInternet = true;
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        _songs.clear();
        _songs.addAll(data.map((e) => Song.fromJson(e)));
      }
    } catch (e) {
      // optionally set hasInternet false here on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  */


  //works fine for offline  badge with network
 /*
  Future<void> fetchSongs(String apiUrl) async {
    _isLoading = true;
    notifyListeners();

    final connectivityResult = await Connectivity().checkConnectivity();
    _hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    if (_hasInternet) {
      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          List<dynamic> data = json.decode(response.body);
          _songs.clear();
          _songs.addAll(data.map((e) => Song.fromJson(e)));
          await _scanCachedSongs();
        }
      } catch (_) {
        await _scanCachedSongs(); // fallback if API fails
      }
    } else {
      await _scanCachedSongs(); // fallback if offline
    }

    _isLoading = false;
    notifyListeners();
  }

*/

  Future<void> fetchSongs(String apiUrl) async {
    _isLoading = true;
    notifyListeners();

    // ── Determine connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _hasInternet = !connectivityResult.contains(ConnectivityResult.none);

    // ── If offline, first try to load the saved manifest
    if (!_hasInternet) {
      final manifestFile = await _getSongManifestFile();
      if (await manifestFile.exists()) {
        try {
          final rawJson = await manifestFile.readAsString();
          final rawList = jsonDecode(rawJson) as List<dynamic>;
          _songs
            ..clear()
            ..addAll(rawList.map((e) => Song.fromJson(e)));
        } catch (_) {
          // ignore corrupt manifest
        }
      }
      // scan cache for local files
      await _scanCachedSongs();
    } else {
      // ── Online path: fetch from API
      try {
        final response = await http.get(Uri.parse(apiUrl));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as List<dynamic>;

          // update in-memory list
          _songs
            ..clear()
            ..addAll(data.map((e) => Song.fromJson(e)));

          // save manifest for future offline launches
          final manifestFile = await _getSongManifestFile();
          await manifestFile.writeAsString(jsonEncode(data));

          // scan cache so 'cached' badges show
          await _scanCachedSongs();
        } else {
          // API failed - try whatever cache we have
          await _scanCachedSongs();
        }
      } catch (_) {
        // network error - fall back to cached manifest & files
        await _scanCachedSongs();
      }
    }

    _isLoading = false;
    notifyListeners();
  }




/*
  Future<void> play(int index) async {
    final isNewSong = _currentIndex != index;

    // 🔥 Trigger spinner right away
    _currentIndex = index; // ✅ Set currentIndex early
    _isPlayingLoading = true;
    notifyListeners();

    try {
      if (isNewSong) {
        await _player.stop();
        await _player.setUrl(_songs[index].url);
        await _player.seek(Duration.zero);
      }

      await _player.play();
    } catch (e) {
      // Optionally log error or show snackbar
    } finally {
      _isPlayingLoading = false;
      notifyListeners();
    }
  }


*/

/*

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

*/

  Future<String> _getLocalFilePath(String url) async {
    final dir = await getApplicationDocumentsDirectory();
    final filename = Uri.parse(url).pathSegments.last;
    return '${dir.path}/$filename';
  }


/*
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
    } catch (e) {
      _showSnackBar("Failed to play ${_songs[index].name}");

      _isPlayingLoading = false;
      notifyListeners();

      // Forcefully stop playback to update play/pause UI correctly
      await _player.stop();
      return;
    }

    if (isNewSong) {
      _isPlayingLoading = false;
      notifyListeners();
    }
  }
*/

  Future<void> play(int index) async {
    final song = _songs[index];
    final isNewSong = _currentIndex != index;

    if (isNewSong) {
      _isPlayingLoading = true;
      notifyListeners();

      _currentIndex = index;
      final filePath = await _getLocalFilePath(song.url);
      final file = File(filePath);



      // ——- waveform setup (no-audio) ——-


      try {
        if (await file.exists()) {
          await _player.setFilePath(filePath);
        } else {
          // Start streaming & download in background
          await _player.setUrl(song.url);

          // ⬇️ Download in parallel
          _downloadSong(song.url, filePath);
        }

        await _player.seek(Duration.zero);
        await _player.play();
      } catch (e) {
        _errorMessage = "Playback failed";
      } finally {
        _isPlayingLoading = false;
        notifyListeners();
      }
    } else {
      await _player.play();
    }


  }




  void _downloadSong(String url, String savePath) async {
    try {
      final dio = Dio();
      await dio.download(url, savePath);
    } catch (e) {
      debugPrint("Failed to cache song: $e");
    }
  }



  void _showSnackBar(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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

    if (_songs.length == 1) {
      // Only one song — restart it
      play(0);
      return;
    }
    final nextIndex = (_currentIndex + 1) % _songs.length;
    await play(nextIndex);
  }



  Future<void> resume() async {
    await _player.play();
    notifyListeners();
  }



/*
  Future<void> playPrevious() async {

    if (_songs.isEmpty) return;

    if (_songs.length == 1) {
      // Only one song — restart it
      play(0);
      return;
    }

    if (_currentIndex > 0) {
      await play(_currentIndex - 1);
    }
  }
*/
  Future<void> playPrevious() async {

    if (_songs.isEmpty) return;

    if (_songs.length == 1) {
      // Only one song — restart it
      play(0);
      return;
    }


    final prevIndex =
        (_currentIndex - 1 + _songs.length) % _songs.length;
    await play(prevIndex);

  }




  
  void seekTo(Duration position) {
    _player.seek(position);
  }



  Future<void> _scanCachedSongs() async {
    _cachedSongs.clear();

    final dir = await getApplicationDocumentsDirectory();
    for (var song in _songs) {
      final filename = Uri.parse(song.url).pathSegments.last;
      final filePath = '${dir.path}/$filename';
      final file = File(filePath);
      if (await file.exists()) {
        _cachedSongs.add(song);
      }
    }

    if (!_hasInternet && _cachedSongs.isNotEmpty) {
      _songs.clear();
      _songs.addAll(_cachedSongs);
    }
  }


  Future<File> _getSongManifestFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/songs_manifest.json');
  }





  void monitorConnectivity() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hadInternet = _hasInternet;
      _hasInternet = results.any((r) => r != ConnectivityResult.none);

      if (!hadInternet && _hasInternet) {
        // Internet just restored
        fetchSongs("https://mocki.io/v1/290de512-4dfb-4bd2-9696-d13de5439a00");

        // ✅ Check actual internet access before retry
        if (_retryIndex != null && await hasRealInternet()) {
          _showSnackBar("Internet restored. Retrying playback...");
          play(_retryIndex!);
        }
      }

      notifyListeners();
    });
  }






  Future<bool> hasRealInternet() async {
    try {
      final result = await http.get(Uri.parse('https://www.google.com')).timeout(
        const Duration(seconds: 3),
      );
      return result.statusCode == 200;
    } catch (_) {
      return false;
    }
  }




  void _throttledNotifyListeners() {
    if (_throttleTimer?.isActive ?? false) return;
    _throttleTimer = Timer(const Duration(milliseconds: 250), () {
      notifyListeners();
    });
  }




  void setupPositionListener() {
    _player.positionStream.listen((pos) {
      _position = pos;
      _throttledNotifyListeners();
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        _duration = dur;
        _throttledNotifyListeners();
      }
    });
    _player.playerStateStream.listen((state) {
      _isBuffering = state.processingState == ProcessingState.buffering;
      _throttledNotifyListeners();

      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
    });


    _player.playingStream.listen((isPlaying) {
      if (isPlaying && _isPlayingLoading) {
        _isPlayingLoading = false;
        _throttledNotifyListeners();
      }
    });

    /*
    _player.playerStateStream.listen((state) {
      _isBuffering = state.processingState == ProcessingState.buffering;
      _playerState = state.processingState;
      _throttledNotifyListeners();
    });
*/

    _player.playerStateStream.listen((state) {
      _playerState = state.processingState;
      _isBuffering = state.processingState == ProcessingState.buffering;

      if (state.processingState == ProcessingState.completed) {
        playNext();
      }
       _throttledNotifyListeners();
    });



  }
}