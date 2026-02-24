import 'package:flutter/material.dart';
import 'package:swimming_trip/training_menu.dart';
import 'package:swimming_trip/menu_item_detail_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

class MenuDetailScreen extends StatefulWidget {
  final TrainingMenu? menu;
  final double userWeight;

  const MenuDetailScreen({super.key, this.menu, required this.userWeight});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen>
    with TickerProviderStateMixin {
  late TrainingMenu _currentMenu;
  late TextEditingController _nameController;
  bool _isEditMode = false;
  int _currentStep = 0;

  late AnimationController _animationController;
  late Animation<AlignmentGeometry> _gradientAnimation;

  @override
  void initState() {
    super.initState();
    _currentMenu = widget.menu ?? TrainingMenu(name: 'newMenu'.tr());
    _nameController = TextEditingController(text: _currentMenu.name);
    _nameController.addListener(() {
      setState(() {
        _currentMenu.name = _nameController.text; // Update menu name
      });
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 10,
      ), // Duration for one cycle of gradient animation
    )..repeat(reverse: true); // Repeat with reverse for smooth back and forth

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
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addSection() async {
    final MenuSectionType? selectedType = await showDialog<MenuSectionType>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'selectSectionType'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: MenuSectionType.values.map((type) {
            return ListTile(
              title: Text(type.toString().split('.').last.toUpperCase()),
              onTap: () => Navigator.of(context).pop(type),
            );
          }).toList(),
        ),
      ),
    );

    if (selectedType != null) {
      setState(() {
        _currentMenu.sections.add(MenuSection(type: selectedType));
      });
    }
  }

  void _onReorderSections(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final MenuSection section = _currentMenu.sections.removeAt(oldIndex);
      _currentMenu.sections.insert(newIndex, section);
    });
  }

  void _deleteSection(MenuSection sectionToDelete) {
    setState(() {
      _currentMenu.sections.removeWhere(
        (section) => section.id == sectionToDelete.id,
      );
    });
  }

  void _deleteMenuItem(MenuSection section, MenuItem itemToDelete) {
    setState(() {
      final sectionIndex = _currentMenu.sections.indexWhere(
        (s) => s.id == section.id,
      );
      if (sectionIndex != -1) {
        _currentMenu.sections[sectionIndex].items.removeWhere(
          (item) => item.id == itemToDelete.id,
        );
      }
    });
  }

  void _navigateAndEditMenuItem(MenuSection section, {MenuItem? item}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MenuItemDetailScreen(item: item)),
    );

    if (result != null && result is MenuItem) {
      setState(() {
        final sectionIndex = _currentMenu.sections.indexWhere(
          (s) => s.id == section.id,
        );
        if (sectionIndex != -1) {
          final itemIndex = _currentMenu.sections[sectionIndex].items
              .indexWhere((i) => i.id == result.id);
          if (itemIndex != -1) {
            // Update existing item
            _currentMenu.sections[sectionIndex].items[itemIndex] = result;
          } else {
            // Add new item
            _currentMenu.sections[sectionIndex].items.add(result);
          }
        }
      });
    }
  }

  Icon _getStrokeIcon(StrokeType type) {
    switch (type) {
      case StrokeType.fr:
        return const Icon(Icons.pool, size: 18); // Freestyle
      case StrokeType.ba:
        return const Icon(Icons.back_hand, size: 18); // Backstroke
      case StrokeType.br:
        return const Icon(Icons.bubble_chart, size: 18); // Breaststroke
      case StrokeType.fly:
        return const Icon(Icons.flight, size: 18); // Butterfly
      case StrokeType.im:
        return const Icon(Icons.sports_score, size: 18); // IM
    }
  }

  Icon _getEquipmentIcon(EquipmentType type) {
    switch (type) {
      case EquipmentType.fin:
        return const Icon(Icons.fitness_center, size: 18); // Fins
      case EquipmentType.paddle:
        return const Icon(Icons.sports_handball, size: 18); // Paddles
      case EquipmentType.pullBuoy:
        return const Icon(Icons.sports_soccer, size: 18); // Pull Buoy
    }
  }

  Icon _getMenuSectionIcon(MenuSectionType type) {
    switch (type) {
      case MenuSectionType.up:
        return const Icon(Icons.arrow_upward, size: 20);
      case MenuSectionType.kick:
        return const Icon(Icons.waves, size: 20);
      case MenuSectionType.pull:
        return const Icon(Icons.compress, size: 20);
      case MenuSectionType.drill:
        return const Icon(Icons.construction, size: 20);
      case MenuSectionType.main:
        return const Icon(Icons.star, size: 20);
      case MenuSectionType.swim:
        return const Icon(Icons.pool, size: 20);
      case MenuSectionType.down:
        return const Icon(Icons.arrow_downward, size: 20);
    }
  }

  void _showSplashEffect(Offset position) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy,
        child: Icon(Icons.water_drop, color: Colors.blue.shade300, size: 50)
            .animate()
            .fadeOut(duration: 500.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.5, 1.5),
              duration: 500.ms,
            )
            .slideY(begin: 0, end: -0.5, duration: 500.ms)
            .callback(
          callback: (isCompleted) {
            if (isCompleted) {
              overlayEntry.remove();
            }
          },
        ),
      ),
    );
    overlay.insert(overlayEntry);
  }

  Widget _buildStep1() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Step 1: Name your menu', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'menuName'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return _currentMenu.sections.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'addFirstSectionPrompt'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        : ReorderableListView.builder(
            itemCount: _currentMenu.sections.length,
            itemBuilder: (context, index) {
              final section = _currentMenu.sections[index];
              return Card(
                key: ValueKey(section.id),
                margin: const EdgeInsets.all(8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _getMenuSectionIcon(section.type),
                              const SizedBox(width: 8),
                              Text(
                                section.type
                                    .toString()
                                    .split('.')
                                    .last
                                    .toUpperCase(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          if (_isEditMode)
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                              onPressed: () => _deleteSection(section),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<Intensity>(
                        segments: <ButtonSegment<Intensity>>[
                          ButtonSegment<Intensity>(
                              value: Intensity.low,
                              label: Flexible(
                                  child: Text('intensityLow'.tr()))),
                          ButtonSegment<Intensity>(
                              value: Intensity.medium,
                              label: Flexible(
                                  child: Text('intensityMedium'.tr()))),
                          ButtonSegment<Intensity>(
                              value: Intensity.high,
                              label: Flexible(
                                  child: Text('intensityHigh'.tr()))),
                        ],
                        selected: {section.intensity},
                        onSelectionChanged: (Set<Intensity> newSelection) {
                          setState(() {
                            section.intensity = newSelection.first;
                          });
                        },
                      ),
                      if (section.items.isEmpty)
                        Container()
                      else if (_isEditMode)
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: section.items.length,
                          itemBuilder: (context, itemIndex) {
                            final item = section.items[itemIndex];
                            return ListTile(
                              key: ValueKey(item.id),
                              title: Row(
                                children: [
                                  _getStrokeIcon(item.stroke),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'itemDescription'.tr(namedArgs: {
                                        'distance': item.distance.toString(),
                                        'reps': item.reps.toString(),
                                        'interval': item.interval,
                                        'note': item.note
                                      }),
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: item.equipment.isNotEmpty
                                  ? Row(
                                      children: [
                                        ...item.equipment.map(
                                          (e) => Padding(
                                            padding: const EdgeInsets.only(
                                                right: 4.0),
                                            child: _getEquipmentIcon(e),
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                              leading: IconButton(
                                icon: Icon(Icons.delete,
                                    color:
                                        Theme.of(context).colorScheme.error),
                                onPressed: () =>
                                    _deleteMenuItem(section, item),
                              ),
                              trailing: ReorderableDragStartListener(
                                index: itemIndex,
                                child: const Icon(Icons.drag_handle),
                              ),
                              onTap: () =>
                                  _navigateAndEditMenuItem(section, item: item),
                            );
                          },
                          onReorder: (oldItemIndex, newItemIndex) {
                            setState(() {
                              if (newItemIndex > oldItemIndex) {
                                newItemIndex -= 1;
                              }
                              final menuItem =
                                  section.items.removeAt(oldItemIndex);
                              section.items.insert(newItemIndex, menuItem);
                            });
                          },
                        )
                      else
                        Column(
                          children: section.items
                              .map(
                                (item) => ListTile(
                                  title: Row(
                                    children: [
                                      _getStrokeIcon(item.stroke),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'itemDescription'.tr(namedArgs: {
                                            'distance': item.distance.toString(),
                                            'reps': item.reps.toString(),
                                            'interval': item.interval,
                                            'note': item.note
                                          }),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: item.equipment.isNotEmpty
                                      ? Row(
                                          children: [
                                            ...item.equipment.map(
                                              (e) => Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 4.0),
                                                child: _getEquipmentIcon(e),
                                              ),
                                            ),
                                          ],
                                        )
                                      : null,
                                  onTap: () =>
                                      _navigateAndEditMenuItem(section, item: item),
                                ),
                              )
                              .toList(),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: Text('addItem'.tr()),
                          onPressed: () => _navigateAndEditMenuItem(section),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            onReorder: _onReorderSections,
          );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _currentMenu.name = _nameController.text;
        Navigator.pop(context, _currentMenu);
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(
            kToolbarHeight,
          ),
          child: AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: _gradientAnimation.value,
                    end: Alignment(
                      -(_gradientAnimation.value as Alignment).x,
                      -(_gradientAnimation.value as Alignment).y,
                    ),
                  ),
                ),
                child: AppBar(
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () {
                      _currentMenu.name = _nameController.text;
                      Navigator.pop(context, _currentMenu);
                    },
                  ),
                  title: AnimatedBuilder(
                    animation: _gradientAnimation,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.onPrimary,
                              Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.7),
                            ],
                            begin: _gradientAnimation.value,
                            end: Alignment(
                              -(_gradientAnimation.value as Alignment).x,
                              -(_gradientAnimation.value as Alignment).y,
                            ),
                          ).createShader(bounds);
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: _currentStep == 0
                                  ? Text('createMenu'.tr(), style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white))
                                  : TextField(
                                      controller: _nameController,
                                      decoration: InputDecoration(
                                        hintText: 'menuName'.tr(),
                                        border: InputBorder.none,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                          ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_currentMenu.totalDistanceInMeters.toStringAsFixed(0)} m',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                        ),
                                  ),
                                  Text(
                                    '${_currentMenu.totalCalories(widget.userWeight).toStringAsFixed(0)} kcal',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isEditMode ? Icons.check : Icons.edit,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditMode = !_isEditMode;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.save,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        _currentMenu.name = _nameController.text;
                        Navigator.pop(context, _currentMenu);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        body: IndexedStack(
          index: _currentStep,
          children: [
            _buildStep1(),
            _buildStep2(),
          ],
        ),
        floatingActionButton: _currentStep == 1 ? Container(
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
            onPressed: _addSection,
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ) : null,
        bottomNavigationBar: BottomAppBar(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep--;
                    });
                  },
                  child: Text('back'.tr()),
                ),
              const Spacer(),
              if (_currentStep < 1)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentStep++;
                    });
                  },
                  child: Text('next'.tr()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}