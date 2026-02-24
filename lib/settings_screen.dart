import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_trip/goal_time.dart';
import 'package:swimming_trip/goal_time_screen.dart';
import 'package:swimming_trip/privacy_policy_screen.dart';
import 'package:swimming_trip/statistics_screen.dart';
import 'package:swimming_trip/terms_screen.dart';

// コールバックの型定義
typedef GoalCallback = void Function(
    double weekly, double monthly, double yearly);
typedef GoalTimeCallback = void Function(List<GoalTime> goalTimes);

class SettingsScreen extends StatelessWidget {
  final double goalWeekly, goalMonthly, goalYearly;
  final GoalCallback onSetGoal;
  final double totalSwamDistance;
  final List<GoalTime> goalTimes;
  final GoalTimeCallback onGoalTimeUpdate;
  final double userWeight;
  final void Function(double) onUserWeightUpdate;

  const SettingsScreen({
    super.key,
    required this.goalWeekly,
    required this.goalMonthly,
    required this.goalYearly,
    required this.onSetGoal,
    required this.totalSwamDistance,
    required this.goalTimes,
    required this.onGoalTimeUpdate,
    required this.userWeight,
    required this.onUserWeightUpdate,
  });

  void _showWeightDialog(BuildContext context) {
    final weightController = TextEditingController(
      text: userWeight > 0 ? userWeight.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('setUserWeight'.tr()),
          content: TextField(
            controller: weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: 'userWeightKg'.tr()),
          ),
          actions: [
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('save'.tr()),
              onPressed: () {
                final weight = double.tryParse(weightController.text) ?? 0.0;
                onUserWeightUpdate(weight);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showGoalDialog(BuildContext context) {
    final weeklyController = TextEditingController(
      text: goalWeekly > 0 ? goalWeekly.toString() : '',
    );
    final monthlyController = TextEditingController(
      text: goalMonthly > 0 ? goalMonthly.toString() : '',
    );
    final yearlyController = TextEditingController(
      text: goalYearly > 0 ? goalYearly.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('setGoalDistance'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weeklyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'weeklyGoal'.tr()),
                ),
                TextField(
                  controller: monthlyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'monthlyGoal'.tr()),
                ),
                TextField(
                  controller: yearlyController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: 'yearlyGoal'.tr()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('save'.tr()),
              onPressed: () {
                final weekly = double.tryParse(weeklyController.text) ?? 0.0;
                final monthly = double.tryParse(monthlyController.text) ?? 0.0;
                final yearly = double.tryParse(yearlyController.text) ?? 0.0;
                onSetGoal(weekly, monthly, yearly);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languages = [
      {'name': 'japanese'.tr(), 'locale': const Locale('ja')},
      {'name': 'english'.tr(), 'locale': const Locale('en')},
      {'name': 'chinese'.tr(), 'locale': const Locale('zh')},
      {'name': 'hindi'.tr(), 'locale': const Locale('hi')},
      {'name': 'spanish'.tr(), 'locale': const Locale('es')},
      {'name': 'french'.tr(), 'locale': const Locale('fr')},
      {'name': 'arabic'.tr(), 'locale': const Locale('ar')},
      {'name': 'bengali'.tr(), 'locale': const Locale('bn')},
      {'name': 'portuguese'.tr(), 'locale': const Locale('pt')},
      {'name': 'russian'.tr(), 'locale': const Locale('ru')},
      {'name': 'urdu'.tr(), 'locale': const Locale('ur')},
      {'name': 'indonesian'.tr(), 'locale': const Locale('id')},
      {'name': 'german'.tr(), 'locale': const Locale('de')},
      {'name': 'italian'.tr(), 'locale': const Locale('it')},
      {'name': 'korean'.tr(), 'locale': const Locale('ko')},
      {'name': 'dutch'.tr(), 'locale': const Locale('nl')},
      {'name': 'swedish'.tr(), 'locale': const Locale('sv')},
      {'name': 'norwegian'.tr(), 'locale': const Locale('no')},
      {'name': 'danish'.tr(), 'locale': const Locale('da')},
      {'name': 'thai'.tr(), 'locale': const Locale('th')},
      {'name': 'turkish'.tr(), 'locale': const Locale('tr')},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('selectLanguage'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(languages[index]['name'] as String),
                  onTap: () {
                    context.setLocale(languages[index]['locale'] as Locale);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.flag),
            title: Text('setGoalDistance'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showGoalDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: Text('setGoalTime'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GoalTimeScreen(
                    goalTimes: goalTimes,
                    onUpdate: onGoalTimeUpdate,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.monitor_weight),
            title: Text('setUserWeight'.tr()),
            subtitle: Text('userWeightSubtitle'
                .tr(namedArgs: {'weight': userWeight.toString()})),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showWeightDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('language'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLanguageDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.show_chart),
            title: Text('statistics'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      StatisticsScreen(totalSwamDistance: totalSwamDistance),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text('termsOfService'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: Text('privacyPolicy'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
