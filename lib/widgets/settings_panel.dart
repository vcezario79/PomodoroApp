import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../state/app_state.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.all(16.0), child: Text("SETTINGS")),
        const Divider(height: 1),
        _SettingTile(
          label: "Transition",
          child: Column(
            children: [
              _Option(
                label: "Auto-advance",
                selected: state.autoProgress,
                onTap: () => state.autoProgress = true,
              ),
              _Option(
                label: "Manual (Enter)",
                selected: !state.autoProgress,
                onTap: () => state.autoProgress = false,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _SettingTile(
          label: "Order",
          child: Column(
            children: [
              _Option(
                label: "Random",
                selected: state.mode == ScheduleMode.random,
                onTap: () => state.mode = ScheduleMode.random,
              ),
              _Option(
                label: "Round-robin",
                selected: state.mode == ScheduleMode.roundRobin,
                onTap: () => state.mode = ScheduleMode.roundRobin,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        _SettingTile(
          label: "Interval",
          child: Column(
            children: [5, 10, 20, 30]
                .map(
                  (i) => _Option(
                    label: "${i} minutes",
                    selected: state.intervalMinutes == i,
                    onTap: () => state.intervalMinutes = i,
                  ),
                )
                .toList(),
          ),
        ),
        const Divider(height: 1),
        const Divider(height: 1),
        _SettingTile(
          label: "Breaks",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Option(
                label: "Enabled",
                selected: state.breaksEnabled,
                onTap: () => state.breaksEnabled = !state.breaksEnabled,
              ),
              if (state.breaksEnabled) ...[
                const SizedBox(height: 4),
                _Stepper(
                  label: "Break duration",
                  value: state.breakDuration,
                  unit: "min",
                  min: 1,
                  max: 60,
                  onChanged: (v) => state.breakDuration = v,
                ),
                const SizedBox(height: 8),
                _Option(
                  label: "By interval",
                  selected: state.breakMode == BreakMode.interval,
                  onTap: () => state.breakMode = BreakMode.interval,
                ),
                _Option(
                  label: "By count",
                  selected: state.breakMode == BreakMode.count,
                  onTap: () => state.breakMode = BreakMode.count,
                ),
                const SizedBox(height: 4),
                if (state.breakMode == BreakMode.interval)
                  _Stepper(
                    label: "Every",
                    value: state.breakInterval,
                    unit: "min",
                    min: 5,
                    max: 120,
                    onChanged: (v) => state.breakInterval = v,
                  ),
                if (state.breakMode == BreakMode.count)
                  _Stepper(
                    label: "Number of breaks",
                    value: state.breakCount,
                    unit: "",
                    min: 1,
                    max: 10,
                    onChanged: (v) => state.breakCount = v,
                  ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final String label;
  final Widget child;

  const _SettingTile({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white54,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 18,
              color: selected ? Colors.indigoAccent : Colors.white38,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: selected ? Colors.white : Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatefulWidget {
  final String label;
  final int value;
  final String unit;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_Stepper> createState() => _StepperState();
}

class _StepperState extends State<_Stepper> {
  bool _editing = false;
  late TextEditingController _controller;

  void _startEditing() {
    _controller = TextEditingController(text: widget.value.toString());
    setState(() => _editing = true);
  }

  void _commitEdit() {
    final parsed = int.tryParse(_controller.text);
    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
    }
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              widget.label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: [
              IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.remove),
                onPressed: widget.value > widget.min
                    ? () => widget.onChanged(widget.value - 1)
                    : null,
              ),
              GestureDetector(
                onDoubleTap: _startEditing,
                child: GestureDetector(
                  onDoubleTap: _startEditing,
                  child: SizedBox(
                    width: 36,
                    child: _editing
                        ? TextField(
                            controller: _controller,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 4),
                              border: UnderlineInputBorder(),
                            ),
                            onSubmitted: (_) => _commitEdit(),
                            onTapOutside: (_) => _commitEdit(),
                          )
                        : Column(
                            children: [
                              Text(
                                "${widget.value}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (widget.unit.isNotEmpty)
                                Text(
                                  widget.unit,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white54,
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ),
              IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.add),
                onPressed: widget.value < widget.max
                    ? () => widget.onChanged(widget.value + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
