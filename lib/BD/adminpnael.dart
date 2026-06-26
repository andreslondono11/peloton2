// import 'dart:io';

// import 'package:archive/archive_io.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:restart_app/restart_app.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite/sqflite.dart';
// import '../BD/db_manager.dart';
// import '../provider/tema.dart';

// class AdminPanel extends StatefulWidget {
//   const AdminPanel({super.key});

//   @override
//   State<AdminPanel> createState() => _AdminPanelState();
// }

// class _AdminPanelState extends State<AdminPanel> {
//   List<Map<String, dynamic>> _usuarios = [];

//   @override
//   void initState() {
//     super.initState();
//     _cargarUsuarios();
//   }

//   // ✅ CORREGIDO: Usar authDatabase (tablet_app.db) donde están los usuarios
//   Future<void> _cargarUsuarios() async {
//     final db = await DBManager.instance.authDatabase;
//     final res = await db.query('usuarios', orderBy: 'nombres ASC');
//     setState(() => _usuarios = res);
//   }

//   // ✅ CORREGIDO: Usar authDatabase para actualizar usuarios
//   Future<void> _actualizarDato(int id, String campo, dynamic valor) async {
//     final db = await DBManager.instance.authDatabase;
//     await db.update(
//       'usuarios',
//       {campo: valor},
//       where: 'id = ?',
//       whereArgs: [id],
//     );
//     _cargarUsuarios();
//   }

//   // ========================================================================
//   // NUEVA FUNCIÓN: Importar Usuario desde ZIP directamente al Admin
//   // ========================================================================
//   Future<void> _importarUsuarioDesdeZip() async {
//     try {
//       // 1. Abrir selector de archivos
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['zip'],
//       );

//       if (result == null || result.files.single.path == null) return;

//       final zipFile = File(result.files.single.path!);
//       final tempDir = await getTemporaryDirectory();
//       final extractDir = Directory(p.join(tempDir.path, 'admin_import_work'));

//       // Limpiar y crear carpeta temporal
//       if (await extractDir.exists()) await extractDir.delete(recursive: true);
//       await extractDir.create(recursive: true);

//       // Mostrar cargando
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Descomprimiendo archivo..."),
//             duration: Duration(seconds: 5),
//           ),
//         );
//       }

//       // 2. Descomprimir ZIP
//       await extractArchiveToDisk(
//         ZipDecoder().decodeBuffer(InputFileStream(zipFile.path)),
//         extractDir.path,
//       );

//       final dbPath = await getDatabasesPath();
//       String? usuarioIdStr;
//       File? dbUsuarioFile;
//       File? dbGlobalFile; // <-- NUEVO: Para capturar la BD global si viene

//       // 3. Buscar bases de datos dentro del ZIP
//       final dbsDir = Directory(p.join(extractDir.path, 'DBS'));
//       List<Directory> dirsToSearch = [extractDir];
//       if (await dbsDir.exists()) dirsToSearch.add(dbsDir);

//       for (var dir in dirsToSearch) {
//         await for (var entity in dir.list(
//           recursive: true,
//           followLinks: false,
//         )) {
//           if (entity is File && entity.path.endsWith('.db')) {
//             final nombre = p.basename(entity.path);

//             // Capturar BD del usuario
//             if (nombre.startsWith('calipso_user_') && nombre.endsWith('.db')) {
//               usuarioIdStr = nombre
//                   .replaceAll('calipso_user_', '')
//                   .replaceAll('.db', '');
//               dbUsuarioFile = entity;
//             }
//             // Capturar BD global (tablet_app.db)
//             else if (nombre == 'tablet_app.db') {
//               dbGlobalFile = entity;
//             }
//           }
//         }
//         if (dbUsuarioFile != null) break;
//       }

//       if (dbUsuarioFile == null || usuarioIdStr == null) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                 "Error: No se encontró una base de usuario válida en el ZIP.",
//               ),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//         await extractDir.delete(recursive: true);
//         return;
//       }

//       final userId = int.tryParse(usuarioIdStr) ?? 0;

//       // 4. Copiar la BD del usuario a la carpeta oficial
//       final destinoPath = p.join(dbPath, 'calipso_user_$userId.db');
//       final archivoDestino = File(destinoPath);
//       if (await archivoDestino.exists()) await archivoDestino.delete();
//       await dbUsuarioFile.copy(destinoPath);

//       // ====================================================================
//       // NUEVO PASO CRÍTICO: Asegurar que el usuario exista en la BD Global
//       // ====================================================================
//       final globalDbPath = p.join(dbPath, 'tablet_app.db');
//       final globalDb = await openDatabase(globalDbPath);

//       // Opción A: Si el ZIP traía el tablet_app.db, lo copiamos y reemplazamos
//       if (dbGlobalFile != null) {
//         await globalDb.close(); // Cerramos para poder sobreescribir
//         final destGlobal = File(globalDbPath);
//         if (await destGlobal.exists()) await destGlobal.delete();
//         await dbGlobalFile.copy(globalDbPath);
//       }
//       // Opción B: Si el ZIP NO traía el global (ej. un respaldo básico),
//       // creamos un registro "fantasma" para que aparezca en la lista del Admin.
//       else {
//         final yaExiste = await globalDb.query(
//           'usuarios',
//           where: 'id = ?',
//           whereArgs: [userId],
//         );

//         if (yaExiste.isEmpty) {
//           await globalDb.insert('usuarios', {
//             'id': userId,
//             'nombres': 'Usuario Recuperado ID: $userId',
//             'correo': 'recuperado_$userId@importado.com',
//             'password':
//                 '1234', // Clave genérica por si quiere entrar normal después
//             'estado': 'activo',
//             'rol': 'usuario',
//           });
//         }
//         await globalDb.close();
//       }

//       // 5. Copiar medios si los hay
//       final mediosDir = Directory(p.join(extractDir.path, 'MEDIOS'));
//       if (await mediosDir.exists()) {
//         final docsDir = await getApplicationDocumentsDirectory();
//         await for (var entity in mediosDir.list(
//           recursive: true,
//           followLinks: false,
//         )) {
//           if (entity is File) {
//             final targetPath = p.join(
//               docsDir.path,
//               p.relative(entity.path, from: mediosDir.path),
//             );
//             await File(targetPath).parent.create(recursive: true);
//             await entity.copy(targetPath);
//           }
//         }
//       }

//       // Limpiar temporales
//       await extractDir.delete(recursive: true);

//       // 6. Refrescar la lista y preguntar qué hacer
//       if (mounted) {
//         _cargarUsuarios(); // <-- CLAVE: Refrescamos la lista aquí
//         _dialogoOpcionesUsuarioImportado(userId);
//       }
//     } catch (e) {
//       debugPrint("❌ Error importando usuario: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error al importar: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // ========================================================================
//   // DIÁLOGO: Qué hacer con el usuario importado
//   // ========================================================================
//   void _dialogoOpcionesUsuarioImportado(int userId) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     showDialog(
//       context: context,
//       builder: (c) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         title: const Text("✅ Usuario Importado"),
//         content: Text(
//           "La base de datos del Usuario ID: $userId fue extraída correctamente.\n\n¿Qué desea hacer ahora?",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(c);
//               _cargarUsuarios(); // Refresca la lista por si ya estaba registrado
//             },
//             child: Text(
//               "SOLO GUARDAR EN SISTEMA",
//               style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
//             ),
//           ),
//           ElevatedButton.icon(
//             icon: const Icon(Icons.login, size: 18),
//             label: const Text("ENTRAR A ESTA CUENTA"),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               foregroundColor: Colors.white,
//             ),
//             onPressed: () async {
//               Navigator.pop(c);

//               // Secuestrar sesión
//               final prefs = await SharedPreferences.getInstance();
//               await prefs.setInt('last_logged_user_id', userId);
//               await prefs.setBool('mantener_sesion_activa', true);

//               final dbPath = await getDatabasesPath();
//               final globalDb = await openDatabase(
//                 p.join(dbPath, 'tablet_app.db'),
//               );
//               await globalDb.execute(
//                 'CREATE TABLE IF NOT EXISTS sesion_activa (id INTEGER PRIMARY KEY, usuario_id INTEGER, mantener_sesion INTEGER DEFAULT 0, usar_huella INTEGER DEFAULT 0)',
//               );
//               await globalDb.execute(
//                 'REPLACE INTO sesion_activa (id, usuario_id, mantener_sesion, usar_huella) VALUES (1, $userId, 1, 0)',
//               );
//               await globalDb.close();

//               // Reiniciar limpio para cargar la nueva sesión
//               Restart.restartApp(webOrigin: "");
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _desactivarUsuario(int id, String nombre) async {
//     await _actualizarDato(id, 'estado', 'inactivo');
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Acceso desactivado para $nombre"),
//           backgroundColor: Colors.orange[900],
//         ),
//       );
//     }
//   }

//   // --- ESTILO GLOBAL PARA LOS DIÁLOGOS ---
//   AlertDialog _estiloDialog({
//     required Widget title,
//     required Widget content,
//     required List<Widget> actions,
//   }) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return AlertDialog(
//       backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//         side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
//       ),
//       titleTextStyle: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.bold,
//         color: isDark ? Colors.white : const Color(0xFF1C1FB7),
//       ),
//       contentTextStyle: TextStyle(
//         fontSize: 14,
//         color: isDark ? Colors.white70 : Colors.black87,
//       ),
//       title: title,
//       content: content,
//       actions: actions,
//     );
//   }

//   // --- DIÁLOGOS ---

//   void _dialogoCambiarPinMaestro() {
//     final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
//     final controller = TextEditingController(text: themeProvider.adminPin);
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     showDialog(
//       context: context,
//       builder: (context) => _estiloDialog(
//         title: const Text("Configurar PIN Maestro"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "Clave de acceso administrativo (CALIPSO).",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: isDark ? Colors.white54 : Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 15),
//             TextField(
//               controller: controller,
//               keyboardType: TextInputType.number,
//               maxLength: 4,
//               textAlign: TextAlign.center,
//               obscureText: true,
//               style: TextStyle(
//                 letterSpacing: 10,
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: isDark ? Colors.white : Colors.black87,
//               ),
//               decoration: InputDecoration(
//                 hintText: "0000",
//                 hintStyle: TextStyle(
//                   color: isDark ? Colors.white24 : Colors.black26,
//                 ),
//                 border: const OutlineInputBorder(),
//                 enabledBorder: OutlineInputBorder(
//                   borderSide: BorderSide(
//                     color: isDark ? Colors.white24 : Colors.grey,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               "CANCELAR",
//               style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
//             ),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF1C1FB7),
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () async {
//               if (controller.text.length == 4) {
//                 await themeProvider.setAdminPin(controller.text);
//                 if (context.mounted) Navigator.pop(context);
//               }
//             },
//             child: const Text("GUARDAR"),
//           ),
//         ],
//       ),
//     );
//   }

//   void _dialogoCambiarNombre(int id, String nombreActual) {
//     final controller = TextEditingController(text: nombreActual);
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     showDialog(
//       context: context,
//       builder: (c) => _estiloDialog(
//         title: const Text("Cambiar Nombre"),
//         content: TextField(
//           controller: controller,
//           textCapitalization: TextCapitalization.words,
//           style: TextStyle(color: isDark ? Colors.white : Colors.black87),
//           decoration: InputDecoration(
//             hintText: "Escriba el nuevo nombre",
//             hintStyle: TextStyle(
//               color: isDark ? Colors.white24 : Colors.black26,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderSide: BorderSide(
//                 color: isDark ? Colors.white24 : Colors.grey,
//               ),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c),
//             child: Text(
//               "CANCELAR",
//               style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
//             ),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF1C1FB7),
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () {
//               final nuevoNombre = controller.text.trim();
//               if (nuevoNombre.isNotEmpty && nuevoNombre != nombreActual) {
//                 _actualizarDato(id, 'nombres', nuevoNombre);
//                 Navigator.pop(c);
//               }
//             },
//             child: const Text("GUARDAR"),
//           ),
//         ],
//       ),
//     );
//   }

//   void _dialogoCambiarCorreo(int id, String correoActual) {
//     final controller = TextEditingController(text: correoActual);
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     showDialog(
//       context: context,
//       builder: (c) => StatefulBuilder(
//         builder: (context, setDialogState) => _estiloDialog(
//           title: const Text("Cambiar Correo"),
//           content: TextField(
//             controller: controller,
//             keyboardType: TextInputType.emailAddress,
//             style: TextStyle(color: isDark ? Colors.white : Colors.black87),
//             decoration: InputDecoration(
//               hintText: "Escriba el nuevo correo",
//               hintStyle: TextStyle(
//                 color: isDark ? Colors.white24 : Colors.black26,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderSide: BorderSide(
//                   color: isDark ? Colors.white24 : Colors.grey,
//                 ),
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(c),
//               child: Text(
//                 "CANCELAR",
//                 style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
//               ),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF1C1FB7),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () async {
//                 final nuevoCorreo = controller.text.trim().toLowerCase();
//                 if (nuevoCorreo.isEmpty) return;
//                 if (nuevoCorreo == correoActual) {
//                   Navigator.pop(c);
//                   return;
//                 }

//                 // ✅ CORREGIDO: Usar authDatabase para verificar si existe
//                 final db = await DBManager.instance.authDatabase;
//                 final existe = await db.query(
//                   'usuarios',
//                   where: 'correo = ? AND id != ?',
//                   whereArgs: [nuevoCorreo, id],
//                 );

//                 if (existe.isNotEmpty) {
//                   if (c.mounted) {
//                     ScaffoldMessenger.of(c).showSnackBar(
//                       const SnackBar(
//                         content: Text(
//                           "Ese correo ya está registrado por otro usuario.",
//                         ),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 } else {
//                   _actualizarDato(id, 'correo', nuevoCorreo);
//                   if (c.mounted) Navigator.pop(c);
//                 }
//               },
//               child: const Text("GUARDAR"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _dialogoCambiarPassUsuario(int id, String nombre) {
//     final passController = TextEditingController();
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     showDialog(
//       context: context,
//       builder: (c) => _estiloDialog(
//         title: Text("Nueva clave: $nombre"),
//         content: TextField(
//           controller: passController,
//           style: TextStyle(color: isDark ? Colors.white : Colors.black87),
//           decoration: InputDecoration(
//             hintText: "Escriba la nueva contraseña",
//             hintStyle: TextStyle(
//               color: isDark ? Colors.white24 : Colors.black26,
//             ),
//             enabledBorder: OutlineInputBorder(
//               borderSide: BorderSide(
//                 color: isDark ? Colors.white24 : Colors.grey,
//               ),
//             ),
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c),
//             child: Text(
//               "CANCELAR",
//               style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
//             ),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF1C1FB7),
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () {
//               if (passController.text.isNotEmpty) {
//                 _actualizarDato(id, 'password', passController.text);
//                 Navigator.pop(c);
//               }
//             },
//             child: const Text("GUARDAR"),
//           ),
//         ],
//       ),
//     );
//   }

//   void _confirmarEliminar(int id) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     showDialog(
//       context: context,
//       builder: (c) => _estiloDialog(
//         title: const Text("¿Eliminar usuario?"),
//         content: const Text(
//           "Esta acción no se puede deshacer y se perderán los datos asociados.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(c),
//             child: Text(
//               "NO",
//               style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
//             ),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             onPressed: () async {
//               // ✅ CORREGIDO: Usar authDatabase para eliminar
//               final db = await DBManager.instance.authDatabase;
//               await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
//               _cargarUsuarios();
//               if (c.mounted) Navigator.pop(c);
//             },
//             child: const Text("SÍ, ELIMINAR"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "GESTIÓN ADMIN",
//           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//         ),
//         backgroundColor: isDark
//             ? Colors.black
//             : const Color.fromARGB(255, 28, 31, 183),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           _buildAdminHeader(isDark),
//           Expanded(
//             child: _usuarios.isEmpty
//                 ? const Center(child: Text("Sin registros de usuarios"))
//                 : ListView.builder(
//                     padding: const EdgeInsets.symmetric(horizontal: 15),
//                     itemCount: _usuarios.length,
//                     itemBuilder: (context, index) =>
//                         _itemUsuario(_usuarios[index], isDark),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAdminHeader(bool isDark) {
//     return Container(
//       margin: const EdgeInsets.all(15),
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: isDark ? const Color(0xFF161B22) : Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               const CircleAvatar(
//                 backgroundColor: Color(0xFFB71C1C),
//                 child: Icon(Icons.admin_panel_settings, color: Colors.white),
//               ),
//               const SizedBox(width: 15),
//               const Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       "Seguridad del Sistema",
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     Text(
//                       "Admin entra con PIN numérico",
//                       style: TextStyle(color: Colors.grey, fontSize: 12),
//                     ),
//                   ],
//                 ),
//               ),
//               ElevatedButton.icon(
//                 onPressed: _dialogoCambiarPinMaestro,
//                 icon: const Icon(Icons.vpn_key, size: 16),
//                 label: const Text("PIN"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blueGrey[800],
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           const Divider(height: 30),
//           // ---> NUEVO BOTÓN AQUÍ <---
//           SizedBox(
//             width: double.infinity,
//             height: 45,
//             child: ElevatedButton.icon(
//               onPressed: _importarUsuarioDesdeZip,
//               icon: const Icon(Icons.restore, size: 20),
//               label: const Text(
//                 "IMPORTAR USUARIO DESDE ZIP",
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepPurple,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _itemUsuario(Map<String, dynamic> user, bool isDark) {
//     bool isActive = (user['estado'] ?? 'activo') == 'activo';

//     return Card(
//       margin: const EdgeInsets.only(bottom: 8),
//       color: isDark ? const Color(0xFF161B22) : Colors.white,
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: isActive
//               ? Colors.blue.withOpacity(0.1)
//               : Colors.grey.withOpacity(0.1),
//           child: Icon(
//             isActive ? Icons.person : Icons.person_off,
//             color: isActive ? Colors.blue : Colors.grey,
//           ),
//         ),
//         title: Text(
//           user['nombres'],
//           style: const TextStyle(fontWeight: FontWeight.bold),
//         ),
//         subtitle: Text(
//           user['correo'],
//           style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: isActive
//                     ? Colors.green.withOpacity(0.1)
//                     : Colors.red.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 isActive ? "Activo" : "Bloqueado",
//                 style: TextStyle(
//                   fontSize: 11,
//                   color: isActive ? Colors.green : Colors.red,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(width: 8),
//             Switch(
//               value: isActive,
//               activeColor: Colors.green,
//               onChanged: (v) => _actualizarDato(
//                 user['id'],
//                 'estado',
//                 v ? 'activo' : 'inactivo',
//               ),
//             ),
//             PopupMenuButton(
//               onSelected: (val) {
//                 if (val == 'name')
//                   _dialogoCambiarNombre(user['id'], user['nombres']);
//                 if (val == 'email')
//                   _dialogoCambiarCorreo(user['id'], user['correo']);
//                 if (val == 'pass')
//                   _dialogoCambiarPassUsuario(user['id'], user['nombres']);
//                 if (val == 'off')
//                   _desactivarUsuario(user['id'], user['nombres']);
//                 if (val == 'del') _confirmarEliminar(user['id']);
//               },
//               itemBuilder: (context) => [
//                 const PopupMenuItem(
//                   value: 'name',
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.drive_file_rename_outline,
//                         color: Colors.blue,
//                         size: 18,
//                       ),
//                       SizedBox(width: 8),
//                       Text("Cambiar Nombre"),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'email',
//                   child: Row(
//                     children: [
//                       Icon(Icons.email_outlined, color: Colors.blue, size: 18),
//                       SizedBox(width: 8),
//                       Text("Cambiar Correo"),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'pass',
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.lock_outline,
//                         color: Colors.blueGrey,
//                         size: 18,
//                       ),
//                       SizedBox(width: 8),
//                       Text("Cambiar Contraseña"),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'off',
//                   child: Row(
//                     children: [
//                       Icon(
//                         Icons.power_settings_new,
//                         color: Colors.orange,
//                         size: 18,
//                       ),
//                       SizedBox(width: 8),
//                       Text(
//                         "Desconectar",
//                         style: TextStyle(color: Colors.orange),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const PopupMenuItem(
//                   value: 'del',
//                   child: Text("Eliminar", style: TextStyle(color: Colors.red)),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../BD/db_manager.dart';
import '../provider/tema.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  List<Map<String, dynamic>> _usuarios = [];
  bool _isImporting =
      false; // Variable para bloquear botones mientras se importa

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  Future<void> _cargarUsuarios() async {
    final db = await DBManager.instance.authDatabase;
    final res = await db.query('usuarios', orderBy: 'nombres ASC');
    if (mounted) setState(() => _usuarios = res);
  }

  Future<void> _actualizarDato(int id, String campo, dynamic valor) async {
    final db = await DBManager.instance.authDatabase;
    await db.update(
      'usuarios',
      {campo: valor},
      where: 'id = ?',
      whereArgs: [id],
    );
    _cargarUsuarios();
  }

  // ========================================================================
  // FUNCIÓN 1: Importar ZIP Viejo (Solo BD, busca en carpeta DBS)
  // ========================================================================
  Future<void> _importarUsuarioDesdeZip() async {
    if (_isImporting) return;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.single.path == null) return;

      final zipFile = File(result.files.single.path!);
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory(p.join(tempDir.path, 'admin_import_work'));

      if (await extractDir.exists()) await extractDir.delete(recursive: true);
      await extractDir.create(recursive: true);

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Descomprimiendo archivo...")),
        );

      await extractArchiveToDisk(
        ZipDecoder().decodeBuffer(InputFileStream(zipFile.path)),
        extractDir.path,
      );

      final dbPath = await getDatabasesPath();
      String? usuarioIdStr;
      File? dbUsuarioFile;
      File? dbGlobalFile;

      final dbsDir = Directory(p.join(extractDir.path, 'DBS'));
      List<Directory> dirsToSearch = [extractDir];
      if (await dbsDir.exists()) dirsToSearch.add(dbsDir);

      for (var dir in dirsToSearch) {
        await for (var entity in dir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File && entity.path.endsWith('.db')) {
            final nombre = p.basename(entity.path);
            if (nombre.startsWith('calipso_user_') && nombre.endsWith('.db')) {
              usuarioIdStr = nombre
                  .replaceAll('calipso_user_', '')
                  .replaceAll('.db', '');
              dbUsuarioFile = entity;
            } else if (nombre == 'tablet_app.db') {
              dbGlobalFile = entity;
            }
          }
        }
        if (dbUsuarioFile != null) break;
      }

      if (dbUsuarioFile == null || usuarioIdStr == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error: No se encontró BD de usuario."),
              backgroundColor: Colors.red,
            ),
          );
        await extractDir.delete(recursive: true);
        return;
      }

      final userId = int.tryParse(usuarioIdStr) ?? 0;
      final destinoPath = p.join(dbPath, 'calipso_user_$userId.db');
      final archivoDestino = File(destinoPath);
      if (await archivoDestino.exists()) await archivoDestino.delete();
      await dbUsuarioFile.copy(destinoPath);

      final globalDbPath = p.join(dbPath, 'tablet_app.db');
      final globalDb = await openDatabase(globalDbPath);

      if (dbGlobalFile != null) {
        await globalDb.close();
        final destGlobal = File(globalDbPath);
        if (await destGlobal.exists()) await destGlobal.delete();
        await dbGlobalFile.copy(globalDbPath);
      } else {
        final yaExiste = await globalDb.query(
          'usuarios',
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (yaExiste.isEmpty) {
          await globalDb.insert('usuarios', {
            'id': userId,
            'nombres': 'Usuario Recuperado ID: $userId',
            'correo': 'recuperado_$userId@importado.com',
            'password': '1234',
            'estado': 'activo',
            'rol': 'usuario',
          });
        }
        await globalDb.close();
      }

      // Copiar medios de la estructura vieja (MEDIOS)
      final mediosDir = Directory(p.join(extractDir.path, 'MEDIOS'));
      if (await mediosDir.exists()) {
        final docsDir = await getApplicationDocumentsDirectory();
        await for (var entity in mediosDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            final targetPath = p.join(
              docsDir.path,
              p.relative(entity.path, from: mediosDir.path),
            );
            await File(targetPath).parent.create(recursive: true);
            await entity.copy(targetPath);
          }
        }
      }

      await extractDir.delete(recursive: true);
      if (mounted) {
        _cargarUsuarios();
        _dialogoOpcionesUsuarioImportado(userId);
      }
    } catch (e) {
      debugPrint("❌ Error importando: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    }
  }

  // ========================================================================
  // FUNCIÓN 2: IMPORTAR RESPALDO COMPLETO (NUEVO: Repara rutas mágicamente)
  // ========================================================================
  Future<void> _importarRespaldoCompleto() async {
    if (_isImporting) return;
    setState(() => _isImporting = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.single.path == null) {
        setState(() => _isImporting = false);
        return;
      }

      final zipFile = File(result.files.single.path!);
      final tempDir = await getTemporaryDirectory();
      final extractDir = Directory(p.join(tempDir.path, 'admin_full_import'));

      if (await extractDir.exists()) await extractDir.delete(recursive: true);
      await extractDir.create(recursive: true);

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Descomprimiendo y reparando rutas de imágenes..."),
            duration: Duration(seconds: 3),
          ),
        );

      await extractArchiveToDisk(
        ZipDecoder().decodeBuffer(InputFileStream(zipFile.path)),
        extractDir.path,
      );

      final dbPath = await getDatabasesPath();
      final docsDir = await getApplicationDocumentsDirectory();
      final docsPath = docsDir.path;

      String? usuarioIdStr;
      File? dbUsuarioFile;

      // Buscar específicamente la BD que creamos en el respaldo completo
      await for (var entity in extractDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && entity.path.endsWith('.db')) {
          final nombre = p.basename(entity.path);
          if (nombre.startsWith('calipso_user_') && nombre.endsWith('.db')) {
            usuarioIdStr = nombre
                .replaceAll('calipso_user_', '')
                .replaceAll('.db', '');
            dbUsuarioFile = entity;
            break;
          }
        }
      }

      if (dbUsuarioFile == null || usuarioIdStr == null) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Error: Este ZIP no contiene una base de usuario válida.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        await extractDir.delete(recursive: true);
        setState(() => _isImporting = false);
        return;
      }

      final userId = int.tryParse(usuarioIdStr) ?? 0;

      // 1. Copiar BD a su lugar oficial
      final destinoPath = p.join(dbPath, 'calipso_user_$userId.db');
      if (await File(destinoPath).exists()) await File(destinoPath).delete();
      await dbUsuarioFile.copy(destinoPath);

      // 2. REPARAR RUTAS DE IMÁGENES EN LA BD PARA ESTE CELULAR
      final dbRecuperada = await openDatabase(destinoPath, readOnly: false);
      final columnasFoto = [
        {'tabla': 'inventario_armamento', 'columna': 'foto_patrimonio'},
        {'tabla': 'inventario_especial', 'columna': 'foto_path'},
        {'tabla': 'inventario_miras', 'columna': 'foto_path'},
        {'tabla': 'intendencia', 'columna': 'foto_path'},
        {'tabla': 'inteligencia', 'columna': 'imagen'},
        {'tabla': 'operacional', 'columna': 'imagen'},
        {'tabla': 'personal', 'columna': 'foto_path'},
      ];

      for (var item in columnasFoto) {
        try {
          final registros = await dbRecuperada.query(item['tabla']!);
          for (var reg in registros) {
            String? rutaActual = reg[item['columna']] as String?;
            // Si la ruta no empieza con "/", la limpiamos en el respaldo original
            if (rutaActual != null && !rutaActual.startsWith('/')) {
              // Le pegamos la ruta REAL y actual de este celular
              String rutaNueva = p.join(docsPath, rutaActual);
              await dbRecuperada.update(
                item['tabla']!,
                {item['columna']!: rutaNueva},
                where: 'id = ?',
                whereArgs: [reg['id']],
              );
            }
          }
        } catch (_) {}
      }
      await dbRecuperada.close();

      // 3. Copiar las imágenes aplanadas a la carpeta de Documentos de la app
      final archivosDir = Directory(p.join(extractDir.path, 'ARCHIVOS'));
      if (await archivosDir.exists()) {
        await for (var entity in archivosDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            final targetPath = p.join(docsPath, p.basename(entity.path));
            if (await File(targetPath).exists())
              await File(targetPath).delete();
            await entity.copy(targetPath);
          }
        }
      }

      // 4. Asegurar que exista en la tabla global
      final globalDbPath = p.join(dbPath, 'tablet_app.db');
      final globalDbTemp = await openDatabase(globalDbPath);
      final yaExiste = await globalDbTemp.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (yaExiste.isEmpty) {
        await globalDbTemp.insert('usuarios', {
          'id': userId,
          'nombres': 'Importado Completo ID: $userId',
          'correo': 'completo_$userId@importado.com',
          'password': '1234',
          'estado': 'activo',
          'rol': 'usuario',
        });
      }
      await globalDbTemp.close();

      // Limpiar temporales
      await extractDir.delete(recursive: true);

      if (mounted) {
        _cargarUsuarios();
        _dialogoOpcionesUsuarioImportado(userId);
      }
    } catch (e) {
      debugPrint("❌ Error importando completo: $e");
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  // ========================================================================
  // DIÁLOGO: Qué hacer con el usuario importado
  // ========================================================================
  void _dialogoOpcionesUsuarioImportado(int userId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("✅ Usuario Importado"),
        content: Text(
          "La base de datos del Usuario ID: $userId fue extraída y reparada correctamente.\n\n¿Qué desea hacer ahora?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _cargarUsuarios();
            },
            child: Text(
              "SOLO GUARDAR",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.login, size: 18),
            label: const Text("ENTRAR A ESTA CUENTA"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(c);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('last_logged_user_id', userId);
              await prefs.setBool('mantener_sesion_activa', true);

              final dbPath = await getDatabasesPath();
              final globalDb = await openDatabase(
                p.join(dbPath, 'tablet_app.db'),
              );
              await globalDb.execute(
                'CREATE TABLE IF NOT EXISTS sesion_activa (id INTEGER PRIMARY KEY, usuario_id INTEGER, mantener_sesion INTEGER DEFAULT 0, usar_huella INTEGER DEFAULT 0)',
              );
              await globalDb.execute(
                'REPLACE INTO sesion_activa (id, usuario_id, mantener_sesion, usar_huella) VALUES (1, $userId, 1, 0)',
              );
              await globalDb.close();

              Restart.restartApp(webOrigin: "");
            },
          ),
        ],
      ),
    );
  }

  Future<void> _desactivarUsuario(int id, String nombre) async {
    await _actualizarDato(id, 'estado', 'inactivo');
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Acceso desactivado para $nombre"),
          backgroundColor: Colors.orange[900],
        ),
      );
  }

  // --- ESTILO GLOBAL PARA LOS DIÁLOGOS ---
  AlertDialog _estiloDialog({
    required Widget title,
    required Widget content,
    required List<Widget> actions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
      ),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF1C1FB7),
      ),
      contentTextStyle: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
      title: title,
      content: content,
      actions: actions,
    );
  }

  // --- DIÁLOGOS ---
  void _dialogoCambiarPinMaestro() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final controller = TextEditingController(text: themeProvider.adminPin);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => _estiloDialog(
        title: const Text("Configurar PIN Maestro"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Clave de acceso administrativo (CALIPSO).",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              obscureText: true,
              style: TextStyle(
                letterSpacing: 10,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: "0000",
                hintStyle: TextStyle(
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark ? Colors.white24 : Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCELAR",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1FB7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              if (controller.text.length == 4) {
                await themeProvider.setAdminPin(controller.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  void _dialogoCambiarNombre(int id, String nombreActual) {
    final controller = TextEditingController(text: nombreActual);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (c) => _estiloDialog(
        title: const Text("Cambiar Nombre"),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "Escriba el nuevo nombre",
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(
              "CANCELAR",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1FB7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final n = controller.text.trim();
              if (n.isNotEmpty && n != nombreActual) {
                _actualizarDato(id, 'nombres', n);
                Navigator.pop(c);
              }
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  void _dialogoCambiarCorreo(int id, String correoActual) {
    final controller = TextEditingController(text: correoActual);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => _estiloDialog(
          title: const Text("Cambiar Correo"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: "Escriba el nuevo correo",
              hintStyle: TextStyle(
                color: isDark ? Colors.white24 : Colors.black26,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(
                "CANCELAR",
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C1FB7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                final nc = controller.text.trim().toLowerCase();
                if (nc.isEmpty) return;
                if (nc == correoActual) {
                  Navigator.pop(c);
                  return;
                }
                final db = await DBManager.instance.authDatabase;
                final ex = await db.query(
                  'usuarios',
                  where: 'correo = ? AND id != ?',
                  whereArgs: [nc, id],
                );
                if (ex.isNotEmpty) {
                  if (c.mounted)
                    ScaffoldMessenger.of(c).showSnackBar(
                      const SnackBar(
                        content: Text("Ese correo ya está registrado."),
                        backgroundColor: Colors.red,
                      ),
                    );
                } else {
                  _actualizarDato(id, 'correo', nc);
                  if (c.mounted) Navigator.pop(c);
                }
              },
              child: const Text("GUARDAR"),
            ),
          ],
        ),
      ),
    );
  }

  void _dialogoCambiarPassUsuario(int id, String nombre) {
    final passController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (c) => _estiloDialog(
        title: Text("Nueva clave: $nombre"),
        content: TextField(
          controller: passController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: "Escriba la nueva contraseña",
            hintStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? Colors.white24 : Colors.grey,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(
              "CANCELAR",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1C1FB7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              if (passController.text.isNotEmpty) {
                _actualizarDato(id, 'password', passController.text);
                Navigator.pop(c);
              }
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(int id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (c) => _estiloDialog(
        title: const Text("¿Eliminar usuario?"),
        content: const Text(
          "Esta acción no se puede deshacer y se perderán los datos asociados.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(
              "NO",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final db = await DBManager.instance.authDatabase;
              await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
              _cargarUsuarios();
              if (c.mounted) Navigator.pop(c);
            },
            child: const Text("SÍ, ELIMINAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "GESTIÓN ADMIN",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: isDark
            ? Colors.black
            : const Color.fromARGB(255, 28, 31, 183),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildAdminHeader(isDark),
          Expanded(
            child: _usuarios.isEmpty
                ? const Center(child: Text("Sin registros de usuarios"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: _usuarios.length,
                    itemBuilder: (context, index) =>
                        _itemUsuario(_usuarios[index], isDark),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminHeader(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFB71C1C),
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Seguridad del Sistema",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Admin entra con PIN numérico",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isImporting ? null : _dialogoCambiarPinMaestro,
                icon: const Icon(Icons.vpn_key, size: 16),
                label: const Text("PIN"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const Divider(height: 30),

          // BOTÓN VIEJO
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _importarUsuarioDesdeZip,
              icon: const Icon(Icons.restore, size: 20),
              label: const Text(
                "IMPORTAR USUARIO (ZIP VIEJO)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ---> NUEVO BOTÓN PARA EL RESPALDO COMPLETO <---
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: _isImporting ? null : _importarRespaldoCompleto,
              icon: const Icon(Icons.backup, size: 20),
              label: const Text(
                "IMPORTAR RESPALDO COMPLETO (Fotos + BD)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemUsuario(Map<String, dynamic> user, bool isDark) {
    bool isActive = (user['estado'] ?? 'activo') == 'activo';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isDark ? const Color(0xFF161B22) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          child: Icon(
            isActive ? Icons.person : Icons.person_off,
            color: isActive ? Colors.blue : Colors.grey,
          ),
        ),
        title: Text(
          user['nombres'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          user['correo'],
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isActive ? "Activo" : "Bloqueado",
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: isActive,
              activeColor: Colors.green,
              onChanged: (v) => _actualizarDato(
                user['id'],
                'estado',
                v ? 'activo' : 'inactivo',
              ),
            ),
            PopupMenuButton(
              onSelected: (val) {
                if (val == 'name')
                  _dialogoCambiarNombre(user['id'], user['nombres']);
                if (val == 'email')
                  _dialogoCambiarCorreo(user['id'], user['correo']);
                if (val == 'pass')
                  _dialogoCambiarPassUsuario(user['id'], user['nombres']);
                if (val == 'off')
                  _desactivarUsuario(user['id'], user['nombres']);
                if (val == 'del') _confirmarEliminar(user['id']);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(
                        Icons.drive_file_rename_outline,
                        color: Colors.blue,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text("Cambiar Nombre"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'email',
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: Colors.blue, size: 18),
                      SizedBox(width: 8),
                      Text("Cambiar Correo"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pass',
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Colors.blueGrey,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text("Cambiar Contraseña"),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'off',
                  child: Row(
                    children: [
                      Icon(
                        Icons.power_settings_new,
                        color: Colors.orange,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Desconectar",
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'del',
                  child: Text("Eliminar", style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
