import 'package:uuid/uuid.dart';

// Enum for section types
enum MenuSectionType { up, kick, pull, drill, main, swim, down }

// Enum for intensity levels
enum Intensity { low, medium, high }

// Enum for stroke types
enum StrokeType { fr, ba, br, fly, im }

// Enum for equipment types
enum EquipmentType { fin, paddle, pullBuoy }

// Helper function to get METs based on stroke and intensity
double _getMetsForStroke(StrokeType stroke, Intensity intensity) {
  switch (stroke) {
    case StrokeType.fr:
      switch (intensity) {
        case Intensity.low:
          return 7.0;
        case Intensity.medium:
          return 8.3;
        case Intensity.high:
          return 10.0;
      }
    case StrokeType.ba:
      switch (intensity) {
        case Intensity.low:
          return 6.0;
        case Intensity.medium:
          return 9.5;
        case Intensity.high:
          return 11.0;
      }
    case StrokeType.br:
      switch (intensity) {
        case Intensity.low:
          return 5.5;
        case Intensity.medium:
          return 10.3;
        case Intensity.high:
          return 11.5;
      }
    case StrokeType.fly:
      switch (intensity) {
        case Intensity.low:
          return 11.0; // No data for low, using medium as base
        case Intensity.medium:
          return 11.2;
        case Intensity.high:
          return 13.8;
      }
    case StrokeType.im:
      // Average of medium intensity for all strokes as a baseline
      return (8.3 + 9.5 + 10.3 + 11.2) / 4;
  }
}

// Represents each item within a menu section
class MenuItem {
  final String id;
  StrokeType stroke;
  int distance; // in meters
  int reps; // number of repetitions
  String interval; // e.g., "@1'30"
  List<EquipmentType> equipment;
  String note; // e.g., "Easy"

  MenuItem({
    String? id,
    required this.stroke,
    required this.distance,
    required this.reps,
    this.interval = '',
    List<EquipmentType>? equipment,
    this.note = '',
  })  : id = id ?? const Uuid().v4(),
        equipment = equipment ?? [];

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      stroke: StrokeType.values.firstWhere(
        (e) => e.toString() == 'StrokeType.${json['stroke']}',
      ),
      distance: json['distance'] as int,
      reps: json['reps'] as int,
      interval: json['interval'] as String,
      equipment: (json['equipment'] as List<dynamic>)
          .map(
            (e) => EquipmentType.values.firstWhere(
              (et) => et.toString() == 'EquipmentType.$e',
            ),
          )
          .toList(),
      note: json['note'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stroke': stroke.toString().split('.').last,
      'distance': distance,
      'reps': reps,
      'interval': interval,
      'equipment': equipment.map((e) => e.toString().split('.').last).toList(),
      'note': note,
    };
  }
}

// Represents a menu section (e.g., Warm-up, Main Set)
class MenuSection {
  final String id;
  MenuSectionType type;
  List<MenuItem> items;
  Intensity intensity; // Add intensity

  MenuSection({
    String? id,
    required this.type,
    List<MenuItem>? items,
    this.intensity = Intensity.medium, // Default to medium
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [];

  factory MenuSection.fromJson(Map<String, dynamic> json) {
    return MenuSection(
      id: json['id'] as String,
      type: MenuSectionType.values.firstWhere(
        (e) => e.toString() == 'MenuSectionType.${json['type']}',
      ),
      items: (json['items'] as List<dynamic>)
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      intensity: json['intensity'] != null
          ? Intensity.values.firstWhere(
              (e) => e.toString() == 'Intensity.${json['intensity']}',
              orElse: () => Intensity.medium) // Fallback
          : Intensity.medium, // Default value if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'items': items.map((e) => e.toJson()).toList(),
      'intensity': intensity.toString().split('.').last, // Add to json
    };
  }
}

// Represents the entire training menu
class TrainingMenu {
  final String id;
  String name;
  List<MenuSection> sections;

  TrainingMenu({String? id, required this.name, List<MenuSection>? sections})
      : id = id ?? const Uuid().v4(),
        sections = sections ?? [];

  factory TrainingMenu.fromJson(Map<String, dynamic> json) {
    return TrainingMenu(
      id: json['id'] as String,
      name: json['name'] as String,
      sections: (json['sections'] as List<dynamic>)
          .map((e) => MenuSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // Getter to calculate the total distance of the entire menu
  double get totalDistance {
    double total = 0;
    for (var section in sections) {
      for (var item in section.items) {
        total += item.distance * item.reps; // Calculated in meters
      }
    }
    return total / 1000; // Convert to km and return
  }

  // Getter to calculate the total distance in meters
  double get totalDistanceInMeters {
    double total = 0;
    for (var section in sections) {
      for (var item in section.items) {
        total += item.distance * item.reps; // Calculated in meters
      }
    }
    return total;
  }

  // Getter for total time in hours
  double get totalTimeInHours {
    double totalMeters = totalDistance * 1000;
    if (totalMeters == 0) return 0;
    // 20 seconds per 25 meters
    double totalSeconds = (totalMeters / 25) * 20;
    return totalSeconds / 3600; // Convert seconds to hours
  }

  // Getter to calculate total calories
  double totalCalories(double userWeight) {
    if (userWeight <= 0) return 0;

    double totalKcal = 0;
    for (var section in sections) {
      for (var item in section.items) {
        // 1. Get base METs
        double mets = _getMetsForStroke(item.stroke, section.intensity);

        // 2. Apply modifiers for section type
        switch (section.type) {
          case MenuSectionType.kick:
            mets += 0.75;
            break;
          case MenuSectionType.pull:
            mets -= 0.75;
            break;
          case MenuSectionType.up:
          case MenuSectionType.down:
            // Treat as low intensity crawl
            mets = _getMetsForStroke(StrokeType.fr, Intensity.low);
            break;
          default:
            break;
        }

        // 3. Calculate time for the item
        double itemMeters = (item.distance * item.reps).toDouble();
        double itemTimeInHours = ((itemMeters / 25) * 20) / 3600;

        // 4. Calculate calories for the item and add to total
        totalKcal += mets * itemTimeInHours * userWeight;
      }
    }
    return totalKcal;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sections': sections.map((e) => e.toJson()).toList(),
    };
  }
}
