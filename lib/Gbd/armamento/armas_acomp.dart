import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // ✅ NUEVO
import '../../BD/db_manager.dart';

class InventarioEspecialScreen extends StatefulWidget {
  final String categoria;
  const InventarioEspecialScreen({super.key, required this.categoria});

  @override
  State<InventarioEspecialScreen> createState() =>
      _InventarioEspecialScreenState();
}

class _InventarioEspecialScreenState extends State<InventarioEspecialScreen> {
  List<Map<String, dynamic>> _datosTecnicos = [];
  final String _tablaEspecial = 'inventario_especial';
  final ImagePicker _picker = ImagePicker();
  String? _nombreUsuario;
  bool _isProcessing = false; // ✅ NUEVO

  // ✅ PLANTILLA ÚNICA: Exportar e Importar leen de aquí
  static const List<Map<String, dynamic>> _columnasExcel = [
    {'header': 'Nº', 'key': '_index', 'type': 'int'},
    {'header': 'GRD', 'key': 'grd', 'type': 'text'},
    {'header': 'NOMBRES', 'key': 'apellidos_nombres', 'type': 'text'},
    {'header': 'N° ARMA', 'key': 'n_arma', 'type': 'text'},
    {'header': '7.62E', 'key': 'm_762_eslb', 'type': 'int'},
    {'header': '5.56E', 'key': 'm_556_eslb', 'type': 'int'},
    {'header': '9MM', 'key': 'm_9mm', 'type': 'int'},
    {'header': '7.62S', 'key': 'm_762_sub', 'type': 'int'},
    {'header': 'CAÑON', 'key': 'canon', 'type': 'int'},
    {'header': 'IM26', 'key': 'g_im26', 'type': 'int'},
    {'header': 'HUMO', 'key': 'g_humo', 'type': 'int'},
    {'header': '40MM', 'key': 'g_40mm', 'type': 'int'},
    {'header': 'LAGRI', 'key': 'g_lacrimogena', 'type': 'int'},
    {'header': 'TRAMPA', 'key': 'trampa_ilu', 'type': 'int'},
    {'header': 'P.7.62', 'key': 'prov_762', 'type': 'int'},
    {'header': 'P.9MM', 'key': 'prov_9mm', 'type': 'int'},
    {'header': 'CASCO', 'key': 'casco_kevlar', 'type': 'int'},
    {'header': 'LENTES', 'key': 'lentes', 'type': 'int'},
    {'header': 'PORTA', 'key': 'porta_arma', 'type': 'int'},
    {'header': 'SUPRE', 'key': 'supresor', 'type': 'int'},
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
          setState(() => _nombreUsuario = usuario.first['nombres'] as String?);
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
    try {
      // 1. Intentamos la consulta normal
      final db = await DBManager.instance.database;
      final data = await db.query(
        _tablaEspecial,
        where: 'categoria = ?',
        whereArgs: [widget.categoria],
      );

      if (mounted) {
        setState(() => _datosTecnicos = data);
      }
    } catch (e) {
      debugPrint(
        "❌ Error de memoria en BD (Especial): $e. Reiniciando conexión...",
      );

      // 2. GUARDAMOS EL ID ANTES del reset
      final int? userIdGuardado = DBManager.instance.currentUserId;

      // 3. Matamos la conexión corrupta
      await DBManager.instance.fullReset();

      // 4. Restauramos la sesión correcta
      if (userIdGuardado != null) {
        await DBManager.instance.initUserSession(userIdGuardado);
      } else {
        await DBManager.instance.database;
      }

      // 5. Reintentamos la consulta
      try {
        final dbFresh = await DBManager.instance.database;
        final dataFresh = await dbFresh.query(
          _tablaEspecial,
          where: 'categoria = ?',
          whereArgs: [widget.categoria],
        );

        if (mounted) {
          setState(() => _datosTecnicos = dataFresh);
          debugPrint("✅ Datos técnicos recuperados correctamente.");
        }
      } catch (e2) {
        debugPrint("❌ Error definitivo cargando datos técnicos: $e2");
        if (mounted) {
          setState(() => _datosTecnicos = []); // Evita crashear la app
        }
      }
    }
  }

  Future<void> _seleccionarImagen(
    ImageSource source,
    Function(String) onSelected,
  ) async {
    final XFile? photo = await _picker.pickImage(source: source);
    if (photo != null) {
      final directory = await getApplicationDocumentsDirectory();
      final String name = "IMG_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final String newPath = "${directory.path}/$name";
      final File localImage = await File(photo.path).copy(newPath);
      onSelected(localImage.path);
    }
  }

  void _opcionesFoto(Function(String) onSelected) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.gallery, onSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen(ImageSource.camera, onSelected);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ✅ EXPORTAR MODERNIZADO (Sin hojas en blanco)
  Future<void> _exportarExcel() async {
    try {
      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel['Inventario'];

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1'); // Elimina hoja en blanco
      }

      List<ex.CellValue> headers = _columnasExcel
          .map((col) => ex.TextCellValue(col['header'] as String))
          .toList();
      sheet.appendRow(headers);

      for (int i = 0; i < _datosTecnicos.length; i++) {
        var r = _datosTecnicos[i];
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
      final file = File("${dir.path}/Reporte_${widget.categoria}.xlsx");
      var bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Reporte de Material Especializado');
      }
    } catch (e) {
      debugPrint("Error: $e");
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

        var table = excel.tables['Inventario'] ?? excel.tables.values.first;

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

        for (int i = 1; i < table.rows.length; i++) {
          var row = table.rows[i];

          if (row.isEmpty || (row[0]?.value == null && row[1]?.value == null)) {
            continue;
          }

          Map<String, dynamic> registroMap = {
            'categoria': widget.categoria, // Se asigna la categoría actual
            'foto_path': null, // Las fotos no se importan
          };

          for (int c = 0; c < _columnasExcel.length; c++) {
            String key = _columnasExcel[c]['key'];
            if (key == '_index') continue;

            if (_columnasExcel[c]['type'] == 'text') {
              registroMap[key] = _getCellValue(row[c]);
            } else {
              registroMap[key] = _getCellIntValue(row[c]);
            }
          }

          await db.insert(_tablaEspecial, registroMap);
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

  void _abrirFormulario({Map<String, dynamic>? item}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final esEdicion = item != null;
    String? rutaImagen = esEdicion ? item['foto_path'] : null;

    final ctrls = {
      'grd': TextEditingController(text: esEdicion ? item['grd'] : ''),
      'nom': TextEditingController(
        text: esEdicion ? item['apellidos_nombres'] : '',
      ),
      'arma': TextEditingController(text: esEdicion ? item['n_arma'] : ''),
      'm762e': TextEditingController(
        text: esEdicion ? item['m_762_eslb'].toString() : '0',
      ),
      'm556e': TextEditingController(
        text: esEdicion ? item['m_556_eslb'].toString() : '0',
      ),
      'm762s': TextEditingController(
        text: esEdicion ? item['m_762_sub'].toString() : '0',
      ),
      'm9mm': TextEditingController(
        text: esEdicion ? item['m_9mm'].toString() : '0',
      ),
      'gIm26': TextEditingController(
        text: esEdicion ? item['g_im26'].toString() : '0',
      ),
      'gHumo': TextEditingController(
        text: esEdicion ? item['g_humo'].toString() : '0',
      ),
      'g40mm': TextEditingController(
        text: esEdicion ? item['g_40mm'].toString() : '0',
      ),
      'gLacri': TextEditingController(
        text: esEdicion ? item['g_lacrimogena'].toString() : '0',
      ),
      'canon': TextEditingController(
        text: esEdicion ? item['canon'].toString() : '0',
      ),
      'trampa': TextEditingController(
        text: esEdicion ? item['trampa_ilu'].toString() : '0',
      ),
      'casco': TextEditingController(
        text: esEdicion ? item['casco_kevlar'].toString() : '0',
      ),
      'lentes': TextEditingController(
        text: esEdicion ? item['lentes'].toString() : '0',
      ),
      'prov762': TextEditingController(
        text: esEdicion ? item['prov_762'].toString() : '0',
      ),
      'prov9mm': TextEditingController(
        text: esEdicion ? item['prov_9mm'].toString() : '0',
      ),
      'porta': TextEditingController(
        text: esEdicion ? item['porta_arma'].toString() : '0',
      ),
      'supre': TextEditingController(
        text: esEdicion ? item['supresor'].toString() : '0',
      ),
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? Colors.black : Colors.white,
          title: Text(esEdicion ? "Editar Registro" : "Nuevo Registro Técnico"),
          content: SizedBox(
            width: 800,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _opcionesFoto(
                      (path) => setDialogState(() => rutaImagen = path),
                    ),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: rutaImagen != null
                            ? DecorationImage(
                                image: FileImage(File(rutaImagen!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: rutaImagen == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_search,
                                  size: 40,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.blueAccent,
                                ),
                                Text("Agregar Foto"),
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
                  _buildInput(ctrls['arma']!, "N° ARMA", Icons.qr_code),
                  const Divider(color: Colors.black26),
                  _row([
                    _buildInput(
                      ctrls['m762e']!,
                      "7.62 E",
                      Icons.adjust,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['m556e']!,
                      "5.56 E",
                      Icons.adjust,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(
                      ctrls['m762s']!,
                      "7.62 S",
                      Icons.adjust,
                      n: true,
                    ),
                    _buildInput(ctrls['m9mm']!, "9 MM", Icons.adjust, n: true),
                  ]),
                  _row([
                    _buildInput(ctrls['gIm26']!, "IM26", Icons.circle, n: true),
                    _buildInput(ctrls['gHumo']!, "HUMO", Icons.cloud, n: true),
                  ]),
                  _row([
                    _buildInput(ctrls['g40mm']!, "40 MM", Icons.api, n: true),
                    _buildInput(
                      ctrls['gLacri']!,
                      "LAGRI",
                      Icons.masks,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(
                      ctrls['canon']!,
                      "CAÑÓN",
                      Icons.straighten,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['supre']!,
                      "SUPRE",
                      Icons.volume_off,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(
                      ctrls['casco']!,
                      "CASCO",
                      Icons.security,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['lentes']!,
                      "LENTES",
                      Icons.visibility,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(
                      ctrls['prov762']!,
                      "P. 7.62",
                      Icons.inventory,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['prov9mm']!,
                      "P. 9MM",
                      Icons.inventory,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(
                      ctrls['trampa']!,
                      "TRAMPA",
                      Icons.warning,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['porta']!,
                      "PORTA",
                      Icons.backpack,
                      n: true,
                    ),
                  ]),
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
                final data = {
                  'categoria': widget.categoria,
                  'foto_path': rutaImagen,
                  'grd': ctrls['grd']!.text,
                  'apellidos_nombres': ctrls['nom']!.text,
                  'n_arma': ctrls['arma']!.text,
                  'm_762_eslb': int.tryParse(ctrls['m762e']!.text) ?? 0,
                  'm_556_eslb': int.tryParse(ctrls['m556e']!.text) ?? 0,
                  'm_762_sub': int.tryParse(ctrls['m762s']!.text) ?? 0,
                  'm_9mm': int.tryParse(ctrls['m9mm']!.text) ?? 0,
                  'g_im26': int.tryParse(ctrls['gIm26']!.text) ?? 0,
                  'g_humo': int.tryParse(ctrls['gHumo']!.text) ?? 0,
                  'g_40mm': int.tryParse(ctrls['g40mm']!.text) ?? 0,
                  'g_lacrimogena': int.tryParse(ctrls['gLacri']!.text) ?? 0,
                  'canon': int.tryParse(ctrls['canon']!.text) ?? 0,
                  'trampa_ilu': int.tryParse(ctrls['trampa']!.text) ?? 0,
                  'casco_kevlar': int.tryParse(ctrls['casco']!.text) ?? 0,
                  'lentes': int.tryParse(ctrls['lentes']!.text) ?? 0,
                  'prov_762': int.tryParse(ctrls['prov762']!.text) ?? 0,
                  'prov_9mm': int.tryParse(ctrls['prov9mm']!.text) ?? 0,
                  'porta_arma': int.tryParse(ctrls['porta']!.text) ?? 0,
                  'supresor': int.tryParse(ctrls['supre']!.text) ?? 0,
                };

                if (esEdicion) {
                  await db.update(
                    _tablaEspecial,
                    data,
                    where: 'id = ?',
                    whereArgs: [item['id']],
                  );
                } else {
                  await db.insert(_tablaEspecial, data);
                }

                Navigator.pop(context);
                _cargarDatos();
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
        title: Text("INVENTARIO: ${widget.categoria.toUpperCase()}"),
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
                  headingRowColor: WidgetStateProperty.all(
                    const Color(0xFF1A237E),
                  ),
                  columnSpacing: 15,
                  horizontalMargin: 10,
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
                      label: Text(
                        "ARMA",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "7.62E",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "5.56E",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text("9MM", style: TextStyle(color: Colors.white)),
                    ),
                    DataColumn(
                      label: Text(
                        "7.62S",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "CAÑÓN",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "IM26",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "HUMO",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "40MM",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "LAGRI",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "TRAMPA",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "P.7.62",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "P.9MM",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "CASCO",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "LENTES",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "PORTA",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "SUPRE",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "FOTO",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "ACCIONES",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                  rows: _datosTecnicos.asMap().entries.map((e) {
                    final r = e.value;
                    final ts = TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 11,
                    );
                    return DataRow(
                      cells: [
                        DataCell(Text("${e.key + 1}", style: ts)),
                        DataCell(Text("${r['grd']}", style: ts)),
                        DataCell(Text("${r['apellidos_nombres']}", style: ts)),
                        DataCell(Text("${r['n_arma']}", style: ts)),
                        DataCell(Text("${r['m_762_eslb']}", style: ts)),
                        DataCell(Text("${r['m_556_eslb']}", style: ts)),
                        DataCell(Text("${r['m_9mm']}", style: ts)),
                        DataCell(Text("${r['m_762_sub']}", style: ts)),
                        DataCell(Text("${r['canon']}", style: ts)),
                        DataCell(Text("${r['g_im26']}", style: ts)),
                        DataCell(Text("${r['g_humo']}", style: ts)),
                        DataCell(Text("${r['g_40mm']}", style: ts)),
                        DataCell(Text("${r['g_lacrimogena']}", style: ts)),
                        DataCell(Text("${r['trampa_ilu']}", style: ts)),
                        DataCell(Text("${r['prov_762']}", style: ts)),
                        DataCell(Text("${r['prov_9mm']}", style: ts)),
                        DataCell(Text("${r['casco_kevlar']}", style: ts)),
                        DataCell(Text("${r['lentes']}", style: ts)),
                        DataCell(Text("${r['porta_arma']}", style: ts)),
                        DataCell(Text("${r['supresor']}", style: ts)),
                        DataCell(
                          r['foto_path'] != null &&
                                  r['foto_path'].toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(r['foto_path']),
                                    width: 35,
                                    height: 35,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.broken_image,
                                              size: 25,
                                            ),
                                  ),
                                )
                              : const Icon(Icons.person, size: 25),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                icon: const Icon(
                                  Icons.visibility,
                                  color: Colors.green,
                                  size: 18,
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EspecialDetallePage(data: r),
                                  ),
                                ),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                                onPressed: () => _abrirFormulario(item: r),
                              ),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                onPressed: () async {
                                  final db = await DBManager.instance.database;
                                  await db.delete(
                                    _tablaEspecial,
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

  Widget _buildInput(
    TextEditingController c,
    String l,
    IconData i, {
    bool n = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: c,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 13,
        ),
        keyboardType: n ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: l,
          prefixIcon: Icon(i, size: 18),
          border: const OutlineInputBorder(),
          isDense: true,
          filled: true,
          fillColor: isDark ? Colors.grey[900] : Colors.white,
        ),
      ),
    );
  }

  Widget _row(List<Widget> ch) => Row(
    children: ch
        .map(
          (w) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: w,
            ),
          ),
        )
        .toList(),
  );
}

// ... (La clase EspecialDetallePage permanece exactamente igual) ...
class EspecialDetallePage extends StatefulWidget {
  final Map<String, dynamic> data;
  const EspecialDetallePage({super.key, required this.data});

  @override
  State<EspecialDetallePage> createState() => _EspecialDetallePageState();
}

class _EspecialDetallePageState extends State<EspecialDetallePage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String? rutaImagen = widget.data['foto_path'];

    return Scaffold(
      backgroundColor: isDark ? Colors.black12 : Colors.grey[100],
      appBar: AppBar(
        title: Text("Detalle: ${widget.data['apellidos_nombres']}"),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
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
                color: isDark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: rutaImagen != null && rutaImagen.isNotEmpty
                    ? Image.file(
                        File(rutaImagen),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: 50,
                                color: isDark ? Colors.white : Colors.grey,
                              ),
                              const Text("Error al cargar imagen"),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person,
                            size: 80,
                            color: isDark ? Colors.white70 : Colors.black,
                          ),
                          Text(
                            "Sin fotografía disponible",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            _cardInfo("Información Personal", [
              _dato("Grado:", widget.data['grd'] ?? 'N/A'),
              _dato("Nombres:", widget.data['apellidos_nombres'] ?? 'N/A'),
              _dato("N° Arma:", widget.data['n_arma'] ?? 'N/A'),
            ]),
            _cardInfo("Municiones", [
              _dato("7.62 ESLB:", (widget.data['m_762_eslb'] ?? 0).toString()),
              _dato("5.56 ESLB:", (widget.data['m_556_eslb'] ?? 0).toString()),
              _dato("7.62 SUB:", (widget.data['m_762_sub'] ?? 0).toString()),
              _dato("9MM:", (widget.data['m_9mm'] ?? 0).toString()),
              _dato(
                "Prov 7.62 / 9MM:",
                "${widget.data['prov_762'] ?? 0} / ${widget.data['prov_9mm'] ?? 0}",
              ),
            ]),
            _cardInfo("Granadas", [
              _dato("IM/26:", (widget.data['g_im26'] ?? 0).toString()),
              _dato("Humo:", (widget.data['g_humo'] ?? 0).toString()),
              _dato("40MM:", (widget.data['g_40mm'] ?? 0).toString()),
              _dato(
                "Lagrimógena:",
                (widget.data['g_lacrimogena'] ?? 0).toString(),
              ),
              _dato("Trampa ILU:", (widget.data['trampa_ilu'] ?? 0).toString()),
            ]),
            _cardInfo("Equipo Técnico", [
              _dato("Cañón:", (widget.data['canon'] ?? 0).toString()),
              _dato("Supresor:", (widget.data['supresor'] ?? 0).toString()),
              _dato(
                "Casco Kevlar:",
                (widget.data['casco_kevlar'] ?? 0).toString(),
              ),
              _dato("Lentes:", (widget.data['lentes'] ?? 0).toString()),
              _dato("Porta Arma:", (widget.data['porta_arma'] ?? 0).toString()),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _cardInfo(String t, List<Widget> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      color: isDark ? Colors.black : Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: isDark ? Colors.white10 : Colors.blueGrey[100],
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.white : Colors.blueGrey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  t,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.blueGrey,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _dato(String l, String v) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            v,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
