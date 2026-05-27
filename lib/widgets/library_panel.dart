import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/preset.dart';
import '../state/app_state.dart';

class GlobalLibraryPanel extends StatelessWidget {
  const GlobalLibraryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: "BLUEPRINTS"),
              Tab(text: "PRESETS"),
            ],
          ),
          Expanded(
            child: TabBarView(children: [_BlueprintsTab(), _PresetsTab()]),
          ),
        ],
      ),
    );
  }
}

// --- Blueprints tab ---

class _BlueprintsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: state.globalTasks.length,
            itemBuilder: (context, i) {
              final task = state.globalTasks[i];
              return ListTile(
                title: Text(task.name),
                subtitle: Text("${task.defaultMinutes}m"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: "Add to session",
                      onPressed: () => state.addToSession(task),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: "Delete",
                      onPressed: () => state.deleteGlobalTask(task.id),
                    ),
                  ],
                ),
                onLongPress: () => _showEditTaskDialog(context, state, task),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddTaskDialog(context),
            icon: const Icon(Icons.add),
            label: const Text("New Blueprint"),
          ),
        ),
      ],
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final name = TextEditingController();
    final time = TextEditingController(text: "30");
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("New Blueprint"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Task name"),
              autofocus: true,
            ),
            TextField(
              controller: time,
              decoration: const InputDecoration(labelText: "Minutes"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(time.text) ?? 30;
              context.read<AppState>().addGlobalTask(name.text, minutes);
              Navigator.pop(c);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, AppState state, task) {
    final name = TextEditingController(text: task.name);
    final time = TextEditingController(text: task.defaultMinutes.toString());
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Edit Blueprint"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Task name"),
              autofocus: true,
            ),
            TextField(
              controller: time,
              decoration: const InputDecoration(labelText: "Minutes"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final minutes = int.tryParse(time.text) ?? task.defaultMinutes;
              state.editGlobalTask(task.id, name.text.trim(), minutes);
              Navigator.pop(c);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}

// --- Presets tab ---

class _PresetsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        Expanded(
          child: state.presets.isEmpty
              ? const Center(
                  child: Text(
                    "No presets yet.\nSave your session queue as a preset.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  itemCount: state.presets.length,
                  itemBuilder: (context, i) {
                    final preset = state.presets[i];
                    return ListTile(
                      title: Text(preset.name),
                      subtitle: Tooltip(
                        message: preset.tasks
                            .map((t) => "${t.name} (${t.minutes}m)")
                            .join("\n"),
                        child: Text(
                          preset.tasks.map((t) => t.name).join(", "),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        tooltip: "Load into session",
                        onPressed: () => _confirmLoad(context, state, preset),
                      ),
                      onLongPress: () => _confirmDelete(context, state, preset),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: state.sessionQueue.isEmpty
                ? null // greyed out when queue is empty
                : () => _showSaveDialog(context),
            icon: const Icon(Icons.bookmark_add),
            label: const Text("Save Session as Preset"),
          ),
        ),
      ],
    );
  }

  void _showSaveDialog(BuildContext context) {
    final name = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Save Preset"),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(labelText: "Preset name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (name.text.trim().isNotEmpty) {
                context.read<AppState>().savePreset(name.text.trim());
                Navigator.pop(c);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmLoad(BuildContext context, AppState state, Preset preset) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Load "${preset.name}"?'),
        content: Text(
          "${preset.tasks.length} task(s): ${preset.tasks.map((t) => t.name).join(", ")}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              state.loadPreset(preset);
              Navigator.pop(c);
            },
            child: Text(state.sessionQueue.isEmpty ? "Load" : "Append"),
          ),
          if (state.sessionQueue.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                state.stopSession();
                state.loadPreset(preset);
                Navigator.pop(c);
              },
              child: const Text("Replace"),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, Preset preset) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete "${preset.name}"?'),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              state.deletePreset(preset.id);
              Navigator.pop(c);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
