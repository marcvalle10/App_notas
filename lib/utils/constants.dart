import 'package:flutter/material.dart';

class AppColors {
  // UNISON recomendados
  static const Color azulUnison = Color.fromARGB(255, 8, 86, 158);
  static const Color azulOscuroUnison = Color.fromARGB(255, 19, 124, 210);
  static const Color doradoUnison = Color(0xFFF8BB00);
  static const Color doradoOscuroUnison = Color(0xFFD99E30);

  // Fondo azul marino (más oscuro que el azul UNISON)
  static const Color azulMarino = Color.fromARGB(255, 18, 87, 165);
}
/// Similar a noteColors[] en tu React.
const List<int> kNoteColorValues = [
  0xFFFFF3B0, // amarillo suave
  0xFFD6F5D6, // verde suave
  0xFFD6E4FF, // azul suave
  0xFFFFD6E7, // rosa suave
];

const int kDefaultColorValue = 0xFFFFF3B0;

const String kUserNameKey = 'USER_NAME_KEY'; // como tu USER_NAME_KEY
const String kUserTokenKey = 'USER_TOKEN_KEY';