import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../widgets/library_panel.dart';
import '../widgets/session_panel.dart';
import '../widgets/settings_panel.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
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
    );
  }
}
