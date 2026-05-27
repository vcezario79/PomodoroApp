import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../state/app_state.dart';

class ActiveSessionPanel extends StatelessWidget {
  const ActiveSessionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final absSeconds = state.currentCountdown.abs();
    final sign = state.currentCountdown < 0 ? "-" : "";
    final minutes = (absSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (absSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Spacer(),

          // Active task + timer
          Text(
            state.isOnBreak ? "BREAK" : (state.activeTask?.name ?? "Ready"),
            style: TextStyle(
              fontSize: 32,
              color: state.isOnBreak ? Colors.greenAccent : Colors.indigoAccent,
            ),
          ),
          Text(
            "$sign$minutes:$seconds",
            style: TextStyle(
              fontSize: 100,
              fontFamily: 'monospace',
              color: state.currentCountdown < 0
                  ? Colors.redAccent
                  : Colors.white,
            ),
          ),
          if (!state.autoProgress &&
              state.currentCountdown <= 0 &&
              state.isRunning)
            const Text(
              "OVERTIME - Press <Enter> to advance",
              style: TextStyle(color: Colors.redAccent),
            ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Stop — only shown when there's an active session
              if (state.isRunning || state.activeTask != null)
                IconButton(
                  iconSize: 36,
                  tooltip: "Stop & clear session",
                  onPressed: state.stopSession,
                  icon: const Icon(
                    Icons.stop_circle_outlined,
                    color: Colors.redAccent,
                  ),
                ),
              const SizedBox(width: 12),
              IconButton.filled(
                iconSize: 64,
                onPressed: state.isRunning
                    ? state.pauseTimer
                    : state.startTimer,
                icon: Icon(state.isRunning ? Icons.pause : Icons.play_arrow),
              ),
              const SizedBox(width: 12),
              // Skip — only shown when there's an active session
              if (state.isRunning || state.activeTask != null)
                IconButton(
                  iconSize: 36,
                  tooltip: "Skip to next task",
                  onPressed: state.skipTask,
                  icon: const Icon(Icons.skip_next),
                ),
            ],
          ),

          const Spacer(),

          // Queue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (state.sessionQueue.isEmpty)
                const Text("QUEUE")
              else
                Builder(
                  builder: (context) {
                    final totalSeconds = state.sessionQueue.fold<int>(
                      0,
                      (sum, t) =>
                          sum + t.remainingSeconds.clamp(0, t.initialSeconds),
                    );
                    final initialSeconds = state.sessionQueue.fold<int>(
                      0,
                      (sum, t) => sum + t.initialSeconds,
                    );
                    String fmt(int s) {
                      final h = s ~/ 3600;
                      final m = (s % 3600) ~/ 60;
                      return h > 0 ? "${h}h ${m}m" : "${m}m";
                    }

                    return Tooltip(
                      message: "Total original time: ${fmt(initialSeconds)}",
                      child: Text(
                        "QUEUE  ${fmt(totalSeconds)} left",
                        style: const TextStyle(letterSpacing: 0.5),
                      ),
                    );
                  },
                ),
              TextButton.icon(
                onPressed: state.sessionQueue.isEmpty
                    ? null
                    : state.stopSession,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text("Clear"),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: state.sessionQueue.length,
              itemBuilder: (context, i) {
                final item = state.sessionQueue[i];
                return ListTile(
                  leading: Text("${i + 1}"),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      color: state.activeTask == item
                          ? Colors.indigoAccent
                          : null,
                    ),
                  ),
                  subtitle: Text(
                    "${(item.remainingSeconds / 60).toStringAsFixed(1)}m left",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => state.removeFromSession(i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
