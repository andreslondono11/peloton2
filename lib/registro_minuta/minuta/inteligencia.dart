// // // import 'dart:io';
// // // import 'package:flutter/material.dart';
// // // import 'package:flutter/foundation.dart';
// // // import 'package:intl/intl.dart';
// // // import 'package:excel/excel.dart';
// // // import 'package:path_provider/path_provider.dart';
// // // import 'package:share_plus/share_plus.dart';
// // // import 'package:file_picker/file_picker.dart';
// // // import '../../BD/db_manager.dart';
// // // import 'package:pdf/pdf.dart';
// // // import 'package:pdf/widgets.dart' as pw;

// // // // ─── FUNCIÓN TOP-LEVEL para generar PDF en isolate separado ───
// // // Future<List<int>> _generarPdfBytesIsolate(
// // //   List<Map<String, dynamic>> data,
// // // ) async {
// // //   final pdf = pw.Document();

// // //   pdf.addPage(
// // //     pw.MultiPage(
// // //       pageFormat: PdfPageFormat.letter.copyWith(
// // //         marginBottom: 1.5 * PdfPageFormat.cm,
// // //         marginTop: 1.5 * PdfPageFormat.cm,
// // //         marginLeft: 1 * PdfPageFormat.cm,
// // //         marginRight: 1 * PdfPageFormat.cm,
// // //       ),
// // //       header: (context) => pw.Container(
// // //         alignment: pw.Alignment.centerRight,
// // //         margin: const pw.EdgeInsets.only(bottom: 20),
// // //         child: pw.Text(
// // //           "INTELIGENCIA - CALIPSO",
// // //           style: pw.TextStyle(color: PdfColors.grey700, fontSize: 12),
// // //         ),
// // //       ),
// // //       footer: (context) => pw.Container(
// // //         alignment: pw.Alignment.centerRight,
// // //         margin: const pw.EdgeInsets.only(top: 10),
// // //         child: pw.Text(
// // //           'Página ${context.pageNumber} de ${context.pagesCount}',
// // //           style: const pw.TextStyle(fontSize: 10),
// // //         ),
// // //       ),
// // //       build: (context) => [
// // //         pw.Header(
// // //           level: 0,
// // //           child: pw.Text(
// // //             "REPORTE LIBRO DE INTELIGENCIA",
// // //             style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
// // //           ),
// // //         ),
// // //         pw.SizedBox(height: 10),
// // //         pw.TableHelper.fromTextArray(
// // //           headers: ['Fecha', 'Hora', 'Asunto', 'Medio', 'Anotaciones'],
// // //           data: data
// // //               .map(
// // //                 (m) => [
// // //                   m['fecha']?.toString() ?? '',
// // //                   m['hora']?.toString() ?? '',
// // //                   m['asunto']?.toString() ?? '',
// // //                   m['medio']?.toString() ?? '',
// // //                   m['anotaciones']?.toString() ?? '',
// // //                 ],
// // //               )
// // //               .toList(),
// // //           headerStyle: pw.TextStyle(
// // //             color: PdfColors.white,
// // //             fontWeight: pw.FontWeight.bold,
// // //             fontSize: 10,
// // //           ),
// // //           headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
// // //           cellStyle: const pw.TextStyle(fontSize: 9),
// // //           cellAlignment: pw.Alignment.topLeft,
// // //           columnWidths: {
// // //             0: const pw.FixedColumnWidth(70),
// // //             1: const pw.FixedColumnWidth(45),
// // //             2: const pw.FixedColumnWidth(90),
// // //             3: const pw.FixedColumnWidth(70),
// // //             4: const pw.FlexColumnWidth(),
// // //           },
// // //         ),
// // //       ],
// // //     ),
// // //   );

// // //   return await pdf.save();
// // // }

// // // class InteligenciaScreen extends StatefulWidget {
// // //   const InteligenciaScreen({super.key});
// // //   @override
// // //   State<InteligenciaScreen> createState() => _InteligenciaScreenState();
// // // }

// // // class _InteligenciaScreenState extends State<InteligenciaScreen> {
// // //   List<Map<String, dynamic>> _filteredData = [];
// // //   final String _tableName = 'inteligencia';

// // //   String? _nombreUsuario;
// // //   bool _cargandoUsuario = true;

// // //   @override
// // //   void initState() {
// // //     super.initState();
// // //     _cargarUsuarioLogueado();
// // //     _cargarDatos();
// // //   }

// // //   // CORRECTO: Usar authDatabase para el nombre
// // //   Future<void> _cargarUsuarioLogueado() async {
// // //     final db = await DBManager.instance.authDatabase;
// // //     try {
// // //       final sesion = await db.query('sesion_activa', limit: 1);
// // //       if (sesion.isNotEmpty) {
// // //         final int usuarioId = sesion.first['usuario_id'] as int;
// // //         final usuario = await db.query(
// // //           'usuarios',
// // //           where: 'id = ?',
// // //           whereArgs: [usuarioId],
// // //           limit: 1,
// // //         );

// // //         if (usuario.isNotEmpty && mounted) {
// // //           setState(() {
// // //             _nombreUsuario = usuario.first['nombres'] as String?;
// // //             _cargandoUsuario = false;
// // //           });
// // //           return;
// // //         }
// // //       }
// // //     } catch (e) {
// // //       print("Error cargando usuario en inteligencia: $e");
// // //     }
// // //     if (mounted) setState(() => _cargandoUsuario = false);
// // //   }

// // //   // ---> CORRECCIÓN CRÍTICA: Usar database (BD del usuario) para leer sus inteligencias <---
// // //   Future<void> _cargarDatos() async {
// // //     final db = await DBManager.instance.database;
// // //     final data = await db.query(_tableName, orderBy: 'fecha ASC, hora ASC');
// // //     setState(() {
// // //       _filteredData = data;
// // //     });
// // //   }

// // //   Future<void> _exportarPDF() async {
// // //     try {
// // //       showDialog(
// // //         context: context,
// // //         barrierDismissible: false,
// // //         builder: (context) => const PopScope(
// // //           canPop: false,
// // //           child: Center(child: CircularProgressIndicator()),
// // //         ),
// // //       );

// // //       final data = _filteredData
// // //           .map(
// // //             (m) => {
// // //               'fecha': m['fecha']?.toString() ?? '',
// // //               'hora': m['hora']?.toString() ?? '',
// // //               'asunto': m['asunto']?.toString() ?? '',
// // //               'medio': m['medio']?.toString() ?? '',
// // //               'anotaciones': m['anotaciones']?.toString() ?? '',
// // //             },
// // //           )
// // //           .toList();

// // //       final pdfBytes = await compute(_generarPdfBytesIsolate, data);

// // //       final dir = await getTemporaryDirectory();
// // //       final String fileName =
// // //           'Reporte_Inteligencia_${DateTime.now().millisecondsSinceEpoch}.pdf';
// // //       final file = File('${dir.path}/$fileName');

// // //       final sink = file.openWrite();
// // //       const chunkSize = 65536;
// // //       for (int i = 0; i < pdfBytes.length; i += chunkSize) {
// // //         final end = (i + chunkSize > pdfBytes.length)
// // //             ? pdfBytes.length
// // //             : i + chunkSize;
// // //         sink.add(pdfBytes.sublist(i, end));
// // //       }
// // //       await sink.flush();
// // //       await sink.close();

// // //       if (mounted) Navigator.pop(context);
// // //       await Share.shareXFiles([
// // //         XFile(file.path),
// // //       ], text: 'Reporte PDF Inteligencia');
// // //     } catch (e) {
// // //       if (mounted) {
// // //         try {
// // //           Navigator.pop(context);
// // //         } catch (_) {}
// // //       }
// // //       debugPrint("Error PDF Inteligencia: $e");
// // //       if (mounted) {
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           SnackBar(content: Text("No se pudo generar el PDF: $e")),
// // //         );
// // //       }
// // //     }
// // //   }

// // //   Future<void> _importarExcel() async {
// // //     try {
// // //       FilePickerResult? result = await FilePicker.platform.pickFiles(
// // //         type: FileType.custom,
// // //         allowedExtensions: ['xlsx'],
// // //       );
// // //       if (result != null) {
// // //         var bytes = File(result.files.single.path!).readAsBytesSync();
// // //         var excel = Excel.decodeBytes(bytes);
// // //         // CORRECTO: Usar database para guardar en la BD del usuario
// // //         final db = await DBManager.instance.database;

// // //         for (var table in excel.tables.keys) {
// // //           var rows = excel.tables[table]!.rows;
// // //           for (int i = 1; i < rows.length; i++) {
// // //             var row = rows[i];
// // //             if (row.length >= 5) {
// // //               await db.insert(_tableName, {
// // //                 'fecha': row[0]?.value.toString() ?? '',
// // //                 'hora': row[1]?.value.toString() ?? '',
// // //                 'asunto': row[2]?.value.toString() ?? '',
// // //                 'medio': row[3]?.value.toString() ?? '',
// // //                 'anotaciones': row[4]?.value.toString() ?? '',
// // //               });
// // //             }
// // //           }
// // //         }
// // //         _cargarDatos();
// // //         ScaffoldMessenger.of(context).showSnackBar(
// // //           const SnackBar(content: Text("Datos importados con éxito")),
// // //         );
// // //       }
// // //     } catch (e) {
// // //       ScaffoldMessenger.of(
// // //         context,
// // //       ).showSnackBar(SnackBar(content: Text("Error al importar: $e")));
// // //     }
// // //   }

// // //   Future<void> _exportarExcel() async {
// // //     var excel = Excel.createExcel();
// // //     Sheet sheet = excel['Inteligencia'];
// // //     sheet.appendRow([
// // //       TextCellValue('Fecha'),
// // //       TextCellValue('Hora'),
// // //       TextCellValue('Asunto'),
// // //       TextCellValue('Medio'),
// // //       TextCellValue('Anotaciones'),
// // //     ]);
// // //     for (var m in _filteredData) {
// // //       sheet.appendRow([
// // //         TextCellValue(m['fecha']),
// // //         TextCellValue(m['hora']),
// // //         TextCellValue(m['asunto']),
// // //         TextCellValue(m['medio']),
// // //         TextCellValue(m['anotaciones']),
// // //       ]);
// // //     }
// // //     final directory = await getTemporaryDirectory();
// // //     final filePath = '${directory.path}/Reporte_Inteligencia.xlsx';
// // //     final bytes = excel.save();
// // //     if (bytes != null) {
// // //       await File(filePath).writeAsBytes(bytes);
// // //       await Share.shareXFiles([XFile(filePath)], text: 'Excel Inteligencia');
// // //     }
// // //   }

// // //   void _abrirFormulario({Map<String, dynamic>? item}) {
// // //     final bool esEdicion = item != null;
// // //     final fCon = TextEditingController(
// // //       text: esEdicion
// // //           ? item['fecha']
// // //           : DateFormat('yyyy-MM-dd').format(DateTime.now()),
// // //     );
// // //     final hCon = TextEditingController(
// // //       text: esEdicion
// // //           ? item['hora']
// // //           : DateFormat('HH:mm').format(DateTime.now()),
// // //     );
// // //     final aCon = TextEditingController(text: esEdicion ? item['asunto'] : '');
// // //     final mCon = TextEditingController(text: esEdicion ? item['medio'] : '');
// // //     final nCon = TextEditingController(
// // //       text: esEdicion ? item['anotaciones'] : '',
// // //     );

// // //     showDialog(
// // //       context: context,
// // //       builder: (c) => AlertDialog(
// // //         title: Text(
// // //           esEdicion ? "Editar Inteligencia" : "Nuevo Registro Inteligencia",
// // //         ),
// // //         content: SizedBox(
// // //           width: MediaQuery.of(context).size.width * 0.8,
// // //           child: SingleChildScrollView(
// // //             child: Column(
// // //               mainAxisSize: MainAxisSize.min,
// // //               children: [
// // //                 Row(
// // //                   children: [
// // //                     Expanded(
// // //                       child: TextField(
// // //                         controller: fCon,
// // //                         decoration: const InputDecoration(
// // //                           labelText: "Fecha",
// // //                           border: OutlineInputBorder(),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                     const SizedBox(width: 10),
// // //                     Expanded(
// // //                       child: TextField(
// // //                         controller: hCon,
// // //                         decoration: const InputDecoration(
// // //                           labelText: "Hora",
// // //                           border: OutlineInputBorder(),
// // //                         ),
// // //                       ),
// // //                     ),
// // //                   ],
// // //                 ),
// // //                 const SizedBox(height: 15),
// // //                 TextField(
// // //                   controller: aCon,
// // //                   decoration: const InputDecoration(
// // //                     labelText: "Asunto",
// // //                     border: OutlineInputBorder(),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 15),
// // //                 TextField(
// // //                   controller: mCon,
// // //                   decoration: const InputDecoration(
// // //                     labelText: "Medio (Ej. Humano, Técnico)",
// // //                     border: OutlineInputBorder(),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(height: 15),
// // //                 TextField(
// // //                   controller: nCon,
// // //                   maxLines: 5,
// // //                   decoration: const InputDecoration(
// // //                     labelText: "Anotaciones",
// // //                     border: OutlineInputBorder(),
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ),
// // //         actions: [
// // //           TextButton(
// // //             onPressed: () => Navigator.pop(c),
// // //             child: const Text("Cancelar"),
// // //           ),
// // //           ElevatedButton(
// // //             onPressed: () async {
// // //               // CORRECTO: Usar database para guardar
// // //               final db = await DBManager.instance.database;
// // //               final map = {
// // //                 'fecha': fCon.text,
// // //                 'hora': hCon.text,
// // //                 'asunto': aCon.text,
// // //                 'medio': mCon.text,
// // //                 'anotaciones': nCon.text,
// // //               };
// // //               if (esEdicion) {
// // //                 await db.update(
// // //                   _tableName,
// // //                   map,
// // //                   where: 'id = ?',
// // //                   whereArgs: [item['id']],
// // //                 );
// // //               } else {
// // //                 await db.insert(_tableName, map);
// // //               }
// // //               Navigator.pop(c);
// // //               _cargarDatos();
// // //             },
// // //             child: const Text("Guardar"),
// // //           ),
// // //         ],
// // //       ),
// // //     );
// // //   }

// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(
// // //         title: const Text(
// // //           "Libro de Inteligencia",
// // //           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
// // //         ),
// // //         backgroundColor: const Color(0xFF1A237E),
// // //         iconTheme: const IconThemeData(color: Colors.white),
// // //         actions: [
// // //           Padding(
// // //             padding: const EdgeInsets.only(right: 16.0),
// // //             child: Row(
// // //               children: [
// // //                 Container(
// // //                   width: 8,
// // //                   height: 8,
// // //                   decoration: BoxDecoration(
// // //                     color: Colors.greenAccent,
// // //                     shape: BoxShape.circle,
// // //                     boxShadow: [
// // //                       BoxShadow(
// // //                         color: Colors.greenAccent.withOpacity(0.6),
// // //                         blurRadius: 4,
// // //                         spreadRadius: 1,
// // //                       ),
// // //                     ],
// // //                   ),
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 CircleAvatar(
// // //                   radius: 14,
// // //                   backgroundColor: Colors.white.withOpacity(0.2),
// // //                   child: Text(
// // //                     _nombreUsuario != null && _nombreUsuario!.isNotEmpty
// // //                         ? _nombreUsuario![0].toUpperCase()
// // //                         : "?",
// // //                     style: const TextStyle(
// // //                       color: Colors.white,
// // //                       fontWeight: FontWeight.bold,
// // //                       fontSize: 12,
// // //                     ),
// // //                   ),
// // //                 ),
// // //                 const SizedBox(width: 8),
// // //                 Text(
// // //                   _nombreUsuario ?? "Usuario",
// // //                   style: const TextStyle(
// // //                     color: Colors.white70,
// // //                     fontSize: 14,
// // //                     fontWeight: FontWeight.w500,
// // //                   ),
// // //                 ),
// // //               ],
// // //             ),
// // //           ),
// // //         ],
// // //       ),
// // //       body: Padding(
// // //         padding: const EdgeInsets.all(20),
// // //         child: Column(
// // //           children: [
// // //             SingleChildScrollView(
// // //               scrollDirection: Axis.horizontal,
// // //               child: Row(
// // //                 children: [
// // //                   _btn(
// // //                     "PDF",
// // //                     Colors.purple,
// // //                     Icons.picture_as_pdf,
// // //                     _exportarPDF,
// // //                   ),
// // //                   const SizedBox(width: 10),
// // //                   _btn(
// // //                     "Exportar",
// // //                     Colors.green,
// // //                     Icons.file_upload,
// // //                     _exportarExcel,
// // //                   ),
// // //                   const SizedBox(width: 10),
// // //                   _btn(
// // //                     "Importar",
// // //                     Colors.blueGrey,
// // //                     Icons.file_download,
// // //                     _importarExcel,
// // //                   ),
// // //                   const SizedBox(width: 10),
// // //                   _btn(
// // //                     "Nuevo",
// // //                     Colors.indigo,
// // //                     Icons.add,
// // //                     () => _abrirFormulario(),
// // //                   ),
// // //                 ],
// // //               ),
// // //             ),
// // //             const SizedBox(height: 15),
// // //             Expanded(
// // //               child: SingleChildScrollView(
// // //                 scrollDirection: Axis.vertical,
// // //                 child: Table(
// // //                   border: TableBorder.all(color: Colors.grey[300]!),
// // //                   columnWidths: const {
// // //                     0: FlexColumnWidth(1.2),
// // //                     1: FlexColumnWidth(0.8),
// // //                     2: FlexColumnWidth(1.5),
// // //                     3: FlexColumnWidth(1.5),
// // //                     4: FlexColumnWidth(4),
// // //                     5: FlexColumnWidth(1.5),
// // //                   },
// // //                   children: [_header(), ..._filteredData.map((m) => _row(m))],
// // //                 ),
// // //               ),
// // //             ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }

// // //   TableRow _header() {
// // //     return TableRow(
// // //       children: ['Fecha', 'Hora', 'Asunto', 'Medio', 'Anotación', 'Acciones']
// // //           .map(
// // //             (t) => Container(
// // //               color: const Color(0xFF2196F3),
// // //               padding: const EdgeInsets.all(10),
// // //               child: Text(
// // //                 t,
// // //                 style: const TextStyle(
// // //                   color: Colors.white,
// // //                   fontWeight: FontWeight.bold,
// // //                   fontSize: 12,
// // //                 ),
// // //               ),
// // //             ),
// // //           )
// // //           .toList(),
// // //     );
// // //   }

// // //   TableRow _row(Map<String, dynamic> m) => TableRow(
// // //     children: [
// // //       _c(m['fecha']),
// // //       _c(m['hora']),
// // //       _c(m['asunto']),
// // //       _c(m['medio']),
// // //       _c(m['anotaciones']),
// // //       Row(
// // //         children: [
// // //           IconButton(
// // //             icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
// // //             onPressed: () => _abrirFormulario(item: m),
// // //           ),
// // //           IconButton(
// // //             icon: const Icon(Icons.delete, color: Colors.red, size: 18),
// // //             // ---> CORRECCIÓN CRÍTICA: Usar database para borrar de la BD del usuario <---
// // //             onPressed: () async {
// // //               final db = await DBManager.instance.database;
// // //               await db.delete(
// // //                 _tableName,
// // //                 where: 'id = ?',
// // //                 whereArgs: [m['id']],
// // //               );
// // //               _cargarDatos();
// // //             },
// // //           ),
// // //         ],
// // //       ),
// // //     ],
// // //   );

// // //   Widget _c(String t) => Padding(
// // //     padding: const EdgeInsets.all(10),
// // //     child: Text(t, style: const TextStyle(fontSize: 11)),
// // //   );

// // //   Widget _btn(String t, Color c, IconData i, VoidCallback o) =>
// // //       ElevatedButton.icon(
// // //         onPressed: o,
// // //         icon: Icon(i, size: 16, color: Colors.white),
// // //         label: Text(t, style: const TextStyle(color: Colors.white)),
// // //         style: ElevatedButton.styleFrom(backgroundColor: c),
// // //       );
// // // }
// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/foundation.dart';
// // import 'package:intl/intl.dart';
// // import 'package:excel/excel.dart';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:share_plus/share_plus.dart';
// // import 'package:file_picker/file_picker.dart';
// // import '../../BD/db_manager.dart';
// // import 'package:pdf/pdf.dart';
// // import 'package:pdf/widgets.dart' as pw;

// // // ─── FUNCIÓN TOP-LEVEL para generar PDF en isolate separado ───
// // Future<List<int>> _generarPdfBytesIsolate(
// //   List<Map<String, dynamic>> data,
// // ) async {
// //   final pdf = pw.Document();

// //   pdf.addPage(
// //     pw.MultiPage(
// //       pageFormat: PdfPageFormat.letter.copyWith(
// //         marginBottom: 1.5 * PdfPageFormat.cm,
// //         marginTop: 1.5 * PdfPageFormat.cm,
// //         marginLeft: 1 * PdfPageFormat.cm,
// //         marginRight: 1 * PdfPageFormat.cm,
// //       ),
// //       header: (context) => pw.Container(
// //         alignment: pw.Alignment.centerRight,
// //         margin: const pw.EdgeInsets.only(bottom: 20),
// //         child: pw.Text(
// //           "INTELIGENCIA - CALIPSO",
// //           style: pw.TextStyle(color: PdfColors.grey700, fontSize: 12),
// //         ),
// //       ),
// //       footer: (context) => pw.Container(
// //         alignment: pw.Alignment.centerRight,
// //         margin: const pw.EdgeInsets.only(top: 10),
// //         child: pw.Text(
// //           'Página ${context.pageNumber} de ${context.pagesCount}',
// //           style: const pw.TextStyle(fontSize: 10),
// //         ),
// //       ),
// //       build: (context) => [
// //         pw.Header(
// //           level: 0,
// //           child: pw.Text(
// //             "REPORTE LIBRO DE INTELIGENCIA",
// //             style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
// //           ),
// //         ),
// //         pw.SizedBox(height: 10),
// //         pw.TableHelper.fromTextArray(
// //           headers: ['Fecha', 'Hora', 'Asunto', 'Medio', 'Anotaciones'],
// //           data: data
// //               .map(
// //                 (m) => [
// //                   m['fecha']?.toString() ?? '',
// //                   m['hora']?.toString() ?? '',
// //                   m['asunto']?.toString() ?? '',
// //                   m['medio']?.toString() ?? '',
// //                   m['anotaciones']?.toString() ?? '',
// //                 ],
// //               )
// //               .toList(),
// //           headerStyle: pw.TextStyle(
// //             color: PdfColors.white,
// //             fontWeight: pw.FontWeight.bold,
// //             fontSize: 10,
// //           ),
// //           headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
// //           cellStyle: const pw.TextStyle(fontSize: 9),
// //           cellAlignment: pw.Alignment.topLeft,
// //           columnWidths: {
// //             0: const pw.FixedColumnWidth(70),
// //             1: const pw.FixedColumnWidth(45),
// //             2: const pw.FixedColumnWidth(90),
// //             3: const pw.FixedColumnWidth(70),
// //             4: const pw.FlexColumnWidth(),
// //           },
// //         ),
// //       ],
// //     ),
// //   );

// //   return await pdf.save();
// // }

// // class InteligenciaScreen extends StatefulWidget {
// //   const InteligenciaScreen({super.key});
// //   @override
// //   State<InteligenciaScreen> createState() => _InteligenciaScreenState();
// // }

// // class _InteligenciaScreenState extends State<InteligenciaScreen> {
// //   List<Map<String, dynamic>> _allData = []; // Almacena TODOS los datos
// //   List<Map<String, dynamic>> _filteredData = []; // Almacena los filtrados
// //   final String _tableName = 'inteligencia';

// //   // Controlador para el buscador
// //   final TextEditingController _searchController = TextEditingController();

// //   String? _nombreUsuario;
// //   bool _cargandoUsuario = true;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _cargarUsuarioLogueado();
// //     _cargarDatos();
// //   }

// //   // CORRECTO: Usar authDatabase para el nombre
// //   Future<void> _cargarUsuarioLogueado() async {
// //     final db = await DBManager.instance.authDatabase;
// //     try {
// //       final sesion = await db.query('sesion_activa', limit: 1);
// //       if (sesion.isNotEmpty) {
// //         final int usuarioId = sesion.first['usuario_id'] as int;
// //         final usuario = await db.query(
// //           'usuarios',
// //           where: 'id = ?',
// //           whereArgs: [usuarioId],
// //           limit: 1,
// //         );

// //         if (usuario.isNotEmpty && mounted) {
// //           setState(() {
// //             _nombreUsuario = usuario.first['nombres'] as String?;
// //             _cargandoUsuario = false;
// //           });
// //           return;
// //         }
// //       }
// //     } catch (e) {
// //       print("Error cargando usuario en inteligencia: $e");
// //     }
// //     if (mounted) setState(() => _cargandoUsuario = false);
// //   }

// //   // ---> Cargar datos y guardar en _allData
// //   Future<void> _cargarDatos() async {
// //     final db = await DBManager.instance.database;
// //     final data = await db.query(_tableName, orderBy: 'fecha ASC, hora ASC');
// //     setState(() {
// //       _allData = data;
// //       _filteredData = data; // Inicialmente mostramos todo
// //     });
// //   }

// //   // ---> FUNCIÓN DE FILTRADO <---
// //   void _filtrarDatos(String query) {
// //     setState(() {
// //       if (query.isEmpty) {
// //         _filteredData = _allData;
// //       } else {
// //         _filteredData = _allData.where((item) {
// //           final asunto = (item['asunto']?.toString() ?? '').toLowerCase();
// //           final medio = (item['medio']?.toString() ?? '').toLowerCase();
// //           final anotaciones = (item['anotaciones']?.toString() ?? '')
// //               .toLowerCase();
// //           final fecha = (item['fecha']?.toString() ?? '').toLowerCase();

// //           final searchLower = query.toLowerCase();

// //           return asunto.contains(searchLower) ||
// //               medio.contains(searchLower) ||
// //               anotaciones.contains(searchLower) ||
// //               fecha.contains(searchLower);
// //         }).toList();
// //       }
// //     });
// //   }

// //   Future<void> _exportarPDF() async {
// //     try {
// //       showDialog(
// //         context: context,
// //         barrierDismissible: false,
// //         builder: (context) => const PopScope(
// //           canPop: false,
// //           child: Center(child: CircularProgressIndicator()),
// //         ),
// //       );

// //       // Exportamos SOLO lo filtrado
// //       final data = _filteredData
// //           .map(
// //             (m) => {
// //               'fecha': m['fecha']?.toString() ?? '',
// //               'hora': m['hora']?.toString() ?? '',
// //               'asunto': m['asunto']?.toString() ?? '',
// //               'medio': m['medio']?.toString() ?? '',
// //               'anotaciones': m['anotaciones']?.toString() ?? '',
// //             },
// //           )
// //           .toList();

// //       final pdfBytes = await compute(_generarPdfBytesIsolate, data);

// //       final dir = await getTemporaryDirectory();
// //       final String fileName =
// //           'Reporte_Inteligencia_${DateTime.now().millisecondsSinceEpoch}.pdf';
// //       final file = File('${dir.path}/$fileName');

// //       final sink = file.openWrite();
// //       const chunkSize = 65536;
// //       for (int i = 0; i < pdfBytes.length; i += chunkSize) {
// //         final end = (i + chunkSize > pdfBytes.length)
// //             ? pdfBytes.length
// //             : i + chunkSize;
// //         sink.add(pdfBytes.sublist(i, end));
// //       }
// //       await sink.flush();
// //       await sink.close();

// //       if (mounted) Navigator.pop(context);
// //       await Share.shareXFiles([
// //         XFile(file.path),
// //       ], text: 'Reporte PDF Inteligencia');
// //     } catch (e) {
// //       if (mounted) {
// //         try {
// //           Navigator.pop(context);
// //         } catch (_) {}
// //       }
// //       debugPrint("Error PDF Inteligencia: $e");
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(content: Text("No se pudo generar el PDF: $e")),
// //         );
// //       }
// //     }
// //   }

// //   Future<void> _importarExcel() async {
// //     try {
// //       FilePickerResult? result = await FilePicker.platform.pickFiles(
// //         type: FileType.custom,
// //         allowedExtensions: ['xlsx'],
// //       );
// //       if (result != null) {
// //         var bytes = File(result.files.single.path!).readAsBytesSync();
// //         var excel = Excel.decodeBytes(bytes);
// //         final db = await DBManager.instance.database;

// //         for (var table in excel.tables.keys) {
// //           var rows = excel.tables[table]!.rows;
// //           for (int i = 1; i < rows.length; i++) {
// //             var row = rows[i];
// //             if (row.length >= 5) {
// //               await db.insert(_tableName, {
// //                 'fecha': row[0]?.value.toString() ?? '',
// //                 'hora': row[1]?.value.toString() ?? '',
// //                 'asunto': row[2]?.value.toString() ?? '',
// //                 'medio': row[3]?.value.toString() ?? '',
// //                 'anotaciones': row[4]?.value.toString() ?? '',
// //               });
// //             }
// //           }
// //         }
// //         _cargarDatos(); // Recargar todo
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           const SnackBar(content: Text("Datos importados con éxito")),
// //         );
// //       }
// //     } catch (e) {
// //       ScaffoldMessenger.of(
// //         context,
// //       ).showSnackBar(SnackBar(content: Text("Error al importar: $e")));
// //     }
// //   }

// //   Future<void> _exportarExcel() async {
// //     var excel = Excel.createExcel();
// //     Sheet sheet = excel['Inteligencia'];
// //     sheet.appendRow([
// //       TextCellValue('Fecha'),
// //       TextCellValue('Hora'),
// //       TextCellValue('Asunto'),
// //       TextCellValue('Medio'),
// //       TextCellValue('Anotaciones'),
// //     ]);
// //     // Exportamos SOLO lo filtrado
// //     for (var m in _filteredData) {
// //       sheet.appendRow([
// //         TextCellValue(m['fecha']),
// //         TextCellValue(m['hora']),
// //         TextCellValue(m['asunto']),
// //         TextCellValue(m['medio']),
// //         TextCellValue(m['anotaciones']),
// //       ]);
// //     }
// //     final directory = await getTemporaryDirectory();
// //     final filePath = '${directory.path}/Reporte_Inteligencia.xlsx';
// //     final bytes = excel.save();
// //     if (bytes != null) {
// //       await File(filePath).writeAsBytes(bytes);
// //       await Share.shareXFiles([XFile(filePath)], text: 'Excel Inteligencia');
// //     }
// //   }

// //   void _abrirFormulario({Map<String, dynamic>? item}) {
// //     final bool esEdicion = item != null;
// //     final fCon = TextEditingController(
// //       text: esEdicion
// //           ? item['fecha']
// //           : DateFormat('yyyy-MM-dd').format(DateTime.now()),
// //     );
// //     final hCon = TextEditingController(
// //       text: esEdicion
// //           ? item['hora']
// //           : DateFormat('HH:mm').format(DateTime.now()),
// //     );
// //     final aCon = TextEditingController(text: esEdicion ? item['asunto'] : '');
// //     final mCon = TextEditingController(text: esEdicion ? item['medio'] : '');
// //     final nCon = TextEditingController(
// //       text: esEdicion ? item['anotaciones'] : '',
// //     );

// //     showDialog(
// //       context: context,
// //       builder: (c) => AlertDialog(
// //         title: Text(
// //           esEdicion ? "Editar Inteligencia" : "Nuevo Registro Inteligencia",
// //         ),
// //         content: SizedBox(
// //           width: MediaQuery.of(context).size.width * 0.8,
// //           child: SingleChildScrollView(
// //             child: Column(
// //               mainAxisSize: MainAxisSize.min,
// //               children: [
// //                 Row(
// //                   children: [
// //                     Expanded(
// //                       child: TextField(
// //                         controller: fCon,
// //                         decoration: const InputDecoration(
// //                           labelText: "Fecha",
// //                           border: OutlineInputBorder(),
// //                         ),
// //                       ),
// //                     ),
// //                     const SizedBox(width: 10),
// //                     Expanded(
// //                       child: TextField(
// //                         controller: hCon,
// //                         decoration: const InputDecoration(
// //                           labelText: "Hora",
// //                           border: OutlineInputBorder(),
// //                         ),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //                 const SizedBox(height: 15),
// //                 TextField(
// //                   controller: aCon,
// //                   decoration: const InputDecoration(
// //                     labelText: "Asunto",
// //                     border: OutlineInputBorder(),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 15),
// //                 TextField(
// //                   controller: mCon,
// //                   decoration: const InputDecoration(
// //                     labelText: "Medio (Ej. Humano, Técnico)",
// //                     border: OutlineInputBorder(),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 15),
// //                 TextField(
// //                   controller: nCon,
// //                   maxLines: 5,
// //                   decoration: const InputDecoration(
// //                     labelText: "Anotaciones",
// //                     border: OutlineInputBorder(),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(c),
// //             child: const Text("Cancelar"),
// //           ),
// //           ElevatedButton(
// //             onPressed: () async {
// //               final db = await DBManager.instance.database;
// //               final map = {
// //                 'fecha': fCon.text,
// //                 'hora': hCon.text,
// //                 'asunto': aCon.text,
// //                 'medio': mCon.text,
// //                 'anotaciones': nCon.text,
// //               };
// //               if (esEdicion) {
// //                 await db.update(
// //                   _tableName,
// //                   map,
// //                   where: 'id = ?',
// //                   whereArgs: [item['id']],
// //                 );
// //               } else {
// //                 await db.insert(_tableName, map);
// //               }
// //               Navigator.pop(c);
// //               _cargarDatos(); // Recargar datos y resetear filtro si es necesario, o mantener filtro
// //             },
// //             child: const Text("Guardar"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: const Text(
// //           "Libro de Inteligencia",
// //           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
// //         ),
// //         backgroundColor: const Color(0xFF1A237E),
// //         iconTheme: const IconThemeData(color: Colors.white),
// //         actions: [
// //           Padding(
// //             padding: const EdgeInsets.only(right: 16.0),
// //             child: Row(
// //               children: [
// //                 Container(
// //                   width: 8,
// //                   height: 8,
// //                   decoration: BoxDecoration(
// //                     color: Colors.greenAccent,
// //                     shape: BoxShape.circle,
// //                     boxShadow: [
// //                       BoxShadow(
// //                         color: Colors.greenAccent.withOpacity(0.6),
// //                         blurRadius: 4,
// //                         spreadRadius: 1,
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 const SizedBox(width: 8),
// //                 CircleAvatar(
// //                   radius: 14,
// //                   backgroundColor: Colors.white.withOpacity(0.2),
// //                   child: Text(
// //                     _nombreUsuario != null && _nombreUsuario!.isNotEmpty
// //                         ? _nombreUsuario![0].toUpperCase()
// //                         : "?",
// //                     style: const TextStyle(
// //                       color: Colors.white,
// //                       fontWeight: FontWeight.bold,
// //                       fontSize: 12,
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(width: 8),
// //                 Text(
// //                   _nombreUsuario ?? "Usuario",
// //                   style: const TextStyle(
// //                     color: Colors.white70,
// //                     fontSize: 14,
// //                     fontWeight: FontWeight.w500,
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //       body: Padding(
// //         padding: const EdgeInsets.all(20),
// //         child: Column(
// //           children: [
// //             // --- SECCIÓN DE BOTONES Y BÚSQUEDA ---
// //             Column(
// //               crossAxisAlignment: CrossAxisAlignment.stretch,
// //               children: [
// //                 // Barra de botones
// //                 SingleChildScrollView(
// //                   scrollDirection: Axis.horizontal,
// //                   child: Row(
// //                     children: [
// //                       _btn(
// //                         "PDF",
// //                         Colors.purple,
// //                         Icons.picture_as_pdf,
// //                         _exportarPDF,
// //                       ),
// //                       const SizedBox(width: 10),
// //                       _btn(
// //                         "Exportar",
// //                         Colors.green,
// //                         Icons.file_upload,
// //                         _exportarExcel,
// //                       ),
// //                       const SizedBox(width: 10),
// //                       _btn(
// //                         "Importar",
// //                         Colors.blueGrey,
// //                         Icons.file_download,
// //                         _importarExcel,
// //                       ),
// //                       const SizedBox(width: 10),
// //                       _btn(
// //                         "Nuevo",
// //                         Colors.indigo,
// //                         Icons.add,
// //                         () => _abrirFormulario(),
// //                       ),
// //                     ],
// //                   ),
// //                 ),
// //                 const SizedBox(height: 15),
// //                 // Campo de Búsqueda
// //                 TextField(
// //                   controller: _searchController,
// //                   onChanged: _filtrarDatos,
// //                   decoration: InputDecoration(
// //                     hintText: "Buscar por asunto, medio, fecha...",
// //                     prefixIcon: const Icon(Icons.search),
// //                     border: OutlineInputBorder(
// //                       borderRadius: BorderRadius.circular(10),
// //                     ),
// //                     filled: true,
// //                     fillColor: Colors.grey[200],
// //                   ),
// //                 ),
// //               ],
// //             ),

// //             const SizedBox(height: 15),

// //             // --- TABLA DE DATOS ---
// //             Expanded(
// //               child: _filteredData.isEmpty
// //                   ? const Center(child: Text("No se encontraron registros"))
// //                   : SingleChildScrollView(
// //                       scrollDirection: Axis.vertical,
// //                       child: Table(
// //                         border: TableBorder.all(color: Colors.grey[300]!),
// //                         columnWidths: const {
// //                           0: FlexColumnWidth(1.2),
// //                           1: FlexColumnWidth(0.8),
// //                           2: FlexColumnWidth(1.5),
// //                           3: FlexColumnWidth(1.5),
// //                           4: FlexColumnWidth(4),
// //                           5: FlexColumnWidth(1.5),
// //                         },
// //                         children: [
// //                           _header(),
// //                           ..._filteredData.map((m) => _row(m)),
// //                         ],
// //                       ),
// //                     ),
// //             ),
// //           ],
// //         ),
// //       ),
// //     );
// //   }

// //   TableRow _header() {
// //     return TableRow(
// //       decoration: const BoxDecoration(color: Color(0xFF2196F3)),
// //       children: ['Fecha', 'Hora', 'Asunto', 'Medio', 'Anotación', 'Acciones']
// //           .map(
// //             (t) => Container(
// //               padding: const EdgeInsets.all(10),
// //               child: Text(
// //                 t,
// //                 style: const TextStyle(
// //                   color: Colors.white,
// //                   fontWeight: FontWeight.bold,
// //                   fontSize: 12,
// //                 ),
// //               ),
// //             ),
// //           )
// //           .toList(),
// //     );
// //   }

// //   TableRow _row(Map<String, dynamic> m) => TableRow(
// //     children: [
// //       _c(m['fecha']),
// //       _c(m['hora']),
// //       _c(m['asunto']),
// //       _c(m['medio']),
// //       _c(m['anotaciones']),
// //       Row(
// //         children: [
// //           IconButton(
// //             icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
// //             onPressed: () => _abrirFormulario(item: m),
// //           ),
// //           IconButton(
// //             icon: const Icon(Icons.delete, color: Colors.red, size: 18),
// //             onPressed: () async {
// //               final db = await DBManager.instance.database;
// //               await db.delete(
// //                 _tableName,
// //                 where: 'id = ?',
// //                 whereArgs: [m['id']],
// //               );
// //               _cargarDatos();
// //             },
// //           ),
// //         ],
// //       ),
// //     ],
// //   );

// //   Widget _c(String t) => Padding(
// //     padding: const EdgeInsets.all(10),
// //     child: Text(t, style: const TextStyle(fontSize: 11)),
// //   );

// //   Widget _btn(String t, Color c, IconData i, VoidCallback o) =>
// //       ElevatedButton.icon(
// //         onPressed: o,
// //         icon: Icon(i, size: 16, color: Colors.white),
// //         label: Text(t, style: const TextStyle(color: Colors.white)),
// //         style: ElevatedButton.styleFrom(backgroundColor: c),
// //       );
// // }
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:intl/intl.dart';
// import 'package:excel/excel.dart' hide Border;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:image_picker/image_picker.dart';
// import '../../BD/db_manager.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;

// // ─── FUNCIÓN TOP-LEVEL para generar PDF en isolate separado ───
// Future<List<int>> _generarPdfBytesIsolate(
//   List<Map<String, dynamic>> data,
// ) async {
//   final pdf = pw.Document();

//   pdf.addPage(
//     pw.MultiPage(
//       pageFormat: PdfPageFormat.letter.copyWith(
//         marginBottom: 1.5 * PdfPageFormat.cm,
//         marginTop: 1.5 * PdfPageFormat.cm,
//         marginLeft: 1 * PdfPageFormat.cm,
//         marginRight: 1 * PdfPageFormat.cm,
//       ),
//       header: (context) => pw.Container(
//         alignment: pw.Alignment.centerRight,
//         margin: const pw.EdgeInsets.only(bottom: 20),
//         child: pw.Text(
//           "INTELIGENCIA - CALIPSO",
//           style: pw.TextStyle(color: PdfColors.grey700, fontSize: 12),
//         ),
//       ),
//       footer: (context) => pw.Container(
//         alignment: pw.Alignment.centerRight,
//         margin: const pw.EdgeInsets.only(top: 10),
//         child: pw.Text(
//           'Página ${context.pageNumber} de ${context.pagesCount}',
//           style: const pw.TextStyle(fontSize: 10),
//         ),
//       ),
//       build: (context) => [
//         pw.Header(
//           level: 0,
//           child: pw.Text(
//             "REPORTE LIBRO DE INTELIGENCIA",
//             style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
//           ),
//         ),
//         pw.SizedBox(height: 10),
//         pw.TableHelper.fromTextArray(
//           headers: ['Fecha', 'Hora', 'Asunto', 'Medio', 'Anotaciones', 'Img'],
//           data: data
//               .map(
//                 (m) => [
//                   m['fecha']?.toString() ?? '',
//                   m['hora']?.toString() ?? '',
//                   m['asunto']?.toString() ?? '',
//                   m['medio']?.toString() ?? '',
//                   m['anotaciones']?.toString() ?? '',
//                   (m['imagen'] != null && m['imagen'].toString().isNotEmpty)
//                       ? 'Sí'
//                       : 'No',
//                 ],
//               )
//               .toList(),
//           headerStyle: pw.TextStyle(
//             color: PdfColors.white,
//             fontWeight: pw.FontWeight.bold,
//             fontSize: 10,
//           ),
//           headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
//           cellStyle: const pw.TextStyle(fontSize: 9),
//           cellAlignment: pw.Alignment.topLeft,
//           columnWidths: {
//             0: const pw.FixedColumnWidth(70),
//             1: const pw.FixedColumnWidth(45),
//             2: const pw.FixedColumnWidth(90),
//             3: const pw.FixedColumnWidth(70),
//             4: const pw.FlexColumnWidth(),
//             5: const pw.FixedColumnWidth(30),
//           },
//         ),
//       ],
//     ),
//   );

//   return await pdf.save();
// }

// class InteligenciaScreen extends StatefulWidget {
//   const InteligenciaScreen({super.key});
//   @override
//   State<InteligenciaScreen> createState() => _InteligenciaScreenState();
// }

// class _InteligenciaScreenState extends State<InteligenciaScreen> {
//   List<Map<String, dynamic>> _allData = [];
//   List<Map<String, dynamic>> _filteredData = [];
//   final String _tableName = 'inteligencia';

//   final TextEditingController _searchController = TextEditingController();
//   final ImagePicker _picker = ImagePicker();

//   String? _nombreUsuario;
//   bool _cargandoUsuario = true;

//   @override
//   void initState() {
//     super.initState();
//     _cargarUsuarioLogueado();
//     _cargarDatos();
//   }

//   Future<void> _cargarUsuarioLogueado() async {
//     final db = await DBManager.instance.authDatabase;
//     try {
//       final sesion = await db.query('sesion_activa', limit: 1);
//       if (sesion.isNotEmpty) {
//         final int usuarioId = sesion.first['usuario_id'] as int;
//         final usuario = await db.query(
//           'usuarios',
//           where: 'id = ?',
//           whereArgs: [usuarioId],
//           limit: 1,
//         );

//         if (usuario.isNotEmpty && mounted) {
//           setState(() {
//             _nombreUsuario = usuario.first['nombres'] as String?;
//             _cargandoUsuario = false;
//           });
//           return;
//         }
//       }
//     } catch (e) {
//       print("Error cargando usuario en inteligencia: $e");
//     }
//     if (mounted) setState(() => _cargandoUsuario = false);
//   }

//   Future<void> _cargarDatos() async {
//     final db = await DBManager.instance.database;
//     final data = await db.query(_tableName, orderBy: 'fecha ASC, hora ASC');
//     setState(() {
//       _allData = data;
//       _filteredData = data;
//     });
//   }

//   void _filtrarDatos(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredData = _allData;
//       } else {
//         _filteredData = _allData.where((item) {
//           final asunto = (item['asunto']?.toString() ?? '').toLowerCase();
//           final medio = (item['medio']?.toString() ?? '').toLowerCase();
//           final anotaciones = (item['anotaciones']?.toString() ?? '')
//               .toLowerCase();
//           final fecha = (item['fecha']?.toString() ?? '').toLowerCase();
//           final searchLower = query.toLowerCase();

//           return asunto.contains(searchLower) ||
//               medio.contains(searchLower) ||
//               anotaciones.contains(searchLower) ||
//               fecha.contains(searchLower);
//         }).toList();
//       }
//     });
//   }

//   Future<void> _exportarPDF() async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const PopScope(
//           canPop: false,
//           child: Center(child: CircularProgressIndicator()),
//         ),
//       );

//       final data = _filteredData
//           .map(
//             (m) => {
//               'fecha': m['fecha']?.toString() ?? '',
//               'hora': m['hora']?.toString() ?? '',
//               'asunto': m['asunto']?.toString() ?? '',
//               'medio': m['medio']?.toString() ?? '',
//               'anotaciones': m['anotaciones']?.toString() ?? '',
//               'imagen': m['imagen'],
//             },
//           )
//           .toList();

//       final pdfBytes = await compute(_generarPdfBytesIsolate, data);

//       final dir = await getTemporaryDirectory();
//       final String fileName =
//           'Reporte_Inteligencia_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final file = File('${dir.path}/$fileName');

//       final sink = file.openWrite();
//       const chunkSize = 65536;
//       for (int i = 0; i < pdfBytes.length; i += chunkSize) {
//         final end = (i + chunkSize > pdfBytes.length)
//             ? pdfBytes.length
//             : i + chunkSize;
//         sink.add(pdfBytes.sublist(i, end));
//       }
//       await sink.flush();
//       await sink.close();

//       if (mounted) Navigator.pop(context);
//       await Share.shareXFiles([
//         XFile(file.path),
//       ], text: 'Reporte PDF Inteligencia');
//     } catch (e) {
//       if (mounted) {
//         try {
//           Navigator.pop(context);
//         } catch (_) {}
//       }
//       debugPrint("Error PDF Inteligencia: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("No se pudo generar el PDF: $e")),
//         );
//       }
//     }
//   }

//   Future<void> _importarExcel() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['xlsx'],
//       );
//       if (result != null) {
//         var bytes = File(result.files.single.path!).readAsBytesSync();
//         var excel = Excel.decodeBytes(bytes);
//         final db = await DBManager.instance.database;

//         for (var table in excel.tables.keys) {
//           var rows = excel.tables[table]!.rows;
//           for (int i = 1; i < rows.length; i++) {
//             var row = rows[i];
//             if (row.length >= 5) {
//               await db.insert(_tableName, {
//                 'fecha': row[0]?.value.toString() ?? '',
//                 'hora': row[1]?.value.toString() ?? '',
//                 'asunto': row[2]?.value.toString() ?? '',
//                 'medio': row[3]?.value.toString() ?? '',
//                 'anotaciones': row[4]?.value.toString() ?? '',
//                 'imagen': '',
//               });
//             }
//           }
//         }
//         _cargarDatos();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Datos importados con éxito")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error al importar: $e")));
//     }
//   }

//   Future<void> _exportarExcel() async {
//     var excel = Excel.createExcel();
//     Sheet sheet = excel['Inteligencia'];
//     sheet.appendRow([
//       TextCellValue('Fecha'),
//       TextCellValue('Hora'),
//       TextCellValue('Asunto'),
//       TextCellValue('Medio'),
//       TextCellValue('Anotaciones'),
//       TextCellValue('Imagen'),
//     ]);
//     for (var m in _filteredData) {
//       sheet.appendRow([
//         TextCellValue(m['fecha']),
//         TextCellValue(m['hora']),
//         TextCellValue(m['asunto']),
//         TextCellValue(m['medio']),
//         TextCellValue(m['anotaciones']),
//         TextCellValue(m['imagen']?.toString().isNotEmpty == true ? 'Sí' : 'No'),
//       ]);
//     }
//     final directory = await getTemporaryDirectory();
//     final filePath = '${directory.path}/Reporte_Inteligencia.xlsx';
//     final bytes = excel.save();
//     if (bytes != null) {
//       await File(filePath).writeAsBytes(bytes);
//       await Share.shareXFiles([XFile(filePath)], text: 'Excel Inteligencia');
//     }
//   }

//   void _abrirFormulario({Map<String, dynamic>? item}) {
//     final bool esEdicion = item != null;

//     final fCon = TextEditingController(
//       text: esEdicion
//           ? item['fecha']
//           : DateFormat('yyyy-MM-dd').format(DateTime.now()),
//     );
//     final hCon = TextEditingController(
//       text: esEdicion
//           ? item['hora']
//           : DateFormat('HH:mm').format(DateTime.now()),
//     );
//     final aCon = TextEditingController(text: esEdicion ? item['asunto'] : '');
//     final mCon = TextEditingController(text: esEdicion ? item['medio'] : '');
//     final nCon = TextEditingController(
//       text: esEdicion ? item['anotaciones'] : '',
//     );

//     String? _rutaImagenActual = esEdicion ? item['imagen'] : null;

//     showDialog(
//       context: context,
//       builder: (c) => StatefulBuilder(
//         builder: (context, setDialogState) {
//           return AlertDialog(
//             title: Text(
//               esEdicion ? "Editar Inteligencia" : "Nuevo Registro Inteligencia",
//             ),
//             content: SizedBox(
//               width: MediaQuery.of(context).size.width * 0.8,
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: fCon,
//                             decoration: const InputDecoration(
//                               labelText: "Fecha",
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: TextField(
//                             controller: hCon,
//                             decoration: const InputDecoration(
//                               labelText: "Hora",
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: aCon,
//                       decoration: const InputDecoration(
//                         labelText: "Asunto",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: mCon,
//                       decoration: const InputDecoration(
//                         labelText: "Medio",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: nCon,
//                       maxLines: 5,
//                       decoration: const InputDecoration(
//                         labelText: "Anotaciones",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     const Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(
//                         "Evidencia Fotográfica:",
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Row(
//                       children: [
//                         Container(
//                           width: 80,
//                           height: 80,
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey),
//                             borderRadius: BorderRadius.circular(8),
//                             color: Colors.grey[200],
//                           ),
//                           child: _rutaImagenActual != null
//                               ? ClipRRect(
//                                   borderRadius: BorderRadius.circular(7),
//                                   child: Image.file(
//                                     File(_rutaImagenActual!),
//                                     fit: BoxFit.cover,
//                                   ),
//                                 )
//                               : const Icon(
//                                   Icons.image,
//                                   size: 40,
//                                   color: Colors.grey,
//                                 ),
//                         ),
//                         const SizedBox(width: 10),
//                         Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             // MODIFICADO: Botón que abre opciones
//                             ElevatedButton.icon(
//                               onPressed: () {
//                                 showModalBottomSheet(
//                                   context: context,
//                                   builder: (BuildContext bc) {
//                                     return SafeArea(
//                                       child: Wrap(
//                                         children: <Widget>[
//                                           ListTile(
//                                             leading: const Icon(
//                                               Icons.camera_alt,
//                                             ),
//                                             title: const Text('Cámara'),
//                                             onTap: () async {
//                                               Navigator.pop(bc);
//                                               final XFile? photo = await _picker
//                                                   .pickImage(
//                                                     source: ImageSource.camera,
//                                                     imageQuality: 50,
//                                                   );
//                                               if (photo != null) {
//                                                 setDialogState(() {
//                                                   _rutaImagenActual =
//                                                       photo.path;
//                                                 });
//                                               }
//                                             },
//                                           ),
//                                           ListTile(
//                                             leading: const Icon(
//                                               Icons.photo_library,
//                                             ),
//                                             title: const Text('Galería'),
//                                             onTap: () async {
//                                               Navigator.pop(bc);
//                                               final XFile? photo = await _picker
//                                                   .pickImage(
//                                                     source: ImageSource.gallery,
//                                                     imageQuality: 50,
//                                                   );
//                                               if (photo != null) {
//                                                 setDialogState(() {
//                                                   _rutaImagenActual =
//                                                       photo.path;
//                                                 });
//                                               }
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                 );
//                               },
//                               icon: const Icon(Icons.add_a_photo, size: 18),
//                               label: const Text("Adjuntar"),
//                               style: ElevatedButton.styleFrom(
//                                 foregroundColor: Colors.white,
//                                 backgroundColor: Colors.indigo,
//                               ),
//                             ),
//                             if (_rutaImagenActual != null)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 5.0),
//                                 child: TextButton(
//                                   onPressed: () {
//                                     setDialogState(() {
//                                       _rutaImagenActual = null;
//                                     });
//                                   },
//                                   child: const Text(
//                                     "Eliminar",
//                                     style: TextStyle(
//                                       color: Colors.red,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(c),
//                 child: const Text("Cancelar"),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   final db = await DBManager.instance.database;
//                   final map = {
//                     'fecha': fCon.text,
//                     'hora': hCon.text,
//                     'asunto': aCon.text,
//                     'medio': mCon.text,
//                     'anotaciones': nCon.text,
//                     'imagen': _rutaImagenActual,
//                   };
//                   if (esEdicion) {
//                     await db.update(
//                       _tableName,
//                       map,
//                       where: 'id = ?',
//                       whereArgs: [item['id']],
//                     );
//                   } else {
//                     await db.insert(_tableName, map);
//                   }
//                   Navigator.pop(c);
//                   _cargarDatos();
//                 },
//                 child: const Text("Guardar"),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // --- FUNCIÓN PARA VER EL REGISTRO COMPLETO ---
//   void _verRegistro(Map<String, dynamic> item) {
//     final ThemeData theme = Theme.of(context); // Obtener el tema actual
//     final bool isDark = theme.brightness == Brightness.dark;

//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         // Usamos color de superficie del tema para el fondo
//         backgroundColor: theme.colorScheme.surface,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Container(
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.9,
//             maxHeight: MediaQuery.of(context).size.height * 0.85,
//           ),
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "Detalle del Registro",
//                       style: theme.textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: theme.colorScheme.onSurface,
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.pop(context),
//                       color: theme.colorScheme.onSurfaceVariant,
//                     ),
//                   ],
//                 ),
//                 Divider(color: theme.dividerColor),
//                 const SizedBox(height: 15),

//                 // Información de texto
//                 _detalleFila("Fecha:", item['fecha']),
//                 _detalleFila("Hora:", item['hora']),
//                 _detalleFila("Asunto:", item['asunto']),
//                 _detalleFila("Medio:", item['medio']),
//                 const SizedBox(height: 15),

//                 Text(
//                   "Anotaciones:",
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.onSurface,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   item['anotaciones']?.toString() ?? 'Sin anotaciones',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: theme.colorScheme.onSurface,
//                     height: 1.4,
//                   ),
//                 ),
//                 const SizedBox(height: 25),

//                 // --- VISUALIZACIÓN DE IMAGEN (MÁS GRANDE) ---
//                 if (item['imagen'] != null &&
//                     item['imagen'].toString().isNotEmpty)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Evidencia Fotográfica:",
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: theme.colorScheme.onSurface,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Center(
//                         child: InkWell(
//                           onTap: () {
//                             // Zoom al hacer tap en la imagen
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => Scaffold(
//                                   backgroundColor: Colors
//                                       .black, // Fondo negro siempre para zoom
//                                   appBar: AppBar(
//                                     backgroundColor: Colors.transparent,
//                                     iconTheme: const IconThemeData(
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                   body: Center(
//                                     child: InteractiveViewer(
//                                       child: Image.file(
//                                         File(item['imagen'].toString()),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                           child: Container(
//                             height: 300,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               // Fondo que cambia según el tema
//                               color: isDark
//                                   ? const Color(0xFF2C2C2C)
//                                   : Colors.grey[200],
//                               border: Border.all(
//                                 color: isDark ? Colors.grey[700]! : Colors.grey,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(12),
//                               child: Image.file(
//                                 File(item['imagen'].toString()),
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       Center(
//                         child: Text(
//                           "Toca la imagen para ampliar",
//                           style: TextStyle(
//                             color: theme.colorScheme.onSurfaceVariant,
//                             fontSize: 12,
//                             fontStyle: FontStyle.italic,
//                           ),
//                         ),
//                       ),
//                     ],
//                   )
//                 else
//                   Center(
//                     child: Padding(
//                       padding: const EdgeInsets.all(30.0),
//                       child: Column(
//                         children: [
//                           Icon(
//                             Icons.image_not_supported,
//                             size: 60,
//                             color: theme.colorScheme.onSurfaceVariant,
//                           ),
//                           const SizedBox(height: 10),
//                           Text(
//                             "No hay evidencia adjunta.",
//                             style: TextStyle(
//                               color: theme.colorScheme.onSurfaceVariant,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // Helper para mostrar las filas de texto
//   Widget _detalleFila(String label, String? value) {
//     final ThemeData theme = Theme.of(context); // Obtener el tema actual

//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 90,
//             child: Text(
//               label,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.onSurface,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value?.toString() ?? '',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurface,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Libro de Inteligencia",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(0xFF1A237E),
//         iconTheme: const IconThemeData(color: Colors.white),
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
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.greenAccent.withOpacity(0.6),
//                         blurRadius: 4,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 CircleAvatar(
//                   radius: 14,
//                   backgroundColor: Colors.white.withOpacity(0.2),
//                   child: Text(
//                     _nombreUsuario != null && _nombreUsuario!.isNotEmpty
//                         ? _nombreUsuario![0].toUpperCase()
//                         : "?",
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   _nombreUsuario ?? "Usuario",
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       _btn(
//                         "PDF",
//                         Colors.purple,
//                         Icons.picture_as_pdf,
//                         _exportarPDF,
//                       ),
//                       const SizedBox(width: 10),
//                       _btn(
//                         "Exportar",
//                         Colors.green,
//                         Icons.file_upload,
//                         _exportarExcel,
//                       ),
//                       const SizedBox(width: 10),
//                       _btn(
//                         "Importar",
//                         Colors.blueGrey,
//                         Icons.file_download,
//                         _importarExcel,
//                       ),
//                       const SizedBox(width: 10),
//                       _btn(
//                         "Nuevo",
//                         Colors.indigo,
//                         Icons.add,
//                         () => _abrirFormulario(),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 TextField(
//                   controller: _searchController,
//                   onChanged: _filtrarDatos,
//                   decoration: InputDecoration(
//                     hintText: "Buscar por asunto, medio, fecha...",
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 15),
//             Expanded(
//               child: _filteredData.isEmpty
//                   ? const Center(child: Text("No se encontraron registros"))
//                   : SingleChildScrollView(
//                       scrollDirection: Axis.vertical,
//                       child: Table(
//                         border: TableBorder.all(color: Colors.grey[300]!),
//                         // Ajustado para ocultar columna Img
//                         columnWidths: const {
//                           0: FlexColumnWidth(1.2),
//                           1: FlexColumnWidth(0.8),
//                           2: FlexColumnWidth(1.5),
//                           3: FlexColumnWidth(1.5),
//                           4: FlexColumnWidth(4.5), // Anotaciones más ancho
//                           5: FlexColumnWidth(1.5), // Acciones
//                         },
//                         children: [
//                           _header(),
//                           ..._filteredData.map((m) => _row(m)),
//                         ],
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   TableRow _header() {
//     return TableRow(
//       decoration: const BoxDecoration(color: Color(0xFF2196F3)),
//       children:
//           [
//                 'Fecha',
//                 'Hora',
//                 'Asunto',
//                 'Medio',
//                 'Anotación',
//                 'Acciones', // Ya no incluye 'Img'
//               ]
//               .map(
//                 (t) => Container(
//                   padding: const EdgeInsets.all(10),
//                   child: Text(
//                     t,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               )
//               .toList(),
//     );
//   }

//   TableRow _row(Map<String, dynamic> m) => TableRow(
//     children: [
//       _c(m['fecha']),
//       _c(m['hora']),
//       _c(m['asunto']),
//       _c(m['medio']),
//       _c(m['anotaciones']),
//       // Celda de Acciones: Editar, Ver, Eliminar
//       Padding(
//         padding: const EdgeInsets.all(5.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             IconButton(
//               icon: const Icon(Icons.visibility, color: Colors.blue, size: 18),
//               onPressed: () => _verRegistro(m),
//               tooltip: 'Ver Registro',
//             ),
//             IconButton(
//               icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
//               onPressed: () => _abrirFormulario(item: m),
//               tooltip: 'Editar',
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red, size: 18),
//               onPressed: () async {
//                 final confirm = await _confirmarEliminacion();
//                 if (confirm == true) {
//                   final db = await DBManager.instance.database;
//                   await db.delete(
//                     _tableName,
//                     where: 'id = ?',
//                     whereArgs: [m['id']],
//                   );
//                   _cargarDatos();
//                 }
//               },
//               tooltip: 'Eliminar',
//             ),
//           ],
//         ),
//       ),
//     ],
//   );

//   Future<bool?> _confirmarEliminacion() {
//     return showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Eliminar Registro"),
//         content: const Text(
//           "¿Está seguro de que desea eliminar este registro?",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Cancelar"),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _c(String t) => Padding(
//     padding: const EdgeInsets.all(10),
//     child: Text(t, style: const TextStyle(fontSize: 11)),
//   );

//   Widget _btn(String t, Color c, IconData i, VoidCallback o) =>
//       ElevatedButton.icon(
//         onPressed: o,
//         icon: Icon(i, size: 16, color: Colors.white),
//         label: Text(t, style: const TextStyle(color: Colors.white)),
//         style: ElevatedButton.styleFrom(backgroundColor: c),
//       );
// }

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:intl/intl.dart';
// import 'package:excel/excel.dart' hide Border;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:open_file/open_file.dart';
// import '../../BD/db_manager.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;

// // ─── FUNCIÓN TOP-LEVEL para generar PDF en isolate separado ───
// Future<List<int>> _generarPdfBytesIsolate(
//   List<Map<String, dynamic>> data,
// ) async {
//   final pdf = pw.Document();

//   pdf.addPage(
//     pw.MultiPage(
//       pageFormat: PdfPageFormat.letter.copyWith(
//         marginBottom: 1.5 * PdfPageFormat.cm,
//         marginTop: 1.5 * PdfPageFormat.cm,
//         marginLeft: 1 * PdfPageFormat.cm,
//         marginRight: 1 * PdfPageFormat.cm,
//       ),
//       header: (context) => pw.Container(
//         alignment: pw.Alignment.centerRight,
//         margin: const pw.EdgeInsets.only(bottom: 20),
//         child: pw.Text(
//           "INTELIGENCIA - CALIPSO",
//           style: pw.TextStyle(color: PdfColors.grey700, fontSize: 12),
//         ),
//       ),
//       footer: (context) => pw.Container(
//         alignment: pw.Alignment.centerRight,
//         margin: const pw.EdgeInsets.only(top: 10),
//         child: pw.Text(
//           'Página ${context.pageNumber} de ${context.pagesCount}',
//           style: const pw.TextStyle(fontSize: 10),
//         ),
//       ),
//       build: (context) => [
//         pw.Header(
//           level: 0,
//           child: pw.Text(
//             "REPORTE LIBRO DE INTELIGENCIA",
//             style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
//           ),
//         ),
//         pw.SizedBox(height: 10),
//         pw.TableHelper.fromTextArray(
//           headers: [
//             'Fecha',
//             'Hora',
//             'Asunto',
//             'Medio',
//             'Anotaciones',
//             'Img',
//             'Adj',
//           ],
//           data: data
//               .map(
//                 (m) => [
//                   m['fecha']?.toString() ?? '',
//                   m['hora']?.toString() ?? '',
//                   m['asunto']?.toString() ?? '',
//                   m['medio']?.toString() ?? '',
//                   m['anotaciones']?.toString() ?? '',
//                   (m['imagen'] != null && m['imagen'].toString().isNotEmpty)
//                       ? 'Sí'
//                       : 'No',
//                   (m['adjuntos'] != null && m['adjuntos'].toString().isNotEmpty)
//                       ? 'Sí'
//                       : 'No',
//                 ],
//               )
//               .toList(),
//           headerStyle: pw.TextStyle(
//             color: PdfColors.white,
//             fontWeight: pw.FontWeight.bold,
//             fontSize: 10,
//           ),
//           headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo900),
//           cellStyle: const pw.TextStyle(fontSize: 9),
//           cellAlignment: pw.Alignment.topLeft,
//           columnWidths: {
//             0: const pw.FixedColumnWidth(70),
//             1: const pw.FixedColumnWidth(45),
//             2: const pw.FixedColumnWidth(90),
//             3: const pw.FixedColumnWidth(70),
//             4: const pw.FlexColumnWidth(),
//             5: const pw.FixedColumnWidth(30),
//             6: const pw.FixedColumnWidth(30),
//           },
//         ),
//       ],
//     ),
//   );

//   return await pdf.save();
// }

// class InteligenciaScreen extends StatefulWidget {
//   const InteligenciaScreen({super.key});
//   @override
//   State<InteligenciaScreen> createState() => _InteligenciaScreenState();
// }

// class _InteligenciaScreenState extends State<InteligenciaScreen> {
//   List<Map<String, dynamic>> _allData = [];
//   List<Map<String, dynamic>> _filteredData = [];
//   final String _tableName = 'inteligencia';

//   final TextEditingController _searchController = TextEditingController();
//   final ImagePicker _picker = ImagePicker();

//   String? _nombreUsuario;
//   bool _cargandoUsuario = true;

//   @override
//   void initState() {
//     super.initState();
//     _cargarUsuarioLogueado();
//     _cargarDatos();
//   }

//   Future<void> _cargarUsuarioLogueado() async {
//     final db = await DBManager.instance.authDatabase;
//     try {
//       final sesion = await db.query('sesion_activa', limit: 1);
//       if (sesion.isNotEmpty) {
//         final int usuarioId = sesion.first['usuario_id'] as int;
//         final usuario = await db.query(
//           'usuarios',
//           where: 'id = ?',
//           whereArgs: [usuarioId],
//           limit: 1,
//         );

//         if (usuario.isNotEmpty && mounted) {
//           setState(() {
//             _nombreUsuario = usuario.first['nombres'] as String?;
//             _cargandoUsuario = false;
//           });
//           return;
//         }
//       }
//     } catch (e) {
//       print("Error cargando usuario en inteligencia: $e");
//     }
//     if (mounted) setState(() => _cargandoUsuario = false);
//   }

//   Future<void> _cargarDatos() async {
//     final db = await DBManager.instance.database;
//     final data = await db.query(_tableName, orderBy: 'fecha ASC, hora ASC');
//     setState(() {
//       _allData = data;
//       _filteredData = data;
//     });
//   }

//   void _filtrarDatos(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredData = _allData;
//       } else {
//         _filteredData = _allData.where((item) {
//           final asunto = (item['asunto']?.toString() ?? '').toLowerCase();
//           final medio = (item['medio']?.toString() ?? '').toLowerCase();
//           final anotaciones = (item['anotaciones']?.toString() ?? '')
//               .toLowerCase();
//           final fecha = (item['fecha']?.toString() ?? '').toLowerCase();
//           final searchLower = query.toLowerCase();

//           return asunto.contains(searchLower) ||
//               medio.contains(searchLower) ||
//               anotaciones.contains(searchLower) ||
//               fecha.contains(searchLower);
//         }).toList();
//       }
//     });
//   }

//   Future<void> _exportarPDF() async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const PopScope(
//           canPop: false,
//           child: Center(child: CircularProgressIndicator()),
//         ),
//       );

//       final data = _filteredData
//           .map(
//             (m) => {
//               'fecha': m['fecha']?.toString() ?? '',
//               'hora': m['hora']?.toString() ?? '',
//               'asunto': m['asunto']?.toString() ?? '',
//               'medio': m['medio']?.toString() ?? '',
//               'anotaciones': m['anotaciones']?.toString() ?? '',
//               'imagen': m['imagen'],
//               'adjuntos': m['adjuntos'],
//             },
//           )
//           .toList();

//       final pdfBytes = await compute(_generarPdfBytesIsolate, data);

//       final dir = await getTemporaryDirectory();
//       final String fileName =
//           'Reporte_Inteligencia_${DateTime.now().millisecondsSinceEpoch}.pdf';
//       final file = File('${dir.path}/$fileName');

//       final sink = file.openWrite();
//       const chunkSize = 65536;
//       for (int i = 0; i < pdfBytes.length; i += chunkSize) {
//         final end = (i + chunkSize > pdfBytes.length)
//             ? pdfBytes.length
//             : i + chunkSize;
//         sink.add(pdfBytes.sublist(i, end));
//       }
//       await sink.flush();
//       await sink.close();

//       if (mounted) Navigator.pop(context);
//       await Share.shareXFiles([
//         XFile(file.path),
//       ], text: 'Reporte PDF Inteligencia');
//     } catch (e) {
//       if (mounted) {
//         try {
//           Navigator.pop(context);
//         } catch (_) {}
//       }
//       debugPrint("Error PDF Inteligencia: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("No se pudo generar el PDF: $e")),
//         );
//       }
//     }
//   }

//   Future<void> _importarExcel() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['xlsx'],
//       );
//       if (result != null) {
//         var bytes = File(result.files.single.path!).readAsBytesSync();
//         var excel = Excel.decodeBytes(bytes);
//         final db = await DBManager.instance.database;

//         for (var table in excel.tables.keys) {
//           var rows = excel.tables[table]!.rows;
//           for (int i = 1; i < rows.length; i++) {
//             var row = rows[i];
//             if (row.length >= 5) {
//               await db.insert(_tableName, {
//                 'fecha': row[0]?.value.toString() ?? '',
//                 'hora': row[1]?.value.toString() ?? '',
//                 'asunto': row[2]?.value.toString() ?? '',
//                 'medio': row[3]?.value.toString() ?? '',
//                 'anotaciones': row[4]?.value.toString() ?? '',
//                 'imagen': '',
//                 'adjuntos': '',
//               });
//             }
//           }
//         }
//         _cargarDatos();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Datos importados con éxito")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error al importar: $e")));
//     }
//   }

//   Future<void> _exportarExcel() async {
//     var excel = Excel.createExcel();
//     Sheet sheet = excel['Inteligencia'];
//     sheet.appendRow([
//       TextCellValue('Fecha'),
//       TextCellValue('Hora'),
//       TextCellValue('Asunto'),
//       TextCellValue('Medio'),
//       TextCellValue('Anotaciones'),
//       TextCellValue('Imagen'),
//       TextCellValue('Adjuntos'),
//     ]);
//     for (var m in _filteredData) {
//       sheet.appendRow([
//         TextCellValue(m['fecha']),
//         TextCellValue(m['hora']),
//         TextCellValue(m['asunto']),
//         TextCellValue(m['medio']),
//         TextCellValue(m['anotaciones']),
//         TextCellValue(m['imagen']?.toString().isNotEmpty == true ? 'Sí' : 'No'),
//         TextCellValue(
//           m['adjuntos']?.toString().isNotEmpty == true ? 'Sí' : 'No',
//         ),
//       ]);
//     }
//     final directory = await getTemporaryDirectory();
//     final filePath = '${directory.path}/Reporte_Inteligencia.xlsx';
//     final bytes = excel.save();
//     if (bytes != null) {
//       await File(filePath).writeAsBytes(bytes);
//       await Share.shareXFiles([XFile(filePath)], text: 'Excel Inteligencia');
//     }
//   }

//   void _abrirFormulario({Map<String, dynamic>? item}) {
//     final bool esEdicion = item != null;

//     final fCon = TextEditingController(
//       text: esEdicion
//           ? item['fecha']
//           : DateFormat('yyyy-MM-dd').format(DateTime.now()),
//     );
//     final hCon = TextEditingController(
//       text: esEdicion
//           ? item['hora']
//           : DateFormat('HH:mm').format(DateTime.now()),
//     );
//     final aCon = TextEditingController(text: esEdicion ? item['asunto'] : '');
//     final mCon = TextEditingController(text: esEdicion ? item['medio'] : '');
//     final nCon = TextEditingController(
//       text: esEdicion ? item['anotaciones'] : '',
//     );

//     String? _rutaImagenActual = esEdicion ? item['imagen'] : null;

//     // Lógica para múltiples archivos (Genéricos)
//     List<String> _rutasArchivosActuales = [];
//     if (esEdicion && item['adjuntos'] != null) {
//       String adjuntosStr = item['adjuntos'] as String;
//       if (adjuntosStr.isNotEmpty) {
//         _rutasArchivosActuales = adjuntosStr.split('|');
//       }
//     }

//     showDialog(
//       context: context,
//       builder: (c) => StatefulBuilder(
//         builder: (context, setDialogState) {
//           return AlertDialog(
//             title: Text(
//               esEdicion ? "Editar Inteligencia" : "Nuevo Registro Inteligencia",
//             ),
//             content: SizedBox(
//               width: MediaQuery.of(context).size.width * 0.8,
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: fCon,
//                             decoration: const InputDecoration(
//                               labelText: "Fecha",
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: TextField(
//                             controller: hCon,
//                             decoration: const InputDecoration(
//                               labelText: "Hora",
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: aCon,
//                       decoration: const InputDecoration(
//                         labelText: "Asunto",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: mCon,
//                       decoration: const InputDecoration(
//                         labelText: "Medio",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: nCon,
//                       maxLines: 5,
//                       decoration: const InputDecoration(
//                         labelText: "Anotaciones",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),

//                     // --- SECCIÓN IMAGEN ---
//                     const Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(
//                         "Evidencia Fotográfica:",
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Row(
//                       children: [
//                         Container(
//                           width: 80,
//                           height: 80,
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey),
//                             borderRadius: BorderRadius.circular(8),
//                             color: Colors.grey[200],
//                           ),
//                           child: _rutaImagenActual != null
//                               ? ClipRRect(
//                                   borderRadius: BorderRadius.circular(7),
//                                   child: Image.file(
//                                     File(_rutaImagenActual!),
//                                     fit: BoxFit.cover,
//                                   ),
//                                 )
//                               : const Icon(
//                                   Icons.image,
//                                   size: 40,
//                                   color: Colors.grey,
//                                 ),
//                         ),
//                         const SizedBox(width: 10),
//                         Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             ElevatedButton.icon(
//                               onPressed: () {
//                                 showModalBottomSheet(
//                                   context: context,
//                                   builder: (BuildContext bc) {
//                                     return SafeArea(
//                                       child: Wrap(
//                                         children: <Widget>[
//                                           ListTile(
//                                             leading: const Icon(
//                                               Icons.camera_alt,
//                                             ),
//                                             title: const Text('Cámara'),
//                                             onTap: () async {
//                                               Navigator.pop(bc);
//                                               final XFile? photo = await _picker
//                                                   .pickImage(
//                                                     source: ImageSource.camera,
//                                                     imageQuality: 50,
//                                                   );
//                                               if (photo != null) {
//                                                 setDialogState(() {
//                                                   _rutaImagenActual =
//                                                       photo.path;
//                                                 });
//                                               }
//                                             },
//                                           ),
//                                           ListTile(
//                                             leading: const Icon(
//                                               Icons.photo_library,
//                                             ),
//                                             title: const Text('Galería'),
//                                             onTap: () async {
//                                               Navigator.pop(bc);
//                                               final XFile? photo = await _picker
//                                                   .pickImage(
//                                                     source: ImageSource.gallery,
//                                                     imageQuality: 50,
//                                                   );
//                                               if (photo != null) {
//                                                 setDialogState(() {
//                                                   _rutaImagenActual =
//                                                       photo.path;
//                                                 });
//                                               }
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                 );
//                               },
//                               icon: const Icon(Icons.add_a_photo, size: 18),
//                               label: const Text("Adjuntar Foto"),
//                               style: ElevatedButton.styleFrom(
//                                 foregroundColor: Colors.white,
//                                 backgroundColor: Colors.indigo,
//                               ),
//                             ),
//                             if (_rutaImagenActual != null)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 5.0),
//                                 child: TextButton(
//                                   onPressed: () {
//                                     setDialogState(() {
//                                       _rutaImagenActual = null;
//                                     });
//                                   },
//                                   child: const Text(
//                                     "Eliminar Foto",
//                                     style: TextStyle(
//                                       color: Colors.red,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 20),
//                     const Divider(),
//                     const SizedBox(height: 10),

//                     // --- SECCIÓN ARCHIVOS ADJUNTOS (GENERALES) ---
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           "Archivos Adjuntos:",
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         ElevatedButton.icon(
//                           onPressed: () async {
//                             FilePickerResult? result = await FilePicker.platform
//                                 .pickFiles(
//                                   allowMultiple: true,
//                                   type: FileType.any,
//                                 );

//                             if (result != null) {
//                               setDialogState(() {
//                                 _rutasArchivosActuales.addAll(
//                                   result.paths.map((e) => e!).toList(),
//                                 );
//                               });
//                             }
//                           },
//                           icon: const Icon(Icons.attach_file, size: 16),
//                           label: const Text("Agregar Archivos"),
//                           style: ElevatedButton.styleFrom(
//                             foregroundColor: Colors.white,
//                             backgroundColor: Colors.teal,
//                           ),
//                         ),
//                       ],
//                     ),

//                     // --- NUEVO BOTÓN: ADJUNTAR AUDIO ---
//                     Padding(
//                       padding: const EdgeInsets.only(top: 10.0),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: () async {
//                                 // Abrir selector específico de audio
//                                 FilePickerResult? result = await FilePicker
//                                     .platform
//                                     .pickFiles(
//                                       type: FileType.audio,
//                                       allowMultiple: true,
//                                     );

//                                 if (result != null) {
//                                   setDialogState(() {
//                                     _rutasArchivosActuales.addAll(
//                                       result.paths.map((e) => e!).toList(),
//                                     );
//                                   });
//                                 }
//                               },
//                               icon: const Icon(Icons.mic, size: 18),
//                               label: const Text("Adjuntar Audio"),
//                               style: ElevatedButton.styleFrom(
//                                 foregroundColor: Colors.white,
//                                 backgroundColor: Colors.deepPurple,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     // LISTA DE ARCHIVOS (GENERALES + AUDIO)
//                     if (_rutasArchivosActuales.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.all(10.0),
//                         child: Text(
//                           "No hay archivos adjuntos.",
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontStyle: FontStyle.italic,
//                           ),
//                         ),
//                       )
//                     else
//                       Container(
//                         constraints: const BoxConstraints(maxHeight: 150),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade300),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: ListView.builder(
//                           shrinkWrap: true,
//                           itemCount: _rutasArchivosActuales.length,
//                           itemBuilder: (context, index) {
//                             final path = _rutasArchivosActuales[index];
//                             final fileName = path.split('/').last;
//                             // Detectar si es audio para mostrar icono especial
//                             final isAudio =
//                                 path.toLowerCase().endsWith('.mp3') ||
//                                 path.toLowerCase().endsWith('.wav') ||
//                                 path.toLowerCase().endsWith('.m4a') ||
//                                 path.toLowerCase().endsWith('.aac');

//                             return ListTile(
//                               dense: true,
//                               leading: Icon(
//                                 isAudio
//                                     ? Icons.audiotrack
//                                     : Icons.insert_drive_file,
//                                 color: isAudio
//                                     ? Colors.deepPurple
//                                     : Colors.blueGrey,
//                               ),
//                               title: Text(
//                                 fileName,
//                                 style: const TextStyle(fontSize: 12),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               trailing: IconButton(
//                                 icon: const Icon(
//                                   Icons.remove_circle,
//                                   color: Colors.red,
//                                   size: 20,
//                                 ),
//                                 onPressed: () {
//                                   setDialogState(() {
//                                     _rutasArchivosActuales.removeAt(index);
//                                   });
//                                 },
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(c),
//                 child: const Text("Cancelar"),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   final db = await DBManager.instance.database;

//                   // Unir rutas de archivos con un separador (|)
//                   String adjuntosString = _rutasArchivosActuales.join('|');

//                   final map = {
//                     'fecha': fCon.text,
//                     'hora': hCon.text,
//                     'asunto': aCon.text,
//                     'medio': mCon.text,
//                     'anotaciones': nCon.text,
//                     'imagen': _rutaImagenActual,
//                     'adjuntos': adjuntosString,
//                   };
//                   if (esEdicion) {
//                     await db.update(
//                       _tableName,
//                       map,
//                       where: 'id = ?',
//                       whereArgs: [item['id']],
//                     );
//                   } else {
//                     await db.insert(_tableName, map);
//                   }
//                   Navigator.pop(c);
//                   _cargarDatos();
//                 },
//                 child: const Text("Guardar"),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   // --- FUNCIÓN PARA VER EL REGISTRO COMPLETO ---
//   void _verRegistro(Map<String, dynamic> item) {
//     final ThemeData theme = Theme.of(context);
//     final bool isDark = theme.brightness == Brightness.dark;

//     // Parsear archivos adjuntos
//     List<String> archivos = [];
//     if (item['adjuntos'] != null) {
//       String str = item['adjuntos'] as String;
//       if (str.isNotEmpty) {
//         archivos = str.split('|');
//       }
//     }

//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: theme.colorScheme.surface,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Container(
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.9,
//             maxHeight: MediaQuery.of(context).size.height * 0.85,
//           ),
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "Detalle del Registro",
//                       style: theme.textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: theme.colorScheme.onSurface,
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.pop(context),
//                       color: theme.colorScheme.onSurfaceVariant,
//                     ),
//                   ],
//                 ),
//                 Divider(color: theme.dividerColor),
//                 const SizedBox(height: 15),

//                 _detalleFila("Fecha:", item['fecha']),
//                 _detalleFila("Hora:", item['hora']),
//                 _detalleFila("Asunto:", item['asunto']),
//                 _detalleFila("Medio:", item['medio']),
//                 const SizedBox(height: 15),

//                 Text(
//                   "Anotaciones:",
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.onSurface,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   item['anotaciones']?.toString() ?? 'Sin anotaciones',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: theme.colorScheme.onSurface,
//                     height: 1.4,
//                   ),
//                 ),
//                 const SizedBox(height: 25),

//                 // --- VISUALIZACIÓN DE IMAGEN ---
//                 if (item['imagen'] != null &&
//                     item['imagen'].toString().isNotEmpty)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Evidencia Fotográfica:",
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: theme.colorScheme.onSurface,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Center(
//                         child: InkWell(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => Scaffold(
//                                   backgroundColor: Colors.black,
//                                   appBar: AppBar(
//                                     backgroundColor: Colors.transparent,
//                                     iconTheme: const IconThemeData(
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                   body: Center(
//                                     child: InteractiveViewer(
//                                       child: Image.file(
//                                         File(item['imagen'].toString()),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                           child: Container(
//                             height: 300,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: isDark
//                                   ? const Color(0xFF2C2C2C)
//                                   : Colors.grey[200],
//                               border: Border.all(
//                                 color: isDark ? Colors.grey[700]! : Colors.grey,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(12),
//                               child: Image.file(
//                                 File(item['imagen'].toString()),
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       Center(
//                         child: Text(
//                           "Toca la imagen para ampliar",
//                           style: TextStyle(
//                             color: theme.colorScheme.onSurfaceVariant,
//                             fontSize: 12,
//                             fontStyle: FontStyle.italic,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                 // --- VISUALIZACIÓN DE ARCHIVOS ADJUNTOS (Incluye Audio) ---
//                 if (archivos.isNotEmpty) ...[
//                   const SizedBox(height: 25),
//                   Text(
//                     "Archivos Adjuntos:",
//                     style: theme.textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: theme.colorScheme.onSurface,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   ...archivos.map((path) {
//                     final fileName = path.split('/').last;
//                     // Detectar tipo de archivo para icono
//                     final isAudio =
//                         path.toLowerCase().endsWith('.mp3') ||
//                         path.toLowerCase().endsWith('.wav') ||
//                         path.toLowerCase().endsWith('.m4a') ||
//                         path.toLowerCase().endsWith('.aac');

//                     return Card(
//                       margin: const EdgeInsets.symmetric(vertical: 4),
//                       child: ListTile(
//                         leading: Icon(
//                           isAudio ? Icons.audiotrack : Icons.description,
//                           color: isAudio ? Colors.deepPurple : Colors.teal,
//                         ),
//                         title: Text(
//                           fileName,
//                           style: const TextStyle(fontSize: 13),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.open_in_new, size: 20),
//                           tooltip: "Abrir archivo",
//                           onPressed: () async {
//                             final result = await OpenFile.open(path);
//                             if (result.type == ResultType.noAppToOpen) {
//                               if (mounted) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text(
//                                       "No hay aplicación para abrir este archivo",
//                                     ),
//                                   ),
//                                 );
//                               }
//                             }
//                           },
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _detalleFila(String label, String? value) {
//     final ThemeData theme = Theme.of(context);
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 90,
//             child: Text(
//               label,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.onSurface,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value?.toString() ?? '',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurface,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Libro de Inteligencia",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(0xFF1A237E),
//         iconTheme: const IconThemeData(color: Colors.white),
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
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.greenAccent.withOpacity(0.6),
//                         blurRadius: 4,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 CircleAvatar(
//                   radius: 14,
//                   backgroundColor: Colors.white.withOpacity(0.2),
//                   child: Text(
//                     _nombreUsuario != null && _nombreUsuario!.isNotEmpty
//                         ? _nombreUsuario![0].toUpperCase()
//                         : "?",
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   _nombreUsuario ?? "Usuario",
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       _btn(
//                         "PDF",
//                         Colors.purple,
//                         Icons.picture_as_pdf,
//                         _exportarPDF,
//                       ),
//                       const SizedBox(width: 10),
//                       _btn(
//                         "Exportar",
//                         Colors.green,
//                         Icons.file_upload,
//                         _exportarExcel,
//                       ),
//                       const SizedBox(width: 10),
//                       _btn(
//                         "Importar",
//                         Colors.blueGrey,
//                         Icons.file_download,
//                         _importarExcel,
//                       ),
//                       const SizedBox(width: 10),
//                       _btn(
//                         "Nuevo",
//                         Colors.indigo,
//                         Icons.add,
//                         () => _abrirFormulario(),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 TextField(
//                   controller: _searchController,
//                   onChanged: _filtrarDatos,
//                   decoration: InputDecoration(
//                     hintText: "Buscar por asunto, medio, fecha...",
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 15),
//             Expanded(
//               child: _filteredData.isEmpty
//                   ? const Center(child: Text("No se encontraron registros"))
//                   : SingleChildScrollView(
//                       scrollDirection: Axis.vertical,
//                       child: Table(
//                         border: TableBorder.all(color: Colors.grey[300]!),
//                         columnWidths: const {
//                           0: FlexColumnWidth(1.2),
//                           1: FlexColumnWidth(0.8),
//                           2: FlexColumnWidth(1.5),
//                           3: FlexColumnWidth(1.5),
//                           4: FlexColumnWidth(4.5),
//                           5: FlexColumnWidth(1.5),
//                         },
//                         children: [
//                           _header(),
//                           ..._filteredData.map((m) => _row(m)),
//                         ],
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   TableRow _header() {
//     return TableRow(
//       decoration: const BoxDecoration(color: Color(0xFF2196F3)),
//       children: ['Fecha', 'Hora', 'Asunto', 'Medio', 'Anotación', 'Acciones']
//           .map(
//             (t) => Container(
//               padding: const EdgeInsets.all(10),
//               child: Text(
//                 t,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//           )
//           .toList(),
//     );
//   }

//   TableRow _row(Map<String, dynamic> m) => TableRow(
//     children: [
//       _c(m['fecha']),
//       _c(m['hora']),
//       _c(m['asunto']),
//       _c(m['medio']),
//       _c(m['anotaciones']),
//       Padding(
//         padding: const EdgeInsets.all(5.0),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             IconButton(
//               icon: const Icon(Icons.visibility, color: Colors.blue, size: 18),
//               onPressed: () => _verRegistro(m),
//               tooltip: 'Ver Registro',
//             ),
//             IconButton(
//               icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
//               onPressed: () => _abrirFormulario(item: m),
//               tooltip: 'Editar',
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red, size: 18),
//               onPressed: () async {
//                 final confirm = await _confirmarEliminacion();
//                 if (confirm == true) {
//                   final db = await DBManager.instance.database;
//                   await db.delete(
//                     _tableName,
//                     where: 'id = ?',
//                     whereArgs: [m['id']],
//                   );
//                   _cargarDatos();
//                 }
//               },
//               tooltip: 'Eliminar',
//             ),
//           ],
//         ),
//       ),
//     ],
//   );

//   Future<bool?> _confirmarEliminacion() {
//     return showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("Eliminar Registro"),
//         content: const Text(
//           "¿Está seguro de que desea eliminar este registro?",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Cancelar"),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _c(String t) => Padding(
//     padding: const EdgeInsets.all(10),
//     child: Text(t, style: const TextStyle(fontSize: 11)),
//   );

//   Widget _btn(String t, Color c, IconData i, VoidCallback o) =>
//       ElevatedButton.icon(
//         onPressed: o,
//         icon: Icon(i, size: 16, color: Colors.white),
//         label: Text(t, style: const TextStyle(color: Colors.white)),
//         style: ElevatedButton.styleFrom(backgroundColor: c),
//       );
// }

// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:intl/intl.dart';
// import 'package:excel/excel.dart' hide Border;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:open_file/open_file.dart';
// import '../../BD/db_manager.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;

// // ────────────────────────────────────────────────────────────────────────────────
// // FUNCIÓN TOP-LEVEL para generar PDF en isolate separado (Evita congelar UI)
// // ────────────────────────────────────────────────────────────────────────────────
// Future<List<int>> _generarPdfBytesIsolate(
//   List<Map<String, dynamic>> data,
// ) async {
//   final pdf = pw.Document();

//   final headerStyle = pw.TextStyle(
//     color: PdfColors.white,
//     fontWeight: pw.FontWeight.bold,
//     fontSize: 10,
//   );
//   final cellStyle = const pw.TextStyle(fontSize: 9);

//   // Dividir en bloques de 200 registros para evitar out-of-memory
//   const int rowsPerPage = 200;
//   final int totalPages = (data.length / rowsPerPage).ceil();

//   for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
//     final chunk = data.skip(pageIndex * rowsPerPage).take(rowsPerPage).toList();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.letter.copyWith(
//           marginBottom: 1.5 * PdfPageFormat.cm,
//           marginTop: 1.5 * PdfPageFormat.cm,
//           marginLeft: 1 * PdfPageFormat.cm,
//           marginRight: 1 * PdfPageFormat.cm,
//         ),
//         header: (context) => pw.Container(
//           alignment: pw.Alignment.centerRight,
//           margin: const pw.EdgeInsets.only(bottom: 20),
//           child: pw.Text(
//             "INTELIGENCIA - CALIPSO",
//             style: pw.TextStyle(color: PdfColors.grey700, fontSize: 12),
//           ),
//         ),
//         footer: (context) => pw.Container(
//           alignment: pw.Alignment.centerRight,
//           margin: const pw.EdgeInsets.only(top: 10),
//           child: pw.Text(
//             'Página ${context.pageNumber} de ${context.pagesCount}',
//             style: const pw.TextStyle(fontSize: 10),
//           ),
//         ),
//         build: (context) => [
//           pw.Header(
//             level: 0,
//             child: pw.Text(
//               "REPORTE LIBRO DE INTELIGENCIA",
//               style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
//             ),
//           ),
//           pw.SizedBox(height: 10),
//           pw.Table(
//             border: pw.TableBorder.all(color: PdfColors.black),
//             columnWidths: {
//               0: const pw.FixedColumnWidth(70),
//               1: const pw.FixedColumnWidth(45),
//               2: const pw.FixedColumnWidth(90),
//               3: const pw.FixedColumnWidth(70),
//               4: const pw.FlexColumnWidth(),
//               5: const pw.FixedColumnWidth(30),
//               6: const pw.FixedColumnWidth(30),
//             },
//             children: [
//               // Encabezado
//               pw.TableRow(
//                 decoration: const pw.BoxDecoration(color: PdfColors.indigo900),
//                 children: [
//                   pw.Text('Fecha', style: headerStyle),
//                   pw.Text('Hora', style: headerStyle),
//                   pw.Text('Asunto', style: headerStyle),
//                   pw.Text('Medio', style: headerStyle),
//                   pw.Text('Anotaciones', style: headerStyle),
//                   pw.Text('Img', style: headerStyle),
//                   pw.Text('Adj', style: headerStyle),
//                 ],
//               ),
//               // Filas dinámicas
//               ...chunk.asMap().entries.map((entry) {
//                 final i = entry.key;
//                 final m = entry.value;
//                 return pw.TableRow(
//                   decoration: i.isOdd
//                       ? const pw.BoxDecoration(color: PdfColors.grey100)
//                       : const pw.BoxDecoration(),
//                   children: [
//                     pw.Text(m['fecha']?.toString() ?? '', style: cellStyle),
//                     pw.Text(m['hora']?.toString() ?? '', style: cellStyle),
//                     pw.Text(m['asunto']?.toString() ?? '', style: cellStyle),
//                     pw.Text(m['medio']?.toString() ?? '', style: cellStyle),
//                     pw.Text(
//                       m['anotaciones']?.toString() ?? '',
//                       style: cellStyle,
//                     ),
//                     pw.Text(
//                       (m['imagen'] != null && m['imagen'].toString().isNotEmpty)
//                           ? 'Sí'
//                           : 'No',
//                       style: cellStyle,
//                     ),
//                     pw.Text(
//                       (m['adjuntos'] != null &&
//                               m['adjuntos'].toString().isNotEmpty)
//                           ? 'Sí'
//                           : 'No',
//                       style: cellStyle,
//                     ),
//                   ],
//                 );
//               }),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   return await pdf.save();
// }

// // ────────────────────────────────────────────────────────────────────────────────
// // FUNCIÓN PARA GENERAR WORD (TABLA CONTINUA - LIBRO DE INTELIGENCIA)
// // ────────────────────────────────────────────────────────────────────────────────
// Future<File> _generarWordFileInteligencia(
//   List<Map<String, dynamic>> data,
// ) async {
//   final buffer = StringBuffer();

//   // 1. Cabecera HTML
//   buffer.writeln(
//     '<html xmlns:o="urn:schemas-microsoft-com:office:office" '
//     'xmlns:w="urn:schemas-microsoft-com:office:word" '
//     'xmlns="http://www.w3.org/TR/REC-html40">',
//   );
//   buffer.writeln('<head><meta charset="utf-8">');
//   buffer.writeln('<meta name=ProgId content=Word.Document>');
//   buffer.writeln('<title>Reporte Inteligencia</title></head><body>');

//   // 2. TÍTULO
//   buffer.writeln(
//     '<h1 style="text-align: center; font-family: Arial; font-size: 20pt; font-weight: bold; margin-bottom: 20px;">REPORTE LIBRO DE INTELIGENCIA</h1>',
//   );

//   // 3. TABLA PRINCIPAL (encabezado + datos)
//   buffer.writeln(
//     '<table style="width: 100%; border-collapse: collapse; border: 1px solid #000000;">',
//   );

//   // Encabezados
//   buffer.writeln('<tr>');
//   buffer.writeln(
//     '<th style="width: 10%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Fecha</th>',
//   );
//   buffer.writeln(
//     '<th style="width: 8%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Hora</th>',
//   );
//   buffer.writeln(
//     '<th style="width: 25%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Asunto</th>',
//   );
//   buffer.writeln(
//     '<th style="width: 15%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Medio</th>',
//   );
//   buffer.writeln(
//     '<th style="width: 32%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Anotaciones</th>',
//   );
//   buffer.writeln(
//     '<th style="width: 5%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Img</th>',
//   );
//   buffer.writeln(
//     '<th style="width: 5%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Adj</th>',
//   );
//   buffer.writeln('</tr>');

//   // 4. FILAS DE DATOS
//   for (var m in data) {
//     String anotaciones = (m['anotaciones']?.toString() ?? '').replaceAll(
//       '\n',
//       '<br>',
//     );

//     // Escapar HTML básico
//     String fecha = (m['fecha']?.toString() ?? '').replaceAll('<', '&lt;');
//     String hora = (m['hora']?.toString() ?? '').replaceAll('<', '&lt;');
//     String asunto = (m['asunto']?.toString() ?? '').replaceAll('<', '&lt;');
//     String medio = (m['medio']?.toString() ?? '').replaceAll('<', '&lt;');
//     anotaciones = anotaciones.replaceAll('<', '&lt;');

//     String imagen = (m['imagen'] != null && m['imagen'].toString().isNotEmpty)
//         ? 'Sí'
//         : 'No';
//     String adjuntos =
//         (m['adjuntos'] != null && m['adjuntos'].toString().isNotEmpty)
//         ? 'Sí'
//         : 'No';

//     buffer.writeln('<tr>');
//     buffer.writeln(
//       '<td style="width: 10%; border: 1px solid #000000; padding: 6px; text-align: center;">$fecha</td>',
//     );
//     buffer.writeln(
//       '<td style="width: 8%; border: 1px solid #000000; padding: 6px; text-align: center;">$hora</td>',
//     );
//     buffer.writeln(
//       '<td style="width: 25%; border: 1px solid #000000; padding: 6px; text-align: left;">$asunto</td>',
//     );
//     buffer.writeln(
//       '<td style="width: 15%; border: 1px solid #000000; padding: 6px; text-align: left;">$medio</td>',
//     );
//     buffer.writeln(
//       '<td style="width: 32%; border: 1px solid #000000; padding: 6px; text-align: left;">$anotaciones</td>',
//     );
//     buffer.writeln(
//       '<td style="width: 5%; border: 1px solid #000000; padding: 6px; text-align: center;">$imagen</td>',
//     );
//     buffer.writeln(
//       '<td style="width: 5%; border: 1px solid #000000; padding: 6px; text-align: center;">$adjuntos</td>',
//     );
//     buffer.writeln('</tr>');
//   }

//   buffer.writeln('</table>');
//   buffer.writeln('</body></html>');

//   // 5. Guardar
//   final tempDir = await getTemporaryDirectory();
//   final filePath = '${tempDir.path}/Reporte_Inteligencia.doc';
//   final file = File(filePath);
//   await file.writeAsBytes(const Utf8Encoder().convert(buffer.toString()));

//   return file;
// }

// class InteligenciaScreen extends StatefulWidget {
//   const InteligenciaScreen({super.key});
//   @override
//   State<InteligenciaScreen> createState() => _InteligenciaScreenState();
// }

// class _InteligenciaScreenState extends State<InteligenciaScreen> {
//   List<Map<String, dynamic>> _allData = [];
//   List<Map<String, dynamic>> _filteredData = [];
//   final String _tableName = 'inteligencia';

//   final TextEditingController _searchController = TextEditingController();
//   final ImagePicker _picker = ImagePicker();

//   String? _nombreUsuario;
//   bool _cargandoUsuario = true;

//   @override
//   void initState() {
//     super.initState();
//     _cargarUsuarioLogueado();
//     _cargarDatos();
//   }

//   Future<void> _cargarUsuarioLogueado() async {
//     final db = await DBManager.instance.authDatabase;
//     try {
//       final sesion = await db.query('sesion_activa', limit: 1);
//       if (sesion.isNotEmpty) {
//         final int usuarioId = sesion.first['usuario_id'] as int;
//         final usuario = await db.query(
//           'usuarios',
//           where: 'id = ?',
//           whereArgs: [usuarioId],
//           limit: 1,
//         );

//         if (usuario.isNotEmpty && mounted) {
//           setState(() {
//             _nombreUsuario = usuario.first['nombres'] as String?;
//             _cargandoUsuario = false;
//           });
//           return;
//         }
//       }
//     } catch (e) {
//       print("Error cargando usuario en inteligencia: $e");
//     }
//     if (mounted) setState(() => _cargandoUsuario = false);
//   }

//   Future<void> _cargarDatos() async {
//     final db = await DBManager.instance.database;
//     final data = await db.query(_tableName, orderBy: 'fecha ASC, hora ASC');
//     setState(() {
//       _allData = data;
//       _filteredData = data;
//     });
//   }

//   void _filtrarDatos(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         _filteredData = _allData;
//       } else {
//         _filteredData = _allData.where((item) {
//           final asunto = (item['asunto']?.toString() ?? '').toLowerCase();
//           final medio = (item['medio']?.toString() ?? '').toLowerCase();
//           final anotaciones = (item['anotaciones']?.toString() ?? '')
//               .toLowerCase();
//           final fecha = (item['fecha']?.toString() ?? '').toLowerCase();
//           final searchLower = query.toLowerCase();

//           return asunto.contains(searchLower) ||
//               medio.contains(searchLower) ||
//               anotaciones.contains(searchLower) ||
//               fecha.contains(searchLower);
//         }).toList();
//       }
//     });
//   }

//   // ─────────────────────────────────────────────────────
//   // FUNCIÓN EXPORTAR PDF (SnackBar + Botón Abrir)
//   // ─────────────────────────────────────────────────────
//   Future<void> _exportarPDF() async {
//     try {
//       // 1. Mostrar Loader
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const PopScope(
//           canPop: false,
//           child: Center(child: CircularProgressIndicator()),
//         ),
//       );

//       // 2. Preparar Datos
//       final data = _filteredData
//           .map(
//             (m) => {
//               'fecha': m['fecha']?.toString() ?? '',
//               'hora': m['hora']?.toString() ?? '',
//               'asunto': m['asunto']?.toString() ?? '',
//               'medio': m['medio']?.toString() ?? '',
//               'anotaciones': m['anotaciones']?.toString() ?? '',
//               'imagen': m['imagen'],
//               'adjuntos': m['adjuntos'],
//             },
//           )
//           .toList();

//       // 3. Generar en Isolate
//       final pdfBytes = await compute(_generarPdfBytesIsolate, data);

//       // 4. Guardar en temporal
//       final dir = await getTemporaryDirectory();
//       final String fileName = 'Reporte_Inteligencia.pdf';
//       final file = File('${dir.path}/$fileName');

//       final sink = file.openWrite();
//       const chunkSize = 65536;
//       for (int i = 0; i < pdfBytes.length; i += chunkSize) {
//         final end = (i + chunkSize > pdfBytes.length)
//             ? pdfBytes.length
//             : i + chunkSize;
//         sink.add(pdfBytes.sublist(i, end));
//       }
//       await sink.flush();
//       await sink.close();

//       // 5. Cerrar Loader
//       if (mounted) Navigator.pop(context);

//       // 6. Mostrar SnackBar de Éxito con opción ABRIR
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text("PDF generado correctamente"),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 4),
//             action: SnackBarAction(
//               label: 'ABRIR',
//               textColor: Colors.white,
//               onPressed: () {
//                 OpenFile.open(file.path);
//               },
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         try {
//           Navigator.pop(context);
//         } catch (_) {}
//       }
//       debugPrint("Error PDF Inteligencia: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("No se pudo generar el PDF: $e")),
//         );
//       }
//     }
//   }

//   // ─────────────────────────────────────────────────────
//   // FUNCIÓN EXPORTAR WORD (Alineado y con SnackBar)
//   // ─────────────────────────────────────────────────────
//   Future<void> _exportarWord() async {
//     try {
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => const PopScope(
//           canPop: false,
//           child: Center(child: CircularProgressIndicator()),
//         ),
//       );

//       final data = _filteredData
//           .map(
//             (m) => {
//               'fecha': m['fecha']?.toString() ?? '',
//               'hora': m['hora']?.toString() ?? '',
//               'asunto': m['asunto']?.toString() ?? '',
//               'medio': m['medio']?.toString() ?? '',
//               'anotaciones': m['anotaciones']?.toString() ?? '',
//               'imagen': m['imagen'],
//               'adjuntos': m['adjuntos'],
//             },
//           )
//           .toList();

//       final file = await _generarWordFileInteligencia(data);

//       if (mounted) Navigator.pop(context);

//       // Abrir automáticamente o mostrar SnackBar
//       await OpenFile.open(file.path);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Documento Word generado"),
//             backgroundColor: Colors.blue,
//             duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         try {
//           Navigator.pop(context);
//         } catch (_) {}
//       }
//       debugPrint("Error Word Inteligencia: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("No se pudo generar el Word: $e")),
//         );
//       }
//     }
//   }

//   Future<void> _importarExcel() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['xlsx'],
//       );
//       if (result != null) {
//         var bytes = File(result.files.single.path!).readAsBytesSync();
//         var excel = Excel.decodeBytes(bytes);
//         final db = await DBManager.instance.database;

//         for (var table in excel.tables.keys) {
//           var rows = excel.tables[table]!.rows;
//           for (int i = 1; i < rows.length; i++) {
//             var row = rows[i];
//             if (row.length >= 5) {
//               await db.insert(_tableName, {
//                 'fecha': row[0]?.value.toString() ?? '',
//                 'hora': row[1]?.value.toString() ?? '',
//                 'asunto': row[2]?.value.toString() ?? '',
//                 'medio': row[3]?.value.toString() ?? '',
//                 'anotaciones': row[4]?.value.toString() ?? '',
//                 'imagen': '',
//                 'adjuntos': '',
//               });
//             }
//           }
//         }
//         _cargarDatos();
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Datos importados con éxito")),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Error al importar: $e")));
//     }
//   }

//   Future<void> _exportarExcel() async {
//     var excel = Excel.createExcel();
//     Sheet sheet = excel['Inteligencia'];
//     sheet.appendRow([
//       TextCellValue('Fecha'),
//       TextCellValue('Hora'),
//       TextCellValue('Asunto'),
//       TextCellValue('Medio'),
//       TextCellValue('Anotaciones'),
//       TextCellValue('Imagen'),
//       TextCellValue('Adjuntos'),
//     ]);
//     for (var m in _filteredData) {
//       sheet.appendRow([
//         TextCellValue(m['fecha']),
//         TextCellValue(m['hora']),
//         TextCellValue(m['asunto']),
//         TextCellValue(m['medio']),
//         TextCellValue(m['anotaciones']),
//         TextCellValue(m['imagen']?.toString().isNotEmpty == true ? 'Sí' : 'No'),
//         TextCellValue(
//           m['adjuntos']?.toString().isNotEmpty == true ? 'Sí' : 'No',
//         ),
//       ]);
//     }
//     final directory = await getTemporaryDirectory();
//     final filePath = '${directory.path}/Reporte_Inteligencia.xlsx';
//     final bytes = excel.save();
//     if (bytes != null) {
//       await File(filePath).writeAsBytes(bytes);
//       await Share.shareXFiles([XFile(filePath)], text: 'Excel Inteligencia');
//     }
//   }

//   void _abrirFormulario({Map<String, dynamic>? item}) {
//     final bool esEdicion = item != null;

//     final fCon = TextEditingController(
//       text: esEdicion
//           ? item['fecha']
//           : DateFormat('yyyy-MM-dd').format(DateTime.now()),
//     );
//     final hCon = TextEditingController(
//       text: esEdicion
//           ? item['hora']
//           : DateFormat('HH:mm').format(DateTime.now()),
//     );
//     final aCon = TextEditingController(text: esEdicion ? item['asunto'] : '');
//     final mCon = TextEditingController(text: esEdicion ? item['medio'] : '');
//     final nCon = TextEditingController(
//       text: esEdicion ? item['anotaciones'] : '',
//     );

//     String? _rutaImagenActual = esEdicion ? item['imagen'] : null;

//     List<String> _rutasArchivosActuales = [];
//     if (esEdicion && item['adjuntos'] != null) {
//       String adjuntosStr = item['adjuntos'] as String;
//       if (adjuntosStr.isNotEmpty) {
//         _rutasArchivosActuales = adjuntosStr.split('|');
//       }
//     }

//     showDialog(
//       context: context,
//       builder: (c) => StatefulBuilder(
//         builder: (context, setDialogState) {
//           return AlertDialog(
//             title: Text(
//               esEdicion ? "Editar Inteligencia" : "Nuevo Registro Inteligencia",
//             ),
//             content: SizedBox(
//               width: MediaQuery.of(context).size.width * 0.8,
//               child: SingleChildScrollView(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextField(
//                             controller: fCon,
//                             decoration: const InputDecoration(
//                               labelText: "Fecha",
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: TextField(
//                             controller: hCon,
//                             decoration: const InputDecoration(
//                               labelText: "Hora",
//                               border: OutlineInputBorder(),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: aCon,
//                       decoration: const InputDecoration(
//                         labelText: "Asunto",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: mCon,
//                       decoration: const InputDecoration(
//                         labelText: "Medio",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     TextField(
//                       controller: nCon,
//                       maxLines: 5,
//                       decoration: const InputDecoration(
//                         labelText: "Anotaciones",
//                         border: OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 15),

//                     const Align(
//                       alignment: Alignment.centerLeft,
//                       child: Text(
//                         "Evidencia Fotográfica:",
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                     const SizedBox(height: 5),
//                     Row(
//                       children: [
//                         Container(
//                           width: 80,
//                           height: 80,
//                           decoration: BoxDecoration(
//                             border: Border.all(color: Colors.grey),
//                             borderRadius: BorderRadius.circular(8),
//                             color: Colors.grey[200],
//                           ),
//                           child: _rutaImagenActual != null
//                               ? ClipRRect(
//                                   borderRadius: BorderRadius.circular(7),
//                                   child: Image.file(
//                                     File(_rutaImagenActual!),
//                                     fit: BoxFit.cover,
//                                   ),
//                                 )
//                               : const Icon(
//                                   Icons.image,
//                                   size: 40,
//                                   color: Colors.grey,
//                                 ),
//                         ),
//                         const SizedBox(width: 10),
//                         Column(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             ElevatedButton.icon(
//                               onPressed: () {
//                                 showModalBottomSheet(
//                                   context: context,
//                                   builder: (BuildContext bc) {
//                                     return SafeArea(
//                                       child: Wrap(
//                                         children: <Widget>[
//                                           ListTile(
//                                             leading: const Icon(
//                                               Icons.camera_alt,
//                                             ),
//                                             title: const Text('Cámara'),
//                                             onTap: () async {
//                                               Navigator.pop(bc);
//                                               final XFile? photo = await _picker
//                                                   .pickImage(
//                                                     source: ImageSource.camera,
//                                                     imageQuality: 50,
//                                                   );
//                                               if (photo != null) {
//                                                 setDialogState(() {
//                                                   _rutaImagenActual =
//                                                       photo.path;
//                                                 });
//                                               }
//                                             },
//                                           ),
//                                           ListTile(
//                                             leading: const Icon(
//                                               Icons.photo_library,
//                                             ),
//                                             title: const Text('Galería'),
//                                             onTap: () async {
//                                               Navigator.pop(bc);
//                                               final XFile? photo = await _picker
//                                                   .pickImage(
//                                                     source: ImageSource.gallery,
//                                                     imageQuality: 50,
//                                                   );
//                                               if (photo != null) {
//                                                 setDialogState(() {
//                                                   _rutaImagenActual =
//                                                       photo.path;
//                                                 });
//                                               }
//                                             },
//                                           ),
//                                         ],
//                                       ),
//                                     );
//                                   },
//                                 );
//                               },
//                               icon: const Icon(Icons.add_a_photo, size: 18),
//                               label: const Text("Adjuntar Foto"),
//                               style: ElevatedButton.styleFrom(
//                                 foregroundColor: Colors.white,
//                                 backgroundColor: Colors.indigo,
//                               ),
//                             ),
//                             if (_rutaImagenActual != null)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 5.0),
//                                 child: TextButton(
//                                   onPressed: () {
//                                     setDialogState(() {
//                                       _rutaImagenActual = null;
//                                     });
//                                   },
//                                   child: const Text(
//                                     "Eliminar Foto",
//                                     style: TextStyle(
//                                       color: Colors.red,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ],
//                     ),

//                     const SizedBox(height: 20),
//                     const Divider(),
//                     const SizedBox(height: 10),

//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           "Archivos Adjuntos:",
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         ElevatedButton.icon(
//                           onPressed: () async {
//                             FilePickerResult? result = await FilePicker.platform
//                                 .pickFiles(
//                                   allowMultiple: true,
//                                   type: FileType.any,
//                                 );

//                             if (result != null) {
//                               setDialogState(() {
//                                 _rutasArchivosActuales.addAll(
//                                   result.paths.map((e) => e!).toList(),
//                                 );
//                               });
//                             }
//                           },
//                           icon: const Icon(Icons.attach_file, size: 16),
//                           label: const Text("Agregar Archivos"),
//                           style: ElevatedButton.styleFrom(
//                             foregroundColor: Colors.white,
//                             backgroundColor: Colors.teal,
//                           ),
//                         ),
//                       ],
//                     ),

//                     Padding(
//                       padding: const EdgeInsets.only(top: 10.0),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: () async {
//                                 FilePickerResult? result = await FilePicker
//                                     .platform
//                                     .pickFiles(
//                                       type: FileType.audio,
//                                       allowMultiple: true,
//                                     );

//                                 if (result != null) {
//                                   setDialogState(() {
//                                     _rutasArchivosActuales.addAll(
//                                       result.paths.map((e) => e!).toList(),
//                                     );
//                                   });
//                                 }
//                               },
//                               icon: const Icon(Icons.mic, size: 18),
//                               label: const Text("Adjuntar Audio"),
//                               style: ElevatedButton.styleFrom(
//                                 foregroundColor: Colors.white,
//                                 backgroundColor: Colors.deepPurple,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 10),

//                     if (_rutasArchivosActuales.isEmpty)
//                       const Padding(
//                         padding: EdgeInsets.all(10.0),
//                         child: Text(
//                           "No hay archivos adjuntos.",
//                           style: TextStyle(
//                             color: Colors.grey,
//                             fontStyle: FontStyle.italic,
//                           ),
//                         ),
//                       )
//                     else
//                       Container(
//                         constraints: const BoxConstraints(maxHeight: 150),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey.shade300),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: ListView.builder(
//                           shrinkWrap: true,
//                           itemCount: _rutasArchivosActuales.length,
//                           itemBuilder: (context, index) {
//                             final path = _rutasArchivosActuales[index];
//                             final fileName = path.split('/').last;
//                             final isAudio =
//                                 path.toLowerCase().endsWith('.mp3') ||
//                                 path.toLowerCase().endsWith('.wav') ||
//                                 path.toLowerCase().endsWith('.m4a') ||
//                                 path.toLowerCase().endsWith('.aac');

//                             return ListTile(
//                               dense: true,
//                               leading: Icon(
//                                 isAudio
//                                     ? Icons.audiotrack
//                                     : Icons.insert_drive_file,
//                                 color: isAudio
//                                     ? Colors.deepPurple
//                                     : Colors.blueGrey,
//                               ),
//                               title: Text(
//                                 fileName,
//                                 style: const TextStyle(fontSize: 12),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               trailing: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   IconButton(
//                                     icon: const Icon(
//                                       Icons.open_in_new,
//                                       size: 20,
//                                     ),
//                                     tooltip: "Abrir archivo",
//                                     color: Colors.green,
//                                     onPressed: () async {
//                                       final result = await OpenFile.open(path);
//                                       if (result.type ==
//                                           ResultType.noAppToOpen) {
//                                         if (mounted) {
//                                           ScaffoldMessenger.of(
//                                             context,
//                                           ).showSnackBar(
//                                             const SnackBar(
//                                               content: Text(
//                                                 "No hay aplicación para abrir este archivo",
//                                               ),
//                                             ),
//                                           );
//                                         }
//                                       }
//                                     },
//                                   ),
//                                   IconButton(
//                                     icon: const Icon(
//                                       Icons.remove_circle,
//                                       color: Colors.red,
//                                       size: 20,
//                                     ),
//                                     onPressed: () {
//                                       setDialogState(() {
//                                         _rutasArchivosActuales.removeAt(index);
//                                       });
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(c),
//                 child: const Text("Cancelar"),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   final db = await DBManager.instance.database;
//                   String adjuntosString = _rutasArchivosActuales.join('|');

//                   final map = {
//                     'fecha': fCon.text,
//                     'hora': hCon.text,
//                     'asunto': aCon.text,
//                     'medio': mCon.text,
//                     'anotaciones': nCon.text,
//                     'imagen': _rutaImagenActual,
//                     'adjuntos': adjuntosString,
//                   };
//                   if (esEdicion) {
//                     await db.update(
//                       _tableName,
//                       map,
//                       where: 'id = ?',
//                       whereArgs: [item['id']],
//                     );
//                   } else {
//                     await db.insert(_tableName, map);
//                   }
//                   Navigator.pop(c);
//                   _cargarDatos();
//                 },
//                 child: const Text("Guardar"),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   void _verRegistro(Map<String, dynamic> item) {
//     final ThemeData theme = Theme.of(context);
//     List<String> archivos = [];
//     if (item['adjuntos'] != null) {
//       String str = item['adjuntos'] as String;
//       if (str.isNotEmpty) {
//         archivos = str.split('|');
//       }
//     }

//     showDialog(
//       context: context,
//       builder: (context) => Dialog(
//         backgroundColor: theme.colorScheme.surface,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: Container(
//           constraints: BoxConstraints(
//             maxWidth: MediaQuery.of(context).size.width * 0.9,
//             maxHeight: MediaQuery.of(context).size.height * 0.85,
//           ),
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "Detalle del Registro",
//                       style: theme.textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: theme.colorScheme.onSurface,
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close),
//                       onPressed: () => Navigator.pop(context),
//                       color: theme.colorScheme.onSurfaceVariant,
//                     ),
//                   ],
//                 ),
//                 Divider(color: theme.dividerColor),
//                 const SizedBox(height: 15),

//                 _detalleFila("Fecha:", item['fecha']),
//                 _detalleFila("Hora:", item['hora']),
//                 _detalleFila("Asunto:", item['asunto']),
//                 _detalleFila("Medio:", item['medio']),
//                 const SizedBox(height: 15),

//                 Text(
//                   "Anotaciones:",
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     fontWeight: FontWeight.bold,
//                     color: theme.colorScheme.onSurface,
//                   ),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   item['anotaciones']?.toString() ?? 'Sin anotaciones',
//                   style: theme.textTheme.bodyMedium?.copyWith(
//                     color: theme.colorScheme.onSurface,
//                     height: 1.4,
//                   ),
//                 ),
//                 const SizedBox(height: 25),

//                 if (item['imagen'] != null &&
//                     item['imagen'].toString().isNotEmpty)
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Evidencia Fotográfica:",
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                           color: theme.colorScheme.onSurface,
//                         ),
//                       ),
//                       const SizedBox(height: 10),
//                       Center(
//                         child: InkWell(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => Scaffold(
//                                   backgroundColor: Colors.black,
//                                   appBar: AppBar(
//                                     backgroundColor: Colors.transparent,
//                                     iconTheme: const IconThemeData(
//                                       color: Colors.white,
//                                     ),
//                                   ),
//                                   body: Center(
//                                     child: InteractiveViewer(
//                                       child: Image.file(
//                                         File(item['imagen'].toString()),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                           child: Container(
//                             height: 300,
//                             width: double.infinity,
//                             decoration: BoxDecoration(
//                               color: theme.brightness == Brightness.dark
//                                   ? const Color(0xFF2C2C2C)
//                                   : Colors.grey[200],
//                               border: Border.all(
//                                 color: theme.brightness == Brightness.dark
//                                     ? Colors.grey[700]!
//                                     : Colors.grey,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(12),
//                               child: Image.file(
//                                 File(item['imagen'].toString()),
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       Center(
//                         child: Text(
//                           "Toca la imagen para ampliar",
//                           style: TextStyle(
//                             color: theme.colorScheme.onSurfaceVariant,
//                             fontSize: 12,
//                             fontStyle: FontStyle.italic,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),

//                 if (archivos.isNotEmpty) ...[
//                   const SizedBox(height: 25),
//                   Text(
//                     "Archivos Adjuntos:",
//                     style: theme.textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                       color: theme.colorScheme.onSurface,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   ...archivos.map((path) {
//                     final fileName = path.split('/').last;
//                     final isAudio =
//                         path.toLowerCase().endsWith('.mp3') ||
//                         path.toLowerCase().endsWith('.wav') ||
//                         path.toLowerCase().endsWith('.m4a') ||
//                         path.toLowerCase().endsWith('.aac');
//                     return Card(
//                       margin: const EdgeInsets.symmetric(vertical: 4),
//                       child: ListTile(
//                         leading: Icon(
//                           isAudio ? Icons.audiotrack : Icons.description,
//                           color: isAudio ? Colors.deepPurple : Colors.teal,
//                         ),
//                         title: Text(
//                           fileName,
//                           style: const TextStyle(fontSize: 13),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.open_in_new, size: 20),
//                           onPressed: () async {
//                             final result = await OpenFile.open(path);
//                             if (result.type == ResultType.noAppToOpen &&
//                                 mounted) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text(
//                                     "No hay aplicación para abrir este archivo",
//                                   ),
//                                 ),
//                               );
//                             }
//                           },
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _detalleFila(String label, String? value) {
//     final ThemeData theme = Theme.of(context);
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 90,
//             child: Text(
//               label,
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 fontWeight: FontWeight.bold,
//                 color: theme.colorScheme.onSurface,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value?.toString() ?? '',
//               style: theme.textTheme.bodyMedium?.copyWith(
//                 color: theme.colorScheme.onSurface,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Libro de Inteligencia",
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(0xFF1A237E),
//         iconTheme: const IconThemeData(color: Colors.white),
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
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.greenAccent.withOpacity(0.6),
//                         blurRadius: 4,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 CircleAvatar(
//                   radius: 14,
//                   backgroundColor: Colors.white.withOpacity(0.2),
//                   child: Text(
//                     _nombreUsuario != null && _nombreUsuario!.isNotEmpty
//                         ? _nombreUsuario![0].toUpperCase()
//                         : "?",
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   _nombreUsuario ?? "Usuario",
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       _btn(
//                         "PDF",
//                         Colors.purple,
//                         Icons.picture_as_pdf,
//                         _exportarPDF,
//                       ),
//                       const SizedBox(width: 10),
//                       _btn(
//                         "Word",
//                         Colors.blue,
//                         Icons.description,
//                         _exportarWord,
//                       ),
//                       const SizedBox(width: 10),
//                       _btn(
//                         "Exportar",
//                         Colors.green,
//                         Icons.file_upload,
//                         _exportarExcel,
//                       ),
//                       const SizedBox(width: 10),
//                       _btn(
//                         "Importar",
//                         Colors.blueGrey,
//                         Icons.file_download,
//                         _importarExcel,
//                       ),
//                       const SizedBox(width: 10),
//                       _btn(
//                         "Nuevo",
//                         Colors.indigo,
//                         Icons.add,
//                         () => _abrirFormulario(),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 15),
//                 TextField(
//                   controller: _searchController,
//                   onChanged: _filtrarDatos,
//                   decoration: InputDecoration(
//                     hintText: "Buscar por asunto, medio, fecha...",
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[200],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 15),
//             Expanded(
//               child: _filteredData.isEmpty
//                   ? const Center(child: Text("No se encontraron registros"))
//                   : SingleChildScrollView(
//                       scrollDirection: Axis.vertical,
//                       child: Table(
//                         border: TableBorder.all(color: Colors.grey[300]!),
//                         columnWidths: const {
//                           0: FlexColumnWidth(1.2),
//                           1: FlexColumnWidth(0.8),
//                           2: FlexColumnWidth(1.5),
//                           3: FlexColumnWidth(1.5),
//                           4: FlexColumnWidth(4.5),
//                           5: FlexColumnWidth(1.5),
//                         },
//                         children: [
//                           _header(),
//                           ..._filteredData.map((m) => _row(m)),
//                         ],
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   TableRow _header() {
//     return TableRow(
//       decoration: const BoxDecoration(color: Color(0xFF2196F3)),
//       children: ['Fecha', 'Hora', 'Asunto', 'Medio', 'Anotación', 'Acciones']
//           .map(
//             (t) => Container(
//               padding: const EdgeInsets.all(10),
//               child: Text(
//                 t,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           )
//           .toList(),
//     );
//   }

//   TableRow _row(Map<String, dynamic> m) {
//     return TableRow(
//       children: [
//         _c(m['fecha']),
//         _c(m['hora']),
//         _c(m['asunto']),
//         _c(m['medio']),
//         Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: Text(
//             m['anotaciones']?.toString() ?? '',
//             style: const TextStyle(fontSize: 12),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             IconButton(
//               icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
//               onPressed: () => _verRegistro(m),
//             ),
//             IconButton(
//               icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
//               onPressed: () => _abrirFormulario(item: m),
//             ),
//             IconButton(
//               icon: const Icon(Icons.delete, color: Colors.red, size: 20),
//               onPressed: () async {
//                 final db = await DBManager.instance.database;
//                 await db.delete(
//                   _tableName,
//                   where: 'id = ?',
//                   whereArgs: [m['id']],
//                 );
//                 _cargarDatos();
//               },
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _c(dynamic valor) {
//     String texto = '';
//     if (valor != null) {
//       texto = valor.toString();
//     }
//     return Padding(
//       padding: const EdgeInsets.all(10),
//       child: Text(texto, style: const TextStyle(fontSize: 12)),
//     );
//   }

//   Widget _btn(String t, Color c, IconData i, VoidCallback o) =>
//       ElevatedButton.icon(
//         onPressed: o,
//         icon: Icon(i, size: 16, color: Colors.white),
//         label: Text(t, style: const TextStyle(color: Colors.white)),
//         style: ElevatedButton.styleFrom(backgroundColor: c),
//       );
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'
    hide ImageSource;
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:sqflite/sqflite.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../BD/db_manager.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ==============================================================================
// 1. CONFIGURACIÓN DEL PDF (Tamaño, estilos, anchos)
// ==============================================================================

final _pdfPageFormat = PdfPageFormat.letter.copyWith(
  marginBottom: 1.0 * PdfPageFormat.cm,
  marginTop: 1.0 * PdfPageFormat.cm,
  marginLeft: 0.5 * PdfPageFormat.cm,
  marginRight: 0.5 * PdfPageFormat.cm,
);

final _headerStyle = pw.TextStyle(
  color: PdfColors.white,
  fontWeight: pw.FontWeight.bold,
  fontSize: 10,
);

final _cellStyle = const pw.TextStyle(fontSize: 9);

final _columnWidths = [
  const pw.FixedColumnWidth(65), // Fecha
  const pw.FixedColumnWidth(45), // Hora
  const pw.FlexColumnWidth(2), // Asunto
  const pw.FlexColumnWidth(1.5), // Medio
  const pw.FlexColumnWidth(4), // Anotaciones
  const pw.FixedColumnWidth(25), // Img
  const pw.FixedColumnWidth(25), // Adj
];

// Helpers de construcción de celdas
pw.Widget _buildCenterCell(String text, pw.TextStyle style) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
  );
}

pw.Widget _buildDataCell(String text, pw.TextStyle style) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: style,
      maxLines: null,
      overflow: pw.TextOverflow.clip,
    ),
  );
}

/// ==============================================================================
// FUNCIÓN PRINCIPAL DE GENERACIÓN (CORRE EN ISOLATE)
// ==============================================================================
Future<void> _generarPdfEnIsolate(Map<String, dynamic> payload) async {
  final List<List<Map<String, dynamic>>> chunks =
      List<List<Map<String, dynamic>>>.from(payload['chunks']);
  final String outputPath = payload['ruta'];

  final pdf = pw.Document();

  // Iteramos sobre cada "chunk" de datos
  for (var i = 0; i < chunks.length; i++) {
    final batch = chunks[i];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: _pdfPageFormat,
        header: (context) => pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "INTELIGENCIA - CALIPSO",
                  style: pw.TextStyle(
                    color: PdfColors.grey700,
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Página ${context.pageNumber}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              "REPORTE LIBRO DE INTELIGENCIA",
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14,
                color: PdfColors.indigo900,
              ),
            ),
            pw.SizedBox(height: 10),
          ],
        ),
        build: (context) {
          final contenido = <pw.Widget>[
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              columnWidths: {
                0: _columnWidths[0],
                1: _columnWidths[1],
                2: _columnWidths[2],
                3: _columnWidths[3],
                4: _columnWidths[4],
                5: _columnWidths[5],
                6: _columnWidths[6],
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.indigo900,
                  ),
                  children: [
                    _buildCenterCell('Fecha', _headerStyle),
                    _buildCenterCell('Hora', _headerStyle),
                    _buildCenterCell('Asunto', _headerStyle),
                    _buildCenterCell('Medio', _headerStyle),
                    _buildCenterCell('Anotaciones', _headerStyle),
                    _buildCenterCell('Img', _headerStyle),
                    _buildCenterCell('Adj', _headerStyle),
                  ],
                ),
                ...batch.asMap().entries.map((entry) {
                  final j = entry.key;
                  final m = entry.value;
                  final rowColor = j.isOdd
                      ? const pw.BoxDecoration(color: PdfColors.grey100)
                      : const pw.BoxDecoration();

                  return pw.TableRow(
                    decoration: rowColor,
                    children: [
                      _buildDataCell(m['fecha']?.toString() ?? '', _cellStyle),
                      _buildDataCell(m['hora']?.toString() ?? '', _cellStyle),
                      _buildDataCell(m['asunto']?.toString() ?? '', _cellStyle),
                      _buildDataCell(m['medio']?.toString() ?? '', _cellStyle),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text(
                          m['anotaciones']?.toString() ?? '',
                          style: _cellStyle,
                          softWrap: true,
                        ),
                      ),
                      _buildCenterCell(
                        m['imagen']?.toString() ?? 'No',
                        _cellStyle,
                      ),
                      _buildCenterCell(
                        m['adjuntos']?.toString() ?? 'No',
                        _cellStyle,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];

          // Solo en el último chunk añadimos la firma y huella
          if (i == chunks.length - 1) {
            contenido.add(pw.SizedBox(height: 30));
            contenido.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 200,
                        height: 1,
                        color: PdfColors.black,
                      ),
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
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 1,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        "Huella",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          return contenido;
        },
      ),
    );
  }

  // Guardar al final
  final file = File(outputPath);
  await file.writeAsBytes(await pdf.save());
}

Future<File> _generarWordFileInteligencia(
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
  buffer.writeln('<title>Reporte Inteligencia</title></head><body>');

  // 2. TÍTULO
  buffer.writeln(
    '<h1 style="text-align: center; font-family: Arial; font-size: 20pt; font-weight: bold; margin-bottom: 20px;">REPORTE LIBRO DE INTELIGENCIA</h1>',
  );

  // 3. TABLA PRINCIPAL
  buffer.writeln(
    '<table style="width: 100%; border-collapse: collapse; border: 1px solid #000000; font-family: Arial; font-size: 10pt;">',
  );

  // Encabezados con anchos optimizados: Img y Adj bajan al 4%, Anotaciones sube al 43%
  buffer.writeln('<tr>');
  buffer.writeln(
    '<th style="width: 10%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Fecha</th>',
  );
  buffer.writeln(
    '<th style="width: 8%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Hora</th>',
  );
  buffer.writeln(
    '<th style="width: 22%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Asunto</th>',
  );
  buffer.writeln(
    '<th style="width: 11%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Medio</th>',
  );
  buffer.writeln(
    '<th style="width: 43%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Anotaciones</th>',
  );
  buffer.writeln(
    '<th style="width: 4%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Img</th>',
  );
  buffer.writeln(
    '<th style="width: 4%; background-color: #2196F3; color: white; border: 1px solid #000000; padding: 8px; text-align: center;">Adj</th>',
  );
  buffer.writeln('</tr>');

  // 4. FILAS DE DATOS (Sin width interno para heredar correctamente la cabecera)
  for (var m in data) {
    String anotacionesRaw = (m['anotaciones']?.toString() ?? '').replaceAll(
      '\n',
      '<br>',
    );

    // Escapar HTML básico
    String fecha = (m['fecha']?.toString() ?? '').replaceAll('<', '&lt;');
    String hora = (m['hora']?.toString() ?? '').replaceAll('<', '&lt;');
    String asunto = (m['asunto']?.toString() ?? '').replaceAll('<', '&lt;');
    String medio = (m['medio']?.toString() ?? '').replaceAll('<', '&lt;');
    String anotaciones = anotacionesRaw.replaceAll('<', '&lt;');

    String imagen = (m['imagen'] != null && m['imagen'].toString().isNotEmpty)
        ? 'Sí'
        : 'No';
    String adjuntos =
        (m['adjuntos'] != null && m['adjuntos'].toString().isNotEmpty)
        ? 'Sí'
        : 'No';

    buffer.writeln('<tr>');
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: center;">$fecha</td>',
    );
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: center;">$hora</td>',
    );
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: left;">$asunto</td>',
    );
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: left;">$medio</td>',
    );
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: left;">$anotaciones</td>',
    );
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: center;">$imagen</td>',
    );
    buffer.writeln(
      '<td style="border: 1px solid #000000; padding: 6px; text-align: center;">$adjuntos</td>',
    );
    buffer.writeln('</tr>');
  }

  buffer.writeln('</table>');
  buffer.writeln('</body></html>');

  // 5. Guardar
  final tempDir = await getTemporaryDirectory();
  final filePath = '${tempDir.path}/Reporte_Inteligencia.doc';
  final file = File(filePath);
  await file.writeAsBytes(const Utf8Encoder().convert(buffer.toString()));

  return file;
}

class InteligenciaScreen extends StatefulWidget {
  const InteligenciaScreen({super.key});
  @override
  State<InteligenciaScreen> createState() => _InteligenciaScreenState();
}

class _InteligenciaScreenState extends State<InteligenciaScreen> {
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];
  final String _tableName = 'inteligencia';

  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

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
      print("Error cargando usuario en inteligencia: $e");
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

  void _filtrarDatos(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredData = _allData;
      } else {
        _filteredData = _allData.where((item) {
          final asunto = (item['asunto']?.toString() ?? '').toLowerCase();
          final medio = (item['medio']?.toString() ?? '').toLowerCase();
          final anotaciones = (item['anotaciones']?.toString() ?? '')
              .toLowerCase();
          final fecha = (item['fecha']?.toString() ?? '').toLowerCase();
          final searchLower = query.toLowerCase();

          return asunto.contains(searchLower) ||
              medio.contains(searchLower) ||
              anotaciones.contains(searchLower) ||
              fecha.contains(searchLower);
        }).toList();
      }
    });
  }

  Future<void> _exportarPDF() async {
    try {
      // 1. Mostrar Loader
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

      // 3. Consulta paginada directa a la base de datos
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

        final cleanBatch = batch.map((m) {
          return {
            'fecha': m['fecha']?.toString() ?? '',
            'hora': m['hora']?.toString() ?? '',
            'asunto': m['asunto']?.toString() ?? '',
            'medio': m['medio']?.toString() ?? '',
            'anotaciones': m['anotaciones']?.toString() ?? '',
            'imagen': (m['imagen']?.toString().isNotEmpty ?? false)
                ? 'Sí'
                : 'No',
            'adjuntos': (m['adjuntos']?.toString().isNotEmpty ?? false)
                ? 'Sí'
                : 'No',
          };
        }).toList();

        allChunks.add(cleanBatch);
        offset += chunkSize;
      }

      // 4. Ruta de salida
      final dir = await getApplicationDocumentsDirectory();
      final String fileName =
          'Reporte_Inteligencia_Masivo_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir.path}/$fileName');

      // 5. Ejecutar en Isolate
      await compute(_generarPdfEnIsolate, {
        'chunks': allChunks,
        'ruta': file.path,
      });

      // 6. Finalizar
      if (mounted) Navigator.pop(context); // Cerrar loader

      if (mounted) {
        // CAMBIO AQUÍ: Navegar al visor en lugar de usar OpenFile
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
      debugPrint("Error PDF Masivo: $e");
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

  // FUNCIÓN EXPORTAR WORD (Usa Visor Interno)
  Future<void> _exportarWord() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      final data = _filteredData
          .map(
            (m) => {
              'fecha': m['fecha']?.toString() ?? '',
              'hora': m['hora']?.toString() ?? '',
              'asunto': m['asunto']?.toString() ?? '',
              'medio': m['medio']?.toString() ?? '',
              'anotaciones': m['anotaciones']?.toString() ?? '',
              'imagen': m['imagen'],
              'adjuntos': m['adjuntos'],
            },
          )
          .toList();

      // Generar archivo Word
      final file = await _generarWordFileInteligencia(data);

      if (mounted) Navigator.pop(context);

      // CAMBIO AQUÍ: Navegar al visor de Word en lugar de abrir externamente
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocxViewerScreen(filePath: file.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      debugPrint("Error Word Inteligencia: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo generar el Word: $e")),
        );
      }
    }
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

        for (var table in excel.tables.keys) {
          var rows = excel.tables[table]!.rows;
          for (int i = 1; i < rows.length; i++) {
            var row = rows[i];
            if (row.length >= 5) {
              await db.insert(_tableName, {
                'fecha': row[0]?.value.toString() ?? '',
                'hora': row[1]?.value.toString() ?? '',
                'asunto': row[2]?.value.toString() ?? '',
                'medio': row[3]?.value.toString() ?? '',
                'anotaciones': row[4]?.value.toString() ?? '',
                'imagen': '',
                'adjuntos': '',
              });
            }
          }
        }
        _cargarDatos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Datos importados con éxito")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al importar: $e")));
    }
  }

  Future<void> _exportarExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Inteligencia'];
    sheet.appendRow([
      TextCellValue('Fecha'),
      TextCellValue('Hora'),
      TextCellValue('Asunto'),
      TextCellValue('Medio'),
      TextCellValue('Anotaciones'),
      TextCellValue('Imagen'),
      TextCellValue('Adjuntos'),
    ]);
    for (var m in _filteredData) {
      sheet.appendRow([
        TextCellValue(m['fecha']),
        TextCellValue(m['hora']),
        TextCellValue(m['asunto']),
        TextCellValue(m['medio']),
        TextCellValue(m['anotaciones']),
        TextCellValue(m['imagen']?.toString().isNotEmpty == true ? 'Sí' : 'No'),
        TextCellValue(
          m['adjuntos']?.toString().isNotEmpty == true ? 'Sí' : 'No',
        ),
      ]);
    }
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/Reporte_Inteligencia.xlsx';
    final bytes = excel.save();
    if (bytes != null) {
      await File(filePath).writeAsBytes(bytes);
      await Share.shareXFiles([XFile(filePath)], text: 'Excel Inteligencia');
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
    final mCon = TextEditingController(text: esEdicion ? item['medio'] : '');
    final nCon = TextEditingController(
      text: esEdicion ? item['anotaciones'] : '',
    );

    String? _rutaImagenActual = esEdicion ? item['imagen'] : null;

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
            title: Text(
              esEdicion ? "Editar Inteligencia" : "Nuevo Registro Inteligencia",
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
                      controller: mCon,
                      decoration: const InputDecoration(
                        labelText: "Medio",
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
                    const SizedBox(height: 15),

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Evidencia Fotográfica:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: _rutaImagenActual != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.file(
                                    File(_rutaImagenActual!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (BuildContext bc) {
                                    return SafeArea(
                                      child: Wrap(
                                        children: <Widget>[
                                          ListTile(
                                            leading: const Icon(
                                              Icons.camera_alt,
                                            ),
                                            title: const Text('Cámara'),
                                            onTap: () async {
                                              Navigator.pop(bc);
                                              final XFile? photo = await _picker
                                                  .pickImage(
                                                    source: ImageSource.camera,
                                                    imageQuality: 50,
                                                  );
                                              if (photo != null) {
                                                setDialogState(() {
                                                  _rutaImagenActual =
                                                      photo.path;
                                                });
                                              }
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.photo_library,
                                            ),
                                            title: const Text('Galería'),
                                            onTap: () async {
                                              Navigator.pop(bc);
                                              final XFile? photo = await _picker
                                                  .pickImage(
                                                    source: ImageSource.gallery,
                                                    imageQuality: 50,
                                                  );
                                              if (photo != null) {
                                                setDialogState(() {
                                                  _rutaImagenActual =
                                                      photo.path;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.add_a_photo, size: 18),
                              label: const Text("Adjuntar Foto"),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.indigo,
                              ),
                            ),
                            if (_rutaImagenActual != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: TextButton(
                                  onPressed: () {
                                    setDialogState(() {
                                      _rutaImagenActual = null;
                                    });
                                  },
                                  child: const Text(
                                    "Eliminar Foto",
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                FilePickerResult? result = await FilePicker
                                    .platform
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
                        ],
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
                                path.toLowerCase().endsWith('.m4a') ||
                                path.toLowerCase().endsWith('.aac');

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
                onPressed: () async {
                  final db = await DBManager.instance.database;
                  String adjuntosString = _rutasArchivosActuales.join('|');

                  final map = {
                    'fecha': fCon.text,
                    'hora': hCon.text,
                    'asunto': aCon.text,
                    'medio': mCon.text,
                    'anotaciones': nCon.text,
                    'imagen': _rutaImagenActual,
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
                child: const Text("Guardar"),
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
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 15),

                _detalleFila("Fecha:", item['fecha']),
                _detalleFila("Hora:", item['hora']),
                _detalleFila("Asunto:", item['asunto']),
                _detalleFila("Medio:", item['medio']),
                const SizedBox(height: 15),

                Text(
                  "Anotaciones:",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item['anotaciones']?.toString() ?? 'Sin anotaciones',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 25),

                if (item['imagen'] != null &&
                    item['imagen'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Evidencia Fotográfica:",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  backgroundColor: Colors.black,
                                  appBar: AppBar(
                                    backgroundColor: Colors.transparent,
                                    iconTheme: const IconThemeData(
                                      color: Colors.white,
                                    ),
                                  ),
                                  body: Center(
                                    child: InteractiveViewer(
                                      child: Image.file(
                                        File(item['imagen'].toString()),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF2C2C2C)
                                  : Colors.grey[200],
                              border: Border.all(
                                color: theme.brightness == Brightness.dark
                                    ? Colors.grey[700]!
                                    : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(item['imagen'].toString()),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Center(
                        child: Text(
                          "Toca la imagen para ampliar",
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),

                if (archivos.isNotEmpty) ...[
                  const SizedBox(height: 25),
                  Text(
                    "Archivos Adjuntos:",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...archivos.map((path) {
                    final fileName = path.split('/').last;
                    final isAudio =
                        path.toLowerCase().endsWith('.mp3') ||
                        path.toLowerCase().endsWith('.wav') ||
                        path.toLowerCase().endsWith('.m4a') ||
                        path.toLowerCase().endsWith('.aac');
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
                            if (result.type == ResultType.noAppToOpen &&
                                mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "No hay aplicación para abrir este archivo",
                                  ),
                                ),
                              );
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
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
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
          "Libro de Inteligencia",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
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
                hintText: "Buscar en Inteligencia...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filtrarDatos,
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  columnWidths: const {
                    0: FlexColumnWidth(1.0),
                    1: FlexColumnWidth(0.8),
                    2: FlexColumnWidth(1.4),
                    3: FlexColumnWidth(1.1),
                    4: FlexColumnWidth(2.4),
                    5: FlexColumnWidth(0.4),
                    6: FlexColumnWidth(1.0),
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
      children:
          ['Fecha', 'Hora', 'Asunto', 'Medio', 'Anotaciones', 'Img', 'Acciones']
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
      _c(m['medio']?.toString() ?? ''),
      _c(m['anotaciones']?.toString() ?? ''),
      _c((m['imagen']?.toString().isNotEmpty == true) ? 'Sí' : '-'),
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

// ==============================================================================
// CLASE VISOR DE PDF

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
      await Share.shareXFiles([
        XFile(widget.filePath),
      ], text: 'Reporte de Inteligencia');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
            : const Text('Visor de Reporte'),
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
      ], text: 'Reporte Inteligencia (Word)');
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
