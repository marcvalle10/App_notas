import 'package:flutter/material.dart';
import '../models/note.dart';
import '../utils/date_format.dart';

class NoteViewScreen extends StatelessWidget {
  final Note note;
  const NoteViewScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
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
            ],
          ),
        ),
      ),
    );
  }
}