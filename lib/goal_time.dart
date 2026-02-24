import 'package:uuid/uuid.dart';

// Class to hold goal time data
class GoalTime {
  final String id;
  final String stroke; // Stroke (e.g., 'freestyle', 'breaststroke')
  final int distance; // Distance (m)
  final Duration time; // Goal time

  GoalTime({
    required this.id,
    required this.stroke,
    required this.distance,
    required this.time,
  });

  // Converts the time to a formatted string MM:SS.ss
  String get formattedTime {
    final minutes = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');
    final milliseconds =
        (time.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$milliseconds';
  }

  // Converts the object to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'stroke': stroke,
        'distance': distance,
        'time': time.inMilliseconds, // Save in milliseconds
      };

  // Creates an object from JSON
  factory GoalTime.fromJson(Map<String, dynamic> json) => GoalTime(
        id: json['id'] ?? const Uuid().v4(),
        stroke: json['stroke'],
        distance: json['distance'],
        time: Duration(milliseconds: json['time']),
      );
}
