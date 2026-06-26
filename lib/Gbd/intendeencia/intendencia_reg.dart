import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:excel/excel.dart' as ex;
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart'; // ✅ NUEVO: Importar file_picker
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:peloton/Gbd/intendeencia/detalles.dart';
import '../../BD/db_manager.dart';

// ==========================================
// 1. MODELO DE DATOS: INTENDENCIA
// ==========================================
class Intendencia {
  final int? id;
  final int no;
  final String grado;
  final String apellidosNombres;
  final Map<String, dynamic> equipo;
  final String? fotoPath;
  final String? observaciones;

  Intendencia({
    this.id,
    required this.no,
    required this.grado,
    required this.apellidosNombres,
    required this.equipo,
    this.fotoPath,
    this.observaciones,
  });

  Map<String, dynamic> toMap() {
    final map = {
      'no': no,
      'grado': grado,
      'apellidos_nombres': apellidosNombres,
      'foto_path': fotoPath,
      'observaciones': observaciones,
    };
    map.addAll(equipo);
    return map;
  }

  factory Intendencia.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> eq = {};
    [
      'camuflado_1',
      'camuflado_2',
      'equipo_campana',
      'botas_par',
      'camisetas_verdes',
      'medias_negras',
      'marmita',
      'hamaca',
      'poncho_pixelado',
      'cintela',
      'colchoneta',
      'estuche_jarro_cantimplora',
      'boxer',
      'toalla_verde',
    ].forEach((k) {
      if (k.contains('camuflado')) {
        eq[k] = map[k]?.toString() ?? "";
      } else {
        eq[k] = map[k] ?? 0;
      }
    });

    return Intendencia(
      id: map['id'],
      no: map['no'],
      grado: map['grado'],
      apellidosNombres: map['apellidos_nombres'],
      fotoPath: map['foto_path'],
      observaciones: map['observaciones'],
      equipo: eq,
    );
  }
}

// ==========================================
// 2. PANTALLA PRINCIPAL
// ==========================================
class IntendenciaPage extends StatefulWidget {
  const IntendenciaPage({super.key});

  @override
  State<IntendenciaPage> createState() => _IntendenciaPageState();
}

class _IntendenciaPageState extends State<IntendenciaPage>
    with SingleTickerProviderStateMixin {
  int? _editId;
  String? _nombreUsuario;
  bool _isProcessing = false; // ✅ NUEVO: Indicador de carga

  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  List<Intendencia> _registros = [];
  final TextEditingController _noCtrl = TextEditingController();
  final TextEditingController _gradoCtrl = TextEditingController();
  final TextEditingController _nombresCtrl = TextEditingController();
  final TextEditingController _obsCtrl = TextEditingController();

  Map<String, dynamic> equipo = {
    'camuflado_1': "",
    'camuflado_2': "",
    'equipo_campana': 0,
    'botas_par': 0,
    'camisetas_verdes': 0,
    'medias_negras': 0,
    'marmita': 0,
    'hamaca': 0,
    'poncho_pixelado': 0,
    'cintela': 0,
    'colchoneta': 0,
    'estuche_jarro_cantimplora': 0,
    'boxer': 0,
    'toalla_verde': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarRegistros();
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
      print("Error cargando usuario en intendencia: $e");
      if (mounted) setState(() => _nombreUsuario = "Sin sesión");
    }
  }

  void _prepararEdicion(Intendencia r) {
    setState(() {
      _editId = r.id;
      _noCtrl.text = r.no.toString();
      _gradoCtrl.text = r.grado;
      _nombresCtrl.text = r.apellidosNombres;
      _obsCtrl.text = r.observaciones ?? "";
      _image = r.fotoPath != null ? File(r.fotoPath!) : null;
      equipo = Map.from(r.equipo);
    });
    _tabController.animateTo(1);
  }

  Future<void> _cargarRegistros() async {
    final db = await DBManager.instance.database;
    final maps = await db.query('intendencia', orderBy: 'id DESC');
    setState(
      () => _registros = maps.map((m) => Intendencia.fromMap(m)).toList(),
    );
  }

  // ✅ NUEVO: MÉTODO PARA IMPORTAR EXCEL
  Future<void> _importarExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isProcessing = true); // Mostrar cargando

        File file = File(result.files.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = ex.Excel.decodeBytes(bytes);

        // Obtiene la primera hoja (usualmente 'Intendencia' si exportaste desde aquí)
        var table = excel.tables[excel.tables.keys.first];

        if (table == null) {
          _mostrarSnack("El archivo no contiene hojas válidas.");
          setState(() => _isProcessing = false);
          return;
        }

        final db = await DBManager.instance.database;
        int importadosCount = 0;

        // Empezar desde la fila 1 (la 0 son los encabezados)
        for (int i = 1; i < table.rows.length; i++) {
          var row = table.rows[i];

          // Validar que la fila no esté completamente vacía
          if (row.isEmpty || (row[0]?.value == null && row[1]?.value == null)) {
            continue;
          }

          // Mapear según el orden de tu Excel: No, Grado, Nombres, Cam1, Cam2, EqCamp, Botas...
          Map<String, dynamic> equipoMap = {
            'camuflado_1': _getCellValue(row[3]),
            'camuflado_2': _getCellValue(row[4]),
            'equipo_campana': _getCellIntValue(row[5]),
            'botas_par': _getCellIntValue(row[6]),
            'camisetas_verdes': _getCellIntValue(row[7]),
            'medias_negras': _getCellIntValue(row[8]),
            'marmita': _getCellIntValue(row[9]),
            'hamaca': _getCellIntValue(row[10]),
            'poncho_pixelado': _getCellIntValue(row[11]),
            'cintela': _getCellIntValue(row[12]),
            'colchoneta': _getCellIntValue(row[13]),
            'estuche_jarro_cantimplora': _getCellIntValue(row[14]),
            'boxer': _getCellIntValue(row[15]),
            'toalla_verde': _getCellIntValue(row[16]),
          };

          Map<String, dynamic> registroMap = {
            'no': _getCellIntValue(row[0]),
            'grado': _getCellValue(row[1]),
            'apellidos_nombres': _getCellValue(row[2]),
            'foto_path': null, // Las fotos no se importan en Excel
            'observaciones': null,
          };

          registroMap.addAll(equipoMap);

          await db.insert('intendencia', registroMap);
          importadosCount++;
        }

        await _cargarRegistros(); // Refrescar la lista
        setState(() => _isProcessing = false);

        _mostrarSnack(
          "Se importaron $importadosCount registros correctamente.",
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _mostrarSnack("Error al importar: $e");
    }
  }

  // ✅ NUEVO: Helpers para leer celdas del Excel sin errores de tipo
  String _getCellValue(ex.Data? cell) {
    if (cell == null || cell.value == null) return "";
    return cell.value.toString();
  }

  int _getCellIntValue(ex.Data? cell) {
    if (cell == null || cell.value == null) return 0;
    if (cell.value is int) return cell.value as int;
    return int.tryParse(cell.value.toString()) ?? 0;
  }

  void _mostrarSnack(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  // --- VISTA DE TABLA (LISTADO) ---
  Widget _buildListView() {
    Future<void> _exportarExcel() async {
      if (_registros.isEmpty) {
        _mostrarSnack("No hay registros para exportar");
        return;
      }

      try {
        var excel = ex.Excel.createExcel();
        ex.Sheet sheetObject = excel['Intendencia'];

        if (excel.sheets.containsKey('Sheet1')) {
          excel.delete('Sheet1');
        }

        List<ex.CellValue> headers = [
          ex.TextCellValue('No'),
          ex.TextCellValue('Grado'),
          ex.TextCellValue('Apellidos y Nombres'),
          ex.TextCellValue('Camuflado N°1'),
          ex.TextCellValue('Camuflado N°2'),
          ex.TextCellValue('Equipo Campaña'),
          ex.TextCellValue('Botas'),
          ex.TextCellValue('Camisetas'),
          ex.TextCellValue('Medias'),
          ex.TextCellValue('Marmita'),
          ex.TextCellValue('Hamaca'),
          ex.TextCellValue('Poncho'),
          ex.TextCellValue('Cintela'),
          ex.TextCellValue('Colchoneta'),
          ex.TextCellValue('Estuche Jarro'),
          ex.TextCellValue('Boxer'),
          ex.TextCellValue('Toalla Verde'),
        ];
        sheetObject.appendRow(headers);

        for (var r in _registros) {
          sheetObject.appendRow([
            ex.IntCellValue(r.no),
            ex.TextCellValue(r.grado),
            ex.TextCellValue(r.apellidosNombres.toUpperCase()),
            ex.TextCellValue(r.equipo['camuflado_1']?.toString() ?? ""),
            ex.TextCellValue(r.equipo['camuflado_2']?.toString() ?? ""),
            ex.IntCellValue(r.equipo['equipo_campana'] ?? 0),
            ex.IntCellValue(r.equipo['botas_par'] ?? 0),
            ex.IntCellValue(r.equipo['camisetas_verdes'] ?? 0),
            ex.IntCellValue(r.equipo['medias_negras'] ?? 0),
            ex.IntCellValue(r.equipo['marmita'] ?? 0),
            ex.IntCellValue(r.equipo['hamaca'] ?? 0),
            ex.IntCellValue(r.equipo['poncho_pixelado'] ?? 0),
            ex.IntCellValue(r.equipo['cintela'] ?? 0),
            ex.IntCellValue(r.equipo['colchoneta'] ?? 0),
            ex.IntCellValue(r.equipo['estuche_jarro_cantimplora'] ?? 0),
            ex.IntCellValue(r.equipo['boxer'] ?? 0),
            ex.IntCellValue(r.equipo['toalla_verde'] ?? 0),
          ]);
        }

        var fileBytes = excel.encode();
        if (fileBytes == null) return;

        final directory = await getTemporaryDirectory();
        final String filePath = p.join(
          directory.path,
          "Reporte_Intendencia.xlsx",
        );
        final File file = File(filePath);
        await file.writeAsBytes(fileBytes, flush: true);

        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Reporte de Intendencia generado desde la App.');
      } catch (e) {
        _mostrarSnack("Error: $e");
      }
    }

    return Column(
      children: [
        // ✅ NUEVO: Indicador de carga superior
        if (_isProcessing) const LinearProgressIndicator(),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 10, // Espacio horizontal entre botones
            runSpacing: 10, // Espacio vertical si se bajan de línea
            children: [
              ElevatedButton.icon(
                onPressed: _exportarExcel,
                icon: const Icon(Icons.file_download),
                label: const Text("Exportar Excel"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
              ),
              // ✅ NUEVO: Botón de Importar
              ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : _importarExcel, // Se deshabilita si está procesando
                icon: const Icon(Icons.file_upload),
                label: const Text("Importar Excel"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[800],
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.add),
                label: const Text("Nuevo Registro"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
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
                columnSpacing: 20,
                columns: const [
                  DataColumn(
                    label: Text(
                      'No',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Grado',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Apellidos y Nombres',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(label: Text('Camuflado 1')),
                  DataColumn(label: Text('Camuflado 2')),
                  DataColumn(label: Text('Eq. Campaña')),
                  DataColumn(label: Text('Botas (Par)')),
                  DataColumn(label: Text('Camisetas V.')),
                  DataColumn(label: Text('Medias N.')),
                  DataColumn(label: Text('Marmita')),
                  DataColumn(label: Text('Hamaca')),
                  DataColumn(label: Text('Poncho P.')),
                  DataColumn(label: Text('Cintela')),
                  DataColumn(label: Text('Colchoneta')),
                  DataColumn(label: Text('Estuche/Jarro')),
                  DataColumn(label: Text('Boxer')),
                  DataColumn(label: Text('Toalla V.')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: _registros
                    .map(
                      (r) => DataRow(
                        cells: [
                          DataCell(Text(r.no.toString())),
                          DataCell(Text(r.grado)),
                          DataCell(Text(r.apellidosNombres.toUpperCase())),
                          DataCell(Text(r.equipo['camuflado_1'] ?? "")),
                          DataCell(Text(r.equipo['camuflado_2'] ?? "")),
                          DataCell(Text(r.equipo['equipo_campana'].toString())),
                          DataCell(Text(r.equipo['botas_par'].toString())),
                          DataCell(
                            Text(r.equipo['camisetas_verdes'].toString()),
                          ),
                          DataCell(Text(r.equipo['medias_negras'].toString())),
                          DataCell(Text(r.equipo['marmita'].toString())),
                          DataCell(Text(r.equipo['hamaca'].toString())),
                          DataCell(
                            Text(r.equipo['poncho_pixelado'].toString()),
                          ),
                          DataCell(Text(r.equipo['cintela'].toString())),
                          DataCell(Text(r.equipo['colchoneta'].toString())),
                          DataCell(
                            Text(
                              r.equipo['estuche_jarro_cantimplora'].toString(),
                            ),
                          ),
                          DataCell(Text(r.equipo['boxer'].toString())),
                          DataCell(Text(r.equipo['toalla_verde'].toString())),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.visibility,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetalleRegistroScreen(registro: r),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _prepararEdicion(r),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _eliminar(r.id!),
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
      ],
    );
  }

  // --- VISTA DE FORMULARIO (Sin cambios internos) ---
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildImagePicker(),
            _buildCard("Identificación", [
              _textF(_noCtrl, "N° de Orden", Icons.tag, num: true),
              _textF(_gradoCtrl, "Grado", Icons.military_tech),
              _textF(_nombresCtrl, "Apellidos y Nombres", Icons.person),
            ]),
            _buildCard("Series Camuflados", [
              _seriesField("SERIE CAMUFLADO N°1", "camuflado_1"),
              _seriesField("SERIE CAMUFLADO N°2", "camuflado_2"),
            ]),
            _buildCard("Cantidades Equipo", [
              ...equipo.keys
                  .where((k) => !k.contains('camuflado'))
                  .map((k) => _counter(k.replaceAll('_', ' ').toUpperCase(), k))
                  .toList(),
            ]),
            _textF(
              _obsCtrl,
              "Observaciones",
              Icons.comment,
              lines: 3,
              req: false,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B262C),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "GUARDAR REGISTRO",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---
  Widget _seriesField(String label, String key) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onChanged: (v) => equipo[key] = v,
    ),
  );

  Widget _counter(String label, String key) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: const TextStyle(fontSize: 11)),
      Row(
        children: [
          IconButton(
            onPressed: () => setState(
              () => equipo[key] = (equipo[key] > 0) ? equipo[key] - 1 : 0,
            ),
            icon: const Icon(Icons.remove_circle, color: Colors.red),
          ),
          Text("${equipo[key]}"),
          IconButton(
            onPressed: () => setState(() => equipo[key]++),
            icon: const Icon(Icons.add_circle, color: Colors.green),
          ),
        ],
      ),
    ],
  );

  Widget _buildCard(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 15),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    ),
  );

  Widget _textF(
    TextEditingController c,
    String l,
    IconData i, {
    bool num = false,
    int lines = 1,
    bool req = true,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: TextFormField(
      controller: c,
      keyboardType: num ? TextInputType.number : TextInputType.text,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        border: const OutlineInputBorder(),
      ),
      validator: req ? (v) => v!.isEmpty ? "Requerido" : null : null,
    ),
  );

  Widget _buildImagePicker() => GestureDetector(
    onTap: () => _mostrarOpcionesFoto(context),
    child: Container(
      height: 100,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[200],
      ),
      child: _image == null
          ? const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.grey),
                Text(
                  "Toca para añadir foto",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_image!, fit: BoxFit.cover),
            ),
    ),
  );

  void _mostrarOpcionesFoto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería del dispositivo'),
                onTap: () {
                  _seleccionarImagen(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  _seleccionarImagen(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _seleccionarImagen(ImageSource fuente) async {
    final img = await _picker.pickImage(source: fuente, imageQuality: 50);
    if (img != null) setState(() => _image = File(img.path));
  }

  void _guardar() async {
    if (_formKey.currentState!.validate()) {
      final db = await DBManager.instance.database;
      final esEdicion = _editId != null;
      final item = Intendencia(
        id: _editId,
        no: int.tryParse(_noCtrl.text) ?? 0,
        grado: _gradoCtrl.text,
        apellidosNombres: _nombresCtrl.text,
        equipo: Map.from(equipo),
        fotoPath: _image?.path,
        observaciones: _obsCtrl.text,
      );

      if (_editId == null) {
        await db.insert('intendencia', item.toMap());
      } else {
        await db.update(
          'intendencia',
          item.toMap(),
          where: 'id = ?',
          whereArgs: [_editId],
        );
      }

      _noCtrl.clear();
      _gradoCtrl.clear();
      _nombresCtrl.clear();
      _obsCtrl.clear();
      setState(() {
        _editId = null;
        _image = null;
        equipo.updateAll((k, v) => k.contains('camuflado') ? "" : 0);
      });

      _cargarRegistros();
      _tabController.animateTo(0);
      _mostrarSnack(esEdicion ? "Actualizado con éxito" : "Guardado con éxito");
    }
  }

  void _eliminar(int id) async {
    final db = await DBManager.instance.database;
    await db.delete('intendencia', where: 'id = ?', whereArgs: [id]);
    _cargarRegistros();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text("Gestión de Intendencia"),
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
        bottom: TabBar(
          labelColor: Colors.white,
          overlayColor: const WidgetStatePropertyAll(Colors.blueGrey),
          unselectedLabelColor: Colors.white70,
          controller: _tabController,
          tabs: const [
            Tab(text: "LISTADO"),
            Tab(text: "NUEVO"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildListView(), _buildFormView()],
      ),
    );
  }
}
