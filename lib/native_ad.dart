import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class NativeAdManager extends ChangeNotifier {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  NativeAd? get nativeAd => _nativeAd;
  bool get isAdLoaded => _isAdLoaded;

  // Use test ad unit IDs for development
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256098942573/2247696110';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256098942573/3986624511';
    }
    throw UnsupportedError("Unsupported platform");
  }

  void loadAd() {
    // If an ad is already loaded, don't load another one.
    if (_isAdLoaded) {
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      // The factoryId must match the one defined in the native code.
      // For this example, we'll use a simple string.
      // For Android, this is not strictly needed for simple layouts.
      // For iOS, you MUST register a factory with this ID.
      factoryId: 'adFactoryExample',
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          print('$NativeAd loaded.');
          _isAdLoaded = true;
          // Notify listeners that the ad state has changed.
          notifyListeners();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$NativeAd failed to load: $error');
          ad.dispose();
          _isAdLoaded = false;
          // Notify listeners even on failure, so the UI can update.
          notifyListeners();
        },
        onAdClicked: (Ad ad) => print('$NativeAd clicked.'),
        onAdImpression: (Ad ad) => print('$NativeAd impression.'),
        onAdClosed: (Ad ad) => print('$NativeAd closed.'),
        onAdOpened: (Ad ad) => print('$NativeAd opened.'),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }
}