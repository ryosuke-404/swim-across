import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:swimming_trip/ad_manager.dart';

class AdDialog extends StatefulWidget {
  const AdDialog({super.key});

  @override
  State<AdDialog> createState() => _AdDialogState();
}

class _AdDialogState extends State<AdDialog> {
  final AdManager _adManager = AdManager.instance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(10),
      content: SizedBox(
        width: 360, // Increase width
        height: 320, // Increase height
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: AdWidget(ad: _adManager.nativeAd!),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('閉じる'),
            ),
          ],
        ),
      ),
    );
  }
}
