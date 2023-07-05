import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'main.dart';


class AdPreloader {
  AdPreloader({bool initAdMob = false}) {
    if (initAdMob) init();
  }

  final List<AdContainer> _adList = List<AdContainer>.empty(growable: true);

  //Init admob with correct adapters
  Future<void> init() async {
      await MobileAds.instance.initialize().then((initializationStatus) {
        initializationStatus.adapterStatuses.forEach((key, value) {
          debugPrint(
              'Adapter status for $key: ${value.description} ${value.state.toString()}');
        });
      });
  }

  //inlineAdaptive == true -->
  AdContainer get(
      AdSize? inlineSize,
      AnchoredAdaptiveBannerAdSize? size,
      VoidCallback onComplete) {
    //Get first element we find that is equal or create new and return
    AdContainer ad = _adList.firstWhere((element) => element.inlineSize == inlineSize && element.size == size, orElse: () {
      AdContainer newAd = AdContainer(inlineSize: inlineSize, size: size, onComplete: onComplete);
      _adList.add(newAd);
      return newAd;
    });

    return ad;
  }
}

//Class to actual load the ad
class AdContainer extends Equatable {
  final AdSize? inlineSize;
  final AnchoredAdaptiveBannerAdSize? size;
  final VoidCallback onComplete;

  AdContainer({this.inlineSize, this.size, required this.onComplete}) {
    if (!_adLoaded) loadAd();
  }

  //Returns list of objects used to compare classes
  @override
  List<Object?> get props => [inlineSize, size];

  //Return if the ad is loaded
  bool _adLoaded = false;

  get adLoaded => _adLoaded;
  BannerAd? _banner;
  get banner => _banner;
  AdSize? _inLineCorrected;
  get inlineSizeCorrected => _inLineCorrected;

  void loadAd() async {

    //Banner TestAD
    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-3940256099942544/2934735716';

    try {
      _banner = BannerAd(
          adUnitId: adUnitId,
          request: const AdRequest(),
          size: inlineSize != null ? inlineSize! : size!,
          listener: BannerAdListener(onAdLoaded: (Ad ad) async {
            BannerAd bannerAdTemp = ad as BannerAd;
            if (inlineSize != null) {
              _inLineCorrected = await bannerAdTemp.getPlatformAdSize();
              if (inlineSize == null) {
                debugPrint(
                    'Error: getPlatformAdSize() returned null for $banner');
                return;
              }
            }

            _banner = bannerAdTemp;
            _adLoaded = true;
            onComplete();
          },

              ///Handle loading error
              onAdFailedToLoad: (Ad ad, LoadAdError error) async {
                debugPrint('$BannerAd failedToLoad: $error');
                _adLoaded = false;

                //Clear resources
                await ad.dispose();
                await _banner?.dispose();
                _banner = null;
                onComplete();
              },
              onAdOpened: (Ad ad) => debugPrint('$BannerAd onAdOpened.'),
              onAdClosed: (Ad ad) => debugPrint('$BannerAd onAdClosed.'),
              onAdImpression: (Ad ad) {
                debugPrint(
                    '########## $BannerAd from impression given.');
                MyApp.showMaterialBanner("Banner impression given...");
              }));
        return _banner!.load();
    } catch (e) {
      debugPrint("############# BannerAd error ${e.toString()}");
      _banner = null;
      _adLoaded = false;
      onComplete();
    }
  }
}
