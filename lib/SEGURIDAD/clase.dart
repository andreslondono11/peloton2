// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:peloton/BD/db_manager.dart';
// import 'package:peloton/main.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart' as p;
// import 'package:archive/archive_io.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // <-- CLAVE PARA EL REINICIO

// class BackupService {
//   static final BackupService _instance = BackupService._internal();
//   factory BackupService() => _instance;
//   BackupService._internal();

//   // ========================================================================
//   // MÉTODO SEGURO: Copia limpia de BD usando VACUUM (Previene corrupción)
//   // ========================================================================
//   Future<File?> _crearCopiaSeguraBD(String dbName) async {
//     try {
//       final dbPath = await getDatabasesPath();
//       final originalPath = p.join(dbPath, dbName);
//       final originalFile = File(originalPath);

//       if (!await originalFile.exists()) return null;

//       final backupPath = '$originalPath.bak';
//       final viejoBak = File(backupPath);
//       if (await viejoBak.exists()) await viejoBak.delete();

//       Database db = await openDatabase(originalPath, readOnly: true);
//       await db.execute('VACUUM INTO "$backupPath"');
//       await db.close();

//       final backupFile = File(backupPath);
//       return await backupFile.exists() ? backupFile : null;
//     } catch (e) {
//       debugPrint("❌ Error creando copia segura de $dbName: $e");
//       return null;
//     }
//   }

//   // ========================================================================
//   // 1. RESPALDO BÁSICO
//   // ========================================================================
//   Future<bool> generarRespaldoBasico() async {
//     Directory? workDir;
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final timeStamp = DateTime.now().millisecondsSinceEpoch;
//       workDir = Directory(p.join(tempDir.path, 'backup_work'));
//       final zipPath = p.join(tempDir.path, 'BACKUP_BASICO_$timeStamp.zip');

//       if (await workDir.exists()) await workDir.delete(recursive: true);
//       await workDir.create(recursive: true);

//       final globalBackup = await _crearCopiaSeguraBD('tablet_app.db');
//       if (globalBackup != null) {
//         await globalBackup.copy(p.join(workDir.path, 'tablet_app.db'));
//         await globalBackup.delete();
//       }

//       final userId = DBManager.instance.currentUserId;
//       if (userId != null) {
//         final userBackup = await _crearCopiaSeguraBD('calipso_user_$userId.db');
//         if (userBackup != null) {
//           await userBackup.copy(
//             p.join(workDir.path, 'calipso_user_$userId.db'),
//           );
//           await userBackup.delete();
//         }
//       }

//       final encoder = ZipFileEncoder();
//       encoder.create(zipPath);
//       await encoder.addDirectory(workDir);
//       encoder.close();

//       if (await File(zipPath).exists()) {
//         await Share.shareXFiles([
//           XFile(zipPath),
//         ], text: 'Respaldo Básico de Base de Datos');
//         return true;
//       }
//       return false;
//     } catch (e) {
//       debugPrint("❌ Error respaldo básico: $e");
//       return false;
//     } finally {
//       if (workDir != null && await workDir.exists()) {
//         await workDir.delete(recursive: true);
//       }
//     }
//   }

//   // ========================================================================
//   // 2. RESPALDO DE EVIDENCIAS TOTAL (Optimizado para no saturar la memoria)
//   // ========================================================================
//   Future<bool> generarRespaldoCompleto() async {
//     final context = navigatorKey.currentContext;

//     try {
//       final userId = DBManager.instance.currentUserId;
//       if (userId == null) {
//         debugPrint("❌ No hay usuario logueado para extraer datos.");
//         return false;
//       }

//       final docsDir = await getApplicationDocumentsDirectory();
//       final tempDir = await getTemporaryDirectory();
//       final timeStamp = DateTime.now().millisecondsSinceEpoch;

//       // Carpeta temporal SOLO para el JSON
//       final workDir = Directory(
//         p.join(tempDir.path, 'evidencias_work_$timeStamp'),
//       );
//       final zipPath = p.join(tempDir.path, 'EVIDENCIAS_$timeStamp.zip');

//       if (await workDir.exists()) await workDir.delete(recursive: true);
//       await workDir.create(recursive: true);

//       // ====================================================================
//       // 1. EXTRAER DATOS DE CAMPOS A UN ARCHIVO JSON
//       // ====================================================================
//       final jsonFile = File(p.join(workDir.path, 'datos_extraidos.json'));
//       final userDb = await DBManager.instance.database;

//       Map<String, List<Map<String, dynamic>>> datosExtraidos = {};
//       final tablasAExtraer = [
//         'inventario_armamento',
//         'inventario_especial',
//         'inventario_miras',
//         'intendencia',
//         'inteligencia',
//         'operacional',
//         'personal',
//       ];

//       for (var tabla in tablasAExtraer) {
//         try {
//           final filas = await userDb.query(tabla);
//           if (filas.isNotEmpty) {
//             datosExtraidos[tabla] = filas;
//           }
//         } catch (e) {
//           debugPrint("⚠️ Tabla $tabla omitida (no existe o error).");
//         }
//       }

//       final jsonString = const JsonEncoder.withIndent(
//         '  ',
//       ).convert(datosExtraidos);
//       await jsonFile.writeAsString(jsonString);

//       // ====================================================================
//       // 2. COMPRIMIR "AL VUELO" (Ahorra RAM y espacio en disco)
//       // ====================================================================
//       final encoder = ZipFileEncoder();
//       encoder.create(zipPath);

//       // Primero añadimos la carpeta chiquita del JSON
//       await encoder.addDirectory(workDir);

//       // Segundo, añadimos la carpeta de documentos original directamente al ZIP
//       // Esto lee los archivos (jpg, mp4, pdf, etc) y los comprime sin duplicarlos en el disco
//       if (await docsDir.exists()) {
//         // Lo renombramos dentro del ZIP para que se llame "ARCHIVOS"
//         await encoder.addDirectory(docsDir, includeDirName: true);
//       }

//       encoder.close();

//       // ====================================================================
//       // 3. VERIFICAR PESO DEL ZIP (Si el límite es estricto para el archivo final)
//       // ====================================================================
//       final zipFile = File(zipPath);
//       if (await zipFile.exists()) {
//         final pesoZipBytes = await zipFile.length();
//         const int limite5GB = 5368709120;

//         if (pesoZipBytes > limite5GB) {
//           debugPrint(
//             "❌ El ZIP final pesa ${pesoZipBytes / (1024 * 1024 * 1024)} GB (Supera los 5 GB)",
//           );
//           if (context != null) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text(
//                   "⚠️ El archivo de respaldo supera los 5 GB y no puede ser compartido.",
//                 ),
//                 backgroundColor: Colors.red,
//                 duration: Duration(seconds: 5),
//               ),
//             );
//           }
//           await zipFile.delete(); // Borramos el ZIP inútil
//           return false;
//         }

//         // Si todo está bien, compartimos
//         await Share.shareXFiles([
//           XFile(zipPath),
//         ], text: 'Evidencias Completas (Todos los formatos)');
//         return true;
//       }

//       return false;
//     } catch (e) {
//       debugPrint("❌ Error extrayendo evidencias totales: $e");
//       return false;
//     } finally {
//       // Limpiamos el JSON temporal (el ZIP ya se queda donde está para que el usuario lo comparta)
//       final tempDir = await getTemporaryDirectory();
//       final workDirs = await tempDir
//           .list()
//           .where((entity) => entity.path.contains('evidencias_work_'))
//           .toList();
//       for (var dir in workDirs) {
//         if (dir is Directory) await dir.delete(recursive: true);
//       }
//     }
//   }

//   // ========================================================================
//   // 3. RESTAURACIÓN SCOUT (Busca cualquier archivo válido en cualquier carpeta del ZIP)
//   // ========================================================================
//   Future<bool> restaurarRespaldo({required Function(String) onProgress}) async {
//     Directory? extractDir;

//     try {
//       onProgress("Abriendo selector de archivos...");

//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['zip'],
//       );

//       if (result == null || result.files.single.path == null) return false;

//       final zipFile = File(result.files.single.path!);

//       // LÍMITE DE 5 GB
//       final int fileSizeInBytes = await zipFile.length();
//       const int limit5GB = 5368709120;
//       if (fileSizeInBytes > limit5GB) {
//         onProgress("ERROR: El archivo supera el límite de 5 GB.");
//         return false;
//       }

//       onProgress("Preparando descompresión...");
//       final tempDir = await getTemporaryDirectory();
//       extractDir = Directory(p.join(tempDir.path, 'restore_work'));

//       if (await extractDir.exists()) await extractDir.delete(recursive: true);
//       await extractDir.create(recursive: true);

//       onProgress("Descomprimiendo archivo...");
//       try {
//         await extractArchiveToDisk(
//           ZipDecoder().decodeBuffer(InputFileStream(zipFile.path)),
//           extractDir.path,
//         );
//       } catch (e) {
//         onProgress("ERROR: El ZIP está corrupto o no se puede leer.");
//         return false;
//       }

//       final docsDir = await getApplicationDocumentsDirectory();
//       int archivosCopiados = 0;
//       bool encontroAlgo = false;

//       onProgress("Analizando contenido del ZIP...");

//       // ====================================================================
//       // NUEVA ESTRATEGIA: Escanear TODO lo que hay dentro del ZIP
//       // Si es un archivo (foto, audio, pdf, etc) y NO es una base de datos, lo copia.
//       // ====================================================================
//       await for (var entity in extractDir.list(
//         recursive: true,
//         followLinks: false,
//       )) {
//         if (entity is File) {
//           final nombre = p.basename(entity.path).toLowerCase();

//           // Ignorar archivos ocultos de Mac y bases de datos de la app
//           if (!entity.path.contains('__MACOSX') &&
//               !nombre.startsWith('.') &&
//               !nombre.endsWith('.db') &&
//               !nombre.endsWith('.json')) {
//             // Ignoramos el JSON porque solo queríamos los archivos físicos

//             try {
//               encontroAlgo = true;
//               final targetPath = p.join(docsDir.path, p.basename(entity.path));

//               // Evitar sobreescribir si ya existe un archivo con el mismo nombre
//               if (!await File(targetPath).exists()) {
//                 await File(targetPath).parent.create(recursive: true);
//                 await entity.copy(targetPath);
//                 archivosCopiados++;

//                 if (archivosCopiados % 50 == 0) {
//                   onProgress(
//                     "Copiando archivos... ($archivosCopiados procesados)",
//                   );
//                 }
//               } else {
//                 // Si el archivo ya existe, le agregamos un número al final para no perderlo
//                 final String extension = p.extension(entity.path);
//                 final String baseName = p.basenameWithoutExtension(entity.path);
//                 final String nuevoNombre = "${baseName}_copiado$extension";
//                 final newPath = p.join(docsDir.path, nuevoNombre);

//                 await File(newPath).parent.create(recursive: true);
//                 await entity.copy(newPath);
//                 archivosCopiados++;
//               }
//             } catch (e) {
//               debugPrint("⚠️ No se pudo copiar ${entity.path}: $e");
//             }
//           }
//         }
//       }

//       // ====================================================================
//       // RESULTADO FINAL
//       // ====================================================================
//       if (encontroAlgo) {
//         onProgress(
//           "¡Éxito! $archivosCopiados archivos recuperados e importados.",
//         );
//         return true;
//       } else {
//         onProgress(
//           "ERROR: El ZIP está vacío o solo contiene bases de datos (sin fotos/audios).",
//         );
//         return false;
//       }
//     } catch (e) {
//       debugPrint("❌ Error general restaurando: $e");
//       onProgress("Error crítico: $e");
//       return false;
//     } finally {
//       if (extractDir != null && await extractDir.exists()) {
//         await extractDir.delete(recursive: true);
//       }
//     }
//   }

//   // Puedes borrar la función _sobrescribirBDSeguro si ya no la usas en ningún
//   // otro lado de este archivo, porque esta nueva función ya no la necesita.
//   // ========================================================================
//   // AUXILIAR: Sobrescribir BD (Sin cambios, igual que antes)
//   // ========================================================================
//   // Future<void> _sobrescribirBDSeguro(
//   //   File archivoOrigen,
//   //   String dbPathDestino,
//   // ) async {
//   //   final destinoPath = p.join(dbPathDestino, p.basename(archivoOrigen.path));
//   //   final archivoDestino = File(destinoPath);

//   //   if (await archivoDestino.exists()) {
//   //     await archivoDestino.delete();
//   //   }

//   //   await archivoOrigen.copy(destinoPath);
//   // }

//   // ========================================================================
//   // 4. LIMPIADOR DE RESIDUOS
//   // ========================================================================
//   Future<Map<String, int>> limpiarResiduos({
//     bool eliminarTemporales = true,
//     bool eliminarHuerfanos = true,
//   }) async {
//     int tempEliminados = 0;
//     int huerfanosEliminados = 0;

//     final userId = DBManager.instance.currentUserId;

//     if (eliminarTemporales) {
//       final tempDir = await getTemporaryDirectory();
//       if (await tempDir.exists()) {
//         await for (var entity in tempDir.list(recursive: true)) {
//           try {
//             if (entity is File) {
//               await entity.delete();
//               tempEliminados++;
//             }
//           } catch (_) {}
//         }
//       }
//     }

//     if (eliminarHuerfanos) {
//       final docsDir = await getApplicationDocumentsDirectory();
//       final rutasValidasEnBD = await _obtenerRutasFotosEnBD();

//       if (await docsDir.exists()) {
//         await for (var entity in docsDir.list(
//           recursive: true,
//           followLinks: false,
//         )) {
//           if (entity is File) {
//             final pathLower = entity.path.toLowerCase();
//             final isImage =
//                 pathLower.endsWith('.jpg') ||
//                 pathLower.endsWith('.png') ||
//                 pathLower.endsWith('.jpeg');

//             if (isImage && !rutasValidasEnBD.contains(entity.path)) {
//               try {
//                 await entity.delete();
//                 huerfanosEliminados++;
//               } catch (_) {}
//             }
//           }
//         }
//       }
//     }

//     // Refrescar conexión tras limpieza
//     await DBManager.instance.fullReset();
//     if (userId != null) {
//       await DBManager.instance.initUserSession(userId);
//     } else {
//       await DBManager.instance.database;
//     }

//     debugPrint(
//       "🔄 Limpieza finalizada. Temporales: $tempEliminados, Huérfanos: $huerfanosEliminados.",
//     );
//     return {'temporales': tempEliminados, 'huerfanos': huerfanosEliminados};
//   }

//   // ========================================================================
//   // CONSULTA DE RUTAS VÁLIDAS EN BD
//   // ========================================================================
//   Future<Set<String>> _obtenerRutasFotosEnBD() async {
//     Set<String> rutas = {};
//     try {
//       final db = await DBManager.instance.database;
//       final columnasAFiltrar = [
//         {'tabla': 'inventario_armamento', 'columna': 'foto_patrimonio'},
//         {'tabla': 'inventario_especial', 'columna': 'foto_path'},
//         {'tabla': 'inventario_miras', 'columna': 'foto_path'},
//         {'tabla': 'intendencia', 'columna': 'foto_path'},
//         {'tabla': 'inteligencia', 'columna': 'imagen'},
//         {'tabla': 'operacional', 'columna': 'imagen'},
//         {'tabla': 'personal', 'columna': 'foto_path'},
//       ];

//       for (var item in columnasAFiltrar) {
//         try {
//           final results = await db.query(
//             item['tabla']!,
//             where:
//                 '${item['columna']} IS NOT NULL AND ${item['columna']} != ""',
//             columns: [item['columna']!],
//           );
//           for (var row in results) {
//             final path = row[item['columna']] as String?;
//             if (path != null && path.isNotEmpty) rutas.add(path);
//           }
//         } catch (_) {}
//       }
//     } catch (e) {
//       debugPrint("⚠️ Error obteniendo rutas de fotos: $e");
//     }
//     return rutas;
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:peloton/BD/db_manager.dart';
import 'package:peloton/main.dart'; // Asegúrate que navigatorKey esté aquí
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  // ========================================================================
  // MÉTODO SEGURO: Copia limpia de BD usando VACUUM (Previene corrupción)
  // ========================================================================
  Future<File?> _crearCopiaSeguraBD(String dbName) async {
    try {
      final dbPath = await getDatabasesPath();
      final originalPath = p.join(dbPath, dbName);
      final originalFile = File(originalPath);

      if (!await originalFile.exists()) return null;

      final backupPath = '$originalPath.bak';
      final viejoBak = File(backupPath);
      if (await viejoBak.exists()) await viejoBak.delete();

      Database db = await openDatabase(originalPath, readOnly: true);
      await db.execute('VACUUM INTO "$backupPath"');
      await db.close();

      final backupFile = File(backupPath);
      return await backupFile.exists() ? backupFile : null;
    } catch (e) {
      debugPrint("❌ Error creando copia segura de $dbName: $e");
      return null;
    }
  }

  // ========================================================================
  // 1. RESPALDO BÁSICO
  // ========================================================================
  Future<bool> generarRespaldoBasico() async {
    Directory? workDir;
    try {
      final tempDir = await getTemporaryDirectory();
      final timeStamp = DateTime.now().millisecondsSinceEpoch;
      workDir = Directory(p.join(tempDir.path, 'backup_work'));
      final zipPath = p.join(tempDir.path, 'BACKUP_BASICO_$timeStamp.zip');

      if (await workDir.exists()) await workDir.delete(recursive: true);
      await workDir.create(recursive: true);

      final globalBackup = await _crearCopiaSeguraBD('tablet_app.db');
      if (globalBackup != null) {
        await globalBackup.copy(p.join(workDir.path, 'tablet_app.db'));
        await globalBackup.delete();
      }

      final userId = DBManager.instance.currentUserId;
      if (userId != null) {
        final userBackup = await _crearCopiaSeguraBD('calipso_user_$userId.db');
        if (userBackup != null) {
          await userBackup.copy(
            p.join(workDir.path, 'calipso_user_$userId.db'),
          );
          await userBackup.delete();
        }
      }

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addDirectory(workDir);
      encoder.close();

      if (await File(zipPath).exists()) {
        await Share.shareXFiles([
          XFile(zipPath),
        ], text: 'Respaldo Básico de Base de Datos');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ Error respaldo básico: $e");
      return false;
    } finally {
      if (workDir != null && await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
    }
  }

  // ========================================================================
  // 2. RESPALDO DE EVIDENCIAS TOTAL (CORREGIDO: INTEGERS + CACHE TOTAL)
  // ========================================================================
  Future<bool> generarRespaldoCompleto({
    Function(double porcentaje, String mensaje)? onProgress,
  }) async {
    Directory? workDir;
    Database? dbEditable;
    try {
      final userId = DBManager.instance.currentUserId;
      if (userId == null) {
        onProgress?.call(-1, "Error: No hay usuario logueado.");
        return false;
      }

      onProgress?.call(0.0, "Preparando sistema de archivos...");
      final docsDir = await getApplicationDocumentsDirectory();
      final docsPath = docsDir.path;

      // OBTENER RUTA DEL CACHE
      String cachePath = "";
      try {
        final tempDir = await getTemporaryDirectory();
        cachePath = p.join(tempDir.path, '..', 'cache');
      } catch (_) {}

      final tempDir = await getTemporaryDirectory();
      final timeStamp = DateTime.now().millisecondsSinceEpoch;

      workDir = Directory(p.join(tempDir.path, 'evidencias_work_$timeStamp'));
      final zipPath = p.join(tempDir.path, 'EVIDENCIAS_$timeStamp.zip');

      if (await workDir.exists()) await workDir.delete(recursive: true);
      await workDir.create(recursive: true);

      // ====================================================================
      // 0. OBTENER LISTADO GLOBAL DE TABLAS
      // ====================================================================
      onProgress?.call(0.02, "Leyendo estructura de la base de datos...");
      final userDb = await DBManager.instance.database;
      final tablasResult = await userDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
      );

      // ====================================================================
      // 1. GUARDAR BASE DE DATOS GLOBAL
      // ====================================================================
      onProgress?.call(0.05, "Respaldo BD Global (Usuarios)...");
      final globalBackup = await _crearCopiaSeguraBD('tablet_app.db');
      if (globalBackup != null) {
        await globalBackup.copy(p.join(workDir.path, 'tablet_app.db'));
        await globalBackup.delete();
      }

      // ====================================================================
      // 2. CLONAR BD DEL USUARIO Y REPARAR RUTAS
      // ====================================================================
      onProgress?.call(0.10, "Preparando BD del Usuario y reparando rutas...");
      final dbPathDestino = p.join(workDir.path, 'calipso_user_$userId.db');

      try {
        final userDbBackup = await _crearCopiaSeguraBD(
          'calipso_user_$userId.db',
        );
        if (userDbBackup != null) {
          await userDbBackup.copy(dbPathDestino);
          await userDbBackup.delete();
        } else {
          final dbPath = await getDatabasesPath();
          await File(
            p.join(dbPath, 'calipso_user_$userId.db'),
          ).copy(dbPathDestino);
        }

        dbEditable = await openDatabase(dbPathDestino, readOnly: false);

        for (var tabla in tablasResult) {
          String nombreTabla = tabla['name'] as String;
          try {
            final columnasResult = await userDb.rawQuery(
              "PRAGMA table_info($nombreTabla)",
            );

            for (var col in columnasResult) {
              String nombreCol = col['name'] as String;
              if (nombreCol.toLowerCase().contains('foto') ||
                  nombreCol.toLowerCase().contains('imagen') ||
                  nombreCol.toLowerCase().contains('adjunto') ||
                  nombreCol.toLowerCase().contains('path')) {
                final registros = await dbEditable!.query(nombreTabla);
                for (var reg in registros) {
                  String? rutaActual = reg[nombreCol] as String?;
                  if (rutaActual != null && rutaActual.contains(docsPath)) {
                    List<String> partes = rutaActual.split(',');
                    List<String> partesLimpias = [];

                    for (var parte in partes) {
                      String limpia = parte
                          .trim()
                          .replaceAll(docsPath, '')
                          .replaceAll('\\', '/');
                      if (limpia.startsWith('/')) limpia = limpia.substring(1);
                      partesLimpias.add(limpia);
                    }

                    String rutaFinalLimpia = partesLimpias.join(',');
                    await dbEditable!.update(
                      nombreTabla,
                      {nombreCol: rutaFinalLimpia},
                      where: 'id = ?',
                      whereArgs: [reg['id']],
                    );
                  }
                }
              }
            }
          } catch (_) {}
        }
        await dbEditable.close();
        dbEditable = null;
      } catch (e) {
        debugPrint("⚠️ Error procesando BD para respaldo: $e");
        if (dbEditable != null) await dbEditable.close();
      }

      // ====================================================================
      // 3. EXTRAER DATOS A JSON
      // ====================================================================
      onProgress?.call(0.20, "Generando JSON estructurado...");
      final jsonFile = File(p.join(workDir.path, 'datos_extraidos.json'));

      Map<String, List<Map<String, dynamic>>> datosExtraidos = {};
      for (var tabla in tablasResult) {
        String nombreTabla = tabla['name'] as String;
        try {
          final filas = await userDb.query(nombreTabla);
          if (filas.isNotEmpty) datosExtraidos[nombreTabla] = filas;
        } catch (e) {
          debugPrint("⚠️ Tabla $nombreTabla omitida en JSON.");
        }
      }

      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(datosExtraidos);
      await jsonFile.writeAsString(jsonString);

      // ====================================================================
      // 4. RASTREO OMNÍVORO DE LA BASE DE DATOS
      // ====================================================================
      onProgress?.call(0.30, "Rastreando archivos vinculados en la BD...");

      final mediaWorkDir = Directory(p.join(workDir.path, 'ARCHIVOS'));
      await mediaWorkDir.create(recursive: true);

      Set<String> rutasYaCopiadas = {};
      int archivosCopiados = 0;

      List<String> extensionesValidas = [
        'jpg',
        'jpeg',
        'png',
        'webp',
        'gif',
        'mp3',
        'wav',
        'm4a',
        'aac',
        'ogg',
        'amr',
        'mp4',
        'avi',
        'mov',
        'pdf',
        'xls',
        'xlsx',
        'doc',
        'docx',
        'csv',
      ];

      for (var tabla in tablasResult) {
        String nombreTabla = tabla['name'] as String;
        try {
          final registros = await userDb.query(nombreTabla);

          for (var reg in registros) {
            for (var valor in reg.values) {
              // CLAVE: Saltamos inmediatamente si es nulo o si es un INTEGER (int)
              if (valor == null || valor is int) continue;

              String valStr = valor.toString().trim();
              if (valStr.isEmpty) continue;

              for (var fragmento in valStr.split(',')) {
                fragmento = fragmento.trim();
                if (fragmento.isEmpty) continue;

                String extension = fragmento.split('.').last.toLowerCase();
                if (!extensionesValidas.contains(extension)) continue;

                // Si empieza con / es ruta completa
                if (fragmento.startsWith('/') &&
                    !rutasYaCopiadas.contains(fragmento)) {
                  rutasYaCopiadas.add(fragmento);
                  final archivoFisico = File(fragmento);
                  if (await archivoFisico.exists()) {
                    await archivoFisico.copy(
                      p.join(mediaWorkDir.path, p.basename(fragmento)),
                    );
                    archivosCopiados++;
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint("⚠️ Error leyendo archivos en $nombreTabla: $e");
        }
      }

      // ====================================================================
      // 5. BARRIDO TOTAL DEL CACHE (REPORTES EXCEL, AUDIOS SUELTOS, ETC)
      // ====================================================================
      onProgress?.call(
        0.75,
        "Rastreando reportes y audios en caché temporal...",
      );

      if (cachePath.isNotEmpty) {
        final dirCache = Directory(cachePath);

        if (await dirCache.exists()) {
          List<File> archivosEnCache = [];
          try {
            archivosEnCache = await dirCache
                .list(recursive: true, followLinks: true)
                .where((e) => e is File)
                .cast<File>()
                .toList();
          } catch (_) {}

          for (var archivoCache in archivosEnCache) {
            String nombreReal = p.basename(archivoCache.path).toLowerCase();

            // Ignorar archivos basura del sistema
            if (nombreReal.startsWith('.') || nombreReal.contains('exoplayer'))
              continue;

            String extension = nombreReal.split('.').last.toLowerCase();

            // Si es un archivo válido (Excel, PDF, Audio, Imagen)
            if (extensionesValidas.contains(extension)) {
              String destinoFinal = p.join(
                mediaWorkDir.path,
                p.basename(archivoCache.path),
              );

              // Evitar sobreescribir si ya lo sacamos de la BD
              if (!await File(destinoFinal).exists()) {
                try {
                  await archivoCache.copy(destinoFinal);
                  archivosCopiados++;
                } catch (_) {}
              }
            }
          }
        }
      }

      onProgress?.call(
        0.85,
        "Se han empaquetado $archivosCopiados archivos multimedia...",
      );

      // ====================================================================
      // 6. COMPRIMIR TODO
      // ====================================================================
      onProgress?.call(0.90, "Comprimiendo todo en formato .ZIP...");
      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      await encoder.addDirectory(workDir);
      encoder.close();

      if (await workDir.exists()) await workDir.delete(recursive: true);

      if (!await File(zipPath).exists()) {
        onProgress?.call(-1, "Error al generar el archivo ZIP.");
        return false;
      }

      // ====================================================================
      // 7. VERIFICAR PESO Y COMPARTIR
      // ====================================================================
      onProgress?.call(0.98, "Verificando tamaño...");
      final zipFile = File(zipPath);
      final pesoZipBytes = await zipFile.length();
      const int limite5GB = 5368709120;

      if (pesoZipBytes > limite5GB) {
        onProgress?.call(-1, "Error: El archivo supera el límite de 5 GB.");
        await zipFile.delete();
        return false;
      }

      onProgress?.call(1.0, "¡Respaldo Total Listo! Abriendo menú...");
      await Future.delayed(const Duration(milliseconds: 500));

      await Share.shareXFiles([
        XFile(zipPath),
      ], text: 'Respaldo Total (BD + Fotos + Audios + Reportes)');
      return true;
    } catch (e) {
      debugPrint("❌ Error extrayendo evidencias totales: $e");
      if (dbEditable != null) await dbEditable.close();
      onProgress?.call(-1, "Ocurrió un error inesperado: $e");
      return false;
    } finally {
      if (workDir != null && await workDir.exists()) {
        try {
          await workDir.delete(recursive: true);
        } catch (_) {}
      }
    }
  }

  // ========================================================================
  // 3. RESTAURACIÓN SCOUT
  // ========================================================================
  Future<bool> restaurarRespaldo({required Function(String) onProgress}) async {
    Directory? extractDir;

    try {
      onProgress("Abriendo selector de archivos...");

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result == null || result.files.single.path == null) return false;

      final zipFile = File(result.files.single.path!);

      // LÍMITE DE 5 GB
      final int fileSizeInBytes = await zipFile.length();
      const int limit5GB = 5368709120;
      if (fileSizeInBytes > limit5GB) {
        onProgress("ERROR: El archivo supera el límite de 5 GB.");
        return false;
      }

      onProgress("Preparando descompresión...");
      final tempDir = await getTemporaryDirectory();
      extractDir = Directory(p.join(tempDir.path, 'restore_work'));

      if (await extractDir.exists()) await extractDir.delete(recursive: true);
      await extractDir.create(recursive: true);

      onProgress("Descomprimiendo archivo...");
      try {
        await extractArchiveToDisk(
          ZipDecoder().decodeBuffer(InputFileStream(zipFile.path)),
          extractDir.path,
        );
      } catch (e) {
        onProgress("ERROR: El ZIP está corrupto o no se puede leer.");
        return false;
      }

      final docsDir = await getApplicationDocumentsDirectory();
      int archivosCopiados = 0;
      bool encontroAlgo = false;

      onProgress("Analizando contenido del ZIP...");

      await for (var entity in extractDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final nombre = p.basename(entity.path).toLowerCase();

          if (!entity.path.contains('__MACOSX') &&
              !nombre.startsWith('.') &&
              !nombre.endsWith('.db') &&
              !nombre.endsWith('.json')) {
            try {
              encontroAlgo = true;
              final targetPath = p.join(docsDir.path, p.basename(entity.path));

              if (!await File(targetPath).exists()) {
                await File(targetPath).parent.create(recursive: true);
                await entity.copy(targetPath);
                archivosCopiados++;

                if (archivosCopiados % 50 == 0) {
                  onProgress(
                    "Copiando archivos... ($archivosCopiados procesados)",
                  );
                }
              } else {
                final String extension = p.extension(entity.path);
                final String baseName = p.basenameWithoutExtension(entity.path);
                final String nuevoNombre = "${baseName}_copiado$extension";
                final newPath = p.join(docsDir.path, nuevoNombre);

                await File(newPath).parent.create(recursive: true);
                await entity.copy(newPath);
                archivosCopiados++;
              }
            } catch (e) {
              debugPrint("⚠️ No se pudo copiar ${entity.path}: $e");
            }
          }
        }
      }

      if (encontroAlgo) {
        onProgress(
          "¡Éxito! $archivosCopiados archivos recuperados e importados.",
        );
        return true;
      } else {
        onProgress("ERROR: El ZIP está vacío o solo contiene bases de datos.");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error general restaurando: $e");
      onProgress("Error crítico: $e");
      return false;
    } finally {
      if (extractDir != null && await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
    }
  }

  // ========================================================================
  // 4. LIMPIADOR DE RESIDUOS
  // ========================================================================
  Future<Map<String, int>> limpiarResiduos({
    bool eliminarTemporales = true,
    bool eliminarHuerfanos = true,
  }) async {
    int tempEliminados = 0;
    int huerfanosEliminados = 0;

    final userId = DBManager.instance.currentUserId;

    if (eliminarTemporales) {
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (var entity in tempDir.list(recursive: true)) {
          try {
            if (entity is File) {
              await entity.delete();
              tempEliminados++;
            }
          } catch (_) {}
        }
      }
    }

    if (eliminarHuerfanos) {
      final docsDir = await getApplicationDocumentsDirectory();
      final rutasValidasEnBD = await _obtenerRutasFotosEnBD();

      if (await docsDir.exists()) {
        await for (var entity in docsDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            final pathLower = entity.path.toLowerCase();
            final isImage =
                pathLower.endsWith('.jpg') ||
                pathLower.endsWith('.png') ||
                pathLower.endsWith('.jpeg');

            if (isImage && !rutasValidasEnBD.contains(entity.path)) {
              try {
                await entity.delete();
                huerfanosEliminados++;
              } catch (_) {}
            }
          }
        }
      }
    }

    await DBManager.instance.fullReset();
    if (userId != null) {
      await DBManager.instance.initUserSession(userId);
    } else {
      await DBManager.instance.database;
    }

    debugPrint(
      "🔄 Limpieza finalizada. Temporales: $tempEliminados, Huérfanos: $huerfanosEliminados.",
    );
    return {'temporales': tempEliminados, 'huerfanos': huerfanosEliminados};
  }

  // ========================================================================
  // CONSULTA DE RUTAS VÁLIDAS EN BD
  // ========================================================================
  Future<Set<String>> _obtenerRutasFotosEnBD() async {
    Set<String> rutas = {};
    try {
      final db = await DBManager.instance.database;
      final columnasAFiltrar = [
        {'tabla': 'inventario_armamento', 'columna': 'foto_patrimonio'},
        {'tabla': 'inventario_especial', 'columna': 'foto_path'},
        {'tabla': 'inventario_miras', 'columna': 'foto_path'},
        {'tabla': 'intendencia', 'columna': 'foto_path'},
        {'tabla': 'inteligencia', 'columna': 'imagen'},
        {'tabla': 'operacional', 'columna': 'imagen'},
        {'tabla': 'personal', 'columna': 'foto_path'},
      ];

      for (var item in columnasAFiltrar) {
        try {
          final results = await db.query(
            item['tabla']!,
            where:
                '${item['columna']} IS NOT NULL AND ${item['columna']} != ""',
            columns: [item['columna']!],
          );
          for (var row in results) {
            final path = row[item['columna']] as String?;
            if (path != null && path.isNotEmpty) rutas.add(path);
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("⚠️ Error obteniendo rutas de fotos: $e");
    }
    return rutas;
  }
}
