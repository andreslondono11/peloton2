import 'package:flutter/material.dart';
import 'package:peloton/registro_minuta/minuta/inteligencia.dart';
import 'package:peloton/registro_minuta/minuta/minuta.dart';
import 'package:peloton/registro_minuta/minuta/operacional.dart';
import 'package:peloton/provider/apptex.dart';
import 'package:peloton/BD/db_manager.dart';

class RegistroDiarioScreen extends StatefulWidget {
  const RegistroDiarioScreen({super.key});

  @override
  State<RegistroDiarioScreen> createState() => _RegistroDiarioScreenState();
}

class _RegistroDiarioScreenState extends State<RegistroDiarioScreen> {
  String? _nombreUsuario;
  String? _correoUsuario; // ---> NUEVA VARIABLE
  bool _cargando = true;

  // ---> NUEVA CLAVE GLOBAL PARA EL MENÚ
  final GlobalKey _menuButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  // ---> MÉTODO ROBUSTO OPTIMIZADO (Actualizado para correo) <---
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
          setState(() {
            _nombreUsuario = usuario.first['nombres'] as String?;
            // ---> OBTENER CORREO (Ajusta 'correo' si en tu BD es 'email')
            _correoUsuario = usuario.first['correo'] as String?;
            _cargando = false;
          });
          return;
        }
      }
    } catch (e) {
      print("Error cargando usuario en registro diario: $e");
    }
    if (mounted) setState(() => _cargando = false);
  }

  // ---> MÉTODO PARA CERRAR SESIÓN
  void _cerrarSesion() {
    // Tu lógica para cerrar sesión aquí
    print("Cerrando sesión desde Registro Diario...");
    // Navigator.pushReplacementNamed(context, '/login');
  }

  // ---> MÉTODO DEL MENÚ DESPLEGABLE
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "REGISTRO DIARIO",
          style: AppStyles.mainTitle(
            context,
          ).copyWith(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
        elevation: 0,
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
                // ---> BOTÓN INTERACTIVO DEL MENÚ
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
                      ), // Indicador visual
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
            Text(
              "Seleccione una categoría",
              style: AppStyles.mainTitle(context).copyWith(fontSize: 28),
            ),
            const SizedBox(height: 10),
            Text(
              "Módulos de registro y control institucional",
              style: AppStyles.tableCell(context).copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 25,
                mainAxisSpacing: 25,
                children: [
                  _optionCard(
                    context,
                    "Minutas",
                    "Registro de novedades",
                    Icons.history_edu,
                    const Color(0xFF00BFA5),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MinutasScreen(),
                      ),
                    ),
                  ),
                  _optionCard(
                    context,
                    "Inteligencia",
                    "Análisis de datos",
                    Icons.psychology,
                    const Color(0xFF263238),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InteligenciaScreen(),
                      ),
                    ),
                  ),
                  _optionCard(
                    context,
                    "Qso Operacional",
                    "Control de radio",
                    Icons.radio,
                    const Color(0xFF1A237E),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OperacionalScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
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
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
