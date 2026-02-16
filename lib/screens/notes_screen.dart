import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/notes_repo.dart';
import '../data/cloud_sync_service.dart';
import '../models/note.dart';
import '../utils/constants.dart';

import 'note_form_screen.dart';
import 'note_view_screen.dart';
import '../widgets/note_card.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  final _repo = NotesRepo();
  final _cloud = CloudSyncService();

  List<Note> _notes = [];
  List<Note> _shared = [];
  String _query = '';

  bool _isOnline = false;
  bool _isSyncing = false;

  StreamSubscription? _connSub;
  Timer? _autoSyncDebounce;

  late final TabController _tabs = TabController(length: 2, vsync: this);

 @override
  void initState() {
    super.initState();

    _tabs.addListener(() {
      if (mounted) setState(() {});
    });

    _load();
    _listenConnectivity();
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _autoSyncDebounce?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final notes = await _repo.getAll();
    final shared = await _repo.getShared();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _shared = shared;
    });
  }

  void _listenConnectivity() async {
    // estado inicial
    final initial = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() => _isOnline = initial != ConnectivityResult.none);

    _connSub = Connectivity().onConnectivityChanged.listen((res) {
      final online = res != ConnectivityResult.none;
      if (!mounted) return;
      setState(() => _isOnline = online);

      // Si vuelve internet, intenta sync silenciosa
      if (online) _scheduleAutoSync();
    });
  }

  void _scheduleAutoSync() {
    _autoSyncDebounce?.cancel();
    _autoSyncDebounce = Timer(const Duration(milliseconds: 600), () {
      _syncNow(showSnackbars: false);
    });
  }

  List<Note> _applyQuery(List<Note> list) {
    if (_query.trim().isEmpty) return list;
    final q = _query.toLowerCase();
    return list.where((n) {
      return n.title.toLowerCase().contains(q) || n.content.toLowerCase().contains(q);
    }).toList();
  }

  Future<Map<String, String>> _getNameAndToken() async {
    final prefs = await SharedPreferences.getInstance();
    final name = (prefs.getString(kUserNameKey) ?? '').trim();
    final token = (prefs.getString(kUserTokenKey) ?? '').trim();
    return {'name': name, 'token': token};
  }

  Future<void> _syncNow({required bool showSnackbars}) async {
    if (_isSyncing) return;

    // Regla offline-first: si no hay internet, no truena nada
    if (!_isOnline) {
      if (showSnackbars && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin internet: trabajando en modo offline.')),
        );
      }
      return;
    }

    setState(() => _isSyncing = true);

    try {
      await _cloud.signInAnonymousIfNeeded();

      final user = await _getNameAndToken();
      // Asegura profile para que sharing por token funcione
      await _cloud.ensureProfile(
        name: user['name']!.isEmpty ? 'Usuario' : user['name']!,
        token: user['token']!.isEmpty ? 'NO_TOKEN' : user['token']!,
      );

      // 1) Procesa eliminados (tombstones)
      final deletedIds = await _repo.getDeletedIds();
      for (final id in deletedIds) {
        try {
          await _cloud.deleteRemoteNote(id);
        } catch (_) {
          // si falla uno, no rompemos todo; seguirá en la cola
        }
      }
      // si no explotó, limpias cola (en la práctica, lo ideal sería limpiar solo los borrados ok)
      await _repo.clearDeletedIds();

      // 2) Push local
      final local = await _repo.getAll();
      for (final n in local) {
        await _cloud.pushLocalNote(n);
      }

      // 3) Pull my notes + merge (last-write-wins por updatedAt)
      final cloudMine = await _cloud.pullMyNotes();
      final merged = _mergeLastWriteWins(local, cloudMine);
      await _repo.saveAll(merged);

      // 4) Pull shared
      final cloudShared = await _cloud.pullSharedNotes();
      await _repo.saveShared(cloudShared);

      await _load();

      if (showSnackbars && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronización completada ✅')),
        );
      }
    } catch (e) {
      if (showSnackbars && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync falló: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  List<Note> _mergeLastWriteWins(List<Note> a, List<Note> b) {
    final map = <String, Note>{};

    for (final n in a) {
      map[n.id] = n;
    }
    for (final n in b) {
      final existing = map[n.id];
      if (existing == null) {
        map[n.id] = n;
      } else {
        // el más nuevo gana
        map[n.id] = (n.updatedAt.isAfter(existing.updatedAt)) ? n : existing;
      }
    }

    final merged = map.values.toList();
    merged.sort((x, y) => y.updatedAt.compareTo(x.updatedAt));
    return merged;
  }

  Future<void> _confirmDeleteMine(Note note) async {
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
      await _repo.delete(note.id, trackRemote: true);
      await _load();
      _scheduleAutoSync(); // auto sync silenciosa
    }
  }

  Future<void> _hideShared(Note note) async {
    // solo lo ocultamos localmente (no podemos borrar en nube)
    await _repo.hideSharedLocally(note.id);
    await _load();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota compartida ocultada (solo en tu dispositivo).')),
    );
  }

  Future<void> _openCreate() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const NoteFormScreen()),
    );
    if (changed == true) {
      await _load();
      _scheduleAutoSync();
    }
  }

  Future<void> _openEdit(Note note) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => NoteFormScreen(editing: note)),
    );
    if (changed == true) {
      await _load();
      _scheduleAutoSync();
    }
  }

  void _openView(Note note, {required bool isShared}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteViewScreen(note: note, isShared: isShared),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mine = _applyQuery(_notes);
    final shared = _applyQuery(_shared);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Notas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // indicador online/offline
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(_isOnline ? 'Online' : 'Offline', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Sincronizar',
            onPressed: _isSyncing ? null : () => _syncNow(showSnackbars: true),
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Mis notas'),
            Tab(text: 'Compartidas'),
          ],
        ),
      ),
      floatingActionButton: _tabs.index == 0
    ? FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      )
    : FloatingActionButton.extended(
        onPressed: _isSyncing ? null : () => _syncNow(showSnackbars: true),
        icon: _isSyncing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.sync),
        label: const Text('Sync'),
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
              child: TabBarView(
                controller: _tabs,
                children: [
                  // --- Mis notas ---
                  mine.isEmpty
                      ? const Center(child: Text('No hay notas aún.'))
                      : ListView.separated(
                          itemCount: mine.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final note = mine[i];
                            return Dismissible(
                              key: ValueKey('mine-${note.id}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                await _confirmDeleteMine(note);
                                return false; // no auto borra visualmente
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
                                onTap: () => _openView(note, isShared: false),
                                onEdit: () => _openEdit(note),
                              ),
                            );
                          },
                        ),

                  // --- Compartidas ---
                  shared.isEmpty
                      ? const Center(child: Text('No hay notas compartidas.'))
                      : ListView.separated(
                          itemCount: shared.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final note = shared[i];
                            return Dismissible(
                              key: ValueKey('shared-${note.id}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                await _hideShared(note);
                                return false;
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 18),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade400,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.visibility_off, color: Colors.white),
                              ),
                              child: NoteCard(
                                note: note,
                                isShared: true,
                                onTap: () => _openView(note, isShared: true),
                                onEdit: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No puedes editar notas compartidas.')),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}