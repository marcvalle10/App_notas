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

    // Primero trae ids de notas compartidas
    final shares = await _sb
        .from('note_shares')
        .select('note_id')
        .eq('shared_with', uid);

    final ids = (shares as List).map((e) => (e as Map)['note_id'] as String).toList();
    if (ids.isEmpty) return [];

    final rows = await _sb.from('notes').select().inFilter('id', ids);

    return (rows as List).map((r) {
      final m = Map<String, dynamic>.from(r);
      return Note(
        id: m['id'] as String,
        title: m['title'] as String,
        content: (m['content'] as String?) ?? '',
        colorValue: (m['color_value'] as int?) ?? 0,
        createdAt: DateTime.parse(m['updated_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
    }).toList();
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

    // 3) Insert share
    await _sb.from('note_shares').upsert({
      'note_id': noteId,
      'shared_with': targetId,
    });
  }
    Future<void> deleteRemoteNote(String noteId) async {
      await _sb.from('notes').delete().eq('id', noteId);
    }
}