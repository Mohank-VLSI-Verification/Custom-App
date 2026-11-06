import 'package:flutter/material.dart';

import '../models/shift.dart';
import '../services/repository.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../utils/time_utils.dart';
import 'time_wheel.dart';

class ShiftEditResult {
  final Shift? shift;
  final bool delete;

  const ShiftEditResult.save(Shift this.shift) : delete = false;
  const ShiftEditResult.delete()
      : shift = null,
        delete = true;
}

/// Opens the add/edit sheet and applies the result.
Future<void> openShiftEditor(
  BuildContext context, {
  Shift? existing,
  DateTime? day,
}) async {
  final result = await showModalBottomSheet<ShiftEditResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => ShiftEditSheet(existing: existing, day: day),
  );
  if (result == null) return;
  final repo = Repository.instance;
  if (result.delete) {
    if (existing != null) await repo.deleteShift(existing.id);
  } else if (result.shift != null) {
    if (existing == null) {
      await repo.addShift(result.shift!);
    } else {
      await repo.updateShift(result.shift!);
    }
  }
}

class ShiftEditSheet extends StatefulWidget {
  final Shift? existing;
  final DateTime? day;

  const ShiftEditSheet({super.key, this.existing, this.day});

  @override
  State<ShiftEditSheet> createState() => _ShiftEditSheetState();
}

class _ShiftEditSheetState extends State<ShiftEditSheet> {
  late DateTime _start;
  late DateTime _end;
  late final TextEditingController _note;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _start = e.start;
      _end = e.end;
    } else {
      final d = dateOnly(widget.day ?? DateTime.now());
      _start = DateTime(d.year, d.month, d.day, 9, 0);
      _end = DateTime(d.year, d.month, d.day, 17, 0);
    }
    _note = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DateTime _withDate(DateTime t, DateTime d) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  DateTime _withTime(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  Future<void> _pickDate(bool isStart) async {
    final current = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        // Keep the end on the same relative day as the start.
        final shift = daysBetween(_start, picked);
        _start = _withDate(_start, picked);
        _end = _withDate(_end, addDays(_end, shift));
      } else {
        _end = _withDate(_end, picked);
      }
      _error = null;
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final current = isStart ? _start : _end;
    final picked = await showTimeWheel(
      context,
      initial: TimeOfDay.fromDateTime(current),
      title: isStart ? 'Start time' : 'End time',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = _withTime(_start, picked);
      } else {
        _end = _withTime(_end, picked);
      }
      _error = null;
    });
  }

  void _save() {
    if (!_end.isAfter(_start)) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }
    final shift = Shift(
      id: widget.existing?.id ?? Shift.newId(),
      start: _start,
      end: _end,
      note: _note.text.trim(),
    );
    Navigator.of(context).pop(ShiftEditResult.save(shift));
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit Shift' : 'Add Shift',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text),
            ),
            const SizedBox(height: 16),
            _PickRow(
              label: 'Date',
              text: fmtDay(_start),
              onTap: () => _pickDate(true),
            ),
            const SizedBox(height: 12),
            _PickRow(
              label: 'Start',
              text: fmtClock(_start),
              onTap: () => _pickTime(true),
            ),
            const SizedBox(height: 12),
            _PickRow(
              label: 'End',
              text: fmtClock(_end),
              onTap: () => _pickTime(false),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (isEdit)
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pop(const ShiftEditResult.delete()),
                    style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error),
                    child: const Text('Delete'),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  final String label;
  final String text;
  final VoidCallback onTap;

  const _PickRow({
    required this.label,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(label,
              style: const TextStyle(fontSize: 15, color: AppColors.muted)),
        ),
        Expanded(
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(text, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}
