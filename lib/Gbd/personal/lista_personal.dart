// import 'dart:io';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:excel/excel.dart' hide Border;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';

// // Tus otros imports...
// import 'package:peloton/BD/data_personal.dart';
// import 'package:peloton/Gbd/personal/personal_reg.dart';
// import 'package:peloton/Gbd/personal/registrar_personal.dart';
// import 'package:peloton/Gbd/personal/ver_personal.dart';
// import 'package:peloton/BD/db_manager.dart';

// class ListaPersonalScreen extends StatefulWidget {
//   const ListaPersonalScreen({super.key});

//   @override
//   State<ListaPersonalScreen> createState() => _ListaPersonalScreenState();
// }

// class _ListaPersonalScreenState extends State<ListaPersonalScreen> {
//   List<Personal> _todos = [];
//   List<Personal> _filtrados = [];
//   bool _cargando = true;
//   bool _exportando = false;
//   final _searchCtrl = TextEditingController();
//   String? _nombreUsuario;

//   @override
//   void initState() {
//     super.initState();
//     _cargarDatos();
//     _cargarNombreUsuario();
//   }

//   Future<void> _cargarNombreUsuario() async {
//     try {
//       final db = await DBManager.instance.authDatabase;
//       final sesion = await db.query('sesion_activa');

//       if (sesion.isNotEmpty) {
//         int usuarioId = sesion.first['usuario_id'] as int;
//         final usuario = await db.query(
//           'usuarios',
//           where: 'id = ?',
//           whereArgs: [usuarioId],
//           limit: 1,
//         );

//         if (usuario.isNotEmpty && mounted) {
//           setState(() {
//             _nombreUsuario = usuario.first['nombres'] as String?;
//           });
//         } else if (mounted) {
//           setState(() => _nombreUsuario = "Error ID");
//         }
//       } else if (mounted) {
//         setState(() => _nombreUsuario = "Sin sesión");
//       }
//     } catch (e) {
//       print("Error cargando usuario: $e");
//       if (mounted) setState(() => _nombreUsuario = "Sin sesión");
//     }
//   }

//   Future<void> _cargarDatos() async {
//     setState(() => _cargando = true);
//     try {
//       final datos = await DBPersonal.instance.listar();
//       setState(() {
//         _todos = datos;
//         _filtrados = datos;
//         _cargando = false;
//       });
//     } catch (e) {
//       setState(() => _cargando = false);
//     }
//   }

//   void _filtrar(String query) {
//     setState(() {
//       _filtrados = _todos.where((p) {
//         final searchLower = query.toLowerCase();
//         return p.nombre.toLowerCase().contains(searchLower) ||
//             p.apellido.toLowerCase().contains(searchLower) ||
//             p.numeroDocumento.contains(query);
//       }).toList();
//     });
//   }

//   // --- FUNCIÓN ACTUALIZADA: IMPORTAR DESDE EXCEL (Coincide con el nuevo Exportar) ---
//   Future<void> _importarExcel() async {
//     try {
//       FilePickerResult? result = await FilePicker.platform.pickFiles(
//         type: FileType.custom,
//         allowedExtensions: ['xlsx', 'xls'],
//       );

//       if (result == null || result.files.single.path == null) return;

//       final filePath = result.files.single.path!;
//       final file = File(filePath);

//       if (await file.length() == 0) {
//         if (mounted) _mostrarError("El archivo está vacío.");
//         return;
//       }

//       final bytes = await file.readAsBytes();
//       var excel = Excel.decodeBytes(bytes);

//       String sheetName = excel.tables.keys.first;
//       Sheet sheet = excel[sheetName];

//       if (sheet.rows.length <= 1) {
//         if (mounted) _mostrarError("El Excel no tiene filas de datos.");
//         return;
//       }

//       int totalFilas = sheet.rows.length - 1;
//       int importados = 0;
//       int omitidos = 0;

//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) {
//           return StatefulBuilder(
//             builder: (context, setDialogState) {
//               if (importados + omitidos == totalFilas) {
//                 Future.delayed(const Duration(milliseconds: 500), () {
//                   if (mounted) Navigator.of(context).pop();
//                   _mostrarMensaje(
//                     "Importación completada: $importados guardados, $omitidos omitidos.",
//                   );
//                   _cargarDatos();
//                 });
//               }

//               double progreso = (importados + omitidos) / totalFilas;
//               return AlertDialog(
//                 title: const Text("Importando Excel"),
//                 content: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     LinearProgressIndicator(value: progreso),
//                     const SizedBox(height: 20),
//                     Text("Procesando $importados de $totalFilas..."),
//                   ],
//                 ),
//               );
//             },
//           );
//         },
//       );

//       for (int i = 1; i < sheet.rows.length; i++) {
//         var row = sheet.rows[i];

//         // Índice 6 es la Cédula (No = 0, Grado = 1, Nombre = 2, Apellido = 3, Tipo Doc = 4, RH = 5, Cédula = 6)
//         String cedula = row[6]?.value?.toString() ?? "";

//         if (cedula.isEmpty) {
//           omitidos++;
//           continue;
//         }

//         // ✅ MAPEO EXACTO SEGÚN EL NUEVO ORDEN DEL EXPORTAR
//         Map<String, dynamic> nuevoPersonal = {
//           'grado': row[1]?.value?.toString() ?? "",
//           'nombre': row[2]?.value?.toString() ?? "",
//           'apellido': row[3]?.value?.toString() ?? "",
//           'tipo_documento': row[4]?.value?.toString() ?? "",
//           'rh': row[5]?.value?.toString() ?? "", // ✅ RECUPERADO
//           'numero_documento': cedula,
//           'fecha_nacimiento': row[7]?.value?.toString() ?? "",
//           'ciudad_nacimiento': row[8]?.value?.toString() ?? "",
//           'pais_nacimiento': row[9]?.value?.toString() ?? "",
//           'sexo': row[10]?.value?.toString() ?? "",
//           'direccion': row[11]?.value?.toString() ?? "",
//           'telefono': row[12]?.value?.toString() ?? "",
//           'correo': row[13]?.value?.toString() ?? "",
//           'cargo': row[14]?.value?.toString() ?? "",
//           'fecha_ingreso': row[15]?.value?.toString() ?? "",
//           'estado': row[16]?.value?.toString() ?? "activo",
//           'foto_path': (row[17]?.value?.toString() ?? "Sin foto") == "Sin foto"
//               ? null
//               : row[17]?.value?.toString(),
//           'nombre_padre': row[18]?.value?.toString() ?? "",
//           'telefono_padre': row[19]?.value?.toString() ?? "", // ✅ RECUPERADO
//           'nombre_madre': row[20]?.value?.toString() ?? "",
//           'telefono_madre': row[21]?.value?.toString() ?? "", // ✅ RECUPERADO
//           'nombre_hijo': row[22]?.value?.toString() ?? "", // ✅ RECUPERADO
//           'contacto_emergencia': row[23]?.value?.toString() ?? "",
//           'telefono_emergencia': row[24]?.value?.toString() ?? "",
//         };

//         await DBPersonal.instance.insertarDesdeMapa(nuevoPersonal);
//         importados++;
//       }
//     } catch (e) {
//       print("Error importando Excel: $e");
//       if (mounted) _mostrarError("Error al leer el archivo: $e");
//     }
//   }

//   void _mostrarMensaje(String msg) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
//   }

//   void _mostrarError(String msg) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
//   }

//   // --- FUNCIÓN ACTUALIZADA: EXPORTAR EXCEL (Se agregaron los campos faltantes) ---
//   Future<void> _generarExcel() async {
//     setState(() => _exportando = true);

//     try {
//       final Excel excel = Excel.createExcel();
//       excel.delete('Sheet1');
//       final Sheet sheetObject = excel['Personal'];

//       final cellStyle = CellStyle(
//         bold: true,
//         fontColorHex: ExcelColor.white,
//         backgroundColorHex: ExcelColor.blue,
//         horizontalAlign: HorizontalAlign.Center,
//       );

//       // ✅ NUEVOS ENCABEZADOS (Se agregaron RH, Tel Padre, Tel Madre, Hijo)
//       final headers = [
//         'No',
//         'Grado',
//         'Nombre',
//         'Apellido',
//         'Tipo Doc',
//         'RH',
//         'Cédula',
//         'F. Nac',
//         'Ciudad',
//         'País',
//         'Sexo',
//         'Dirección',
//         'Teléfono',
//         'Correo',
//         'Cargo',
//         'F. Ingreso',
//         'Estado',
//         'Foto Path',
//         'Padre',
//         'Tel. Padre',
//         'Madre',
//         'Tel. Madre',
//         'Nombre Hijo',
//         'Contacto Emer.',
//         'Tel. Emer.',
//       ];

//       for (int i = 0; i < headers.length; i++) {
//         var cell = sheetObject.cell(
//           CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
//         );
//         cell.value = TextCellValue(headers[i]);
//         cell.cellStyle = cellStyle;
//       }

//       // 4. Llenar Datos
//       for (int rowIndex = 0; rowIndex < _todos.length; rowIndex++) {
//         final p = _todos[rowIndex];
//         int r = rowIndex + 1;

//         // ✅ NUEVO ORDEN DE EXPORTACIÓN
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r))
//             .value = TextCellValue(
//           "${rowIndex + 1}",
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r))
//             .value = TextCellValue(
//           p.grado,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r))
//             .value = TextCellValue(
//           p.nombre,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r))
//             .value = TextCellValue(
//           p.apellido,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r))
//             .value = TextCellValue(
//           p.tipoDocumento,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: r))
//             .value = TextCellValue(
//           p.rh,
//         ); // ✅ NUEVO
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: r))
//             .value = TextCellValue(
//           p.numeroDocumento,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: r))
//             .value = TextCellValue(
//           p.fechaNacimiento,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: r))
//             .value = TextCellValue(
//           p.ciudadNacimiento,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: r))
//             .value = TextCellValue(
//           p.paisNacimiento,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: r))
//             .value = TextCellValue(
//           p.sexo,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: r))
//             .value = TextCellValue(
//           p.direccion,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: r))
//             .value = TextCellValue(
//           p.telefono,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: r))
//             .value = TextCellValue(
//           p.correo,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: r))
//             .value = TextCellValue(
//           p.cargo,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: r))
//             .value = TextCellValue(
//           p.fechaIngreso,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: r))
//             .value = TextCellValue(
//           p.estado,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: r))
//             .value = TextCellValue(
//           p.fotoPath ?? "Sin foto",
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: r))
//             .value = TextCellValue(
//           p.nombrePadre,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 19, rowIndex: r))
//             .value = TextCellValue(
//           p.telefonoPadre,
//         ); // ✅ NUEVO
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 20, rowIndex: r))
//             .value = TextCellValue(
//           p.nombreMadre,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 21, rowIndex: r))
//             .value = TextCellValue(
//           p.telefonoMadre,
//         ); // ✅ NUEVO
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: r))
//             .value = TextCellValue(
//           p.nombreHijo,
//         ); // ✅ NUEVO
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: r))
//             .value = TextCellValue(
//           p.contactoEmergencia,
//         );
//         sheetObject
//             .cell(CellIndex.indexByColumnRow(columnIndex: 24, rowIndex: r))
//             .value = TextCellValue(
//           p.telefonoEmergencia,
//         );
//       }

//       final bytes = excel.encode();
//       if (bytes != null) {
//         final directory = await getTemporaryDirectory();
//         final String fileName =
//             'Reporte_Personal_${DateTime.now().millisecondsSinceEpoch}.xlsx';
//         final String path = '${directory.path}/$fileName';
//         final file = File(path);
//         await file.writeAsBytes(bytes, flush: true);

//         if (!mounted) return;

//         await Share.shareXFiles(
//           [XFile(path)],
//           subject: 'Reporte de Personal',
//           text: 'Adjunto el listado completo de personal generado por la App.',
//         );
//       }
//     } catch (e) {
//       print("Error exportando: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("Error al generar archivo: $e"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _exportando = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     const primaryBlue = Color(0xFF1A237E);

//     return Scaffold(
//       backgroundColor: isDark
//           ? const Color(0xFF121212)
//           : const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         title: const Text(
//           "LISTADO DE PERSONAL COMPLETO",
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: primaryBlue,
//         foregroundColor: Colors.white,
//         actions: [
//           Padding(
//             padding: const EdgeInsets.only(right: 8.0),
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
//                 IconButton(
//                   onPressed: _cargarDatos,
//                   icon: const Icon(Icons.refresh),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildCabecera(isDark, primaryBlue),
//           Expanded(
//             child: _cargando
//                 ? const Center(
//                     child: CircularProgressIndicator(color: primaryBlue),
//                   )
//                 : _buildTablaScrollable(isDark, primaryBlue),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCabecera(bool isDark, Color primaryBlue) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//       child: Row(
//         children: [
//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: primaryBlue,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//             ),
//             onPressed: () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) =>
//                     const RegistroPersonalScreen(personal: null),
//               ),
//             ).then((_) => _cargarDatos()),
//             icon: const Icon(Icons.person_add),
//             label: const Text("NUEVO"),
//           ),
//           const SizedBox(width: 15),
//           _exportando
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     color: Colors.green,
//                   ),
//                 )
//               : ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 15,
//                     ),
//                   ),
//                   onPressed: _generarExcel,
//                   icon: const Icon(Icons.share),
//                   label: const Text("EXPORTAR EXCEL"),
//                 ),
//           const SizedBox(width: 15),
//           ElevatedButton.icon(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.orange,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//             ),
//             onPressed: _importarExcel,
//             icon: const Icon(Icons.file_download),
//             label: const Text("IMPORTAR EXCEL"),
//           ),
//           const SizedBox(width: 15),
//           Expanded(
//             child: TextField(
//               controller: _searchCtrl,
//               onChanged: _filtrar,
//               decoration: InputDecoration(
//                 hintText: "Buscar por nombre o cédula...",
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 contentPadding: EdgeInsets.zero,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTablaScrollable(bool isDark, Color primaryBlue) {
//     if (_filtrados.isEmpty) return const Center(child: Text("Sin registros"));

//     return SingleChildScrollView(
//       scrollDirection: Axis.vertical,
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         child: DataTable(
//           columnSpacing: 25,
//           headingRowColor: MaterialStateProperty.all(
//             primaryBlue.withOpacity(0.1),
//           ),
//           columns: _buildColumnas(primaryBlue),
//           rows: List.generate(_filtrados.length, (index) {
//             final p = _filtrados[index];
//             return DataRow(
//               cells: [
//                 DataCell(Text("${index + 1}")),
//                 DataCell(
//                   Text(
//                     p.grado,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 DataCell(Text(p.nombre)),
//                 DataCell(Text(p.apellido)),
//                 DataCell(Text(p.tipoDocumento)),
//                 DataCell(
//                   Text(
//                     p.rh,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ), // ✅ VISUALIZAR RH EN TABLA
//                 DataCell(
//                   Text(
//                     p.numeroDocumento,
//                     style: const TextStyle(
//                       color: Colors.blue,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//                 DataCell(Text(p.fechaNacimiento)),
//                 DataCell(Text(p.ciudadNacimiento)),
//                 DataCell(Text(p.paisNacimiento)),
//                 DataCell(Text(p.sexo)),
//                 DataCell(Text(p.direccion)),
//                 DataCell(Text(p.telefono)),
//                 DataCell(Text(p.correo)),
//                 DataCell(Text(p.cargo)),
//                 DataCell(Text(p.fechaIngreso)),
//                 DataCell(_buildChipEstado(p.estado)),
//                 DataCell(_buildMiniatura(p.fotoPath)),
//                 DataCell(Text(p.nombrePadre)),
//                 DataCell(Text(p.telefonoPadre)), // ✅ VISUALIZAR EN TABLA
//                 DataCell(Text(p.nombreMadre)),
//                 DataCell(Text(p.telefonoMadre)), // ✅ VISUALIZAR EN TABLA
//                 DataCell(Text(p.nombreHijo)), // ✅ VISUALIZAR EN TABLA
//                 DataCell(Text(p.contactoEmergencia)),
//                 DataCell(Text(p.telefonoEmergencia)),
//                 DataCell(_buildBotonesAccion(p)),
//               ],
//             );
//           }),
//         ),
//       ),
//     );
//   }

//   List<DataColumn> _buildColumnas(Color blue) {
//     // ✅ CABECERAS DE LA TABLA VISUAL ACTUALIZADAS
//     const labels = [
//       'No',
//       'Grado',
//       'Nombre',
//       'Apellido',
//       'Tipo Doc',
//       'RH',
//       'Cédula',
//       'F. Nac',
//       'Ciudad',
//       'País',
//       'Sexo',
//       'Dirección',
//       'Teléfono',
//       'Correo',
//       'Cargo',
//       'F. Ingreso',
//       'Estado',
//       'Foto',
//       'Padre',
//       'Tel. Padre',
//       'Madre',
//       'Tel. Madre',
//       'Nombre Hijo',
//       'Contacto Emer.',
//       'Tel. Emer.',
//       'Acciones',
//     ];
//     return labels
//         .map(
//           (l) => DataColumn(
//             label: Text(
//               l,
//               style: TextStyle(color: blue, fontWeight: FontWeight.bold),
//             ),
//           ),
//         )
//         .toList();
//   }

//   Widget _buildChipEstado(String estado) {
//     bool activo = estado.toLowerCase() == 'activo';
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: activo
//             ? Colors.green.withOpacity(0.2)
//             : Colors.red.withOpacity(0.2),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: activo ? Colors.green : Colors.red),
//       ),
//       child: Text(
//         estado.toUpperCase(),
//         style: TextStyle(
//           color: activo ? Colors.green[900] : Colors.red[900],
//           fontSize: 11,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _buildMiniatura(String? path) {
//     return CircleAvatar(
//       radius: 18,
//       backgroundImage: (path != null && File(path).existsSync())
//           ? FileImage(File(path))
//           : null,
//       child: (path == null || !File(path).existsSync())
//           ? const Icon(Icons.person, size: 18)
//           : null,
//     );
//   }

//   Widget _buildBotonesAccion(Personal p) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         _btn(
//           Icons.visibility,
//           Colors.blue,
//           () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (c) => DetallePersonalScreen(personal: p),
//             ),
//           ),
//         ),
//         const SizedBox(width: 5),
//         _btn(
//           Icons.edit,
//           Colors.orange,
//           () => Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) => RegistroPersonalScreen(personal: p),
//             ),
//           ).then((_) => _cargarDatos()),
//         ),
//         const SizedBox(width: 5),
//         _btn(Icons.delete, Colors.red, () => _confirmarEliminar(p)),
//       ],
//     );
//   }

//   Widget _btn(IconData i, Color c, VoidCallback t) => InkWell(
//     onTap: t,
//     child: Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: c,
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Icon(i, color: Colors.white, size: 18),
//     ),
//   );

//   void _confirmarEliminar(Personal p) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Confirmar Baja"),
//         content: Text("¿Eliminar a ${p.apellido}?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("CANCELAR"),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             onPressed: () async {
//               await DBPersonal.instance.eliminar(p.id!);
//               if (!mounted) return;
//               Navigator.pop(ctx);
//               _cargarDatos();
//             },
//             child: const Text(
//               "ELIMINAR",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Tus otros imports...
import 'package:peloton/BD/data_personal.dart';
import 'package:peloton/Gbd/personal/personal_reg.dart';
import 'package:peloton/Gbd/personal/registrar_personal.dart';
import 'package:peloton/Gbd/personal/ver_personal.dart';
import 'package:peloton/BD/db_manager.dart';

class ListaPersonalScreen extends StatefulWidget {
  const ListaPersonalScreen({super.key});

  @override
  State<ListaPersonalScreen> createState() => _ListaPersonalScreenState();
}

class _ListaPersonalScreenState extends State<ListaPersonalScreen> {
  List<Personal> _todos = [];
  List<Personal> _filtrados = [];
  bool _cargando = true;
  bool _exportando = false;
  final _searchCtrl = TextEditingController();
  String? _nombreUsuario;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    try {
      final db = await DBManager.instance.authDatabase;
      final sesion = await db.query('sesion_activa');

      if (sesion.isNotEmpty) {
        int usuarioId = sesion.first['usuario_id'] as int;
        final usuario = await db.query(
          'usuarios',
          where: 'id = ?',
          whereArgs: [usuarioId],
          limit: 1,
        );

        if (usuario.isNotEmpty && mounted) {
          setState(() {
            _nombreUsuario = usuario.first['nombres'] as String?;
          });
        } else if (mounted) {
          setState(() => _nombreUsuario = "Error ID");
        }
      } else if (mounted) {
        setState(() => _nombreUsuario = "Sin sesión");
      }
    } catch (e) {
      print("Error cargando usuario: $e");
      if (mounted) setState(() => _nombreUsuario = "Sin sesión");
    }
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final datos = await DBPersonal.instance.listar();
      setState(() {
        _todos = datos;
        _filtrados = datos;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  void _filtrar(String query) {
    setState(() {
      _filtrados = _todos.where((p) {
        final searchLower = query.toLowerCase();
        return p.nombre.toLowerCase().contains(searchLower) ||
            p.apellido.toLowerCase().contains(searchLower) ||
            p.numeroDocumento.contains(query);
      }).toList();
    });
  }

  // --- FUNCIÓN MEJORADA: IMPORTAR DESDE EXCEL (Lectura Dinámica por Encabezado) ---
  Future<void> _importarExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.single.path == null) return;

      final filePath = result.files.single.path!;
      final file = File(filePath);

      if (await file.length() == 0) {
        if (mounted) _mostrarError("El archivo está vacío.");
        return;
      }

      final bytes = await file.readAsBytes();
      var excel = Excel.decodeBytes(bytes);

      if (!excel.tables.containsKey('Personal')) {
        if (mounted) _mostrarError("El archivo no tiene la hoja 'Personal'.");
        return;
      }

      Sheet sheet = excel['Personal'];

      if (sheet.rows.length <= 1) {
        if (mounted) _mostrarError("El Excel no tiene filas de datos.");
        return;
      }

      // 1. Leer encabezados
      final headerRow = sheet.rows[0];
      Map<String, int> columnIndex = {};

      for (int i = 0; i < headerRow.length; i++) {
        String headerName = (headerRow[i]?.value?.toString() ?? "").trim();
        columnIndex[headerName] = i;
      }

      if (!columnIndex.containsKey('Cédula')) {
        if (mounted) _mostrarError("Formato inválido (Falta 'Cédula').");
        return;
      }

      int totalFilas = sheet.rows.length - 1;
      int importados = 0;
      int omitidos = 0;
      bool procesoForzado =
          false; // Bandera para saber si el usuario presionó el botón

      // 2. Mostrar Diálogo con el botón de fuerza
      showDialog(
        context: context,
        barrierDismissible: false, // Ya no se cierra tocando fuera
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              // Si termina de forma natural o se fuerza, se cierra y actualiza
              if ((importados + omitidos == totalFilas || procesoForzado) &&
                  totalFilas > 0) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) Navigator.of(context).pop();
                  _mostrarMensaje(
                    "Carga completada: $importados guardados, $omitidos omitidos.",
                  );
                  _cargarDatos(); // Aquí se actualiza la tabla principal
                });
              }

              double progreso = totalFilas > 0
                  ? (importados + omitidos) / totalFilas
                  : 0;
              return AlertDialog(
                title: const Text("Importando Excel"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: progreso),
                    const SizedBox(height: 20),
                    Text("Procesando $importados de $totalFilas..."),
                    const SizedBox(height: 15),
                    const Divider(),
                    const SizedBox(height: 10),
                    // ✅ EL NUEVO BOTÓN DE FORZAR CARGA
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, color: Colors.orange),
                        label: const Text(
                          "Forzar Carga",
                          style: TextStyle(color: Colors.orange),
                        ),
                        onPressed: () {
                          // Al presionar, cambiamos la bandera y el diálogo se cerrará en el siguiente ciclo
                          procesoForzado = true;
                          setDialogState(() {});
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                    const Text(
                      "Si el progreso se detiene, presiona el botón\npara mostrar los datos guardados hasta ahora.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

      // 3. Leer todos los datos del Excel primero
      List<Map<String, dynamic>> listaParaInsertar = [];

      for (int i = 1; i < sheet.rows.length; i++) {
        // ✅ VERIFICAR SI EL USUARIO YA PRESIONÓ FORZAR CARGA
        // Si es así, rompemos el ciclo y dejamos de leer el Excel
        if (procesoForzado) {
          omitidos += (sheet.rows.length - i); // Sumamos el resto como omitidos
          break;
        }

        var row = sheet.rows[i];

        String getValue(String colName) {
          if (columnIndex.containsKey(colName) &&
              columnIndex[colName]! < row.length) {
            return row[columnIndex[colName]!]?.value?.toString() ?? "";
          }
          return "";
        }

        String cedula = getValue('Cédula');

        if (cedula.isEmpty) {
          omitidos++;
          continue;
        }

        String fotoPathStr = getValue('Foto Path');

        listaParaInsertar.add({
          'grado': getValue('Grado'),
          'nombre': getValue('Nombre'),
          'apellido': getValue('Apellido'),
          'tipo_documento': getValue('Tipo Doc'),
          'rh': getValue('RH'),
          'numero_documento': cedula,
          'fecha_nacimiento': getValue('F. Nac'),
          'ciudad_nacimiento': getValue('Ciudad'),
          'pais_nacimiento': getValue('País'),
          'sexo': getValue('Sexo'),
          'direccion': getValue('Dirección'),
          'telefono': getValue('Teléfono'),
          'correo': getValue('Correo'),
          'cargo': getValue('Cargo'),
          'fecha_ingreso': getValue('F. Ingreso'),
          'estado': getValue('Estado').isEmpty ? "activo" : getValue('Estado'),
          'foto_path': fotoPathStr == "Sin foto" ? null : fotoPathStr,
          'nombre_padre': getValue('Padre'),
          'telefono_padre': getValue('Tel. Padre'),
          'nombre_madre': getValue('Madre'),
          'telefono_madre': getValue('Tel. Madre'),
          'nombre_hijo': getValue('Nombre Hijo'),
          'contacto_emergencia': getValue('Contacto Emer.'),
          'telefono_emergencia': getValue('Tel. Emer.'),
        });
      }

      // 4. Insertar en BD
      for (var nuevoPersonal in listaParaInsertar) {
        // Si ya se forzó, no insertamos más de los que alcanzamos a leer
        if (procesoForzado) break;

        await DBPersonal.instance.insertarDesdeMapa(nuevoPersonal);
        importados++;

        // Ceder control para actualizar la barra sin congelarse
        await Future.delayed(Duration.zero);
      }
    } catch (e) {
      print("Error importando Excel: $e");
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) _mostrarError("Error al leer el archivo: $e");
    }
  }

  void _mostrarMensaje(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  Future<void> _generarExcel() async {
    setState(() => _exportando = true);

    try {
      final Excel excel = Excel.createExcel();

      // 1. Eliminar la hoja por defecto para evitar conflictos de metadatos
      excel.delete('Sheet1');

      // 2. Crear nuestra hoja limpia
      final Sheet sheetObject = excel['Personal'];

      final cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.white,
        backgroundColorHex: ExcelColor.blue,
        horizontalAlign: HorizontalAlign.Center,
      );

      final headers = [
        'No',
        'Grado',
        'Nombre',
        'Apellido',
        'Tipo Doc',
        'RH',
        'Cédula',
        'F. Nac',
        'Ciudad',
        'País',
        'Sexo',
        'Dirección',
        'Teléfono',
        'Correo',
        'Cargo',
        'F. Ingreso',
        'Estado',
        'Foto Path',
        'Padre',
        'Tel. Padre',
        'Madre',
        'Tel. Madre',
        'Nombre Hijo',
        'Contacto Emer.',
        'Tel. Emer.',
      ];

      // 3. Poner Encabezados
      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = cellStyle;
      }

      // 4. Llenar Datos
      for (int rowIndex = 0; rowIndex < _todos.length; rowIndex++) {
        final p = _todos[rowIndex];
        int r =
            rowIndex + 1; // Empieza en la fila 1 porque la 0 son los títulos

        List<String> datosFila = [
          "${rowIndex + 1}",
          p.grado,
          p.nombre,
          p.apellido,
          p.tipoDocumento,
          p.rh,
          p.numeroDocumento,
          p.fechaNacimiento,
          p.ciudadNacimiento,
          p.paisNacimiento,
          p.sexo,
          p.direccion,
          p.telefono,
          p.correo,
          p.cargo,
          p.fechaIngreso,
          p.estado,
          p.fotoPath ?? "Sin foto",
          p.nombrePadre,
          p.telefonoPadre,
          p.nombreMadre,
          p.telefonoMadre,
          p.nombreHijo,
          p.contactoEmergencia,
          p.telefonoEmergencia,
        ];

        // 5. Insertar fila completa en el Excel
        for (int c = 0; c < datosFila.length; c++) {
          sheetObject
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
              .value = TextCellValue(
            datosFila[c],
          );
        }
      }

      // 6. Forzar limpieza de hojas basura internas para que no salga vacía en Windows
      excel.tables.removeWhere((key, value) => key != 'Personal');

      // 7. Codificar y guardar
      final bytes = excel.encode();
      if (bytes != null) {
        final directory = await getTemporaryDirectory();
        final String fileName =
            'Reporte_Personal_${DateTime.now().millisecondsSinceEpoch}.xlsx';
        final String path = '${directory.path}/$fileName';
        final file = File(path);

        await file.writeAsBytes(bytes, flush: true);

        if (!mounted) return;

        // Compartir
        await Share.shareXFiles(
          [XFile(path)],
          subject: 'Reporte de Personal',
          text: 'Adjunto el listado completo de personal generado por la App.',
        );
      }
    } catch (e) {
      print("Error exportando: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al generar archivo: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "LISTADO DE PERSONAL COMPLETO",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
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
                IconButton(
                  onPressed: _cargarDatos,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCabecera(isDark, primaryBlue),
          Expanded(
            child: _cargando
                ? const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  )
                : _buildTablaScrollable(isDark, primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildCabecera(bool isDark, Color primaryBlue) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const RegistroPersonalScreen(personal: null),
              ),
            ).then((_) => _cargarDatos()),
            icon: const Icon(Icons.person_add),
            label: const Text("NUEVO"),
          ),
          const SizedBox(width: 15),
          _exportando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green,
                  ),
                )
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  onPressed: _generarExcel,
                  icon: const Icon(Icons.share),
                  label: const Text("EXPORTAR EXCEL"),
                ),
          const SizedBox(width: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            onPressed: _importarExcel,
            icon: const Icon(Icons.file_download),
            label: const Text("IMPORTAR EXCEL"),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _filtrar,
              decoration: InputDecoration(
                hintText: "Buscar por nombre o cédula...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaScrollable(bool isDark, Color primaryBlue) {
    if (_filtrados.isEmpty) return const Center(child: Text("Sin registros"));

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 25,
          headingRowColor: MaterialStateProperty.all(
            primaryBlue.withOpacity(0.1),
          ),
          columns: _buildColumnas(primaryBlue),
          rows: List.generate(_filtrados.length, (index) {
            final p = _filtrados[index];
            return DataRow(
              cells: [
                DataCell(Text("${index + 1}")),
                DataCell(
                  Text(
                    p.grado,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(Text(p.nombre)),
                DataCell(Text(p.apellido)),
                DataCell(Text(p.tipoDocumento)),
                DataCell(
                  Text(
                    p.rh,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                DataCell(
                  Text(
                    p.numeroDocumento,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                DataCell(Text(p.fechaNacimiento)),
                DataCell(Text(p.ciudadNacimiento)),
                DataCell(Text(p.paisNacimiento)),
                DataCell(Text(p.sexo)),
                DataCell(Text(p.direccion)),
                DataCell(Text(p.telefono)),
                DataCell(Text(p.correo)),
                DataCell(Text(p.cargo)),
                DataCell(Text(p.fechaIngreso)),
                DataCell(_buildChipEstado(p.estado)),
                DataCell(_buildMiniatura(p.fotoPath)),
                DataCell(Text(p.nombrePadre)),
                DataCell(Text(p.telefonoPadre)),
                DataCell(Text(p.nombreMadre)),
                DataCell(Text(p.telefonoMadre)),
                DataCell(Text(p.nombreHijo)),
                DataCell(Text(p.contactoEmergencia)),
                DataCell(Text(p.telefonoEmergencia)),
                DataCell(_buildBotonesAccion(p)),
              ],
            );
          }),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumnas(Color blue) {
    const labels = [
      'No',
      'Grado',
      'Nombre',
      'Apellido',
      'Tipo Doc',
      'RH',
      'Cédula',
      'F. Nac',
      'Ciudad',
      'País',
      'Sexo',
      'Dirección',
      'Teléfono',
      'Correo',
      'Cargo',
      'F. Ingreso',
      'Estado',
      'Foto',
      'Padre',
      'Tel. Padre',
      'Madre',
      'Tel. Madre',
      'Nombre Hijo',
      'Contacto Emer.',
      'Tel. Emer.',
      'Acciones',
    ];
    return labels
        .map(
          (l) => DataColumn(
            label: Text(
              l,
              style: TextStyle(color: blue, fontWeight: FontWeight.bold),
            ),
          ),
        )
        .toList();
  }

  Widget _buildChipEstado(String estado) {
    bool activo = estado.toLowerCase() == 'activo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: activo
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: activo ? Colors.green : Colors.red),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: activo ? Colors.green[900] : Colors.red[900],
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMiniatura(String? path) {
    return CircleAvatar(
      radius: 18,
      backgroundImage: (path != null && File(path).existsSync())
          ? FileImage(File(path))
          : null,
      child: (path == null || !File(path).existsSync())
          ? const Icon(Icons.person, size: 18)
          : null,
    );
  }

  Widget _buildBotonesAccion(Personal p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _btn(
          Icons.visibility,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => DetallePersonalScreen(personal: p),
            ),
          ),
        ),
        const SizedBox(width: 5),
        _btn(
          Icons.edit,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistroPersonalScreen(personal: p),
            ),
          ).then((_) => _cargarDatos()),
        ),
        const SizedBox(width: 5),
        _btn(Icons.delete, Colors.red, () => _confirmarEliminar(p)),
      ],
    );
  }

  Widget _btn(IconData i, Color c, VoidCallback t) => InkWell(
    onTap: t,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(i, color: Colors.white, size: 18),
    ),
  );

  void _confirmarEliminar(Personal p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmar Baja"),
        content: Text("¿Eliminar a ${p.apellido}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await DBPersonal.instance.eliminar(p.id!);
              if (!mounted) return;
              Navigator.pop(ctx);
              _cargarDatos();
            },
            child: const Text(
              "ELIMINAR",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
