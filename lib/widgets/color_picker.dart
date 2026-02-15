import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ColorPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const ColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kNoteColorValues.map((v) {
        final isSelected = v == selected;
        return InkWell(
          onTap: () => onSelected(v),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(v),
              shape: BoxShape.circle,
              border: Border.all(
                width: isSelected ? 3 : 1,
                color: isSelected ? Colors.black : Colors.grey.shade500,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18)
                : const SizedBox.shrink(),
          ),
        );
      }).toList(),
    );
  }
}