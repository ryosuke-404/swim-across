import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onIntroEnd() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    await prefs.setBool('isFirstLaunchAfterOnboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/menu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              _buildLanguageSelectionPage(context),
              _buildPage(
                context,
                image: Image.asset('assets/images/map_screenshot.png',
                    height: 400),
                title: 'mapTabTitle'.tr(),
                body: 'mapTabBody'.tr(),
              ),
              _buildPage(
                context,
                image: Image.asset('assets/images/calendar_screenshot.png',
                    height: 400),
                title: 'calendarTabTitle'.tr(),
                body: 'calendarTabBody'.tr(),
              ),
              _buildPage(
                context,
                image: Image.asset('assets/images/menu_screenshot.png',
                    height: 400),
                title: 'menuTabTitle'.tr(),
                body: 'menuTabBody'.tr(),
              ),
            ],
          ),
          Positioned(
            bottom: 30.0,
            left: 20.0,
            right: 20.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children:
                      List.generate(4, (index) => _buildDot(index, context)),
                ),
                Flexible(
                  child: (_currentPage != 3)
                      ? TextButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.ease,
                            );
                          },
                          child: Text('next'.tr(),
                              style: const TextStyle(fontSize: 18)),
                        )
                      : TextButton(
                          onPressed: _onIntroEnd,
                          child: Text('done'.tr(),
                              style: const TextStyle(fontSize: 18)),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectionPage(BuildContext context) {
    // A map of locale codes to their translated names
    final languages = {
      'ja': 'japanese'.tr(),
      'en': 'english'.tr(),
      'it': 'italian'.tr(),
      'ko': 'korean'.tr(),
      'nl': 'dutch'.tr(),
      'sv': 'swedish'.tr(),
      'no': 'norwegian'.tr(),
      'da': 'danish'.tr(),
      'th': 'thai'.tr(),
      'tr': 'turkish'.tr(),
      'zh': 'chinese'.tr(),
      'hi': 'hindi'.tr(),
      'es': 'spanish'.tr(),
      'fr': 'french'.tr(),
      'ar': 'arabic'.tr(),
      'bn': 'bengali'.tr(),
      'pt': 'portuguese'.tr(),
      'ru': 'russian'.tr(),
      'ur': 'urdu'.tr(),
      'id': 'indonesian'.tr(),
      'de': 'german'.tr(),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(24.0, 60.0, 24.0, 80.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('selectLanguage'.tr(),
              style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                  spacing: 12.0,
                  runSpacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: languages.entries.map((entry) {
                    final locale = Locale(entry.key);
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: context.locale == locale,
                      onSelected: (selected) {
                        if (selected) {
                          context.setLocale(locale);
                        }
                      },
                    );
                  }).toList()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required Widget image,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          image,
          const SizedBox(height: 48),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Flexible(
            child: Text(
              body,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 5),
      height: 6,
      width: _currentPage == index ? 20 : 6,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
