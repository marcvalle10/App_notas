import 'package:hive/hive.dart';
import '../models/note.dart';

class NotesRepo {
  static const String boxName = 'notes_box';

  static const String keyNotes = 'notes';
  static const String keyShared = 'shared_notes';
  static const String keyDeleted = 'deleted_note_ids'; // tombstones

  Future<Box> _box() async => Hive.openBox(boxName);

  // ---------- Mis notas ----------
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

  /// trackRemote=true => agrega el ID a la cola de eliminados para borrar en nube en la próxima sync
  Future<void> delete(String id, {bool trackRemote = true}) async {
    final notes = await getAll();
    notes.removeWhere((n) => n.id == id);
    await saveAll(notes);

    if (trackRemote) {
      await markDeleted(id);
    }
  }

  // ---------- Compartidas conmigo ----------
  Future<List<Note>> getShared() async {
    final box = await _box();
    final raw = (box.get(keyShared) as List?) ?? [];
    final notes = raw
        .map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }

  Future<void> saveShared(List<Note> notes) async {
    final box = await _box();
    await box.put(keyShared, notes.map((n) => n.toJson()).toList());
  }

  Future<void> hideSharedLocally(String id) async {
    final shared = await getShared();
    shared.removeWhere((n) => n.id == id);
    await saveShared(shared);
  }

  // ---------- Tombstones (eliminados) ----------
  Future<List<String>> getDeletedIds() async {
    final box = await _box();
    final raw = (box.get(keyDeleted) as List?) ?? [];
    return raw.map((e) => e.toString()).toList();
  }

  Future<void> markDeleted(String id) async {
    final box = await _box();
    final ids = await getDeletedIds();
    if (!ids.contains(id)) ids.add(id);
    await box.put(keyDeleted, ids);
  }

  Future<void> clearDeletedIds() async {
    final box = await _box();
    await box.put(keyDeleted, <String>[]);
  }
}