// import 'dart:async';
// import 'dart:io';

// import 'package:excel/excel.dart' as ex;
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
// import 'package:peloton/SEGURIDAD/clase.dart';
// import 'package:peloton/provider/apptex.dart';
// import 'package:peloton/BD/db_manager.dart';
// import 'package:restart_app/restart_app.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:sqflite/sqflite.dart';

// class ConfiguracionScreen extends StatefulWidget {
//   const ConfiguracionScreen({super.key});

//   @override
//   State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
// }

// class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
//   final BackupService _backupService = BackupService();
//   bool _isProcessing = false;
//   String _processMessage = "";
//   Map<String, int>? _limpiezaResultados;

//   // Variables para controlar SOLO el diálogo del Respaldo Completo
//   bool _showCompleteDialog = false;
//   double _completeProgress = 0.0;
//   String _completeMessage = "Iniciando...";

//   // ========================================================================
//   // NUEVA FUNCIÓN: Dispara el diálogo moderno para el RESPALDO COMPLETO
//   // ========================================================================
//   Future<void> _iniciarRespaldoCompletoUI() async {
//     setState(() {
//       _showCompleteDialog = true;
//       _completeProgress = 0.0;
//       _completeMessage = "Preparando sistema...";
//     });

//     await _backupService.generarRespaldoCompleto(
//       onProgress: (porcentaje, mensaje) {
//         if (mounted) {
//           setState(() {
//             _completeProgress = porcentaje;
//             _completeMessage = mensaje;
//           });
//         }
//       },
//     );

//     if (mounted && _completeProgress >= 1.0) {
//       setState(() {
//         _completeMessage = "¡Completado! Seleccione dónde guardar el archivo.";
//       });
//     }
//   }

//   // ========================================================================
//   // ACCIÓN GENÉRICA (Para Respaldos Básicos y Limpieza)
//   // ========================================================================
//   Future<void> _ejecutarAccion(Function funcion, String mensaje) async {
//     setState(() {
//       _isProcessing = true;
//       _processMessage = mensaje;
//       _limpiezaResultados = null;
//     });

//     final resultado = await funcion();

//     if (mounted) {
//       setState(() {
//         _isProcessing = false;

//         if (resultado is bool && resultado) {
//           _processMessage = "$mensaje completado con éxito.";
//         } else if (resultado is Map) {
//           _processMessage = "Limpieza finalizada.";
//         } else {
//           if (_processMessage.contains("LÍMITE EXCEDIDO")) {
//             _processMessage = "Operación cancelada: Límite de 5 GB excedido.";
//           } else {
//             _processMessage = "Ocurrió un error al $mensaje.";
//           }
//         }
//       });
//     }
//   }

//   // ========================================================================
//   // RESPALDO DISPOSITIVO (EXTRACCIÓN OMNÍVORA: IMÁGENES, AUDIOS, DOCS + EXCELS)
//   // ========================================================================
//   Future<void> _respaldoDispositivo() async {
//     final _progressController = StreamController<String>.broadcast();

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return StreamBuilder<String>(
//           stream: _progressController.stream,
//           initialData: "Iniciando...|0.0%",
//           builder: (context, snapshot) {
//             final data = snapshot.data ?? "||";
//             final partes = data.split('|');
//             final mensaje = partes.isNotEmpty ? partes[0] : "";
//             final porcentajeTexto = partes.length > 1 ? partes[1] : "0.0%";
//             final porcentajeDouble =
//                 double.tryParse(porcentajeTexto.replaceAll('%', '')) ?? 0.0;
//             final isDark = Theme.of(context).brightness == Brightness.dark;

//             return AlertDialog(
//               backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               title: const Text(
//                 "Extracción Total de Data",
//                 textAlign: TextAlign.center,
//               ),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       SizedBox(
//                         width: 120,
//                         height: 120,
//                         child: CircularProgressIndicator(
//                           value: porcentajeDouble / 100.0,
//                           strokeWidth: 10,
//                           backgroundColor: isDark
//                               ? Colors.grey[800]
//                               : Colors.grey[300],
//                           valueColor: const AlwaysStoppedAnimation<Color>(
//                             Color(0xFF1A237E),
//                           ),
//                         ),
//                       ),
//                       Text(
//                         "${porcentajeDouble.toInt()}%",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                           color: isDark ? Colors.white : Colors.black87,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   Text(
//                     mensaje,
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: isDark ? Colors.grey[400] : Colors.grey[600],
//                     ),
//                     textAlign: TextAlign.center,
//                     maxLines: 3,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );

//     int countImagenes = 0;
//     int countAudios = 0;
//     int countDocs = 0;

//     try {
//       final userId = DBManager.instance.currentUserId;
//       if (userId == null) {
//         _progressController.add("Error: No hay sesión activa.|0.0%");
//         await Future.delayed(const Duration(seconds: 2));
//         if (mounted) Navigator.of(context).pop();
//         return;
//       }

//       String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
//         dialogTitle: "Seleccione dónde guardar la copia",
//       );
//       if (selectedDirectory == null) {
//         await _progressController.close();
//         if (mounted) Navigator.of(context).pop();
//         return;
//       }

//       final destinoBaseDir = Directory(
//         p.join(selectedDirectory, 'RESPALDO_COMPLETO_USER_$userId'),
//       );
//       await destinoBaseDir.create(recursive: true);

//       // Creamos las 4 carpetas finales
//       final carpetaImagenes = Directory(
//         p.join(destinoBaseDir.path, 'IMAGENES'),
//       );
//       final carpetaAudios = Directory(p.join(destinoBaseDir.path, 'AUDIOS'));
//       final carpetaDocs = Directory(p.join(destinoBaseDir.path, 'DOCUMENTOS'));
//       final carpetaExcels = Directory(
//         p.join(destinoBaseDir.path, 'BASES_DE_DATOS_EXCEL'),
//       );

//       await carpetaImagenes.create(recursive: true);
//       await carpetaAudios.create(recursive: true);
//       await carpetaDocs.create(recursive: true);
//       await carpetaExcels.create(recursive: true);

//       final db = await DBManager.instance.database;

//       final tablasParaExportar = [
//         'minutas',
//         'inteligencia',
//         'operacional',
//         'armamento',
//         'inventario_armamento',
//         'comunicaciones',
//         'expediente',
//         'inventario_especial',
//         'inventario_miras',
//         'intendencia',
//         'personal',
//         'exde',
//       ];

//       double progresoBase = 0.0;
//       double incrementoPorTabla = 85.0 / tablasParaExportar.length;

//       for (String nombreTabla in tablasParaExportar) {
//         _progressController.add(
//           "Procesando: $nombreTabla...|${progresoBase.toStringAsFixed(1)}%",
//         );

//         try {
//           final columnasResult = await db.rawQuery(
//             "PRAGMA table_info($nombreTabla)",
//           );
//           List<String> nombresColumnas = columnasResult
//               .map((col) => col['name'] as String)
//               .toList();
//           if (nombresColumnas.isEmpty) continue;

//           final registros = await db.query(nombreTabla);
//           if (registros.isEmpty) continue;

//           var excel = ex.Excel.createExcel();
//           String nombreHoja = nombreTabla.length > 31
//               ? nombreTabla.substring(0, 31)
//               : nombreTabla;
//           ex.Sheet sheet = excel[nombreHoja];
//           if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

//           sheet.appendRow(
//             nombresColumnas.map((col) => ex.TextCellValue(col)).toList(),
//           );

//           for (var reg in registros) {
//             List<ex.CellValue> fila = [];
//             for (String col in nombresColumnas) {
//               var valor = reg[col];
//               if (valor == null) {
//                 fila.add(ex.TextCellValue(""));
//               } else if (valor is int) {
//                 fila.add(ex.IntCellValue(valor));
//               } else {
//                 String valStr = valor.toString().trim();
//                 fila.add(ex.TextCellValue(valStr));

//                 // ====================================================================
//                 // DETECCIÓN UNIVERSAL DE ARCHIVOS (FOTOS, AUDIOS, DOCS)
//                 // ====================================================================
//                 // Si el texto tiene comas, lo partimos (ej: adjuntos múltiples)
//                 List<String> posiblesRutas = valStr.split(',');

//                 for (String posibleRuta in posiblesRutas) {
//                   posibleRuta = posibleRuta.trim();
//                   if (!posibleRuta.startsWith('/'))
//                     continue; // Descartamos texto normal

//                   File archivoOriginal = File(posibleRuta);
//                   if (!await archivoOriginal.exists()) continue;

//                   String extension = p.extension(posibleRuta).toLowerCase();
//                   String nombreArchivo = p.basename(posibleRuta);

//                   // Prevenimos que dos tablas se pisen un archivo con el mismo nombre
//                   String destinoFinal = p.join(
//                     carpetaDocs.path,
//                     nombreArchivo,
//                   ); // Por defecto

//                   if ([
//                     '.jpg',
//                     '.jpeg',
//                     '.png',
//                     '.webp',
//                     '.gif',
//                   ].contains(extension)) {
//                     destinoFinal = p.join(
//                       carpetaImagenes.path,
//                       "${nombreTabla}_$nombreArchivo",
//                     );
//                     countImagenes++;
//                   } else if ([
//                     '.mp3',
//                     '.wav',
//                     '.m4a',
//                     '.aac',
//                     '.ogg',
//                     '.amr',
//                   ].contains(extension)) {
//                     destinoFinal = p.join(
//                       carpetaAudios.path,
//                       "${nombreTabla}_$nombreArchivo",
//                     );
//                     countAudios++;
//                   } else if ([
//                     '.pdf',
//                     '.xls',
//                     '.xlsx',
//                     '.doc',
//                     '.docx',
//                     '.csv',
//                   ].contains(extension)) {
//                     destinoFinal = p.join(
//                       carpetaDocs.path,
//                       "${nombreTabla}_$nombreArchivo",
//                     );
//                     countDocs++;
//                   } else {
//                     continue; // Si es otra extensión rara, no lo copiamos
//                   }

//                   await archivoOriginal.copy(destinoFinal);
//                 }
//               }
//             }
//             sheet.appendRow(fila);
//           }

//           var fileBytes = excel.encode();
//           if (fileBytes != null) {
//             File excelFile = File(
//               p.join(carpetaExcels.path, '${nombreTabla.toUpperCase()}.xlsx'),
//             );
//             await excelFile.writeAsBytes(fileBytes, flush: true);
//           }
//         } catch (e) {
//           debugPrint("Error procesando $nombreTabla: $e");
//         }

//         progresoBase += incrementoPorTabla;
//       }

//       // ====================================================================
//       // FASE FINAL: CACHE TEMPORAL (Audios/Excel/PDFs sueltos sin ruta en BD)
//       // ====================================================================
//       _progressController.add(
//         "Buscando audios/docs en caché temporal...|95.0%",
//       );
//       String rutaCache = "";
//       try {
//         final temp = await getTemporaryDirectory();
//         rutaCache = p.join(temp.path, '..', 'cache');
//       } catch (_) {}

//       if (rutaCache.isNotEmpty) {
//         final dirCache = Directory(rutaCache);
//         if (await dirCache.exists()) {
//           List<File> archivosCache = await dirCache
//               .list(recursive: true, followLinks: true)
//               .where((e) => e is File)
//               .cast<File>()
//               .toList();
//           for (var archivo in archivosCache) {
//             final ext = p.extension(archivo.path).toLowerCase();
//             final nombre = p.basename(archivo.path);

//             if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
//               await archivo.copy(p.join(carpetaImagenes.path, "CACHE_$nombre"));
//               countImagenes++;
//             } else if (['.mp3', '.wav', '.m4a', '.aac'].contains(ext)) {
//               await archivo.copy(p.join(carpetaAudios.path, "CACHE_$nombre"));
//               countAudios++;
//             } else if ([
//               '.pdf',
//               '.xlsx',
//               '.xls',
//               '.csv',
//               '.doc',
//               '.docx',
//             ].contains(ext)) {
//               await archivo.copy(p.join(carpetaDocs.path, "CACHE_$nombre"));
//               countDocs++;
//             }
//           }
//         }
//       }

//       // ====================================================================
//       // FIN
//       // ====================================================================
//       _progressController.add("¡Extracción Completada!|100.0%");
//       await Future.delayed(const Duration(milliseconds: 1500));

//       if (mounted) {
//         Navigator.of(context).pop();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "✅ Respaldo Total Exitoso:\n\n"
//               "📁 12 Excels generados.\n"
//               "🖼️ $countImagenes Imágenes extraídas.\n"
//               "🎵 $countAudios Audios extraídos.\n"
//               "📄 $countDocs Documentos extraídos.",
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 7),
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint("❌ Error crítico: $e");
//       _progressController.add("Error crítico: $e|0.0%");
//       await Future.delayed(const Duration(seconds: 3));
//       if (mounted) Navigator.of(context).pop();
//     } finally {
//       await _progressController.close();
//     }
//   } // FUNCIÓN AUXILIAR (Mejorada con progreso matemático real)

//   // ========================================================================
//   Future<void> _procesarYCopiarArchivo(
//     String ruta,
//     Directory destImg,
//     Directory destAud,
//     Directory destDoc,
//     StreamController<String> progress, {
//     required int totalProcesados,
//     required int totalEncontrados,
//     Function(String tipo)? sumarContadores,
//   }) async {
//     final archivo = File(ruta);
//     if (!await archivo.exists()) return;

//     final extension = ruta.split('.').last.toLowerCase();
//     String nombre = p.basename(archivo.path);
//     Directory destino = destDoc;
//     String tipo = 'doc';

//     if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
//       destino = destImg;
//       tipo = 'img';
//     } else if (['mp3', 'wav', 'm4a', 'aac', 'ogg', 'amr'].contains(extension)) {
//       destino = destAud;
//       tipo = 'aud';
//     } else if (![
//       'pdf',
//       'xls',
//       'xlsx',
//       'doc',
//       'docx',
//       'csv',
//     ].contains(extension)) {
//       return;
//     }

//     // Calcula el porcentaje real basado en los archivos copiados
//     double progresoReal = (totalProcesados / totalEncontrados) * 100;
//     // Limitar entre 10% y 95% (el 100% se pone al final del todo)
//     if (progresoReal < 10) progresoReal = 10;
//     if (progresoReal > 95) progresoReal = 95;

//     progress.add(
//       "Copiando ($totalProcesados/$totalEncontrados): $nombre|${progresoReal.toStringAsFixed(1)}%",
//     );

//     String rutaFinal = p.join(destino.path, nombre);
//     int c = 1;
//     while (await File(rutaFinal).exists()) {
//       rutaFinal = p.join(
//         destino.path,
//         '${nombre.split('.')[0]}_($c).$extension',
//       );
//       c++;
//     }

//     await archivo.copy(rutaFinal);
//     if (sumarContadores != null) sumarContadores(tipo);
//   }

//   void _mostrarDialogoReinicioExitoso() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: Theme.of(context).cardColor,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         title: const Text("Restauración Completada"),
//         content: const Text(
//           "Los datos y la sesión fueron actualizados. La aplicación se reiniciará ahora para cargar el usuario del respaldo.",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Restart.restartApp(webOrigin: ""),
//             child: const Text(
//               "ACEPTAR",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _hacerEjercitoYReiniciar() async {
//     final confirmar = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Theme.of(context).cardColor,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         title: const Text("⚠️ ¿Eliminar toda la data?"),
//         content: const Text(
//           "Se vaciarán TODAS las tablas de inventario, minutas, inteligencia, etc. La app se reiniciará automáticamente.",
//           style: TextStyle(fontSize: 14),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("CANCELAR"),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text(
//               "SÍ, BORRAR TODO",
//               style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );

//     if (confirmar != true) return;

//     setState(() {
//       _isProcessing = true;
//       _processMessage = "Borrando datos de las tablas...";
//     });

//     try {
//       await DBManager.instance.limpiarTodaLaData();
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove('last_logged_user_id');
//       await prefs.setBool('mantener_sesion_activa', false);
//       await Future.delayed(const Duration(milliseconds: 500));
//       if (mounted) Restart.restartApp(webOrigin: "");
//     } catch (e) {
//       setState(() {
//         _isProcessing = false;
//         _processMessage = "Error al borrar: $e";
//       });
//     }
//   }

//   void _mostrarSnackBarError(String mensaje) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         backgroundColor: Colors.redAccent,
//         content: Text(mensaje, style: const TextStyle(color: Colors.white)),
//         duration: const Duration(seconds: 4),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = AppStyles.isDark(context);

//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
//       appBar: AppBar(
//         title: const Text(
//           "SISTEMA DE RESPALDOS",
//           style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
//         ),
//         backgroundColor: const Color(0xFF1A237E),
//         foregroundColor: Colors.white,
//         centerTitle: true,
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: 10),
//                 _sectionTitle("CREAR RESPALDO"),
//                 const SizedBox(height: 15),
//                 _actionCard(
//                   icon: Icons.abc,
//                   title: "Respaldo Básico",
//                   description:
//                       "Genera un archivo .ZIP únicamente con las Bases de Datos. Peso mínimo.",
//                   color: Colors.blue.shade700,
//                   onTap: _isProcessing
//                       ? null
//                       : () => _ejecutarAccion(
//                           _backupService.generarRespaldoBasico,
//                           "Respaldo Básico",
//                         ),
//                 ),
//                 const SizedBox(height: 15),
//                 _actionCard(
//                   icon: Icons.backup,
//                   title: "Respaldo COMPLETO",
//                   description:
//                       "Genera un archivo .ZIP con las Bases de Datos + TODAS las fotografías y medios guardados.",
//                   color: Colors.green.shade800,
//                   onTap: (_isProcessing || _showCompleteDialog)
//                       ? null
//                       : _iniciarRespaldoCompletoUI,
//                 ),
//                 const SizedBox(height: 40),
//                 _sectionTitle("COPIA DE SEGURIDAD EXTERNA"),
//                 const SizedBox(height: 15),
//                 _actionCard(
//                   icon: Icons.folder_copy,
//                   title: "Extraer a Carpeta (Dispositivo)",
//                   description:
//                       "Copia todas las imágenes, audios y documentos registrados en tu BD a una carpeta seleccionada sin comprimir.",
//                   color: Colors.orange.shade800,
//                   onTap: _isProcessing ? null : _respaldoDispositivo,
//                 ),
//                 const SizedBox(height: 40),
//                 _sectionTitle("MANTENIMIENTO Y LIMPIEZA"),
//                 const SizedBox(height: 15),
//                 _actionCard(
//                   icon: Icons.delete_forever,
//                   title: "Hacer Ejército (Borrar Tablas)",
//                   description:
//                       "Elimina TODOS los registros de inventario, personal, minutas, etc. La app se reiniciará automáticamente.",
//                   color: Colors.red.shade900,
//                   onTap: _isProcessing ? null : _hacerEjercitoYReiniciar,
//                 ),
//                 const SizedBox(height: 15),
//                 _actionCard(
//                   icon: Icons.cleaning_services_rounded,
//                   title: "Eliminar Residuos y Huérfanos",
//                   description:
//                       "Borra archivos temporales (Excels/PDFs viejos) y fotos que ya no están registradas en la base de datos.",
//                   color: Colors.red.shade700,
//                   onTap: _isProcessing
//                       ? null
//                       : () async {
//                           setState(() => _isProcessing = true);
//                           final resultados = await _backupService
//                               .limpiarResiduos();
//                           setState(() {
//                             _isProcessing = false;
//                             _limpiezaResultados = resultados;
//                             _processMessage = "Limpieza finalizada.";
//                           });
//                         },
//                 ),
//                 if (_limpiezaResultados != null) ...[
//                   const SizedBox(height: 15),
//                   Container(
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: isDark ? Colors.grey[900] : Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.green),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "Reporte de Limpieza:",
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green[700],
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           "• Archivos temporales eliminados: ${_limpiezaResultados!['temporales']}",
//                         ),
//                         Text(
//                           "• Fotos huérfanas eliminadas: ${_limpiezaResultados!['huerfanos']}",
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//                 const SizedBox(height: 80),
//               ],
//             ),
//           ),

//           // --- DIÁLOGO MODERNO CON PORCENTAJE (SOLO PARA RESPALDO COMPLETO) ---
//           if (_showCompleteDialog) _buildModernProgressDialog(isDark),

//           // --- INDICADOR DE CARGA GENÉRICO ---
//           if (_isProcessing && !_showCompleteDialog)
//             Container(
//               color: Colors.black.withOpacity(0.6),
//               child: Center(
//                 child: Card(
//                   elevation: 10,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(16),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(24.0),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         const CircularProgressIndicator(),
//                         const SizedBox(height: 20),
//                         Text(
//                           _processMessage,
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   // ========================================================================
//   // WIDGET DEL DIÁLOGO MODERNO COMPLETADO (Aquí estaba el corte)
//   // ========================================================================
//   Widget _buildModernProgressDialog(bool isDark) {
//     final esError = _completeProgress < 0;
//     final porcentajeTexto = (_completeProgress * 100).toInt();

//     return Container(
//       color: Colors.black.withOpacity(0.8),
//       child: Center(
//         child: Material(
//           color: Colors.transparent,
//           child: Container(
//             width: MediaQuery.of(context).size.width * 0.85,
//             padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
//             decoration: BoxDecoration(
//               color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//               borderRadius: BorderRadius.circular(24),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(isDark ? 0.6 : 0.2),
//                   blurRadius: 25,
//                   spreadRadius: 2,
//                 ),
//               ],
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Icon(
//                   esError ? Icons.error_outline : Icons.backup_rounded,
//                   color: esError ? Colors.red : const Color(0xFF1A237E),
//                   size: 42,
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   esError ? "Error en el Respaldo" : "Generando Respaldo Total",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: isDark ? Colors.white : Colors.black87,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 12),
//                 const Text(
//                   "⚠️ NO CIERRE LA APP\nSi minimiza la pantalla, el proceso podría cancelarse.",
//                   style: TextStyle(
//                     fontSize: 13,
//                     color: Colors.redAccent,
//                     fontWeight: FontWeight.w600,
//                     height: 1.4,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 30),
//                 Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     SizedBox(
//                       width: 120,
//                       height: 120,
//                       child: CircularProgressIndicator(
//                         value: esError
//                             ? 1.0
//                             : _completeProgress.clamp(0.0, 1.0),
//                         strokeWidth: 10,
//                         backgroundColor: isDark
//                             ? Colors.grey[800]
//                             : Colors.grey[300],
//                         valueColor: AlwaysStoppedAnimation<Color>(
//                           esError ? Colors.red : const Color(0xFF1A237E),
//                         ),
//                       ),
//                     ),
//                     Text(
//                       esError ? "!" : "$porcentajeTexto%",
//                       style: TextStyle(
//                         fontSize: esError ? 40 : 28,
//                         fontWeight: FontWeight.bold,
//                         color: esError
//                             ? Colors.red
//                             : (isDark ? Colors.white : Colors.black87),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 Text(
//                   _completeMessage,
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: isDark ? Colors.grey[400] : Colors.grey[600],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 if (esError || _completeProgress >= 1.0) ...[
//                   const SizedBox(height: 24),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         setState(() => _showCompleteDialog = false);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF1A237E),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: const Text(
//                         "CERRAR",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // ========================================================================
//   // WIDGETS AUXILIARES
//   // ========================================================================
//   Widget _sectionTitle(String title) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           letterSpacing: 1.0,
//           color: Colors.grey,
//         ),
//       ),
//     );
//   }

//   Widget _actionCard({
//     required IconData icon,
//     required String title,
//     required String description,
//     required Color color,
//     required VoidCallback? onTap,
//   }) {
//     final isDark = AppStyles.isDark(context);

//     return Material(
//       color: isDark ? const Color(0xFF161B22) : Colors.white,
//       elevation: 2,
//       borderRadius: BorderRadius.circular(16),
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(16),
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: color.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(icon, size: 30, color: color),
//               ),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       description,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey[600],
//                         height: 1.4,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const Icon(Icons.chevron_right, color: Colors.grey),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:io';

import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:peloton/SEGURIDAD/clase.dart';
import 'package:peloton/SEGURIDAD/estadi.dart';
import 'package:peloton/provider/apptex.dart';
// import 'package:peloton/provider/stats_provider.dart'; // <-- IMPORTAR TU PROVIDER
import 'package:peloton/BD/db_manager.dart';
import 'package:provider/provider.dart'; // <-- IMPORTAR PROVIDER
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final BackupService _backupService = BackupService();
  bool _isProcessing = false;
  String _processMessage = "";
  Map<String, int>? _limpiezaResultados;

  // Variables para controlar SOLO el diálogo del Respaldo Completo
  bool _showCompleteDialog = false;
  double _completeProgress = 0.0;
  String _completeMessage = "Iniciando...";

  // ========================================================================
  // NUEVA FUNCIÓN: Dispara el diálogo moderno para el RESPALDO COMPLETO
  // ========================================================================
  Future<void> _iniciarRespaldoCompletoUI() async {
    setState(() {
      _showCompleteDialog = true;
      _completeProgress = 0.0;
      _completeMessage = "Preparando sistema...";
    });

    await _backupService.generarRespaldoCompleto(
      onProgress: (porcentaje, mensaje) {
        if (mounted) {
          setState(() {
            _completeProgress = porcentaje;
            _completeMessage = mensaje;
          });
        }
      },
    );

    if (mounted && _completeProgress >= 1.0) {
      setState(() {
        _completeMessage = "¡Completado! Seleccione dónde guardar el archivo.";
      });
    }
  }

  // ========================================================================
  // ACCIÓN GENÉRICA (Para Respaldos Básicos y Limpieza)
  // ========================================================================
  Future<void> _ejecutarAccion(Function funcion, String mensaje) async {
    setState(() {
      _isProcessing = true;
      _processMessage = mensaje;
      _limpiezaResultados = null;
    });

    final resultado = await funcion();

    if (mounted) {
      setState(() {
        _isProcessing = false;

        if (resultado is bool && resultado) {
          _processMessage = "$mensaje completado con éxito.";
        } else if (resultado is Map) {
          _processMessage = "Limpieza finalizada.";
        } else {
          if (_processMessage.contains("LÍMITE EXCEDIDO")) {
            _processMessage = "Operación cancelada: Límite de 5 GB excedido.";
          } else {
            _processMessage = "Ocurrió un error al $mensaje.";
          }
        }
      });
    }
  }

  // ========================================================================
  // RESPALDO DISPOSITIVO (EXTRACCIÓN OMNÍVORA: IMÁGENES, AUDIOS, DOCS + EXCELS)
  // ========================================================================
  Future<void> _respaldoDispositivo() async {
    final _progressController = StreamController<String>.broadcast();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<String>(
          stream: _progressController.stream,
          initialData: "Iniciando...|0.0%",
          builder: (context, snapshot) {
            final data = snapshot.data ?? "||";
            final partes = data.split('|');
            final mensaje = partes.isNotEmpty ? partes[0] : "";
            final porcentajeTexto = partes.length > 1 ? partes[1] : "0.0%";
            final porcentajeDouble =
                double.tryParse(porcentajeTexto.replaceAll('%', '')) ?? 0.0;
            final isDark = Theme.of(context).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Extracción Total de Data",
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: porcentajeDouble / 100.0,
                          strokeWidth: 10,
                          backgroundColor: isDark
                              ? Colors.grey[800]
                              : Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF1A237E),
                          ),
                        ),
                      ),
                      Text(
                        "${porcentajeDouble.toInt()}%",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    mensaje,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    int countImagenes = 0;
    int countAudios = 0;
    int countDocs = 0;

    try {
      final userId = DBManager.instance.currentUserId;
      if (userId == null) {
        _progressController.add("Error: No hay sesión activa.|0.0%");
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();
        return;
      }

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Seleccione dónde guardar la copia",
      );
      if (selectedDirectory == null) {
        await _progressController.close();
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final destinoBaseDir = Directory(
        p.join(selectedDirectory, 'RESPALDO_COMPLETO_USER_$userId'),
      );
      await destinoBaseDir.create(recursive: true);

      // Creamos las 4 carpetas finales
      final carpetaImagenes = Directory(
        p.join(destinoBaseDir.path, 'IMAGENES'),
      );
      final carpetaAudios = Directory(p.join(destinoBaseDir.path, 'AUDIOS'));
      final carpetaDocs = Directory(p.join(destinoBaseDir.path, 'DOCUMENTOS'));
      final carpetaExcels = Directory(
        p.join(destinoBaseDir.path, 'BASES_DE_DATOS_EXCEL'),
      );

      await carpetaImagenes.create(recursive: true);
      await carpetaAudios.create(recursive: true);
      await carpetaDocs.create(recursive: true);
      await carpetaExcels.create(recursive: true);

      final db = await DBManager.instance.database;

      final tablasParaExportar = [
        'minutas',
        'inteligencia',
        'operacional',
        'armamento',
        'inventario_armamento',
        'comunicaciones',
        'expediente',
        'inventario_especial',
        'inventario_miras',
        'intendencia',
        'personal',
        'exde',
      ];

      double progresoBase = 0.0;
      double incrementoPorTabla = 85.0 / tablasParaExportar.length;

      for (String nombreTabla in tablasParaExportar) {
        _progressController.add(
          "Procesando: $nombreTabla...|${progresoBase.toStringAsFixed(1)}%",
        );

        try {
          final columnasResult = await db.rawQuery(
            "PRAGMA table_info($nombreTabla)",
          );
          List<String> nombresColumnas = columnasResult
              .map((col) => col['name'] as String)
              .toList();
          if (nombresColumnas.isEmpty) continue;

          final registros = await db.query(nombreTabla);
          if (registros.isEmpty) continue;

          var excel = ex.Excel.createExcel();
          String nombreHoja = nombreTabla.length > 31
              ? nombreTabla.substring(0, 31)
              : nombreTabla;
          ex.Sheet sheet = excel[nombreHoja];
          if (excel.sheets.containsKey('Sheet1')) excel.delete('Sheet1');

          sheet.appendRow(
            nombresColumnas.map((col) => ex.TextCellValue(col)).toList(),
          );

          for (var reg in registros) {
            List<ex.CellValue> fila = [];
            for (String col in nombresColumnas) {
              var valor = reg[col];
              if (valor == null) {
                fila.add(ex.TextCellValue(""));
              } else if (valor is int) {
                fila.add(ex.IntCellValue(valor));
              } else {
                String valStr = valor.toString().trim();
                fila.add(ex.TextCellValue(valStr));

                List<String> posiblesRutas = valStr.split(',');

                for (String posibleRuta in posiblesRutas) {
                  posibleRuta = posibleRuta.trim();
                  if (!posibleRuta.startsWith('/')) continue;

                  File archivoOriginal = File(posibleRuta);
                  if (!await archivoOriginal.exists()) continue;

                  String extension = p.extension(posibleRuta).toLowerCase();
                  String nombreArchivo = p.basename(posibleRuta);

                  String destinoFinal = p.join(carpetaDocs.path, nombreArchivo);

                  if ([
                    '.jpg',
                    '.jpeg',
                    '.png',
                    '.webp',
                    '.gif',
                  ].contains(extension)) {
                    destinoFinal = p.join(
                      carpetaImagenes.path,
                      "${nombreTabla}_$nombreArchivo",
                    );
                    countImagenes++;
                    // ---> INYECCIÓN SEGURA AQUÍ <---
                    if (mounted)
                      context.read<StatsProvider>().registrarArchivo(
                        posibleRuta,
                      );
                  } else if ([
                    '.mp3',
                    '.wav',
                    '.m4a',
                    '.aac',
                    '.ogg',
                    '.amr',
                  ].contains(extension)) {
                    destinoFinal = p.join(
                      carpetaAudios.path,
                      "${nombreTabla}_$nombreArchivo",
                    );
                    countAudios++;
                    // ---> INYECCIÓN SEGURA AQUÍ <---
                    if (mounted)
                      context.read<StatsProvider>().registrarArchivo(
                        posibleRuta,
                      );
                  } else if ([
                    '.pdf',
                    '.xls',
                    '.xlsx',
                    '.doc',
                    '.docx',
                    '.csv',
                  ].contains(extension)) {
                    destinoFinal = p.join(
                      carpetaDocs.path,
                      "${nombreTabla}_$nombreArchivo",
                    );
                    countDocs++;
                    // ---> INYECCIÓN SEGURA AQUÍ <---
                    if (mounted)
                      context.read<StatsProvider>().registrarArchivo(
                        posibleRuta,
                      );
                  } else {
                    continue;
                  }

                  await archivoOriginal.copy(destinoFinal);
                }
              }
            }
            sheet.appendRow(fila);
          }

          var fileBytes = excel.encode();
          if (fileBytes != null) {
            File excelFile = File(
              p.join(carpetaExcels.path, '${nombreTabla.toUpperCase()}.xlsx'),
            );
            await excelFile.writeAsBytes(fileBytes, flush: true);
          }
        } catch (e) {
          debugPrint("Error procesando $nombreTabla: $e");
        }

        progresoBase += incrementoPorTabla;
      }

      // ====================================================================
      // FASE FINAL: CACHE TEMPORAL
      // ====================================================================
      _progressController.add(
        "Buscando audios/docs en caché temporal...|95.0%",
      );
      String rutaCache = "";
      try {
        final temp = await getTemporaryDirectory();
        rutaCache = p.join(temp.path, '..', 'cache');
      } catch (_) {}

      if (rutaCache.isNotEmpty) {
        final dirCache = Directory(rutaCache);
        if (await dirCache.exists()) {
          List<File> archivosCache = await dirCache
              .list(recursive: true, followLinks: true)
              .where((e) => e is File)
              .cast<File>()
              .toList();
          for (var archivo in archivosCache) {
            final ext = p.extension(archivo.path).toLowerCase();
            final nombre = p.basename(archivo.path);

            if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) {
              await archivo.copy(p.join(carpetaImagenes.path, "CACHE_$nombre"));
              countImagenes++;
              if (mounted)
                context.read<StatsProvider>().registrarArchivo(archivo.path);
            } else if (['.mp3', '.wav', '.m4a', '.aac'].contains(ext)) {
              await archivo.copy(p.join(carpetaAudios.path, "CACHE_$nombre"));
              countAudios++;
              if (mounted)
                context.read<StatsProvider>().registrarArchivo(archivo.path);
            } else if ([
              '.pdf',
              '.xlsx',
              '.xls',
              '.csv',
              '.doc',
              '.docx',
            ].contains(ext)) {
              await archivo.copy(p.join(carpetaDocs.path, "CACHE_$nombre"));
              countDocs++;
              if (mounted)
                context.read<StatsProvider>().registrarArchivo(archivo.path);
            }
          }
        }
      }

      _progressController.add("¡Extracción Completada!|100.0%");
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Respaldo Total Exitoso:\n\n"
              "📁 12 Excels generados.\n"
              "🖼️ $countImagenes Imágenes extraídas.\n"
              "🎵 $countAudios Audios extraídos.\n"
              "📄 $countDocs Documentos extraídos.",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 7),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error crítico: $e");
      _progressController.add("Error crítico: $e|0.0%");
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.of(context).pop();
    } finally {
      await _progressController.close();
    }
  }

  Future<void> _procesarYCopiarArchivo(
    String ruta,
    Directory destImg,
    Directory destAud,
    Directory destDoc,
    StreamController<String> progress, {
    required int totalProcesados,
    required int totalEncontrados,
    Function(String tipo)? sumarContadores,
  }) async {
    final archivo = File(ruta);
    if (!await archivo.exists()) return;

    final extension = ruta.split('.').last.toLowerCase();
    String nombre = p.basename(archivo.path);
    Directory destino = destDoc;
    String tipo = 'doc';

    if (['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      destino = destImg;
      tipo = 'img';
    } else if ([
      'mp3',
      '.wav',
      'm4a',
      'aac',
      'ogg',
      'amr',
    ].contains(extension)) {
      destino = destAud;
      tipo = 'aud';
    } else if (![
      'pdf',
      'xls',
      'xlsx',
      'doc',
      'docx',
      'csv',
    ].contains(extension)) {
      return;
    }

    double progresoReal = (totalProcesados / totalEncontrados) * 100;
    if (progresoReal < 10) progresoReal = 10;
    if (progresoReal > 95) progresoReal = 95;

    progress.add(
      "Copiando ($totalProcesados/$totalEncontrados): $nombre|${progresoReal.toStringAsFixed(1)}%",
    );

    String rutaFinal = p.join(destino.path, nombre);
    int c = 1;
    while (await File(rutaFinal).exists()) {
      rutaFinal = p.join(
        destino.path,
        '${nombre.split('.')[0]}_($c).$extension',
      );
      c++;
    }

    await archivo.copy(rutaFinal);
    if (sumarContadores != null) sumarContadores(tipo);
  }

  void _mostrarDialogoReinicioExitoso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Restauración Completada"),
        content: const Text(
          "Los datos y la sesión fueron actualizados. La aplicación se reiniciará ahora para cargar el usuario del respaldo.",
        ),
        actions: [
          TextButton(
            onPressed: () => Restart.restartApp(webOrigin: ""),
            child: const Text(
              "ACEPTAR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _hacerEjercitoYReiniciar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("⚠️ ¿Eliminar toda la data?"),
        content: const Text(
          "Se vaciarán TODAS las tablas de inventario, minutas, inteligencia, etc. La app se reiniciará automáticamente.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "SÍ, BORRAR TODO",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _isProcessing = true;
      _processMessage = "Borrando datos de las tablas...";
    });

    try {
      await DBManager.instance.limpiarTodaLaData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_logged_user_id');
      await prefs.setBool('mantener_sesion_activa', false);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Restart.restartApp(webOrigin: "");
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _processMessage = "Error al borrar: $e";
      });
    }
  }

  void _mostrarSnackBarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppStyles.isDark(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "SISTEMA DE RESPALDOS",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),

                // ========================================================================
                // TARJETA DE ESTADÍSTICAS INYECTADA AQUÍ (No afecta tu flujo original)
                // ========================================================================
                Consumer<StatsProvider>(
                  builder: (context, stats, child) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF1E1E1E),
                                  const Color(0xFF2C2C2C),
                                ]
                              : [
                                  const Color(0xFFE8EAF6),
                                  const Color(0xFFFFFFFF),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF1A237E).withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.equalizer_rounded,
                                color: Color(0xFF1A237E),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "ESTADÍSTICAS DE RESPALDO",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _statItem(
                                Icons.image_rounded,
                                "Imágenes",
                                stats.totalImagenes,
                                Colors.blue,
                                isDark,
                              ),
                              _statItem(
                                Icons.audiotrack_rounded,
                                "Audios",
                                stats.totalAudios,
                                Colors.green,
                                isDark,
                              ),
                              _statItem(
                                Icons.picture_as_pdf_rounded,
                                "Docs",
                                stats.totalDocumentos,
                                Colors.orange,
                                isDark,
                              ),
                            ],
                          ),
                          const Divider(height: 25, thickness: 1),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Archivos Extraídos",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                "${stats.totalArchivosGenerales}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                _sectionTitle("CREAR RESPALDO"),
                const SizedBox(height: 15),
                _actionCard(
                  icon: Icons.abc,
                  title: "Respaldo Básico",
                  description:
                      "Genera un archivo .ZIP únicamente con las Bases de Datos. Peso mínimo.",
                  color: Colors.blue.shade700,
                  onTap: _isProcessing
                      ? null
                      : () => _ejecutarAccion(
                          _backupService.generarRespaldoBasico,
                          "Respaldo Básico",
                        ),
                ),
                const SizedBox(height: 15),
                _actionCard(
                  icon: Icons.backup,
                  title: "Respaldo COMPLETO",
                  description:
                      "Genera un archivo .ZIP con las Bases de Datos + TODAS las fotografías y medios guardados.",
                  color: Colors.green.shade800,
                  onTap: (_isProcessing || _showCompleteDialog)
                      ? null
                      : _iniciarRespaldoCompletoUI,
                ),
                const SizedBox(height: 40),
                _sectionTitle("COPIA DE SEGURIDAD EXTERNA"),
                const SizedBox(height: 15),
                _actionCard(
                  icon: Icons.folder_copy,
                  title: "Extraer a Carpeta (Dispositivo)",
                  description:
                      "Copia todas las imágenes, audios y documentos registrados en tu BD a una carpeta seleccionada sin comprimir.",
                  color: Colors.orange.shade800,
                  onTap: _isProcessing ? null : _respaldoDispositivo,
                ),
                const SizedBox(height: 40),
                _sectionTitle("MANTENIMIENTO Y LIMPIEZA"),
                const SizedBox(height: 15),
                _actionCard(
                  icon: Icons.delete_forever,
                  title: "Hacer Ejército (Borrar Tablas)",
                  description:
                      "Elimina TODOS los registros de inventario, personal, minutas, etc. La app se reiniciará automáticamente.",
                  color: Colors.red.shade900,
                  onTap: _isProcessing ? null : _hacerEjercitoYReiniciar,
                ),
                const SizedBox(height: 15),
                _actionCard(
                  icon: Icons.cleaning_services_rounded,
                  title: "Eliminar Residuos y Huérfanos",
                  description:
                      "Borra archivos temporales (Excels/PDFs viejos) y fotos que ya no están registradas en la base de datos.",
                  color: Colors.red.shade700,
                  onTap: _isProcessing
                      ? null
                      : () async {
                          setState(() => _isProcessing = true);
                          final resultados = await _backupService
                              .limpiarResiduos();
                          setState(() {
                            _isProcessing = false;
                            _limpiezaResultados = resultados;
                            _processMessage = "Limpieza finalizada.";
                          });
                        },
                ),
                if (_limpiezaResultados != null) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Reporte de Limpieza:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "• Archivos temporales eliminados: ${_limpiezaResultados!['temporales']}",
                        ),
                        Text(
                          "• Fotos huérfanas eliminadas: ${_limpiezaResultados!['huerfanos']}",
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),

          // --- DIÁLOGO MODERNO CON PORCENTAJE (SOLO PARA RESPALDO COMPLETO) ---
          if (_showCompleteDialog) _buildModernProgressDialog(isDark),

          // --- INDICADOR DE CARGA GENÉRICO ---
          if (_isProcessing && !_showCompleteDialog)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 20),
                        Text(
                          _processMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ========================================================================
  // WIDGETS AUXILIARES (Incluido el nuevo de estadísticas)
  // ========================================================================

  // Widget reutilizable para las estadísticas
  Widget _statItem(
    IconData icon,
    String label,
    int value,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          "$value",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildModernProgressDialog(bool isDark) {
    final esError = _completeProgress < 0;
    final porcentajeTexto = (_completeProgress * 100).toInt();

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.6 : 0.2),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  esError ? Icons.error_outline : Icons.backup_rounded,
                  color: esError ? Colors.red : const Color(0xFF1A237E),
                  size: 42,
                ),
                const SizedBox(height: 20),
                Text(
                  esError ? "Error en el Respaldo" : "Generando Respaldo Total",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  "⚠️ NO CIERRE LA APP\nSi minimiza la pantalla, el proceso podría cancelarse.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: esError
                            ? 1.0
                            : _completeProgress.clamp(0.0, 1.0),
                        strokeWidth: 10,
                        backgroundColor: isDark
                            ? Colors.grey[800]
                            : Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          esError ? Colors.red : const Color(0xFF1A237E),
                        ),
                      ),
                    ),
                    Text(
                      esError ? "!" : "$porcentajeTexto%",
                      style: TextStyle(
                        fontSize: esError ? 40 : 28,
                        fontWeight: FontWeight.bold,
                        color: esError
                            ? Colors.red
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _completeMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (esError || _completeProgress >= 1.0) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _showCompleteDialog = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "CERRAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final isDark = AppStyles.isDark(context);

    return Material(
      color: isDark ? const Color(0xFF161B22) : Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
