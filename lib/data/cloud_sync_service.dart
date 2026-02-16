import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/note.dart';

class SharedNoteItem {
  final Note note;
  final bool canEdit;
  const SharedNoteItem({required this.note, required this.canEdit});
}

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
      'id': note.id,
      'owner_id': uid,
      'title': note.title,
      'content': note.content,
      'color_value': note.colorValue,
      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    });
  }

  // 4) Bajar mis notas
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
        createdAt: DateTime.parse(m['updated_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );
    }).toList();
  }

  // 5) Bajar notas compartidas conmigo (solo notas)
  Future<List<Note>> pullSharedNotes() async {
    final items = await pullSharedNotesWithPerms();
    return items.map((e) => e.note).toList();
  }

  // 5b) Bajar notas compartidas conmigo + permiso (can_edit)
  Future<List<SharedNoteItem>> pullSharedNotesWithPerms() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw Exception('No auth user');

    final rows = await _sb
        .from('note_shares')
        .select('can_edit, notes(id,title,content,color_value,updated_at)')
        .eq('shared_with', uid);

    final items = <SharedNoteItem>[];

    for (final r in (rows as List)) {
      final row = Map<String, dynamic>.from(r as Map);
      final canEdit = (row['can_edit'] as bool?) ?? false;
      final noteMap = row['notes'];
      if (noteMap == null) continue;

      final m = Map<String, dynamic>.from(noteMap as Map);
      items.add(
        SharedNoteItem(
          canEdit: canEdit,
          note: Note(
            id: m['id'] as String,
            title: m['title'] as String,
            content: (m['content'] as String?) ?? '',
            colorValue: (m['color_value'] as int?) ?? 0,
            createdAt: DateTime.parse(m['updated_at'] as String),
            updatedAt: DateTime.parse(m['updated_at'] as String),
          ),
        ),
      );
    }

    items.sort((a, b) => b.note.updatedAt.compareTo(a.note.updatedAt));
    return items;
  }

  // 6) Compartir por token (con canEdit)
  Future<void> shareNoteByToken({
    required String noteId,
    required String token,
    required bool canEdit,
  }) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw Exception('No auth user');

    final res = await _sb.rpc('find_profile_by_token', params: {'p_token': token});
    final list = (res as List);
    if (list.isEmpty) throw Exception('Token no encontrado');
    final targetId = (list.first as Map)['id'] as String;

    if (targetId == uid) {
      throw Exception('No puedes compartirte una nota a ti mismo.');
    }

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

    try {
      await _sb.from('note_shares').insert({
        'note_id': noteId,
        'shared_with': targetId,
        'can_edit': canEdit,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw Exception('Esa nota ya estaba compartida con ese token.');
      }
      if (e.code == '42501') {
        throw Exception('Bloqueado por seguridad (RLS). Revisa policies de note_shares.');
      }
      rethrow;
    }
  }

  // 7) Actualizar una nota (para ediciones de compartidas con permiso)
  Future<void> updateSharedNote({
    required String noteId,
    required String title,
    required String content,
    required int colorValue,
  }) async {
    await _sb.from('notes').update({
      'title': title,
      'content': content,
      'color_value': colorValue,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', noteId);
  }

  Future<void> deleteRemoteNote(String noteId) async {
    await _sb.from('notes').delete().eq('id', noteId);
  }
}