import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as ex;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart'; // ✅ NUEVO
import 'package:peloton/provider/apptex.dart';
import 'package:peloton/Gbd/armamento/armas_acomp.dart';
import 'package:peloton/Gbd/armamento/fusil_reg.dart';
import 'package:peloton/Gbd/armamento/miras_reg.dart';
import 'package:peloton/BD/db_manager.dart';

class ArmamentoMenuScreen extends StatefulWidget {
  const ArmamentoMenuScreen({super.key});

  @override
  State<ArmamentoMenuScreen> createState() => _ArmamentoMenuScreenState();
}

class _ArmamentoMenuScreenState extends State<ArmamentoMenuScreen> {
  String? _nombreUsuario;
  String? _correoUsuario;
  final GlobalKey _menuButtonKey = GlobalKey();
  bool _isProcessing = false; // ✅ NUEVO

  @override
  void initState() {
    super.initState();
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
            _correoUsuario = usuario.first['correo'] as String?;
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

  void _cerrarSesion() {
    print("Cerrando sesión desde Armamento...");
  }

  void _mostrarMenuDesplegable() async {
    RenderBox button =
        _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
    RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final Color accentColor = AppStyles.accentColor(context);

    await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _nombreUsuario ?? "Usuario",
                style: AppStyles.mainTitle(
                  context,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                _correoUsuario ?? "Sin correo",
                style: AppStyles.tableCell(
                  context,
                ).copyWith(fontSize: 13, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: accentColor, size: 20),
              const SizedBox(width: 10),
              Text("Cerrar Sesión", style: TextStyle(color: accentColor)),
            ],
          ),
        ),
      ],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).cardColor,
    ).then((value) {
      if (value == 'logout') {
        _cerrarSesion();
      }
    });
  }

  // ✅ NUEVO: EXPORTAR GENERAL (Ejemplo genérico, puedes adaptar la tabla si necesitas)
  Future<void> _exportarGeneral() async {
    try {
      setState(() => _isProcessing = true);
      var excel = ex.Excel.createExcel();
      ex.Sheet sheet = excel['Resumen_Global'];

      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1'); // ✅ Elimina la hoja en blanco
      }

      sheet.appendRow([
        ex.TextCellValue('Módulo'),
        ex.TextCellValue('Total Registros'),
      ]);

      final db = await DBManager.instance.database;

      // Cuenta registros de las 3 tablas para un resumen rápido
      int fusiles = (await db.query('inventario_armamento')).length;
      int miras = (await db.query('inventario_miras')).length;
      int acomp = (await db.query('inventario_especial')).length;

      sheet.appendRow([ex.TextCellValue('Fusiles'), ex.IntCellValue(fusiles)]);
      sheet.appendRow([ex.TextCellValue('Miras'), ex.IntCellValue(miras)]);
      sheet.appendRow([
        ex.TextCellValue('Acompañamiento'),
        ex.IntCellValue(acomp),
      ]);

      final dir = await getTemporaryDirectory();
      final file = File("${dir.path}/Resumen_Armamento_Global.xlsx");
      var bytes = excel.encode();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Resumen Global de Armamento');
      }
      setState(() => _isProcessing = false);
    } catch (e) {
      setState(() => _isProcessing = false);
      AppStyles.showSnackBar(context, "Error: $e", isError: true);
    }
  }

  // ✅ NUEVO: IMPORTAR GENERAL
  Future<void> _importarGeneral() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        AppStyles.showSnackBar(
          context,
          "Por favor importe los archivos desde las sub-categorías (Fusiles, Miras, etc.) para evitar errores de columnas.",
          isError: false,
        );
      }
    } catch (e) {
      AppStyles.showSnackBar(context, "Error: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "CONTROL DE ARMAMENTO",
          style: AppStyles.mainTitle(
            context,
          ).copyWith(color: Colors.white, fontSize: 18, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
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
                InkWell(
                  key: _menuButtonKey,
                  onTap: _mostrarMenuDesplegable,
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
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
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF0D1117) : Colors.grey[100],
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Categorías Bélicas",
                      style: AppStyles.mainTitle(
                        context,
                      ).copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Seleccione el tipo de material para gestionar el inventario",
                      style: AppStyles.tableCell(
                        context,
                      ).copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                // ✅ NUEVO: BOTONES GLOBALES
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _exportarGeneral,
                      icon: const Icon(Icons.file_download, size: 18),
                      label: const Text("RESUMEN EXCEL"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 25,
                mainAxisSpacing: 25,
                children: [
                  _weaponOptionCard(
                    context,
                    "Fusiles",
                    "Armamento Largo",
                    Icons.straighten,
                    const Color(0xFF37474F),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) =>
                              const ArmamentoTablaScreen(categoria: ''),
                        ),
                      );
                    },
                  ),
                  _weaponOptionCard(
                    context,
                    "Miras",
                    "Ópticos y Precisión",
                    Icons.visibility,
                    const Color(0xFF455A64),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const InventarioMirasScreen(),
                        ),
                      );
                    },
                  ),
                  _weaponOptionCard(
                    context,
                    "Acompañamiento",
                    "Apoyo y Pesados",
                    Icons.groups_3,
                    const Color(0xFF263238),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) =>
                              const InventarioEspecialScreen(categoria: ''),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weaponOptionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 45, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
