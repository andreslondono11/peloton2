import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // ✅ NUEVO
import '../../BD/db_manager.dart';

class InventarioMirasScreen extends StatefulWidget {
  const InventarioMirasScreen({super.key});

  @override
  State<InventarioMirasScreen> createState() => _InventarioMirasScreenState();
}

class _InventarioMirasScreenState extends State<InventarioMirasScreen> {
  List<Map<String, dynamic>> _datosMiras = [];
  final ImagePicker _picker = ImagePicker();
  String? _nombreUsuario;
  bool _isProcessing = false; // ✅ NUEVO

  // ✅ PLANTILLA ÚNICA: Exportar e Importar leen de aquí
  static const List<Map<String, dynamic>> _columnasExcel = [
    {'header': 'N°', 'key': '_index', 'type': 'int'},
    {'header': 'GRD', 'key': 'grd', 'type': 'text'},
    {
      'header': 'APELLIDOS Y NOMBRES',
      'key': 'apellidos_nombres',
      'type': 'text',
    },
    {'header': 'AVN', 'key': 'numero_avn', 'type': 'text'},
    {'header': 'MIRAS MOR', 'key': 'numero_miras_mor', 'type': 'text'},
    {'header': 'NIMROD 6X40', 'key': 'numero_mira_nimrod', 'type': 'text'},
    {'header': 'IMPRONTA', 'key': 'impronta_mira_nimrod', 'type': 'text'},
    // Nota: 'foto_path' se omite porque las fotos no se pueden importar desde un Excel
  ];

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
      print("Error cargando usuario en miras: $e");
      if (mounted) setState(() => _nombreUsuario = "Sin sesión");
    }
  }

  Future<void> _cargarDatos() async {
    try {
      // 1. Intentamos la consulta normal
      final db = await DBManager.instance.database;
      final data = await db.query('inventario_miras');

      if (mounted) {
        setState(() => _datosMiras = data);
      }
    } catch (e) {
      debugPrint(
        "❌ Error de memoria en BD (Miras): $e. Reiniciando conexión...",
      );

      // 2. GUARDAMOS EL ID ANTES de que fullReset() lo borre
      final int? userIdGuardado = DBManager.instance.currentUserId;

      // 3. Matamos la conexión corrupta en RAM
      await DBManager.instance.fullReset();

      // 4. Volvemos a abrir la BD forzando la sesión del usuario correcto
      if (userIdGuardado != null) {
        await DBManager.instance.initUserSession(userIdGuardado);
      } else {
        await DBManager.instance.database;
      }

      // 5. Reintentamos la consulta YA CON LA CONEXIÓN LIMPIA
      try {
        final dbFresh = await DBManager.instance.database;
        final dataFresh = await dbFresh.query('inventario_miras');

        if (mounted) {
          setState(() => _datosMiras = dataFresh);
          debugPrint("✅ Datos de miras recuperados correctamente.");
        }
      } catch (e2) {
        debugPrint("❌ Error definitivo cargando miras: $e2");
        if (mounted) {
          setState(
            () => _datosMiras = [],
          ); // Deja la lista vacía pero no crashea la app
        }
      }
    }
  }

  // ✅ EXPORTAR MODERNIZADO (Sin hojas en blanco)
  Future<void> _exportarExcel() async {
    try {
      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel['Miras'];

      // Eliminar la molesta hoja en blanco 'Sheet1'
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Genera encabezados automáticamente
      List<ex.CellValue> headers = _columnasExcel
          .map((col) => ex.TextCellValue(col['header'] as String))
          .toList();
      sheet.appendRow(headers);

      // Genera filas automáticamente
      for (int i = 0; i < _datosMiras.length; i++) {
        var r = _datosMiras[i];
        List<ex.CellValue> row = [];

        for (var col in _columnasExcel) {
          if (col['key'] == '_index') {
            row.add(ex.IntCellValue(i + 1));
          } else if (col['type'] == 'text') {
            row.add(ex.TextCellValue(r[col['key']]?.toString() ?? ''));
          } else {
            row.add(ex.IntCellValue(r[col['key']] ?? 0));
          }
        }
        sheet.appendRow(row);
      }

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/Reporte_Miras_Completo.xlsx");
      var bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], text: 'Reporte de Miras');
      }
    } catch (e) {
      debugPrint("Error Excel: $e");
    }
  }

  // ✅ NUEVO: MÉTODO PARA IMPORTAR EXCEL
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
        var excel = ex.Excel.decodeBytes(bytes);

        // Busca la hoja 'Miras' directamente
        var table = excel.tables['Miras'] ?? excel.tables.values.first;

        if (table == null || table.rows.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("El archivo no tiene datos válidos."),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isProcessing = false);
          return;
        }

        final db = await DBManager.instance.database;
        int importadosCount = 0;

        // Ignorar fila 0 (encabezados)
        for (int i = 1; i < table.rows.length; i++) {
          var row = table.rows[i];

          if (row.isEmpty || (row[0]?.value == null && row[1]?.value == null)) {
            continue;
          }

          Map<String, dynamic> registroMap = {
            'foto_path': null, // Las fotos no se importan
          };

          for (int c = 0; c < _columnasExcel.length; c++) {
            String key = _columnasExcel[c]['key'];

            // Ignorar el índice '_index'
            if (key == '_index') continue;

            if (_columnasExcel[c]['type'] == 'text') {
              registroMap[key] = _getCellValue(row[c]);
            } else {
              registroMap[key] = _getCellIntValue(row[c]);
            }
          }

          await db.insert('inventario_miras', registroMap);
          importadosCount++;
        }

        await _cargarDatos();
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Se importaron $importadosCount registros correctamente.",
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al importar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helpers para leer celdas
  String _getCellValue(ex.Data? cell) {
    if (cell == null || cell.value == null) return "";
    return cell.value.toString();
  }

  int _getCellIntValue(ex.Data? cell) {
    if (cell == null || cell.value == null) return 0;
    if (cell.value is int) return cell.value as int;
    return int.tryParse(cell.value.toString()) ?? 0;
  }

  Future<String?> _seleccionarImagen(BuildContext context) async {
    return await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería del dispositivo'),
              onTap: () async {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                Navigator.pop(context, image?.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () async {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                Navigator.pop(context, image?.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _abrirFormulario({Map<String, dynamic>? item}) {
    final esEdicion = item != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String? rutaImagen = esEdicion ? item['foto_path'] : null;

    final ctrls = {
      'grd': TextEditingController(text: esEdicion ? item['grd'] : ''),
      'nom': TextEditingController(
        text: esEdicion ? item['apellidos_nombres'] : '',
      ),
      'avn': TextEditingController(text: esEdicion ? item['numero_avn'] : ''),
      'mor': TextEditingController(
        text: esEdicion ? item['numero_miras_mor'] : '',
      ),
      'nimrod': TextEditingController(
        text: esEdicion ? item['numero_mira_nimrod'] : '',
      ),
      'impronta': TextEditingController(
        text: esEdicion ? item['impronta_mira_nimrod'] : '',
      ),
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? Colors.black : Colors.white,
          title: Text(esEdicion ? "Editar Mira" : "Nueva Mira Técnica"),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      String? path = await _seleccionarImagen(context);
                      if (path != null) setDialogState(() => rutaImagen = path);
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                        image: rutaImagen != null
                            ? DecorationImage(
                                image: FileImage(File(rutaImagen!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: rutaImagen == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 50),
                                Text("Toque para elegir imagen"),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildInput(ctrls['grd']!, "GRD", Icons.military_tech),
                  _buildInput(
                    ctrls['nom']!,
                    "APELLIDOS Y NOMBRES",
                    Icons.person,
                  ),
                  _buildInput(ctrls['avn']!, "N° AVN", Icons.visibility),
                  _buildInput(ctrls['mor']!, "N° MIRAS MOR", Icons.biotech),
                  _buildInput(
                    ctrls['nimrod']!,
                    "N° MIRA NIMROD 6X40",
                    Icons.center_focus_strong,
                  ),
                  _buildInput(
                    ctrls['impronta']!,
                    "IMPRONTA NIMROD",
                    Icons.fingerprint,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = await DBManager.instance.database;
                final values = {
                  'grd': ctrls['grd']!.text,
                  'apellidos_nombres': ctrls['nom']!.text,
                  'numero_avn': ctrls['avn']!.text,
                  'numero_miras_mor': ctrls['mor']!.text,
                  'numero_mira_nimrod': ctrls['nimrod']!.text,
                  'impronta_mira_nimrod': ctrls['impronta']!.text,
                  'foto_path': rutaImagen,
                };
                if (esEdicion) {
                  await db.update(
                    'inventario_miras',
                    values,
                    where: 'id=?',
                    whereArgs: [item['id']],
                  );
                } else {
                  await db.insert('inventario_miras', values);
                }
                _cargarDatos();
                Navigator.pop(context);
              },
              child: const Text("GUARDAR"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: const Text("CONTROL DE MIRAS"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
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
      body: Column(
        children: [
          // ✅ NUEVO: Indicador de carga
          if (_isProcessing) const LinearProgressIndicator(),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _abrirFormulario(),
                  icon: const Icon(Icons.add),
                  label: const Text("NUEVO"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportarExcel,
                  icon: const Icon(Icons.file_download),
                  label: const Text("EXPORTAR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                // ✅ NUEVO: Botón Importar
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _importarExcel,
                  icon: const Icon(Icons.file_upload),
                  label: const Text("IMPORTAR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFF1A237E),
                  ),
                  columns: const [
                    DataColumn(
                      label: Text("N°", style: TextStyle(color: Colors.white)),
                    ),
                    DataColumn(
                      label: Text("GRD", style: TextStyle(color: Colors.white)),
                    ),
                    DataColumn(
                      label: Text(
                        "NOMBRES",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text("AVN", style: TextStyle(color: Colors.white)),
                    ),
                    DataColumn(
                      label: Text(
                        "MIRAS MOR",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "NIMROD 6X40",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "IMPRONTA",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "ACCIONES",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                  rows: _datosMiras.asMap().entries.map((e) {
                    final r = e.value;
                    return DataRow(
                      color: WidgetStatePropertyAll(
                        isDark ? Colors.grey[900] : Colors.white38,
                      ),
                      cells: [
                        DataCell(
                          Text(
                            "${e.key + 1}",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${r['grd']}",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${r['apellidos_nombres']}",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${r['numero_avn']}",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${r['numero_miras_mor']}",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${r['numero_mira_nimrod']}",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${r['impronta_mira_nimrod']}",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.visibility,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MirasDetalles(data: r),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                onPressed: () => _abrirFormulario(item: r),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final db = await DBManager.instance.database;
                                  await db.delete(
                                    'inventario_miras',
                                    where: 'id=?',
                                    whereArgs: [r['id']],
                                  );
                                  _cargarDatos();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController c, String l, IconData i) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: c,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: l,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(i, size: 20, color: Colors.blue[900]),
          filled: true,
          fillColor: Colors.transparent,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Campo requerido';
          }
          return null;
        },
      ),
    );
  }
}

// ... (La clase MirasDetalles permanece exactamente igual, no necesita cambios) ...
class MirasDetalles extends StatefulWidget {
  final Map<String, dynamic> data;
  const MirasDetalles({super.key, required this.data});

  @override
  State<MirasDetalles> createState() => _MirasDetallesState();
}

class _MirasDetallesState extends State<MirasDetalles> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String? rutaFoto = widget.data['foto_path'];

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Text("Detalle: ${widget.data['apellidos_nombres']}"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 400,
              width: 600,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2226),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: rutaFoto != null && rutaFoto.isNotEmpty
                    ? Image.file(
                        File(rutaFoto),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 60,
                                  color: Colors.redAccent,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  "Archivo no encontrado",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.center_focus_strong,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Sin fotografía del equipo",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            _cardInfo("Asignación de Personal", [
              _dato("Grado (GRD):", widget.data['grd'] ?? 'N/A'),
              _dato(
                "Apellidos y Nombres:",
                widget.data['apellidos_nombres'] ?? 'N/A',
              ),
            ], Icons.person),
            _cardInfo("Ópticas y Dispositivos", [
              _dato("Número AVN:", widget.data['numero_avn'] ?? 'N/A'),
              _dato("Miras MOR:", widget.data['numero_miras_mor'] ?? 'N/A'),
              _dato(
                "Mira Nimrod 6X40:",
                widget.data['numero_mira_nimrod'] ?? 'N/A',
              ),
            ], Icons.visibility),
            _cardInfo("Seguridad e Improntas", [
              _dato(
                "Impronta Nimrod:",
                widget.data['impronta_mira_nimrod'] ?? 'N/A',
              ),
              _dato("ID Registro:", "#${widget.data['id']}"),
            ], Icons.fingerprint),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _cardInfo(String title, List<Widget> items, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      color: isDark ? Colors.black : Colors.white,
      elevation: 4,
      shadowColor: isDark ? Colors.white54 : Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isDark ? Colors.white : Colors.blueGrey,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.blueGrey,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const Divider(height: 30, thickness: 1),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _dato(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
