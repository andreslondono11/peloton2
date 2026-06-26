// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:sqflite/sqflite.dart';
// import 'package:peloton/provider/apptex.dart';
// import '../BD/db_manager.dart';

// class ItemArmamento {
//   int? id;
//   String clase;
//   int cargo;
//   int mano;
//   int deposito;
//   int total;
//   String observaciones;

//   ItemArmamento({
//     this.id,
//     required this.clase,
//     this.cargo = 0,
//     this.mano = 0,
//     this.deposito = 0,
//     this.total = 0,
//     this.observaciones = "",
//   });

//   Map<String, dynamic> toMap() => {
//     'clase': clase,
//     'cargo': cargo,
//     'mano': mano,
//     'deposito': deposito,
//     'total': total,
//     'observaciones': observaciones,
//   };

//   factory ItemArmamento.fromMap(Map<String, dynamic> map) => ItemArmamento(
//     id: map['id'],
//     clase: map['clase'] ?? "",
//     cargo: map['cargo'] ?? 0,
//     mano: map['mano'] ?? 0,
//     deposito: map['deposito'] ?? 0,
//     total: map['total'] ?? 0,
//     observaciones: map['observaciones'] ?? "",
//   );
// }

// class ParteArmamentoScreen extends StatefulWidget {
//   const ParteArmamentoScreen({super.key});

//   @override
//   State<ParteArmamentoScreen> createState() => _ParteArmamentoScreenState();
// }

// class _ParteArmamentoScreenState extends State<ParteArmamentoScreen> {
//   bool modoEdicion = false;
//   List<ItemArmamento> inventario = [];
//   bool cargando = true;

//   final List<String> nombresOficiales = [
//     "FUSIL ACE 23",
//     "AMETRALLADORA 7.62",
//     "AMETRALLADORA 5.56",
//     "MGL 40MM",
//     "MORTERO 60 MM",
//     "PISTOLA PRIETTO 9MM",
//     "REMINTONG 7.62",
//     "REMINTONG .50",
//     "MUN. 5,56MM",
//     "MUN. 7,62MM",
//     "MUN. 5,56MM ESLAB",
//     "MUN. 7,62MM ESLAB",
//     "MUN. SUBSÓNICA",
//     "MUN. 9MM",
//     "GRANADA 60 MM",
//     "GRANADA 40 MM",
//     "GRANADA IM 26",
//     "MIRA MEPRO",
//     "MIRA MINROD",
//     "LENTE TASCO",
//     "PROV. 5.56",
//     "PROV. 9MM",
//     "PROV. TAP",
//     "CASCO KEBLAC",
//     "CAÑON REP. 7,62",
//     "CAÑON REP. 5,56",
//     "AVN",
//     "TRAMPA ILUM.",
//     "GRANADA HUMO",
//     "GRANADA LACRI.",
//     "BENGALAS",
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _cargarDatos();
//   }

//   Future<void> _cargarDatos() async {
//     try {
//       final db = await DBManager.instance.database;
//       final List<Map<String, dynamic>> res = await db.query('armamento');

//       List<ItemArmamento> datosDb = res
//           .map((m) => ItemArmamento.fromMap(m))
//           .toList();
//       List<ItemArmamento> listaFinal = [];

//       for (var nombre in nombresOficiales) {
//         var itemExistente = datosDb.firstWhere(
//           (element) => element.clase == nombre,
//           orElse: () => ItemArmamento(clase: nombre),
//         );
//         listaFinal.add(itemExistente);
//       }

//       if (mounted) {
//         setState(() {
//           inventario = listaFinal;
//           cargando = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           inventario = nombresOficiales
//               .map((n) => ItemArmamento(clase: n))
//               .toList();
//           cargando = false;
//         });
//       }
//     }
//   }

//   Future<void> _guardarCambios() async {
//     final db = await DBManager.instance.database;
//     final batch = db.batch();
//     for (var item in inventario) {
//       // Ajuste: El total ahora solo suma mano + deposito
//       item.total = item.mano + item.deposito;
//       batch.insert(
//         'armamento',
//         item.toMap(),
//         conflictAlgorithm: ConflictAlgorithm.replace,
//       );
//     }
//     await batch.commit(noResult: true);
//     AppStyles.showSnackBar(context, "✅ Inventario Actualizado");
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppStyles.isDark(context)
//           ? const Color(0xFF0D1117)
//           : Colors.white,
//       appBar: AppBar(
//         title: const Text(
//           "PARTE DE ARMAMENTO",
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             letterSpacing: 1.2,
//           ),
//         ),
//         backgroundColor: AppStyles.primaryColor(context),
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         elevation: 1,
//         toolbarHeight: 50,
//       ),
//       body: cargando
//           ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
//           : Column(
//               children: [
//                 Expanded(
//                   child: Padding(
//                     padding: const EdgeInsets.all(12.0),
//                     child: Container(
//                       decoration: AppStyles.tableDecoration(context),
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: SingleChildScrollView(
//                           child: SizedBox(
//                             width: double.infinity,
//                             child: Theme(
//                               data: Theme.of(context).copyWith(
//                                 dataTableTheme: AppStyles.tableTheme(context),
//                               ),
//                               child: DataTable(
//                                 headingRowHeight: 40,
//                                 dataRowMinHeight: 35,
//                                 dataRowMaxHeight: 45,
//                                 columnSpacing: 20,
//                                 columns: _buildColumns(),
//                                 rows: inventario
//                                     .map((item) => _filaEditable(item))
//                                     .toList(),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//                 _buildControlBar(),
//               ],
//             ),
//     );
//   }

//   List<DataColumn> _buildColumns() {
//     const s = TextStyle(
//       color: Colors.white,
//       fontWeight: FontWeight.bold,
//       fontSize: 12,
//     );
//     return const [
//       DataColumn(
//         label: Expanded(child: Text("DESCRIPCIÓN MATERIAl", style: s)),
//       ),
//       DataColumn(label: Text("CARGO", style: s)),
//       DataColumn(label: Text("MANO", style: s)),
//       DataColumn(label: Text("DEP", style: s)),
//       DataColumn(label: Text("TOTAL", style: s)),
//       DataColumn(label: Text("OBSERVACIONES", style: s)),
//     ];
//   }

//   DataRow _filaEditable(ItemArmamento item) {
//     final cellStyle = AppStyles.tableCell(context).copyWith(fontSize: 12);
//     return DataRow(
//       cells: [
//         DataCell(
//           Text(
//             item.clase,
//             style: cellStyle.copyWith(fontWeight: FontWeight.w600),
//           ),
//         ),
//         DataCell(
//           modoEdicion
//               ? _input(item.cargo, (v) => setState(() => item.cargo = v))
//               : Text("${item.cargo}", style: cellStyle),
//         ),
//         DataCell(
//           modoEdicion
//               ? _input(item.mano, (v) => setState(() => item.mano = v))
//               : Text("${item.mano}", style: cellStyle),
//         ),
//         DataCell(
//           modoEdicion
//               ? _input(item.deposito, (v) => setState(() => item.deposito = v))
//               : Text("${item.deposito}", style: cellStyle),
//         ),
//         DataCell(
//           Text(
//             // Ajuste visual: Solo suma mano + deposito
//             "${item.mano + item.deposito}",
//             style: cellStyle.copyWith(
//               color: Colors.blueAccent,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ),
//         DataCell(
//           modoEdicion
//               ? _inputStr(item.observaciones, (v) => item.observaciones = v)
//               : Text(
//                   item.observaciones,
//                   style: cellStyle.copyWith(
//                     fontSize: 11,
//                     fontStyle: FontStyle.italic,
//                   ),
//                 ),
//         ),
//       ],
//     );
//   }

//   Widget _input(int init, Function(int) save) => Container(
//     width: 50,
//     decoration: BoxDecoration(
//       color: Colors.blue.withOpacity(0.05),
//       borderRadius: BorderRadius.circular(4),
//     ),
//     child: TextFormField(
//       initialValue: "$init",
//       keyboardType: TextInputType.number,
//       textAlign: TextAlign.center,
//       style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
//       decoration: const InputDecoration(
//         isDense: true,
//         border: InputBorder.none,
//       ),
//       onChanged: (v) => save(int.tryParse(v) ?? 0),
//     ),
//   );

//   Widget _inputStr(String init, Function(String) save) => SizedBox(
//     width: 150,
//     child: TextFormField(
//       initialValue: init,
//       style: const TextStyle(fontSize: 12),
//       decoration: const InputDecoration(
//         isDense: true,
//         hintText: "Escribir...",
//         hintStyle: TextStyle(fontSize: 10),
//       ),
//       onChanged: (v) => save(v),
//     ),
//   );

//   Widget _buildControlBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       color: AppStyles.isDark(context)
//           ? const Color(0xFF161B22)
//           : Colors.grey[200],
//       child: SafeArea(
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             _btnAction(
//               Icons.picture_as_pdf,
//               "EXPORTAR PDF",
//               Colors.red[800]!,
//               _exportarPDF,
//             ),
//             const SizedBox(width: 15),
//             _btnAction(
//               modoEdicion ? Icons.save_rounded : Icons.edit_note_rounded,
//               modoEdicion ? "FINALIZAR Y GUARDAR" : "EDITAR REGISTROS",
//               modoEdicion
//                   ? Colors.green[700]!
//                   : AppStyles.primaryColor(context),
//               () {
//                 if (modoEdicion) _guardarCambios();
//                 setState(() => modoEdicion = !modoEdicion);
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _btnAction(
//     IconData icon,
//     String label,
//     Color color,
//     VoidCallback onTap,
//   ) {
//     return ElevatedButton.icon(
//       onPressed: onTap,
//       icon: Icon(icon, size: 18, color: Colors.white),
//       label: Text(
//         label,
//         style: const TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.bold,
//           color: Colors.white,
//         ),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: color,
//         minimumSize: const Size(150, 40),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
//         elevation: 2,
//       ),
//     );
//   }

//   Future<void> _exportarPDF() async {
//     final pdf = pw.Document();
//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (context) => [
//           pw.Header(
//             level: 0,
//             child: pw.Text(
//               "PARTE DE ARMAMENTO ",
//               style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
//             ),
//           ),
//           pw.SizedBox(height: 15),
//           pw.TableHelper.fromTextArray(
//             headers: [
//               'MATERIAl',
//               'CARGO',
//               'MANO',
//               'DEP',
//               'TOTAL',
//               'OBSERVACIONES',
//             ],
//             headerStyle: pw.TextStyle(
//               color: PdfColors.white,
//               fontWeight: pw.FontWeight.bold,
//               fontSize: 10,
//             ),
//             headerDecoration: const pw.BoxDecoration(color: PdfColors.grey900),
//             data: inventario
//                 .map(
//                   (i) => [
//                     i.clase,
//                     i.cargo,
//                     i.mano,
//                     i.deposito,
//                     (i.mano + i.deposito), // Ajuste en el PDF
//                     i.observaciones,
//                   ],
//                 )
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//     final dir = await getTemporaryDirectory();
//     final file = File('${dir.path}/Reporte_Armamento.pdf');
//     await file.writeAsBytes(await pdf.save());
//     await Share.shareXFiles([XFile(file.path)]);
//   }
// }
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sqflite/sqflite.dart';
import 'package:excel/excel.dart'
    show Excel, Sheet, TextCellValue, IntCellValue, CellValue, Data; // ✅ NUEVO
import 'package:file_picker/file_picker.dart'; // ✅ NUEVO
import 'package:peloton/provider/apptex.dart';
import '../BD/db_manager.dart';

class ItemArmamento {
  int? id;
  String clase;
  int cargo;
  int mano;
  int deposito;
  int total;
  String observaciones;

  ItemArmamento({
    this.id,
    required this.clase,
    this.cargo = 0,
    this.mano = 0,
    this.deposito = 0,
    this.total = 0,
    this.observaciones = "",
  });

  Map<String, dynamic> toMap() => {
    'clase': clase,
    'cargo': cargo,
    'mano': mano,
    'deposito': deposito,
    'total': total,
    'observaciones': observaciones,
  };

  factory ItemArmamento.fromMap(Map<String, dynamic> map) => ItemArmamento(
    id: map['id'],
    clase: map['clase'] ?? "",
    cargo: map['cargo'] ?? 0,
    mano: map['mano'] ?? 0,
    deposito: map['deposito'] ?? 0,
    total: map['total'] ?? 0,
    observaciones: map['observaciones'] ?? "",
  );
}

class ParteArmamentoScreen extends StatefulWidget {
  const ParteArmamentoScreen({super.key});

  @override
  State<ParteArmamentoScreen> createState() => _ParteArmamentoScreenState();
}

class _ParteArmamentoScreenState extends State<ParteArmamentoScreen> {
  bool modoEdicion = false;
  List<ItemArmamento> inventario = [];
  bool cargando = true;
  String? _nombreUsuario;
  bool _isProcessing = false; // ✅ NUEVO

  final List<String> nombresOficiales = [
    "FUSIL ACE 23",
    "AMETRALLADORA 7.62",
    "AMETRALLADORA 5.56",
    "MGL 40MM",
    "MORTERO 60 MM",
    "PISTOLA PRIETTO 9MM",
    "REMINTONG 7.62",
    "REMINTONG .50",
    "MUN. 5,56MM",
    "MUN. 7,62MM",
    "MUN. 5,56MM ESLAB",
    "MUN. 7,62MM ESLAB",
    "MUN. SUBSÓNICA",
    "MUN. 9MM",
    "GRANADA 60 MM",
    "GRANADA 40 MM",
    "GRANADA IM 26",
    "MIRA MEPRO",
    "MIRA MINROD",
    "LENTE TASCO",
    "PROV. 5.56",
    "PROV. 9MM",
    "PROV. TAP",
    "CASCO KEBLAC",
    "CAÑON REP. 7,62",
    "CAÑON REP. 5,56",
    "AVN",
    "TRAMPA ILUM.",
    "GRANADA HUMO",
    "GRANADA LACRI.",
    "BENGALAS",
  ];

  // ✅ PLANTILLA ÚNICA EXCEL
  static const List<Map<String, dynamic>> _columnasExcel = [
    {'header': 'DESCRIPCIÓN MATERIAl', 'key': 'clase', 'type': 'text'},
    {'header': 'CARGO', 'key': 'cargo', 'type': 'int'},
    {'header': 'MANO', 'key': 'mano', 'type': 'int'},
    {'header': 'DEP', 'key': 'deposito', 'type': 'int'},
    {'header': 'TOTAL', 'key': 'total', 'type': 'int'},
    {'header': 'OBSERVACIONES', 'key': 'observaciones', 'type': 'text'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
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
          setState(() => _nombreUsuario = usuario.first['nombres'] as String?);
        }
      }
    } catch (e) {
      print("Error cargando usuario en armamento: $e");
    }
  }

  Future<void> _cargarDatos() async {
    try {
      final db = await DBManager.instance.database;
      final List<Map<String, dynamic>> res = await db.query('armamento');
      List<ItemArmamento> datosDb = res
          .map((m) => ItemArmamento.fromMap(m))
          .toList();
      List<ItemArmamento> listaFinal = [];

      for (var nombre in nombresOficiales) {
        var itemExistente = datosDb.firstWhere(
          (element) => element.clase == nombre,
          orElse: () => ItemArmamento(clase: nombre),
        );
        listaFinal.add(itemExistente);
      }

      if (mounted) {
        setState(() {
          inventario = listaFinal;
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          inventario = nombresOficiales
              .map((n) => ItemArmamento(clase: n))
              .toList();
          cargando = false;
        });
      }
    }
  }

  Future<void> _guardarCambios() async {
    final db = await DBManager.instance.database;
    final batch = db.batch();
    for (var item in inventario) {
      item.total = item.mano + item.deposito;
      batch.insert(
        'armamento',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    AppStyles.showSnackBar(context, "✅ Inventario Actualizado");
  }

  // ✅ NUEVO: EXPORTAR EXCEL
  Future<void> _exportarExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Parte_Armamento'];
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      List<CellValue> headers = _columnasExcel
          .map((col) => TextCellValue(col['header'] as String))
          .toList();
      sheetObject.appendRow(headers);

      for (var item in inventario) {
        List<CellValue> fila = [];
        for (var col in _columnasExcel) {
          if (col['key'] == 'total') {
            fila.add(IntCellValue(item.mano + item.deposito));
          } else if (col['type'] == 'text') {
            fila.add(TextCellValue(item.toMap()[col['key']]?.toString() ?? ''));
          } else {
            fila.add(IntCellValue(item.toMap()[col['key']] ?? 0));
          }
        }
        sheetObject.appendRow(fila);
      }

      var fileBytes = excel.save();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/Parte_Armamento.xlsx');
      await file.writeAsBytes(fileBytes!);
      await Share.shareXFiles([XFile(file.path)], text: 'Parte de Armamento');
    } catch (e) {
      AppStyles.showSnackBar(
        context,
        "Error al exportar Excel: $e",
        isError: true,
      );
    }
  }

  // ✅ NUEVO: IMPORTAR EXCEL
  Future<void> _importarExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isProcessing = true);

        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        var table =
            excel.tables['Parte_Armamento'] ?? excel.tables.values.first;

        if (table == null || table.rows.isEmpty) {
          AppStyles.showSnackBar(
            context,
            "El archivo no tiene datos válidos.",
            isError: true,
          );
          setState(() => _isProcessing = false);
          return;
        }

        // Leer filas ignorando encabezado
        for (int i = 1; i < table.rows.length; i++) {
          var row = table.rows[i];
          if (row.isEmpty || row[0]?.value == null) continue;

          String claseImportada = _getCellValue(row[0]);

          // Buscar si el material ya existe en nuestra lista fija
          var itemExistente = inventario.firstWhere(
            (item) => item.clase == claseImportada,
            orElse: () => ItemArmamento(clase: claseImportada),
          );

          // Actualizar valores (Saltamos el índice 0 'clase' y 4 'total' porque se calcula solo)
          itemExistente.cargo = _getCellIntValue(row[1]);
          itemExistente.mano = _getCellIntValue(row[2]);
          itemExistente.deposito = _getCellIntValue(row[3]);
          itemExistente.observaciones = _getCellValue(row[5]);
        }

        // Como se importó a memoria, forzamos a guardar los cambios en BD
        await _guardarCambiosSilencioso();

        setState(() => _isProcessing = false);
        AppStyles.showSnackBar(
          context,
          "✅ Excel importado y guardado correctamente.",
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      AppStyles.showSnackBar(context, "Error al importar: $e", isError: true);
    }
  }

  // Guardado silencioso usado por la importación
  Future<void> _guardarCambiosSilencioso() async {
    final db = await DBManager.instance.database;
    final batch = db.batch();
    for (var item in inventario) {
      item.total = item.mano + item.deposito;
      batch.insert(
        'armamento',
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // Helpers
  String _getCellValue(Data? cell) {
    if (cell == null || cell.value == null) return "";
    return cell.value.toString();
  }

  int _getCellIntValue(Data? cell) {
    if (cell == null || cell.value == null) return 0;
    if (cell.value is int) return cell.value as int;
    return int.tryParse(cell.value.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.isDark(context)
          ? const Color(0xFF0D1117)
          : Colors.white,
      appBar: AppBar(
        title: const Text(
          "PARTE DE ARMAMENTO",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: AppStyles.primaryColor(context),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        toolbarHeight: 50,
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
      body: cargando
          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
          : Column(
              children: [
                if (_isProcessing) const LinearProgressIndicator(), // ✅ NUEVO
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      decoration: AppStyles.tableDecoration(context),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SingleChildScrollView(
                          child: SizedBox(
                            width: double.infinity,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dataTableTheme: AppStyles.tableTheme(context),
                              ),
                              child: DataTable(
                                headingRowHeight: 40,
                                dataRowMinHeight: 35,
                                dataRowMaxHeight: 45,
                                columnSpacing: 20,
                                columns: _buildColumns(),
                                rows: inventario
                                    .map((item) => _filaEditable(item))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildControlBar(),
              ],
            ),
    );
  }

  List<DataColumn> _buildColumns() {
    const s = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    return const [
      DataColumn(
        label: Expanded(child: Text("DESCRIPCIÓN MATERIAl", style: s)),
      ),
      DataColumn(label: Text("CARGO", style: s)),
      DataColumn(label: Text("MANO", style: s)),
      DataColumn(label: Text("DEP", style: s)),
      DataColumn(label: Text("TOTAL", style: s)),
      DataColumn(label: Text("OBSERVACIONES", style: s)),
    ];
  }

  DataRow _filaEditable(ItemArmamento item) {
    final cellStyle = AppStyles.tableCell(context).copyWith(fontSize: 12);
    return DataRow(
      cells: [
        DataCell(
          Text(
            item.clase,
            style: cellStyle.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          modoEdicion
              ? _input(item.cargo, (v) => setState(() => item.cargo = v))
              : Text("${item.cargo}", style: cellStyle),
        ),
        DataCell(
          modoEdicion
              ? _input(item.mano, (v) => setState(() => item.mano = v))
              : Text("${item.mano}", style: cellStyle),
        ),
        DataCell(
          modoEdicion
              ? _input(item.deposito, (v) => setState(() => item.deposito = v))
              : Text("${item.deposito}", style: cellStyle),
        ),
        DataCell(
          Text(
            "${item.mano + item.deposito}",
            style: cellStyle.copyWith(
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(
          modoEdicion
              ? _inputStr(item.observaciones, (v) => item.observaciones = v)
              : Text(
                  item.observaciones,
                  style: cellStyle.copyWith(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _input(int init, Function(int) save) => Container(
    width: 50,
    decoration: BoxDecoration(
      color: Colors.blue.withOpacity(0.05),
      borderRadius: BorderRadius.circular(4),
    ),
    child: TextFormField(
      initialValue: "$init",
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      decoration: const InputDecoration(
        isDense: true,
        border: InputBorder.none,
      ),
      onChanged: (v) => save(int.tryParse(v) ?? 0),
    ),
  );

  Widget _inputStr(String init, Function(String) save) => SizedBox(
    width: 150,
    child: TextFormField(
      initialValue: init,
      style: const TextStyle(fontSize: 12),
      decoration: const InputDecoration(
        isDense: true,
        hintText: "Escribir...",
        hintStyle: TextStyle(fontSize: 10),
      ),
      onChanged: (v) => save(v),
    ),
  );

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: AppStyles.isDark(context)
          ? const Color(0xFF161B22)
          : Colors.grey[200],
      child: SafeArea(
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 15,
          runSpacing: 10,
          children: [
            _btnAction(
              Icons.picture_as_pdf,
              "PDF",
              Colors.red[800]!,
              _exportarPDF,
            ),
            // ✅ NUEVOS BOTONES
            _btnAction(
              Icons.file_download,
              "EXPORTAR EXCEL",
              Colors.green[800]!,
              _exportarExcel,
            ),
            _btnAction(
              Icons.file_upload,
              "IMPORTAR EXCEL",
              Colors.orange[800]!,
              _isProcessing ? () {} : _importarExcel,
            ),
            _btnAction(
              modoEdicion ? Icons.save_rounded : Icons.edit_note_rounded,
              modoEdicion ? "GUARDAR" : "EDITAR",
              modoEdicion
                  ? Colors.green[700]!
                  : AppStyles.primaryColor(context),
              () {
                if (modoEdicion) _guardarCambios();
                setState(() => modoEdicion = !modoEdicion);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _btnAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(120, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 2,
      ),
    );
  }

  Future<void> _exportarPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              "PARTE DE ARMAMENTO ",
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.TableHelper.fromTextArray(
            headers: [
              'MATERIAl',
              'CARGO',
              'MANO',
              'DEP',
              'TOTAL',
              'OBSERVACIONES',
            ],
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey900),
            data: inventario
                .map(
                  (i) => [
                    i.clase,
                    i.cargo,
                    i.mano,
                    i.deposito,
                    (i.mano + i.deposito),
                    i.observaciones,
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Reporte_Armamento.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
  }
}
