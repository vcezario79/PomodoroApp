class PresetTask {
  final String name;
  final int minutes;

  PresetTask({required this.name, required this.minutes});

  Map<String, dynamic> toJson() => {'name': name, 'minutes': minutes};
  factory PresetTask.fromJson(Map<String, dynamic> json) =>
      PresetTask(name: json['name'], minutes: json['minutes']);
}

class Preset {
  final String id;
  String name;
  final List<PresetTask> tasks;

  Preset({required this.id, required this.name, required this.tasks});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'tasks': tasks.map((t) => t.toJson()).toList(),
  };

  factory Preset.fromJson(Map<String, dynamic> json) => Preset(
    id: json['id'],
    name: json['name'],
    tasks: (json['tasks'] as List).map((t) => PresetTask.fromJson(t)).toList(),
  );
}
