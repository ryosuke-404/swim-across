import 'package:flutter/material.dart';
import 'package:swimming_trip/training_menu.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

class MenuItemDetailScreen extends StatefulWidget {
  final MenuItem? item;

  const MenuItemDetailScreen({super.key, this.item});

  @override
  State<MenuItemDetailScreen> createState() => _MenuItemDetailScreenState();
}

class _MenuItemDetailScreenState extends State<MenuItemDetailScreen> {
  late MenuItem _currentItem;
  late TextEditingController _distanceController;
  late TextEditingController _repsController;
  late TextEditingController _intervalController;
  late TextEditingController _noteController;
  late StrokeType _selectedStroke;
  late List<EquipmentType> _selectedEquipment;

  @override
  void initState() {
    super.initState();
    _currentItem = widget.item ??
        MenuItem(
          stroke: StrokeType.fr,
          distance: 0,
          reps: 0,
          interval: '',
          equipment: [],
          note: '',
        );

    _distanceController = TextEditingController(
      text: _currentItem.distance == 0 ? '' : _currentItem.distance.toString(),
    );
    _repsController = TextEditingController(
        text: _currentItem.reps == 0 ? '' : _currentItem.reps.toString());
    _intervalController = TextEditingController(text: _currentItem.interval);
    _noteController = TextEditingController(text: _currentItem.note);
    _selectedStroke = _currentItem.stroke;
    _selectedEquipment = List.from(_currentItem.equipment);
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _repsController.dispose();
    _intervalController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveItem() {
    final int distance = int.tryParse(_distanceController.text) ?? 0;
    final int reps = int.tryParse(_repsController.text) ?? 0;

    final newItem = MenuItem(
      id: _currentItem.id,
      stroke: _selectedStroke,
      distance: distance,
      reps: reps,
      interval: _intervalController.text,
      equipment: _selectedEquipment,
      note: _noteController.text,
    );
    Navigator.pop(context, newItem);
  }

  void _deleteItem() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('deleteItem'.tr()),
          content: Text('confirmDeleteItem'.tr()),
          actions: [
            TextButton(
              child: Text('cancel'.tr()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('delete'.tr(),
                  style: const TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Close AlertDialog
                Navigator.pop(
                  context,
                  null,
                ); // Close MenuItemDetailScreen and return null to signal deletion
              },
            ),
          ],
        );
      },
    );
  }

  String _strokeTypeToString(StrokeType type) {
    return type.toString().split('.').last;
  }

  String _equipmentTypeToString(EquipmentType type) {
    return type.toString().split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'addItem'.tr() : 'editItem'.tr()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (widget.item != null) // Only show delete button for existing items
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteItem,
            ),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveItem),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stroke
            DropdownButtonFormField<StrokeType>(
              value: _selectedStroke,
              decoration: InputDecoration(
                labelText: 'stroke'.tr(),
                border: const OutlineInputBorder(),
              ),
              items: StrokeType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Flexible(child: Text(_strokeTypeToString(type).tr())),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedStroke = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Distance
            TextField(
              controller: _distanceController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'distanceMeters'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Reps
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'reps'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Interval
            TextField(
              controller: _intervalController,
              decoration: InputDecoration(
                labelText: 'intervalExample'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Equipment
            Text(
              'equipment'.tr(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: EquipmentType.values.map((type) {
                final isSelected = _selectedEquipment.contains(type);
                return ChoiceChip(
                  label:
                      Flexible(child: Text(_equipmentTypeToString(type).tr())),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedEquipment.add(type);
                      } else {
                        _selectedEquipment.remove(type);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'note'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
