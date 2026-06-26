import 'package:flutter/material.dart';
import 'package:peloton/diario/exde_reg.dart';
import 'package:peloton/diario/part_comunicacines.dart';
import 'package:peloton/diario/parte_armamento.dart';
import 'package:peloton/provider/apptex.dart';
import 'package:peloton/BD/db_manager.dart';

class OperacionesEspecialesScreen extends StatefulWidget {
  const OperacionesEspecialesScreen({super.key});

  @override
  State<OperacionesEspecialesScreen> createState() =>
      _OperacionesEspecialesScreenState();
}

class _OperacionesEspecialesScreenState
    extends State<OperacionesEspecialesScreen> {
  String? _nombreUsuario;
  String? _correoUsuario; // ---> NUEVA VARIABLE

  // ---> NUEVA CLAVE GLOBAL PARA EL MENÚ
  final GlobalKey _menuButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  Future<void> _cargarNombreUsuario() async {
    // ---> CORRECCIÓN: USAR authDatabase <---
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
            // ---> OBTENER CORREO (Ajusta 'correo' si tu BD usa 'email')
            _correoUsuario = usuario.first['correo'] as String?;
          });
        }
      }
    } catch (e) {
      print("Error cargando usuario en operaciones especiales: $e");
    }
  }

  // ---> MÉTODO PARA CERRAR SESIÓN
  void _cerrarSesion() {
    // Tu lógica para cerrar sesión aquí
    print("Cerrando sesión desde Operaciones Especiales...");
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
          "GESTIÓN DE MATERIAL Y EQUIPO",
          style: AppStyles.mainTitle(
            context,
          ).copyWith(color: Colors.white, fontSize: 18, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Módulos Especializados",
              style: AppStyles.mainTitle(context).copyWith(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              "Seleccione el área de registro técnico para control de inventario.",
              style: AppStyles.tableCell(context).copyWith(
                color: isDark ? Colors.white54 : Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 50),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 30,
                mainAxisSpacing: 30,
                children: [
                  _buildMenuCard(
                    context,
                    "Parte de\nArmamento",
                    "Control de fusiles y munición",
                    Icons.shield_rounded,
                    const Color(0xFF263238),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParteArmamentoScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    "Comunicaciones",
                    "Equipos de radio y señales",
                    Icons.settings_remote_rounded,
                    const Color(0xFF00BFA5),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ComunicacionesScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    "Equipo Exde",
                    "Material explosivo y demolición",
                    Icons.warning_amber_rounded,
                    const Color(0xFFD32F2F),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExdeScreen(),
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

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        splashColor: Colors.white24,
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withOpacity(0.85)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 25),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
