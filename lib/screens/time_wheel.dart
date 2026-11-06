import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Phone-clock style time picker: scroll wheels for hour, minute and
/// a.m./p.m. Tap the hour or minute to type it on the keyboard.
Future<TimeOfDay?> showTimeWheel(
  BuildContext context, {
  required TimeOfDay initial,
  String? title,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.black,
    builder: (_) => _TimeWheelSheet(initial: initial, title: title),
  );
}

enum _Field { hour, minute }

class _TimeWheelSheet extends StatefulWidget {
  final TimeOfDay initial;
  final String? title;
  const _TimeWheelSheet({required this.initial, this.title});

  @override
  State<_TimeWheelSheet> createState() => _TimeWheelSheetState();
}

class _TimeWheelSheetState extends State<_TimeWheelSheet> {
  static const _extent = 92.0;
  static const _faded = Color(0xFF3A3A3A);

  late int _hour12; // 1..12
  late int _minute; // 0..59
  late bool _pm;
  late final FixedExtentScrollController _hourCtl;
  late final FixedExtentScrollController _minCtl;
  late final FixedExtentScrollController _ampmCtl;

  _Field? _editing;
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    final h = widget.initial.hour;
    _pm = h >= 12;
    _hour12 = h % 12 == 0 ? 12 : h % 12;
    _minute = widget.initial.minute;
    _hourCtl = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minCtl = FixedExtentScrollController(initialItem: _minute);
    _ampmCtl = FixedExtentScrollController(initialItem: _pm ? 1 : 0);
  }

  @override
  void dispose() {
    _hourCtl.dispose();
    _minCtl.dispose();
    _ampmCtl.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  TimeOfDay get _value =>
      TimeOfDay(hour: (_hour12 % 12) + (_pm ? 12 : 0), minute: _minute);

  /// Moves a looping wheel to [index] by the shortest path.
  void _jump(FixedExtentScrollController c, int count, int index) {
    final cur = c.selectedItem;
    var target = cur - (cur % count) + index;
    if (target - cur > count / 2) target -= count;
    if (cur - target > count / 2) target += count;
    c.animateToItem(target,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _startEdit(_Field f) {
    setState(() {
      _editing = f;
      _text.clear();
    });
    _focus.requestFocus();
  }

  void _commitEdit({bool next = false}) {
    final v = int.tryParse(_text.text);
    if (_editing == _Field.hour && v != null && v >= 1 && v <= 12) {
      _hour12 = v;
      _jump(_hourCtl, 12, v - 1);
    } else if (_editing == _Field.minute && v != null && v >= 0 && v <= 59) {
      _minute = v;
      _jump(_minCtl, 60, v);
    }
    if (next && _editing == _Field.hour) {
      _startEdit(_Field.minute);
      return;
    }
    _focus.unfocus();
    setState(() => _editing = null);
  }

  void _onTyped(String s) {
    final v = int.tryParse(s);
    if (v == null) return;
    if (_editing == _Field.hour && (s.length == 2 || v >= 2)) {
      _commitEdit(next: true);
    } else if (_editing == _Field.minute && s.length == 2) {
      _commitEdit();
    }
  }

  TextStyle _style(bool selected, double size) => TextStyle(
        fontSize: size,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        color: selected ? Colors.white : _faded,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required bool looping,
    required int selected,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
    required double fontSize,
    required VoidCallback onTapCenter,
    _Field? field,
  }) {
    final items = [
      for (var i = 0; i < count; i++)
        Center(child: Text(label(i), style: _style(i == selected, fontSize))),
    ];
    final editingThis = field != null && _editing == field;
    return SizedBox(
      height: _extent * 3,
      child: Stack(
        children: [
          ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: _extent,
            physics: const FixedExtentScrollPhysics(),
            diameterRatio: 3,
            onSelectedItemChanged: (i) => setState(() => onChanged(i % count)),
            childDelegate: looping
                ? ListWheelChildLoopingListDelegate(children: items)
                : ListWheelChildListDelegate(children: items),
          ),
          Positioned(
            top: _extent,
            height: _extent,
            left: 0,
            right: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onTapCenter,
            ),
          ),
          if (editingThis)
            Positioned(
              top: _extent,
              height: _extent,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: fontSize * 1.5,
                  color: Colors.black,
                  child: Container(
                    color: const Color(0xFF2C2C2C),
                    child: TextField(
                      controller: _text,
                      focusNode: _focus,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction: field == _Field.hour
                          ? TextInputAction.next
                          : TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      cursorColor: Colors.white,
                      style: _style(true, fontSize),
                      decoration: InputDecoration.collapsed(
                        hintText: label(selected),
                        hintStyle: _style(true, fontSize)
                            .copyWith(color: Colors.white54),
                      ),
                      onChanged: _onTyped,
                      onSubmitted: (_) =>
                          _commitEdit(next: field == _Field.hour),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pill() {
    const style = TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
            child: const Text('Cancel', style: style),
          ),
          Container(width: 1, height: 22, color: const Color(0xFF555555)),
          TextButton(
            onPressed: () {
              if (_editing != null) _commitEdit();
              Navigator.of(context).pop(_value);
            },
            style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16)),
            child: const Text('Save', style: style),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          12, 20, 12, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(widget.title!,
                  style:
                      const TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
            ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _wheel(
                  controller: _hourCtl,
                  count: 12,
                  looping: true,
                  selected: _hour12 - 1,
                  label: (i) => '${i + 1}',
                  onChanged: (i) => _hour12 = i + 1,
                  fontSize: 72,
                  field: _Field.hour,
                  onTapCenter: () => _startEdit(_Field.hour),
                ),
              ),
              Text(':', style: _style(true, 64)),
              Expanded(
                flex: 3,
                child: _wheel(
                  controller: _minCtl,
                  count: 60,
                  looping: true,
                  selected: _minute,
                  label: (i) => i.toString().padLeft(2, '0'),
                  onChanged: (i) => _minute = i,
                  fontSize: 72,
                  field: _Field.minute,
                  onTapCenter: () => _startEdit(_Field.minute),
                ),
              ),
              Expanded(
                flex: 3,
                child: _wheel(
                  controller: _ampmCtl,
                  count: 2,
                  looping: false,
                  selected: _pm ? 1 : 0,
                  label: (i) => i == 0 ? 'a.m.' : 'p.m.',
                  onChanged: (i) => _pm = i == 1,
                  fontSize: 40,
                  onTapCenter: () {
                    _pm = !_pm;
                    _ampmCtl.animateToItem(_pm ? 1 : 0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut);
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _pill(),
        ],
      ),
    );
  }
}
