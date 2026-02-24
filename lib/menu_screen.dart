import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:swimming_trip/menu_detail_screen.dart';
import 'package:swimming_trip/training_menu.dart';

// メニューリストが更新されたときに呼び出されるコールバックの型定義
typedef MenuUpdateCallback = void Function(List<TrainingMenu> menus);

class MenuScreen extends StatefulWidget {
  final List<TrainingMenu> menus;
  final MenuUpdateCallback onUpdate;
  final double userWeight;
  final VoidCallback? onMenuAdded;

  const MenuScreen(
      {super.key,
      required this.menus,
      required this.onUpdate,
      required this.userWeight,
      this.onMenuAdded});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late List<TrainingMenu> _menus;
  bool _isEditMode = false;

  late AnimationController _animationController;
  late Animation<AlignmentGeometry> _gradientAnimation;
  late PageController _pageController;
  int _currentPage = 0;
  late List<ScreenshotController> _screenshotControllers;

  @override
  void initState() {
    super.initState();
    _menus = List.from(widget.menus);
    _screenshotControllers =
        List.generate(_menus.length, (_) => ScreenshotController());
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });

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
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MenuScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.menus != oldWidget.menus) {
      setState(() {
        _menus = List.from(widget.menus);
        _screenshotControllers =
            List.generate(_menus.length, (_) => ScreenshotController());
      });
    }
  }

  void _navigateAndEditMenu({TrainingMenu? menu}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) =>
              MenuDetailScreen(menu: menu, userWeight: widget.userWeight)),
    );

    if (result != null && result is TrainingMenu) {
      setState(() {
        final index = _menus.indexWhere((m) => m.id == result.id);
        if (index != -1) {
          _menus[index] = result; // 既存のメニューを更新
        } else {
          _menus.add(result); // 新しいメニューを追加
          widget.onMenuAdded?.call();
        }
        widget.onUpdate(_menus);
      });
    }
  }

  void _deleteMenu(BuildContext context, TrainingMenu menuToDelete) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('deleteMenuTitle'.tr(),
              style: Theme.of(context).textTheme.titleLarge),
          content: Text(
            'confirmDeleteMenuContent'
                .tr(namedArgs: {'menuName': menuToDelete.name}),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                'delete'.tr(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
              onPressed: () {
                setState(() {
                  _menus.removeWhere((menu) => menu.id == menuToDelete.id);
                  widget.onUpdate(_menus);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('export'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: Text('exportAsPdf'.tr()),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportAsPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: Text('exportAsImage'.tr()),
                onTap: () {
                  Navigator.of(context).pop();
                  _exportAsImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportAsPdf() async {
    final image = await _screenshotControllers[_currentPage].capture();
    if (image != null) {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pw.MemoryImage(image)),
            );
          },
        ),
      );
      await Printing.sharePdf(
          bytes: await pdf.save(), filename: '${_menus[_currentPage].name}.pdf');
    }
  }

  Future<void> _exportAsImage() async {
    final image = await _screenshotControllers[_currentPage].capture();
    if (image != null) {
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/${_menus[_currentPage].name}.png').create();
      await imagePath.writeAsBytes(image);
      await Share.shareXFiles([XFile(imagePath.path)]);
    }
  }

  // Helper function to build a single dot indicator
  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Colors.grey.shade400,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  'trainingMenuTitle'.tr(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: _showExportDialog,
                  ),
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
                ],
              ),
            );
          },
        ),
      ),
      body: _menus.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'addMenuPrompt'.tr(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : _isEditMode
              ? ReorderableListView.builder(
                  itemCount: _menus.length,
                  itemBuilder: (context, index) {
                    final menu = _menus[index];
                    return Card(
                      key: ValueKey(menu.id),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          menu.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        subtitle: Text(
                          '${menu.totalDistanceInMeters.toStringAsFixed(0)} m / ${menu.totalCalories(widget.userWeight).toStringAsFixed(0)} kcal',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                        ),
                        leading: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () => _deleteMenu(context, menu),
                        ),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                        onTap: () => _navigateAndEditMenu(menu: menu),
                      ),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) {
                        newIndex -= 1;
                      }
                      final TrainingMenu item = _menus.removeAt(oldIndex);
                      _menus.insert(newIndex, item);
                      widget.onUpdate(_menus);
                    });
                  },
                )
              : Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: _menus.length,
                      itemBuilder: (context, index) {
                        final menu = _menus[index];
                        return Screenshot(
                          controller: _screenshotControllers[index],
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                                20, 20, 20, 50), // Add padding for indicators
                            child: Card(
                              key: ValueKey(menu.id),
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              clipBehavior: Clip.antiAlias,
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.fromLTRB(16, 16, 8, 8),
                                      title: Text(
                                        menu.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      subtitle: Text(
                                        '${menu.totalDistanceInMeters.toStringAsFixed(0)} m / ${menu.totalCalories(widget.userWeight).toStringAsFixed(0)} kcal',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .secondary,
                                            ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.edit_note,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        onPressed: () =>
                                            _navigateAndEditMenu(menu: menu),
                                      ),
                                      onTap: () =>
                                          _navigateAndEditMenu(menu: menu),
                                    ),
                                    const Divider(
                                        height: 1, indent: 16, endIndent: 16),
                                    ...menu.sections.map((section) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0, vertical: 8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              section.type
                                                  .toString()
                                                  .split('.')
                                                  .last
                                                  .tr(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            ...section.items.map((item) {
                                              final equipmentText = item.equipment
                                                  .map((e) => e
                                                      .toString()
                                                      .split('.')
                                                      .last
                                                      .tr())
                                                  .join(', ');
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0, top: 4.0),
                                                child: Text(
                                                  'itemDescription'.tr(
                                                    namedArgs: {
                                                      'distance': item.distance
                                                          .toString(),
                                                      'reps':
                                                          item.reps.toString(),
                                                      'interval': item.interval,
                                                      'equipment':
                                                          equipmentText.isNotEmpty
                                                              ? '($equipmentText)'
                                                              : '',
                                                      'note': item.note,
                                                    },
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_menus.length > 1)
                      Positioned(
                        bottom: 20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _menus.length,
                            (index) => _indicator(index == _currentPage),
                          ),
                        ),
                      ),
                  ],
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
          onPressed: () => _navigateAndEditMenu(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
