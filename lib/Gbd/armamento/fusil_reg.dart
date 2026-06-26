import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:peloton/provider/apptex.dart';
import '../../BD/db_manager.dart';

class ArmamentoTablaScreen extends StatefulWidget {
  final String categoria;
  const ArmamentoTablaScreen({super.key, required this.categoria});

  @override
  State<ArmamentoTablaScreen> createState() => _ArmamentoTablaScreenState();
}

class _ArmamentoTablaScreenState extends State<ArmamentoTablaScreen> {
  List<Map<String, dynamic>> _allData = [];
  List<Map<String, dynamic>> _filteredData = [];
  final String _tableName = 'inventario_armamento';
  String? _nombreUsuario;
  bool _isProcessing = false;

  // ✅ PLANTILLA ÚNICA PARA EXPORTAR E IMPORTAR
  static const List<Map<String, dynamic>> _columnasExcel = [
    {'header': 'No', 'key': '_index', 'type': 'int'},
    {'header': 'GRD', 'key': 'grd', 'type': 'text'},
    {'header': 'NOMBRES', 'key': 'apellidos_nombres', 'type': 'text'},
    {'header': 'N° ARMA', 'key': 'n_arma', 'type': 'text'},
    {'header': 'MUN 5.56', 'key': 'municion_556', 'type': 'int'},
    {'header': 'PROV 5.56', 'key': 'proveedores_556', 'type': 'int'},
    {'header': 'ESL 5.56', 'key': 'municion_esl_556', 'type': 'int'},
    {'header': 'ESL 7.62', 'key': 'municion_esl_762', 'type': 'int'},
    {'header': 'CAÑON', 'key': 'canon', 'type': 'int'},
    {'header': 'G. MANO', 'key': 'granada_mano', 'type': 'int'},
    {'header': 'G. 60MM', 'key': 'granada_60', 'type': 'int'},
    {'header': 'G. HUMO', 'key': 'granada_humo', 'type': 'int'},
    {'header': 'BENGALAS', 'key': 'bengalas', 'type': 'int'},
    {'header': 'G. LACRI', 'key': 'granada_lacrimogena', 'type': 'int'},
    {'header': 'TRAMPA', 'key': 'trampa_iluminacion', 'type': 'int'},
    {'header': 'G. ATURD', 'key': 'granada_aturdidora', 'type': 'int'},
    {'header': 'PORTA ARMA', 'key': 'porta_arma', 'type': 'int'},
    {'header': 'CASCO', 'key': 'casco', 'type': 'int'},
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
      print("Error cargando usuario: $e");
      if (mounted) setState(() => _nombreUsuario = "Sin sesión");
    }
  }

  Future<void> _cargarDatos() async {
    try {
      // 1. Intentamos la consulta normal
      final db = await DBManager.instance.database;
      final data = await db.query(
        _tableName,
        where: 'categoria = ?',
        whereArgs: [widget.categoria],
      );

      // 2. Si tiene éxito, actualizamos la pantalla
      if (mounted) {
        setState(() {
          _allData = data;
          // Mantenemos el filtro de búsqueda actual al recargar
          _filteredData = data;
        });
      }
    } catch (e) {
      debugPrint("❌ Error de memoria en BD: $e. Reiniciando conexión...");

      // 3. SI FALLA: Matamos la conexión corrupta en RAM
      await DBManager.instance.fullReset();

      // 4. Volvemos a abrir la BD leyendo el archivo físico limpio del disco
      final userId = DBManager.instance.currentUserId;
      if (userId != null) {
        await DBManager.instance.initUserSession(userId);
      } else {
        await DBManager.instance.database; // Abre global si no hay sesión
      }

      // 5. Reintentamos la consulta YA CON LA CONEXIÓN LIMPIA
      try {
        final dbFresh = await DBManager.instance.database;
        final dataFresh = await dbFresh.query(
          _tableName,
          where: 'categoria = ?',
          whereArgs: [widget.categoria],
        );

        if (mounted) {
          setState(() {
            _allData = dataFresh;
            _filteredData = dataFresh;
          });
          debugPrint("✅ Datos recuperados correctamente.");
        }
      } catch (e2) {
        debugPrint("❌ Error definitivo (El backup no tenía la tabla): $e2");
        if (mounted) {
          setState(() {
            _allData = [];
            _filteredData = [];
          });
        }
      }
    }
  }

  void _filtrarBusqueda(String query) {
    setState(() {
      if (query.isEmpty) {
        // Si borramos el campo de búsqueda, mostramos todos los datos otra vez
        _filteredData = _allData;
      } else {
        // Filtramos normalmente
        _filteredData = _allData.where((item) {
          final nombre =
              item['apellidos_nombres']?.toString().toLowerCase() ?? '';
          final nArma = item['n_arma']?.toString().toLowerCase() ?? '';
          return nombre.contains(query.toLowerCase()) ||
              nArma.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _exportarExcel() async {
    try {
      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel['Inventario'];

      // ✅ SOLUCIÓN DEFINITIVA: Eliminar la hoja en blanco 'Sheet1' que crea por defecto
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      List<ex.CellValue> headers = _columnasExcel
          .map((col) => ex.TextCellValue(col['header'] as String))
          .toList();
      sheet.appendRow(headers);

      for (int i = 0; i < _filteredData.length; i++) {
        var r = _filteredData[i];
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

      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/Inventario_${widget.categoria}.xlsx',
      );
      file.writeAsBytesSync(excel.save()!);
      await Share.shareXFiles([XFile(file.path)]);
      AppStyles.showSnackBar(context, "Excel generado");
    } catch (e) {
      AppStyles.showSnackBar(context, "Error: $e", isError: true);
    }
  }

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

        // ✅ Ahora esto buscará 'Inventario' correctamente porque 'Sheet1' ya no existe
        var table = excel.tables['Inventario'] ?? excel.tables.values.first;

        if (table == null || table.rows.isEmpty) {
          AppStyles.showSnackBar(
            context,
            "El archivo no tiene datos válidos.",
            isError: true,
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
            'categoria': widget.categoria,
            'foto_patrimonio': null,
            'observaciones': '',
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

          await db.insert(_tableName, registroMap);
          importadosCount++;
        }

        await _cargarDatos();
        setState(() => _isProcessing = false);
        AppStyles.showSnackBar(
          context,
          "Se importaron $importadosCount registros correctamente.",
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      AppStyles.showSnackBar(context, "Error al importar: $e", isError: true);
    }
  }

  String _getCellValue(ex.Data? cell) {
    if (cell == null || cell.value == null) return "";
    return cell.value.toString();
  }

  int _getCellIntValue(ex.Data? cell) {
    if (cell == null || cell.value == null) return 0;
    if (cell.value is int) return cell.value as int;
    return int.tryParse(cell.value.toString()) ?? 0;
  }

  void _elegirImagen(Function(String) onPick) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () async {
                Navigator.pop(context);
                final i = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 50,
                );
                if (i != null) onPick(i.path);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería / Carpeta'),
              onTap: () async {
                Navigator.pop(context);
                final i = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 50,
                );
                if (i != null) onPick(i.path);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _abrirFormulario({Map<String, dynamic>? item}) {
    final esEdicion = item != null;
    final ctrls = {
      'grd': TextEditingController(text: esEdicion ? item['grd'] : ''),
      'nom': TextEditingController(
        text: esEdicion ? item['apellidos_nombres'] : '',
      ),
      'arma': TextEditingController(text: esEdicion ? item['n_arma'] : ''),
      'm556': TextEditingController(
        text: esEdicion ? item['municion_556'].toString() : '0',
      ),
      'p556': TextEditingController(
        text: esEdicion ? item['proveedores_556'].toString() : '0',
      ),
      'e556': TextEditingController(
        text: esEdicion ? item['municion_esl_556'].toString() : '0',
      ),
      'e762': TextEditingController(
        text: esEdicion ? item['municion_esl_762'].toString() : '0',
      ),
      'can': TextEditingController(
        text: esEdicion ? item['canon'].toString() : '0',
      ),
      'gMano': TextEditingController(
        text: esEdicion ? item['granada_mano'].toString() : '0',
      ),
      'g60': TextEditingController(
        text: esEdicion ? item['granada_60'].toString() : '0',
      ),
      'gHumo': TextEditingController(
        text: esEdicion ? item['granada_humo'].toString() : '0',
      ),
      'ben': TextEditingController(
        text: esEdicion ? item['bengalas'].toString() : '0',
      ),
      'gLac': TextEditingController(
        text: esEdicion ? item['granada_lacrimogena'].toString() : '0',
      ),
      'tra': TextEditingController(
        text: esEdicion ? item['trampa_iluminacion'].toString() : '0',
      ),
      'gAtu': TextEditingController(
        text: esEdicion ? item['granada_aturdidora'].toString() : '0',
      ),
      'port': TextEditingController(
        text: esEdicion ? item['porta_arma'].toString() : '0',
      ),
      'casc': TextEditingController(
        text: esEdicion ? item['casco'].toString() : '0',
      ),
      'obs': TextEditingController(
        text: esEdicion ? item['observaciones'] : '',
      ),
    };
    String? _img = esEdicion ? item['foto_patrimonio'] : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDS) => AlertDialog(
          shape: AppStyles.cardTheme(context).shape,
          backgroundColor: AppStyles.cardTheme(context).color,
          title: Text(
            esEdicion ? "Actualizar" : "Nuevo",
            style: AppStyles.mainTitle(context).copyWith(fontSize: 20),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        _elegirImagen((p) => setStateDS(() => _img = p)),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: AppStyles.tableDecoration(context),
                      child: _img == null
                          ? const Icon(Icons.add_a_photo, size: 40)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(_img!), fit: BoxFit.cover),
                            ),
                    ),
                  ),
                  _buildInput(ctrls['grd']!, "Grado", Icons.military_tech),
                  _buildInput(ctrls['nom']!, "Nombres", Icons.person),
                  _buildInput(ctrls['arma']!, "Serie Arma", Icons.qr_code),
                  const Divider(),
                  _row([
                    _buildInput(
                      ctrls['m556']!,
                      "Mun 5.56",
                      Icons.adjust,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['p556']!,
                      "Prov 5.56",
                      Icons.inventory,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(
                      ctrls['e556']!,
                      "Esl 5.56",
                      Icons.link,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['e762']!,
                      "Esl 7.62",
                      Icons.link,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(ctrls['can']!, "Cañón", Icons.flag, n: true),
                    _buildInput(
                      ctrls['gMano']!,
                      "G. Mano",
                      Icons.circle,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(
                      ctrls['g60']!,
                      "G. 60mm",
                      Icons.adjust,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['gHumo']!,
                      "G. Humo",
                      Icons.cloud,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(
                      ctrls['ben']!,
                      "Bengalas",
                      Icons.flare,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['gLac']!,
                      "G. Lacri",
                      Icons.masks,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(
                      ctrls['tra']!,
                      "Trampa",
                      Icons.warning,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['gAtu']!,
                      "G. Aturdi",
                      Icons.flash_on,
                      n: true,
                    ),
                  ]),
                  _row([
                    _buildInput(
                      ctrls['port']!,
                      "Porta Arma",
                      Icons.backpack,
                      n: true,
                    ),
                    _buildInput(
                      ctrls['casc']!,
                      "Casco",
                      Icons.security,
                      n: true,
                    ),
                  ]),
                  _buildInput(ctrls['obs']!, "Obs", Icons.comment, max: 2),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
            ElevatedButton(
              style: AppStyles.primaryButton(context),
              onPressed: () async {
                final db = await DBManager.instance.database;
                final map = {
                  'categoria': widget.categoria,
                  'grd': ctrls['grd']!.text,
                  'apellidos_nombres': ctrls['nom']!.text,
                  'n_arma': ctrls['arma']!.text,
                  'municion_556': int.tryParse(ctrls['m556']!.text) ?? 0,
                  'proveedores_556': int.tryParse(ctrls['p556']!.text) ?? 0,
                  'municion_esl_556': int.tryParse(ctrls['e556']!.text) ?? 0,
                  'municion_esl_762': int.tryParse(ctrls['e762']!.text) ?? 0,
                  'canon': int.tryParse(ctrls['can']!.text) ?? 0,
                  'granada_mano': int.tryParse(ctrls['gMano']!.text) ?? 0,
                  'granada_60': int.tryParse(ctrls['g60']!.text) ?? 0,
                  'granada_humo': int.tryParse(ctrls['gHumo']!.text) ?? 0,
                  'bengalas': int.tryParse(ctrls['ben']!.text) ?? 0,
                  'granada_lacrimogena': int.tryParse(ctrls['gLac']!.text) ?? 0,
                  'trampa_iluminacion': int.tryParse(ctrls['tra']!.text) ?? 0,
                  'granada_aturdidora': int.tryParse(ctrls['gAtu']!.text) ?? 0,
                  'porta_arma': int.tryParse(ctrls['port']!.text) ?? 0,
                  'casco': int.tryParse(ctrls['casc']!.text) ?? 0,
                  'foto_patrimonio': _img,
                  'observaciones': ctrls['obs']!.text,
                };
                esEdicion
                    ? await db.update(
                        _tableName,
                        map,
                        where: 'id=?',
                        whereArgs: [item['id']],
                      )
                    : await db.insert(_tableName, map);
                Navigator.pop(context);
                _cargarDatos();
                AppStyles.showSnackBar(context, "Guardado");
              },
              child: const Text("GUARDAR"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController c,
    String l,
    IconData i, {
    bool n = false,
    int max = 1,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextField(
      controller: c,
      keyboardType: n ? TextInputType.number : TextInputType.text,
      maxLines: max,
      decoration: AppStyles.inputDecoration(context, label: l, icon: i),
    ),
  );

  Widget _row(List<Widget> ch) => Row(
    children: ch
        .map(
          (w) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: w,
            ),
          ),
        )
        .toList(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuadro Material de Fusiles'),
        backgroundColor: AppStyles.primaryColor(context),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
            child: TextField(
              onChanged: _filtrarBusqueda,
              decoration: AppStyles.inputDecoration(
                context,
                label: "Buscar por nombre o serie...",
                icon: Icons.search,
              ),
            ),
          ),
          if (_isProcessing) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Wrap(
              spacing: 15,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _abrirFormulario(),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("NUEVO REGISTRO"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppStyles.primaryColor(context),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportarExcel,
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  label: const Text("EXPORTAR EXCEL"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _importarExcel,
                  icon: const Icon(Icons.file_upload, color: Colors.white),
                  label: const Text("IMPORTAR EXCEL"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: AppStyles.tableDecoration(context),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(dataTableTheme: AppStyles.tableTheme(context)),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("No")),
                        DataColumn(label: Text("GRD")),
                        DataColumn(label: Text("Nombres")),
                        DataColumn(label: Text("N° Arma")),
                        DataColumn(label: Text("Mun 5.56")),
                        DataColumn(label: Text("Prov 5.56")),
                        DataColumn(label: Text("Esl 5.56")),
                        DataColumn(label: Text("Esl 7.62")),
                        DataColumn(label: Text("Cañon")),
                        DataColumn(label: Text("G. Mano")),
                        DataColumn(label: Text("G. 60")),
                        DataColumn(label: Text("G. Humo")),
                        DataColumn(label: Text("Beng")),
                        DataColumn(label: Text("G. Lac")),
                        DataColumn(label: Text("Trampa")),
                        DataColumn(label: Text("G. Atur")),
                        DataColumn(label: Text("Porta")),
                        DataColumn(label: Text("Casco")),
                        DataColumn(label: Text("Acción")),
                      ],
                      rows: _filteredData
                          .map(
                            (r) => DataRow(
                              cells: [
                                DataCell(
                                  Text("${_filteredData.indexOf(r) + 1}"),
                                ),
                                DataCell(Text(r['grd'] ?? '')),
                                DataCell(Text(r['apellidos_nombres'] ?? '')),
                                DataCell(Text(r['n_arma'] ?? '')),
                                DataCell(Text("${r['municion_556']}")),
                                DataCell(Text("${r['proveedores_556']}")),
                                DataCell(Text("${r['municion_esl_556']}")),
                                DataCell(Text("${r['municion_esl_762']}")),
                                DataCell(Text("${r['canon']}")),
                                DataCell(Text("${r['granada_mano']}")),
                                DataCell(Text("${r['granada_60']}")),
                                DataCell(Text("${r['granada_humo']}")),
                                DataCell(Text("${r['bengalas']}")),
                                DataCell(Text("${r['granada_lacrimogena']}")),
                                DataCell(Text("${r['trampa_iluminacion']}")),
                                DataCell(Text("${r['granada_aturdidora']}")),
                                DataCell(Text("${r['porta_arma']}")),
                                DataCell(Text("${r['casco']}")),
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
                                                  ArmamentoDetalleScreen(
                                                    datos: r,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            _abrirFormulario(item: r),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        onPressed: () async {
                                          final db =
                                              await DBManager.instance.database;
                                          await db.delete(
                                            _tableName,
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
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ... (ArmamentoDetalleScreen permanece exactamente igual) ...
class ArmamentoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> datos;

  ArmamentoDetalleScreen({super.key, required this.datos});

  @override
  State<ArmamentoDetalleScreen> createState() => _ArmamentoDetalleScreenState();
}

class _ArmamentoDetalleScreenState extends State<ArmamentoDetalleScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.datos['apellidos_nombres'] ?? 'Detalle'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 400,
              width: 600,
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child:
                    widget.datos['foto_patrimonio'] != null &&
                        widget.datos['foto_patrimonio'].toString().isNotEmpty
                    ? Image.file(
                        File(widget.datos['foto_patrimonio']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                      )
                    : Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: isDark ? Colors.grey : Colors.black,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text("Información General", style: AppStyles.mainTitle(context)),
            const Divider(),
            _buildInfoTable([
              _itemDetalle("Grado:", widget.datos['grd']),
              _itemDetalle("Nombres:", widget.datos['apellidos_nombres']),
              _itemDetalle("Serie Arma:", widget.datos['n_arma']),
              _itemDetalle("Tipo de Arma:", widget.datos['tipo_arma']),
            ]),
            const SizedBox(height: 15),
            Text(
              "Inventario y Cantidades",
              style: AppStyles.mainTitle(context),
            ),
            const Divider(),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _chipInfo("Mun 5.56", widget.datos['municion_556']),
                _chipInfo("Prov 5.56", widget.datos['proveedores_556']),
                _chipInfo("Esl 5.56", widget.datos['municion_esl_556']),
                _chipInfo("Esl 7.62", widget.datos['municion_esl_762']),
                _chipInfo("Cañón", widget.datos['canon']),
                _chipInfo("G. Mano", widget.datos['granada_mano']),
                _chipInfo("G. 40mm", widget.datos['granada_40mm']),
                _chipInfo("G. 60mm", widget.datos['granada_60mm']),
                _chipInfo("G. Humo", widget.datos['granada_humo']),
                _chipInfo("G. Lacri.", widget.datos['granada_lacrimogena']),
                _chipInfo("G. Aturdi.", widget.datos['granada_aturdidora']),
                _chipInfo("Bengalas", widget.datos['bengalas']),
                _chipInfo("Trampa Ilu.", widget.datos['trampa_iluminacion']),
                _chipInfo("Casco", widget.datos['casco']),
                _chipInfo("Chaleco", widget.datos['chaleco']),
                _chipInfo("Porta Arma", widget.datos['porta_arma']),
              ],
            ),
            const SizedBox(height: 15),
            Text("Observaciones", style: AppStyles.mainTitle(context)),
            const Divider(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: Text(
                (widget.datos['observaciones'] != null &&
                        widget.datos['observaciones'].toString().isNotEmpty)
                    ? widget.datos['observaciones']
                    : 'Sin observaciones registradas.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTable(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }

  Widget _itemDetalle(String label, dynamic valor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "${valor ?? 'N/A'}",
              style: TextStyle(color: isDark ? Colors.white : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipInfo(String label, dynamic valor) {
    bool tieneMaterial =
        (valor != null &&
        valor.toString() != "0" &&
        valor.toString().isNotEmpty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tieneMaterial
              ? Colors.blueGrey.shade200
              : Colors.grey.shade800,
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(color: Colors.white70),
            ),
            TextSpan(
              text: "${valor ?? '0'}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
