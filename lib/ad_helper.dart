import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdHelper {
  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;
  static const int maxFailedLoadAttempts = 3;

  // TODO: Replace with your real Ad Unit ID before publishing
  final String _interstitialAdUnitId = "ca-app-pub-3940256099942544/1033173712"; // Test ID

  void createInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;
          if (_interstitialLoadAttempts <= maxFailedLoadAttempts) {
            createInterstitialAd();
          }
        },
      ),
    );
  }

  // This method now handles frequency capping
  Future<void> showInterstitialAd() async {
    // Check if the ad is even loaded
    if (_interstitialAd == null) {
      return;
    }

    // Frequency Capping Logic
    final prefs = await SharedPreferences.getInstance();
    int playerCloseCounter = prefs.getInt('playerCloseCounter') ?? 0;
    playerCloseCounter++;

    // Show ad every 3rd time the player is closed.
    if (playerCloseCounter % 3 == 0) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          createInterstitialAd(); // Pre-load the next one
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          createInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null; // Ad can only be shown once
    }

    // Save the new count
    await prefs.setInt('playerCloseCounter', playerCloseCounter);
  }
}