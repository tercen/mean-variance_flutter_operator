import 'package:flutter/material.dart';

/// Compact number input field (volcano pattern)
/// Empty field = auto/null value
class CompactNumberField extends StatefulWidget {
  final double? value;
  final String hint;
  final ValueChanged<double?> onChanged;

  const CompactNumberField({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<CompactNumberField> createState() => _CompactNumberFieldState();
}

class _CompactNumberFieldState extends State<CompactNumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.value?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(CompactNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = widget.value?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          hintText: widget.hint,
          hintStyle: const TextStyle(fontSize: 12),
        ),
        onChanged: (value) {
          if (value.isEmpty) {
            widget.onChanged(null); // null = auto
          } else {
            final parsed = double.tryParse(value);
            if (parsed != null) {
              widget.onChanged(parsed);
            }
          }
        },
      ),
    );
  }
}
