import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../BD/db_manager.dart';

// Debe ser una función estática o de nivel superior (global) para usarse en compute()
Future<void> _generarPdfEnIsolate(Map<String, dynamic> params) async {
  // 1. Extraer parámetros enviados por la función de exportación
  final List<List<Map<String, dynamic>>> chunks = params['chunks'];
  final String path = params['ruta'];
  final String titulo = params['titulo'] ?? 'REPORTE OPERACIONAL';

  // Aplanar los chunks para procesar toda la data de forma lineal
  final List<Map<String, dynamic>> data = chunks
      .expand((chunk) => chunk)
      .toList();

  final pdf = pw.Document();

  final headerStyle = pw.TextStyle(
    color: PdfColors.white,
    fontWeight: pw.FontWeight.bold,
    fontSize: 10,
  );
  final cellStyle = const pw.TextStyle(fontSize: 9);

  // 2. Construcción de las páginas del PDF
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter.copyWith(
        marginBottom: 1.5 * PdfPageFormat.cm,
        marginTop: 1.5 * PdfPageFormat.cm,
        marginLeft: 1 * PdfPageFormat.cm,
        marginRight: 1 * PdfPageFormat.cm,
      ),
      header: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Text(
          "OPERACIONAL - CALIPSO",
          style: pw.TextStyle(color: PdfColors.grey700, fontSize: 12),
        ),
      ),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 10),
        child: pw.Text(
          'Página ${context.pageNumber} de ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ),
      build: (context) => [
        pw.Header(
          level: 0,
          child: pw.Text(
            titulo, // Título dinámico recibido desde los parámetros
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.black),
          columnWidths: {
            0: const pw.FixedColumnWidth(80), // Fecha
            1: const pw.FixedColumnWidth(60), // Hora
            2: const pw.FixedColumnWidth(120), // Asunto
            3: const pw.FlexColumnWidth(), // Anotaciones
            4: const pw.FixedColumnWidth(30), // Adj
          },
          children: [
            // Encabezado de la tabla
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Fecha', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Hora', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Asunto', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Anotaciones', style: headerStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text('Adj', style: headerStyle),
                ),
              ],
            ),
            // Filas dinámicas generadas a partir de la data limpia
            ...data.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return pw.TableRow(
                decoration: i.isOdd
                    ? const pw.BoxDecoration(color: PdfColors.grey100)
                    : const pw.BoxDecoration(),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      m['fecha']?.toString() ?? '',
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      m['hora']?.toString() ?? '',
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      m['asunto']?.toString() ?? '',
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      m['anotaciones']?.toString() ?? '',
                      style: cellStyle,
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(
                      m['adjuntos']?.toString() ??
                          'No', // Ya viene mapeado como 'Sí' o 'No' del paso anterior
                      style: cellStyle,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 40),

        // Sección de firma y huella al final del documento
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              children: [
                pw.Container(width: 200, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 5),
                pw.Text("Firma", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Column(
              children: [
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 1),
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text("Huella", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ],
        ),
      ],
    ),
  );

  // 3. Guardar el PDF y escribir el archivo directamente en el disco
  final List<int> bytes = await pdf.save();
  final File file = File(path);
  await file.writeAsBytes(bytes, flush: true);
} // ─── FUNCIÓN PARA GENERAR WORD (TABLA CONTINUA) ───

Future<File> _generarWordFileOperacional(
  List<Map<String, dynamic>> data,
) async {
  final buffer = StringBuffer();

  // 1. Cabecera HTML
  buffer.writeln(
    '<html xmlns:o="urn:schemas-microsoft-com:office:office" '
    'xmlns:w="urn:schemas-microsoft-com:office:word" '
    'xmlns="http://www.w3.org/TR/REC-html40">',
  );
  buffer.writeln('<head><meta charset="utf-8">');
  buffer.writeln('<meta name=ProgId content=Word.Document>');
  buffer.writeln('<title>Reporte Operacional</title></head><body>');

  // 2. TÍTULO
  buffer.writeln(
    '<h1 style="text-align: center; font-family: Arial; font-size: 20pt; font-weight: bold; margin-bottom: 20px;">REPORTE OPERACIONAL - CALIPSO</h1>',
  );

  // 3. TABLA PRINCIPAL (AQUÍ SE AGREGA 'table-layout: fixed;' PARA TRABAR LOS ANCHOS)
  buffer.writeln(
    '<table style="width: 100%; table-layout: fixed; border-collapse: collapse; border: 1px solid #000000; font-family: Arial; font-size: 10pt;">',
  );

  // ENCABEZADOS: Con los porcentajes fijos y obligatorios
  buffer.writeln('<tr>');
  buffer.writeln(
    '<th style="width: 12%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Fecha</th>',
  );
  buffer.writeln(
    '<th style="width: 8%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Hora</th>',
  );
  buffer.writeln(
    '<th style="width: 20%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Asunto</th>',
  );
  buffer.writeln(
    '<th style="width: 60%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Anotaciones</th>',
  );
  buffer.writeln('</tr>');

  // 4. FILAS DE DATOS (Se añade 'word-wrap' para obligar al texto a respetar el límite asignado)
  for (var m in data) {
    String anotacionesRaw = (m['anotaciones']?.toString() ?? '').replaceAll(
      '\n',
      '<br>',
    );

    // Escapar HTML básico
    String fecha = (m['fecha']?.toString() ?? '').replaceAll('<', '&lt;');
    String hora = (m['hora']?.toString() ?? '').replaceAll('<', '&lt;');
    String asunto = (m['asunto']?.toString() ?? '').replaceAll('<', '&lt;');
    String anotaciones = anotacionesRaw.replaceAll('<', '&lt;');

    buffer.writeln('<tr>');
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: center; word-wrap: break-word;">$fecha</td>',
    );
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: center; word-wrap: break-word;">$hora</td>',
    );
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: left; word-wrap: break-word;">$asunto</td>',
    );
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: left; word-wrap: break-word;">$anotaciones</td>',
    );
    buffer.writeln('</tr>');
  }

  buffer.writeln('</table>');
  buffer.writeln('</body></html>');

  // 5. Guardar
  final tempDir = await getTemporaryDirectory();
  final filePath = '${tempDir.path}/Reporte_Operacional.doc';
  final file = File(filePath);
  await file.writeAsBytes(const Utf8Encoder().convert(buffer.toString()));

  return file;
}

class OperacionalScreen extends StatefulWidget {
  const OperacionalScreen({super.key});
  @override
  State<OperacionalScreen> createState() => _OperacionalScreenState();
}

class _OperacionalScreenState extends State<OperacionalScreen> {
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];
  final TextEditingController _searchController = TextEditingController();
  final String _tableName = 'operacional';

  String? _nombreUsuario;
  bool _cargandoUsuario = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioLogueado();
    _cargarDatos();
  }

  Future<void> _cargarUsuarioLogueado() async {
    final db = await DBManager.instance.authDatabase;
    try {
      final sesion = await db.query('sesion_activa', limit: 1);
      if (sesion.isNotEmpty) {
        final int usuarioId = sesion.first['usuario_id'] as int;
        final usuario = await db.query(
          'usuarios',
          where: 'id = ?',
          whereArgs: [usuarioId],
          limit: 1,
        );

        if (usuario.isNotEmpty && mounted) {
          setState(() {
            _nombreUsuario = usuario.first['nombres'] as String?;
            _cargandoUsuario = false;
          });
          return;
        }
      }
    } catch (e) {
      print("Error cargando usuario en operacional: $e");
    }
    if (mounted) setState(() => _cargandoUsuario = false);
  }

  Future<void> _cargarDatos() async {
    final db = await DBManager.instance.database;
    final data = await db.query(_tableName, orderBy: 'fecha ASC, hora ASC');
    setState(() {
      _allData = data;
      _filteredData = data;
    });
  }

  Future<void> _importarExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );
      if (result != null) {
        var bytes = File(result.files.single.path!).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        final db = await DBManager.instance.database;
        int count = 0;

        for (var table in excel.tables.keys) {
          bool isFirstRow = true;
          for (var row in excel.tables[table]!.rows) {
            if (isFirstRow) {
              isFirstRow = false;
              continue;
            }
            if (row[0] != null && row[2] != null) {
              await db.insert(_tableName, {
                'fecha': row[0]?.value.toString() ?? '',
                'hora': row[1]?.value.toString() ?? '',
                'asunto': row[2]?.value.toString() ?? '',
                'anotaciones': row[3]?.value.toString() ?? '',
                'adjuntos': '',
              });
              count++;
            }
          }
        }
        _cargarDatos();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Importados $count registros a Operacional"),
            ),
          );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _exportarExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Operacional'];
    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Hora'),
      TextCellValue('Asunto'),
      TextCellValue('Anotaciones'),
      TextCellValue('Adjuntos'),
    ]);
    for (var m in _filteredData) {
      sheet.appendRow([
        TextCellValue(m['fecha']),
        TextCellValue(m['hora']),
        TextCellValue(m['asunto']),
        TextCellValue(m['anotaciones']),
        TextCellValue(
          m['adjuntos']?.toString().isNotEmpty == true ? 'Sí' : 'No',
        ),
      ]);
    }
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/Reporte_Operacional.xlsx';
    final bytes = excel.save();
    if (bytes != null) {
      await File(filePath).writeAsBytes(bytes);
      await Share.shareXFiles([XFile(filePath)], text: 'Excel Operacional');
    }
  }

  // ─────────────────────────────────────────────────────
  // FUNCIÓN EXPORTAR PDF (SnackBar + Botón Abrir)
  // ─────────────────────────────────────────────────────
  Future<void> _exportarPDF() async {
    try {
      // 1. Mostrar Loader idéntico y moderno (PopScope)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      // 2. Definir tamaño del lote (Chunk size)
      const int chunkSize = 15;
      List<List<Map<String, dynamic>>> allChunks = [];

      // 3. Consulta paginada directa a la base de datos Operacional
      final db = await DBManager.instance.database;

      // TODO: Asegúrate de que '_tableName' corresponda a la tabla operacional de esta pantalla
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName',
      );
      int totalCount = Sqflite.firstIntValue(countResult) ?? 0;

      if (totalCount == 0) {
        if (mounted) Navigator.pop(context); // Cerrar loader
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay datos para exportar")),
          );
        }
        return;
      }

      int offset = 0;
      while (offset < totalCount) {
        final List<Map<String, dynamic>> batch = await db.query(
          _tableName,
          orderBy: 'fecha ASC, hora ASC', // Mantiene el orden cronológico
          limit: chunkSize,
          offset: offset,
        );

        if (batch.isEmpty) break;

        // Mapeo y limpieza de los campos específicos de Operacional
        final cleanBatch = batch.map((m) {
          return {
            'fecha': m['fecha']?.toString() ?? '',
            'hora': m['hora']?.toString() ?? '',
            'asunto': m['asunto']?.toString() ?? '',
            'anotaciones': m['anotaciones']?.toString() ?? '',
            // Estandarizamos la lógica de adjuntos a 'Sí' o 'No' igual que en Minuta
            'adjuntos': (m['adjuntos']?.toString().isNotEmpty ?? false)
                ? 'Sí'
                : 'No',
          };
        }).toList();

        allChunks.add(cleanBatch);
        offset += chunkSize;
      }

      // 4. Ruta de salida en el directorio de documentos con nombre Operacional
      final dir = await getApplicationDocumentsDirectory();
      final String fileName =
          'Reporte_Operacional_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');

      // 5. Ejecutar en Isolate mandando la ruta final para evitar manejo de bytes pesados en UI
      await compute(_generarPdfEnIsolate, {
        'chunks': allChunks,
        'ruta': file.path,
        'titulo': 'REPORTE OPERACIONAL',
      });

      // 6. Finalizar y redirigir al PdfViewerScreen moderno
      if (mounted) Navigator.pop(context); // Cerrar loader

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(filePath: file.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        try {
          Navigator.pop(context); // Asegurar el cierre del loader ante fallos
        } catch (_) {}
      }
      debugPrint("Error PDF Operacional: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al exportar PDF Operacional: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ─────────────────────────────────────────────────────
  // FUNCIÓN EXPORTAR WORD (Alineado con DocxViewerScreen)
  // ─────────────────────────────────────────────────────
  Future<void> _exportarWord() async {
    try {
      // 1. Mostrar Loader moderno idéntico al de los otros módulos
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      // 2. Mapeo y preparación de los datos antes de enviar al generador
      final data = _filteredData
          .map(
            (m) => {
              'fecha': m['fecha']?.toString() ?? '',
              'hora': m['hora']?.toString() ?? '',
              'asunto': m['asunto']?.toString() ?? '',
              'anotaciones': m['anotaciones']?.toString() ?? '',
              'adjuntos': m['adjuntos'],
            },
          )
          .toList();

      // 3. Generación del archivo binario (.doc)
      final file = await _generarWordFileOperacional(data);

      // 4. Quitar loader de la pantalla de forma segura
      if (mounted) Navigator.pop(context);

      // 5. Redirección limpia al visor interno de la aplicación
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocxViewerScreen(filePath: file.path),
          ),
        );
      }

      // 6. Notificación de éxito consistente con la línea gráfica
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Documento Word generado con éxito"),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Manejo preventivo de excepciones para cerrar el diálogo en caso de fallo
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      debugPrint("Error Word Operacional: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No se pudo generar el Word: $e"),
            backgroundColor: Colors.red, // Rojo para alertar fallos de guardado
          ),
        );
      }
    }
  }

  void _abrirFormulario({Map<String, dynamic>? item}) {
    final bool esEdicion = item != null;

    final fCon = TextEditingController(
      text: esEdicion
          ? item['fecha']
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final hCon = TextEditingController(
      text: esEdicion
          ? item['hora']
          : DateFormat('HH:mm').format(DateTime.now()),
    );
    final aCon = TextEditingController(text: esEdicion ? item['asunto'] : '');
    final nCon = TextEditingController(
      text: esEdicion ? item['anotaciones'] : '',
    );

    List<String> _rutasArchivosActuales = [];
    if (esEdicion && item['adjuntos'] != null) {
      String adjuntosStr = item['adjuntos'] as String;
      if (adjuntosStr.isNotEmpty) {
        _rutasArchivosActuales = adjuntosStr.split('|');
      }
    }

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              esEdicion ? "Editar Operacional" : "Nuevo Registro Operacional",
              style: const TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fCon,
                            decoration: const InputDecoration(
                              labelText: "Fecha",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: hCon,
                            decoration: const InputDecoration(
                              labelText: "Hora",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: aCon,
                      decoration: const InputDecoration(
                        labelText: "Asunto",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: nCon,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: "Anotaciones",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Archivos Adjuntos:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
                                  allowMultiple: true,
                                  type: FileType.any,
                                );
                            if (result != null) {
                              setDialogState(() {
                                _rutasArchivosActuales.addAll(
                                  result.paths.map((e) => e!).toList(),
                                );
                              });
                            }
                          },
                          icon: const Icon(Icons.attach_file, size: 16),
                          label: const Text("Agregar Archivos"),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.teal,
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform
                                .pickFiles(
                                  type: FileType.audio,
                                  allowMultiple: true,
                                );
                            if (result != null) {
                              setDialogState(() {
                                _rutasArchivosActuales.addAll(
                                  result.paths.map((e) => e!).toList(),
                                );
                              });
                            }
                          },
                          icon: const Icon(Icons.mic, size: 18),
                          label: const Text("Adjuntar Audio"),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.deepPurple,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (_rutasArchivosActuales.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text(
                          "No hay archivos adjuntos.",
                          style: TextStyle(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 150),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _rutasArchivosActuales.length,
                          itemBuilder: (context, index) {
                            final path = _rutasArchivosActuales[index];
                            final fileName = path.split('/').last;
                            final isAudio =
                                path.toLowerCase().endsWith('.mp3') ||
                                path.toLowerCase().endsWith('.wav') ||
                                path.toLowerCase().endsWith('.m4a');

                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isAudio
                                    ? Icons.audiotrack
                                    : Icons.insert_drive_file,
                                color: isAudio
                                    ? Colors.deepPurple
                                    : Colors.blueGrey,
                              ),
                              title: Text(
                                fileName,
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 20,
                                    ),
                                    tooltip: "Abrir archivo",
                                    color: Colors.green,
                                    onPressed: () async {
                                      final result = await OpenFile.open(path);
                                      if (result.type ==
                                          ResultType.noAppToOpen) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "No hay aplicación para abrir este archivo",
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setDialogState(() {
                                        _rutasArchivosActuales.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                ),
                onPressed: () async {
                  final db = await DBManager.instance.database;

                  String adjuntosString = _rutasArchivosActuales.join('|');

                  final map = {
                    'fecha': fCon.text,
                    'hora': hCon.text,
                    'asunto': aCon.text,
                    'anotaciones': nCon.text,
                    'adjuntos': adjuntosString,
                  };
                  if (esEdicion) {
                    await db.update(
                      _tableName,
                      map,
                      where: 'id = ?',
                      whereArgs: [item['id']],
                    );
                  } else {
                    await db.insert(_tableName, map);
                  }
                  Navigator.pop(c);
                  _cargarDatos();
                },
                child: const Text(
                  "Guardar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _verRegistro(Map<String, dynamic> item) {
    final ThemeData theme = Theme.of(context);

    List<String> archivos = [];
    if (item['adjuntos'] != null) {
      String str = item['adjuntos'] as String;
      if (str.isNotEmpty) {
        archivos = str.split('|');
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Detalle del Registro",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 15),

                _detalleFila("Fecha:", item['fecha']),
                _detalleFila("Hora:", item['hora']),
                const SizedBox(height: 10),

                Text(
                  "Asunto:",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(item['asunto'] ?? ''),
                const SizedBox(height: 15),

                Text(
                  "Anotaciones:",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(item['anotaciones'] ?? 'Sin anotaciones'),
                const SizedBox(height: 25),

                if (archivos.isNotEmpty) ...[
                  Text(
                    "Archivos Adjuntos:",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...archivos.map((path) {
                    final fileName = path.split('/').last;
                    final isAudio =
                        path.toLowerCase().endsWith('.mp3') ||
                        path.toLowerCase().endsWith('.wav');

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          isAudio ? Icons.audiotrack : Icons.description,
                          color: isAudio ? Colors.deepPurple : Colors.teal,
                        ),
                        title: Text(
                          fileName,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new, size: 20),
                          onPressed: () async {
                            final result = await OpenFile.open(path);
                            if (result.type == ResultType.noAppToOpen) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "No hay aplicación para abrir este archivo",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detalleFila(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? '')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Programas Operacionales",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
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
                Text(
                  _nombreUsuario ?? "Usuario",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _btn("PDF", Colors.purple, Icons.picture_as_pdf, _exportarPDF),
                const SizedBox(width: 10),
                _btn("Word", Colors.blue, Icons.description, _exportarWord),
                const SizedBox(width: 10),
                _btn("Excel", Colors.green, Icons.table_chart, _exportarExcel),
                const SizedBox(width: 10),
                _btn(
                  "Importar",
                  Colors.blueGrey,
                  Icons.upload_file,
                  _importarExcel,
                ),
                const SizedBox(width: 10),
                _btn(
                  "Nuevo",
                  const Color(0xFF1A237E),
                  Icons.add,
                  () => _abrirFormulario(),
                ),
              ],
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Buscar en Operacional...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {
                  _filteredData = _allData
                      .where(
                        (m) =>
                            m['asunto'].toLowerCase().contains(
                              v.toLowerCase(),
                            ) ||
                            m['anotaciones'].toLowerCase().contains(
                              v.toLowerCase(),
                            ),
                      )
                      .toList();
                });
              },
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(0.8),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(3.5),
                    4: FlexColumnWidth(1.2),
                  },
                  children: [_header(), ..._filteredData.map((m) => _row(m))],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _header() {
    return TableRow(
      children: ['Fecha', 'Hora', 'Asunto', 'Anotaciones', 'Acciones']
          .map(
            (t) => Container(
              color: const Color(0xFF2196F3),
              padding: const EdgeInsets.all(10),
              child: Text(
                t,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  TableRow _row(Map<String, dynamic> m) => TableRow(
    children: [
      _c(m['fecha']?.toString() ?? ''),
      _c(m['hora']?.toString() ?? ''),
      _c(m['asunto']?.toString() ?? ''),
      _c(m['anotaciones']?.toString() ?? ''),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
            onPressed: () => _verRegistro(m),
            tooltip: 'Ver Registro',
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
            onPressed: () => _abrirFormulario(item: m),
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () async {
              final confirm = await _confirmarEliminacion();
              if (confirm == true) {
                final db = await DBManager.instance.database;
                await db.delete(
                  _tableName,
                  where: 'id = ?',
                  whereArgs: [m['id']],
                );
                _cargarDatos();
              }
            },
            tooltip: 'Eliminar',
          ),
        ],
      ),
    ],
  );

  Future<bool?> _confirmarEliminacion() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Registro"),
        content: const Text(
          "¿Está seguro de que desea eliminar este registro?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _c(String t) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(t, style: const TextStyle(fontSize: 12)),
  );

  Widget _btn(String t, Color c, IconData i, VoidCallback o) =>
      ElevatedButton.icon(
        onPressed: o,
        icon: Icon(i, size: 16, color: Colors.white),
        label: Text(t, style: const TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: c),
      );
}

class PdfViewerScreen extends StatefulWidget {
  final String filePath;
  final String title; // Añadido para hacer la pantalla reutilizable y dinámica

  const PdfViewerScreen({
    Key? key,
    required this.filePath,
    this.title = 'Reporte', // Valor por defecto por si acaso
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  int _totalPages = 0;
  bool _showSearchBar = false;
  bool _hasMatches = false;

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    _searchResult.clear();
    super.dispose();
  }

  // BÚSQUEDA EN TIEMPO REAL: Se ejecuta cada vez que el usuario escribe una letra
  void _onSearchChanged(String text) async {
    if (text.isEmpty) {
      _clearSearch();
      return;
    }

    // Buscamos el texto en el documento
    final result = await _pdfViewerController.searchText(text);

    setState(() {
      _searchResult = result;
      _hasMatches = _searchResult.hasResult;
    });

    // Si encuentra algo, te desplaza AUTOMÁTICAMENTE en vivo al primer resultado
    if (_hasMatches) {
      _searchResult.nextInstance();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchResult.clear();
    setState(() {
      _hasMatches = false;
    });
  }

  // Cuadro flotante pequeño para ir a una página específica
  void _mostrarIrAPaginaDialog() {
    final TextEditingController pageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Ir a la página', style: TextStyle(fontSize: 18)),
          content: TextField(
            controller: pageController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ej: 5 (Max: $_totalPages)',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final page = int.tryParse(pageController.text);
                if (page != null && page > 0 && page <= _totalPages) {
                  _pdfViewerController.jumpToPage(page);
                  Navigator.pop(context);
                }
              },
              child: const Text('Ir'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarPdf() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.filePath)],
        text: widget.title, // Alineado dinámicamente con el título del reporte
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al compartir: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        // Si no hay coincidencias y el texto no está vacío, el AppBar avisa discretamente
        backgroundColor:
            (_showSearchBar &&
                _searchController.text.isNotEmpty &&
                !_hasMatches)
            ? Colors.red[900]
            : null,
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: InputDecoration(
                  hintText: _hasMatches
                      ? 'Buscar en el documento...'
                      : 'Sin coincidencias...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged:
                    _onSearchChanged, // Reacción en tiempo real letra por letra
              )
            : Text(widget.title), // Muestra el nombre dinámico en el AppBar
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_showSearchBar) {
                  _showSearchBar = false;
                  _clearSearch();
                } else {
                  _showSearchBar = true;
                }
              });
            },
          ),
          if (!_showSearchBar)
            IconButton(icon: const Icon(Icons.share), onPressed: _guardarPdf),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.file(
            File(widget.filePath),
            controller: _pdfViewerController,
            enableDoubleTapZooming: true,
            interactionMode: PdfInteractionMode.pan,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _totalPages = _pdfViewerController.pageCount;
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              setState(() {
                _currentPage = details.newPageNumber;
              });
            },
          ),

          // PANEL FLOTANTE DE BÚSQUEDA (Solo se muestra si realmente hay coincidencias)
          if (_showSearchBar &&
              _hasMatches &&
              _searchController.text.isNotEmpty)
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Resultado: ${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up),
                            onPressed: () {
                              _searchResult.previousInstance();
                              setState(() {});
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onPressed: () {
                              _searchResult.nextInstance();
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // BURBUJA DE PÁGINAS (BOTÓN FLOTANTE DISCRETO)
          if (_totalPages > 0)
            Positioned(
              bottom: 25,
              right: 20,
              child: GestureDetector(
                onTap: _mostrarIrAPaginaDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_currentPage / $_totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==============================================================================
// VISOR DE WORD INTERNO (HTML) - Alineado con la línea gráfica de la App
// ==============================================================================
class DocxViewerScreen extends StatefulWidget {
  final String filePath;

  const DocxViewerScreen({Key? key, required this.filePath}) : super(key: key);

  @override
  State<DocxViewerScreen> createState() => _DocxViewerScreenState();
}

class _DocxViewerScreenState extends State<DocxViewerScreen> {
  String? _htmlContent;

  @override
  void initState() {
    super.initState();
    _cargarArchivo();
  }

  Future<void> _cargarArchivo() async {
    try {
      final file = File(widget.filePath);
      String htmlString = await file.readAsString();

      // INYECCIÓN CSS INTELIGENTE PARA CONTROLAR EL MODO OSCURO AUTOMÁTICAMENTE
      // Usamos 'currentColor' para heredar el color del texto del Scaffold sin alterar fondos
      final String correccionColor = '''
        <style>
          table, tr, td, th { 
            border-color: currentColor !important; 
          }
          body, p, span, td, th { 
            color: currentColor !important; 
          }
        </style>
      ''';

      // Insertamos los estilos al inicio del archivo HTML
      htmlString = correccionColor + htmlString;

      if (mounted) {
        setState(() {
          _htmlContent = htmlString;
        });
      }
    } catch (e) {
      debugPrint("Error cargando archivo Word en visor: $e");
    }
  }

  Future<void> _guardarDoc() async {
    try {
      await Share.shareXFiles([
        XFile(widget.filePath),
      ], text: 'Minuta Operacional (Word)');
    } catch (e) {
      debugPrint("Error al compartir archivo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detectamos si la app está corriendo en modo oscuro para ajustar el fondo del contenedor
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visor de Reporte'),
        centerTitle:
            false, // Alineado a la izquierda igual que los demás módulos
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Guardar / Compartir',
            onPressed: _guardarDoc,
          ),
        ],
      ),
      // Contenedor principal con fondo adaptable para una transición visual suave
      body: Container(
        color: isDark ? const Color(0xff121212) : Colors.white,
        child: _htmlContent == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: HtmlWidget(
                  _htmlContent!,
                  factoryBuilder: () => MyWidgetFactory(),
                  textStyle: const TextStyle(fontSize: 14, fontFamily: 'Arial'),
                ),
              ),
      ),
    );
  }
}

// ==============================================================================
// FACTORÍA REQUERIDA PARA EL RENDERIZADO CORRECTO DE TABLAS HTML
// ==============================================================================
class MyWidgetFactory extends WidgetFactory {
  @override
  bool get isHtmlTableSupported => true;
}
