import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swimming_trip/calendar_screen.dart';
import 'package:swimming_trip/goal_time.dart';
import 'package:swimming_trip/menu_screen.dart';
import 'package:swimming_trip/training_menu.dart';
import 'package:swimming_trip/splash_screen.dart';
import 'package:swimming_trip/map_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:swimming_trip/ad_manager.dart';
import 'package:swimming_trip/ad_dialog.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  AdManager.instance.loadAd();
  await EasyLocalization.ensureInitialized();
  await initializeDateFormatting(); // No need for locale here with easy_localization

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ja'), // Japanese
        Locale('en'), // English
        Locale('it'), // Italian
        Locale('ko'), // Korean
        Locale('nl'), // Dutch
        Locale('sv'), // Swedish
        Locale('no'), // Norwegian
        Locale('da'), // Danish
        Locale('th'), // Thai
        Locale('tr'), // Turkish
        Locale('zh'), // Chinese
        Locale('hi'), // Hindi
        Locale('es'), // Spanish
        Locale('fr'), // French
        Locale('ar'), // Arabic
        Locale('bn'), // Bengali
        Locale('pt'), // Portuguese
        Locale('ru'), // Russian
        Locale('ur'), // Urdu
        Locale('id'), // Indonesian
        Locale('de') // German
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ja'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue.shade600,
      primary: Colors.blue.shade600,
      secondary: Colors.teal.shade300,
      background: Colors.blue.shade50,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.black87,
      onBackground: Colors.black87,
      onSurface: Colors.black87,
    );

    final textTheme = GoogleFonts.notoSansJpTextTheme(
      ThemeData.light().textTheme,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Swimming Trip',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        colorScheme: colorScheme,
        textTheme: textTheme
            .apply(
              bodyColor: colorScheme.onBackground,
              displayColor: colorScheme.onBackground,
            )
            .copyWith(
              labelLarge: textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
        useMaterial3: true,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          backgroundColor: colorScheme.surface,
          elevation: 8,
        ),
      ),
      home: const SplashScreen(),
      routes: {'/menu': (context) => const MainScreen()},
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String _selectedPeriod = 'monthly';

  late AnimationController _bottomNavAnimationController;
  Timer? _adTimer;

  // --- State Management ---
  Map<DateTime, List<double>> _events = {};
  List<TrainingMenu> _trainingMenus = [];
  List<GoalTime> _goalTimes = [];

  final Map<String, LatLng?> _startPoints = {
    'weekly': null,
    'monthly': null,
    'yearly': null,
  };
  final Map<String, LatLng?> _endPoints = {
    'weekly': null,
    'monthly': null,
    'yearly': null,
  };
  final Map<String, double> _totalDistances = {
    'weekly': 0.0,
    'monthly': 0.0,
    'yearly': 0.0,
  };

  LatLng? _currentPosition;
  String _instructionText = '';

  double _goalWeekly = 0.0, _goalMonthly = 0.0, _goalYearly = 0.0;
  double _swamDistanceWeekly = 0.0,
      _swamDistanceMonthly = 0.0,
      _swamDistanceYearly = 0.0;

  double _totalSwamDistance = 0.0;
  double _userWeight = 70.0; // Default weight

  @override
  void initState() {
    super.initState();
    _loadAllData();

    _bottomNavAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _adTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (AdManager.instance.isNativeAdLoaded) {
        _showAdDialog();
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _bottomNavAnimationController.dispose();
    super.dispose();
  }

  void _showAdDialog() {
    if (AdManager.instance.isNativeAdLoaded && AdManager.instance.nativeAd != null) {
      showDialog(
        context: context,
        builder: (context) => const AdDialog(),
      ).then((_) {
        // Ad closed, load a new one for the next time.
        AdManager.instance.dispose();
        AdManager.instance.loadAd();
      });
    }
  }



  // Add this method to handle locale changes
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will be called when the locale changes, triggering a rebuild.
    // We can re-run calculations that depend on the locale if needed.
    // In our case, instructionText depends on the locale.
    _recalculateAll();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    // Load events
    final eventsString = prefs.getString('swim_events');
    if (eventsString != null) {
      final Map<String, dynamic> decodedEvents = json.decode(eventsString);
      _events = decodedEvents.map(
        (key, value) => MapEntry(
          DateTime.parse(key),
          (value as List).map((item) => item as double).toList(),
        ),
      );
    }
    // Load training menus
    final menusString = prefs.getString('training_menus');
    if (menusString != null) {
      final List<dynamic> decodedMenus = json.decode(menusString);
      _trainingMenus =
          decodedMenus.map((json) => TrainingMenu.fromJson(json)).toList();
    }
    // Load routes
    for (var period in ['weekly', 'monthly', 'yearly']) {
      final startLat = prefs.getDouble('route_${period}_start_lat');
      final startLng = prefs.getDouble('route_${period}_start_lng');
      final endLat = prefs.getDouble('route_${period}_end_lat');
      final endLng = prefs.getDouble('route_${period}_end_lng');
      if (startLat != null && startLng != null) {
        _startPoints[period] = LatLng(startLat, startLng);
      }
      if (endLat != null && endLng != null) {
        _endPoints[period] = LatLng(endLat, endLng);
      }
    }
    // Load goals
    _goalWeekly = prefs.getDouble('goal_weekly') ?? 0.0;
    _goalMonthly = prefs.getDouble('goal_monthly') ?? 0.0;
    _goalYearly = prefs.getDouble('goal_yearly') ?? 0.0;

    // Load user weight
    _userWeight = prefs.getDouble('user_weight') ?? 70.0;

    // Load goal times
    final goalTimesString = prefs.getString('goal_times');
    if (goalTimesString != null) {
      final List<dynamic> decodedGoalTimes = json.decode(goalTimesString);
      _goalTimes =
          decodedGoalTimes.map((json) => GoalTime.fromJson(json)).toList();
    }

    _recalculateAll(isInit: true);
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    // Save events
    final eventsToSave = _events.map(
      (key, value) => MapEntry(key.toIso8601String(), value),
    );
    await prefs.setString('swim_events', json.encode(eventsToSave));
    // Save menus
    final menusToSave = _trainingMenus.map((menu) => menu.toJson()).toList();
    await prefs.setString('training_menus', json.encode(menusToSave));
    // Save routes
    for (var period in ['weekly', 'monthly', 'yearly']) {
      final startPoint = _startPoints[period];
      final endPoint = _endPoints[period];
      if (startPoint != null) {
        await prefs.setDouble('route_${period}_start_lat', startPoint.latitude);
        await prefs.setDouble(
          'route_${period}_start_lng',
          startPoint.longitude,
        );
      } else {
        await prefs.remove('route_${period}_start_lat');
        await prefs.remove('route_${period}_start_lng');
      }
      if (endPoint != null) {
        await prefs.setDouble('route_${period}_end_lat', endPoint.latitude);
        await prefs.setDouble('route_${period}_end_lng', endPoint.longitude);
      } else {
        await prefs.remove('route_${period}_end_lat');
        await prefs.remove('route_${period}_end_lng');
      }
    }
    // Save goals
    await prefs.setDouble('goal_weekly', _goalWeekly);
    await prefs.setDouble('goal_monthly', _goalMonthly);
    await prefs.setDouble('goal_yearly', _goalYearly);

    // Save user weight
    await prefs.setDouble('user_weight', _userWeight);

    // Save goal times
    final goalTimesToSave = _goalTimes.map((gt) => gt.toJson()).toList();
    await prefs.setString('goal_times', json.encode(goalTimesToSave));
  }

  void _handleCalendarUpdate(Map<DateTime, List<double>> updatedEvents) {
    setState(() {
      _events = updatedEvents;
    });
    _recalculateAll();
  }

  void _handleGoalUpdate(double weekly, double monthly, double yearly) {
    setState(() {
      _goalWeekly = weekly;
      _goalMonthly = monthly;
      _goalYearly = yearly;
    });
    _recalculateAll();
  }

  void _handleMenuUpdate(List<TrainingMenu> updatedMenus) {
    setState(() {
      _trainingMenus = updatedMenus;
    });
    _saveAllData();
  }

  void _handleUserWeightUpdate(double newWeight) {
    setState(() {
      _userWeight = newWeight;
    });
    _saveAllData();
  }

  void _handleGoalTimeUpdate(List<GoalTime> updatedGoalTimes) {
    setState(() {
      _goalTimes = updatedGoalTimes;
    });
    _saveAllData();
  }

  void _handleMapLongPress(LatLng latlng) {
    setState(() {
      final start = _startPoints[_selectedPeriod];
      if (start == null) {
        _startPoints[_selectedPeriod] = latlng;
      } else if (_endPoints[_selectedPeriod] == null) {
        _endPoints[_selectedPeriod] = latlng;
      }
    });
    _recalculateAll();
  }

  void _resetRoute() {
    setState(() {
      _startPoints[_selectedPeriod] = null;
      _endPoints[_selectedPeriod] = null;
      switch (_selectedPeriod) {
        case 'weekly':
          _goalWeekly = 0;
          break;
        case 'monthly':
          _goalMonthly = 0;
          break;
        case 'yearly':
          _goalYearly = 0;
          break;
      }
    });
    _recalculateAll();
  }

  void _handlePeriodChange(String newPeriod) {
    setState(() => _selectedPeriod = newPeriod);
    // Recalculation is handled by didUpdateWidget in MapScreen and state update here
    _recalculateAll();
  }

  void _recalculateAll({bool isInit = false}) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    // Calculate distances for periods
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final startOfMonth = DateTime.utc(now.year, now.month, 1);
    final startOfYear = DateTime.utc(now.year, 1, 1);
    _swamDistanceWeekly = _getDistanceForPeriod(startOfWeek, today);
    _swamDistanceMonthly = _getDistanceForPeriod(startOfMonth, today);
    _swamDistanceYearly = _getDistanceForPeriod(startOfYear, today);
    _totalSwamDistance = _events.values
        .expand((distances) => distances)
        .fold(0.0, (prev, dist) => prev + dist);

    // Calculate route and current position
    final start = _startPoints[_selectedPeriod];
    final end = _endPoints[_selectedPeriod];
    if (start != null && end != null) {
      final routeDistance = const Distance().as(
        LengthUnit.Kilometer,
        start,
        end,
      );
      _totalDistances[_selectedPeriod] = routeDistance;
      _instructionText = ''; // Clear instruction text
      if (!isInit) {
        // Update goal if route is set/changed
        switch (_selectedPeriod) {
          case 'weekly':
            _goalWeekly = routeDistance;
            break;
          case 'monthly':
            _goalMonthly = routeDistance;
            break;
          case 'yearly':
            _goalYearly = routeDistance;
            break;
        }
      }
    } else {
      _totalDistances[_selectedPeriod] = 0;
      _instructionText = start == null
          ? 'instructionSetStart'
              .tr(namedArgs: {'period': _periodToJapanese(_selectedPeriod)})
          : 'instructionSetGoal'
              .tr(namedArgs: {'period': _periodToJapanese(_selectedPeriod)});
    }

    final currentSwam = {
      'weekly': _swamDistanceWeekly,
      'monthly': _swamDistanceMonthly,
      'yearly': _swamDistanceYearly,
    }[_selectedPeriod]!;
    final currentTotal = _totalDistances[_selectedPeriod]!;
    if (start == null) {
      _currentPosition = null;
    } else if (end == null) {
      _currentPosition = start;
    } else {
      if (currentSwam >= currentTotal) {
        _currentPosition = end;
      } else {
        final progress = currentTotal > 0 ? currentSwam / currentTotal : 0;
        _currentPosition = LatLng(
          start.latitude + (end.latitude - start.latitude) * progress,
          start.longitude + (end.longitude - start.longitude) * progress,
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
    _saveAllData();
  }

  double _getDistanceForPeriod(DateTime start, DateTime end) {
    double total = 0.0;
    _events.forEach((date, distances) {
      if (!date.isBefore(start) && !date.isAfter(end)) {
        total += distances.fold(0.0, (prev, dist) => prev + dist);
      }
    });
    return total;
  }

  String _periodToJapanese(String period) {
    switch (period) {
      case 'weekly':
        return 'thisWeek'.tr();
      case 'monthly':
        return 'thisMonth'.tr();
      case 'yearly':
        return 'thisYear'.tr();
      default:
        return '';
    }
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      MapScreen(
        selectedPeriod: _selectedPeriod,
        onPeriodChanged: _handlePeriodChange,
        startPoint: _startPoints[_selectedPeriod],
        endPoint: _endPoints[_selectedPeriod],
        currentPosition: _currentPosition,
        totalDistanceKm: _totalDistances[_selectedPeriod]!,
        swamDistanceKm: {
          'weekly': _swamDistanceWeekly,
          'monthly': _swamDistanceMonthly,
          'yearly': _swamDistanceYearly,
        }[_selectedPeriod]!,
        instructionText: _instructionText,
        onMapLongPress: _handleMapLongPress,
        onReset: _resetRoute,
      ),
      CalendarScreen(
        events: _events,
        trainingMenus: _trainingMenus,
        onUpdate: _handleCalendarUpdate,
        goalWeekly: _goalWeekly,
        goalMonthly: _goalMonthly,
        goalYearly: _goalYearly,
        swamWeekly: _swamDistanceWeekly,
        swamMonthly: _swamDistanceMonthly,
        swamYearly: _swamDistanceYearly,
        onSetGoal: _handleGoalUpdate,
        totalSwamDistance: _totalSwamDistance,
        goalTimes: _goalTimes,
        onGoalTimeUpdate: _handleGoalTimeUpdate,
        userWeight: _userWeight,
        onUserWeightUpdate: _handleUserWeightUpdate,
      ),
      MenuScreen(
          menus: _trainingMenus,
          onUpdate: _handleMenuUpdate,
          userWeight: _userWeight,
          onMenuAdded: _showAdDialog),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Center(child: widgetOptions.elementAt(_selectedIndex)),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _bottomNavAnimationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                      _bottomNavAnimationController.value)!,
                  Color.lerp(
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.primary,
                      _bottomNavAnimationController.value)!,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: const Icon(Icons.map),
                  label: 'map'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.calendar_today),
                  label: 'calendar'.tr(),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.list_alt),
                  label: 'menu'.tr(),
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedItemColor: Theme.of(context).colorScheme.onPrimary,
              unselectedItemColor:
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
            ),
          );
        },
      ),
    );
  }
}
