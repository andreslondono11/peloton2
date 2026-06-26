import 'dart:io';
import 'package:excel/excel.dart'
    show TextCellValue, IntCellValue, Excel, Sheet, CellValue, Data;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart'; // ✅ NUEVO
import '../BD/db_manager.dart';
import 'package:peloton/provider/apptex.dart';

class ComunicacionesScreen extends StatefulWidget {
  const ComunicacionesScreen({super.key});

  @override
  State<ComunicacionesScreen> createState() => _ComunicacionesScreenState();
}

class _ComunicacionesScreenState extends State<ComunicacionesScreen> {
  List<Map<String, dynamic>> _datos = [];
  bool _cargando = true;
  String? _nombreUsuario;
  bool _isProcessing = false; // ✅ NUEVO

  // ✅ PLANTILLA ÚNICA: Sincroniza Exportar, Importar y Encabezados de Tabla
  static const List<Map<String, dynamic>> _columnasExcel = [
    {'header': 'No', 'key': 'no', 'type': 'int'},
    {'header': 'GDO', 'key': 'gdo', 'type': 'text'},
    {'header': 'Nombres', 'key': 'nombres', 'type': 'text'},
    {'header': 'Clase Radio', 'key': 'clase_radio', 'type': 'text'},
    {'header': 'No Radio', 'key': 'no_radio', 'type': 'text'},
    {'header': 'A. Tubular', 'key': 'antena_tubular', 'type': 'int'},
    {'header': 'A. Latigo', 'key': 'antena_latigo', 'type': 'int'},
    {'header': 'Arnes', 'key': 'arnes', 'type': 'int'},
    {'header': 'Microtelefono', 'key': 'microtelefono', 'type': 'int'},
    {'header': 'Bolso', 'key': 'bolso', 'type': 'int'},
    {'header': 'B. Antena', 'key': 'base_antena', 'type': 'int'},
    {'header': 'Tapa Bat', 'key': 'tapa_baterias', 'type': 'int'},
    {'header': 'B. Latigo', 'key': 'base_latigo', 'type': 'int'},
    {'header': 'B. Tubular', 'key': 'base_tubular', 'type': 'int'},
    {'header': 'A. Flex', 'key': 'antena_flexible', 'type': 'int'},
    {'header': 'Baterias', 'key': 'baterias', 'type': 'int'},
    {'header': 'Perillas', 'key': 'perillas', 'type': 'int'},
    {'header': 'Cargador', 'key': 'cargador', 'type': 'int'},
    {'header': 'Protector', 'key': 'protector', 'type': 'int'},
    {'header': 'Clip', 'key': 'clip', 'type': 'int'},
    {'header': 'GPS', 'key': 'antena_gps', 'type': 'int'},
    {'header': 'C. APX', 'key': 'cargador_apx', 'type': 'int'},
    {'header': 'GPS 56', 'key': 'antena_gps_5602', 'type': 'int'},
    {'header': 'Chaleco', 'key': 'chaleco', 'type': 'int'},
    {'header': 'Paneles', 'key': 'paneles', 'type': 'int'},
    {'header': 'Garmin', 'key': 'gps_garmin', 'type': 'int'},
    {'header': 'Flecher', 'key': 'flecher', 'type': 'int'},
    {'header': 'OBS', 'key': 'observaciones', 'type': 'text'},
  ];

  @override
  void initState() {
    super.initState();
    _leerBD();
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
      print("Error cargando usuario en comunicaciones: $e");
    }
  }

  Future<void> _leerBD() async {
    final db = await DBManager.instance.database;
    final res = await db.query('comunicaciones', orderBy: 'id ASC');
    setState(() {
      _datos = res;
      _cargando = false;
    });
  }

  Future<void> _eliminar(int id) async {
    final db = await DBManager.instance.database;
    await db.delete('comunicaciones', where: 'id = ?', whereArgs: [id]);
    AppStyles.showSnackBar(
      context,
      "Registro eliminado con éxito",
      isError: true,
    );
    _leerBD();
  }

  // ✅ EXPORTAR MODERNIZADO (Sin hojas en blanco y basado en plantilla)
  Future<void> _exportarExcel() async {
    if (_datos.isEmpty) {
      AppStyles.showSnackBar(
        context,
        "No hay datos para exportar",
        isError: true,
      );
      return;
    }

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Comunicaciones'];
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      List<CellValue> headers = _columnasExcel
          .map((col) => TextCellValue(col['header'] as String))
          .toList();
      sheetObject.appendRow(headers);

      for (var row in _datos) {
        List<CellValue> fila = [];
        for (var col in _columnasExcel) {
          if (col['type'] == 'text') {
            fila.add(TextCellValue(row[col['key']]?.toString() ?? ''));
          } else {
            fila.add(IntCellValue(row[col['key']] ?? 0));
          }
        }
        sheetObject.appendRow(fila);
      }

      var fileBytes = excel.save();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/Inventario_Comunicaciones.xlsx');
      await file.writeAsBytes(fileBytes!);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Cuadro de Comunicaciones');
      AppStyles.showSnackBar(context, "Excel generado exitosamente");
    } catch (e) {
      AppStyles.showSnackBar(context, "Error al exportar: $e", isError: true);
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
        var excel = Excel.decodeBytes(bytes);

        var table = excel.tables['Comunicaciones'] ?? excel.tables.values.first;

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

          Map<String, dynamic> registroMap = {};

          for (int c = 0; c < _columnasExcel.length; c++) {
            String key = _columnasExcel[c]['key'];

            if (_columnasExcel[c]['type'] == 'text') {
              registroMap[key] = _getCellValue(row[c]);
            } else {
              registroMap[key] = _getCellIntValue(row[c]);
            }
          }

          await db.insert('comunicaciones', registroMap);
          importadosCount++;
        }

        await _leerBD();
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

  // Helpers para leer celdas
  String _getCellValue(Data? cell) {
    if (cell == null || cell.value == null) return "";
    return cell.value.toString();
  }

  int _getCellIntValue(Data? cell) {
    if (cell == null || cell.value == null) return 0;
    if (cell.value is int) return cell.value as int;
    return int.tryParse(cell.value.toString()) ?? 0;
  }

  void _abrirFormulario({Map<String, dynamic>? item}) {
    final ctrls = {
      'gdo': TextEditingController(text: item?['gdo'] ?? ''),
      'nom': TextEditingController(text: item?['nombres'] ?? ''),
      'clase': TextEditingController(text: item?['clase_radio'] ?? ''),
      'radio': TextEditingController(text: item?['no_radio'] ?? ''),
      'obs': TextEditingController(text: item?['observaciones'] ?? ''),
    };

    Map<String, int> cant = {
      'a_tub': item?['antena_tubular'] ?? 0,
      'a_lat': item?['antena_latigo'] ?? 0,
      'arnes': item?['arnes'] ?? 0,
      'micro': item?['microtelefono'] ?? 0,
      'bolso': item?['bolso'] ?? 0,
      'b_ant': item?['base_antena'] ?? 0,
      't_bat': item?['tapa_baterias'] ?? 0,
      'b_lat': item?['base_latigo'] ?? 0,
      'b_tub': item?['base_tubular'] ?? 0,
      'a_flex': item?['antena_flexible'] ?? 0,
      'bat': item?['baterias'] ?? 0,
      'per': item?['perillas'] ?? 0,
      'carg': item?['cargador'] ?? 0,
      'prot': item?['protector'] ?? 0,
      'clip': item?['clip'] ?? 0,
      'gps': item?['antena_gps'] ?? 0,
      'c_apx': item?['cargador_apx'] ?? 0,
      'gps_5602': item?['antena_gps_5602'] ?? 0,
      'chaleco': item?['chaleco'] ?? 0,
      'paneles': item?['paneles'] ?? 0,
      'garmin': item?['gps_garmin'] ?? 0,
      'flecher': item?['flecher'] ?? 0,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.isDark(context)
            ? const Color(0xFF0D1117)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          item == null ? "Registrar Personal" : "Editar Registro",
          style: AppStyles.mainTitle(context),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _sectionTitle("DATOS BÁSICOS"),
                _txt(ctrls['gdo']!, "GDO", Icons.military_tech),
                _txt(ctrls['nom']!, "Apellidos y Nombres", Icons.person),
                _txt(ctrls['clase']!, "Clase Radio", Icons.radio),
                _txt(ctrls['radio']!, "No Radio", Icons.numbers),
                const Divider(height: 30),
                _sectionTitle("ELEMENTOS TÉCNICOS"),
                ...cant.entries.map(
                  (e) => _num(
                    e.key.replaceAll('_', ' ').toUpperCase(),
                    e.value,
                    (v) => cant[e.key] = v,
                  ),
                ),
                const SizedBox(height: 15),
                _txt(ctrls['obs']!, "Observaciones", Icons.comment),
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
            style: AppStyles.primaryButton(context),
            onPressed: () async {
              final db = await DBManager.instance.database;
              final data = {
                'no': item == null ? _datos.length + 1 : item['no'],
                'gdo': ctrls['gdo']!.text,
                'nombres': ctrls['nom']!.text,
                'clase_radio': ctrls['clase']!.text,
                'no_radio': ctrls['radio']!.text,
                'antena_tubular': cant['a_tub'],
                'antena_latigo': cant['a_lat'],
                'arnes': cant['arnes'],
                'microtelefono': cant['micro'],
                'bolso': cant['bolso'],
                'base_antena': cant['b_ant'],
                'tapa_baterias': cant['t_bat'],
                'base_latigo': cant['b_lat'],
                'base_tubular': cant['b_tub'],
                'antena_flexible': cant['a_flex'],
                'baterias': cant['bat'],
                'perillas': cant['per'],
                'cargador': cant['carg'],
                'protector': cant['prot'],
                'clip': cant['clip'],
                'antena_gps': cant['gps'],
                'cargador_apx': cant['c_apx'],
                'antena_gps_5602': cant['gps_5602'],
                'chaleco': cant['chaleco'],
                'paneles': cant['paneles'],
                'gps_garmin': cant['garmin'],
                'flecher': cant['flecher'],
                'observaciones': ctrls['obs']!.text,
              };
              item == null
                  ? await db.insert('comunicaciones', data)
                  : await db.update(
                      'comunicaciones',
                      data,
                      where: 'id = ?',
                      whereArgs: [item['id']],
                    );
              Navigator.pop(context);
              _leerBD();
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.isDark(context)
          ? const Color(0xFF0D1117)
          : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "Cuadro de Comunicaciones",
          style: AppStyles.mainTitle(context).copyWith(color: Colors.white),
        ),
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isProcessing) const LinearProgressIndicator(), // ✅ NUEVO
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: AppStyles.tableDecoration(context),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: _buildCols(),
                          rows: _buildRows(),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBotonesInferiores(),
              ],
            ),
    );
  }

  List<DataColumn> _buildCols() {
    // ✅ MEJORA: Genera los encabezados automáticamente desde la plantilla para evitar errores
    return [
      ..._columnasExcel.map(
        (col) => DataColumn(label: Text(col['header'] as String)),
      ),
      const DataColumn(label: Text("Acc")),
    ];
  }

  List<DataRow> _buildRows() {
    return _datos.map((i) {
      return DataRow(
        cells: [
          ..._columnasExcel.map((col) {
            // Pone en negrita solo la columna de nombres
            if (col['key'] == 'nombres') {
              return DataCell(
                Text(
                  "${i[col['key']]}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }
            return DataCell(Text("${i[col['key']] ?? ''}"));
          }),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _abrirFormulario(item: i),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminar(i['id']),
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildBotonesInferiores() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: AppStyles.isDark(context) ? const Color(0xFF161B22) : Colors.white,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 15,
        children: [
          _botonCompacto(
            onPressed: () => _abrirFormulario(),
            icon: Icons.person_add,
            label: "NUEVO",
            color: AppStyles.primaryColor(context),
          ),
          _botonCompacto(
            onPressed: _exportarExcel,
            icon: Icons.table_chart,
            label: "EXPORTAR",
            color: Colors.green[800]!,
          ),
          // ✅ NUEVO: Botón Importar
          _botonCompacto(
            onPressed: _isProcessing ? () {} : _importarExcel,
            icon: Icons.upload_file,
            label: "IMPORTAR",
            color: Colors.orange[800]!,
          ),
        ],
      ),
    );
  }

  Widget _botonCompacto({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final bool isDark = AppStyles.isDark(context);
    return SizedBox(
      height: 38,
      width: 130,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: AppStyles.primaryButton(context).copyWith(
          backgroundColor: WidgetStateProperty.all(color),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withOpacity(isDark ? 0.15 : 0.2),
          ),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: TextStyle(
      fontWeight: FontWeight.bold,
      color: AppStyles.accentColor(context),
    ),
  );

  Widget _txt(TextEditingController c, String l, IconData i) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: c,
      decoration: AppStyles.inputDecoration(context, label: l, icon: i),
    ),
  );

  Widget _num(String l, int init, Function(int) onU) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l),
      SizedBox(
        width: 60,
        child: TextFormField(
          initialValue: init.toString(),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          onChanged: (v) => onU(int.tryParse(v) ?? 0),
        ),
      ),
    ],
  );
}
