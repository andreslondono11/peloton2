import 'package:flutter/material.dart';
import 'package:peloton/Gbd/personal/lista_personal.dart';
import 'package:peloton/SCREENS/login_screen.dart';
import 'package:peloton/provider/apptex.dart';
import 'package:peloton/Gbd/armamento/reg_armamento.dart';
import 'package:peloton/Gbd/intendeencia/intendencia_reg.dart' hide DBManager;
import 'package:peloton/BD/db_manager.dart';
// ---> ASEGÚRATE DE QUE ESTA RUTA SEA CORRECTA <---
// import 'package:peloton/login/login_screen.dart';

class GestionDBNavigator extends StatefulWidget {
  const GestionDBNavigator({super.key});

  @override
  State<GestionDBNavigator> createState() => _GestionDBNavigatorState();
}

class _GestionDBNavigatorState extends State<GestionDBNavigator> {
  int _selectedIndex = 0;
  String? _nombreUsuario;
  String? _correoUsuario;
  String _mensajeDebug = "";
  bool _cargandoUsuario = true;
  final GlobalKey _menuButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarUsuarioLogueado();
  }

  Future<void> _cargarUsuarioLogueado() async {
    final db = await DBManager.instance.authDatabase;

    try {
      final sesion = await db.query('sesion_activa', limit: 1);

      if (sesion.isEmpty) {
        if (mounted) {
          setState(() {
            _mensajeDebug = "Error Crítico: Sesión perdida";
            _cargandoUsuario = false;
          });
        }
        return;
      }

      final int usuarioId = sesion.first['usuario_id'] as int;

      final usuario = await db.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [usuarioId],
        limit: 1,
      );

      if (mounted) {
        setState(() {
          if (usuario.isNotEmpty) {
            _nombreUsuario = usuario.first['nombres'] as String?;
            final String? correoBD = usuario.first['correo'] as String?;

            if (correoBD != null && correoBD.isNotEmpty) {
              _correoUsuario = correoBD;
            } else {
              _correoUsuario = 'Sin correo';
            }
          } else {
            _mensajeDebug = "Usuario eliminado";
            _correoUsuario = "Desconocido";
          }
          _cargandoUsuario = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _mensajeDebug = "Error BD: $e";
          _cargandoUsuario = false;
        });
      }
    }
  }

  Future<void> _cerrarSesion() async {
    final db = await DBManager.instance.authDatabase;
    final sesion = await db.query('sesion_activa', limit: 1);

    if (sesion.isNotEmpty) {
      int usuarioId = sesion.first['usuario_id'] as int;
      int configHuella = sesion.first['usar_huella'] as int? ?? 0;

      await db.update('sesion_activa', {
        'usuario_id': usuarioId,
        'mantener_sesion': 0,
        'usar_huella': configHuella,
      }, where: 'id = 1');
    }

    await DBManager.instance.closeUserSession();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "GESTIÓN DE BASES DE DATOS",
          style: AppStyles.mainTitle(
            context,
          ).copyWith(color: Colors.white, fontSize: 18, letterSpacing: 1.2),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          // ---> MENÚ DESPLEGABLE CON USUARIO Y CERRAR SESIÓN <---
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
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
                    _cargandoUsuario
                        ? "..."
                        : (_nombreUsuario != null && _nombreUsuario!.isNotEmpty
                              ? _nombreUsuario![0].toUpperCase()
                              : "?"),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Botón que activa el menú
                IconButton(
                  key: _menuButtonKey,
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: _mostrarMenuDesplegable,
                  tooltip: 'Opciones de usuario',
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
              "Administración",
              style: AppStyles.mainTitle(context).copyWith(fontSize: 28),
            ),
            const SizedBox(height: 10),
            Text(
              "Control y actualización de registros maestros",
              style: AppStyles.tableCell(context).copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 25,
                mainAxisSpacing: 25,
                children: [
                  _adminOptionCard(
                    context,
                    "Personal",
                    "Listado Maestro",
                    Icons.badge,
                    const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const ListaPersonalScreen(),
                        ),
                      );
                    },
                  ),
                  _adminOptionCard(
                    context,
                    "Armamento",
                    "Control Bélico",
                    Icons.security,
                    const Color(0xFFC62828),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ArmamentoMenuScreen(),
                      ),
                    ),
                  ),
                  _adminOptionCard(
                    context,
                    "Intendencia",
                    "Suministros",
                    Icons.inventory,
                    const Color(0xFF2E7D32),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => const IntendenciaPage(),
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

  Widget _adminOptionCard(
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
              child: Icon(icon, size: 45, color: Colors.white),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
