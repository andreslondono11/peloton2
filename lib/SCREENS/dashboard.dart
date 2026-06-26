// import 'package:flutter/material.dart';
// import 'package:peloton/SCREENS/ajuste.dart';
// import 'package:peloton/SCREENS/archivo_d.dart';
// import 'package:peloton/SCREENS/dev_loper.dart';
// import 'package:peloton/Gbd/gestion_bd.dart';
// import 'package:peloton/SCREENS/mapa.dart';
// import 'package:peloton/diario/minu_diario.dart';
// import 'package:peloton/registro_minuta/regis_diario.dart';
// import 'package:peloton/SCREENS/seguridad.dart';
// import 'package:peloton/provider/apptex.dart';
// import '../BD/db_manager.dart';
// import 'login_screen.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   int _selectedIndex = 0;
//   String? _nombreUsuario;
//   String _mensajeDebug = "";
//   bool _cargandoUsuario = true;

//   @override
//   void initState() {
//     super.initState();
//     _cargarUsuarioLogueado();
//   }

//   /// MÉTODO CORREGIDO: Usar authDatabase
//   Future<void> _cargarUsuarioLogueado() async {
//     // ---> CORRECCIÓN 1: USAMOS authDatabase <---
//     final db = await DBManager.instance.authDatabase;

//     try {
//       final sesion = await db.query('sesion_activa', limit: 1);

//       if (sesion.isEmpty) {
//         if (mounted)
//           setState(() {
//             _mensajeDebug = "Error Crítico: Sesión perdida";
//             _cargandoUsuario = false;
//           });
//         return;
//       }

//       final int usuarioId = sesion.first['usuario_id'] as int;

//       final usuario = await db.query(
//         'usuarios',
//         where: 'id = ?',
//         whereArgs: [usuarioId],
//         limit: 1,
//       );

//       if (mounted) {
//         setState(() {
//           if (usuario.isNotEmpty) {
//             _nombreUsuario = usuario.first['nombres'] as String?;
//           } else {
//             _mensajeDebug = "Usuario eliminado";
//           }
//           _cargandoUsuario = false;
//         });
//       }
//     } catch (e) {
//       if (mounted)
//         setState(() {
//           _mensajeDebug = "Error BD: $e";
//           _cargandoUsuario = false;
//         });
//     }
//   }

//   /// MÉTODO CORREGIDO: Usar authDatabase y cerrar la sesión del usuario
//   Future<void> _cerrarSesion() async {
//     // ---> CORRECCIÓN 2: USAMOS authDatabase <---
//     final db = await DBManager.instance.authDatabase;
//     final sesion = await db.query('sesion_activa', limit: 1);

//     if (sesion.isNotEmpty) {
//       int usuarioId = sesion.first['usuario_id'] as int;
//       int configHuella = sesion.first['usar_huella'] as int? ?? 0;

//       await db.update('sesion_activa', {
//         'usuario_id': usuarioId,
//         'mantener_sesion': 0,
//         'usar_huella': configHuella,
//       }, where: 'id = 1');
//     }

//     // ---> CORRECCIÓN 3: CERRAMOS LA BD DEL USUARIO PARA QUE EL SIGUIENTE PUEDA ENTRAR <---
//     await DBManager.instance.closeUserSession();

//     if (!mounted) return;
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (context) => const LoginScreen()),
//       (route) => false,
//     );
//   }

//   void _mostrarDialogoSalir() {
//     showDialog(
//       context: context,
//       builder: (dialogContext) => AlertDialog(
//         backgroundColor: Theme.of(context).cardColor,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//         title: Text(
//           "¿Cerrar Sesión?",
//           style: AppStyles.mainTitle(context).copyWith(fontSize: 20),
//         ),
//         content: Text(
//           "Se requerirán credenciales para ingresar de nuevo.",
//           style: AppStyles.tableCell(context),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(dialogContext),
//             child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.redAccent,
//               foregroundColor: Colors.white,
//             ),
//             onPressed: () {
//               Navigator.pop(dialogContext);
//               _cerrarSesion();
//             },
//             child: const Text("SALIR"),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;

//     return Scaffold(
//       body: Row(
//         children: [
//           NavigationRail(
//             backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
//             selectedIndex: _selectedIndex,
//             extended: true,
//             minExtendedWidth: 220,
//             indicatorColor: AppStyles.accentColor(context).withOpacity(0.1),
//             unselectedIconTheme: IconThemeData(
//               color: isDark ? Colors.white24 : Colors.black,
//             ),
//             selectedIconTheme: IconThemeData(
//               color: AppStyles.accentColor(context),
//             ),
//             unselectedLabelTextStyle: TextStyle(
//               color: isDark ? Colors.white24 : Colors.black,
//             ),
//             selectedLabelTextStyle: TextStyle(
//               color: AppStyles.accentColor(context),
//               fontWeight: FontWeight.bold,
//               letterSpacing: 1.1,
//             ),
//             onDestinationSelected: (int index) =>
//                 setState(() => _selectedIndex = index),
//             leading: Column(
//               children: [
//                 const SizedBox(height: 40),
//                 _buildSidebarLogo(context),
//                 const SizedBox(height: 15),
//                 Text(
//                   "CALIPSO",
//                   style: TextStyle(
//                     color: isDark ? Colors.white : const Color(0xFF1A237E),
//                     fontWeight: FontWeight.w900,
//                     fontSize: 18,
//                     letterSpacing: 1.5,
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//               ],
//             ),
//             destinations: const [
//               NavigationRailDestination(
//                 icon: Icon(Icons.dashboard_outlined),
//                 selectedIcon: Icon(Icons.dashboard),
//                 label: Text('INICIO'),
//               ),
//               NavigationRailDestination(
//                 icon: Icon(Icons.folder_open),
//                 label: Text('ARCHIVOS'),
//               ),
//               NavigationRailDestination(
//                 icon: Icon(Icons.settings_outlined),
//                 label: Text('AJUSTES'),
//               ),
//             ],
//             trailing: Expanded(
//               child: Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Padding(
//                   padding: const EdgeInsets.only(bottom: 30),
//                   child: IconButton(
//                     onPressed: _mostrarDialogoSalir,
//                     icon: const Icon(
//                       Icons.power_settings_new_rounded,
//                       color: Colors.redAccent,
//                       size: 28,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: Container(
//               color: theme.scaffoldBackgroundColor,
//               child: IndexedStack(
//                 index: _selectedIndex,
//                 children: [
//                   _buildMainDashboard(context),
//                   const ArchivosPage(),
//                   const AjustesScreen(),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSidebarLogo(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: Border.all(
//           color: AppStyles.accentColor(context).withOpacity(0.3),
//           width: 2,
//         ),
//       ),
//       child: const CircleAvatar(
//         radius: 35,
//         backgroundColor: Colors.transparent,
//         backgroundImage: AssetImage('assets/img/appstore.png'),
//       ),
//     );
//   }

//   Widget _buildMainDashboard(BuildContext context) {
//     String nombreAMostrar = "Usuario";
//     String inicial = "?";
//     Color colorAvatar = Colors.grey;

//     if (_mensajeDebug.isNotEmpty) {
//       nombreAMostrar = _mensajeDebug;
//     } else if (_nombreUsuario != null && _nombreUsuario!.isNotEmpty) {
//       nombreAMostrar = _nombreUsuario!;
//       inicial = nombreAMostrar[0].toUpperCase();
//       colorAvatar = AppStyles.accentColor(context);
//     }

//     return Padding(
//       padding: const EdgeInsets.all(40),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 "Panel Administrativo",
//                 style: AppStyles.mainTitle(context).copyWith(fontSize: 32),
//               ),
//               Row(
//                 children: [
//                   Container(
//                     width: 10,
//                     height: 10,
//                     decoration: BoxDecoration(
//                       color: _mensajeDebug.isNotEmpty
//                           ? Colors.redAccent
//                           : Colors.greenAccent,
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color:
//                               (_mensajeDebug.isNotEmpty
//                                       ? Colors.redAccent
//                                       : Colors.greenAccent)
//                                   .withOpacity(0.5),
//                           blurRadius: 6,
//                           spreadRadius: 1,
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   CircleAvatar(
//                     radius: 20,
//                     backgroundColor: colorAvatar,
//                     child: Text(
//                       inicial,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   _cargandoUsuario
//                       ? const SizedBox(
//                           width: 100,
//                           height: 16,
//                           child: LinearProgressIndicator(
//                             backgroundColor: Colors.transparent,
//                           ),
//                         )
//                       : Text(
//                           nombreAMostrar,
//                           style: AppStyles.tableCell(context).copyWith(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: _mensajeDebug.isNotEmpty
//                                 ? Colors.redAccent
//                                 : null,
//                           ),
//                         ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 30),
//           Expanded(
//             child: GridView.count(
//               crossAxisCount: 3,
//               crossAxisSpacing: 25,
//               mainAxisSpacing: 25,
//               children: [
//                 _AnimatedDashboardCard(
//                   titulo: "Base de Datos",
//                   subtitulo: "Gestión de Unidad",
//                   icono: Icons.storage,
//                   color: Colors.blue,
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const GestionDBNavigator(),
//                     ),
//                   ),
//                 ),
//                 _AnimatedDashboardCard(
//                   titulo: "Registro de Minuta",
//                   subtitulo: "Pelotón",
//                   icono: Icons.book,
//                   color: Colors.redAccent,
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const RegistroDiarioScreen(),
//                     ),
//                   ),
//                 ),
//                 _AnimatedDashboardCard(
//                   titulo: "Registro Diario",
//                   subtitulo: "Operacional",
//                   icono: Icons.badge,
//                   color: Colors.green,
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const OperacionesEspecialesScreen(),
//                     ),
//                   ),
//                 ),
//                 _AnimatedDashboardCard(
//                   titulo: "Desarrollador",
//                   subtitulo: "Modelo DEV",
//                   icono: Icons.developer_mode,
//                   color: Colors.orange,
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const DesarrolladorScreen(),
//                     ),
//                   ),
//                 ),
//                 _AnimatedDashboardCard(
//                   titulo: "Seguridad",
//                   subtitulo: "Políticas",
//                   icono: Icons.security,
//                   color: Colors.purple,
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const SeguridadScreen(),
//                     ),
//                   ),
//                 ),
//                 _AnimatedDashboardCard(
//                   titulo: "Mapa Tactico",
//                   subtitulo: "Módulo Planeamiento",
//                   icono: Icons.map,
//                   color: Colors.teal,
//                   onTap: () => Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const MapaDibujoPage(),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _AnimatedDashboardCard extends StatefulWidget {
//   final String titulo;
//   final String subtitulo;
//   final IconData icono;
//   final Color color;
//   final VoidCallback? onTap;

//   const _AnimatedDashboardCard({
//     required this.titulo,
//     required this.subtitulo,
//     required this.icono,
//     required this.color,
//     this.onTap,
//   });

//   @override
//   State<_AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
// }

// class _AnimatedDashboardCardState extends State<_AnimatedDashboardCard> {
//   bool _isHovered = false;
//   bool _isPressed = false;

//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;

//     return MouseRegion(
//       onEnter: (_) => setState(() => _isHovered = true),
//       onExit: (_) => setState(() => _isHovered = false),
//       child: GestureDetector(
//         onTapDown: (_) => setState(() => _isPressed = true),
//         onTapUp: (_) => setState(() => _isPressed = false),
//         onTapCancel: () => setState(() => _isPressed = false),
//         onTap: widget.onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           curve: Curves.easeOutCubic,
//           transform: Matrix4.identity()
//             ..scale(_isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0)),
//           decoration: BoxDecoration(
//             color: isDark ? const Color(0xFF1C2128) : Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(
//               color: _isHovered
//                   ? widget.color.withOpacity(0.5)
//                   : Colors.transparent,
//               width: 2,
//             ),
//             boxShadow: [
//               BoxShadow(
//                 color: widget.color.withOpacity(_isHovered ? 0.15 : 0.05),
//                 blurRadius: _isHovered ? 20 : 10,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(15),
//                 decoration: BoxDecoration(
//                   color: widget.color.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(widget.icono, size: 40, color: widget.color),
//               ),
//               const SizedBox(height: 15),
//               Text(
//                 widget.titulo,
//                 textAlign: TextAlign.center,
//                 style: AppStyles.tableCell(context).copyWith(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: isDark ? Colors.white : const Color(0xFF1A237E),
//                 ),
//               ),
//               const SizedBox(height: 5),
//               Text(
//                 widget.subtitulo,
//                 textAlign: TextAlign.center,
//                 style: AppStyles.tableCell(
//                   context,
//                 ).copyWith(fontSize: 13, color: Colors.grey),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:peloton/SCREENS/ajuste.dart';
import 'package:peloton/SCREENS/archivo_d.dart';
import 'package:peloton/SCREENS/dev_loper.dart';
import 'package:peloton/Gbd/gestion_bd.dart';
import 'package:peloton/SCREENS/mapa.dart';
import 'package:peloton/SEGURIDAD/configuracion.dart';
import 'package:peloton/diario/minu_diario.dart';
import 'package:peloton/registro_minuta/regis_diario.dart';
import 'package:peloton/SCREENS/seguridad.dart';
import 'package:peloton/provider/apptex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../BD/db_manager.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? _nombreUsuario;
  String? _correoUsuario; // Variable para almacenar el correo
  String _mensajeDebug = "";
  bool _cargandoUsuario = true;

  // Key para posicionar el menú debajo del botón
  final GlobalKey _menuButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarUsuarioLogueado();
  }

  Future<void> _cargarUsuarioLogueado() async {
    // Usamos la misma instancia que usas en LoginScreen
    final db = await DBManager.instance.authDatabase;
    final prefs = await SharedPreferences.getInstance(); // <-- AGREGAR ESTO

    try {
      final sesion = await db.query('sesion_activa', limit: 1);

      if (sesion.isEmpty) {
        // ---> INICIO DEL PARACAÍDAS <---
        final int? ultimoUserId = prefs.getInt('last_logged_user_id');
        if (ultimoUserId != null) {
          final usuarioRespaldo = await db.query(
            'usuarios',
            where: 'id = ?',
            whereArgs: [ultimoUserId],
            limit: 1,
          );
          if (usuarioRespaldo.isNotEmpty && mounted) {
            setState(() {
              _nombreUsuario = usuarioRespaldo.first['nombres'] as String?;
              _correoUsuario =
                  usuarioRespaldo.first['correo'] as String? ?? 'Sin correo';
              _cargandoUsuario = false;
            });
            return;
          }
        }
        // ---> FIN DEL PARACAÍDAS <---

        if (mounted) {
          setState(() {
            _mensajeDebug = "Error Crítico: Sesión perdida";
            _cargandoUsuario = false;
          });
        }
        return;
      }

      // Obtenemos el ID del usuario de la sesión
      final int usuarioId = sesion.first['usuario_id'] as int;

      // Buscamos los datos del usuario usando ese ID
      final usuario = await db.query(
        'usuarios',
        where: 'id = ?',
        whereArgs: [usuarioId],
        limit: 1,
      );

      if (mounted) {
        setState(() {
          if (usuario.isNotEmpty) {
            // Cargamos el nombre
            _nombreUsuario = usuario.first['nombres'] as String?;

            // --- CORRECCIÓN AQUÍ ---
            // Usamos 'correo' porque así se llama la columna en tu LoginScreen
            // y se guarda en la BD.
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
    try {
      // Intentamos obtener la base de datos
      final db = await DBManager.instance.authDatabase;

      // Verificamos explícitamente si está abierta antes de hacer el query
      if (db.isOpen) {
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
      }
    } catch (e) {
      // Si falla porque la BD está cerrada o corrupta tras el backup,
      // lo ignoramos silenciosamente. Lo importante es salir al Login.
      debugPrint(
        "⚠️ La BD estaba cerrada al cerrar sesión (seguramente por un backup reciente). Ignorando error: $e",
      );
    }

    // Intentamos cerrar la sesión del usuario de forma segura
    try {
      await DBManager.instance.closeUserSession();
    } catch (e) {
      debugPrint("⚠️ Error al cerrar sesión en DBManager: $e");
    }

    // Por si las moscas, limpiamos la sesión de SharedPreferences también
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mantener_sesion_activa', false);

    // Navegamos al Login destruyendo el historial
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
        // Cabecera: Nombre y CORREO
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre
              Text(
                _nombreUsuario ?? "Usuario",
                style: AppStyles.mainTitle(
                  context,
                ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              // --- CORREO AQUÍ ---
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
        // Opción: Cerrar Sesión
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.white,
            selectedIndex: _selectedIndex,
            extended: true,
            minExtendedWidth: 220,
            indicatorColor: AppStyles.accentColor(context).withOpacity(0.1),
            unselectedIconTheme: IconThemeData(
              color: isDark ? Colors.white24 : Colors.black,
            ),
            selectedIconTheme: IconThemeData(
              color: AppStyles.accentColor(context),
            ),
            unselectedLabelTextStyle: TextStyle(
              color: isDark ? Colors.white24 : Colors.black,
            ),
            selectedLabelTextStyle: TextStyle(
              color: AppStyles.accentColor(context),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
            onDestinationSelected: (int index) =>
                setState(() => _selectedIndex = index),
            leading: Column(
              children: [
                const SizedBox(height: 40),
                _buildSidebarLogo(context),
                const SizedBox(height: 15),
                Text(
                  "CALIPSO",
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A237E),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('INICIO'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_open),
                label: Text('ARCHIVOS'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text('AJUSTES'),
              ),
            ],
          ),
          Expanded(
            child: Container(
              color: theme.scaffoldBackgroundColor,
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildMainDashboard(context),
                  const ArchivosPage(),
                  const AjustesScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarLogo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppStyles.accentColor(context).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: const CircleAvatar(
        radius: 35,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage('assets/img/appstore.png'),
      ),
    );
  }

  Widget _buildMainDashboard(BuildContext context) {
    String nombreAMostrar = "Usuario";
    String inicial = "?";
    Color colorAvatar = Colors.grey;

    if (_mensajeDebug.isNotEmpty) {
      nombreAMostrar = _mensajeDebug;
    } else if (_nombreUsuario != null && _nombreUsuario!.isNotEmpty) {
      nombreAMostrar = _nombreUsuario!;
      inicial = nombreAMostrar[0].toUpperCase();
      colorAvatar = AppStyles.accentColor(context);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Panel Administrativo",
                style: AppStyles.mainTitle(context).copyWith(fontSize: 32),
              ),
              // ---> BOTÓN DESPLEGABLE <---
              TextButton(
                key: _menuButtonKey,
                style: TextButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF1C2128)
                      : Colors.grey[100],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                onPressed: _mostrarMenuDesplegable,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorAvatar,
                      child: Text(
                        inicial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _cargandoUsuario
                        ? const SizedBox(
                            width: 80,
                            height: 16,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                            ),
                          )
                        : Row(
                            children: [
                              Text(
                                nombreAMostrar,
                                style: AppStyles.tableCell(context).copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _mensajeDebug.isNotEmpty
                                      ? Colors.redAccent
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyLarge?.color,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.expand_more,
                                size: 20,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              // <--- FIN BOTÓN <---
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 25,
              mainAxisSpacing: 25,
              children: [
                _AnimatedDashboardCard(
                  titulo: "Base de Datos",
                  subtitulo: "Gestión de Unidad",
                  icono: Icons.storage,
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GestionDBNavigator(),
                    ),
                  ),
                ),
                _AnimatedDashboardCard(
                  titulo: "Registro de Minuta",
                  subtitulo: "Pelotón",
                  icono: Icons.book,
                  color: Colors.redAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistroDiarioScreen(),
                    ),
                  ),
                ),
                _AnimatedDashboardCard(
                  titulo: "Registro Diario",
                  subtitulo: "Operacional",
                  icono: Icons.badge,
                  color: Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OperacionesEspecialesScreen(),
                    ),
                  ),
                ),
                _AnimatedDashboardCard(
                  titulo: "Copia de Seguridad",
                  subtitulo: "Modelo",
                  icono: Icons.backup,
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfiguracionScreen(),

                      // DesarrolladorScreen(),
                    ),
                  ),
                ),
                _AnimatedDashboardCard(
                  titulo: "Seguridad",
                  subtitulo: "Políticas",
                  icono: Icons.security,
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    //SeguridadScreen
                    MaterialPageRoute(
                      builder: (context) => DesarrolladorScreen(),
                    ),
                  ),
                ),
                _AnimatedDashboardCard(
                  titulo: "Mapa Tactico",
                  subtitulo: "Módulo Planeamiento",
                  icono: Icons.map,
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapaDibujoPage()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDashboardCard extends StatefulWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color color;
  final VoidCallback? onTap;

  const _AnimatedDashboardCard({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.color,
    this.onTap,
  });

  @override
  State<_AnimatedDashboardCard> createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<_AnimatedDashboardCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..scale(_isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0)),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2128) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? widget.color.withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 20 : 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icono, size: 40, color: widget.color),
              ),
              const SizedBox(height: 15),
              Text(
                widget.titulo,
                textAlign: TextAlign.center,
                style: AppStyles.tableCell(context).copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.subtitulo,
                textAlign: TextAlign.center,
                style: AppStyles.tableCell(
                  context,
                ).copyWith(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
