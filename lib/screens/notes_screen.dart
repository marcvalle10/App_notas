import 'package:flutter/material.dart';
import '../data/notes_repo.dart';
import '../models/note.dart';
import 'note_form_screen.dart';
import 'note_view_screen.dart';
import '../widgets/note_card.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _repo = NotesRepo();
  List<Note> _notes = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await _repo.getAll();
    setState(() => _notes = notes);
  }

  List<Note> get _filtered {
    if (_query.trim().isEmpty) return _notes;
    final q = _query.toLowerCase();
    return _notes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Seguro que deseas eliminar esta nota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _repo.delete(note.id);
      await _load();
    }
  }

  Future<void> _openCreate() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NoteFormScreen()),
    );
    if (changed == true) await _load();
  }

  Future<void> _openEdit(Note note) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteFormScreen(editing: note)),
    );
    if (changed == true) await _load();
  }

  void _openView(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteViewScreen(note: note)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Notas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // regresar a inicio
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar nota...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No hay notas aún.'))
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final note = items[i];

                        // Swipe para eliminar (como tu UI web con acciones)
                        return Dismissible(
                          key: ValueKey(note.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            await _confirmDelete(note);
                            return false; // no lo auto borra visualmente
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 18),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          child: NoteCard(
                            note: note,
                            onTap: () => _openView(note),
                            onEdit: () => _openEdit(note),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}