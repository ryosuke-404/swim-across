import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  final String selectedPeriod;
  final Function(String) onPeriodChanged;
  final LatLng? startPoint, endPoint, currentPosition;
  final double totalDistanceKm, swamDistanceKm;
  final String instructionText;
  final void Function(LatLng) onMapLongPress;
  final VoidCallback onReset;

  const MapScreen({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.startPoint,
    required this.endPoint,
    required this.currentPosition,
    required this.totalDistanceKm,
    required this.swamDistanceKm,
    required this.instructionText,
    required this.onMapLongPress,
    required this.onReset,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  late AnimationController _gradientAnimationController;
  late Animation<AlignmentGeometry> _gradientAnimation;
  late AnimationController _rippleAnimationController;

  final MapController _mapController = MapController();
  double _initialZoom = 3.0;

  @override
  void initState() {
    super.initState();
    _loadInitialZoom();

    _gradientAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _gradientAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).animate(
      CurvedAnimation(
        parent: _gradientAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _rippleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  Future<void> _loadInitialZoom() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch =
        prefs.getBool('isFirstLaunchAfterOnboarding') ?? false;
    if (isFirstLaunch) {
      setState(() {
        _initialZoom = 1.0;
      });
      await prefs.setBool('isFirstLaunchAfterOnboarding', false);
    }
  }

  @override
  void dispose() {
    _gradientAnimationController.dispose();
    _rippleAnimationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if start and end points are valid and the period has changed
    if (widget.startPoint != null &&
        widget.endPoint != null &&
        widget.selectedPeriod != oldWidget.selectedPeriod) {
      // Use a post-frame callback to ensure the map is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final bounds = LatLngBounds(widget.startPoint!, widget.endPoint!);
        _mapController.fitBounds(
          bounds,
          options: const FitBoundsOptions(
            padding: EdgeInsets.all(50.0), // Add some padding around the route
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    if (widget.startPoint != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: widget.startPoint!,
          child: SvgPicture.string('''
            <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" fill="#4ade80"/>
                <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" stroke="white" stroke-width="1.5"/>
                <circle cx="12" cy="9" r="2.5" fill="white"/>
            </svg>
          '''),
        ),
      );
    }
    if (widget.endPoint != null) {
      markers.add(
        Marker(
          width: 40,
          height: 40,
          point: widget.endPoint!,
          child: SvgPicture.string('''
            <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <defs>
                    <pattern id="checker" patternUnits="userSpaceOnUse" width="6" height="6">
                        <rect width="3" height="3" fill="#dc2626"/>
                        <rect x="3" width="3" height="3" fill="white"/>
                        <rect y="3" width="3" height="3" fill="white"/>
                        <rect x="3" y="3" width="3" height="3" fill="#dc2626"/>
                    </pattern>
                </defs>
                <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" fill="url(#checker)"/>
                <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7z" stroke="white" stroke-width="1.5"/>
            </svg>
          '''),
        ),
      );
    }
    if (widget.currentPosition != null) {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: widget.currentPosition!,
          child: AnimatedBuilder(
            animation: _rippleAnimationController,
            builder: (context, child) {
              final value = _rippleAnimationController.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 24 * (1 + value * 2),
                    height: 24 * (1 + value * 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue.withOpacity(1 - value),
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    final polylines = <Polyline>[];
    if (widget.startPoint != null && widget.endPoint != null) {
      polylines.add(
        Polyline(
          points: [widget.startPoint!, widget.endPoint!],
          color: Theme.of(context).colorScheme.primary,
          strokeWidth: 5,
        ),
      );
    }

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
                      _gradientAnimationController.value,
                    )!,
                    Color.lerp(
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).colorScheme.primary,
                      _gradientAnimationController.value,
                    )!,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: AppBar(
                title: Text(
                  'swimRoute'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: widget.onReset,
                    tooltip: 'resetRoute'.tr(),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  widget.currentPosition ?? const LatLng(35.681236, 139.767125),
              initialZoom: _initialZoom,
              minZoom: 1.0,
              onLongPress: (tapPosition, point) {
                widget.onMapLongPress(point);
              },
              maxBounds: LatLngBounds(
                const LatLng(-90, -270),
                const LatLng(90, 270),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.swimming_trip',
              ),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _buildGradientChip(
                  context: context,
                  label: 'thisWeek'.tr(),
                  isSelected: widget.selectedPeriod == 'weekly',
                  onTap: () => widget.onPeriodChanged('weekly'),
                ),
                const SizedBox(height: 12),
                _buildGradientChip(
                  context: context,
                  label: 'thisMonth'.tr(),
                  isSelected: widget.selectedPeriod == 'monthly',
                  onTap: () => widget.onPeriodChanged('monthly'),
                ),
                const SizedBox(height: 12),
                _buildGradientChip(
                  context: context,
                  label: 'thisYear'.tr(),
                  isSelected: widget.selectedPeriod == 'yearly',
                  onTap: () => widget.onPeriodChanged('yearly'),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: widget.totalDistanceKm > 0
                    ? _RouteProgress(
                        totalDistance: widget.totalDistanceKm,
                        swamDistance: widget.swamDistanceKm,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.instructionText,
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'totalSwam'.tr(namedArgs: {
                              'distance':
                                  widget.swamDistanceKm.toStringAsFixed(2)
                            }),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ]
                : [Colors.grey.shade600, Colors.grey.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.onPrimary.withOpacity(0.8),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}

class _RouteProgress extends StatelessWidget {
  final double totalDistance;
  final double swamDistance;

  const _RouteProgress({
    required this.totalDistance,
    required this.swamDistance,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (totalDistance > 0 && swamDistance > 0)
        ? (swamDistance / totalDistance)
        : 0.0;
    final percentText = '${(percent * 100).toStringAsFixed(0)}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('progress'.tr(),
                style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${swamDistance.toStringAsFixed(2)} / ${totalDistance.toStringAsFixed(2)} km',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
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
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
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
