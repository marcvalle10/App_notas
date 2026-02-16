import 'package:flutter/material.dart';

class AppColors {
  // UNISON recomendados
  static const Color azulUnison = Color.fromARGB(255, 8, 86, 158);
  static const Color azulOscuroUnison = Color.fromARGB(255, 7, 83, 146);
  static const Color doradoUnison = Color(0xFFF8BB00);
  static const Color doradoOscuroUnison = Color(0xFFD99E30);

  // Fondo azul marino (más oscuro que el azul UNISON)
  static const Color azulMarino = Color.fromARGB(255, 4, 56, 114);
}
/// Similar a noteColors[] en tu React.
const kNoteColorValues = <int>[
  0xFFB3E5FC, // azul claro
  0xFFC8E6C9, // verde claro
  0xFFFFCDD2, // rojo/rosa claro
  0xFFFFF9C4, // amarillo claro
  0xFFD1C4E9, // morado claro
  0xFFFFE0B2, // naranja claro
  0xFFCFD8DC, // gris azulado claro
];

const int kDefaultColorValue = 0xFFFFF3B0;

const String kUserNameKey = 'USER_NAME_KEY';
const String kUserTokenKey = 'USER_TOKEN_KEY';