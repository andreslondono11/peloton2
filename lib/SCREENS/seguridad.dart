import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Necesario para la ilustración
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:path/path.dart' as p show basename;
import 'package:path_provider/path_provider.dart';
import 'package:peloton/SCREENS/bakcup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:peloton/provider/apptex.dart';
import 'package:peloton/BD/db_manager.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path_pkg;
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:convert'; // Necesario para jsonEncode

class SeguridadScreen extends StatefulWidget {
  const SeguridadScreen({super.key});

  @override
  State<SeguridadScreen> createState() => _SeguridadScreenState();
}

class _SeguridadScreenState extends State<SeguridadScreen> {
  String? _nombreUsuario;
  String? _correoUsuario;
  bool _cargando = true;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    final db = await DBManager.instance.authDatabase;
    final prefs = await SharedPreferences.getInstance(); // NUEVO

    int? userId = DBManager.instance.currentUserId;

    // Si no hay usuario en memoria, lo buscamos en la tabla (o en SharedPreferences como respaldo)
    if (userId == null) {
      try {
        final sesion = await db.query('sesion_activa', limit: 1);
        if (sesion.isNotEmpty) {
          userId = sesion.first['usuario_id'] as int;
        } else {
          // PARACAÍDAS: Si la tabla fue borrada por el otro usuario, leemos el respaldo
          userId = prefs.getInt('last_logged_user_id');
        }

        if (userId != null) {
          await DBManager.instance.initUserSession(userId);
        }
      } catch (e) {
        print("Error sesión: $e");
        userId = prefs.getInt('last_logged_user_id'); // Segundo intento
      }
    }

    // Si ya tenemos un ID (venga de donde venga), cargamos su nombre
    if (userId != null) {
      try {
        final usuario = await db.query(
          'usuarios',
          where: 'id = ?',
          whereArgs: [userId],
          limit: 1,
        );
        if (usuario.isNotEmpty && mounted) {
          setState(() {
            _nombreUsuario = usuario.first['nombres'] as String?;
            _correoUsuario =
                usuario.first['correo'] as String? ??
                usuario.first['email'] as String?;
            _cargando = false;
          });
          return;
        }
      } catch (e) {}
    }

    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _realizarBackupLite() async {
    final _progressController = StreamController<String>.broadcast();
    bool cancelado = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<String>(
          stream: _progressController.stream,
          initialData: "Preparando base de datos...",
          builder: (context, snapshot) {
            return AlertDialog(
              title: const Text("Generando Backup (BD)"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    snapshot.data ?? "",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => cancelado = true,
                    child: const Text("Cancelar"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    File? dbTempFile;
    File? zipFinalFile;

    try {
      if (DBManager.instance.currentUserId == null)
        throw "No hay usuario activo.";

      final dbPath = await getDatabasesPath();
      final tempDir = await getTemporaryDirectory();
      final carpetaDb = Directory(dbPath);

      _progressController.add("Buscando base de datos activa...");
      await Future.delayed(const Duration(milliseconds: 300));

      // 1. BUSCAR CUALQUIER ARCHIVO .db EN LA CARPETA
      File? dbOriginal;
      if (await carpetaDb.exists()) {
        await for (var entity in carpetaDb.list()) {
          if (entity is File && entity.path.endsWith('.db')) {
            // Ignoramos los archivos temporales de SQLite (-wal, -shm)
            if (!entity.path.endsWith('-wal') &&
                !entity.path.endsWith('-shm')) {
              dbOriginal = entity;
              break; // Encontramos la BD principal, salimos del bucle
            }
          }
        }
      }

      // 2. VERIFICAR SI LA ENCONTRÓ
      if (dbOriginal == null || !await dbOriginal.exists()) {
        throw "No se encontró ningún archivo .db. ¿Abriste la base de datos al menos una vez?";
      }

      _progressController.add("Copiando ${dbOriginal.path.split('/').last}...");
      await Future.delayed(const Duration(milliseconds: 200));

      // 3. COPIAR A TEMPORAL Y RENOMBRAR A 'user.db'
      // Esto asegura que el ZIP siempre lleve 'user.db', sin importar cómo se llame en tu celular
      dbTempFile = File('${tempDir.path}/user.db');
      if (await dbTempFile.exists()) await dbTempFile.delete();
      await dbOriginal.copy(dbTempFile.path);

      if (cancelado) throw "Proceso cancelado.";

      // 4. CREAR ZIP
      _progressController.add("Comprimiendo base de datos...");
      await Future.delayed(const Duration(milliseconds: 100));

      String fecha = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      String zipName = 'BACKUP_${DBManager.instance.currentUserId}_$fecha.zip';

      zipFinalFile = File('${tempDir.path}/$zipName');

      final zipEncoder = ZipFileEncoder();
      zipEncoder.create(zipFinalFile.path);
      zipEncoder.addFile(
        dbTempFile,
        'user.db',
      ); // Lo mete en el zip con el nombre fijo
      zipEncoder.close();

      if (cancelado) throw "Proceso cancelado.";

      // 5. COMPARTIR
      int fileSizeInBytes = await zipFinalFile.length();
      String fileSizeMB = (fileSizeInBytes / (1024 * 1024)).toStringAsFixed(2);

      _progressController.add("¡Listo! Abriendo menú...");

      await Share.shareXFiles(
        [XFile(zipFinalFile.path)],
        subject: 'Backup BD CALIPSO ($fileSizeMB MB)',
        text: 'Adjunto base de datos comprimida.',
      );

      _mostrarMensaje("Backup creado ($fileSizeMB MB).");
    } catch (e) {
      _mostrarMensaje("Error: $e", isError: true);
    } finally {
      // LIMPIEZA
      try {
        if (dbTempFile != null && await dbTempFile.exists())
          await dbTempFile.delete();
        if (zipFinalFile != null && await zipFinalFile.exists())
          await zipFinalFile.delete();
      } catch (_) {}

      await _progressController.close();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _realizarBackupTotal() async {
    final _progressController = StreamController<String>.broadcast();
    bool cancelado = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<String>(
          stream: _progressController.stream,
          initialData: "Preparando...|0.0%",
          builder: (context, snapshot) {
            final data = snapshot.data ?? "||";
            final partes = data.split('|');
            final mensaje = partes.isNotEmpty ? partes[0] : "";
            final porcentajeTexto = partes.length > 1 ? partes[1] : "0.0%";
            final porcentajeDouble =
                double.tryParse(porcentajeTexto.replaceAll('%', '')) ?? 0.0;

            return AlertDialog(
              title: const Text("Crear Backup Total (ZIP)"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: porcentajeDouble / 100.0),
                  const SizedBox(height: 20),
                  Text(
                    mensaje,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    porcentajeTexto,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => cancelado = true,
                    child: const Text("Cancelar"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    File? metadataTemp;
    File? dbTempFile;
    File? zipFinalFile;

    try {
      final dbPath = await getDatabasesPath();
      final tempDir = await getTemporaryDirectory();
      final appDocsDir = await getApplicationDocumentsDirectory();

      // ====================================================================
      // OBTENER EL ID DEL USUARIO DE FORMA 100% SEGURA USANDO EL GETTER PÚBLICO
      // ====================================================================
      int currentUserId;

      // Usamos tu getter público. Si la app está aquí, esto NO debería ser null.
      if (DBManager.instance.currentUserId != null) {
        currentUserId = DBManager.instance.currentUserId!;
      } else {
        // Plan B: Si por algún extraño motivo es null, lo leemos directo de la BD global
        final globalDbPath = '$dbPath/tablet_app.db';
        if (!await File(globalDbPath).exists())
          throw "Error crítico: No hay sesión iniciada.";

        final globalDb = await openDatabase(globalDbPath, readOnly: true);
        final res = await globalDb.query(
          'sesion_activa',
          columns: ['usuario_id'],
          limit: 1,
        );
        await globalDb.close();

        if (res.isEmpty)
          throw "Error: No se encontró usuario activo en el sistema.";
        currentUserId = res.first['usuario_id'] as int;
      }
      // ====================================================================

      _progressController.add("Preparando base de datos...|5.0%");

      // A. Crear Metadata
      metadataTemp = File('${tempDir.path}/metadata.json');
      await metadataTemp.writeAsString('{"usuario_id": "$currentUserId"}');

      // B. Copiar BD a temporal
      String dbFileName = 'calipso_user_$currentUserId.db';
      File dbSource = File('$dbPath/$dbFileName');
      dbTempFile = File('${tempDir.path}/$dbFileName');

      if (!await dbSource.exists())
        throw "No se encontró la base de datos $dbFileName.";
      if (await dbTempFile.exists()) await dbTempFile.delete();
      await dbSource.copy(dbTempFile.path);

      // C. Escanear archivos multimedia
      final sourceFilesDir = Directory(
        '${appDocsDir.path}/archivos_usuario/$currentUserId',
      );
      List<File> archivosParaComprimir = [];

      if (await sourceFilesDir.exists()) {
        _progressController.add("Escaneando archivos multimedia...|10.0%");
        await for (var entity in sourceFilesDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) archivosParaComprimir.add(entity);
        }
      }

      // 2. CREAR ZIP ANTI-OOM
      _progressController.add("Comprimiendo en ZIP...|15.0%");
      String fecha = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      String zipName =
          'BACKUP_TOTAL_${DBManager.instance.currentUserId}_$fecha.zip';
      zipFinalFile = File('${tempDir.path}/$zipName');

      final zipEncoder = ZipFileEncoder();
      zipEncoder.create(zipFinalFile.path);

      zipEncoder.addFile(metadataTemp, 'metadata.json');
      zipEncoder.addFile(dbTempFile, dbFileName);

      if (archivosParaComprimir.isNotEmpty) {
        int procesados = 0;
        int totalArchivos = archivosParaComprimir.length;

        for (var entity in archivosParaComprimir) {
          if (cancelado) break;

          String relativePath = path_pkg.relative(
            entity.path,
            from: sourceFilesDir.path,
          );
          zipEncoder.addFile(entity, 'archivos/$relativePath');

          procesados++;
          if (procesados % 10 == 0 || procesados == totalArchivos) {
            double pct = 15.0 + ((procesados / totalArchivos) * 80.0);
            _progressController.add(
              "Comprimiendo ${procesados + 1}/$totalArchivos|${pct.toStringAsFixed(1)}%",
            );
            await Future.delayed(const Duration(milliseconds: 1));
          }
        }
      } else {
        _progressController.add("No hay multimedia, finalizando ZIP...|95.0%");
      }

      zipEncoder.close();

      if (cancelado) throw "Cancelado por el usuario.";

      // 3. GUARDAR EN CARPETA
      _progressController.add("Abriendo explorador de archivos...|98.0%");
      String? outputPath = await FilePicker.platform.saveFile(
        fileName: zipName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (outputPath != null) {
        await zipFinalFile.copy(outputPath);
        int sizeBytes = await zipFinalFile.length();
        String sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
        _mostrarMensaje("Backup Total guardado ($sizeMB MB).");
      } else {
        _mostrarMensaje("No se seleccionó carpeta.", isError: true);
      }
    } catch (e) {
      _mostrarMensaje("Error: $e", isError: true);
    } finally {
      // LIMPIEZA
      try {
        if (metadataTemp != null && await metadataTemp.exists())
          await metadataTemp.delete();
        if (dbTempFile != null && await dbTempFile.exists())
          await dbTempFile.delete();
        if (zipFinalFile != null && await zipFinalFile.exists())
          await zipFinalFile.delete();
      } catch (_) {}

      await _progressController.close();
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ========================================================================
  // NUEVO: RESPALDO EN CARPETAS REALES (Sin ZIP, sin límites de peso)
  // ========================================================================
  Future<void> _realizarRestauracionTotal() async {
    final _progressController = StreamController<String>.broadcast();

    // Diálogo de progreso moderno
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<String>(
          stream: _progressController.stream,
          initialData: "Preparando respaldo por carpetas...|0.0%",
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
                "Respaldo por Carpetas",
                textAlign: TextAlign.center,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Indicador circular moderno
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
                    "⚠️ NO CIERRE LA APP\nMientras se copian los archivos a la carpeta seleccionada.",
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    mensaje,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      final userId = DBManager.instance.currentUserId;
      if (userId == null) {
        _progressController.add("Error: No hay usuario logueado.|0.0%");
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // 1. ELEGIR CARPETA DE DESTINO EN EL CELULAR/TARJETA SD
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Seleccione dónde guardar la carpeta del respaldo",
      );

      if (selectedDirectory == null) {
        await _progressController.close();
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // 2. CREAR CARPETA RAIZ CON EL NOMBRE DEL USUARIO
      final nombreCarpetaRaiz = 'RESPALDO_COMPLETO_USUARIO_$userId';
      final destinoBaseDir = Directory(
        p.join(selectedDirectory, nombreCarpetaRaiz),
      );
      await destinoBaseDir.create(recursive: true);

      // 3. CREAR ESTRUCTURA INTERNA (Discriminada por tipo de archivo)
      _progressController.add("Creando estructura de carpetas...|5.0%");
      final carpetaImagenes = Directory(
        p.join(destinoBaseDir.path, '01_IMAGENES'),
      );
      final carpetaVideos = Directory(p.join(destinoBaseDir.path, '02_VIDEOS'));
      final carpetaAudios = Directory(p.join(destinoBaseDir.path, '03_AUDIOS'));
      final carpetaDocumentos = Directory(
        p.join(destinoBaseDir.path, '04_DOCUMENTOS_PDF_EXCEL'),
      );
      final carpetaOtros = Directory(
        p.join(destinoBaseDir.path, '05_OTROS_FORMATOS'),
      );

      await carpetaImagenes.create(recursive: true);
      await carpetaVideos.create(recursive: true);
      await carpetaAudios.create(recursive: true);
      await carpetaDocumentos.create(recursive: true);
      await carpetaOtros.create(recursive: true);

      // 4. ESCANEAR LO QUE EL USUARIO TIENE GUARDADO EN LA APP
      _progressController.add("Escaneando evidencias ingresadas...|10.0%");
      final appDocsDir = await getApplicationDocumentsDirectory();

      List<File> archivosParaCopiar = [];
      if (await appDocsDir.exists()) {
        await for (var entity in appDocsDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) archivosParaCopiar.add(entity);
        }
      }

      if (archivosParaCopiar.isEmpty) {
        _progressController.add("No hay archivos para respaldar.|0.0%");
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // 5. COPIAR Y CLASIFICAR ARCHIVO POR ARCHIVO
      int archivosProcesados = 0;
      int totalArchivos = archivosParaCopiar.length;

      for (final archivo in archivosParaCopiar) {
        archivosProcesados++;
        double porcentaje =
            10.0 + ((archivosProcesados / totalArchivos) * 85.0);

        final nombreArchivo = p.basename(archivo.path);
        _progressController.add(
          "Copiando: $nombreArchivo|${porcentaje.toStringAsFixed(1)}%",
        );

        // Ignorar archivos internos de la app
        if (nombreArchivo.endsWith('.db') || nombreArchivo.endsWith('.json')) {
          continue;
        }

        // Discriminar por extensión
        Directory carpetaDestino;
        final extension = p
            .basename(archivo.path)
            .split('.')
            .last
            .toLowerCase();

        if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
          carpetaDestino = carpetaImagenes;
        } else if ([
          'mp4',
          'mov',
          'avi',
          'mkv',
          'webm',
          '3gp',
        ].contains(extension)) {
          carpetaDestino = carpetaVideos;
        } else if ([
          'mp3',
          'wav',
          'm4a',
          'aac',
          'ogg',
          'flac',
          'amr',
        ].contains(extension)) {
          carpetaDestino = carpetaAudios;
        } else if ([
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'csv',
        ].contains(extension)) {
          carpetaDestino = carpetaDocumentos;
        } else {
          carpetaDestino = carpetaOtros;
        }

        // Evitar sobreescribir si hay archivos con el mismo nombre
        String rutaFinal = p.join(carpetaDestino.path, nombreArchivo);
        int contador = 1;
        while (await File(rutaFinal).exists()) {
          final String baseName = nombreArchivo.replaceAll(
            '.${extension.split('').last}',
            '',
          ); // Quita la extensión
          rutaFinal = p.join(
            carpetaDestino.path,
            '${baseName}_($contador).$extension',
          );
          contador++;
        }

        // Copiar físico al disco de destino
        await archivo.copy(rutaFinal);
      }

      // 6. ÉXITO TOTAL
      _progressController.add("¡Respaldo en carpetas terminado!|100.0%");
      await Future.delayed(const Duration(milliseconds: 2000));

      if (mounted) {
        Navigator.of(context).pop(); // Cierra diálogo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Respaldo físico creado exitosamente en $nombreCarpetaRaiz",
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error en respaldo por carpetas: $e");
      _progressController.add("Error al copiar: $e|0.0%");
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.of(context).pop();
    } finally {
      await _progressController.close();
    }
  }

  // Future<void> _realizarRestauracionTotal() async {
  //   final _progressController = StreamController<String>.broadcast();

  //   // Diálogo de progreso
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) {
  //       return StreamBuilder<String>(
  //         stream: _progressController.stream,
  //         initialData: "Seleccionando carpeta de destino...|0.0%",
  //         builder: (context, snapshot) {
  //           final data = snapshot.data ?? "||";
  //           final partes = data.split('|');
  //           final mensaje = partes.isNotEmpty ? partes[0] : "";
  //           final porcentajeTexto = partes.length > 1 ? partes[1] : "0.0%";
  //           final porcentajeDouble = double.tryParse(porcentajeTexto.replaceAll('%', '')) ?? 0.0;

  //           return AlertDialog(
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //             title: const Text("Exportar Evidencias a Carpeta"),
  //             content: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 LinearProgressIndicator(value: porcentajeDouble / 100.0, minHeight: 8),
  //                 const SizedBox(height: 20),
  //                 Text(mensaje, style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center, maxLines: 3),
  //                 const SizedBox(height: 10),
  //                 Text(porcentajeTexto, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );

  //   try {
  //     // 1. ELEGIR CARPETA DE DESTINO (Nativo del sistema)
  //     // Nota: Requiere tener implementado el permiso en AndroidManifest para Android 11+
  //     String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
  //       dialogTitle: "Seleccione dónde guardar las carpetas",
  //     );

  //     if (selectedDirectory == null) {
  //       await _progressController.close();
  //       if (mounted) Navigator.of(context).pop();
  //       return;
  //     }

  //     final destinoBaseDir = Directory(selectedDirectory);

  //     // 2. ELEGIR EL ARCHIVO ZIP
  //     _progressController.add("Seleccione el archivo ZIP a leer...|2.0%");
  //     FilePickerResult? result = await FilePicker.platform.pickFiles(
  //       type: FileType.custom,
  //       allowedExtensions: ['zip'],
  //       withData: false, // CRÍTICO: No cargar en RAM
  //     );

  //     if (result == null || result.files.single.path == null) {
  //       await _progressController.close();
  //       if (mounted) Navigator.of(context).pop();
  //       return;
  //     }

  //     File zipFile = File(result.files.single.path!);

  //     // 3. CREAR ESTRUCTURA DE CARPETAS
  //     _progressController.add("Creando estructura de carpetas...|5.0%");
  //     final carpetaImagenes = Directory(p.join(destinoBaseDir.path, '01_Imagenes'));
  //     final carpetaVideos = Directory(p.join(destinoBaseDir.path, '02_Videos'));
  //     final carpetaAudios = Directory(p.join(destinoBaseDir.path, '03_Audios'));
  //     final carpetaDocumentos = Directory(p.join(destinoBaseDir.path, '04_Documentos'));
  //     final carpetaOtros = Directory(p.join(destinoBaseDir.path, '05_Otros_Formatos'));

  //     await carpetaImagenes.create(recursive: true);
  //     await carpetaVideos.create(recursive: true);
  //     await carpetaAudios.create(recursive: true);
  //     await carpetaDocumentos.create(recursive: true);
  //     await carpetaOtros.create(recursive: true);

  //     // 4. LEER ZIP DIRECTO A DISCO (ANTI-OOM)
  //     _progressController.add("Leyendo estructura del ZIP...|10.0%");
  //     final inputStream = InputFileStream(zipFile.path);
  //     final archive = ZipDecoder().decodeBuffer(inputStream);

  //     int archivosProcesados = 0;
  //     final totalArchivos = archive.length;

  //     // 5. PROCESAR CADA ARCHIVO DEL ZIP Y CLASIFICARLO
  //     for (final file in archive) {
  //       archivosProcesados++;

  //       // Calculamos el progreso (del 10% al 90%)
  //       double porcentaje = 10.0 + ((archivosProcesados / totalArchivos) * 80.0);
  //       _progressController.add(
  //         "Clasificando: ${file.name}|${porcentaje.toStringAsFixed(1)}%",
  //       );

  //       if (file.isFile) {
  //         final nombreArchivo = p.basename(file.name);

  //         // Ignorar bases de datos y archivos basura de Mac
  //         if (nombreArchivo.endsWith('.db') ||
  //             nombreArchivo.endsWith('.json') ||
  //             file.name.contains('__MACOSX')) {
  //           continue;
  //         }

  //         // Determinar la carpeta destino según la extensión
  //         Directory carpetaDestino;
  //         final extension = p.extension(nombreArchivo).toLowerCase();

  //         if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
  //           carpetaDestino = carpetaImagenes;
  //         } else if (['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(extension)) {
  //           carpetaDestino = carpetaVideos;
  //         } else if (['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'].contains(extension)) {
  //           carpetaDestino = carpetaAudios;
  //         } else if (['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.csv'].contains(extension)) {
  //           carpetaDestino = carpetaDocumentos;
  //         } else {
  //           carpetaDestino = carpetaOtros;
  //         }

  //         // Escribir el archivo directo al disco duro en su nueva carpeta
  //         final outputPath = p.join(carpetaDestino.path, nombreArchivo);
  //         final fileDestino = File(outputPath);

  //         final outputStream = OutputFileStream(fileDestino.path);
  //         file.writeContent(outputStream);
  //         await outputStream.close();
  //       }
  //     }

  //     // 6. FINALIZADO
  //     _progressController.add("¡Exportación completa a carpetas!|100.0%");
  //     await Future.delayed(const Duration(milliseconds: 2000)); // Pausa para que el usuario vea el 100%

  //     if (mounted) {
  //       Navigator.of(context).pop(); // Cierra el diálogo de progreso
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text("✅ Evidencias guardadas en: $selectedDirectory"),
  //           backgroundColor: Colors.green,
  //           duration: const Duration(seconds: 5),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     _progressController.add("Error: $e|0.0%");
  //     await Future.delayed(const Duration(seconds: 2));
  //     if (mounted) {
  //       Navigator.of(context).pop(); // Cierra diálogo
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Error al exportar: $e"), backgroundColor: Colors.red),
  //       );
  //     }
  //   } finally {
  //     await _progressController.close();
  //   }
  // }
  // // --- EXPORTAR ARCHIVOS FÍSICOS DIRECTAMENTE A CARPETA ---
  Future<void> _exportarArchivosACarpeta() async {
    final _progressController = StreamController<String>.broadcast();
    bool cancelado = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<String>(
          stream: _progressController.stream,
          initialData: "Preparando...",
          builder: (context, snapshot) {
            return AlertDialog(
              title: const Text("Exportar Adjuntos"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    snapshot.data ?? "",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => cancelado = true,
                    child: const Text("Cancelar"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      final appDocsDir = await getApplicationDocumentsDirectory();
      final dbPath = await getDatabasesPath();

      // OBTENER ID
      int currentUserId;
      if (DBManager.instance.currentUserId != null) {
        currentUserId = DBManager.instance.currentUserId!;
      } else {
        final globalDb = await openDatabase(
          '$dbPath/tablet_app.db',
          readOnly: true,
        );
        final res = await globalDb.query(
          'sesion_activa',
          columns: ['usuario_id'],
          limit: 1,
        );
        await globalDb.close();
        if (res.isEmpty) throw "No hay ningún usuario con sesión activa.";
        currentUserId = res.first['usuario_id'] as int;
      }

      final sourceDir = Directory(
        '${appDocsDir.path}/archivos_usuario/$currentUserId',
      );

      // ========================================================
      // DEBUG: Imprime en tu consola la ruta que está buscando
      // ========================================================
      print("=== RUTA QUE BUSCA LA APP: ${sourceDir.path} ===");
      print("=== ¿EXISTE LA CARPETA? ${await sourceDir.exists()} ===");

      // Si quieres ver TODO lo que hay dentro de la carpeta principal de la app, descomenta esto:
      // await for (var entity in appDocsDir.list(recursive: false)) {
      //   print("CARPETA ENCONTRADA: ${entity.path}");
      // }
      // ========================================================

      if (!await sourceDir.exists()) {
        throw "No hay carpeta de archivos adjuntos para este usuario (ID: $currentUserId).\nAsegúrate de que este usuario haya guardado fotos o audios antes de exportar.";
      }

      // 1. EL USUARIO ELIGE DÓNDE GUARDAR LA CARPETA
      _progressController.add("Abriendo explorador de archivos...");
      String? outputDirectoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Selecciona dónde guardar la carpeta de adjuntos",
      );

      if (outputDirectoryPath == null) {
        cancelado = true;
      }

      if (!cancelado) {
        // ... (El resto del código sigue igual debajo, no lo borres) ...
        // 2. CREAR CARPETA DESTINO
        String fecha = DateFormat(
          'yyyy-MM-dd_HH-mm',
        ).format(DateTime.now()).replaceAll(':', 'h');
        final destinoDir = Directory(
          '$outputDirectoryPath/ADJUNTOS_CALIPSO_$fecha',
        );
        await destinoDir.create(recursive: true);

        _progressController.add("Escaneando archivos...");

        // 3. OBTENER LISTA DE ARCHIVOS
        List<File> archivos = [];
        await for (var entity in sourceDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) archivos.add(entity);
        }

        if (archivos.isEmpty) {
          if (await destinoDir.exists()) await destinoDir.delete();
          throw "La carpeta del usuario existe, pero está completamente vacía (No hay fotos ni audios).";
        }

        int totalArchivos = archivos.length;
        int procesados = 0;

        // 4. COPIAR DISCO A DISCO
        for (var file in archivos) {
          if (cancelado) break;
          procesados++;

          if (procesados % 10 == 0 ||
              procesados == 1 ||
              procesados == totalArchivos) {
            double porcentaje = (procesados / totalArchivos) * 100;
            _progressController.add(
              "Copiando archivos...\n$procesados de $totalArchivos (${porcentaje.toStringAsFixed(1)}%)",
            );
            await Future.delayed(const Duration(milliseconds: 5));
          }

          try {
            String relativePath = path_pkg.relative(
              file.path,
              from: sourceDir.path,
            );
            File destinoArchivo = File('${destinoDir.path}/$relativePath');
            await destinoArchivo.parent.create(recursive: true);
            await file.copy(destinoArchivo.path);
          } catch (e) {
            print("Omitido (bloqueado): ${file.path}");
          }
        }

        // 5. FINALIZAR
        if (!cancelado) {
          _mostrarMensaje(
            "Archivos exportados exitosamente a:\n${destinoDir.path}",
          );
        } else {
          if (await destinoDir.exists())
            await destinoDir.delete(recursive: true);
          _mostrarMensaje("Proceso cancelado.", isError: true);
        }
      }
    } catch (e) {
      _mostrarMensaje("Error al exportar: $e", isError: true);
    } finally {
      await _progressController.close();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _crearBackupTotalEnCarpeta() async {
    final _progressController = StreamController<String>.broadcast();
    bool cancelado = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<String>(
          stream: _progressController.stream,
          initialData: "Preparando...|0.0%",
          builder: (context, snapshot) {
            final data = snapshot.data ?? "||";
            final partes = data.split('|');
            final mensaje = partes.isNotEmpty ? partes[0] : "";
            final porcentajeTexto = partes.length > 1 ? partes[1] : "0.0%";
            final porcentajeDouble =
                double.tryParse(porcentajeTexto.replaceAll('%', '')) ?? 0.0;

            return AlertDialog(
              title: const Text("Crear Backup Total"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: porcentajeDouble / 100.0),
                  const SizedBox(height: 20),
                  Text(
                    mensaje,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    porcentajeTexto,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () => cancelado = true,
                    child: const Text("Cancelar"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    File? metadataTemp;
    File? dbTempFile;
    File? zipFinalFile;

    try {
      final dbPath = await getDatabasesPath();
      final tempDir = await getTemporaryDirectory();
      final appDocsDir = await getApplicationDocumentsDirectory();

      // 1. OBTENER ID DE USUARIO
      int currentUserId =
          DBManager.instance.currentUserId ??
          await (() async {
            final db = await openDatabase(
              '$dbPath/tablet_app.db',
              readOnly: true,
            );
            final rows = await db.query(
              'sesion_activa',
              columns: ['usuario_id'],
              limit: 1,
            );
            if (rows.isEmpty) throw "No hay sesión";
            return rows.first['usuario_id'] as int;
          })();
      _progressController.add("Preparando archivos...|5.0%");

      // 2. CREAR METADATA Y COPIAR BD A TEMPORAL
      metadataTemp = File('${tempDir.path}/metadata.json');
      await metadataTemp.writeAsString('{"usuario_id": "$currentUserId"}');

      String dbFileName = 'calipso_user_$currentUserId.db';
      File dbSource = File('$dbPath/$dbFileName');
      dbTempFile = File('${tempDir.path}/$dbFileName');

      if (!await dbSource.exists()) throw "No se encontró la base de datos.";
      if (await dbTempFile.exists()) await dbTempFile.delete();
      await dbSource.copy(dbTempFile.path);

      // 3. ESCANEAR MULTIMEDIA
      final sourceFilesDir = Directory(
        '${appDocsDir.path}/archivos_usuario/$currentUserId',
      );
      List<File> archivos = [];
      if (await sourceFilesDir.exists()) {
        await for (var entity in sourceFilesDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) archivos.add(entity);
        }
      }

      // 4. CREAR ZIP (Paso obligatorio antes de guardar)
      _progressController.add("Comprimiendo archivos...|15.0%");
      String fecha = DateFormat(
        'yyyy-MM-dd_HH-mm-ss',
      ).format(DateTime.now()).replaceAll(':', 'h');
      String zipName =
          'BACKUP_$currentUserId\_$fecha.zip'; // Ojo: escapé el guion bajo con \ para que no lo confunda con variable
      zipFinalFile = File('${tempDir.path}/$zipName');

      final zipEncoder = ZipFileEncoder();
      zipEncoder.create(zipFinalFile.path);
      zipEncoder.addFile(metadataTemp, 'metadata.json');
      zipEncoder.addFile(dbTempFile, dbFileName);

      // Añadir fotos/audios al zip
      for (int i = 0; i < archivos.length; i++) {
        if (cancelado) break;
        String relPath = path_pkg.relative(
          archivos[i].path,
          from: sourceFilesDir.path,
        );
        zipEncoder.addFile(archivos[i], 'archivos/$relPath');

        if (i % 10 == 0) {
          double pct = 15.0 + ((i / archivos.length) * 80.0);
          _progressController.add(
            "Comprimiendo ${i + 1}/${archivos.length}|${pct.toStringAsFixed(1)}%",
          );
          await Future.delayed(const Duration(milliseconds: 1));
        }
      }

      // CERRAR EL ZIP (Aquí se termina de escribir en la carpeta temporal)
      zipEncoder.close();
      if (cancelado) throw "Cancelado.";

      // ====================================================================
      // 5. ABRIR EXPLORADOR Y COPIAR A LA CARPETA QUE ELIJA EL USUARIO
      // ====================================================================
      _progressController.add("Abriendo explorador...|98.0%");

      // Se usa getDirectoryPath en lugar de saveFile para evitar el error de "Bytes required"
      String? carpetaElegida = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "¿Dónde quieres guardar el Backup?",
      );

      if (carpetaElegida != null) {
        // Copiamos el ZIP temporal a la carpeta que eligió
        final rutaFinal = File('$carpetaElegida/$zipName');
        await zipFinalFile.copy(rutaFinal.path);

        int sizeBytes = await zipFinalFile.length();
        String sizeMB = (sizeBytes / (1024 * 1024)).toStringAsFixed(2);
        _mostrarMensaje("Backup guardado exitosamente ($sizeMB MB).");
      } else {
        _mostrarMensaje("No se eligió ninguna carpeta.", isError: true);
      }
    } catch (e) {
      _mostrarMensaje("Error: $e", isError: true);
    } finally {
      // LIMPIEZA DE TEMPORALES
      try {
        if (metadataTemp != null && await metadataTemp.exists())
          await metadataTemp.delete();
        if (dbTempFile != null && await dbTempFile.exists())
          await dbTempFile.delete();
        if (zipFinalFile != null && await zipFinalFile.exists())
          await zipFinalFile.delete();
      } catch (_) {}

      await _progressController.close();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _recuperarBackupTotal() async {
    final _progressController = StreamController<String>.broadcast();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StreamBuilder<String>(
          stream: _progressController.stream,
          initialData: "Seleccionando archivo ZIP...|0.0%",
          builder: (context, snapshot) {
            final data = snapshot.data ?? "||";
            final partes = data.split('|');
            final mensaje = partes.isNotEmpty ? partes[0] : "";
            final porcentajeTexto = partes.length > 1 ? partes[1] : "0.0%";
            final porcentajeDouble =
                double.tryParse(porcentajeTexto.replaceAll('%', '')) ?? 0.0;

            return AlertDialog(
              title: const Text("Restaurar Copia Total (ZIP)"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: porcentajeDouble / 100.0),
                  const SizedBox(height: 20),
                  Text(
                    mensaje,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    porcentajeTexto,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      // 1. ELEGIR ZIP
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: false, // CRÍTICO ANTI-OOM
      );

      if (result == null || result.files.single.path == null) {
        await _progressController.close();
        if (mounted) Navigator.of(context).pop();
        return;
      }

      File zipFile = File(result.files.single.path!);
      final dbPath = await getDatabasesPath();
      final tempDir = await getTemporaryDirectory();
      final appDocsDir = await getApplicationDocumentsDirectory();

      // 2. CERRAR SESION ACTUAL COMPLETAMENTE
      _progressController.add("Cerrando base de datos actual...|0.0%");
      await Future.delayed(const Duration(milliseconds: 300));
      await DBManager.instance.fullReset();

      // 3. EXTRAER ZIP DIRECTO A DISCO (SIN PASAR POR RAM)
      _progressController.add("Extrayendo archivos del ZIP...|5.0%");
      final inputStream = InputFileStream(zipFile.path);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      int archivosProcesados = 0;
      final totalArchivos = archive.length;

      for (final file in archive) {
        archivosProcesados++;
        double porcentaje = 5.0 + ((archivosProcesados / totalArchivos) * 85.0);
        _progressController.add(
          "Extrayendo: ${file.name}|${porcentaje.toStringAsFixed(1)}%",
        );

        if (file.isFile) {
          final outputPath = '${tempDir.path}/${file.name}';
          final fileDestino = File(outputPath);
          await fileDestino.parent.create(recursive: true);

          // ESCRIBIR DIRECTO A DISCO DURO
          final outputStream = OutputFileStream(fileDestino.path);
          file.writeContent(outputStream);
          await outputStream.close();
        }
      }

      // 4. LEER METADATA (Ahora sí, porque ya está en disco, no en RAM)
      _progressController.add("Verificando usuario de respaldo...|92.0%");
      final metadataFile = File('${tempDir.path}/metadata.json');
      if (!await metadataFile.exists())
        throw "El ZIP no contiene metadata.json (Formato inválido).";

      final metadataRaw = await metadataFile.readAsString();
      final metadata = jsonDecode(metadataRaw);
      final idUsuarioBackup = int.parse(metadata['usuario_id'].toString());

      // 5. MOVER BASE DE DATOS A SU LUGAR OFICIAL
      _progressController.add("Restaurando Base de Datos...|95.0%");
      String dbFileName = 'calipso_user_$idUsuarioBackup.db';
      final dbExtraida = File('${tempDir.path}/$dbFileName');
      final dbDestino = File('$dbPath/$dbFileName');

      if (await dbExtraida.exists()) {
        if (await dbDestino.exists()) await dbDestino.delete(); // Borrar vieja
        await dbExtraida.copy(dbDestino.path); // Mover a ruta oficial
      } else {
        throw "El ZIP no contiene la base de datos $dbFileName.";
      }

      // 6. MOVER ARCHIVOS MULTIMEDIA A SU LUGAR OFICIAL
      final archivosExtraidosDir = Directory('${tempDir.path}/archivos');
      if (await archivosExtraidosDir.exists()) {
        _progressController.add("Moviendo archivos multimedia...|98.0%");
        final destinoFinalDir = Directory(
          '${appDocsDir.path}/archivos_usuario/$idUsuarioBackup',
        );

        if (await destinoFinalDir.exists())
          await destinoFinalDir.delete(recursive: true);

        // Mover la carpeta entera de golpe (es rapidísimo a nivel de sistema operativo)
        await archivosExtraidosDir.rename(destinoFinalDir.path);
      }

      // 7. ASIGNAR USUARIO Y REINICIAR APP
      _progressController.add(
        "¡Restauración Completa! Iniciando sesión...|100.0%",
      );
      await Future.delayed(const Duration(milliseconds: 1500));

      // Inyectar el usuario al DBManager
      await DBManager.instance.initUserSession(idUsuarioBackup);

      // Reiniciar UI
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      _mostrarMensaje("Error restaurando: $e", isError: true);
    } finally {
      await _progressController.close();
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _realizarFactoryReset() async {
    // 1. Diálogo de opciones
    final opcionElegida = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Opciones de Limpieza"),
        content: const Text("¿Qué deseas eliminar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'USUARIO'),
            child: const Text("Mis Datos (Usuario actual)"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'TOTAL'),
            child: const Text(
              "BORRAR TODO (Factory Reset)",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancelar"),
          ),
        ],
      ),
    );

    if (opcionElegida == null) return;

    if (opcionElegida == 'USUARIO') {
      await _borrarDatosUsuario();
    } else if (opcionElegida == 'TOTAL') {
      await _factoryResetTotal();
    }
  }

  // --- LÓGICA 1: BORRAR SOLO LOS DATOS DEL USUARIO LOGEADO ---
  Future<void> _borrarDatosUsuario() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Borrar tus datos?"),
        content: const Text(
          "Se eliminarán todos tus registros (minutas, personal, etc.) y tus archivos adjuntos. La estructura de la app permanecerá intacta.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "BORRAR MIS DATOS",
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    setState(() => _procesando = true);

    try {
      Database? dbUser = await DBManager.instance.database;

      if (dbUser != null) {
        List<String> tablas = [
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

        for (var tabla in tablas) {
          try {
            await dbUser.delete(tabla);
          } catch (e) {
            print("Error vaciando tabla $tabla: $e");
          }
        }

        // Optimizar el archivo BD después de borrar todo (reduce el tamaño a 0KB)
        try {
          await dbUser.execute("VACUUM");
        } catch (e) {
          print("Error haciendo vacuum: $e");
        }
      }

      // Borrar archivos de la carpeta específica
      final tempDir = await getTemporaryDirectory();
      final userFilesDir = Directory('${tempDir.path}/archivos');

      if (await userFilesDir.exists()) {
        await for (var entity in userFilesDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            try {
              await entity.delete();
            } catch (e) {
              print("Archivo en uso: ${entity.path}");
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Limpiar UI
        _mostrarMensaje("Datos eliminados. Reiniciando...");
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      // ---> REINICIO BRUTO
      if (mounted) exit(0);
    } catch (e) {
      _mostrarMensaje("Error al borrar datos: $e", isError: true);
      if (mounted) setState(() => _procesando = false);
    }
  }

  // --- LÓGICA 2: FACTORY RESET (DESTRUIR TODO) ---
  Future<void> _factoryResetTotal() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("⚠️ FACTORY RESET"),
        content: const Text(
          "ESTO ELIMINARÁ TODO:\n\n- Sesiones de todos los usuarios.\n- Todas las bases de datos.\n- Todos los archivos adjuntos.\n\nLa app se reiniciará como recién instalada.",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Mejor no"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "SÍ, BORRAR TODO",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    setState(() => _procesando = true);

    try {
      // 1. Cerrar AMBAS bases de datos para desbloquear los archivos
      await DBManager.instance.fullReset();

      // Pausa para que el SO libere el bloqueo del archivo físico
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Buscar y eliminar TODAS las bases de datos .db
      final dbPath = await getDatabasesPath();
      final dbDir = Directory(dbPath);

      if (await dbDir.exists()) {
        await for (var entity in dbDir.list()) {
          if (entity is File && entity.path.endsWith('.db')) {
            try {
              await entity.delete();
            } catch (e) {
              print("DB bloqueada: ${entity.path}");
            }
          }
        }
      }

      // 3. Limpiar archivos adjuntos del caché
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await for (var entity in tempDir.list(
          recursive: true,
          followLinks: false,
        )) {
          if (entity is File) {
            try {
              await entity.delete();
            } catch (e) {
              print("Archivo bloqueado: ${entity.path}");
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Limpiar UI
        _mostrarMensaje("App restaurada de fábrica. Reiniciando...");
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      // ---> REINICIO BRUTO
      if (mounted) exit(0);
    } catch (e) {
      _mostrarMensaje("Error en Factory Reset: $e", isError: true);
      if (mounted) setState(() => _procesando = false);
    }
  }

  // --- FUNCIÓN AUXILIAR ---
  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "POLÍTICAS DE SEGURIDAD",
          style: AppStyles.mainTitle(
            context,
          ).copyWith(color: Colors.white, fontSize: 18, letterSpacing: 1.5),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    _nombreUsuario != null && _nombreUsuario!.isNotEmpty
                        ? _nombreUsuario![0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _nombreUsuario ?? "Usuario",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _correoUsuario ?? "usuario@ejemplo.com",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: _procesando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 950),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161B22) : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                    border: isDark ? Border.all(color: Colors.white10) : null,
                  ),
                  child: Column(
                    children: [
                      // --- HEADER CON ILUSTRACIÓN INTEGRADA ---
                      _buildHeaderWithIllustration(isDark),

                      Padding(
                        padding: const EdgeInsets.all(45),
                        child: Column(
                          children: [
                            // Texto de Políticas Detalladas
                            _buildPoliticasTexto(isDark),

                            const SizedBox(height: 40),
                            _divider(isDark),

                            // SECCIÓN NUEVA: BACKUP LITE
                            _seccionPolitica(
                              context,
                              Icons.data_object_rounded,
                              "Backup Lite (Solo Textos/Tablas)",
                              "Genera un archivo JSON ligero con todos los registros insertados en las tablas (ideal para texto puro, sin imágenes).",
                            ),
                            _divider(isDark),

                            _seccionPolitica(
                              context,
                              Icons.backup_rounded,
                              "Backup Total (ZIP)",
                              "Guarda Textos, Tablas e Imágenes en un archivo comprimido en tu dispositivo.",
                            ),
                            _divider(isDark),
                            _seccionPolitica(
                              context,
                              Icons.share_rounded,
                              "Compartir Archivos",
                              "Comprime solo los archivos adjuntos (Imágenes/PDF) y los envía para compartir.",
                            ),
                            _divider(isDark),
                            InkWell(
                              onTap: () {
                                // Abre la clase que te di como un Dialogo de pantalla completa
                                showGeneralDialog(
                                  context: context,
                                  barrierDismissible:
                                      false, // Evita que cierre tocando fuera al estar procesando
                                  pageBuilder: (context, anim1, anim2) {
                                    return RestoreBackupScreen(); // Tu clase aquí
                                  },
                                  transitionBuilder:
                                      (context, anim1, anim2, child) {
                                        return FadeTransition(
                                          opacity: anim1,
                                          child: child,
                                        );
                                      },
                                  transitionDuration: const Duration(
                                    milliseconds: 300,
                                  ),
                                );
                              },
                              child: _seccionPolitica(
                                context,
                                Icons.restore_from_trash_rounded,
                                "Restaurar Todo",
                                "Recupera toda la información desde un backup ZIP.",
                              ),
                            ),
                            _divider(isDark),
                            _seccionPolitica(
                              context,
                              Icons.delete_forever_rounded,
                              "Borrar Todo",
                              "Elimina permanentemente todo el contenido de la app.",
                            ),

                            const SizedBox(height: 50),
                            _buildBackupSection(isDark),
                            const SizedBox(height: 40),

                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.verified_user_rounded),
                                label: const Text(
                                  "ENTENDIDO Y ACEPTADO",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A237E),
                                  foregroundColor: Colors.white,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // --- WIDGET DE HEADER CON ILUSTRACIÓN ---
  Widget _buildHeaderWithIllustration(bool isDark) {
    String operadorTexto = _cargando
        ? "Verificando..."
        : (_nombreUsuario != null && _nombreUsuario!.isNotEmpty
              ? "Operador: ${_nombreUsuario!.toUpperCase()}"
              : "NO IDENTIFICADO");

    String detallesTexto = _cargando
        ? ""
        : (_correoUsuario != null && _correoUsuario!.isNotEmpty
              ? _correoUsuario!
              : "");

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A237E),
            isDark ? const Color(0xFF0D47A1) : const Color(0xFF283593),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: CustomPaint(
              size: const Size(300, 180),
              painter: _SecurityIllustrationPainter(isDark: isDark),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "GESTIÓN INTEGRAL DE DATOS",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: Colors.white.withOpacity(0.8),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      operadorTexto,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                if (detallesTexto.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alternate_email,
                        color: Colors.white.withOpacity(0.6),
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        detallesTexto,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TEXTO DE POLÍTICAS ---
  Widget _buildPoliticasTexto(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isDark ? Colors.blueGrey : Colors.blue).withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: (isDark ? Colors.blueAccent : Colors.blue).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: isDark ? Colors.blueAccent : Colors.blue[700],
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                "Manejo de Base de Datos y Responsabilidades",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.blueAccent : Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "1. Almacenamiento Local: La aplicación utiliza SQLite para el almacenamiento local de datos sensibles. No se realiza transmisión de información a servidores externos sin autorización explícita.",
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "2. Responsabilidad del Usuario: Es responsabilidad exclusiva del operador realizar copias de seguridad (Backups) periódicas. La pérdida de datos por desinstalación o fallo del dispositivo no es responsabilidad del desarrollador.",
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "3. Integridad: El uso de las funciones de 'Borrar Todo' es irreversible. Se recomienda verificar la información antes de proceder con la limpieza total o restauración de datos.",
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionPolitica(
    BuildContext context,
    IconData icono,
    String titulo,
    String contenido,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF1A237E).withOpacity(isDark ? 0.3 : 0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icono,
            color: isDark ? Colors.blueAccent : const Color(0xFF1A237E),
            size: 35,
          ),
        ),
        const SizedBox(width: 25),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: AppStyles.mainTitle(context).copyWith(
                  fontSize: 20,
                  color: isDark ? Colors.blueAccent : const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                contenido,
                style: AppStyles.tableCell(context).copyWith(
                  fontSize: 16,
                  height: 1.6,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 35),
      child: Divider(
        height: 1,
        color: isDark ? Colors.white10 : Colors.grey[200],
        thickness: 1,
      ),
    );
  }

  Widget _buildBackupSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: Text(
            "ACCIONES DE SEGURIDAD",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black54,
              letterSpacing: 1.0,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 15.0,
              runSpacing: 15.0,
              alignment: WrapAlignment.center,
              children: [
                // NUEVO BOTÓN: BACKUP LITE
                _buildBackupButton(
                  context,
                  icon: Icons.data_object_rounded,
                  label: "Backup\nBase Dato",
                  color: const Color(0xFFFFC107), // Color ámbar/dorado
                  onTap: _realizarBackupLite,
                ),
                _buildBackupButton(
                  context,
                  icon: Icons.cloud_download_rounded,
                  label: "Restaurar\nBase usuario",
                  color: const Color(0xFF00C853),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Importar Backup"),
                        content: const Text("Seleccione el archivo .ZIP."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Seleccionar"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) _realizarRestauracionTotal();
                  },
                ),

                _buildBackupButton(
                  context,
                  icon: Icons.backup_rounded,
                  label: "Restauracion Total\n(DIRECTO)",
                  color: const Color(0xFF6200EA),
                  onTap: _recuperarBackupTotal,
                ),
                _buildBackupButton(
                  context,
                  icon: Icons.backup_table,
                  label: "Restauracion Total\n(DIRECTO)",
                  color: const ui.Color.fromARGB(255, 0, 234, 31),
                  onTap: _crearBackupTotalEnCarpeta,
                ),
                _buildBackupButton(
                  context,
                  icon: Icons.upload_file_rounded,
                  label: "Compartir\nArchivos",
                  color: const Color(0xFF00BCD4),
                  onTap: _exportarArchivosACarpeta,
                ),
                _buildBackupButton(
                  context,
                  icon: Icons.delete_sweep_rounded,
                  label: "Borrar\nUsuario o Todos",
                  color: const Color(0xFFD84315),
                  onTap: _realizarFactoryReset,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackupButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 160,
      height: 100,
      child: ElevatedButton(
        onPressed: _procesando ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? color.withOpacity(0.15)
              : color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: color.withOpacity(isDark ? 0.3 : 0.5),
              width: 1.5,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CLASE PARA DIBUJAR LA ILUSTRACIÓN DE SEGURIDAD (CustomPainter) ---
class _SecurityIllustrationPainter extends CustomPainter {
  final bool isDark;

  _SecurityIllustrationPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Color shieldColor = isDark
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.2);
    final Color accentColor = Colors.lightBlueAccent.withOpacity(0.8);
    final Color dbColor = isDark ? Colors.blueGrey : Colors.blue.shade700;
    final Color lockBody = isDark ? Colors.white : Colors.grey.shade800;
    final Color lockShackle = isDark ? Colors.amber : Colors.orange.shade400;

    final shieldPath = Path();
    shieldPath.moveTo(center.dx - 60, center.dy - 50);
    shieldPath.quadraticBezierTo(
      center.dx,
      center.dy - 90,
      center.dx + 60,
      center.dy - 50,
    );
    shieldPath.lineTo(center.dx + 60, center.dy + 10);
    shieldPath.quadraticBezierTo(
      center.dx,
      center.dy + 80,
      center.dx - 60,
      center.dy + 10,
    );
    shieldPath.close();

    paint.color = shieldColor;
    canvas.drawPath(shieldPath, paint);

    strokePaint.color = accentColor;
    strokePaint.strokeWidth = 2;
    canvas.drawPath(shieldPath, strokePaint);

    final dbRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 25),
        width: 40,
        height: 30,
      ),
      const Radius.circular(5),
    );

    paint.color = dbColor;
    canvas.drawRRect(dbRect, paint);

    final dbTopPath = Path();
    dbTopPath.addOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 10),
        width: 40,
        height: 10,
      ),
    );
    paint.color = dbColor.withOpacity(0.8);
    canvas.drawPath(dbTopPath, paint);

    strokePaint.color = Colors.white.withOpacity(0.3);
    strokePaint.strokeWidth = 1.5;
    canvas.drawLine(
      Offset(center.dx - 20, center.dy + 18),
      Offset(center.dx + 20, center.dy + 18),
      strokePaint,
    );
    canvas.drawLine(
      Offset(center.dx - 20, center.dy + 32),
      Offset(center.dx + 20, center.dy + 32),
      strokePaint,
    );

    final lockCenter = Offset(center.dx, center.dy - 20);

    final lockRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: lockCenter, width: 30, height: 22),
      const Radius.circular(4),
    );
    paint.color = lockBody;
    canvas.drawRRect(lockRect, paint);

    paint.color = isDark ? Colors.black : Colors.white;
    canvas.drawCircle(Offset(lockCenter.dx, lockCenter.dy), 3, paint);

    final shacklePath = Path();
    shacklePath.moveTo(lockCenter.dx - 8, lockCenter.dy - 11);
    shacklePath.lineTo(lockCenter.dx - 8, lockCenter.dy - 22);
    shacklePath.arcToPoint(
      Offset(lockCenter.dx + 8, lockCenter.dy - 22),
      radius: const Radius.circular(8),
      clockwise: false,
    );
    shacklePath.lineTo(lockCenter.dx + 8, lockCenter.dy - 11);

    strokePaint.color = lockShackle;
    strokePaint.strokeWidth = 4;
    canvas.drawPath(shacklePath, strokePaint);

    _drawParticle(
      canvas,
      Offset(center.dx - 80, center.dy - 40),
      isDark ? Colors.cyanAccent : Colors.blue,
      6,
    );
    _drawParticle(
      canvas,
      Offset(center.dx + 85, center.dy - 20),
      isDark ? Colors.cyanAccent : Colors.blue,
      4,
    );
    _drawParticle(
      canvas,
      Offset(center.dx - 70, center.dy + 50),
      isDark ? Colors.cyanAccent : Colors.blue,
      5,
    );
    _drawParticle(
      canvas,
      Offset(center.dx + 75, center.dy + 40),
      isDark ? Colors.cyanAccent : Colors.blue,
      3,
    );
  }

  void _drawParticle(Canvas canvas, Offset offset, Color color, double size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(offset, size, paint);

    final ringPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(offset, size + 2, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}










// import 'dart:async';
// import 'dart:io';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_phoenix/flutter_phoenix.dart'; // Asumo que lo usas en algún lado
// import 'package:path/path.dart' as p show basename;
// import 'package:path_provider/path_provider.dart';
// import 'package:peloton/SCREENS/bakcup.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:peloton/provider/apptex.dart';
// import 'package:peloton/BD/db_manager.dart';
// import 'package:intl/intl.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:path/path.dart' as path_pkg;
// import 'package:archive/archive.dart';
// import 'package:archive/archive_io.dart';
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart'; // <-- NUEVA IMPORTACIÓN

// class SeguridadScreen extends StatefulWidget {
//   const SeguridadScreen({super.key});

//   @override
//   State<SeguridadScreen> createState() => _SeguridadScreenState();
// }

// class _SeguridadScreenState extends State<SeguridadScreen> {
//   String? _nombreUsuario;
//   String? _correoUsuario;
//   bool _cargando = true;
//   bool _procesando = false;

//   @override
//   void initState() {
//     super.initState();
//     _cargarNombreUsuario();
//   }

//   // ========================================================================
//   // CORRECCIÓN: Carga de usuario blindada con SharedPreferences
//   // ========================================================================
//   Future<void> _cargarNombreUsuario() async {
//     final db = await DBManager.instance.authDatabase;
//     final prefs = await SharedPreferences.getInstance(); // NUEVO

//     int? userId = DBManager.instance.currentUserId;

//     // Si no hay usuario en memoria, lo buscamos en la tabla (o en SharedPreferences como respaldo)
//     if (userId == null) {
//       try {
//         final sesion = await db.query('sesion_activa', limit: 1);
//         if (sesion.isNotEmpty) {
//           userId = sesion.first['usuario_id'] as int;
//         } else {
//           // PARACAÍDAS: Si la tabla fue borrada por el otro usuario, leemos el respaldo
//           userId = prefs.getInt('last_logged_user_id');
//         }
        
//         if (userId != null) {
//           await DBManager.instance.initUserSession(userId);
//         }
//       } catch (e) {
//         print("Error sesión: $e");
//         userId = prefs.getInt('last_logged_user_id'); // Segundo intento
//       }
//     }

//     // Si ya tenemos un ID (venga de donde venga), cargamos su nombre
//     if (userId != null) {
//       try {
//         final usuario = await db.query(
//           'usuarios',
//           where: 'id = ?',
//           whereArgs: [userId],
//           limit: 1,
//         );
//         if (usuario.isNotEmpty && mounted) {
//           setState(() {
//             _nombreUsuario = usuario.first['nombres'] as String?;
//             _correoUsuario = usuario.first['correo'] as String? ?? usuario.first['email'] as String?;
//             _cargando = false;
//           });
//           return;
//         }
//       } catch (e) {}
//     }
    
//     if (mounted) setState(() => _cargando = false);
//   }

//   Future<void> _realizarBackupLite() async {
//     final _progressController = StreamController<String>.broadcast();
//     bool cancelado = false;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return StreamBuilder<String>(
//           stream: _progressController.stream,
//           initialData: "Preparando base de datos...",
//           builder: (context, snapshot) {
//             return AlertDialog(
//               title: const Text("Generando Backup (BD)"),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const LinearProgressIndicator(),
//                   const SizedBox(height: 20),
//                   Text(snapshot.data ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
//                   const SizedBox(height: 15),
//                   TextButton(onPressed: () => cancelado = true, child: const Text("Cancelar")),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );

//     File? dbTempFile;
//     File? zipFinalFile;

//     try {
//       if (DBManager.instance.currentUserId == null) throw "No hay usuario activo.";

//       final dbPath = await getDatabasesPath();
//       final tempDir = await getTemporaryDirectory();
//       final carpetaDb = Directory(dbPath);

//       _progressController.add("Buscando base de datos activa...");
//       await Future.delayed(const Duration(milliseconds: 300));

//       File? dbOriginal;
//       if (await carpetaDb.exists()) {
//         await for (var entity in carpetaDb.list()) {
//           if (entity is File && entity.path.endsWith('.db') && !entity.path.endsWith('-wal') && !entity.path.endsWith('-shm')) {
//             dbOriginal = entity;
//             break;
//           }
//         }
//       }

//       if (dbOriginal == null || !await dbOriginal.exists()) {
//         throw "No se encontró ningún archivo .db.";
//       }

//       _progressController.add("Copiando ${dbOriginal.path.split('/').last}...");
//       await Future.delayed(const Duration(milliseconds: 200));

//       dbTempFile = File('${tempDir.path}/user.db');
//       if (await dbTempFile.exists()) await dbTempFile.delete();
//       await dbOriginal.copy(dbTempFile.path);

//       if (cancelado) throw "Proceso cancelado.";

//       _progressController.add("Comprimiendo base de datos...");
//       await Future.delayed(const Duration(milliseconds: 100));

//       String fecha = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
//       String zipName = 'BACKUP_${DBManager.instance.currentUserId}_$fecha.zip';
//       zipFinalFile = File('${tempDir.path}/$zipName');

//       final zipEncoder = ZipFileEncoder();
//       zipEncoder.create(zipFinalFile.path);
//       zipEncoder.addFile(dbTempFile, 'user.db');
//       zipEncoder.close();

//       if (cancelado) throw "Proceso cancelado.";

//       int fileSizeInBytes = await zipFinalFile.length();
//       String fileSizeMB = (fileSizeInBytes / (1024 * 1024)).toStringAsFixed(2);

//       _progressController.add("¡Listo! Abriendo menú...");

//       await Share.shareXFiles([XFile(zipFinalFile.path)], subject: 'Backup BD CALIPSO ($fileSizeMB MB)', text: 'Adjunto base de datos comprimida.');
//       _mostrarMensaje("Backup creado ($fileSizeMB MB).");
//     } catch (e) {
//       _mostrarMensaje("Error: $e", isError: true);
//     } finally {
//       try {
//         if (dbTempFile != null && await dbTempFile.exists()) await dbTempFile.delete();
//         if (zipFinalFile != null && await zipFinalFile.exists()) await zipFinalFile.delete();
//       } catch (_) {}
//       await _progressController.close();
//       if (mounted) Navigator.of(context).pop();
//     }
//   }

//   // --- Los métodos _realizarBackupTotal, _realizarRestauracionTotal, _exportarArchivosACarpeta, 
//   // --- _crearBackupTotalEnCarpeta, _recuperarBackupTotal, _realizarFactoryReset los dejé 
//   // --- exactamente igual porque su lógica interna con metadata.json es correcta y no afecta el login ---
  
//   // (Pega aquí el resto de tus métodos largos tal cual los tenías, no cambian nada).

//   Future<void> _realizarFactoryReset() async {
//     final opcionElegida = await showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Opciones de Limpieza"),
//         content: const Text("¿Qué deseas eliminar?"),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, 'USUARIO'), child: const Text("Mis Datos (Usuario actual)")),
//           TextButton(
//             onPressed: () => Navigator.pop(context, 'TOTAL'),
//             child: const Text("BORRAR TODO (Factory Reset)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
//           ),
//           TextButton(onPressed: () => Navigator.pop(context, null), child: const Text("Cancelar")),
//         ],
//       ),
//     );

//     if (opcionElegida == null) return;

//     if (opcionElegida == 'USUARIO') {
//       await _borrarDatosUsuario();
//     } else if (opcionElegida == 'TOTAL') {
//       await _factoryResetTotal();
//     }
//   }

//   Future<void> _borrarDatosUsuario() async {
//     final confirmar = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("¿Borrar tus datos?"),
//         content: const Text("Se eliminarán todos tus registros. La estructura de la app permanecerá intacta."),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("BORRAR MIS DATOS", style: TextStyle(color: Colors.orange))),
//         ],
//       ),
//     );

//     if (confirmar != true) return;
//     setState(() => _procesando = true);

//     try {
//       Database? dbUser = await DBManager.instance.database;
//       if (dbUser != null) {
//         List<String> tablas = ['minutas', 'inteligencia', 'operacional', 'armamento', 'inventario_armamento', 'comunicaciones', 'expediente', 'inventario_especial', 'inventario_miras', 'intendencia', 'personal', 'exde'];
//         for (var tabla in tablas) {
//           try { await dbUser.delete(tabla); } catch (e) { print("Error vaciando $tabla: $e"); }
//         }
//         try { await dbUser.execute("VACUUM"); } catch (e) {}
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         _mostrarMensaje("Datos eliminados. Reiniciando...");
//       }
//       await Future.delayed(const Duration(milliseconds: 1500));
//       if (mounted) exit(0);
//     } catch (e) {
//       _mostrarMensaje("Error al borrar datos: $e", isError: true);
//       if (mounted) setState(() => _procesando = false);
//     }
//   }

//   Future<void> _factoryResetTotal() async {
//     final confirmar = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("⚠️ FACTORY RESET"),
//         content: const Text("ESTO ELIMINARÁ TODO:\n\n- Sesiones de todos los usuarios.\n- Todas las bases de datos.\n- Todos los archivos adjuntos.\n\nLa app se reiniciará como recién instalada.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
//         actions: [
//           TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Mejor no")),
//           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SÍ, BORRAR TODO", style: TextStyle(color: Colors.red))),
//         ],
//       ),
//     );

//     if (confirmar != true) return;
//     setState(() => _procesando = true);

//     try {
//       // ---> CORRECCIÓN: Limpiar también SharedPreferences al hacer Factory Reset
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear(); 

//       await DBManager.instance.fullReset();
//       await Future.delayed(const Duration(milliseconds: 500));

//       final dbPath = await getDatabasesPath();
//       final dbDir = Directory(dbPath);
//       if (await dbDir.exists()) {
//         await for (var entity in dbDir.list()) {
//           if (entity is File && entity.path.endsWith('.db')) {
//             try { await entity.delete(); } catch (e) { print("DB bloqueada: ${entity.path}"); }
//           }
//         }
//       }

//       final tempDir = await getTemporaryDirectory();
//       if (await tempDir.exists()) {
//         await for (var entity in tempDir.list(recursive: true, followLinks: false)) {
//           if (entity is File) {
//             try { await entity.delete(); } catch (e) {}
//           }
//         }
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         _mostrarMensaje("App restaurada de fábrica. Reiniciando...");
//       }
//       await Future.delayed(const Duration(milliseconds: 1500));
//       if (mounted) exit(0);
//     } catch (e) {
//       _mostrarMensaje("Error en Factory Reset: $e", isError: true);
//       if (mounted) setState(() => _procesando = false);
//     }
//   }

//   void _mostrarMensaje(String mensaje, {bool isError = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).clearSnackBars();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(mensaje),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
//       appBar: AppBar(
//         title: Text(
//           "POLÍTICAS DE SEGURIDAD",
//           style: AppStyles.mainTitle(context).copyWith(color: Colors.white, fontSize: 18, letterSpacing: 1.5),
//         ),
//         backgroundColor: const Color(0xFF1A237E),
//         centerTitle: true,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 16.0),
//             child: Row(
//               children: [
//                 Container(
//                   width: 8,
//                   height: 8,
//                   decoration: BoxDecoration(
//                     color: Colors.greenAccent,
//                     shape: BoxShape.circle,
//                     boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.6), blurRadius: 4, spreadRadius: 1)],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 CircleAvatar(
//                   radius: 14,
//                   backgroundColor: Colors.white.withOpacity(0.2),
//                   child: Text(
//                     _nombreUsuario != null && _nombreUsuario!.isNotEmpty ? _nombreUsuario![0].toUpperCase() : "?",
//                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.end,
//                   children: [
//                     Text(
//                       _nombreUsuario ?? "Usuario",
//                       style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
//                     ),
//                     if (_correoUsuario != null)
//                       Text(
//                         _correoUsuario!,
//                         style: const TextStyle(color: Colors.white54, fontSize: 10),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: _cargando
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   // --- SECCIÓN RESPALDOS ---
//                   _buildSectionTitle("RESPALDOS DE SEGURIDAD"),
//                   const SizedBox(height: 15),
                  
//                   _actionCard(
//                     icon: Icons.inventory_2_outlined,
//                     title: "1. Backup Rápido (Solo BD)",
//                     description: "Genera y comparte un ZIP ligero con la base de datos actual.",
//                     color: Colors.blue,
//                     onTap: _procesando ? null : _realizarBackupLite,
//                   ),
//                   const SizedBox(height: 12),
                  
//                   _actionCard(
//                     icon: Icons.backup,
//                     title: "2. Backup Total (BD + Archivos)",
//                     description: "Genera un ZIP con la BD y la carpeta completa de imágenes/audios.",
//                     color: Colors.teal,
//                     onTap: _procesando ? null : _realizarBackupTotal,
//                   ),
//                   const SizedBox(height: 12),
                  
//                   _actionCard(
//                     icon: Icons.folder_copy,
//                     title: "3. Guardar Backup Total en Carpeta",
//                     description: "Igual que el anterior, pero te deja elegir dónde guardarlo sin comprimir.",
//                     color: Colors.indigo,
//                     onTap: _procesando ? null : _crearBackupTotalEnCarpeta,
//                   ),
//                   const SizedBox(height: 12),
                  
//                   _actionCard(
//                     icon: Icons.photo_library_outlined,
//                     title: "4. Exportar Solo Fotos/Audios",
//                     description: "Copia la carpeta de adjuntos a la ubicación que elijas.",
//                     color: Colors.purple,
//                     onTap: _procesando ? null : _exportarArchivosACarpeta,
//                   ),

//                   const SizedBox(height: 30),
//                   // --- SECCIÓN RESTAURAR ---
//                   _buildSectionTitle("RESTAURACIÓN"),
//                   const SizedBox(height: 15),
                  
//                   _actionCard(
//                     icon: Settings.backupRestore, // Usando icono genérico de Settings como en tu código cortado
//                     title: "Restaurar desde ZIP (Con Archivos)",
//                     description: "Selecciona un ZIP creado con la opción 2 o 3 para restaurar todo.",
//                     color: Colors.orange,
//                     onTap: _procesando ? null : _realizarRestauracionTotal,
//                   ),
//                   const SizedBox(height: 12),
                  
//                   _actionCard(
//                     icon: Icons.restore,
//                     title: "Restaurar desde ZIP (Carpeta)",
//                     description: "Restaura usando el formato de guardado en carpeta.",
//                     color: Colors.deepOrange,
//                     onTap: _procesando ? null : _recuperarBackupTotal,
//                   ),

//                   const SizedBox(height: 30),
//                   // --- SECCIÓN PELIGRO ---
//                   _buildSectionTitle("ZONA DE PELIGRO"),
//                   const SizedBox(height: 15),
                  
//                   _actionCard(
//                     icon: Icons.warning_amber_rounded,
//                     title: "Factory Reset / Limpiar Datos",
//                     description: "Borrar datos del usuario actual o destruir toda la app por completo.",
//                     color: Colors.red,
//                     onTap: _procesando ? null : _realizarFactoryReset,
//                   ),

//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//     );
//   }

//   // --- WIDGETS DE DISEÑO ---
//   Widget _buildSectionTitle(String title) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.grey)),
//     );
//   }

//   Widget _actionCard({
//     required IconData icon,
//     required String title,
//     required String description,
//     required Color color,
//     required VoidCallback? onTap,
//   }) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       color: isDark ? const Color(0xFF161B22) : Colors.white,
//       child: InkWell(
//         onTap: onTap,
//         borderRadius: BorderRadius.circular(12),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(10),
//                 decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
//                 child: Icon(icon, color: color, size: 28),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
//                     const SizedBox(height: 4),
//                     Text(description, style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
//                   ],
//                 ),
//               ),
//               Icon(Icons.chevron_right, color: Colors.grey),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }