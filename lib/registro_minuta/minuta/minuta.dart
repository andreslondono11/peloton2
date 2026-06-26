import 'dart:convert'; // <--- IMPORTANTE
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
// import 'package:open_file/open_file.dart'; // <--- NUEVA IMPORTACIÓN
import 'package:sqflite/sqflite.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../BD/db_manager.dart';

// ────────────────────────────────────────────────────────────────
// FUNCIÓN OPTIMIZADA: Genera PDF masivo en Isolate (300k+ registros)
// ────────────────────────────────────────────────────────────────
Future<void> _generarPdfEnIsolate(Map<String, dynamic> params) async {
  final List<dynamic> chunks = params['chunks'];
  final String ruta = params['ruta'];
  final String titulo = params['titulo'] ?? 'REPORTE';

  final pdf = pw.Document();
  final headerStyle = pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    fontSize: 10,
    color: PdfColors.white,
  );
  final cellStyle = const pw.TextStyle(fontSize: 9);

  // Aplanamos los lotes (chunks) en una sola lista para la tabla fluida
  final List<List<String>> datosSeguros = [];
  for (var chunk in chunks) {
    for (var m in chunk) {
      datosSeguros.add([
        m['fecha']?.toString() ?? '',
        m['hora']?.toString() ?? '',
        m['asunto']?.toString() ?? '',
        m['anotaciones']?.toString() ?? '',
        // (m['adjuntos'] != null && m['adjuntos'].toString().isNotEmpty)
        //     ? 'Sí'
        //     : 'No',
      ]);
    }
  }

  // Generamos el documento usando la paginación fluida y automática de MultiPage
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter.copyWith(
        marginBottom: 1.5 * PdfPageFormat.cm,
        marginTop: 1.5 * PdfPageFormat.cm,
        marginLeft: 1.2 * PdfPageFormat.cm,
        marginRight: 1.2 * PdfPageFormat.cm,
      ),
      header: (context) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(bottom: 15),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "DIARIO OPERACIONAL - CALIPSO",
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              "Pág. ${context.pageNumber} de ${context.pagesCount}",
              style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
            ),
          ],
        ),
      ),
      footer: (context) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 15),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
        ),
        padding: const pw.EdgeInsets.only(top: 5),
        child: pw.Text(
          "Generado por CALIPSO",
          style: const pw.TextStyle(color: PdfColors.grey500, fontSize: 8),
        ),
      ),
      build: (context) => [
        pw.Text(
          titulo,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 16,
            color: PdfColors.indigo900,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(70), // Fecha
            1: const pw.FixedColumnWidth(40), // Hora
            2: const pw.FixedColumnWidth(110), // Asunto
            3: const pw.FlexColumnWidth(), // Anotaciones
            // 4: const pw.FixedColumnWidth(30), // Adjuntos
          },
          children: [
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
                // pw.Padding(
                //   padding: const pw.EdgeInsets.all(6),
                //   child: pw.Text('Adj', style: headerStyle),
                // ),
              ],
            ),
            ...datosSeguros.asMap().entries.map((entry) {
              final i = entry.key;
              final fila = entry.value;
              return pw.TableRow(
                decoration: i.isOdd
                    ? const pw.BoxDecoration(color: PdfColors.grey100)
                    : const pw.BoxDecoration(),
                children: fila.map((texto) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(texto, style: cellStyle),
                  );
                }).toList(),
              );
            }),
          ],
        ),

        pw.SizedBox(height: 40),

        // Sección de firma y huella
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Línea de firma
            pw.Column(
              children: [
                pw.Container(width: 200, height: 1, color: PdfColors.black),
                pw.SizedBox(height: 5),
                pw.Text("Firma", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),

            // Cuadro de huella
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

  // Guarda los bytes directamente en el almacenamiento secundario desde el Isolate
  final bytes = await pdf.save();
  final file = File(ruta);
  await file.writeAsBytes(bytes, flush: true);
}

class MinutasScreen extends StatefulWidget {
  const MinutasScreen({super.key});
  @override
  State<MinutasScreen> createState() => _MinutasScreenState();
}

class _MinutasScreenState extends State<MinutasScreen> {
  List<Map<String, dynamic>> _allMinutas = [];
  List<Map<String, dynamic>> _filteredMinutas = [];
  final TextEditingController _searchController = TextEditingController();
  final String _tableName = 'minutas';

  String? _nombreUsuario;
  bool _cargandoUsuario = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarioLogueado();
    _cargarDatos();
  }

  // ---> MÉTODO ROBUSTO OPTIMIZADO <---
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
      print("Error cargando usuario en minutas: $e");
    }
    if (mounted) setState(() => _cargandoUsuario = false);
  }

  // CORRECTO: Usa database (BD del usuario actual)
  Future<void> _cargarDatos() async {
    final db = await DBManager.instance.database;
    final data = await db.query('minutas', orderBy: 'fecha ASC, hora ASC');
    setState(() {
      _allMinutas = data;
      _filteredMinutas = data;
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

        int registrosImportados = 0;

        for (var table in excel.tables.keys) {
          bool isFirstRow = true;
          for (var row in excel.tables[table]!.rows) {
            if (isFirstRow) {
              isFirstRow = false;
              continue;
            }
            if (row[0] != null && row[2] != null) {
              await db.insert('minutas', {
                'fecha': row[0]?.value.toString() ?? '',
                'hora': row[1]?.value.toString() ?? '',
                'asunto': row[2]?.value.toString() ?? '',
                'anotaciones': row[3]?.value.toString() ?? '',
              });
              registrosImportados++;
            }
          }
        }

        _cargarDatos();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Se importaron $registrosImportados registros correctamente.",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error importando: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al leer el archivo Excel: $e")),
      );
    }
  }

  Future<void> _exportarExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Diario Operacional'];
      sheet.appendRow([
        TextCellValue('Fecha'),
        TextCellValue('Hora'),
        TextCellValue('Asunto'),
        TextCellValue('Anotaciones'),
      ]);
      for (var m in _filteredMinutas) {
        sheet.appendRow([
          TextCellValue(m['fecha'].toString()),
          TextCellValue(m['hora'].toString()),
          TextCellValue(m['asunto'].toString()),
          TextCellValue(m['anotaciones'].toString()),
        ]);
      }
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Diario_Operacional.xlsx';
      final file = File(filePath);
      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(filePath)], text: 'Reporte Excel');
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // ─────────────────────────────────────────────────────
  // FUNCIÓN EXPORTAR WORD OPERACIONAL (Usa Visor Interno)
  // ─────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────
  // FUNCIÓN EXPORTAR WORD OPERACIONAL (Usa Visor Interno)
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

      // 2. Validación de datos vacíos antes de procesar el archivo
      if (_filteredMinutas.isEmpty) {
        if (mounted) Navigator.pop(context); // Cerrar loader
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay datos para exportar")),
          );
        }
        return;
      }

      // 3. Detectar si la app está en modo oscuro para ajustar los fondos alternos
      final bool isDark = Theme.of(context).brightness == Brightness.dark;

      // 4. Construcción del buffer HTML compatible con MS Word (.doc/.docx)
      final buffer = StringBuffer();

      buffer.writeln(
        '<html xmlns:o="urn:schemas-microsoft-com:office:office" '
        'xmlns:w="urn:schemas-microsoft-com:office:word" '
        'xmlns="http://www.w3.org/TR/REC-html40">',
      );
      buffer.writeln('<head><meta charset="utf-8">');
      buffer.writeln('<meta name=ProgId content=Word.Document>');
      buffer.writeln('<title>Reporte_CALIPSO</title></head><body>');

      // TÍTULO DINÁMICO (Consistente con la línea gráfica)
      buffer.writeln(
        '<h1 style="text-align: center; font-family: Arial; font-size: 20pt; font-weight: bold; margin-bottom: 20px;">REPORTE OPERACIONAL</h1>',
      );

      // --- TABLA PRINCIPAL (Se usa #1A237E Indigo900 para homogeneizar con el PDF) ---
      buffer.writeln(
        '<table style="width: 100%; border-collapse: collapse; border: 1px solid #000000; font-family: Arial; font-size: 10pt;">',
      );

      // Encabezados de la Tabla
      buffer.writeln('<tr>');
      buffer.writeln(
        '<th style="width: 15%; background-color: #1A237E; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Fecha</th>',
      );
      buffer.writeln(
        '<th style="width: 12%; background-color: #1A237E; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Hora</th>',
      );
      buffer.writeln(
        '<th style="width: 23%; background-color: #1A237E; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Asunto</th>',
      );
      buffer.writeln(
        '<th style="width: 42%; background-color: #1A237E; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Anotaciones</th>',
      );
      buffer.writeln(
        '<th style="width: 8%; background-color: #1A237E; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Adj</th>',
      );
      buffer.writeln('</tr>');

      // --- FILAS DE DATOS DINÁMICOS ---
      int index = 0;
      for (var m in _filteredMinutas) {
        String anotaciones = (m['anotaciones']?.toString() ?? '').replaceAll(
          '\n',
          '<br>',
        );
        String adjuntos = (m['adjuntos']?.toString().isNotEmpty ?? false)
            ? 'Sí'
            : 'No';

        // Solución Inteligente Modo Oscuro: Gris oscuro (#2C2C2C) para oscuro, Gris claro (#F5F5F5) para claro
        String backgroundHex = isDark ? '#2C2C2C' : '#F5F5F5';
        String rowBg = (index % 2 != 0)
            ? 'background-color: $backgroundHex;'
            : '';

        buffer.writeln('<tr style="$rowBg">');
        buffer.writeln(
          '<td style="border: 1px solid #000000; padding: 6px; text-align: center;">${m['fecha'] ?? ''}</td>',
        );
        buffer.writeln(
          '<td style="border: 1px solid #000000; padding: 6px; text-align: center;">${m['hora'] ?? ''}</td>',
        );
        buffer.writeln(
          '<td style="border: 1px solid #000000; padding: 6px; text-align: left;">${m['asunto'] ?? ''}</td>',
        );
        buffer.writeln(
          '<td style="border: 1px solid #000000; padding: 6px; text-align: left;">$anotaciones</td>',
        );
        buffer.writeln(
          '<td style="border: 1px solid #000000; padding: 6px; text-align: center;">$adjuntos</td>',
        );
        buffer.writeln('</tr>');
        index++;
      }

      buffer.writeln('</table>');
      buffer.writeln('</body></html>');

      // 5. Guardar archivo en el directorio temporal
      final tempDir = await getTemporaryDirectory();
      final String fileName =
          'Reporte_Operacional_${DateTime.now().millisecondsSinceEpoch}.doc';
      final file = File('${tempDir.path}/$fileName');

      await file.writeAsBytes(const Utf8Encoder().convert(buffer.toString()));

      // 6. Quitar loader de la pantalla de forma segura
      if (mounted) Navigator.pop(context);

      // 7. Redirección limpia al visor moderno interno de Word
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocxViewerScreen(filePath: file.path),
          ),
        );
      }
    } catch (e) {
      // Manejo de excepciones y cierre preventivo del diálogo de carga
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      debugPrint("Error Word Operacional: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al generar Word: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportarPDF() async {
    try {
      // 1. Mostrar Loader idéntico al de Inteligencia
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );

      // 2. Definir tamaño del lote (Chunk size)
      const int chunkSize = 15;
      List<List<Map<String, dynamic>>> allChunks = [];

      // 3. Consulta paginada directa a la base de datos de la Minuta
      final db = await DBManager.instance.database;

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
          orderBy: 'fecha ASC, hora ASC',
          limit: chunkSize,
          offset: offset,
        );

        if (batch.isEmpty) break;

        // Mapeo y limpieza de los campos específicos de la Minuta
        final cleanBatch = batch.map((m) {
          return {
            'fecha': m['fecha']?.toString() ?? '',
            'hora': m['hora']?.toString() ?? '',
            'asunto': m['asunto']?.toString() ?? '',
            'anotaciones': m['anotaciones']?.toString() ?? '',
            // 'adjuntos': (m['adjuntos']?.toString().isNotEmpty ?? false)
            //     ? 'Sí'
            //     : 'No',
          };
        }).toList();

        allChunks.add(cleanBatch);
        offset += chunkSize;
      }

      // 4. Ruta de salida con el nombre correcto de Minuta
      final dir = await getApplicationDocumentsDirectory();
      final String fileName =
          'Reporte_Diario_Minuta_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');

      // 5. Ejecutar en Isolate
      await compute(_generarPdfEnIsolate, {
        'chunks': allChunks,
        'ruta': file.path,
        'titulo': 'REPORTE DIARIO DE MINUTA',
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
          Navigator.pop(context);
        } catch (_) {}
      }
      debugPrint("Error PDF Minuta: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al exportar PDF: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _abrirFormulario({Map<String, dynamic>? minuta}) {
    final bool esEdicion = minuta != null;
    final fCon = TextEditingController(
      text: esEdicion
          ? minuta['fecha']
          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final hCon = TextEditingController(
      text: esEdicion
          ? minuta['hora']
          : DateFormat('HH:mm').format(DateTime.now()),
    );
    final aCon = TextEditingController(text: esEdicion ? minuta['asunto'] : '');
    final nCon = TextEditingController(
      text: esEdicion ? minuta['anotaciones'] : '',
    );

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        contentPadding: const EdgeInsets.all(30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          esEdicion ? "Modificar Registro" : "Nuevo Registro Diario",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
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
                          labelText: "Fecha (AAAA-MM-DD)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: TextField(
                        controller: hCon,
                        decoration: const InputDecoration(
                          labelText: "Hora (HH:MM)",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.access_time),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: aCon,
                  decoration: const InputDecoration(
                    labelText: "Asunto del Reporte",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: nCon,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: "Anotaciones Detalladas",
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text(
              "Cancelar",
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: esEdicion
                  ? Colors.orange
                  : const Color(0xFF1A237E),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: () async {
              if (aCon.text.isEmpty || nCon.text.isEmpty) return;
              final db = await DBManager.instance.database;
              final datos = {
                'fecha': fCon.text,
                'hora': hCon.text,
                'asunto': aCon.text,
                'anotaciones': nCon.text,
              };
              if (esEdicion) {
                await db.update(
                  'minutas',
                  datos,
                  where: 'id = ?',
                  whereArgs: [minuta['id']],
                );
              } else {
                await db.insert('minutas', datos);
              }
              Navigator.pop(c);
              _cargarDatos();
            },
            child: Text(
              esEdicion ? "Actualizar" : "Guardar",
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Diario Operacional",
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
                _btn("Excel", Colors.green, Icons.table_chart, _exportarExcel),
                const SizedBox(width: 10),
                _btn("Word", Colors.blue, Icons.description, _exportarWord),
                const SizedBox(width: 10),
                _btn(
                  "Importar",
                  Colors.blueGrey,
                  Icons.file_upload,
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
                hintText: "Buscar...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() {
                _filteredMinutas = _allMinutas
                    .where(
                      (m) =>
                          m['asunto'].toLowerCase().contains(v.toLowerCase()) ||
                          m['anotaciones'].toLowerCase().contains(
                            v.toLowerCase(),
                          ),
                    )
                    .toList();
              }),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  defaultVerticalAlignment: TableCellVerticalAlignment.top,
                  columnWidths: const {
                    0: FlexColumnWidth(1.2),
                    1: FlexColumnWidth(0.8),
                    2: FlexColumnWidth(1.5),
                    3: FlexColumnWidth(4),
                    4: FlexColumnWidth(1.2),
                  },
                  children: [
                    _header(),
                    ..._filteredMinutas.map((m) => _row(m)),
                  ],
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
      children: ['Fecha', 'Hora', 'Asunto', 'Anotaciones', 'Acciones'].map((t) {
        return Container(
          color: const Color(0xFF2196F3),
          padding: const EdgeInsets.all(10),
          child: Text(
            t,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  TableRow _row(Map<String, dynamic> m) => TableRow(
    children: [
      _c(m['fecha']),
      _c(m['hora']),
      _c(m['asunto']),
      _c(m['anotaciones']),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
            onPressed: () => _abrirFormulario(minuta: m),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
            onPressed: () async {
              final db = await DBManager.instance.database;
              await db.delete('minutas', where: 'id = ?', whereArgs: [m['id']]);
              _cargarDatos();
            },
          ),
        ],
      ),
    ],
  );

  Widget _c(dynamic valor) {
    String texto = '';
    if (valor != null) {
      texto = valor.toString();
    }
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(texto, style: const TextStyle(fontSize: 12)),
    );
  }

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

  const PdfViewerScreen({Key? key, required this.filePath}) : super(key: key);

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

  // BÚSQUEDA EN TIEMPO REAL: Salta automáticamente al texto escrito letra por letra
  void _onSearchChanged(String text) async {
    if (text.isEmpty) {
      _clearSearch();
      return;
    }

    final result = await _pdfViewerController.searchText(text);

    setState(() {
      _searchResult = result;
      _hasMatches = _searchResult.hasResult;
    });

    // Desplazamiento inmediato en vivo al primer resultado encontrado
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

  // Pop-up flotante minimalista para saltar a una página específica de la minuta
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
              hintText: 'Ej: 3 (Max: $_totalPages)',
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

  // Compartir o exportar externamente el reporte generado
  Future<void> _guardarPdf() async {
    try {
      await Share.shareXFiles([
        XFile(widget.filePath),
      ], text: 'Reporte Diario de Minuta');
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
        // Alerta visual cambiando a rojo discreto si se escribe algo que no existe
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
                      ? 'Buscar en la minuta...'
                      : 'Sin coincidencia...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  border: InputBorder.none,
                ),
                onChanged: _onSearchChanged,
              )
            : const Text(
                'REPORTE DIARIO DE MINUTA',
              ), // TÍTULO ALINEADO CORRECTAMENTE
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
          // VISOR CON ZOOM GESTUAL NATURALLY (Pinch-to-zoom nativo y limpio)
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

          // PANEL FLOTANTE DE NAVEGACIÓN DE BÚSQUEDA (Flechas arriba/abajo discretas)
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

          // BURBUJA DE INTERACCIÓN DE PÁGINAS (Tócala para abrir el saltador rápido)
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
// VISOR DE WORD (HTML) - Solución Sin Conflictos
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
      final htmlString = await file.readAsString();

      if (mounted) {
        setState(() {
          _htmlContent = htmlString;
        });
      }
    } catch (e) {
      debugPrint("Error cargando archivo: $e");
    }
  }

  Future<void> _guardarDoc() async {
    try {
      await Share.shareXFiles([
        XFile(widget.filePath),
      ], text: 'Minuta Operacional(Word)');
    } catch (e) {
      debugPrint("Error al guardar: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visor de Reporte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Guardar',
            onPressed: _guardarDoc,
          ),
        ],
      ),
      body: _htmlContent == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: HtmlWidget(
                _htmlContent!,
                factoryBuilder: () => MyWidgetFactory(),
                textStyle: const TextStyle(fontSize: 14),
              ),
            ),
    );
  }
}

class MyWidgetFactory extends WidgetFactory {}

// Necesario para que las tablas se vean bien
