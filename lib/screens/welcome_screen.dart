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

    // Token estilo UUID largo
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
      behavior: HitTestBehavior.opaque,
      onTap: _goNotes, // “toca en cualquier lado”
      child: Scaffold(
        backgroundColor: AppColors.azulMarino, // <-- azul marino
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // LOGO UNISON
                Image.asset(
                  'assets/images/ESCUDO-COLOR.png',
                  height: 140,
                ),

                const SizedBox(height: 18),

                // NOMBRE APP
                const Text(
                  'UniNotas UNISON',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                // AUTORES (equipo)
                const Text(
                  'Casas Gastelum Ana Cecilia\n'
                  'Murillo Monge Joshua David\n'
                  'Vallejo Leyva Marcos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 18),

                // SALUDO
                Text(
                  displayName == null
                      ? 'Hola 👋 (toca "Cambiar nombre")'
                      : 'Hola, $displayName 👋',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),

                // TOKEN
                const SizedBox(height: 8),
                if (_token != null)
                  Text(
                    '#$_token',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),

                const SizedBox(height: 14),

                // BOTONES
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.doradoUnison,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: _changeName,
                        child: const Text('Cambiar nombre'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        onPressed: _copyToken,
                        child: const Text('Copiar token'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // SOLO esto (sin botón iniciar)
                const Text(
                  'Toca en cualquier parte para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
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