// // import 'dart:io';
// // import 'dart:math' as math;
// // import 'package:flutter/material.dart';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:open_file/open_file.dart';
// // import 'package:permission_handler/permission_handler.dart';
// // import 'package:share_plus/share_plus.dart';

// // class ArchivosPage extends StatefulWidget {
// //   const ArchivosPage({super.key});

// //   @override
// //   State<ArchivosPage> createState() => _ArchivosPageState();
// // }

// // class _ArchivosPageState extends State<ArchivosPage> {
// //   List<FileSystemEntity> _archivos = [];
// //   bool _cargando = true;

// //   // Navegación
// //   String _rutaActual = "";
// //   final List<String> _historialRutas = []; // Pila para el botón atrás

// //   // Controladores
// //   final TextEditingController _nombreCarpetaController =
// //       TextEditingController();
// //   final TextEditingController _renombrarController = TextEditingController();

// //   // Variables para Modo Selección
// //   bool _modoNavegacionDestino = false;
// //   final List<FileSystemEntity> _entidadesParaMover = [];
// //   String _operacionPendiente = "";

// //   bool _modoEdicion = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _prepararCarpeta();
// //   }

// //   // 1. Pedir permisos
// //   Future<void> _prepararCarpeta() async {
// //     var status = await Permission.manageExternalStorage.status;
// //     var storageStatus = await Permission.storage.status;

// //     if (status.isGranted || storageStatus.isGranted) {
// //       _ejecutarLogicaCarpeta();
// //       return;
// //     }

// //     if (status.isDenied || storageStatus.isDenied) {
// //       if (!mounted) return;
// //       await showDialog(
// //         context: context,
// //         barrierDismissible: true,
// //         builder: (context) => AlertDialog(
// //           backgroundColor: const Color(0xFF1A237E),
// //           title: const Text(
// //             "Gestión de Archivos",
// //             style: TextStyle(color: Colors.white),
// //           ),
// //           content: const Text(
// //             "Para gestionar archivos se requiere acceso al almacenamiento.",
// //             style: TextStyle(color: Colors.white70),
// //           ),
// //           actions: [
// //             TextButton(
// //               onPressed: () => Navigator.pop(context),
// //               child: const Text(
// //                 "CANCELAR",
// //                 style: TextStyle(color: Colors.white54),
// //               ),
// //             ),
// //             ElevatedButton(
// //               style: ElevatedButton.styleFrom(
// //                 backgroundColor: Colors.greenAccent,
// //               ),
// //               onPressed: () async {
// //                 Navigator.pop(context);
// //                 final result = await Permission.manageExternalStorage.request();
// //                 if (result.isGranted) {
// //                   _ejecutarLogicaCarpeta();
// //                 } else if (result.isPermanentlyDenied) {
// //                   openAppSettings();
// //                 }
// //               },
// //               child: const Text(
// //                 "PERMITIR",
// //                 style: TextStyle(
// //                   color: Colors.black,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //       );
// //     }
// //   }

// //   // 2. Configurar carpeta raíz
// //   Future<void> _ejecutarLogicaCarpeta() async {
// //     try {
// //       Directory? baseDir = Directory('/storage/emulated/0');
// //       final carpetaCalipso = Directory('${baseDir.path}/CALIPSO');

// //       if (!await carpetaCalipso.exists()) {
// //         await carpetaCalipso.create(recursive: true);
// //       }

// //       if (mounted) {
// //         setState(() {
// //           _rutaActual = carpetaCalipso.path;
// //           _historialRutas.clear();
// //         });
// //         _listarArchivos();
// //       }
// //     } catch (e) {
// //       debugPrint("Carpeta no accesible: $e");
// //       if (mounted) setState(() => _cargando = false);
// //     }
// //   }

// //   // 3. Listar archivos
// //   Future<void> _listarArchivos() async {
// //     setState(() => _cargando = true);
// //     try {
// //       final directorio = Directory(_rutaActual);
// //       if (await directorio.exists()) {
// //         final contenido = directorio.listSync();
// //         setState(() {
// //           _archivos = contenido.toList();
// //           _archivos.sort((a, b) {
// //             final aIsDir = a is Directory;
// //             final bIsDir = b is Directory;
// //             if (aIsDir && !bIsDir) return -1;
// //             if (!aIsDir && bIsDir) return 1;
// //             if (aIsDir && bIsDir)
// //               return a.path.toLowerCase().compareTo(b.path.toLowerCase());
// //             return b.statSync().modified.compareTo(a.statSync().modified);
// //           });
// //           _cargando = false;
// //         });
// //       }
// //     } catch (e) {
// //       setState(() => _cargando = false);
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text("Error al leer carpeta: $e")));
// //     }
// //   }

// //   // 4. Entrar a carpeta (Guarda historial)
// //   void _entrarCarpeta(Directory carpeta) {
// //     setState(() {
// //       _historialRutas.add(_rutaActual);
// //       _rutaActual = carpeta.path;
// //     });
// //     _listarArchivos();
// //   }

// //   // 5. Volver Atrás (Usa el historial)
// //   void _volverAtras() {
// //     if (_historialRutas.isNotEmpty) {
// //       setState(() {
// //         _rutaActual = _historialRutas.removeLast();
// //       });
// //       _listarArchivos();
// //     } else {
// //       // Si estamos en la raíz y en modo destino, cancelar
// //       if (_modoNavegacionDestino) {
// //         _cancelarOperacion();
// //       }
// //     }
// //   }

// //   // Navegación rápida por la ruta (Breadcrumb)
// //   void _navegarARuta(String ruta) {
// //     if (ruta != _rutaActual) {
// //       setState(() {
// //         // Añadimos la actual al historial antes de saltar
// //         _historialRutas.add(_rutaActual);
// //         _rutaActual = ruta;
// //       });
// //       _listarArchivos();
// //     }
// //   }

// //   // --- Lógica de Selección ---
// //   void _alternarSeleccion(FileSystemEntity entidad) {
// //     setState(() {
// //       if (_entidadesParaMover.contains(entidad)) {
// //         _entidadesParaMover.remove(entidad);
// //       } else {
// //         _entidadesParaMover.add(entidad);
// //       }
// //     });
// //   }

// //   // --- Compartir ---
// //   Future<void> _compartirArchivo(FileSystemEntity entidad) async {
// //     try {
// //       if (await entidad.exists()) {
// //         await Share.shareXFiles([
// //           XFile(entidad.path),
// //         ], subject: 'Compartiendo archivo');
// //       } else {
// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(const SnackBar(content: Text("El archivo no existe")));
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text("Error al compartir: $e")));
// //     }
// //   }

// //   Future<void> _compartirSeleccionados() async {
// //     final archivos = _entidadesParaMover.whereType<File>().toList();
// //     if (archivos.isEmpty) {
// //       ScaffoldMessenger.of(context).showSnackBar(
// //         const SnackBar(content: Text("Solo se pueden compartir archivos")),
// //       );
// //       return;
// //     }
// //     try {
// //       final xFiles = archivos.map((f) => XFile(f.path)).toList();
// //       await Share.shareXFiles(xFiles, subject: 'Archivos compartidos');
// //     } catch (e) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text("Error: $e")));
// //     }
// //   }

// //   // --- Operaciones ---
// //   void _iniciarOperacion(String operacion) {
// //     if (_entidadesParaMover.isEmpty) return;
// //     setState(() {
// //       _modoEdicion = false;
// //       _modoNavegacionDestino = true;
// //       _operacionPendiente = operacion;
// //     });
// //     ScaffoldMessenger.of(context).showSnackBar(
// //       const SnackBar(
// //         content: Text("Navega y pulsa 'Pegar'"),
// //         duration: Duration(seconds: 3),
// //       ),
// //     );
// //   }

// //   void _cancelarOperacion() {
// //     setState(() {
// //       _modoNavegacionDestino = false;
// //       _modoEdicion = false;
// //       _entidadesParaMover.clear();
// //       _operacionPendiente = "";
// //     });
// //     _listarArchivos();
// //   }

// //   Future<void> _ejecutarOperacionEnDestino() async {
// //     final destino = Directory(_rutaActual);

// //     // Validación: Evitar mover carpeta dentro de sí misma
// //     for (var item in _entidadesParaMover) {
// //       if (item is Directory) {
// //         final itemPathWithSlash =
// //             item.path + (item.path.endsWith('/') ? '' : '/');
// //         if (destino.path.startsWith(itemPathWithSlash)) {
// //           ScaffoldMessenger.of(context).showSnackBar(
// //             const SnackBar(
// //               content: Text(
// //                 "Error: No puedes mover una carpeta dentro de sí misma",
// //               ),
// //             ),
// //           );
// //           return;
// //         }
// //       }
// //     }

// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => AlertDialog(
// //         backgroundColor: const Color(0xFF1E1E1E),
// //         content: Row(
// //           children: [
// //             const CircularProgressIndicator(),
// //             const SizedBox(width: 20),
// //             Expanded(
// //               child: Text(
// //                 _operacionPendiente == 'copiar' ? "Copiando..." : "Moviendo...",
// //                 style: const TextStyle(color: Colors.white),
// //               ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );

// //     int errores = 0;
// //     try {
// //       for (var origen in _entidadesParaMover) {
// //         final nombre = origen.path.split('/').last;
// //         FileSystemEntity destinoFinal = origen is Directory
// //             ? Directory('${destino.path}/$nombre')
// //             : File('${destino.path}/$nombre');

// //         try {
// //           if (_operacionPendiente == 'copiar') {
// //             await _copiarDirectorioOrArchivo(origen, destinoFinal);
// //           } else {
// //             try {
// //               await origen.rename(destinoFinal.path);
// //             } catch (e) {
// //               await _copiarDirectorioOrArchivo(origen, destinoFinal);
// //               await origen.delete(recursive: true);
// //             }
// //           }
// //         } catch (e) {
// //           debugPrint("Error: $e");
// //           errores++;
// //         }
// //       }

// //       if (mounted) Navigator.pop(context);
// //       _cancelarOperacion();

// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(
// //               errores > 0 ? "Finalizado con errores" : "Operación exitosa",
// //             ),
// //           ),
// //         );
// //       }
// //     } catch (e) {
// //       if (mounted) {
// //         Navigator.of(context).pop();
// //         _cancelarOperacion();
// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(SnackBar(content: Text("Error: $e")));
// //       }
// //     }
// //   }

// //   Future<void> _copiarDirectorioOrArchivo(
// //     FileSystemEntity source,
// //     FileSystemEntity destination,
// //   ) async {
// //     if (source is File) {
// //       await source.copy(destination.path);
// //     } else if (source is Directory) {
// //       if (!await destination.exists())
// //         await (destination as Directory).create(recursive: true);
// //       await for (var entity in source.list()) {
// //         final newPath = entity is Directory
// //             ? Directory('${destination.path}/${entity.path.split('/').last}')
// //             : File('${destination.path}/${entity.path.split('/').last}');
// //         await _copiarDirectorioOrArchivo(entity, newPath);
// //       }
// //     }
// //   }

// //   // --- Crear Carpeta ---
// //   Future<void> _crearNuevaCarpeta() async {
// //     final nombre = _nombreCarpetaController.text.trim();
// //     if (nombre.isEmpty) return;
// //     try {
// //       final nuevaCarpeta = Directory('$_rutaActual/$nombre');
// //       if (await nuevaCarpeta.exists()) {
// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(const SnackBar(content: Text("La carpeta ya existe")));
// //       } else {
// //         await nuevaCarpeta.create(recursive: true);
// //         Navigator.pop(context);
// //         _nombreCarpetaController.clear();
// //         _listarArchivos();
// //         ScaffoldMessenger.of(
// //           context,
// //         ).showSnackBar(const SnackBar(content: Text("Carpeta creada")));
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text("Error: $e")));
// //     }
// //   }

// //   void _mostrarDialogoCrearCarpeta() {
// //     final isDark = Theme.of(context).brightness == Brightness.dark;
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
// //         title: Text(
// //           "Nueva Carpeta",
// //           style: TextStyle(color: isDark ? Colors.white : Colors.black),
// //         ),
// //         content: TextField(
// //           controller: _nombreCarpetaController,
// //           autofocus: true,
// //           style: TextStyle(color: isDark ? Colors.white : Colors.black),
// //           decoration: InputDecoration(
// //             hintText: "Nombre",
// //             border: const UnderlineInputBorder(),
// //           ),
// //           onSubmitted: (_) => _crearNuevaCarpeta(),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text("Cancelar"),
// //           ),
// //           ElevatedButton(
// //             onPressed: _crearNuevaCarpeta,
// //             child: const Text("Crear"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // --- Renombrar ---
// //   Future<void> _renombrarEntidad(FileSystemEntity entidad) async {
// //     final nombreViejo = entidad.path.split('/').last;
// //     _renombrarController.text = nombreViejo;
// //     final isDark = Theme.of(context).brightness == Brightness.dark;
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
// //         title: Text(
// //           "Renombrar",
// //           style: TextStyle(color: isDark ? Colors.white : Colors.black),
// //         ),
// //         content: TextField(
// //           controller: _renombrarController,
// //           decoration: const InputDecoration(hintText: "Nuevo nombre"),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text("Cancelar"),
// //           ),
// //           ElevatedButton(
// //             onPressed: () async {
// //               final nombreNuevo = _renombrarController.text.trim();
// //               if (nombreNuevo.isEmpty) return;
// //               try {
// //                 await entidad.rename('${entidad.parent.path}/$nombreNuevo');
// //                 Navigator.pop(context);
// //                 _listarArchivos();
// //               } catch (e) {
// //                 ScaffoldMessenger.of(
// //                   context,
// //                 ).showSnackBar(SnackBar(content: Text("Error: $e")));
// //               }
// //             },
// //             child: const Text("Guardar"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   // --- Detalles ---
// //   void _verDetalles(FileSystemEntity entidad) async {
// //     final stat = await entidad.stat();
// //     final nombre = entidad.path.split('/').last;
// //     final esCarpeta = entidad is Directory;
// //     final isDark = Theme.of(context).brightness == Brightness.dark;
// //     String tipo = esCarpeta ? "Carpeta" : nombre.split('.').last.toUpperCase();
// //     String tamano = esCarpeta ? "-" : _formatBytes(stat.size);
// //     if (esCarpeta) {
// //       try {
// //         tamano = "${(entidad as Directory).listSync().length} elementos";
// //       } catch (e) {}
// //     }
// //     if (!mounted) return;
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
// //         title: Row(
// //           children: [
// //             Icon(
// //               esCarpeta ? Icons.folder : Icons.insert_drive_file,
// //               color: const Color(0xFF1A237E),
// //             ),
// //             const SizedBox(width: 10),
// //             Expanded(
// //               child: Text(
// //                 nombre,
// //                 overflow: TextOverflow.ellipsis,
// //                 style: TextStyle(color: isDark ? Colors.white : Colors.black),
// //               ),
// //             ),
// //           ],
// //         ),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             _detalleFila("Tipo:", tipo, isDark),
// //             _detalleFila("Tamaño:", tamano, isDark),
// //             _detalleFila("Ruta:", entidad.path, isDark),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text("CERRAR"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _detalleFila(String label, String value, bool isDark) {
// //     return Padding(
// //       padding: const EdgeInsets.symmetric(vertical: 4.0),
// //       child: Row(
// //         crossAxisAlignment: CrossAxisAlignment.start,
// //         children: [
// //           SizedBox(
// //             width: 60,
// //             child: Text(
// //               label,
// //               style: TextStyle(
// //                 fontWeight: FontWeight.bold,
// //                 color: isDark ? Colors.white : Colors.black,
// //               ),
// //             ),
// //           ),
// //           Expanded(
// //             child: Text(
// //               value,
// //               style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   String _formatBytes(int bytes, {int decimals = 2}) {
// //     if (bytes <= 0) return "0 B";
// //     const suffixes = ["B", "KB", "MB", "GB", "TB"];
// //     var i = (math.log(bytes) / math.log(1024)).floor();
// //     return ((bytes / math.pow(1024, i)).toStringAsFixed(decimals)) +
// //         ' ' +
// //         suffixes[i];
// //   }

// //   // --- MENÚS ---
// //   void _mostrarMenu(DynamicItem item) {
// //     final entidad = item.entidad;
// //     final esCarpeta = entidad is Directory;
// //     final RenderBox overlay =
// //         Overlay.of(context).context.findRenderObject() as RenderBox;
// //     showMenu(
// //       context: context,
// //       position: RelativeRect.fromRect(Rect.zero, Offset.zero & overlay.size),
// //       items: [
// //         if (!esCarpeta)
// //           const PopupMenuItem(
// //             value: 'abrir',
// //             child: ListTile(
// //               leading: Icon(Icons.open_in_new),
// //               title: Text("Abrir"),
// //               contentPadding: EdgeInsets.zero,
// //             ),
// //           ),
// //         if (!esCarpeta)
// //           const PopupMenuItem(
// //             value: 'compartir',
// //             child: ListTile(
// //               leading: Icon(Icons.share),
// //               title: Text("Compartir"),
// //               contentPadding: EdgeInsets.zero,
// //             ),
// //           ),
// //         const PopupMenuItem(
// //           value: 'detalles',
// //           child: ListTile(
// //             leading: Icon(Icons.info_outline),
// //             title: Text("Detalles"),
// //             contentPadding: EdgeInsets.zero,
// //           ),
// //         ),
// //         const PopupMenuItem(
// //           value: 'renombrar',
// //           child: ListTile(
// //             leading: Icon(Icons.edit),
// //             title: Text("Renombrar"),
// //             contentPadding: EdgeInsets.zero,
// //           ),
// //         ),
// //         const PopupMenuItem(
// //           value: 'copiar',
// //           child: ListTile(
// //             leading: Icon(Icons.copy),
// //             title: Text("Copiar a..."),
// //             contentPadding: EdgeInsets.zero,
// //           ),
// //         ),
// //         const PopupMenuItem(
// //           value: 'mover',
// //           child: ListTile(
// //             leading: Icon(Icons.drive_file_move),
// //             title: Text("Mover a..."),
// //             contentPadding: EdgeInsets.zero,
// //           ),
// //         ),
// //         const PopupMenuItem(
// //           value: 'eliminar',
// //           child: ListTile(
// //             leading: Icon(Icons.delete, color: Colors.red),
// //             title: Text("Eliminar"),
// //             contentPadding: EdgeInsets.zero,
// //           ),
// //         ),
// //       ],
// //     ).then((value) {
// //       if (value == null) return;
// //       switch (value) {
// //         case 'abrir':
// //           OpenFile.open(entidad.path);
// //           break;
// //         case 'compartir':
// //           _compartirArchivo(entidad);
// //           break;
// //         case 'detalles':
// //           _verDetalles(entidad);
// //           break;
// //         case 'renombrar':
// //           _renombrarEntidad(entidad);
// //           break;
// //         case 'copiar':
// //           _entidadesParaMover.clear();
// //           _entidadesParaMover.add(entidad);
// //           _iniciarOperacion('copiar');
// //           break;
// //         case 'mover':
// //           _entidadesParaMover.clear();
// //           _entidadesParaMover.add(entidad);
// //           _iniciarOperacion('mover');
// //           break;
// //         case 'eliminar':
// //           _confirmarEliminarEntidad(entidad);
// //           break;
// //       }
// //     });
// //   }

// //   void _confirmarEliminarEntidad(FileSystemEntity entidad) {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text("¿Eliminar?"),
// //         content: Text("¿Seguro de eliminar ${entidad.path.split('/').last}?"),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text("Cancelar"),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               try {
// //                 entidad.deleteSync(recursive: true);
// //                 Navigator.pop(context);
// //                 _listarArchivos();
// //                 ScaffoldMessenger.of(
// //                   context,
// //                 ).showSnackBar(const SnackBar(content: Text("Eliminado")));
// //               } catch (e) {
// //                 ScaffoldMessenger.of(
// //                   context,
// //                 ).showSnackBar(SnackBar(content: Text("Error: $e")));
// //               }
// //             },
// //             child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _mostrarMenuSeleccion() {
// //     final RenderBox overlay =
// //         Overlay.of(context).context.findRenderObject() as RenderBox;
// //     showMenu(
// //       context: context,
// //       position: RelativeRect.fromRect(Rect.zero, Offset.zero & overlay.size),
// //       items: [
// //         PopupMenuItem(
// //           value: 'compartir',
// //           child: ListTile(
// //             leading: const Icon(Icons.share),
// //             title: Text("Compartir selección"),
// //             contentPadding: EdgeInsets.zero,
// //           ),
// //         ),
// //         PopupMenuItem(
// //           value: 'copiar',
// //           child: ListTile(
// //             leading: const Icon(Icons.copy),
// //             title: Text("Copiar selección"),
// //             contentPadding: EdgeInsets.zero,
// //           ),
// //         ),
// //         PopupMenuItem(
// //           value: 'mover',
// //           child: ListTile(
// //             leading: const Icon(Icons.drive_file_move),
// //             title: Text("Mover selección"),
// //             contentPadding: EdgeInsets.zero,
// //           ),
// //         ),
// //       ],
// //     ).then((value) async {
// //       if (value == null) return;
// //       if (value == 'compartir')
// //         await _compartirSeleccionados();
// //       else
// //         _iniciarOperacion(value);
// //     });
// //   }

// //   // --- Función para mostrar información del gestor (NUEVO) ---
// //   void _mostrarInfoGestor() {
// //     final isDark = Theme.of(context).brightness == Brightness.dark;
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         backgroundColor: isDark ? const Color(0xFF1A237E) : Colors.white,
// //         title: Row(
// //           children: [
// //             Icon(
// //               Icons.folder_shared,
// //               color: isDark ? Colors.white : const Color(0xFF1A237E),
// //             ),
// //             const SizedBox(width: 10),
// //             Text(
// //               "Gestor CALIPSO",
// //               style: TextStyle(color: isDark ? Colors.white : Colors.black),
// //             ),
// //           ],
// //         ),
// //         content: Column(
// //           mainAxisSize: MainAxisSize.min,
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(
// //               "Versión 2.4",
// //               style: TextStyle(
// //                 color: isDark ? Colors.white70 : Colors.black54,
// //                 fontSize: 12,
// //               ),
// //             ),
// //             const SizedBox(height: 10),
// //             Text(
// //               "Gestor de archivos con navegación libre y operaciones de copiar/mover mejoradas.",
// //               style: TextStyle(color: isDark ? Colors.white : Colors.black87),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: Text(
// //               "CERRAR",
// //               style: TextStyle(
// //                 color: isDark ? Colors.greenAccent : const Color(0xFF1A237E),
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final isDark = Theme.of(context).brightness == Brightness.dark;

// //     // Construir lista de rutas para el Breadcrumb (Barra de ruta)
// //     List<String> partesRuta = _rutaActual
// //         .split('/')
// //         .where((p) => p.isNotEmpty)
// //         .toList();
// //     // Ajustar para mostrar desde CALIPSO hacia adelante
// //     int calipsoIndex = partesRuta.indexOf('CALIPSO');
// //     if (calipsoIndex != -1) {
// //       partesRuta = partesRuta.sublist(calipsoIndex);
// //     }

// //     return Scaffold(
// //       backgroundColor: isDark ? const Color(0xFF0A0E12) : Colors.grey[100],
// //       appBar: AppBar(
// //         toolbarHeight: 70, // Un poco más alto para el breadcrumb
// //         backgroundColor: _modoNavegacionDestino
// //             ? Colors.orange
// //             : const Color(0xFF1A237E),
// //         foregroundColor: Colors.white,
// //         elevation: 0,

// //         leading: IconButton(
// //           icon: Icon(_modoNavegacionDestino ? Icons.close : Icons.arrow_back),
// //           onPressed: () {
// //             if (_modoNavegacionDestino && _historialRutas.isEmpty) {
// //               _cancelarOperacion();
// //             } else {
// //               _volverAtras();
// //             }
// //           },
// //         ),

// //         title: Column(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           mainAxisSize: MainAxisSize.min,
// //           children: [
// //             Text(
// //               _modoNavegacionDestino ? "ELIGE DESTINO" : "EXPLORADOR",
// //               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
// //             ),
// //             // BREADCRUMB (Ruta de navegación)
// //             SingleChildScrollView(
// //               scrollDirection: Axis.horizontal,
// //               child: Row(
// //                 children: [
// //                   for (int i = 0; i < partesRuta.length; i++)
// //                     InkWell(
// //                       onTap: () {
// //                         // Reconstruir ruta hasta este índice
// //                         String rutaObjetivo = '/';
// //                         // Encontrar índice real en la ruta completa
// //                         List<String> fullPathParts = _rutaActual
// //                             .split('/')
// //                             .where((p) => p.isNotEmpty)
// //                             .toList();
// //                         int realIndex = fullPathParts.indexOf(partesRuta[i]);

// //                         for (int k = 0; k <= realIndex; k++) {
// //                           rutaObjetivo += '${fullPathParts[k]}/';
// //                         }
// //                         _navegarARuta(rutaObjetivo);
// //                       },
// //                       child: Padding(
// //                         padding: const EdgeInsets.symmetric(vertical: 4.0),
// //                         child: Row(
// //                           children: [
// //                             Text(
// //                               partesRuta[i],
// //                               style: TextStyle(
// //                                 fontSize: 12,
// //                                 color: i == partesRuta.length - 1
// //                                     ? Colors.white
// //                                     : Colors.white70,
// //                                 fontWeight: i == partesRuta.length - 1
// //                                     ? FontWeight.bold
// //                                     : FontWeight.normal,
// //                               ),
// //                             ),
// //                             if (i < partesRuta.length - 1)
// //                               const Padding(
// //                                 padding: EdgeInsets.symmetric(horizontal: 4),
// //                                 child: Text(
// //                                   "/",
// //                                   style: TextStyle(
// //                                     color: Colors.white54,
// //                                     fontSize: 12,
// //                                   ),
// //                                 ),
// //                               ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                 ],
// //               ),
// //             ),
// //           ],
// //         ),

// //         actions: [
// //           if (_modoNavegacionDestino)
// //             IconButton(
// //               icon: const Icon(Icons.close),
// //               onPressed: _cancelarOperacion,
// //             )
// //           else if (!_modoEdicion) ...[
// //             IconButton(
// //               icon: const Icon(Icons.check_box_outline_blank),
// //               onPressed: () {
// //                 setState(() {
// //                   _modoEdicion = true;
// //                   _entidadesParaMover.clear();
// //                 });
// //               },
// //             ),
// //             IconButton(
// //               icon: const Icon(Icons.create_new_folder),
// //               onPressed: _mostrarDialogoCrearCarpeta,
// //             ),
// //             IconButton(
// //               icon: const Icon(Icons.refresh),
// //               onPressed: _listarArchivos,
// //             ),
// //             // --- NUEVO BOTÓN DE INFO ---
// //             IconButton(
// //               icon: const Icon(Icons.info_outline),
// //               tooltip: "Acerca del Gestor",
// //               onPressed: _mostrarInfoGestor,
// //             ),
// //             // -----------------------------
// //           ] else if (_modoEdicion && _entidadesParaMover.isNotEmpty)
// //             IconButton(
// //               icon: const Icon(Icons.more_vert),
// //               onPressed: () => _mostrarMenuSeleccion(),
// //             ),
// //         ],
// //       ),

// //       body: Stack(
// //         children: [
// //           _cargando
// //               ? const Center(child: CircularProgressIndicator())
// //               : _archivos.isEmpty
// //               ? _buildSinArchivos(isDark)
// //               : ListView.builder(
// //                   padding: const EdgeInsets.only(bottom: 100.0),
// //                   itemCount: _archivos.length,
// //                   itemBuilder: (context, index) {
// //                     final entidad = _archivos[index];
// //                     final nombre = entidad.path.split('/').last;
// //                     final esCarpeta = entidad is Directory;
// //                     final estaSeleccionado = _entidadesParaMover.contains(
// //                       entidad,
// //                     );
// //                     final esOrigenEnMovimiento =
// //                         _modoNavegacionDestino &&
// //                         _entidadesParaMover.contains(entidad);

// //                     // Iconos y colores
// //                     IconData icono = Icons.insert_drive_file;
// //                     Color colorIcono = Colors.blueGrey;
// //                     if (esCarpeta) {
// //                       icono = Icons.folder;
// //                       colorIcono = esOrigenEnMovimiento
// //                           ? Colors.orange
// //                           : Colors.amber;
// //                     } else if (nombre.endsWith('.pdf')) {
// //                       icono = Icons.picture_as_pdf;
// //                       colorIcono = Colors.red;
// //                     } else if (nombre.endsWith('.xlsx') ||
// //                         nombre.endsWith('.xls')) {
// //                       icono = Icons.table_chart;
// //                       colorIcono = Colors.green;
// //                     } else if (nombre.endsWith('.jpg') ||
// //                         nombre.endsWith('.png')) {
// //                       icono = Icons.image;
// //                       colorIcono = Colors.orange;
// //                     }

// //                     return Container(
// //                       margin: const EdgeInsets.symmetric(
// //                         vertical: 2.0,
// //                         horizontal: 8.0,
// //                       ),
// //                       decoration: BoxDecoration(
// //                         color: estaSeleccionado
// //                             ? const Color(0xFF2196F3)
// //                             : (esOrigenEnMovimiento
// //                                   ? const Color(0xFFFF9800)
// //                                   : (isDark
// //                                         ? const Color(0xFF212121)
// //                                         : Colors.white)),
// //                         borderRadius: BorderRadius.circular(8),
// //                       ),
// //                       child: ListTile(
// //                         dense: true,
// //                         contentPadding: const EdgeInsets.symmetric(
// //                           horizontal: 10.0,
// //                         ),
// //                         leading: _modoEdicion
// //                             ? Checkbox(
// //                                 value: estaSeleccionado,
// //                                 onChanged: (_) => _alternarSeleccion(entidad),
// //                                 activeColor: Colors.blue,
// //                               )
// //                             : Icon(icono, color: colorIcono),
// //                         title: Text(
// //                           nombre,
// //                           style: TextStyle(
// //                             color: isDark ? Colors.white : Colors.black,
// //                             fontSize: 14,
// //                             fontWeight: (esCarpeta || estaSeleccionado)
// //                                 ? FontWeight.bold
// //                                 : FontWeight.normal,
// //                           ),
// //                           maxLines: 1,
// //                           overflow: TextOverflow.ellipsis,
// //                         ),
// //                         subtitle: esCarpeta
// //                             ? Text(
// //                                 esOrigenEnMovimiento
// //                                     ? "(Seleccionado)"
// //                                     : "Carpeta",
// //                                 style: const TextStyle(
// //                                   fontSize: 11,
// //                                   color: Colors.grey,
// //                                 ),
// //                                 maxLines: 1,
// //                                 overflow: TextOverflow.ellipsis,
// //                               )
// //                             : Text(
// //                                 "Modificado: ${(entidad as File).statSync().modified.toString().split('.')[0]}",
// //                                 style: const TextStyle(
// //                                   fontSize: 11,
// //                                   color: Colors.grey,
// //                                 ),
// //                                 maxLines: 1,
// //                                 overflow: TextOverflow.ellipsis,
// //                               ),
// //                         trailing: _modoEdicion
// //                             ? null
// //                             : (!_modoNavegacionDestino
// //                                   ? IconButton(
// //                                       icon: const Icon(
// //                                         Icons.more_vert,
// //                                         color: Colors.blueGrey,
// //                                         size: 20,
// //                                       ),
// //                                       onPressed: () => _mostrarMenu(
// //                                         DynamicItem(entidad: entidad),
// //                                       ),
// //                                       padding: EdgeInsets.zero,
// //                                     )
// //                                   : null),
// //                         onTap: () {
// //                           if (_modoEdicion) {
// //                             _alternarSeleccion(entidad);
// //                           } else if (_modoNavegacionDestino) {
// //                             if (esCarpeta && !esOrigenEnMovimiento)
// //                               _entrarCarpeta(entidad as Directory);
// //                           } else {
// //                             if (esCarpeta)
// //                               _entrarCarpeta(entidad as Directory);
// //                             else
// //                               OpenFile.open(entidad.path);
// //                           }
// //                         },
// //                         onLongPress: () {
// //                           if (!_modoNavegacionDestino && !_modoEdicion) {
// //                             setState(() {
// //                               _modoEdicion = true;
// //                               _alternarSeleccion(entidad);
// //                             });
// //                           }
// //                         },
// //                       ),
// //                     );
// //                   },
// //                 ),

// //           if (_modoNavegacionDestino)
// //             Positioned(
// //               bottom: 20,
// //               left: 20,
// //               right: 20,
// //               child: Row(
// //                 children: [
// //                   Expanded(
// //                     child: FloatingActionButton.extended(
// //                       heroTag: "btn_cancel",
// //                       onPressed: _cancelarOperacion,
// //                       backgroundColor: Colors.grey,
// //                       icon: const Icon(Icons.close, color: Colors.white),
// //                       label: const Text(
// //                         "CANCELAR",
// //                         style: TextStyle(color: Colors.white),
// //                       ),
// //                     ),
// //                   ),
// //                   const SizedBox(width: 10),
// //                   Expanded(
// //                     child: FloatingActionButton.extended(
// //                       heroTag: "btn_paste",
// //                       onPressed: _ejecutarOperacionEnDestino,
// //                       backgroundColor: Colors.orange,
// //                       icon: const Icon(Icons.paste, color: Colors.white),
// //                       label: Text(
// //                         "PEGAR AQUÍ (${_entidadesParaMover.length})",
// //                         style: const TextStyle(color: Colors.white),
// //                       ),
// //                     ),
// //                   ),
// //                 ],
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildSinArchivos(bool isDark) {
// //     return Center(
// //       child: Column(
// //         mainAxisAlignment: MainAxisAlignment.center,
// //         children: [
// //           Icon(
// //             Icons.folder_open,
// //             size: 80,
// //             color: isDark ? Colors.white24 : Colors.grey,
// //           ),
// //           const SizedBox(height: 10),
// //           Text(
// //             _modoNavegacionDestino ? "Carpeta vacía" : "Carpeta vacía",
// //             style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
// //           ),
// //           const SizedBox(height: 5),
// //           if (!_modoNavegacionDestino)
// //             Text(
// //               "Usa el botón + para crear carpetas",
// //               style: TextStyle(
// //                 fontSize: 12,
// //                 color: isDark ? Colors.white38 : Colors.grey,
// //               ),
// //             ),
// //         ],
// //       ),
// //     );
// //   }
// // }

// // // Clase auxiliar para pasar datos a los menús
// // class DynamicItem {
// //   final FileSystemEntity entidad;
// //   DynamicItem({required this.entidad});
// // }

// import 'dart:io';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:share_plus/share_plus.dart';

// class ArchivosPage extends StatefulWidget {
//   const ArchivosPage({super.key});

//   @override
//   State<ArchivosPage> createState() => _ArchivosPageState();
// }

// class _ArchivosPageState extends State<ArchivosPage> {
//   List<FileSystemEntity> _archivos = [];
//   bool _cargando = true;

//   // Navegación
//   String _rutaActual = "";
//   final List<String> _historialRutas = [];

//   // Controladores
//   final TextEditingController _nombreCarpetaController =
//       TextEditingController();
//   final TextEditingController _renombrarController = TextEditingController();

//   // Variables para Modo Selección
//   bool _modoNavegacionDestino = false;
//   final List<FileSystemEntity> _entidadesParaMover = [];
//   String _operacionPendiente = "";

//   bool _modoEdicion = false;

//   @override
//   void initState() {
//     super.initState();
//     _prepararCarpeta();
//   }

//   // 1. Pedir permisos (Mejorado para forzar escritura)
//   Future<void> _prepararCarpeta() async {
//     // Prioridad: MANAGE_EXTERNAL_STORAGE (Acceso Total)
//     var status = await Permission.manageExternalStorage.status;

//     if (!status.isGranted) {
//       status = await Permission.manageExternalStorage.request();
//     }

//     // Si falla el acceso total, intentar con Storage normal
//     if (!status.isGranted) {
//       var storageStatus = await Permission.storage.status;
//       if (!storageStatus.isGranted) {
//         storageStatus = await Permission.storage.request();
//       }
//       if (storageStatus.isGranted) {
//         _ejecutarLogicaCarpeta();
//         return;
//       }
//     } else {
//       // Tenemos acceso total
//       _ejecutarLogicaCarpeta();
//       return;
//     }

//     // Si llegamos aquí, no hay permisos
//     if (status.isPermanentlyDenied || status.isDenied) {
//       if (!mounted) return;
//       await showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => AlertDialog(
//           backgroundColor: const Color(0xFF1A237E),
//           title: const Text(
//             "Acceso de Almacenamiento",
//             style: TextStyle(color: Colors.white),
//           ),
//           content: const Text(
//             "Para abrir archivos con permiso de edición y gestionar carpetas, CALIPSO necesita acceso completo al almacenamiento.",
//             style: TextStyle(color: Colors.white70),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text(
//                 "SALIR",
//                 style: TextStyle(color: Colors.white54),
//               ),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.greenAccent,
//               ),
//               onPressed: () {
//                 Navigator.pop(context);
//                 openAppSettings(); // Enviar a ajustes manuales si ya se negó
//               },
//               child: const Text(
//                 "CONFIGURAR",
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }
//   }

//   // 2. Configurar carpeta raíz
//   Future<void> _ejecutarLogicaCarpeta() async {
//     try {
//       Directory? baseDir = Directory('/storage/emulated/0');
//       final carpetaCalipso = Directory('${baseDir.path}/CALIPSO');

//       if (!await carpetaCalipso.exists()) {
//         await carpetaCalipso.create(recursive: true);
//       }

//       if (mounted) {
//         setState(() {
//           _rutaActual = carpetaCalipso.path;
//           _historialRutas.clear();
//         });
//         _listarArchivos();
//       }
//     } catch (e) {
//       debugPrint("Carpeta no accesible: $e");
//       if (mounted) setState(() => _cargando = false);
//     }
//   }

//   // 3. Listar archivos
//   Future<void> _listarArchivos() async {
//     setState(() => _cargando = true);
//     try {
//       final directorio = Directory(_rutaActual);
//       if (await directorio.exists()) {
//         final contenido = directorio.listSync();
//         setState(() {
//           _archivos = contenido.toList();
//           _archivos.sort((a, b) {
//             final aIsDir = a is Directory;
//             final bIsDir = b is Directory;
//             if (aIsDir && !bIsDir) return -1;
//             if (!aIsDir && bIsDir) return 1;
//             if (aIsDir && bIsDir)
//               return a.path.toLowerCase().compareTo(b.path.toLowerCase());
//             return b.statSync().modified.compareTo(a.statSync().modified);
//           });
//           _cargando = false;
//         });
//       }
//     } catch (e) {
//       setState(() => _cargando = false);
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error al leer carpeta: $e")));
//     }
//   }

//   // 4. Entrar a carpeta
//   void _entrarCarpeta(Directory carpeta) {
//     setState(() {
//       _historialRutas.add(_rutaActual);
//       _rutaActual = carpeta.path;
//     });
//     _listarArchivos();
//   }

//   // 5. Volver Atrás
//   void _volverAtras() {
//     if (_historialRutas.isNotEmpty) {
//       setState(() {
//         _rutaActual = _historialRutas.removeLast();
//       });
//       _listarArchivos();
//     } else {
//       if (_modoNavegacionDestino) {
//         _cancelarOperacion();
//       }
//     }
//   }

//   void _navegarARuta(String ruta) {
//     if (ruta != _rutaActual) {
//       setState(() {
//         _historialRutas.add(_rutaActual);
//         _rutaActual = ruta;
//       });
//       _listarArchivos();
//     }
//   }

//   // --- Lógica de Selección ---
//   void _alternarSeleccion(FileSystemEntity entidad) {
//     setState(() {
//       if (_entidadesParaMover.contains(entidad)) {
//         _entidadesParaMover.remove(entidad);
//       } else {
//         _entidadesParaMover.add(entidad);
//       }
//     });
//   }

//   // --- Compartir ---
//   Future<void> _compartirArchivo(FileSystemEntity entidad) async {
//     try {
//       if (await entidad.exists()) {
//         await Share.shareXFiles([
//           XFile(entidad.path),
//         ], subject: 'Compartiendo archivo');
//       } else {
//         if (mounted)
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text("El archivo no existe")));
//       }
//     } catch (e) {
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error al compartir: $e")));
//     }
//   }

//   Future<void> _compartirSeleccionados() async {
//     final archivos = _entidadesParaMover.whereType<File>().toList();
//     if (archivos.isEmpty) {
//       if (mounted)
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Solo se pueden compartir archivos")),
//         );
//       return;
//     }
//     try {
//       final xFiles = archivos.map((f) => XFile(f.path)).toList();
//       await Share.shareXFiles(xFiles, subject: 'Archivos compartidos');
//     } catch (e) {
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//   }

//   // --- Operaciones ---
//   void _iniciarOperacion(String operacion) {
//     if (_entidadesParaMover.isEmpty) return;
//     setState(() {
//       _modoEdicion = false;
//       _modoNavegacionDestino = true;
//       _operacionPendiente = operacion;
//     });
//     if (mounted)
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Navega y pulsa 'Pegar'"),
//           duration: Duration(seconds: 3),
//         ),
//       );
//   }

//   void _cancelarOperacion() {
//     setState(() {
//       _modoNavegacionDestino = false;
//       _modoEdicion = false;
//       _entidadesParaMover.clear();
//       _operacionPendiente = "";
//     });
//     _listarArchivos();
//   }

//   Future<void> _ejecutarOperacionEnDestino() async {
//     final destino = Directory(_rutaActual);

//     // Validación: Evitar mover carpeta dentro de sí misma
//     for (var item in _entidadesParaMover) {
//       if (item is Directory) {
//         final itemPathWithSlash =
//             item.path + (item.path.endsWith('/') ? '' : '/');
//         if (destino.path.startsWith(itemPathWithSlash)) {
//           if (mounted)
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text(
//                   "Error: No puedes mover una carpeta dentro de sí misma",
//                 ),
//               ),
//             );
//           return;
//         }
//       }
//     }

//     if (!mounted) return;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF1E1E1E),
//         content: Row(
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(width: 20),
//             Expanded(
//               child: Text(
//                 _operacionPendiente == 'copiar' ? "Copiando..." : "Moviendo...",
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );

//     int errores = 0;
//     try {
//       for (var origen in _entidadesParaMover) {
//         final nombre = origen.path.split('/').last;
//         FileSystemEntity destinoFinal = origen is Directory
//             ? Directory('${destino.path}/$nombre')
//             : File('${destino.path}/$nombre');

//         try {
//           if (_operacionPendiente == 'copiar') {
//             await _copiarDirectorioOrArchivo(origen, destinoFinal);
//           } else {
//             try {
//               await origen.rename(destinoFinal.path);
//             } catch (e) {
//               await _copiarDirectorioOrArchivo(origen, destinoFinal);
//               await origen.delete(recursive: true);
//             }
//           }
//         } catch (e) {
//           debugPrint("Error: $e");
//           errores++;
//         }
//       }

//       if (mounted) Navigator.pop(context);
//       _cancelarOperacion();

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               errores > 0 ? "Finalizado con errores" : "Operación exitosa",
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         Navigator.of(context).pop();
//         _cancelarOperacion();
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error: $e")));
//       }
//     }
//   }

//   Future<void> _copiarDirectorioOrArchivo(
//     FileSystemEntity source,
//     FileSystemEntity destination,
//   ) async {
//     if (source is File) {
//       await source.copy(destination.path);
//     } else if (source is Directory) {
//       if (!await destination.exists())
//         await (destination as Directory).create(recursive: true);
//       await for (var entity in source.list()) {
//         final newPath = entity is Directory
//             ? Directory('${destination.path}/${entity.path.split('/').last}')
//             : File('${destination.path}/${entity.path.split('/').last}');
//         await _copiarDirectorioOrArchivo(entity, newPath);
//       }
//     }
//   }

//   // --- Crear Carpeta ---
//   Future<void> _crearNuevaCarpeta() async {
//     final nombre = _nombreCarpetaController.text.trim();
//     if (nombre.isEmpty) return;
//     try {
//       final nuevaCarpeta = Directory('$_rutaActual/$nombre');
//       if (await nuevaCarpeta.exists()) {
//         if (mounted)
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text("La carpeta ya existe")));
//       } else {
//         await nuevaCarpeta.create(recursive: true);
//         if (mounted) Navigator.pop(context);
//         _nombreCarpetaController.clear();
//         _listarArchivos();
//         if (mounted)
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text("Carpeta creada")));
//       }
//     } catch (e) {
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//   }

//   void _mostrarDialogoCrearCarpeta() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         title: Text(
//           "Nueva Carpeta",
//           style: TextStyle(color: isDark ? Colors.white : Colors.black),
//         ),
//         content: TextField(
//           controller: _nombreCarpetaController,
//           autofocus: true,
//           style: TextStyle(color: isDark ? Colors.white : Colors.black),
//           decoration: const InputDecoration(
//             hintText: "Nombre",
//             border: UnderlineInputBorder(),
//           ),
//           onSubmitted: (_) => _crearNuevaCarpeta(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancelar"),
//           ),
//           ElevatedButton(
//             onPressed: _crearNuevaCarpeta,
//             child: const Text("Crear"),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- Renombrar ---
//   Future<void> _renombrarEntidad(FileSystemEntity entidad) async {
//     final nombreViejo = entidad.path.split('/').last;
//     _renombrarController.text = nombreViejo;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         title: Text(
//           "Renombrar",
//           style: TextStyle(color: isDark ? Colors.white : Colors.black),
//         ),
//         content: TextField(
//           controller: _renombrarController,
//           decoration: const InputDecoration(hintText: "Nuevo nombre"),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancelar"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               final nombreNuevo = _renombrarController.text.trim();
//               if (nombreNuevo.isEmpty) return;
//               try {
//                 await entidad.rename('${entidad.parent.path}/$nombreNuevo');
//                 if (mounted) Navigator.pop(context);
//                 _listarArchivos();
//               } catch (e) {
//                 if (mounted)
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(SnackBar(content: Text("Error: $e")));
//               }
//             },
//             child: const Text("Guardar"),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- Detalles ---
//   void _verDetalles(FileSystemEntity entidad) async {
//     final stat = await entidad.stat();
//     final nombre = entidad.path.split('/').last;
//     final esCarpeta = entidad is Directory;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     String tipo = esCarpeta ? "Carpeta" : nombre.split('.').last.toUpperCase();
//     String tamano = esCarpeta ? "-" : _formatBytes(stat.size);
//     if (esCarpeta) {
//       try {
//         tamano = "${(entidad as Directory).listSync().length} elementos";
//       } catch (e) {}
//     }
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         title: Row(
//           children: [
//             Icon(
//               esCarpeta ? Icons.folder : Icons.insert_drive_file,
//               color: const Color(0xFF1A237E),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 nombre,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(color: isDark ? Colors.white : Colors.black),
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _detalleFila("Tipo:", tipo, isDark),
//             _detalleFila("Tamaño:", tamano, isDark),
//             _detalleFila("Ruta:", entidad.path, isDark),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("CERRAR"),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _detalleFila(String label, String value, bool isDark) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 60,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isDark ? Colors.white : Colors.black,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatBytes(int bytes, {int decimals = 2}) {
//     if (bytes <= 0) return "0 B";
//     const suffixes = ["B", "KB", "MB", "GB", "TB"];
//     var i = (math.log(bytes) / math.log(1024)).floor();
//     return ((bytes / math.pow(1024, i)).toStringAsFixed(decimals)) +
//         ' ' +
//         suffixes[i];
//   }

//   // --- ABRIR ARCHIVO (ACTUALIZADO) ---
//   Future<void> _abrirArchivo(FileSystemEntity entidad) async {
//     try {
//       // El paquete open_file crea el Intent. Con el Manifest correcto, esto permitirá edición.
//       final result = await OpenFile.open(entidad.path);

//       if (result.type == ResultType.noAppToOpen) {
//         if (mounted)
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("No hay aplicación para abrir este archivo"),
//             ),
//           );
//       } else if (result.type == ResultType.permissionDenied) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Permiso denegado. Verifica ajustes."),
//             ),
//           );
//           _prepararCarpeta(); // Reintentar pedir permisos
//         }
//       }
//     } catch (e) {
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error al abrir: $e")));
//     }
//   }

//   // --- MENÚS ---
//   void _mostrarMenu(DynamicItem item) {
//     final entidad = item.entidad;
//     final esCarpeta = entidad is Directory;
//     final RenderBox overlay =
//         Overlay.of(context).context.findRenderObject() as RenderBox;
//     showMenu(
//       context: context,
//       position: RelativeRect.fromRect(Rect.zero, Offset.zero & overlay.size),
//       items: [
//         if (!esCarpeta)
//           const PopupMenuItem(
//             value: 'abrir',
//             child: ListTile(
//               leading: Icon(Icons.open_in_new),
//               title: Text("Abrir"),
//               contentPadding: EdgeInsets.zero,
//             ),
//           ),
//         if (!esCarpeta)
//           const PopupMenuItem(
//             value: 'compartir',
//             child: ListTile(
//               leading: Icon(Icons.share),
//               title: Text("Compartir"),
//               contentPadding: EdgeInsets.zero,
//             ),
//           ),
//         const PopupMenuItem(
//           value: 'detalles',
//           child: ListTile(
//             leading: Icon(Icons.info_outline),
//             title: Text("Detalles"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         const PopupMenuItem(
//           value: 'renombrar',
//           child: ListTile(
//             leading: Icon(Icons.edit),
//             title: Text("Renombrar"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         const PopupMenuItem(
//           value: 'copiar',
//           child: ListTile(
//             leading: Icon(Icons.copy),
//             title: Text("Copiar a..."),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         const PopupMenuItem(
//           value: 'mover',
//           child: ListTile(
//             leading: Icon(Icons.drive_file_move),
//             title: Text("Mover a..."),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         const PopupMenuItem(
//           value: 'eliminar',
//           child: ListTile(
//             leading: Icon(Icons.delete, color: Colors.red),
//             title: Text("Eliminar"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//       ],
//     ).then((value) {
//       if (value == null) return;
//       switch (value) {
//         case 'abrir':
//           _abrirArchivo(entidad);
//           break;
//         case 'compartir':
//           _compartirArchivo(entidad);
//           break;
//         case 'detalles':
//           _verDetalles(entidad);
//           break;
//         case 'renombrar':
//           _renombrarEntidad(entidad);
//           break;
//         case 'copiar':
//           _entidadesParaMover.clear();
//           _entidadesParaMover.add(entidad);
//           _iniciarOperacion('copiar');
//           break;
//         case 'mover':
//           _entidadesParaMover.clear();
//           _entidadesParaMover.add(entidad);
//           _iniciarOperacion('mover');
//           break;
//         case 'eliminar':
//           _confirmarEliminarEntidad(entidad);
//           break;
//       }
//     });
//   }

//   void _confirmarEliminarEntidad(FileSystemEntity entidad) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("¿Eliminar?"),
//         content: Text("¿Seguro de eliminar ${entidad.path.split('/').last}?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancelar"),
//           ),
//           TextButton(
//             onPressed: () {
//               try {
//                 entidad.deleteSync(recursive: true);
//                 if (mounted) Navigator.pop(context);
//                 _listarArchivos();
//                 if (mounted)
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(const SnackBar(content: Text("Eliminado")));
//               } catch (e) {
//                 if (mounted)
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(SnackBar(content: Text("Error: $e")));
//               }
//             },
//             child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _mostrarMenuSeleccion() {
//     final RenderBox overlay =
//         Overlay.of(context).context.findRenderObject() as RenderBox;
//     showMenu(
//       context: context,
//       position: RelativeRect.fromRect(Rect.zero, Offset.zero & overlay.size),
//       items: [
//         PopupMenuItem(
//           value: 'compartir',
//           child: ListTile(
//             leading: const Icon(Icons.share),
//             title: Text("Compartir selección"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         PopupMenuItem(
//           value: 'copiar',
//           child: ListTile(
//             leading: const Icon(Icons.copy),
//             title: Text("Copiar selección"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         PopupMenuItem(
//           value: 'mover',
//           child: ListTile(
//             leading: const Icon(Icons.drive_file_move),
//             title: Text("Mover selección"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//       ],
//     ).then((value) async {
//       if (value == null) return;
//       if (value == 'compartir')
//         await _compartirSeleccionados();
//       else
//         _iniciarOperacion(value);
//     });
//   }

//   void _mostrarInfoGestor() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1A237E) : Colors.white,
//         title: Row(
//           children: [
//             Icon(
//               Icons.folder_shared,
//               color: isDark ? Colors.white : const Color(0xFF1A237E),
//             ),
//             const SizedBox(width: 10),
//             Text(
//               "Gestor CALIPSO",
//               style: TextStyle(color: isDark ? Colors.white : Colors.black),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Versión 2.6",
//               style: TextStyle(
//                 color: isDark ? Colors.white70 : Colors.black54,
//                 fontSize: 12,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               "Gestor optimizado con permisos de edición forzados (Legacy Storage).",
//               style: TextStyle(color: isDark ? Colors.white : Colors.black87),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               "CERRAR",
//               style: TextStyle(
//                 color: isDark ? Colors.greenAccent : const Color(0xFF1A237E),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     List<String> partesRuta = _rutaActual
//         .split('/')
//         .where((p) => p.isNotEmpty)
//         .toList();
//     int calipsoIndex = partesRuta.indexOf('CALIPSO');
//     if (calipsoIndex != -1) {
//       partesRuta = partesRuta.sublist(calipsoIndex);
//     }

//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF0A0E12) : Colors.grey[100],
//       appBar: AppBar(
//         toolbarHeight: 70,
//         backgroundColor: _modoNavegacionDestino
//             ? Colors.orange
//             : const Color(0xFF1A237E),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(_modoNavegacionDestino ? Icons.close : Icons.arrow_back),
//           onPressed: () {
//             if (_modoNavegacionDestino && _historialRutas.isEmpty) {
//               _cancelarOperacion();
//             } else {
//               _volverAtras();
//             }
//           },
//         ),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               _modoNavegacionDestino ? "ELIGE DESTINO" : "EXPLORADOR",
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//             ),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   for (int i = 0; i < partesRuta.length; i++)
//                     InkWell(
//                       onTap: () {
//                         String rutaObjetivo = '/';
//                         List<String> fullPathParts = _rutaActual
//                             .split('/')
//                             .where((p) => p.isNotEmpty)
//                             .toList();
//                         int realIndex = fullPathParts.indexOf(partesRuta[i]);
//                         for (int k = 0; k <= realIndex; k++) {
//                           rutaObjetivo += '${fullPathParts[k]}/';
//                         }
//                         _navegarARuta(rutaObjetivo);
//                       },
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 4.0),
//                         child: Row(
//                           children: [
//                             Text(
//                               partesRuta[i],
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: i == partesRuta.length - 1
//                                     ? Colors.white
//                                     : Colors.white70,
//                                 fontWeight: i == partesRuta.length - 1
//                                     ? FontWeight.bold
//                                     : FontWeight.normal,
//                               ),
//                             ),
//                             if (i < partesRuta.length - 1)
//                               const Padding(
//                                 padding: EdgeInsets.symmetric(horizontal: 4),
//                                 child: Text(
//                                   "/",
//                                   style: TextStyle(
//                                     color: Colors.white54,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           if (_modoNavegacionDestino)
//             IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: _cancelarOperacion,
//             )
//           else if (!_modoEdicion) ...[
//             IconButton(
//               icon: const Icon(Icons.check_box_outline_blank),
//               onPressed: () {
//                 setState(() {
//                   _modoEdicion = true;
//                   _entidadesParaMover.clear();
//                 });
//               },
//             ),
//             IconButton(
//               icon: const Icon(Icons.create_new_folder),
//               onPressed: _mostrarDialogoCrearCarpeta,
//             ),
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: _listarArchivos,
//             ),
//             IconButton(
//               icon: const Icon(Icons.info_outline),
//               tooltip: "Acerca del Gestor",
//               onPressed: _mostrarInfoGestor,
//             ),
//           ] else if (_modoEdicion && _entidadesParaMover.isNotEmpty)
//             IconButton(
//               icon: const Icon(Icons.more_vert),
//               onPressed: () => _mostrarMenuSeleccion(),
//             ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           _cargando
//               ? const Center(child: CircularProgressIndicator())
//               : _archivos.isEmpty
//               ? _buildSinArchivos(isDark)
//               : ListView.builder(
//                   padding: const EdgeInsets.only(bottom: 100.0),
//                   itemCount: _archivos.length,
//                   itemBuilder: (context, index) {
//                     final entidad = _archivos[index];
//                     final nombre = entidad.path.split('/').last;
//                     final esCarpeta = entidad is Directory;
//                     final estaSeleccionado = _entidadesParaMover.contains(
//                       entidad,
//                     );
//                     final esOrigenEnMovimiento =
//                         _modoNavegacionDestino &&
//                         _entidadesParaMover.contains(entidad);

//                     IconData icono = Icons.insert_drive_file;
//                     Color colorIcono = Colors.blueGrey;
//                     if (esCarpeta) {
//                       icono = Icons.folder;
//                       colorIcono = esOrigenEnMovimiento
//                           ? Colors.orange
//                           : Colors.amber;
//                     } else if (nombre.endsWith('.pdf')) {
//                       icono = Icons.picture_as_pdf;
//                       colorIcono = Colors.red;
//                     } else if (nombre.endsWith('.xlsx') ||
//                         nombre.endsWith('.xls')) {
//                       icono = Icons.table_chart;
//                       colorIcono = Colors.green;
//                     } else if (nombre.endsWith('.jpg') ||
//                         nombre.endsWith('.png')) {
//                       icono = Icons.image;
//                       colorIcono = Colors.orange;
//                     }

//                     return Container(
//                       margin: const EdgeInsets.symmetric(
//                         vertical: 2.0,
//                         horizontal: 8.0,
//                       ),
//                       decoration: BoxDecoration(
//                         color: estaSeleccionado
//                             ? const Color(0xFF2196F3)
//                             : (esOrigenEnMovimiento
//                                   ? const Color(0xFFFF9800)
//                                   : (isDark
//                                         ? const Color(0xFF212121)
//                                         : Colors.white)),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: ListTile(
//                         dense: true,
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 10.0,
//                         ),
//                         leading: _modoEdicion
//                             ? Checkbox(
//                                 value: estaSeleccionado,
//                                 onChanged: (_) => _alternarSeleccion(entidad),
//                                 activeColor: Colors.blue,
//                               )
//                             : Icon(icono, color: colorIcono),
//                         title: Text(
//                           nombre,
//                           style: TextStyle(
//                             color: isDark ? Colors.white : Colors.black,
//                             fontSize: 14,
//                             fontWeight: (esCarpeta || estaSeleccionado)
//                                 ? FontWeight.bold
//                                 : FontWeight.normal,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         subtitle: esCarpeta
//                             ? Text(
//                                 esOrigenEnMovimiento
//                                     ? "(Seleccionado)"
//                                     : "Carpeta",
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               )
//                             : Text(
//                                 "Modificado: ${(entidad as File).statSync().modified.toString().split('.')[0]}",
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                         trailing: _modoEdicion
//                             ? null
//                             : (!_modoNavegacionDestino
//                                   ? IconButton(
//                                       icon: const Icon(
//                                         Icons.more_vert,
//                                         color: Colors.blueGrey,
//                                         size: 20,
//                                       ),
//                                       onPressed: () => _mostrarMenu(
//                                         DynamicItem(entidad: entidad),
//                                       ),
//                                       padding: EdgeInsets.zero,
//                                     )
//                                   : null),
//                         onTap: () {
//                           if (_modoEdicion) {
//                             _alternarSeleccion(entidad);
//                           } else if (_modoNavegacionDestino) {
//                             if (esCarpeta && !esOrigenEnMovimiento)
//                               _entrarCarpeta(entidad as Directory);
//                           } else {
//                             if (esCarpeta)
//                               _entrarCarpeta(entidad as Directory);
//                             else
//                               _abrirArchivo(entidad);
//                           }
//                         },
//                         onLongPress: () {
//                           if (!_modoNavegacionDestino && !_modoEdicion) {
//                             setState(() {
//                               _modoEdicion = true;
//                               _alternarSeleccion(entidad);
//                             });
//                           }
//                         },
//                       ),
//                     );
//                   },
//                 ),
//           if (_modoNavegacionDestino)
//             Positioned(
//               bottom: 20,
//               left: 20,
//               right: 20,
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: FloatingActionButton.extended(
//                       heroTag: "btn_cancel",
//                       onPressed: _cancelarOperacion,
//                       backgroundColor: Colors.grey,
//                       icon: const Icon(Icons.close, color: Colors.white),
//                       label: const Text(
//                         "CANCELAR",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: FloatingActionButton.extended(
//                       heroTag: "btn_paste",
//                       onPressed: _ejecutarOperacionEnDestino,
//                       backgroundColor: Colors.orange,
//                       icon: const Icon(Icons.paste, color: Colors.white),
//                       label: Text(
//                         "PEGAR AQUÍ (${_entidadesParaMover.length})",
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSinArchivos(bool isDark) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.folder_open,
//             size: 80,
//             color: isDark ? Colors.white24 : Colors.grey,
//           ),
//           const SizedBox(height: 10),
//           Text(
//             _modoNavegacionDestino ? "Carpeta vacía" : "Carpeta vacía",
//             style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
//           ),
//           const SizedBox(height: 5),
//           if (!_modoNavegacionDestino)
//             Text(
//               "Usa el botón + para crear carpetas",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: isDark ? Colors.white38 : Colors.grey,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class DynamicItem {
//   final FileSystemEntity entidad;
//   DynamicItem({required this.entidad});
// }

// import 'dart:io';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:open_file/open_file.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // 🆕 Importar SharedPreferences

// class ArchivosPage extends StatefulWidget {
//   const ArchivosPage({super.key});

//   @override
//   State<ArchivosPage> createState() => _ArchivosPageState();
// }

// class _ArchivosPageState extends State<ArchivosPage> {
//   List<FileSystemEntity> _archivos = [];
//   bool _cargando = true;

//   // Navegación
//   String _rutaActual = "";
//   final List<String> _historialRutas = [];

//   // Controladores
//   final TextEditingController _nombreCarpetaController =
//       TextEditingController();
//   final TextEditingController _renombrarController = TextEditingController();

//   // Variables para Modo Selección
//   bool _modoNavegacionDestino = false;
//   final List<FileSystemEntity> _entidadesParaMover = [];
//   String _operacionPendiente = "";

//   bool _modoEdicion = false;

//   @override
//   void initState() {
//     super.initState();
//     _prepararCarpeta();
//   }

//   // 1. Pedir permisos con Persistencia y Validación
//   Future<void> _prepararCarpeta() async {
//     final prefs = await SharedPreferences.getInstance();

//     // Verificar estado ACTUAL del permiso
//     var status = await Permission.manageExternalStorage.status;

//     // CASO A: Ya tenemos permiso garantizado -> Ejecutar lógica normal
//     if (status.isGranted) {
//       _ejecutarLogicaCarpeta();
//       return;
//     }

//     // CASO B: No tenemos permiso. ¿Ya preguntamos antes?
//     final bool permisoYaPedido =
//         prefs.getBool('permiso_pedido_calipso') ?? false;

//     if (!permisoYaPedido) {
//       // Es la PRIMERA vez que entramos (o se borraron los datos). Mostrar Alerta Informativa.
//       if (!mounted) return;

//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => AlertDialog(
//           backgroundColor: const Color(0xFF1A237E),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           title: const Row(
//             children: [
//               Icon(Icons.folder_special, color: Colors.greenAccent, size: 28),
//               SizedBox(width: 10),
//               Text(
//                 "Acceso a Archivos",
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           content: const Text(
//             "Para abrir archivos con permiso de edición, crear carpetas y gestionar documentos libremente en CALIPSO, es necesario conceder acceso completo al almacenamiento.",
//             style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 Navigator.pop(context);
//                 // Guardar que ya vimos la alerta
//                 await prefs.setBool('permiso_pedido_calipso', true);
//                 // Cargar igual (aunque probablemente vacío)
//                 _ejecutarLogicaCarpeta();
//               },
//               child: const Text(
//                 "MÁS TARDE",
//                 style: TextStyle(
//                   color: Colors.white54,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.greenAccent,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//               ),
//               onPressed: () async {
//                 Navigator.pop(context);
//                 // Guardar que intentamos pedir permiso
//                 await prefs.setBool('permiso_pedido_calipso', true);

//                 // Pedir permiso real
//                 final result = await Permission.manageExternalStorage.request();
//                 if (result.isGranted) {
//                   _ejecutarLogicaCarpeta();
//                 } else if (result.isPermanentlyDenied) {
//                   if (mounted) _mostrarDialogoSettings();
//                 } else {
//                   if (mounted) {
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(content: Text("Permiso denegado.")),
//                     );
//                     _ejecutarLogicaCarpeta();
//                   }
//                 }
//               },
//               child: const Text(
//                 "PERMITIR AHORA",
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     } else {
//       // CASO C: El usuario ya vio la alerta antes ("Más Tarde"), pero NO tiene permiso.
//       // Intentamos pedirlo silenciosamente al cargar. Si lo acepta en ajustes, funcionará.
//       // Si sigue sin permiso, cargamos la app vacía sin molestar.
//       final result = await Permission.manageExternalStorage.request();
//       if (result.isGranted) {
//         _ejecutarLogicaCarpeta();
//       } else {
//         // Si no se concede, cargamos la carpeta (probablemente fallará o estará vacía, pero no interrumpimos)
//         _ejecutarLogicaCarpeta();
//       }
//     }
//   }

//   // Diálogo para ir a ajustes si el permiso fue denegado permanentemente
//   void _mostrarDialogoSettings() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF1A237E),
//         title: const Text(
//           "Acceso Requerido",
//           style: TextStyle(color: Colors.white),
//         ),
//         content: const Text(
//           "Has denegado el acceso permanentemente. Para usar el gestor, ve a Configuración y activa 'Permitir acceso completo'.",
//           style: TextStyle(color: Colors.white70),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text(
//               "CANCELAR",
//               style: TextStyle(color: Colors.white54),
//             ),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.greenAccent,
//             ),
//             onPressed: () {
//               Navigator.pop(context);
//               openAppSettings();
//             },
//             child: const Text(
//               "IR A AJUSTES",
//               style: TextStyle(
//                 color: Colors.black,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // 2. Configurar carpeta raíz
//   Future<void> _ejecutarLogicaCarpeta() async {
//     try {
//       Directory? baseDir = Directory('/storage/emulated/0');
//       final carpetaCalipso = Directory('${baseDir.path}/CALIPSO');

//       if (!await carpetaCalipso.exists()) {
//         await carpetaCalipso.create(recursive: true);
//       }

//       if (mounted) {
//         setState(() {
//           _rutaActual = carpetaCalipso.path;
//           _historialRutas.clear();
//           _cargando = false;
//         });
//         _listarArchivos();
//       }
//     } catch (e) {
//       debugPrint("Carpeta no accesible: $e");
//       if (mounted) setState(() => _cargando = false);
//     }
//   }

//   // 3. Listar archivos
//   Future<void> _listarArchivos() async {
//     setState(() => _cargando = true);
//     try {
//       final directorio = Directory(_rutaActual);
//       if (await directorio.exists()) {
//         final contenido = directorio.listSync();
//         setState(() {
//           _archivos = contenido.toList();
//           _archivos.sort((a, b) {
//             final aIsDir = a is Directory;
//             final bIsDir = b is Directory;
//             if (aIsDir && !bIsDir) return -1;
//             if (!aIsDir && bIsDir) return 1;
//             if (aIsDir && bIsDir)
//               return a.path.toLowerCase().compareTo(b.path.toLowerCase());
//             return b.statSync().modified.compareTo(a.statSync().modified);
//           });
//           _cargando = false;
//         });
//       }
//     } catch (e) {
//       setState(() => _cargando = false);
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error al leer carpeta: $e")));
//     }
//   }

//   // 4. Entrar a carpeta
//   void _entrarCarpeta(Directory carpeta) {
//     setState(() {
//       _historialRutas.add(_rutaActual);
//       _rutaActual = carpeta.path;
//     });
//     _listarArchivos();
//   }

//   // 5. Volver Atrás
//   void _volverAtras() {
//     if (_historialRutas.isNotEmpty) {
//       setState(() {
//         _rutaActual = _historialRutas.removeLast();
//       });
//       _listarArchivos();
//     } else {
//       if (_modoNavegacionDestino) {
//         _cancelarOperacion();
//       }
//     }
//   }

//   void _navegarARuta(String ruta) {
//     if (ruta != _rutaActual) {
//       setState(() {
//         _historialRutas.add(_rutaActual);
//         _rutaActual = ruta;
//       });
//       _listarArchivos();
//     }
//   }

//   // --- Lógica de Selección ---
//   void _alternarSeleccion(FileSystemEntity entidad) {
//     setState(() {
//       if (_entidadesParaMover.contains(entidad)) {
//         _entidadesParaMover.remove(entidad);
//       } else {
//         _entidadesParaMover.add(entidad);
//       }
//     });
//   }

//   // --- Compartir ---
//   Future<void> _compartirArchivo(FileSystemEntity entidad) async {
//     try {
//       if (await entidad.exists()) {
//         await Share.shareXFiles([
//           XFile(entidad.path),
//         ], subject: 'Compartiendo archivo');
//       } else {
//         if (mounted)
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text("El archivo no existe")));
//       }
//     } catch (e) {
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error al compartir: $e")));
//     }
//   }

//   Future<void> _compartirSeleccionados() async {
//     final archivos = _entidadesParaMover.whereType<File>().toList();
//     if (archivos.isEmpty) {
//       if (mounted)
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Solo se pueden compartir archivos")),
//         );
//       return;
//     }
//     try {
//       final xFiles = archivos.map((f) => XFile(f.path)).toList();
//       await Share.shareXFiles(xFiles, subject: 'Archivos compartidos');
//     } catch (e) {
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//   }

//   // --- Operaciones ---
//   void _iniciarOperacion(String operacion) {
//     if (_entidadesParaMover.isEmpty) return;
//     setState(() {
//       _modoEdicion = false;
//       _modoNavegacionDestino = true;
//       _operacionPendiente = operacion;
//     });
//     if (mounted)
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Navega y pulsa 'Pegar'"),
//           duration: Duration(seconds: 3),
//         ),
//       );
//   }

//   void _cancelarOperacion() {
//     setState(() {
//       _modoNavegacionDestino = false;
//       _modoEdicion = false;
//       _entidadesParaMover.clear();
//       _operacionPendiente = "";
//     });
//     _listarArchivos();
//   }

//   Future<void> _ejecutarOperacionEnDestino() async {
//     final destino = Directory(_rutaActual);

//     for (var item in _entidadesParaMover) {
//       if (item is Directory) {
//         final itemPathWithSlash =
//             item.path + (item.path.endsWith('/') ? '' : '/');
//         if (destino.path.startsWith(itemPathWithSlash)) {
//           if (mounted)
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text(
//                   "Error: No puedes mover una carpeta dentro de sí misma",
//                 ),
//               ),
//             );
//           return;
//         }
//       }
//     }

//     if (!mounted) return;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: const Color(0xFF1E1E1E),
//         content: Row(
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(width: 20),
//             Expanded(
//               child: Text(
//                 _operacionPendiente == 'copiar' ? "Copiando..." : "Moviendo...",
//                 style: const TextStyle(color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );

//     int errores = 0;
//     try {
//       for (var origen in _entidadesParaMover) {
//         final nombre = origen.path.split('/').last;
//         FileSystemEntity destinoFinal = origen is Directory
//             ? Directory('${destino.path}/$nombre')
//             : File('${destino.path}/$nombre');

//         try {
//           if (_operacionPendiente == 'copiar') {
//             await _copiarDirectorioOrArchivo(origen, destinoFinal);
//           } else {
//             try {
//               await origen.rename(destinoFinal.path);
//             } catch (e) {
//               await _copiarDirectorioOrArchivo(origen, destinoFinal);
//               await origen.delete(recursive: true);
//             }
//           }
//         } catch (e) {
//           debugPrint("Error: $e");
//           errores++;
//         }
//       }

//       if (mounted) Navigator.pop(context);
//       _cancelarOperacion();

//       if (mounted)
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               errores > 0 ? "Finalizado con errores" : "Operación exitosa",
//             ),
//           ),
//         );
//     } catch (e) {
//       if (mounted) {
//         Navigator.of(context).pop();
//         _cancelarOperacion();
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error: $e")));
//       }
//     }
//   }

//   Future<void> _copiarDirectorioOrArchivo(
//     FileSystemEntity source,
//     FileSystemEntity destination,
//   ) async {
//     if (source is File) {
//       await source.copy(destination.path);
//     } else if (source is Directory) {
//       if (!await destination.exists())
//         await (destination as Directory).create(recursive: true);
//       await for (var entity in source.list()) {
//         final newPath = entity is Directory
//             ? Directory('${destination.path}/${entity.path.split('/').last}')
//             : File('${destination.path}/${entity.path.split('/').last}');
//         await _copiarDirectorioOrArchivo(entity, newPath);
//       }
//     }
//   }

//   // --- Crear Carpeta ---
//   Future<void> _crearNuevaCarpeta() async {
//     final nombre = _nombreCarpetaController.text.trim();
//     if (nombre.isEmpty) return;
//     try {
//       final nuevaCarpeta = Directory('$_rutaActual/$nombre');
//       if (await nuevaCarpeta.exists()) {
//         if (mounted)
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text("La carpeta ya existe")));
//       } else {
//         await nuevaCarpeta.create(recursive: true);
//         if (mounted) Navigator.pop(context);
//         _nombreCarpetaController.clear();
//         _listarArchivos();
//         if (mounted)
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text("Carpeta creada")));
//       }
//     } catch (e) {
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error: $e")));
//     }
//   }

//   void _mostrarDialogoCrearCarpeta() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         title: Text(
//           "Nueva Carpeta",
//           style: TextStyle(color: isDark ? Colors.white : Colors.black),
//         ),
//         content: TextField(
//           controller: _nombreCarpetaController,
//           autofocus: true,
//           style: TextStyle(color: isDark ? Colors.white : Colors.black),
//           decoration: const InputDecoration(
//             hintText: "Nombre",
//             border: UnderlineInputBorder(),
//           ),
//           onSubmitted: (_) => _crearNuevaCarpeta(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancelar"),
//           ),
//           ElevatedButton(
//             onPressed: _crearNuevaCarpeta,
//             child: const Text("Crear"),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- Renombrar ---
//   Future<void> _renombrarEntidad(FileSystemEntity entidad) async {
//     final nombreViejo = entidad.path.split('/').last;
//     _renombrarController.text = nombreViejo;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         title: Text(
//           "Renombrar",
//           style: TextStyle(color: isDark ? Colors.white : Colors.black),
//         ),
//         content: TextField(
//           controller: _renombrarController,
//           decoration: const InputDecoration(hintText: "Nuevo nombre"),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancelar"),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               final nombreNuevo = _renombrarController.text.trim();
//               if (nombreNuevo.isEmpty) return;
//               try {
//                 await entidad.rename('${entidad.parent.path}/$nombreNuevo');
//                 if (mounted) Navigator.pop(context);
//                 _listarArchivos();
//               } catch (e) {
//                 if (mounted)
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(SnackBar(content: Text("Error: $e")));
//               }
//             },
//             child: const Text("Guardar"),
//           ),
//         ],
//       ),
//     );
//   }

//   // --- Detalles ---
//   void _verDetalles(FileSystemEntity entidad) async {
//     final stat = await entidad.stat();
//     final nombre = entidad.path.split('/').last;
//     final esCarpeta = entidad is Directory;
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     String tipo = esCarpeta ? "Carpeta" : nombre.split('.').last.toUpperCase();
//     String tamano = esCarpeta ? "-" : _formatBytes(stat.size);
//     if (esCarpeta) {
//       try {
//         tamano = "${(entidad as Directory).listSync().length} elementos";
//       } catch (e) {}
//     }
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//         title: Row(
//           children: [
//             Icon(
//               esCarpeta ? Icons.folder : Icons.insert_drive_file,
//               color: const Color(0xFF1A237E),
//             ),
//             const SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 nombre,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(color: isDark ? Colors.white : Colors.black),
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _detalleFila("Tipo:", tipo, isDark),
//             _detalleFila("Tamaño:", tamano, isDark),
//             _detalleFila("Ruta:", entidad.path, isDark),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("CERRAR"),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _detalleFila(String label, String value, bool isDark) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 60,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isDark ? Colors.white : Colors.black,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatBytes(int bytes, {int decimals = 2}) {
//     if (bytes <= 0) return "0 B";
//     const suffixes = ["B", "KB", "MB", "GB", "TB"];
//     var i = (math.log(bytes) / math.log(1024)).floor();
//     return ((bytes / math.pow(1024, i)).toStringAsFixed(decimals)) +
//         ' ' +
//         suffixes[i];
//   }

//   // --- ABRIR ARCHIVO ---
//   Future<void> _abrirArchivo(FileSystemEntity entidad) async {
//     try {
//       final result = await OpenFile.open(entidad.path);
//       if (result.type == ResultType.noAppToOpen) {
//         if (mounted)
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("No hay aplicación para abrir este archivo"),
//             ),
//           );
//       } else if (result.type == ResultType.permissionDenied) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Permiso denegado. Verifica ajustes."),
//             ),
//           );
//           _prepararCarpeta();
//         }
//       }
//     } catch (e) {
//       if (mounted)
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(SnackBar(content: Text("Error al abrir: $e")));
//     }
//   }

//   // --- MENÚS ---
//   void _mostrarMenu(DynamicItem item) {
//     final entidad = item.entidad;
//     final esCarpeta = entidad is Directory;
//     final RenderBox overlay =
//         Overlay.of(context).context.findRenderObject() as RenderBox;
//     showMenu(
//       context: context,
//       position: RelativeRect.fromRect(Rect.zero, Offset.zero & overlay.size),
//       items: [
//         if (!esCarpeta)
//           const PopupMenuItem(
//             value: 'abrir',
//             child: ListTile(
//               leading: Icon(Icons.open_in_new),
//               title: Text("Abrir"),
//               contentPadding: EdgeInsets.zero,
//             ),
//           ),
//         if (!esCarpeta)
//           const PopupMenuItem(
//             value: 'compartir',
//             child: ListTile(
//               leading: Icon(Icons.share),
//               title: Text("Compartir"),
//               contentPadding: EdgeInsets.zero,
//             ),
//           ),
//         const PopupMenuItem(
//           value: 'detalles',
//           child: ListTile(
//             leading: Icon(Icons.info_outline),
//             title: Text("Detalles"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         const PopupMenuItem(
//           value: 'renombrar',
//           child: ListTile(
//             leading: Icon(Icons.edit),
//             title: Text("Renombrar"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         const PopupMenuItem(
//           value: 'copiar',
//           child: ListTile(
//             leading: Icon(Icons.copy),
//             title: Text("Copiar a..."),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         const PopupMenuItem(
//           value: 'mover',
//           child: ListTile(
//             leading: Icon(Icons.drive_file_move),
//             title: Text("Mover a..."),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         const PopupMenuItem(
//           value: 'eliminar',
//           child: ListTile(
//             leading: Icon(Icons.delete, color: Colors.red),
//             title: Text("Eliminar"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//       ],
//     ).then((value) {
//       if (value == null) return;
//       switch (value) {
//         case 'abrir':
//           _abrirArchivo(entidad);
//           break;
//         case 'compartir':
//           _compartirArchivo(entidad);
//           break;
//         case 'detalles':
//           _verDetalles(entidad);
//           break;
//         case 'renombrar':
//           _renombrarEntidad(entidad);
//           break;
//         case 'copiar':
//           _entidadesParaMover.clear();
//           _entidadesParaMover.add(entidad);
//           _iniciarOperacion('copiar');
//           break;
//         case 'mover':
//           _entidadesParaMover.clear();
//           _entidadesParaMover.add(entidad);
//           _iniciarOperacion('mover');
//           break;
//         case 'eliminar':
//           _confirmarEliminarEntidad(entidad);
//           break;
//       }
//     });
//   }

//   void _confirmarEliminarEntidad(FileSystemEntity entidad) {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("¿Eliminar?"),
//         content: Text("¿Seguro de eliminar ${entidad.path.split('/').last}?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancelar"),
//           ),
//           TextButton(
//             onPressed: () {
//               try {
//                 entidad.deleteSync(recursive: true);
//                 if (mounted) Navigator.pop(context);
//                 _listarArchivos();
//                 if (mounted)
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(const SnackBar(content: Text("Eliminado")));
//               } catch (e) {
//                 if (mounted)
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(SnackBar(content: Text("Error: $e")));
//               }
//             },
//             child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   void _mostrarMenuSeleccion() {
//     final RenderBox overlay =
//         Overlay.of(context).context.findRenderObject() as RenderBox;
//     showMenu(
//       context: context,
//       position: RelativeRect.fromRect(Rect.zero, Offset.zero & overlay.size),
//       items: [
//         PopupMenuItem(
//           value: 'compartir',
//           child: ListTile(
//             leading: const Icon(Icons.share),
//             title: Text("Compartir selección"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         PopupMenuItem(
//           value: 'copiar',
//           child: ListTile(
//             leading: const Icon(Icons.copy),
//             title: Text("Copiar selección"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//         PopupMenuItem(
//           value: 'mover',
//           child: ListTile(
//             leading: const Icon(Icons.drive_file_move),
//             title: Text("Mover selección"),
//             contentPadding: EdgeInsets.zero,
//           ),
//         ),
//       ],
//     ).then((value) async {
//       if (value == null) return;
//       if (value == 'compartir')
//         await _compartirSeleccionados();
//       else
//         _iniciarOperacion(value);
//     });
//   }

//   void _mostrarInfoGestor() {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: isDark ? const Color(0xFF1A237E) : Colors.white,
//         title: Row(
//           children: [
//             Icon(
//               Icons.folder_shared,
//               color: isDark ? Colors.white : const Color(0xFF1A237E),
//             ),
//             const SizedBox(width: 10),
//             Text(
//               "Gestor CALIPSO",
//               style: TextStyle(color: isDark ? Colors.white : Colors.black),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Versión 2.8",
//               style: TextStyle(
//                 color: isDark ? Colors.white70 : Colors.black54,
//                 fontSize: 12,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               "Gestor optimizado con persistencia de permisos.",
//               style: TextStyle(color: isDark ? Colors.white : Colors.black87),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(
//               "CERRAR",
//               style: TextStyle(
//                 color: isDark ? Colors.greenAccent : const Color(0xFF1A237E),
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     List<String> partesRuta = _rutaActual
//         .split('/')
//         .where((p) => p.isNotEmpty)
//         .toList();
//     int calipsoIndex = partesRuta.indexOf('CALIPSO');
//     if (calipsoIndex != -1) {
//       partesRuta = partesRuta.sublist(calipsoIndex);
//     }

//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF0A0E12) : Colors.grey[100],
//       appBar: AppBar(
//         toolbarHeight: 70,
//         backgroundColor: _modoNavegacionDestino
//             ? Colors.orange
//             : const Color(0xFF1A237E),
//         foregroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(_modoNavegacionDestino ? Icons.close : Icons.arrow_back),
//           onPressed: () {
//             if (_modoNavegacionDestino && _historialRutas.isEmpty) {
//               _cancelarOperacion();
//             } else {
//               _volverAtras();
//             }
//           },
//         ),
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               _modoNavegacionDestino ? "ELIGE DESTINO" : "EXPLORADOR",
//               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//             ),
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   for (int i = 0; i < partesRuta.length; i++)
//                     InkWell(
//                       onTap: () {
//                         String rutaObjetivo = '/';
//                         List<String> fullPathParts = _rutaActual
//                             .split('/')
//                             .where((p) => p.isNotEmpty)
//                             .toList();
//                         int realIndex = fullPathParts.indexOf(partesRuta[i]);
//                         for (int k = 0; k <= realIndex; k++) {
//                           rutaObjetivo += '${fullPathParts[k]}/';
//                         }
//                         _navegarARuta(rutaObjetivo);
//                       },
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 4.0),
//                         child: Row(
//                           children: [
//                             Text(
//                               partesRuta[i],
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: i == partesRuta.length - 1
//                                     ? Colors.white
//                                     : Colors.white70,
//                                 fontWeight: i == partesRuta.length - 1
//                                     ? FontWeight.bold
//                                     : FontWeight.normal,
//                               ),
//                             ),
//                             if (i < partesRuta.length - 1)
//                               const Padding(
//                                 padding: EdgeInsets.symmetric(horizontal: 4),
//                                 child: Text(
//                                   "/",
//                                   style: TextStyle(
//                                     color: Colors.white54,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           if (_modoNavegacionDestino)
//             IconButton(
//               icon: const Icon(Icons.close),
//               onPressed: _cancelarOperacion,
//             )
//           else if (!_modoEdicion) ...[
//             IconButton(
//               icon: const Icon(Icons.check_box_outline_blank),
//               onPressed: () {
//                 setState(() {
//                   _modoEdicion = true;
//                   _entidadesParaMover.clear();
//                 });
//               },
//             ),
//             IconButton(
//               icon: const Icon(Icons.create_new_folder),
//               onPressed: _mostrarDialogoCrearCarpeta,
//             ),
//             IconButton(
//               icon: const Icon(Icons.refresh),
//               onPressed: _listarArchivos,
//             ),
//             IconButton(
//               icon: const Icon(Icons.info_outline),
//               tooltip: "Acerca del Gestor",
//               onPressed: _mostrarInfoGestor,
//             ),
//           ] else if (_modoEdicion && _entidadesParaMover.isNotEmpty)
//             IconButton(
//               icon: const Icon(Icons.more_vert),
//               onPressed: () => _mostrarMenuSeleccion(),
//             ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           _cargando
//               ? const Center(child: CircularProgressIndicator())
//               : _archivos.isEmpty
//               ? _buildSinArchivos(isDark)
//               : ListView.builder(
//                   padding: const EdgeInsets.only(bottom: 100.0),
//                   itemCount: _archivos.length,
//                   itemBuilder: (context, index) {
//                     final entidad = _archivos[index];
//                     final nombre = entidad.path.split('/').last;
//                     final esCarpeta = entidad is Directory;
//                     final estaSeleccionado = _entidadesParaMover.contains(
//                       entidad,
//                     );
//                     final esOrigenEnMovimiento =
//                         _modoNavegacionDestino &&
//                         _entidadesParaMover.contains(entidad);

//                     IconData icono = Icons.insert_drive_file;
//                     Color colorIcono = Colors.blueGrey;
//                     if (esCarpeta) {
//                       icono = Icons.folder;
//                       colorIcono = esOrigenEnMovimiento
//                           ? Colors.orange
//                           : Colors.amber;
//                     } else if (nombre.endsWith('.pdf')) {
//                       icono = Icons.picture_as_pdf;
//                       colorIcono = Colors.red;
//                     } else if (nombre.endsWith('.xlsx') ||
//                         nombre.endsWith('.xls')) {
//                       icono = Icons.table_chart;
//                       colorIcono = Colors.green;
//                     } else if (nombre.endsWith('.jpg') ||
//                         nombre.endsWith('.png')) {
//                       icono = Icons.image;
//                       colorIcono = Colors.orange;
//                     }

//                     return Container(
//                       margin: const EdgeInsets.symmetric(
//                         vertical: 2.0,
//                         horizontal: 8.0,
//                       ),
//                       decoration: BoxDecoration(
//                         color: estaSeleccionado
//                             ? const Color(0xFF2196F3)
//                             : (esOrigenEnMovimiento
//                                   ? const Color(0xFFFF9800)
//                                   : (isDark
//                                         ? const Color(0xFF212121)
//                                         : Colors.white)),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: ListTile(
//                         dense: true,
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 10.0,
//                         ),
//                         leading: _modoEdicion
//                             ? Checkbox(
//                                 value: estaSeleccionado,
//                                 onChanged: (_) => _alternarSeleccion(entidad),
//                                 activeColor: Colors.blue,
//                               )
//                             : Icon(icono, color: colorIcono),
//                         title: Text(
//                           nombre,
//                           style: TextStyle(
//                             color: isDark ? Colors.white : Colors.black,
//                             fontSize: 14,
//                             fontWeight: (esCarpeta || estaSeleccionado)
//                                 ? FontWeight.bold
//                                 : FontWeight.normal,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         subtitle: esCarpeta
//                             ? Text(
//                                 esOrigenEnMovimiento
//                                     ? "(Seleccionado)"
//                                     : "Carpeta",
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               )
//                             : Text(
//                                 "Modificado: ${(entidad as File).statSync().modified.toString().split('.')[0]}",
//                                 style: const TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.grey,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                         trailing: _modoEdicion
//                             ? null
//                             : (!_modoNavegacionDestino
//                                   ? IconButton(
//                                       icon: const Icon(
//                                         Icons.more_vert,
//                                         color: Colors.blueGrey,
//                                         size: 20,
//                                       ),
//                                       onPressed: () => _mostrarMenu(
//                                         DynamicItem(entidad: entidad),
//                                       ),
//                                       padding: EdgeInsets.zero,
//                                     )
//                                   : null),
//                         onTap: () {
//                           if (_modoEdicion) {
//                             _alternarSeleccion(entidad);
//                           } else if (_modoNavegacionDestino) {
//                             if (esCarpeta && !esOrigenEnMovimiento)
//                               _entrarCarpeta(entidad as Directory);
//                           } else {
//                             if (esCarpeta)
//                               _entrarCarpeta(entidad as Directory);
//                             else
//                               _abrirArchivo(entidad);
//                           }
//                         },
//                         onLongPress: () {
//                           if (!_modoNavegacionDestino && !_modoEdicion) {
//                             setState(() {
//                               _modoEdicion = true;
//                               _alternarSeleccion(entidad);
//                             });
//                           }
//                         },
//                       ),
//                     );
//                   },
//                 ),
//           if (_modoNavegacionDestino)
//             Positioned(
//               bottom: 20,
//               left: 20,
//               right: 20,
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: FloatingActionButton.extended(
//                       heroTag: "btn_cancel",
//                       onPressed: _cancelarOperacion,
//                       backgroundColor: Colors.grey,
//                       icon: const Icon(Icons.close, color: Colors.white),
//                       label: const Text(
//                         "CANCELAR",
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: FloatingActionButton.extended(
//                       heroTag: "btn_paste",
//                       onPressed: _ejecutarOperacionEnDestino,
//                       backgroundColor: Colors.orange,
//                       icon: const Icon(Icons.paste, color: Colors.white),
//                       label: Text(
//                         "PEGAR AQUÍ (${_entidadesParaMover.length})",
//                         style: const TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSinArchivos(bool isDark) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.folder_open,
//             size: 80,
//             color: isDark ? Colors.white24 : Colors.grey,
//           ),
//           const SizedBox(height: 10),
//           Text(
//             _modoNavegacionDestino ? "Carpeta vacía" : "Carpeta vacía",
//             style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
//           ),
//           const SizedBox(height: 5),
//           if (!_modoNavegacionDestino)
//             Text(
//               "Usa el botón + para crear carpetas",
//               style: TextStyle(
//                 fontSize: 12,
//                 color: isDark ? Colors.white38 : Colors.grey,
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class DynamicItem {
//   final FileSystemEntity entidad;
//   DynamicItem({required this.entidad});
// }

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArchivosPage extends StatefulWidget {
  const ArchivosPage({super.key});

  @override
  State<ArchivosPage> createState() => _ArchivosPageState();
}

class _ArchivosPageState extends State<ArchivosPage> {
  List<FileSystemEntity> _archivos = [];
  bool _cargando = true;

  // Navegación
  String _rutaActual = "";
  final List<String> _historialRutas = [];

  // Controladores
  final TextEditingController _nombreCarpetaController =
      TextEditingController();
  final TextEditingController _renombrarController = TextEditingController();

  // Variables para Modo Selección
  bool _modoNavegacionDestino = false;
  final List<FileSystemEntity> _entidadesParaMover = [];
  String _operacionPendiente = "";

  bool _modoEdicion = false;

  @override
  void initState() {
    super.initState();
    _prepararCarpeta();
  }

  // 1. Pedir permisos con Persistencia y Validación
  Future<void> _prepararCarpeta() async {
    final prefs = await SharedPreferences.getInstance();

    // Verificar estado ACTUAL del permiso
    var status = await Permission.manageExternalStorage.status;

    // CASO A: Ya tenemos permiso garantizado -> Ejecutar lógica normal
    if (status.isGranted) {
      _ejecutarLogicaCarpeta();
      return;
    }

    // CASO B: No tenemos permiso. ¿Ya preguntamos antes?
    final bool permisoYaPedido =
        prefs.getBool('permiso_pedido_calipso') ?? false;

    if (!permisoYaPedido) {
      // Es la PRIMERA vez que entramos (o se borraron los datos). Mostrar Alerta Informativa.
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A237E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.folder_special, color: Colors.greenAccent, size: 28),
              SizedBox(width: 10),
              Text(
                "Acceso a Archivos",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Para abrir archivos con permiso de edición, crear carpetas y gestionar documentos libremente en CALIPSO, es necesario conceder acceso completo al almacenamiento.",
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Guardar que ya vimos la alerta
                await prefs.setBool('permiso_pedido_calipso', true);
                // Cargar igual (aunque probablemente vacío)
                _ejecutarLogicaCarpeta();
              },
              child: const Text(
                "MÁS TARDE",
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                // Guardar que intentamos pedir permiso
                await prefs.setBool('permiso_pedido_calipso', true);

                // Pedir permiso real
                final result = await Permission.manageExternalStorage.request();
                if (result.isGranted) {
                  _ejecutarLogicaCarpeta();
                } else if (result.isPermanentlyDenied) {
                  if (mounted) _mostrarDialogoSettings();
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Permiso denegado.")),
                    );
                    _ejecutarLogicaCarpeta();
                  }
                }
              },
              child: const Text(
                "PERMITIR AHORA",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // CASO C: El usuario ya vio la alerta antes ("Más Tarde"), pero NO tiene permiso.
      // Intentamos pedirlo silenciosamente al cargar. Si lo acepta en ajustes, funcionará.
      // Si sigue sin permiso, cargamos la app vacía sin molestar.
      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) {
        _ejecutarLogicaCarpeta();
      } else {
        // Si no se concede, cargamos la carpeta (probablemente fallará o estará vacía, pero no interrumpimos)
        _ejecutarLogicaCarpeta();
      }
    }
  }

  // Diálogo para ir a ajustes si el permiso fue denegado permanentemente
  void _mostrarDialogoSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          "Acceso Requerido",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Has denegado el acceso permanentemente. Para usar el gestor, ve a Configuración y activa 'Permitir acceso completo'.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text(
              "IR A AJUSTES",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Configurar carpeta raíz
  Future<void> _ejecutarLogicaCarpeta() async {
    try {
      Directory? baseDir = Directory('/storage/emulated/0');
      final carpetaCalipso = Directory('${baseDir.path}/CALIPSO');

      if (!await carpetaCalipso.exists()) {
        await carpetaCalipso.create(recursive: true);
      }

      if (mounted) {
        setState(() {
          _rutaActual = carpetaCalipso.path;
          _historialRutas.clear();
          _cargando = false;
        });
        _listarArchivos();
      }
    } catch (e) {
      debugPrint("Carpeta no accesible: $e");
      if (mounted) setState(() => _cargando = false);
    }
  }

  // 3. Listar archivos
  Future<void> _listarArchivos() async {
    setState(() => _cargando = true);
    try {
      final directorio = Directory(_rutaActual);
      if (await directorio.exists()) {
        final contenido = directorio.listSync();
        setState(() {
          _archivos = contenido.toList();
          _archivos.sort((a, b) {
            final aIsDir = a is Directory;
            final bIsDir = b is Directory;
            if (aIsDir && !bIsDir) return -1;
            if (!aIsDir && bIsDir) return 1;
            if (aIsDir && bIsDir)
              return a.path.toLowerCase().compareTo(b.path.toLowerCase());
            return b.statSync().modified.compareTo(a.statSync().modified);
          });
          _cargando = false;
        });
      }
    } catch (e) {
      setState(() => _cargando = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al leer carpeta: $e")));
    }
  }

  // 4. Entrar a carpeta
  void _entrarCarpeta(Directory carpeta) {
    setState(() {
      _historialRutas.add(_rutaActual);
      _rutaActual = carpeta.path;
    });
    _listarArchivos();
  }

  // 5. Volver Atrás
  void _volverAtras() {
    if (_historialRutas.isNotEmpty) {
      setState(() {
        _rutaActual = _historialRutas.removeLast();
      });
      _listarArchivos();
    } else {
      if (_modoNavegacionDestino) {
        _cancelarOperacion();
      }
    }
  }

  void _navegarARuta(String ruta) {
    if (ruta != _rutaActual) {
      setState(() {
        _historialRutas.add(_rutaActual);
        _rutaActual = ruta;
      });
      _listarArchivos();
    }
  }

  // --- Lógica de Selección ---
  void _alternarSeleccion(FileSystemEntity entidad) {
    setState(() {
      if (_entidadesParaMover.contains(entidad)) {
        _entidadesParaMover.remove(entidad);
      } else {
        _entidadesParaMover.add(entidad);
      }
    });
  }

  void _salirModoEdicion() {
    setState(() {
      _modoEdicion = false;
      _entidadesParaMover.clear();
    });
  }

  // --- Compartir ---
  Future<void> _compartirArchivo(FileSystemEntity entidad) async {
    try {
      if (await entidad.exists()) {
        await Share.shareXFiles([
          XFile(entidad.path),
        ], subject: 'Compartiendo archivo');
      } else {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("El archivo no existe")));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al compartir: $e")));
    }
  }

  Future<void> _compartirSeleccionados() async {
    final archivos = _entidadesParaMover.whereType<File>().toList();
    if (archivos.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Solo se pueden compartir archivos")),
        );
      return;
    }
    try {
      final xFiles = archivos.map((f) => XFile(f.path)).toList();
      await Share.shareXFiles(xFiles, subject: 'Archivos compartidos');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- Operaciones ---
  void _iniciarOperacion(String operacion) {
    if (_entidadesParaMover.isEmpty) return;
    setState(() {
      _modoEdicion = false;
      _modoNavegacionDestino = true;
      _operacionPendiente = operacion;
    });
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Navega y pulsa 'Pegar'"),
          duration: Duration(seconds: 3),
        ),
      );
  }

  void _cancelarOperacion() {
    setState(() {
      _modoNavegacionDestino = false;
      _modoEdicion = false;
      _entidadesParaMover.clear();
      _operacionPendiente = "";
    });
    _listarArchivos();
  }

  Future<void> _ejecutarOperacionEnDestino() async {
    final destino = Directory(_rutaActual);

    for (var item in _entidadesParaMover) {
      if (item is Directory) {
        final itemPathWithSlash =
            item.path + (item.path.endsWith('/') ? '' : '/');
        if (destino.path.startsWith(itemPathWithSlash)) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Error: No puedes mover una carpeta dentro de sí misma",
                ),
              ),
            );
          return;
        }
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                _operacionPendiente == 'copiar' ? "Copiando..." : "Moviendo...",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    int errores = 0;
    try {
      for (var origen in _entidadesParaMover) {
        final nombre = origen.path.split('/').last;
        FileSystemEntity destinoFinal = origen is Directory
            ? Directory('${destino.path}/$nombre')
            : File('${destino.path}/$nombre');

        try {
          if (_operacionPendiente == 'copiar') {
            await _copiarDirectorioOrArchivo(origen, destinoFinal);
          } else {
            try {
              await origen.rename(destinoFinal.path);
            } catch (e) {
              await _copiarDirectorioOrArchivo(origen, destinoFinal);
              await origen.delete(recursive: true);
            }
          }
        } catch (e) {
          debugPrint("Error: $e");
          errores++;
        }
      }

      if (mounted) Navigator.pop(context);
      _cancelarOperacion();

      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errores > 0 ? "Finalizado con errores" : "Operación exitosa",
            ),
          ),
        );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _cancelarOperacion();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _copiarDirectorioOrArchivo(
    FileSystemEntity source,
    FileSystemEntity destination,
  ) async {
    if (source is File) {
      await source.copy(destination.path);
    } else if (source is Directory) {
      if (!await destination.exists())
        await (destination as Directory).create(recursive: true);
      await for (var entity in source.list()) {
        final newPath = entity is Directory
            ? Directory('${destination.path}/${entity.path.split('/').last}')
            : File('${destination.path}/${entity.path.split('/').last}');
        await _copiarDirectorioOrArchivo(entity, newPath);
      }
    }
  }

  // --- Crear Carpeta ---
  Future<void> _crearNuevaCarpeta() async {
    final nombre = _nombreCarpetaController.text.trim();
    if (nombre.isEmpty) return;
    try {
      final nuevaCarpeta = Directory('$_rutaActual/$nombre');
      if (await nuevaCarpeta.exists()) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("La carpeta ya existe")));
      } else {
        await nuevaCarpeta.create(recursive: true);
        if (mounted) Navigator.pop(context);
        _nombreCarpetaController.clear();
        _listarArchivos();
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Carpeta creada")));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _mostrarDialogoCrearCarpeta() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          "Nueva Carpeta",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: _nombreCarpetaController,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: const InputDecoration(
            hintText: "Nombre",
            border: UnderlineInputBorder(),
          ),
          onSubmitted: (_) => _crearNuevaCarpeta(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: _crearNuevaCarpeta,
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  // --- Renombrar ---
  Future<void> _renombrarEntidad(FileSystemEntity entidad) async {
    final nombreViejo = entidad.path.split('/').last;
    _renombrarController.text = nombreViejo;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          "Renombrar",
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: TextField(
          controller: _renombrarController,
          decoration: const InputDecoration(hintText: "Nuevo nombre"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombreNuevo = _renombrarController.text.trim();
              if (nombreNuevo.isEmpty) return;
              try {
                await entidad.rename('${entidad.parent.path}/$nombreNuevo');
                if (mounted) Navigator.pop(context);
                _listarArchivos();
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // --- Detalles ---
  void _verDetalles(FileSystemEntity entidad) async {
    final stat = await entidad.stat();
    final nombre = entidad.path.split('/').last;
    final esCarpeta = entidad is Directory;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String tipo = esCarpeta ? "Carpeta" : nombre.split('.').last.toUpperCase();
    String tamano = esCarpeta ? "-" : _formatBytes(stat.size);
    if (esCarpeta) {
      try {
        tamano = "${(entidad as Directory).listSync().length} elementos";
      } catch (e) {}
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Row(
          children: [
            Icon(
              esCarpeta ? Icons.folder : Icons.insert_drive_file,
              color: const Color(0xFF1A237E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                nombre,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detalleFila("Tipo:", tipo, isDark),
            _detalleFila("Tamaño:", tamano, isDark),
            _detalleFila("Ruta:", entidad.path, isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CERRAR"),
          ),
        ],
      ),
    );
  }

  Widget _detalleFila(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return ((bytes / math.pow(1024, i)).toStringAsFixed(decimals)) +
        ' ' +
        suffixes[i];
  }

  // --- ABRIR ARCHIVO ---
  Future<void> _abrirArchivo(FileSystemEntity entidad) async {
    try {
      final result = await OpenFile.open(entidad.path);
      if (result.type == ResultType.noAppToOpen) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No hay aplicación para abrir este archivo"),
            ),
          );
      } else if (result.type == ResultType.permissionDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Permiso denegado. Verifica ajustes."),
            ),
          );
          _prepararCarpeta();
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al abrir: $e")));
    }
  }

  // --- MENÚS (CORREGIDOS PARA PRECISIÓN) ---

  void _mostrarMenuEnPosicion(
    GlobalKey key,
    List<PopupMenuItem<String>> items,
    Function(String?) onSelected,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox button =
        key.currentContext!.findRenderObject() as RenderBox;

    final Offset offset = button.localToGlobal(Offset.zero);
    final Size size = button.size;

    // Menú alineado abajo y a la derecha del icono
    final position = RelativeRect.fromLTRB(
      offset.dx + size.width - 10,
      offset.dy + size.height,
      offset.dx + size.width + 10,
      offset.dy + size.height,
    );

    showMenu(
      context: context,
      position: position,
      items: items,
    ).then((value) => onSelected(value));
  }

  void _mostrarMenu(GlobalKey menuKey, FileSystemEntity entidad) {
    final esCarpeta = entidad is Directory;

    _mostrarMenuEnPosicion(
      menuKey,
      [
        if (!esCarpeta)
          const PopupMenuItem(
            value: 'abrir',
            child: ListTile(
              leading: Icon(Icons.open_in_new),
              title: Text("Abrir"),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (!esCarpeta)
          const PopupMenuItem(
            value: 'compartir',
            child: ListTile(
              leading: Icon(Icons.share),
              title: Text("Compartir"),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem(
          value: 'detalles',
          child: ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Detalles"),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'renombrar',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text("Renombrar"),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'copiar',
          child: ListTile(
            leading: Icon(Icons.copy),
            title: Text("Copiar a..."),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'mover',
          child: ListTile(
            leading: Icon(Icons.drive_file_move),
            title: Text("Mover a..."),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'eliminar',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text("Eliminar"),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      (value) {
        if (value == null) return;
        switch (value) {
          case 'abrir':
            _abrirArchivo(entidad);
            break;
          case 'compartir':
            _compartirArchivo(entidad);
            break;
          case 'detalles':
            _verDetalles(entidad);
            break;
          case 'renombrar':
            _renombrarEntidad(entidad);
            break;
          case 'copiar':
            _entidadesParaMover.clear();
            _entidadesParaMover.add(entidad);
            _iniciarOperacion('copiar');
            break;
          case 'mover':
            _entidadesParaMover.clear();
            _entidadesParaMover.add(entidad);
            _iniciarOperacion('mover');
            break;
          case 'eliminar':
            _confirmarEliminarEntidad(entidad);
            break;
        }
      },
    );
  }

  void _confirmarEliminarEntidad(FileSystemEntity entidad) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar?"),
        content: Text("¿Seguro de eliminar ${entidad.path.split('/').last}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              try {
                entidad.deleteSync(recursive: true);
                if (mounted) Navigator.pop(context);
                _listarArchivos();
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Eliminado")));
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- NUEVA FUNCIÓN: ELIMINAR SELECCIÓN MÚLTIPLE ---
  void _eliminarSeleccionados() {
    if (!mounted) return;
    final count = _entidadesParaMover.length;
    if (count == 0) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Eliminar selección?"),
        content: Text(
          "¿Seguro que deseas eliminar $count elementos seleccionados?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              int errores = 0;
              for (var item in _entidadesParaMover) {
                try {
                  item.deleteSync(recursive: true);
                } catch (e) {
                  errores++;
                }
              }
              _salirModoEdicion();
              _listarArchivos();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      errores > 0
                          ? "Eliminación finalizada con $errores errores"
                          : "Eliminación exitosa",
                    ),
                  ),
                );
              }
            },
            child: const Text(
              "ELIMINAR TODO",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarMenuSeleccion(GlobalKey menuKey) {
    _mostrarMenuEnPosicion(
      menuKey,
      [
        const PopupMenuItem(
          value: 'compartir',
          child: ListTile(
            leading: const Icon(Icons.share),
            title: Text("Compartir selección"),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'copiar',
          child: ListTile(
            leading: const Icon(Icons.copy),
            title: Text("Copiar selección"),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'mover',
          child: ListTile(
            leading: const Icon(Icons.drive_file_move),
            title: Text("Mover selección"),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'eliminar',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text("Eliminar selección"),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      (value) async {
        if (value == null) return;
        if (value == 'compartir')
          await _compartirSeleccionados();
        else if (value == 'eliminar')
          _eliminarSeleccionados();
        else
          _iniciarOperacion(value);
      },
    );
  }

  void _mostrarInfoGestor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A237E) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.folder_shared,
              color: isDark ? Colors.white : const Color(0xFF1A237E),
            ),
            const SizedBox(width: 10),
            Text(
              "Gestor CALIPSO",
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Versión 2.8",
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Gestor optimizado con persistencia de permisos.",
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CERRAR",
              style: TextStyle(
                color: isDark ? Colors.greenAccent : const Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<String> partesRuta = _rutaActual
        .split('/')
        .where((p) => p.isNotEmpty)
        .toList();
    int calipsoIndex = partesRuta.indexOf('CALIPSO');
    if (calipsoIndex != -1) {
      partesRuta = partesRuta.sublist(calipsoIndex);
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E12) : Colors.grey[100],
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: _modoNavegacionDestino
            ? Colors.orange
            : const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(_modoNavegacionDestino ? Icons.close : Icons.arrow_back),
          onPressed: () {
            if (_modoNavegacionDestino && _historialRutas.isEmpty) {
              _cancelarOperacion();
            } else {
              _volverAtras();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _modoNavegacionDestino ? "ELIGE DESTINO" : "EXPLORADOR",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < partesRuta.length; i++)
                    InkWell(
                      onTap: () {
                        String rutaObjetivo = '/';
                        List<String> fullPathParts = _rutaActual
                            .split('/')
                            .where((p) => p.isNotEmpty)
                            .toList();
                        int realIndex = fullPathParts.indexOf(partesRuta[i]);
                        for (int k = 0; k <= realIndex; k++) {
                          rutaObjetivo += '${fullPathParts[k]}/';
                        }
                        _navegarARuta(rutaObjetivo);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Text(
                              partesRuta[i],
                              style: TextStyle(
                                fontSize: 12,
                                color: i == partesRuta.length - 1
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: i == partesRuta.length - 1
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (i < partesRuta.length - 1)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  "/",
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_modoNavegacionDestino)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelarOperacion,
            )
          else if (!_modoEdicion) ...[
            IconButton(
              icon: const Icon(Icons.check_box_outline_blank),
              onPressed: () {
                setState(() {
                  _modoEdicion = true;
                  _entidadesParaMover.clear();
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.create_new_folder),
              onPressed: _mostrarDialogoCrearCarpeta,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _listarArchivos,
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: "Acerca del Gestor",
              onPressed: _mostrarInfoGestor,
            ),
          ] else if (_modoEdicion)
            // Botón X para salir del modo edición
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Cancelar selección",
              onPressed: _salirModoEdicion,
            ),
        ],
      ),
      body: Stack(
        children: [
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : _archivos.isEmpty
              ? _buildSinArchivos(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100.0),
                  itemCount: _archivos.length,
                  itemBuilder: (context, index) {
                    final entidad = _archivos[index];
                    final nombre = entidad.path.split('/').last;
                    final esCarpeta = entidad is Directory;
                    final estaSeleccionado = _entidadesParaMover.contains(
                      entidad,
                    );
                    final esOrigenEnMovimiento =
                        _modoNavegacionDestino &&
                        _entidadesParaMover.contains(entidad);

                    IconData icono = Icons.insert_drive_file;
                    Color colorIcono = Colors.blueGrey;
                    if (esCarpeta) {
                      icono = Icons.folder;
                      colorIcono = esOrigenEnMovimiento
                          ? Colors.orange
                          : Colors.amber;
                    } else if (nombre.endsWith('.pdf')) {
                      icono = Icons.picture_as_pdf;
                      colorIcono = Colors.red;
                    } else if (nombre.endsWith('.xlsx') ||
                        nombre.endsWith('.xls')) {
                      icono = Icons.table_chart;
                      colorIcono = Colors.green;
                    } else if (nombre.endsWith('.jpg') ||
                        nombre.endsWith('.png')) {
                      icono = Icons.image;
                      colorIcono = Colors.orange;
                    }

                    // Key única para cada menú
                    final menuKey = GlobalKey();
                    final seleccionMenuKey =
                        (index == 0 && _entidadesParaMover.isNotEmpty)
                        ? GlobalKey()
                        : null;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 2.0,
                        horizontal: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: estaSeleccionado
                            ? const Color(0xFF2196F3)
                            : (esOrigenEnMovimiento
                                  ? const Color(0xFFFF9800)
                                  : (isDark
                                        ? const Color(0xFF212121)
                                        : Colors.white)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        // Ajuste de padding para reducir el hueco entre el texto y el menú
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        leading: _modoEdicion
                            ? Checkbox(
                                value: estaSeleccionado,
                                onChanged: (_) => _alternarSeleccion(entidad),
                                activeColor: Colors.blue,
                              )
                            : Icon(icono, color: colorIcono),
                        title: Text(
                          nombre,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontSize: 14,
                            fontWeight: (esCarpeta || estaSeleccionado)
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: esCarpeta
                            ? Text(
                                esOrigenEnMovimiento
                                    ? "(Seleccionado)"
                                    : "Carpeta",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                "Modificado: ${(entidad as File).statSync().modified.toString().split('.')[0]}",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                        trailing: SizedBox(
                          width: 40, // Ancho fijo para el área del menú
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_modoEdicion &&
                                  index == 0 &&
                                  _entidadesParaMover.isNotEmpty)
                                GestureDetector(
                                  key: seleccionMenuKey,
                                  onTap: () =>
                                      _mostrarMenuSeleccion(seleccionMenuKey!),
                                  child: const Icon(
                                    Icons.more_vert,
                                    color: Colors.blueGrey,
                                    size: 25,
                                  ),
                                )
                              else if (!_modoEdicion && !_modoNavegacionDestino)
                                GestureDetector(
                                  key: menuKey,
                                  onTap: () {
                                    // onTap: Abre el menú
                                    _mostrarMenu(menuKey, entidad);
                                  },
                                  // Ajuste visual para que se sienta al lado
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                      4.0,
                                    ), // Padding interno del icono
                                    child: const Icon(
                                      Icons.more_vert,
                                      color: Colors.blueGrey,
                                      size: 25,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        onTap: () {
                          if (_modoEdicion) {
                            _alternarSeleccion(entidad);
                          } else if (_modoNavegacionDestino) {
                            if (esCarpeta && !esOrigenEnMovimiento)
                              _entrarCarpeta(entidad as Directory);
                          } else {
                            if (esCarpeta)
                              _entrarCarpeta(entidad as Directory);
                            else
                              _abrirArchivo(entidad);
                          }
                        },
                        onLongPress: () {
                          if (!_modoNavegacionDestino && !_modoEdicion) {
                            setState(() {
                              _modoEdicion = true;
                              _alternarSeleccion(entidad);
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
          if (_modoNavegacionDestino)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  Expanded(
                    child: FloatingActionButton.extended(
                      heroTag: "btn_cancel",
                      onPressed: _cancelarOperacion,
                      backgroundColor: Colors.grey,
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text(
                        "CANCELAR",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FloatingActionButton.extended(
                      heroTag: "btn_paste",
                      onPressed: _ejecutarOperacionEnDestino,
                      backgroundColor: Colors.orange,
                      icon: const Icon(Icons.paste, color: Colors.white),
                      label: Text(
                        "PEGAR AQUÍ (${_entidadesParaMover.length})",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSinArchivos(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: isDark ? Colors.white24 : Colors.grey,
          ),
          const SizedBox(height: 10),
          Text(
            _modoNavegacionDestino ? "Carpeta vacía" : "Carpeta vacía",
            style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
          ),
          const SizedBox(height: 5),
          if (!_modoNavegacionDestino)
            Text(
              "Usa el botón + para crear carpetas",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}

class DynamicItem {
  final FileSystemEntity entidad;
  DynamicItem({required this.entidad});
}
