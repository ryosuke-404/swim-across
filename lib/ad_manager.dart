import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  static AdManager get instance => _instance;

  NativeAd? nativeAd;
  bool isNativeAdLoaded = false;
  bool isAdLoadingFailed = false;

  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-6913173137867777/2110701789'
      : 'ca-app-pub-6913173137867777/3799187979'; // iOS ad unit ID

  void loadAd() {
    isNativeAdLoaded = false;
    isAdLoadingFailed = false;
    nativeAd = NativeAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.italic,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('Ad loaded successfully.');
          isNativeAdLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          print('Ad failed to load: $error');
          isNativeAdLoaded = false;
          isAdLoadingFailed = true;
          nativeAd = null;
          ad.dispose();
        },
      ),
      nativeAdOptions: NativeAdOptions(
        mediaAspectRatio: MediaAspectRatio.landscape,
        // adChoicesPlacement: AdChoicesPlacement.topRight,
      ),
    )..load();
  }

  void dispose() {
    nativeAd?.dispose();
  }
}
