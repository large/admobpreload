import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'admobpreload.dart';
import 'anchored_adaptive_banner_adSize.dart';
import 'main.dart';

class BannerPreloadAD extends StatefulWidget {
  final bool bannerSize;
  final bool inlineAdaptive;
  final int inlineMaxHeight;

  const BannerPreloadAD(
      {Key? key,
        required this.bannerSize,
        this.inlineAdaptive = false,
        this.inlineMaxHeight = 250})
      : super(key: key);

  @override
  BannerPreloadADState createState() => BannerPreloadADState();
}

class BannerPreloadADState extends State<BannerPreloadAD> with WidgetsBindingObserver {

  //This is important for iOS but same logic used on Android.

  //Get preloader
  AdPreloader adPreloader = GetIt.instance<AdPreloader>();
  AdContainer? adContainer;

  @override
  void initState() {
    super.initState();

    //Only add observerer if ads are shown
    //WidgetsBinding.instance.addObserver(this);
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    //WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();

    // Assigning the size of adaptive banner ad after adState initialization.
    AnchoredAdaptiveBannerAdSize? size;
    AdSize? inlineSize;

    //Make sure mounted if used
    if (context.mounted) {
      if (widget.inlineAdaptive) {
        inlineSize = AdSize.getInlineAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate(),
            widget.inlineMaxHeight);
      } else {
        size = await anchoredAdaptiveBannerAdSize(context);
      }
    } else {
      debugPrint("anchoredAdapter not mounted... :(");
    }

    //No size, just return 320 width...
    if (size == null && !widget.inlineAdaptive || widget.bannerSize) {
      size =
      await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(320);
    }

    //Load the ad
    setState(() {
      adContainer = adPreloader.get(inlineSize, size, () {
        setState(() {
          if(adContainer?.adLoaded)
            {
              debugPrint("Ad was loaded, show it now");
            }
            else
              {
                MyApp.showMaterialBanner("Error: Could not load ad...");
              }
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    //If banner is null or showAd (isload variable) is set
    if (adContainer == null || !adContainer?.adLoaded) {
      // Generally banner is null for very less time only until it get assigned in didChangeDependencies.
      // Never think that banner will be null if ads fails loads.
      // To make banner null change the condition in didChangeDependencies or assign null to bannerAdUnitId in AdState().
      return const Text("Waiting for ad to load");
    } else {
      try {

        Widget ad = Container(
          key: widget.key,
          alignment: Alignment.center,
          color: Colors.transparent,
          width: adContainer!.banner.size.width.toDouble(),
          height: widget.inlineAdaptive
              ? adContainer!.inlineSizeCorrected?.height.toDouble()
              : adContainer!.banner!.size.height.toDouble(),
          child: AdWidget(
            ad: adContainer!.banner!,
          ),
        );

        return ad;
      } catch (e) {
        //Implement timer to refresh if the ad failed...
        Timer(const Duration(seconds: 5), () {
          if (mounted) setState(() {});
          debugPrint("Ad timer refresh 5s...");
        });
        return Text("Alternative thingy");
      }
    }
  }

  String generateRandomString(int lengthOfString){
    final random = Random();
    const allChars='AaBbCcDdlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1EeFfGgHhIiJjKkL234567890';
    // below statement will generate a random string of length using the characters
    // and length provided to it
    final randomString = List.generate(lengthOfString,
            (index) => allChars[random.nextInt(allChars.length)]).join();
    return randomString;    // return the generated string
  }

}
