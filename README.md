# WARNING! VIBE CODED!!

# Pomodoro

A Linux desktop Pomodoro timer built with Flutter. Designed around working on multiple tasks in rotating intervals, with weighted random scheduling so tasks with more time remaining are prioritized.

## Features

- **Task blueprints** — define reusable tasks with a default duration, add them to your session queue as needed
- **Presets** — save a session queue as a named preset and reload it in one click
- **Weighted random scheduling** — tasks with more time remaining are more likely to be picked next, preventing one task from being left at the end with a large chunk of time while others are nearly done
- **Round-robin mode** — alternate between tasks in order instead
- **Configurable intervals** — set how long each work interval is (5, 10, 20, or 30 minutes)
- **Breaks** — optional breaks either on a fixed interval (e.g. every 40 minutes) or a fixed count evenly distributed across the session
- **Manual or auto-advance** — auto-advance moves to the next task when the interval ends; manual mode lets the current task run into overtime until you're ready to move on
- **OS notifications** — system notification on interval completion, visible across virtual desktops
- **Chime sound** on interval completion
- **Undo / redo** — Ctrl+Z / Ctrl+Y for session and blueprint changes
- **Keyboard shortcuts** — Space to pause/resume, Enter to skip to the next task

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Space` | Pause / resume |
| `Enter` | Skip to next task (or advance in manual mode) |
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Redo |

## Project Structure

```
lib/
  main.dart                  # Entry point + PomodoroApp
  models/
    task.dart                # GlobalTask, SessionTask, ScheduleMode, BreakMode
    preset.dart              # Preset, PresetTask
  state/
    app_state.dart           # All timer, scheduling, and persistence logic
  screens/
    main_screen.dart         # Root scaffold + keyboard shortcuts
  widgets/
    library_panel.dart       # Left panel: blueprints and presets
    session_panel.dart       # Center panel: timer and queue
    settings_panel.dart      # Right panel: session settings
```

## Setup

Requires a distrobox Ubuntu 22.04 container on SteamOS (or a native Ubuntu 22.04 machine).

To set up from scratch, use the included setup script from the host:

```bash
chmod +x setup-flutter-dev.sh
./setup-flutter-dev.sh
```

To test the setup in a temporary container that gets cleaned up afterward:

```bash
./setup-flutter-dev.sh --test
```

Then enter the container and run the project:

```bash
distrobox enter flutter-dev
cd ~/Documents/Projects/pomodoro
flutter pub get
flutter run
```

## Assets

Place a chime sound file at `assets/sounds/chime.mp3` and make sure it's declared in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/sounds/chime.mp3
```