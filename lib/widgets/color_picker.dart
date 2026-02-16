import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart' as cp;

import '../utils/constants.dart';

class NoteColorPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const NoteColorPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  Future<void> _openPalette(BuildContext context) async {
    Color temp = Color(selected);

    final picked = await showDialog<Color>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Elige un color'),
        content: SingleChildScrollView(
          child: cp.ColorPicker(
            pickerColor: temp,
            onColorChanged: (c) => temp = c,
            enableAlpha: false,
            displayThumbColor: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, temp),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );

    if (picked != null) onSelected(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // 7 colores predefinidos
        ...kNoteColorValues.map((v) {
          final isSelected = v == selected;
          return GestureDetector(
            onTap: () => onSelected(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Color(v),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : Colors.black26,
                  width: isSelected ? 2.5 : 1,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 18, color: Colors.black)
                  : null,
            ),
          );
        }),

        // 🎨 Paleta (color libre)
        GestureDetector(
          onTap: () => _openPalette(context),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black26),
            ),
            child: const Icon(Icons.palette, size: 18, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}