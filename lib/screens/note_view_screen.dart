import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/cloud_sync_service.dart';
import '../models/note.dart';
import '../utils/constants.dart';
import '../utils/date_format.dart';

class NoteViewScreen extends StatefulWidget {
  final Note note;
  final bool isShared;

  const NoteViewScreen({
    super.key,
    required this.note,
    required this.isShared,
  });

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  final _cloud = CloudSyncService();
  bool _sharing = false;

  Future<Map<String, String>> _getNameAndToken() async {
    final prefs = await SharedPreferences.getInstance();
    final name = (prefs.getString(kUserNameKey) ?? '').trim();
    final token = (prefs.getString(kUserTokenKey) ?? '').trim();
    return {'name': name, 'token': token};
  }

  Future<void> _shareByToken() async {
    final controller = TextEditingController();

    final token = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Compartir por token'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Pega el token del otro usuario (UUID)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Compartir'),
          ),
        ],
      ),
    );

    if (token == null || token.isEmpty) return;

    setState(() => _sharing = true);
    try {
      await _cloud.signInAnonymousIfNeeded();

      // asegura profile antes de compartir
      final me = await _getNameAndToken();
      await _cloud.ensureProfile(
        name: me['name']!.isEmpty ? 'Usuario' : me['name']!,
        token: me['token']!.isEmpty ? 'NO_TOKEN' : me['token']!,
      );

      await _cloud.shareNoteByToken(noteId: widget.note.id, token: token);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compartida ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo compartir: $e')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle'),
        actions: [
          if (!widget.isShared)
            IconButton(
              tooltip: 'Compartir',
              onPressed: _sharing ? null : _shareByToken,
              icon: _sharing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share),
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
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 20),
                Text(
                  'Nota compartida (solo lectura)',
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