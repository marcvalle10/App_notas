📝 Notes App — Flutter + Supabase + Railway

Aplicación móvil desarrollada en Flutter para la creación, edición y sincronización de notas.
Incluye soporte para:

📌 Notas locales (offline-first)

☁ Sincronización en la nube

🤝 Compartir notas por token

🔒 Permisos de edición (solo lectura / editable)

🔄 Sincronización automática al recuperar conexión

La aplicación implementa una arquitectura híbrida:

Persistencia local con Hive

Backend REST desplegado en Railway

Autenticación con Supabase (Anonymous Auth)

📖 Descripción

Esta aplicación permite a los usuarios:

Crear y editar notas con colores personalizados.

Almacenar notas localmente (modo offline).

Sincronizar automáticamente con la nube cuando hay conexión.

Compartir notas mediante un token único.

Definir permisos de edición al compartir.

Visualizar notas compartidas con control de acceso.

Resolver conflictos con estrategia last-write-wins.

El sistema está diseñado bajo el enfoque offline-first, donde el almacenamiento local es prioritario y la nube actúa como sistema de sincronización.

🏗 Arquitectura General

La aplicación está organizada en las siguientes capas:

📂 lib/

main.dart → Inicialización de Hive y Supabase.

app.dart → Configuración global de la app.

models/ → Modelos de datos.

data/ → Acceso a datos (local + nube).

screens/ → Pantallas principales.

widgets/ → Componentes reutilizables.

utils/ → Constantes y utilidades.

⚙ Tecnologías Utilizadas
🖥 Frontend
Flutter

Versión: 3.x

Lenguaje: Dart

Framework multiplataforma para desarrollo móvil.

Dart

Versión: 3.x

Lenguaje principal de la aplicación.

💾 Persistencia Local
Hive

Versión: ^2.x

Base de datos NoSQL ligera para Flutter.

Utilizada para almacenamiento offline.

Permite guardar:

Notas propias

Notas compartidas

Registros de eliminación pendientes

🌐 Backend
Railway

Plataforma de despliegue del backend REST.

Maneja:

CRUD de notas

Compartición por token

Control de permisos

Supabase

Versión: Supabase Flutter SDK ^2.x

Autenticación anónima.

Gestión de perfiles.

Validación de permisos desde backend.

📡 Conectividad
connectivity_plus

Detección de conexión a internet.

Activación automática de sincronización.

🎨 UI
Material 3

Diseño moderno.

Personalización con colores institucionales UNISON.

flutter_colorpicker

Selector avanzado de color para notas.

🔄 Funcionamiento de Sincronización

La aplicación sigue este flujo:

Detecta conexión.

Autentica sesión anónima (Supabase).

Asegura perfil de usuario.

Procesa eliminaciones pendientes.

Sincroniza notas locales → nube.

Descarga notas actualizadas.

Descarga notas compartidas con permisos.

Actualiza almacenamiento local.

Estrategia de resolución de conflictos:

Last Write Wins basado en updatedAt.

🔐 Sistema de Compartición

Cada usuario posee un:

Nombre

Token único (UUID)

Para compartir:

Se introduce el token del destinatario.

Se selecciona la nota.

Se define si puede editar o solo leer.

Las notas compartidas:

Se muestran en pestaña independiente.

Respetan permisos enviados por backend.

Permiten edición solo si canEdit = true.

📱 Imágenes de la Aplicación

<img width="720" height="1544" alt="image" src="https://github.com/user-attachments/assets/d1df24e1-53dd-4fef-972b-2c4462a534c8" />

<img width="720" height="1544" alt="image" src="https://github.com/user-attachments/assets/21bd7df8-7ae6-4467-ae36-179497f303c6" />

<img width="720" height="1544" alt="image" src="https://github.com/user-attachments/assets/1d875580-e775-44cf-b722-916ae0ecd231" />

<img width="720" height="1544" alt="image" src="https://github.com/user-attachments/assets/49a09407-62f1-4f7a-a622-4addf0d7e392" />

<img width="720" height="1544" alt="image" src="https://github.com/user-attachments/assets/57732142-093c-4451-9768-c8909d6649d9" />

<img width="720" height="1544" alt="image" src="https://github.com/user-attachments/assets/c24d17b5-9db8-47a2-83e0-fc78fbfb7224" />

<img width="720" height="1544" alt="image" src="https://github.com/user-attachments/assets/795809c5-a0e5-4b8d-9648-b51c437af3e9" />

<img width="720" height="1544" alt="image" src="https://github.com/user-attachments/assets/155e1493-dff5-488f-a24a-edc48917ace3" />


Lista de Notas

Crear / Editar Nota

Nota Compartida

🚀 Cómo Ejecutar el Proyecto
flutter pub get
flutter run


Para compilar APK:

flutter build apk --release

📦 Estructura del Proyecto
lib/
 ├── main.dart
 ├── app.dart
 ├── models/
 ├── data/
 ├── screens/
 ├── widgets/
 └── utils/

📌 Características Técnicas Destacadas

Arquitectura offline-first.

Sincronización automática con debounce.

Control de permisos en notas compartidas.

Manejo de estados de conectividad.

Eliminaciones diferidas con tombstones.

UI responsiva y minimalista.

📄 Licencia

Este proyecto fue desarrollado con fines académicos.
Puede ser modificado y adaptado según necesidades del curso o proyecto.
