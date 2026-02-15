import 'package:hive/hive.dart';
import '../models/note.dart';

class NotesRepo {
  static const String boxName = 'notes_box';
  static const String keyNotes = 'notes';

  Future<Box> _box() async => Hive.openBox(boxName);

  Future<List<Note>> getAll() async {
    final box = await _box();
    final raw = (box.get(keyNotes) as List?) ?? [];
    final notes = raw
        .map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<void> saveAll(List<Note> notes) async {
    final box = await _box();
    await box.put(keyNotes, notes.map((n) => n.toJson()).toList());
  }

  Future<void> upsert(Note note) async {
    final notes = await getAll();
    final idx = notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      notes[idx] = note;
    } else {
      notes.add(note);
    }
    await saveAll(notes);
  }

  Future<void> delete(String id) async {
    final notes = await getAll();
    notes.removeWhere((n) => n.id == id);
    await saveAll(notes);
  }
}