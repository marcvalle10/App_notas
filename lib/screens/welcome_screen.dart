import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _name;

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _name = prefs.getString(kUserNameKey));
  }

  Future<void> _changeName() async {
    final controller = TextEditingController(text: _name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cambiar nombre'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Escribe tu nombre',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kUserNameKey, result);
      setState(() => _name = result);
    }
  }

  void _goNotes() {
    Navigator.pushNamed(context, '/notes');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _goNotes, // como tu “presiona en cualquier lado”
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Icon(Icons.note_alt, size: 90),
                const SizedBox(height: 12),
                const Text(
                  'App de Notas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _name == null || _name!.isEmpty
                      ? 'Hola 👋 (toca "Cambiar nombre")'
                      : 'Hola, $_name 👋',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _changeName,
                  child: const Text('Cambiar nombre'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Toca en cualquier parte para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}