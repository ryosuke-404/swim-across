import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StatisticsScreen extends StatelessWidget {
  final double totalSwamDistance;

  const StatisticsScreen({super.key, required this.totalSwamDistance});

  @override
  Widget build(BuildContext context) {
    // Earth's circumference in km
    const double earthCircumferenceKm = 40075.0;
    final double progressAroundWorld = totalSwamDistance > 0
        ? (totalSwamDistance / earthCircumferenceKm)
        : 0.0;
    final int completedLaps = progressAroundWorld.floor();
    final double currentLapProgress = progressAroundWorld - completedLaps;

    return Scaffold(
      appBar: AppBar(
        title: Text('statisticsTitle'.tr()),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'totalDistanceSwamAllTime'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${totalSwamDistance.toStringAsFixed(2)} km',
                      style:
                          Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(duration: 500.ms).scale(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'comparisonAroundTheWorld'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: currentLapProgress,
                            strokeWidth: 12,
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.public,
                                  size: 60,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withOpacity(0.8),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(currentLapProgress * 100).toStringAsFixed(1)}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),
                    if (completedLaps > 0)
                      Text(
                        'worldCircumnavigations'
                            .tr(namedArgs: {'count': completedLaps.toString()}),
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        'keepSwimming'.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
