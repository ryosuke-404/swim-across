import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swimming_trip/goal_time.dart';
import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';

class GoalTimeScreen extends StatefulWidget {
  final List<GoalTime> goalTimes;
  final Function(List<GoalTime>) onUpdate;

  const GoalTimeScreen({
    super.key,
    required this.goalTimes,
    required this.onUpdate,
  });

  @override
  State<GoalTimeScreen> createState() => _GoalTimeScreenState();
}

class _GoalTimeScreenState extends State<GoalTimeScreen> {
  // 編集・削除のためにリストのコピーを作成
  late List<GoalTime> _goalTimes;

  @override
  void initState() {
    super.initState();
    _goalTimes = List.from(widget.goalTimes);
  }

  void _showAddGoalTimeDialog() {
    final formKey = GlobalKey<FormState>();
    String? selectedStrokeKey;
    final distanceController = TextEditingController();
    final minutesController = TextEditingController();
    final secondsController = TextEditingController();
    final millisController = TextEditingController();

    // Use keys for strokes for localization
    final List<String> swimStrokeKeys = [
      'freestyle',
      'breaststroke',
      'backstroke',
      'butterfly'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('addGoalTime'.tr()),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'stroke'.tr()),
                    items: swimStrokeKeys
                        .map((key) =>
                            DropdownMenuItem(value: key, child: Text(key.tr())))
                        .toList(),
                    onChanged: (value) => selectedStrokeKey = value,
                    validator: (v) => v == null ? 'selectStroke'.tr() : null,
                  ),
                  TextFormField(
                    controller: distanceController,
                    decoration:
                        InputDecoration(labelText: 'distanceMeters'.tr()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) =>
                        v == null || v.isEmpty ? 'enterDistance'.tr() : null,
                  ),
                  const SizedBox(height: 16),
                  Text('goalTime'.tr()),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: minutesController,
                          decoration:
                              InputDecoration(labelText: 'minutes'.tr()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const Text(' : '),
                      Expanded(
                        child: TextFormField(
                          controller: secondsController,
                          decoration:
                              InputDecoration(labelText: 'seconds'.tr()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const Text(' . '),
                      Expanded(
                        child: TextFormField(
                          controller: millisController,
                          decoration:
                              InputDecoration(labelText: 'milliseconds'.tr()),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final minutes = int.tryParse(minutesController.text) ?? 0;
                  final seconds = int.tryParse(secondsController.text) ?? 0;
                  final milliseconds = int.tryParse(millisController.text) ?? 0;

                  final newGoal = GoalTime(
                    id: const Uuid().v4(),
                    stroke: selectedStrokeKey!, // Save the key
                    distance: int.parse(distanceController.text),
                    time: Duration(
                      minutes: minutes,
                      seconds: seconds,
                      milliseconds: milliseconds,
                    ),
                  );

                  setState(() {
                    _goalTimes.add(newGoal);
                  });
                  widget.onUpdate(_goalTimes); // main.dart に変更を通知
                  Navigator.pop(context);
                }
              },
              child: Text('save'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('setGoalTime'.tr())),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalTimeDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: _goalTimes.length,
        itemBuilder: (context, index) {
          final goal = _goalTimes[index];
          return ListTile(
            title: Text('${goal.stroke.tr()} ${goal.distance}m'),
            subtitle:
                Text('goalLabel'.tr(namedArgs: {'time': goal.formattedTime})),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _goalTimes.removeAt(index);
                });
                widget.onUpdate(_goalTimes);
              },
            ),
          );
        },
      ),
    );
  }
}
