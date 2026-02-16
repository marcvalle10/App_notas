import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _name;
  String? _token;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString(kUserNameKey);

    // Token estilo C: UUID largo
    var token = prefs.getString(kUserTokenKey);
    if (token == null || token.isEmpty) {
      token = const Uuid().v4();
      await prefs.setString(kUserTokenKey, token);
    }

    if (!mounted) return;
    setState(() {
      _name = name;
      _token = token;
    });
  }

  Future<void> _ensureToken(SharedPreferences prefs) async {
    final existing = prefs.getString(kUserTokenKey);
    if (existing == null || existing.isEmpty) {
      await prefs.setString(kUserTokenKey, const Uuid().v4());
    }
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
      await _ensureToken(prefs);
      await _loadUserData();
    }
  }

  Future<void> _copyToken() async {
    final token = _token;
    if (token == null || token.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Token copiado ✅')),
    );
  }

  void _goNotes() {
    Navigator.pushNamed(context, '/notes');
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (_name == null || _name!.isEmpty) ? null : _name;

    return GestureDetector(
      onTap: _goNotes, // “presiona en cualquier lado”
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
                  displayName == null
                      ? 'Hola 👋 (toca "Cambiar nombre")'
                      : 'Hola, $displayName 👋',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),

                // TOKEN debajo del nombre
                const SizedBox(height: 8),
                if (_token != null)
                  Text(
                    '#$_token',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),

                const SizedBox(height: 14),

                // Botones (evitamos que el tap general navegue)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          // Evita que el tap del GestureDetector navegue
                          await _changeName();
                        },
                        child: const Text('Cambiar nombre'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await _copyToken();
                        },
                        child: const Text('Copiar token'),
                      ),
                    ),
                  ],
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