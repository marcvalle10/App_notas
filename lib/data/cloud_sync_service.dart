import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/note.dart';
import 'api_client.dart';

class SharedNoteItem {
  final Note note;
  final bool canEdit;
  const SharedNoteItem({required this.note, required this.canEdit});
}

class CloudSyncService {
  final SupabaseClient _sb = Supabase.instance.client;
  final ApiClient _api = ApiClient();

  Future<bool> hasInternet() async {
    final res = await Connectivity().checkConnectivity();
    return res != ConnectivityResult.none;
  }

  // Auth se queda directo con Supabase (cliente)
  Future<void> signInAnonymousIfNeeded() async {
    final session = _sb.auth.currentSession;
    if (session != null) return;
    await _sb.auth.signInAnonymously();
  }

  // Perfil -> ahora via Railway
  Future<void> ensureProfile({
    required String name,
    required String token,
  }) async {
    await _api.postJson('/profile', {'name': name, 'token': token});
  }

  // Subir nota local -> via Railway
  Future<void> pushLocalNote(Note note) async {
    await _api.postJson('/notes', {
      'id': note.id,
      'title': note.title,
      'content': note.content,
      'color_value': note.colorValue,
      //'updated_at': note.updatedAt.toUtc().toIso8601String(),
    });
  }

  // Bajar mis notas -> via Railway
  Future<List<Note>> pullMyNotes() async {
    final data = await _api.getJson('/notes');
    final list = (data['notes'] as List?) ?? [];

    return list.map((r) {
      final m = Map<String, dynamic>.from(r as Map);

      final updated = DateTime.parse(m['updated_at'] as String);

      return Note(
        id: m['id'] as String,
        title: (m['title'] as String?) ?? '',
        content: (m['content'] as String?) ?? '',
        colorValue: (m['color_value'] as int?) ?? 0,
        createdAt: updated,
        updatedAt: updated,
      );
    }).toList();
  }

  // Solo notas compartidas
  Future<List<Note>> pullSharedNotes() async {
    final items = await pullSharedNotesWithPerms();
    return items.map((e) => e.note).toList();
  }

  // Compartidas + permisos -> via Railway
  Future<List<SharedNoteItem>> pullSharedNotesWithPerms() async {
    final data = await _api.getJson('/shared');
    final list = (data['items'] as List?) ?? [];

    final items = <SharedNoteItem>[];

    for (final raw in list) {
      final row = Map<String, dynamic>.from(raw as Map);
      final canEdit = (row['can_edit'] as bool?) ?? false;

      final noteMap = row['notes'];
      if (noteMap == null) continue;

      final m = Map<String, dynamic>.from(noteMap as Map);
      final updated = DateTime.parse(m['updated_at'] as String);

      items.add(
        SharedNoteItem(
          canEdit: canEdit,
          note: Note(
            id: m['id'] as String,
            title: (m['title'] as String?) ?? '',
            content: (m['content'] as String?) ?? '',
            colorValue: (m['color_value'] as int?) ?? 0,
            createdAt: updated,
            updatedAt: updated,
          ),
        ),
      );
    }

    items.sort((a, b) => b.note.updatedAt.compareTo(a.note.updatedAt));
    return items;
  }

  // Compartir por token -> via Railway
  Future<void> shareNoteByToken({
    required String noteId,
    required String token,
    required bool canEdit,
  }) async {
    await _api.postJson('/share', {
      'note_id': noteId,
      'token': token,
      'can_edit': canEdit,
    });
  }

  // Editar nota (incluye compartidas si tu backend lo permite) -> via Railway
  Future<void> updateSharedNote({
    required String noteId,
    required String title,
    required String content,
    required int colorValue,
  }) async {
    await _api.putJson('/notes/$noteId', {
      'title': title,
      'content': content,
      'color_value': colorValue,
    });
  }

  Future<void> deleteRemoteNote(String noteId) async {
    await _api.deleteJson('/notes/$noteId');
  }
}
