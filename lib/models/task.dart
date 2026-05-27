enum ScheduleMode { roundRobin, random }

enum BreakMode { interval, count }

class GlobalTask {
  final String id;
  String name;
  int defaultMinutes;

  GlobalTask({
    required this.id,
    required this.name,
    required this.defaultMinutes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'defaultMinutes': defaultMinutes,
  };

  factory GlobalTask.fromJson(Map<String, dynamic> json) => GlobalTask(
    id: json['id'],
    name: json['name'],
    defaultMinutes: json['defaultMinutes'],
  );
}

class SessionTask {
  final String globalTaskId;
  final String name;
  final int initialSeconds;
  int remainingSeconds;

  SessionTask({
    required this.globalTaskId,
    required this.name,
    required int initialMinutes,
  }) : initialSeconds = initialMinutes * 60,
       remainingSeconds = initialMinutes * 60;
}
