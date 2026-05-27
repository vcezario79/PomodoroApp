import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:local_notifier/local_notifier.dart';

import '../models/preset.dart';
import '../models/task.dart';

class _AppSnapshot {
  final List<(String globalTaskId, String name, int remainingSeconds)> queue;
  final List<(String id, String name, int defaultMinutes)> globalTasks;
  final int queueIndex;
  final int countdown;

  _AppSnapshot(
    List<SessionTask> queue,
    List<GlobalTask> globalTasks,
    int queueIndex,
    int countdown,
  ) : queue = queue
          .map((t) => (t.globalTaskId, t.name, t.remainingSeconds))
          .toList(),
      globalTasks = globalTasks
          .map((t) => (t.id, t.name, t.defaultMinutes))
          .toList(),
      queueIndex = queueIndex,
      countdown = countdown;
}

class AppState extends ChangeNotifier {
  final SharedPreferences prefs;
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<GlobalTask> _globalTasks = [];
  List<SessionTask> _sessionQueue = [];
  List<Preset> _presets = [];
  final List<_AppSnapshot> _undoStack = [];
  final List<_AppSnapshot> _redoStack = [];

  Timer? _timer;
  int _currentCountdown = 0;
  int _currentQueueIndex = -1;
  bool _isRunning = false;

  bool _isOnBreak = false;
  bool get isOnBreak => _isOnBreak;
  int _workSecondsAccumulated = 0;
  List<int> _breakPoints = [];

  int _intervalMinutes = 5;
  int get intervalMinutes => _intervalMinutes;
  set intervalMinutes(int v) {
    _intervalMinutes = v;
    notifyListeners();
  }

  ScheduleMode _mode = ScheduleMode.random;
  ScheduleMode get mode => _mode;
  set mode(ScheduleMode v) {
    _mode = v;
    notifyListeners();
  }

  bool _autoProgress = false;
  bool get autoProgress => _autoProgress;
  set autoProgress(bool v) {
    _autoProgress = v;
    notifyListeners();
  }

  bool _breaksEnabled = false;
  bool get breaksEnabled => _breaksEnabled;
  set breaksEnabled(bool v) {
    _breaksEnabled = v;
    notifyListeners();
  }

  BreakMode _breakMode = BreakMode.interval;
  BreakMode get breakMode => _breakMode;
  set breakMode(BreakMode v) {
    _breakMode = v;
    notifyListeners();
  }

  int _breakDuration = 5;
  int get breakDuration => _breakDuration;
  set breakDuration(int v) {
    _breakDuration = v;
    notifyListeners();
  }

  int _breakInterval = 40;
  int get breakInterval => _breakInterval;
  set breakInterval(int v) {
    _breakInterval = v;
    notifyListeners();
  }

  int _breakCount = 3;
  int get breakCount => _breakCount;
  set breakCount(int v) {
    _breakCount = v;
    notifyListeners();
  }

  AppState(this.prefs) {
    _loadData();
  }

  List<GlobalTask> get globalTasks => _globalTasks;
  List<SessionTask> get sessionQueue => _sessionQueue;
  List<Preset> get presets => _presets;
  SessionTask? get activeTask =>
      (_currentQueueIndex >= 0 && _currentQueueIndex < _sessionQueue.length)
      ? _sessionQueue[_currentQueueIndex]
      : null;
  int get currentCountdown => _currentCountdown;
  bool get isRunning => _isRunning;

  // --- ACTIONS ---

  void addGlobalTask(String name, int minutes) {
    _pushUndo();
    _globalTasks.add(
      GlobalTask(id: const Uuid().v4(), name: name, defaultMinutes: minutes),
    );
    _saveData();
    notifyListeners();
  }

  void deleteGlobalTask(String id) {
    _pushUndo();
    _globalTasks.removeWhere((t) => t.id == id);
    _saveData();
    notifyListeners();
  }

  void editGlobalTask(String id, String name, int minutes) {
    _pushUndo();
    final task = _globalTasks.firstWhere((t) => t.id == id);
    task.name = name;
    task.defaultMinutes = minutes;
    _saveData();
    notifyListeners();
  }

  void addToSession(GlobalTask template) {
    _pushUndo();
    _sessionQueue.add(
      SessionTask(
        globalTaskId: template.id,
        name: template.name,
        initialMinutes: template.defaultMinutes,
      ),
    );
    notifyListeners();
  }

  void removeFromSession(int index) {
    _pushUndo();
    _sessionQueue.removeAt(index);
    notifyListeners();
  }

  void stopSession() {
    _pushUndo();
    _timer?.cancel();
    _sessionQueue.clear();
    _currentQueueIndex = -1;
    _currentCountdown = 0;
    _isRunning = false;
    _isOnBreak = false;
    _workSecondsAccumulated = 0;
    _breakPoints = [];
    notifyListeners();
  }

  void skipTask() {
    _pushUndo();
    if (!_isRunning && activeTask == null) return;
    _timer?.cancel();
    if (_selectNextTask()) {
      startTimer();
    } else {
      _isRunning = false;
      notifyListeners();
    }
  }

  // Snapshots the current session queue as a named preset.
  void savePreset(String name) {
    if (_sessionQueue.isEmpty) return;
    final tasks = _sessionQueue.map((t) {
      // Convert remaining seconds back to whole minutes, minimum 1.
      final minutes = (t.remainingSeconds / 60).ceil().clamp(1, 9999);
      return PresetTask(name: t.name, minutes: minutes);
    }).toList();
    _presets.add(Preset(id: const Uuid().v4(), name: name, tasks: tasks));
    _saveData();
    notifyListeners();
  }

  // Appends all tasks from a preset into the current session queue.
  void loadPreset(Preset preset) {
    _pushUndo();
    for (final t in preset.tasks) {
      _sessionQueue.add(
        SessionTask(
          globalTaskId: const Uuid().v4(),
          name: t.name,
          initialMinutes: t.minutes,
        ),
      );
    }
    notifyListeners();
  }

  void deletePreset(String id) {
    _pushUndo();
    _presets.removeWhere((p) => p.id == id);
    _saveData();
    notifyListeners();
  }

  void _pushUndo() {
    _undoStack.add(
      _AppSnapshot(
        _sessionQueue,
        _globalTasks,
        _currentQueueIndex,
        _currentCountdown,
      ),
    );
    if (_undoStack.length > 20) _undoStack.removeAt(0);
    _redoStack.clear(); // branching clears redo history
  }

  void _restoreSnapshot(_AppSnapshot snap) {
    _timer?.cancel();
    _isRunning = false;
    _sessionQueue = snap.queue
        .map(
          (t) =>
              SessionTask(globalTaskId: t.$1, name: t.$2, initialMinutes: 0)
                ..remainingSeconds = t.$3,
        )
        .toList();
    _globalTasks = snap.globalTasks
        .map((t) => GlobalTask(id: t.$1, name: t.$2, defaultMinutes: t.$3))
        .toList();
    _currentQueueIndex = snap.queueIndex;
    _currentCountdown = snap.countdown;
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(
      _AppSnapshot(
        _sessionQueue,
        _globalTasks,
        _currentQueueIndex,
        _currentCountdown,
      ),
    );
    _restoreSnapshot(_undoStack.removeLast());
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(
      _AppSnapshot(
        _sessionQueue,
        _globalTasks,
        _currentQueueIndex,
        _currentCountdown,
      ),
    );
    _restoreSnapshot(_redoStack.removeLast());
  }
  // --- TIMER ENGINE ---

  void startTimer() {
    if (_sessionQueue.isEmpty) return;
    if (activeTask == null) {
      if (_breaksEnabled && _breakMode == BreakMode.count) {
        _initBreakPoints();
      }
      if (!_selectNextTask()) return;
    }
    _startCountdown();
  }

  void _startCountdown() {
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentCountdown--;
      if (!_isOnBreak && activeTask != null) {
        activeTask!.remainingSeconds--;
        _workSecondsAccumulated++;
      }
      if (_currentCountdown == 0) {
        _playChime();
        if (autoProgress) _onIntervalComplete();
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void _startBreak() {
    if (_breakMode == BreakMode.interval) {
      _workSecondsAccumulated = 0;
    } else {
      if (_breakPoints.isNotEmpty) _breakPoints.removeAt(0);
    }
    _isOnBreak = true;
    _currentCountdown = _breakDuration * 60;
    _startCountdown();
  }

  void _initBreakPoints() {
    final total = _sessionQueue.fold<int>(0, (s, t) => s + t.remainingSeconds);
    _breakPoints = List.generate(
      _breakCount,
      (i) => total * (i + 1) ~/ (_breakCount + 1),
    );
    _workSecondsAccumulated = 0;
  }

  bool _shouldTakeBreak() {
    if (!_breaksEnabled) return false;
    if (_breakMode == BreakMode.interval) {
      return _workSecondsAccumulated >= _breakInterval * 60;
    } else {
      return _breakPoints.isNotEmpty &&
          _workSecondsAccumulated >= _breakPoints.first;
    }
  }

  void pauseTimer() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void advanceManual() {
    if (!autoProgress && _isRunning) {
      _onIntervalComplete();
    }
  }

  void _onIntervalComplete() {
    _timer?.cancel();
    if (_isOnBreak) {
      _isOnBreak = false;
      if (_selectNextTask()) {
        _startCountdown();
      } else {
        _isRunning = false;
        notifyListeners();
      }
      return;
    }
    if (_shouldTakeBreak()) {
      _startBreak();
      return;
    }
    if (_selectNextTask()) {
      _startCountdown();
    } else {
      _isRunning = false;
      notifyListeners();
    }
  }

  bool _selectNextTask() {
    final available = _sessionQueue
        .asMap()
        .entries
        .where((e) => e.value.remainingSeconds > 0)
        .toList();
    if (available.isEmpty) return false;

    if (mode == ScheduleMode.roundRobin) {
      int nextIdx = -1;
      for (int i = 1; i <= _sessionQueue.length; i++) {
        int checkIdx = (_currentQueueIndex + i) % _sessionQueue.length;
        if (_sessionQueue[checkIdx].remainingSeconds > 0) {
          nextIdx = checkIdx;
          break;
        }
      }
      _currentQueueIndex = nextIdx;
    } else {
      final currentId = activeTask?.globalTaskId;
      final candidates = available
          .where((e) => e.value.globalTaskId != currentId)
          .toList();
      final pool = candidates.isNotEmpty ? candidates : available;

      // Weighted pick: weight = remainingSeconds^exponent, so tasks with more
      // time left are proportionally more likely to be chosen next.
      const double exponent = 1.7;
      final weights = pool
          .map((e) => pow(e.value.remainingSeconds, exponent).toDouble())
          .toList();
      final totalWeight = weights.fold<double>(0, (sum, w) => sum + w);
      double pick = Random().nextDouble() * totalWeight;
      _currentQueueIndex = pool.last.key; // fallback
      for (int i = 0; i < pool.length; i++) {
        pick -= weights[i];
        if (pick < 0) {
          _currentQueueIndex = pool[i].key;
          break;
        }
      }
    }

    _currentCountdown = min(intervalMinutes * 60, activeTask!.remainingSeconds);
    return _currentQueueIndex != -1;
  }

  // --- PERSISTENCE ---

  void _saveData() {
    prefs.setString(
      'global_tasks',
      jsonEncode(_globalTasks.map((t) => t.toJson()).toList()),
    );
    prefs.setString(
      'presets',
      jsonEncode(_presets.map((p) => p.toJson()).toList()),
    );
  }

  void _loadData() {
    final String? taskData = prefs.getString('global_tasks');
    if (taskData != null) {
      _globalTasks = (jsonDecode(taskData) as List)
          .map((i) => GlobalTask.fromJson(i))
          .toList();
    }
    final String? presetData = prefs.getString('presets');
    if (presetData != null) {
      _presets = (jsonDecode(presetData) as List)
          .map((i) => Preset.fromJson(i))
          .toList();
    }
    notifyListeners();
  }

  // --- AUDIO ---

  Future<void> _playChime() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/chime.mp3'));
    } catch (e) {
      debugPrint("Sound error: $e");
    }

    final notification = LocalNotification(
      title: "Pomodoro — Interval Complete",
      body: activeTask != null
          ? '"${activeTask!.name}" interval finished.'
          : "Interval finished.",
    );
    await notification.show();
  }
}
