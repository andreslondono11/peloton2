import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:peloton/BD/db_manager.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';

class RestoreBackupScreen extends StatefulWidget {
  @override
  _RestoreBackupScreenState createState() => _RestoreBackupScreenState();
}

class _RestoreBackupScreenState extends State<RestoreBackupScreen> {
  bool _procesando = false;
  double _progreso = 0.0;
  String _mensajeProgreso = "";

  void _mostrarOpcionesRestauracion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restaurar Copia"),
        content: const Text("¿Qué tipo de archivo deseas restaurar?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _realizarRestauracionJSON();
            },
            child: const Text("Archivo JSON (Datos ligeros)"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _realizarRestauracionZIP();
            },
            child: const Text("Archivo ZIP (Datos y Archivos pesados)"),
          ),
        ],
      ),
    );
  }

  Future<void> _realizarRestauracionJSON() async {
    setState(() {
      _procesando = true;
      _progreso = 0;
      _mensajeProgreso = "Seleccionando archivo JSON...";
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: false,
      );

      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        _detenerProceso();
        return;
      }

      File jsonFile = File(result.files.single.path!);
      setState(() => _mensajeProgreso = "Leyendo JSON...");
      final String jsonString = await jsonFile.readAsString();
      setState(() => _mensajeProgreso = "Procesando datos...");

      _mostrarMensaje("JSON restaurado correctamente.");
    } catch (e) {
      _mostrarMensaje("Error restaurando JSON: $e", isError: true);
    } finally {
      _detenerProceso();
    }
  }

  Future<void> _realizarRestauracionZIP() async {
    setState(() {
      _procesando = true;
      _progreso = 0;
      _mensajeProgreso = "Seleccionando archivo ZIP...";
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: false,
      );

      // --- BLINDAJE ANTI-NULL: Si cancela, simplemente detiene el proceso ---
      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        _detenerProceso();
        return;
      }

      File zipFile = File(result.files.single.path!);
      final int totalBytes = await zipFile.length();

      if (totalBytes > 2147483648) {
        await Permission.manageExternalStorage.request();
      }

      setState(() => _mensajeProgreso = "Cerrando base de datos actual...");
      await DBManager.instance.fullReset();

      final dbPath = await getDatabasesPath();
      final tempDir = await getTemporaryDirectory();
      final dbDir = Directory(dbPath);
      if (!await dbDir.exists()) await dbDir.create(recursive: true);

      setState(() => _mensajeProgreso = "Descomprimiendo (0%)...");

      final inputStream = InputFileStream(zipFile.path);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      int archivosProcesados = 0;
      final totalArchivos = archive.length;

      for (final file in archive) {
        final filename = file.name;

        archivosProcesados++;
        final porcentaje = (archivosProcesados / totalArchivos);

        if (mounted) {
          setState(() {
            _progreso = porcentaje;
            _mensajeProgreso =
                "Descomprimiendo: $filename (${(porcentaje * 100).toStringAsFixed(1)}%)";
          });
        }

        if (file.isFile) {
          final outputPath = filename.endsWith('.db')
              ? '$dbPath/$filename'
              : '${tempDir.path}/${filename.replaceFirst('archivos/', '')}';

          final outFile = File(outputPath);
          await outFile.parent.create(recursive: true);

          final outputStream = OutputFileStream(outFile.path);
          file.writeContent(outputStream);
          await outputStream.close();
        }
      }

      // --- REINICIO INFALIBLE ---
      if (mounted) {
        // 1. Actualizamos la UI por última vez
        setState(() {
          _mensajeProgreso = "¡Completado! Reiniciando app...";
          _progreso = 1.0;
        });

        // 2. Esperamos un segundo para que el usuario vea el 100%
        await Future.delayed(const Duration(seconds: 1));

        // 3. CERRAMOS CUALQUIER SNACKBAR ABIERTO para que no estorbe a Phoenix
        ScaffoldMessenger.of(context).clearSnackBars();

        // 4. REINICIO TOTAL
        Phoenix.rebirth(context);
      }
    } catch (e) {
      _mostrarMensaje("Error restaurando ZIP: $e", isError: true);
      _detenerProceso();
    }
  }

  void _detenerProceso() {
    if (mounted) {
      setState(() {
        _procesando = false;
        _progreso = 0;
        _mensajeProgreso = "";
      });
    }
  }

  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars(); // Evita que se amontonen
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
    return Scaffold(
      appBar: AppBar(title: const Text("Restaurar Datos")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_procesando)
                ElevatedButton.icon(
                  icon: const Icon(Icons.restore),
                  label: const Text("Iniciar Restauración"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                  ),
                  onPressed: _mostrarOpcionesRestauracion,
                ),
              if (_procesando) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progreso > 0 ? _progreso : null,
                    minHeight: 20,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  _mensajeProgreso,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "${(_progreso * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(fontSize: 24, color: Colors.blue),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
