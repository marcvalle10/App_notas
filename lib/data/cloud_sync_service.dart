import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/note.dart';

class CloudSyncService {
  final SupabaseClient _sb = Supabase.instance.client;

  Future<bool> hasInternet() async {
    final res = await Connectivity().checkConnectivity();
    return res != ConnectivityResult.none;
  }

  // 1) Login anónimo si hace falta
  Future<void> signInAnonymousIfNeeded() async {
    final session = _sb.auth.currentSession;
    if (session != null) return;
    await _sb.auth.signInAnonymously();
  }

  // 2) Crear/asegurar perfil (id = auth.uid)
  Future<void> ensureProfile({required String name, required String token}) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw Exception('No auth user');

    // Upsert por PK (id)
    await _sb.from('profiles').upsert({
      'id': uid,
      'name': name,
      'token': token,
    });
  }

  // 3) Subir una nota local a la nube (owner = auth.uid)
  Future<void> pushLocalNote(Note note) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw Exception('No auth user');

    await _sb.from('notes').upsert({
      'id': note.id, // IMPORTANTE: que tu Note.id sea UUID también
      'owner_id': uid,
      'title': note.title,
      'content': note.content,
      'color_value': note.colorValue,
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    });
  }

  // 4) Bajar mis notas (por si cambias en otro dispositivo)
  Future<List<Note>> pullMyNotes() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw Exception('No auth user');

    final rows = await _sb
        .from('notes')
        .select()
        .eq('owner_id', uid)
        .order('updated_at', ascending: false);

    return (rows as List).map((r) {
      final m = Map<String, dynamic>.from(r);
      return Note(
        id: m['id'] as String,
        title: m['title'] as String,
        content: (m['content'] as String?) ?? '',
        colorValue: (m['color_value'] as int?) ?? 0,
        createdAt: DateTime.parse(m['updated_at'] as String), // no guardamos created_at en nube (opcional)
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
    }).toList();
  }

  // 5) Bajar notas compartidas conmigo
  Future<List<Note>> pullSharedNotes() async {
  final uid = _sb.auth.currentUser?.id;
  if (uid == null) throw Exception('No auth user');

  final rows = await _sb
      .from('note_shares')
      .select('notes(id,title,content,color_value,updated_at)')
      .eq('shared_with', uid);

  final notes = <Note>[];

  for (final r in (rows as List)) {
    final m = (r as Map<String, dynamic>)['notes'];
    if (m == null) continue;

    final n = Map<String, dynamic>.from(m as Map);

    notes.add(
      Note(
        id: n['id'] as String,
        title: n['title'] as String,
        content: (n['content'] as String?) ?? '',
        colorValue: (n['color_value'] as int?) ?? 0,
        createdAt: DateTime.parse(n['updated_at'] as String),
        updatedAt: DateTime.parse(n['updated_at'] as String),
      ),
    );
  }

  notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return notes;
}

  // 6) Compartir por token
Future<void> shareNoteByToken({required String noteId, required String token}) async {
  final uid = _sb.auth.currentUser?.id;
  if (uid == null) throw Exception('No auth user');

  // 1) Buscar usuario destino por token (RPC)
  final res = await _sb.rpc('find_profile_by_token', params: {'p_token': token});
  final list = (res as List);
  if (list.isEmpty) throw Exception('Token no encontrado');
  final targetId = (list.first as Map)['id'] as String;

  if (targetId == uid) {
    throw Exception('No puedes compartirte una nota a ti mismo.');
  }

  // 2) Asegurar que la nota exista en nube y sea del owner actual
  final noteRow = await _sb
      .from('notes')
      .select('id, owner_id')
      .eq('id', noteId)
      .maybeSingle();

  if (noteRow == null) {
    throw Exception('Esa nota no está sincronizada aún. Haz Sync primero.');
  }
  if (noteRow['owner_id'] != uid) {
    throw Exception('No eres dueño de esa nota (no se puede compartir).');
  }

  // 3) Insert share (si ya existe, mostramos mensaje amigable)
  try {
    await _sb.from('note_shares').insert({
      'note_id': noteId,
      'shared_with': targetId,
    });
  } on PostgrestException catch (e) {
    // 23505 = unique_violation (PK compuesta note_id + shared_with)
    if (e.code == '23505') {
      throw Exception('Esa nota ya estaba compartida con ese token.');
    }
    // 42501 = RLS
    if (e.code == '42501') {
      throw Exception('Bloqueado por seguridad (RLS). Revisa policies de note_shares.');
    }
    rethrow;
  }
}
    Future<void> deleteRemoteNote(String noteId) async {
      await _sb.from('notes').delete().eq('id', noteId);
    }
}