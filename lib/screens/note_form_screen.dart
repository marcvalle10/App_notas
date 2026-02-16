import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/notes_repo.dart';
import '../models/note.dart';
import '../utils/constants.dart';
import '../widgets/color_picker.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? editing;
  const NoteFormScreen({super.key, this.editing});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _repo = NotesRepo();
  final _title = TextEditingController();
  final _content = TextEditingController();

  int _colorValue = kDefaultColorValue;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _title.text = e.title;
      _content.text = e.content;
      _colorValue = e.colorValue;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final content = _content.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título es obligatorio.')),
      );
      return;
    }

    final now = DateTime.now();

    final note = _isEditing
        ? widget.editing!.copyWith(
            title: title,
            content: content,
            colorValue: _colorValue,
            updatedAt: now,
          )
        : Note(
            id: const Uuid().v4(),
            title: title,
            content: content,
            colorValue: _colorValue,
            createdAt: now,
            updatedAt: now,
          );

    await _repo.upsert(note);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Nota' : 'Nueva Nota'),
      ),
      body: Container(
        color: Color(_colorValue).withOpacity(0.35),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _content,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Contenido',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Color de nota',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),

            // ✅ 7 colores + paleta libre
            NoteColorPicker(
              selected: _colorValue,
              onSelected: (v) => setState(() => _colorValue = v),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}