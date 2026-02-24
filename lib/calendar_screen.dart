import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:swimming_trip/goal_time.dart';
import 'package:swimming_trip/settings_screen.dart';
import 'package:swimming_trip/training_menu.dart';
import 'package:table_calendar/table_calendar.dart';

// Callback type definitions
typedef EventCallback = void Function(Map<DateTime, List<double>> events);
typedef GoalCallback = void Function(
    double weekly, double monthly, double yearly);
typedef GoalTimeCallback = void Function(List<GoalTime> goalTimes);

class CalendarScreen extends StatefulWidget {
  final Map<DateTime, List<double>> events;
  final List<TrainingMenu> trainingMenus;
  final EventCallback onUpdate;
  final double goalWeekly, goalMonthly, goalYearly;
  final double swamWeekly, swamMonthly, swamYearly;
  final GoalCallback onSetGoal;
  final double totalSwamDistance;
  final List<GoalTime> goalTimes;
  final GoalTimeCallback onGoalTimeUpdate;
  final double userWeight;
  final void Function(double) onUserWeightUpdate;

  const CalendarScreen({
    super.key,
    required this.events,
    required this.trainingMenus,
    required this.onUpdate,
    required this.goalWeekly,
    required this.goalMonthly,
    required this.goalYearly,
    required this.swamWeekly,
    required this.swamMonthly,
    required this.swamYearly,
    required this.onSetGoal,
    required this.totalSwamDistance,
    required this.goalTimes,
    required this.onGoalTimeUpdate,
    required this.userWeight,
    required this.onUserWeightUpdate,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late AnimationController _animationController;
  late Animation<AlignmentGeometry> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _gradientAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<double> _getEventsForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return widget.events[dayUtc] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _showAddRecordDialog() {
    final day = _selectedDay ?? _focusedDay;
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    TrainingMenu? selectedMenu;
    final distanceController = TextEditingController();
    bool isMenuMode = widget.trainingMenus.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'addRecordForDate'
                    .tr(namedArgs: {'date': '${day.month}/${day.day}'}),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.trainingMenus.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: Text('menu'.tr()),
                            selected: isMenuMode,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => isMenuMode = true);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('distanceInput'.tr()),
                            selected: !isMenuMode,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() => isMenuMode = false);
                              }
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    if (isMenuMode)
                      DropdownButtonFormField<TrainingMenu>(
                        hint: Text('selectMenu'.tr()),
                        items: widget.trainingMenus.map((menu) {
                          return DropdownMenuItem(
                            value: menu,
                            child: Text(
                                '${menu.name} (${menu.totalDistance.toStringAsFixed(1)} km)'),
                          );
                        }).toList(),
                        onChanged: (value) => selectedMenu = value,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      )
                    else
                      TextField(
                        controller: distanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'distanceKm'.tr(),
                          border: const OutlineInputBorder(),
                        ),
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
                    double? distanceToAdd;
                    if (isMenuMode) {
                      distanceToAdd = selectedMenu?.totalDistance;
                    } else {
                      distanceToAdd = double.tryParse(distanceController.text);
                    }

                    if (distanceToAdd != null && distanceToAdd > 0) {
                      final newEvents =
                          Map<DateTime, List<double>>.from(widget.events);
                      newEvents.update(
                        dayUtc,
                        (list) => list..add(distanceToAdd!),
                        ifAbsent: () => [distanceToAdd!],
                      );
                      widget.onUpdate(newEvents);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(int indexToDelete) {
    final dayUtc = DateTime.utc(
      (_selectedDay ?? _focusedDay).year,
      (_selectedDay ?? _focusedDay).month,
      (_selectedDay ?? _focusedDay).day,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('confirmDeleteRecordTitle'.tr()),
          content: Text('confirmDeleteRecordContent'.tr()),
          actions: <Widget>[
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('delete'.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () {
                final newEvents =
                    Map<DateTime, List<double>>.from(widget.events);
                newEvents[dayUtc]?.removeAt(indexToDelete);
                if (newEvents[dayUtc]?.isEmpty ?? false) {
                  newEvents.remove(dayUtc);
                }
                widget.onUpdate(newEvents);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedBuilder(
          animation: _gradientAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                        _animationController.value)!,
                    Color.lerp(
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.primary,
                        _animationController.value)!,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: AppBar(
                title: Text(
                  'calendarLog'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(Icons.settings,
                        color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(
                            goalWeekly: widget.goalWeekly,
                            goalMonthly: widget.goalMonthly,
                            goalYearly: widget.goalYearly,
                            onSetGoal: widget.onSetGoal,
                            totalSwamDistance: widget.totalSwamDistance,
                            goalTimes: widget.goalTimes,
                            onGoalTimeUpdate: widget.onGoalTimeUpdate,
                            userWeight: widget.userWeight, // Pass weight
                            onUserWeightUpdate:
                                widget.onUserWeightUpdate, // Pass callback
                          ),
                        ),
                      );
                    },
                    tooltip: 'settings'.tr(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddRecordDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          tooltip: 'addRecord'.tr(),
          child:
              Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
        ),
      ),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  _GoalProgress(
                      title: 'weeklyGoal'.tr(),
                      swam: widget.swamWeekly,
                      goal: widget.goalWeekly),
                  const SizedBox(height: 8),
                  _GoalProgress(
                      title: 'monthlyGoal'.tr(),
                      swam: widget.swamMonthly,
                      goal: widget.goalMonthly),
                  const SizedBox(height: 8),
                  _GoalProgress(
                      title: 'yearlyGoal'.tr(),
                      swam: widget.swamYearly,
                      goal: widget.goalYearly),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TableCalendar<double>(
                    locale: context.locale.toString(),
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    availableCalendarFormats: {
                      CalendarFormat.month: 'calendarFormatMonth'.tr(),
                      CalendarFormat.twoWeeks: 'calendarFormatTwoWeeks'.tr(),
                    },
                    eventLoader: _getEventsForDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() => _calendarFormat = format);
                      }
                    },
                    onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                    calendarStyle: CalendarStyle(
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: true,
                      titleCentered: true,
                      titleTextStyle: Theme.of(context).textTheme.titleLarge!,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: selectedDayEvents.length,
                    itemBuilder: (context, index) {
                      final distance = selectedDayEvents[index];
                      return ListTile(
                        title: Text(
                          'distanceSwam'.tr(namedArgs: {
                            'distance': distance.toStringAsFixed(2)
                          }),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onLongPress: () => _showDeleteConfirmationDialog(index),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  final String title;
  final double swam;
  final double goal;

  const _GoalProgress(
      {required this.title, required this.swam, required this.goal});

  @override
  Widget build(BuildContext context) {
    final percent = (goal > 0 && swam > 0) ? (swam / goal) : 0.0;
    final percentText = '${(percent * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${swam.toStringAsFixed(1)} / ${goal.toStringAsFixed(1)} km',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: percent > 1.0 ? 1.0 : percent,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percentText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}
