import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart'; // ✅ NUEVO
import 'package:peloton/provider/apptex.dart';
import '../BD/db_manager.dart';

class ExdeScreen extends StatefulWidget {
  const ExdeScreen({super.key});
  @override
  State<ExdeScreen> createState() => _ExdeScreenState();
}

class _ExdeScreenState extends State<ExdeScreen> {
  List<Map<String, dynamic>> _datos = [];
  bool _cargando = true;
  String? _nombreUsuario;
  bool _isProcessing = false; // ✅ NUEVO

  // ✅ PLANTILLA ÚNICA: Exportar e Importar leen exactamente de aquí.
  // Esto soluciona el error donde 'tubo_metalico' no coincidía con 'T_Met' en el Excel anterior.
  static const List<Map<String, dynamic>> _columnasExcel = [
    {'header': 'No', 'key': 'no', 'type': 'int'},
    {'header': 'GRD', 'key': 'grd', 'type': 'text'},
    {'header': 'Nombres', 'key': 'nombres', 'type': 'text'},
    {'header': 'N_Elemento', 'key': 'n_elemento', 'type': 'text'},
    {'header': 'Canino', 'key': 'canino', 'type': 'int'},
    {'header': 'Valom', 'key': 'valom', 'type': 'int'},
    {'header': 'Ecaex', 'key': 'ecaex', 'type': 'int'},
    {'header': 'T_PVC', 'key': 'tubo_pvc', 'type': 'int'},
    {
      'header': 'T_Met',
      'key': 'tubo_metalico',
      'type': 'int',
    }, // Corregido para que apunte al key real de la BD
    {'header': 'G_20m', 'key': 'guindo_20m', 'type': 'int'},
    {'header': 'C_50m', 'key': 'cuerda_50m', 'type': 'int'},
    {'header': 'Gancho', 'key': 'gancho_3puntas', 'type': 'int'},
    {'header': 'B_Pato', 'key': 'boca_pato', 'type': 'int'},
    {'header': 'Estuche', 'key': 'estuche_verde', 'type': 'int'},
    {'header': 'Pera', 'key': 'pera', 'type': 'int'},
    {'header': 'Bolso', 'key': 'bolso_transporte', 'type': 'int'},
    {'header': 'Audio', 'key': 'auriculares', 'type': 'int'},
    {'header': 'Tes', 'key': 'tes_prueba', 'type': 'int'},
    {'header': 'U_Elec', 'key': 'unidad_electrica', 'type': 'int'},
    {'header': 'Cabeza', 'key': 'cabeza_busqueda', 'type': 'int'},
    {'header': 'Pinza', 'key': 'pinzas_sog', 'type': 'int'},
    {'header': 'Cargas', 'key': 'cargas_huecas', 'type': 'int'},
    {'header': 'P_1kg', 'key': 'pentolita_1kg', 'type': 'int'},
    {'header': 'P_1/2', 'key': 'pentolita_1_2kg', 'type': 'int'},
    {'header': 'P_1/4', 'key': 'pentolita_1_4kg', 'type': 'int'},
    {'header': 'P_1/8', 'key': 'pentolita_1_8kg', 'type': 'int'},
    {'header': 'Mecha', 'key': 'mecha_lenta', 'type': 'int'},
    {'header': 'C_12gr', 'key': 'cordon_12gr', 'type': 'int'},
    {'header': 'Det_C', 'key': 'detonador_comun', 'type': 'int'},
    {'header': 'C_6gr', 'key': 'cordon_6gr', 'type': 'int'},
    {'header': 'C_3gr', 'key': 'cordon_3gr', 'type': 'int'},
    {'header': 'D_Elec', 'key': 'detonadores_elec', 'type': 'int'},
    {'header': 'D_Inel', 'key': 'detonadores_inelec', 'type': 'int'},
    {'header': 'Observación', 'key': 'observacion', 'type': 'text'},
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
      print("Error cargando usuario en EXDE: $e");
    }
  }

  Future<void> _leerBD() async {
    final db = await DBManager.instance.database;
    final res = await db.query('exde', orderBy: 'id ASC');
    setState(() {
      _datos = res;
      _cargando = false;
    });
  }

  // ✅ EXPORTAR MODERNIZADO (Sin hojas en blanco y sincronizado con la plantilla)
  Future<void> _exportarExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Inventario_EXDE'];
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1'); // Elimina la hoja en blanco
      }

      // Genera encabezados automáticamente
      List<CellValue> headers = _columnasExcel
          .map((col) => TextCellValue(col['header'] as String))
          .toList();
      sheetObject.appendRow(headers);

      // Genera filas automáticamente
      for (int i = 0; i < _datos.length; i++) {
        var r = _datos[i];
        List<CellValue> row = [];

        for (var col in _columnasExcel) {
          if (col['type'] == 'text') {
            row.add(TextCellValue(r[col['key']]?.toString() ?? ''));
          } else {
            row.add(IntCellValue(r[col['key']] ?? 0));
          }
        }
        sheetObject.appendRow(row);
      }

      final dir = await getTemporaryDirectory();
      final path =
          "${dir.path}/EXDE_${DateTime.now().millisecondsSinceEpoch}.xlsx";
      final bytes = excel.save();
      if (bytes != null) {
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        await Share.shareXFiles([XFile(path)], text: 'Inventario EXDE');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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

        var table =
            excel.tables['Inventario_EXDE'] ?? excel.tables.values.first;

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

          Map<String, dynamic> registroMap = {};

          for (int c = 0; c < _columnasExcel.length; c++) {
            String key = _columnasExcel[c]['key'];

            if (_columnasExcel[c]['type'] == 'text') {
              registroMap[key] = _getCellValue(row[c]);
            } else {
              registroMap[key] = _getCellIntValue(row[c]);
            }
          }

          await db.insert('exde', registroMap);
          importadosCount++;
        }

        await _leerBD();
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
      'grd': TextEditingController(text: item?['grd'] ?? ''),
      'nom': TextEditingController(text: item?['nombres'] ?? ''),
      'elem': TextEditingController(text: item?['n_elemento'] ?? ''),
      'obs': TextEditingController(text: item?['observacion'] ?? ''),
    };

    Map<String, int> cant = {
      'canino': item?['canino'] ?? 0,
      'valom': item?['valom'] ?? 0,
      'ecaex': item?['ecaex'] ?? 0,
      'tubo_pvc': item?['tubo_pvc'] ?? 0,
      'tubo_met': item?['tubo_metalico'] ?? 0,
      'guindo': item?['guindo_20m'] ?? 0,
      'cuerda': item?['cuerda_50m'] ?? 0,
      'gancho': item?['gancho_3puntas'] ?? 0,
      'boca': item?['boca_pato'] ?? 0,
      'estuche': item?['estuche_verde'] ?? 0,
      'pera': item?['pera'] ?? 0,
      'bolso': item?['bolso_transporte'] ?? 0,
      'audio': item?['auriculares'] ?? 0,
      'tes': item?['tes_prueba'] ?? 0,
      'uelec': item?['unidad_electrica'] ?? 0,
      'cabeza': item?['cabeza_busqueda'] ?? 0,
      'pinza': item?['pinzas_sog'] ?? 0,
      'cargas': item?['cargas_huecas'] ?? 0,
      'p1kg': item?['pentolita_1kg'] ?? 0,
      'p12': item?['pentolita_1_2kg'] ?? 0,
      'p14': item?['pentolita_1_4kg'] ?? 0,
      'p18': item?['pentolita_1_8kg'] ?? 0,
      'mecha': item?['mecha_lenta'] ?? 0,
      'c12': item?['cordon_12gr'] ?? 0,
      'det_com': item?['detonador_comun'] ?? 0,
      'c6gr': item?['cordon_6gr'] ?? 0,
      'c3gr': item?['cordon_3gr'] ?? 0,
      'dele': item?['detonadores_elec'] ?? 0,
      'dine': item?['detonadores_inelec'] ?? 0,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: AppStyles.cardTheme(context).shape,
        backgroundColor: AppStyles.cardTheme(context).color,
        title: Text(
          "REGISTRO EXDE",
          style: AppStyles.mainTitle(context).copyWith(fontSize: 20),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _txt(ctrls['grd']!, "Grado"),
                _txt(ctrls['nom']!, "Nombres"),
                _txt(ctrls['elem']!, "Nº Elemento"),
                const Divider(height: 30),
                ...cant.keys.map(
                  (k) => _num(
                    k.toUpperCase().replaceAll('_', ' '),
                    cant[k]!,
                    (v) => cant[k] = v,
                  ),
                ),
                _txt(ctrls['obs']!, "Observaciones", maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: AppStyles.primaryButton(context),
            onPressed: () async {
              final db = await DBManager.instance.database;
              final data = {
                'no': item == null ? _datos.length + 1 : item['no'],
                'grd': ctrls['grd']!.text,
                'nombres': ctrls['nom']!.text,
                'n_elemento': ctrls['elem']!.text,
                'canino': cant['canino'],
                'valom': cant['valom'],
                'ecaex': cant['ecaex'],
                'tubo_pvc': cant['tubo_pvc'],
                'tubo_metalico': cant['tubo_met'],
                'guindo_20m': cant['guindo'],
                'cuerda_50m': cant['cuerda'],
                'gancho_3puntas': cant['gancho'],
                'boca_pato': cant['boca'],
                'estuche_verde': cant['estuche'],
                'pera': cant['pera'],
                'bolso_transporte': cant['bolso'],
                'auriculares': cant['audio'],
                'tes_prueba': cant['tes'],
                'unidad_electrica': cant['uelec'],
                'cabeza_busqueda': cant['cabeza'],
                'pinzas_sog': cant['pinza'],
                'cargas_huecas': cant['cargas'],
                'pentolita_1kg': cant['p1kg'],
                'pentolita_1_2kg': cant['p12'],
                'pentolita_1_4kg': cant['p14'],
                'pentolita_1_8kg': cant['p18'],
                'mecha_lenta': cant['mecha'],
                'cordon_12gr': cant['c12'],
                'detonador_comun': cant['det_com'],
                'cordon_6gr': cant['c6gr'],
                'cordon_3gr': cant['c3gr'],
                'detonadores_elec': cant['dele'],
                'detonadores_inelec': cant['dine'],
                'observacion': ctrls['obs']!.text,
              };
              if (item == null)
                await db.insert('exde', data);
              else
                await db.update(
                  'exde',
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
          : const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("Inventario EXDE"),
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
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isProcessing) const LinearProgressIndicator(), // ✅ NUEVO
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppStyles.isDark(context)
                          ? const Color(0xFF1E2227)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dataTableTheme: AppStyles.tableTheme(context),
                            ),
                            child: DataTable(
                              columns: _buildCols(),
                              rows: _buildRows(),
                            ),
                          ),
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

  Widget _buildBotonesInferiores() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      color: AppStyles.isDark(context) ? const Color(0xFF161B22) : Colors.white,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 20,
        children: [
          _btn(
            onPressed: () => _abrirFormulario(),
            icon: Icons.add,
            label: "NUEVO",
            color: const Color(0xFF1A237E),
          ),
          _btn(
            onPressed: _exportarExcel,
            icon: Icons.download,
            label: "EXPORTAR",
            color: Colors.green[800]!,
          ),
          // ✅ NUEVO: Botón Importar
          _btn(
            onPressed: _isProcessing ? () {} : _importarExcel,
            icon: Icons.upload,
            label: "IMPORTAR",
            color: Colors.orange[800]!,
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return SizedBox(
      height: 40,
      width: 130,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  List<DataColumn> _buildCols() {
    // Se genera automáticamente desde la plantilla para que nunca haya errores humanos
    return [
      ..._columnasExcel.map(
        (col) => DataColumn(
          label: Text(
            col['header'] as String,
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ),
      const DataColumn(label: Text("Acciones", style: TextStyle(fontSize: 10))),
    ];
  }

  List<DataRow> _buildRows() {
    return _datos
        .map(
          (i) => DataRow(
            cells: [
              ..._columnasExcel.map(
                (col) => DataCell(Text("${i[col['key']] ?? ''}")),
              ),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit,
                        size: 18,
                        color: Colors.blue,
                      ),
                      onPressed: () => _abrirFormulario(item: i),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () async {
                        final db = await DBManager.instance.database;
                        await db.delete(
                          'exde',
                          where: 'id = ?',
                          whereArgs: [i['id']],
                        );
                        _leerBD();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .toList();
  }

  Widget _txt(TextEditingController c, String l, {int maxLines = 1}) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: l,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
    ),
  );

  Widget _num(String l, int init, Function(int) onU) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(l, style: const TextStyle(fontSize: 10))),
        SizedBox(
          width: 55,
          child: TextFormField(
            initialValue: init.toString(),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (v) => onU(int.tryParse(v) ?? 0),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.all(8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
