import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/library_panel.dart';
import '../widgets/session_panel.dart';
import '../widgets/settings_panel.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  void _showConflictDialog(BuildContext context, AppState state) {
    final conflict = state.pendingConflicts.first;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text("Sync Conflict"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("A task differs between this device and the NAS:"),
            const SizedBox(height: 12),
            Text(
              "Local:  ${conflict.local.name} (${conflict.local.defaultMinutes}m)",
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              "Remote: ${conflict.remote.name} (${conflict.remote.defaultMinutes}m)",
              style: const TextStyle(color: Colors.indigoAccent),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              state.resolveConflict(conflict, false); // keep local
              Navigator.pop(c);
            },
            child: const Text("Keep Local"),
          ),
          ElevatedButton(
            onPressed: () {
              state.resolveConflict(conflict, true); // use remote
              Navigator.pop(c);
            },
            child: const Text("Use Remote"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.pendingConflicts.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showConflictDialog(context, state);
            });
          }
          return child!;
        },
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              final state = context.read<AppState>();
              if (event.logicalKey == LogicalKeyboardKey.space) {
                state.isRunning ? state.pauseTimer() : state.startTimer();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.enter) {
                state.advanceManual();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.keyZ &&
                  HardwareKeyboard.instance.isControlPressed) {
                state.undo();
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.keyY &&
                  HardwareKeyboard.instance.isControlPressed) {
                state.redo();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: Row(
            children: const [
              SizedBox(width: 280, child: GlobalLibraryPanel()),
              VerticalDivider(width: 1),
              Expanded(child: ActiveSessionPanel()),
              VerticalDivider(width: 1),
              SizedBox(width: 220, child: SettingsPanel()),
            ],
          ),
        ),
      ),
    );
  }
}
