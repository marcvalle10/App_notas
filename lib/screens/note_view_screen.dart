import 'package:flutter/material.dart';

import '../data/cloud_sync_service.dart';
import '../models/note.dart';
import '../utils/date_format.dart';

class NoteViewScreen extends StatefulWidget {
  final Note note;
  final bool isShared;
  final bool canEdit;

  const NoteViewScreen({
    super.key,
    required this.note,
    required this.isShared,
    required this.canEdit,
  });

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  final _cloud = CloudSyncService();

  late Note _note; // copia local para reflejar cambios visualmente
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  Future<void> _editSharedNote() async {
    if (!widget.isShared || !widget.canEdit) return;

    final titleCtrl = TextEditingController(text: _note.title);
    final contentCtrl = TextEditingController(text: _note.content);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nota compartida'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Contenido',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Se guardará en la nube y se sincronizará.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final newTitle = titleCtrl.text.trim();
    final newContent = contentCtrl.text.trim();

    if (newTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El título no puede estar vacío.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // Si no hay internet, avisa (no guardamos offline aquí para no mezclar con Hive/shared)
      final online = await _cloud.hasInternet();
      if (!online) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sin internet: no se puede editar una nota compartida.',
            ),
          ),
        );
        return;
      }

      await _cloud.signInAnonymousIfNeeded();

      await _cloud.updateSharedNote(
        noteId: _note.id,
        title: newTitle,
        content: newContent,
        colorValue: _note.colorValue,
      );

      // Actualiza vista local
      setState(() {
        _note = _note.copyWith(
          title: newTitle,
          content: newContent,
          updatedAt: DateTime.now(),
        );
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Actualizada ✅')));

      // Regresa "true" para que NotesScreen refresque y sincronice
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo editar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = _note;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: [
          if (widget.isShared)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Row(
                  children: [
                    Icon(widget.canEdit ? Icons.edit : Icons.lock, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      widget.canEdit ? 'Editable' : 'Solo lectura',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.isShared && widget.canEdit)
            IconButton(
              tooltip: 'Editar',
              onPressed: _saving ? null : _editSharedNote,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit),
            ),
        ],
      ),
      body: Container(
        color: Color(note.colorValue).withOpacity(0.35),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                note.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Creada: ${formatDate(note.createdAt)}\nActualizada: ${formatDate(note.updatedAt)}',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              const SizedBox(height: 16),
              Text(
                note.content.isEmpty ? '(Sin contenido)' : note.content,
                style: const TextStyle(fontSize: 16),
              ),
              if (widget.isShared) ...[
                const SizedBox(height: 18),
                Text(
                  widget.canEdit
                      ? 'Nota compartida con permiso de edición.'
                      : 'Nota compartida (solo lectura).',
                  style: TextStyle(color: Colors.grey.shade800),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper: si tu Note no tiene copyWith, agrega este extension.
/// Si ya tienes copyWith en tu modelo, puedes borrar esta parte.
extension _NoteCopyWith on Note {
  Note copyWith({
    String? title,
    String? content,
    int? colorValue,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
