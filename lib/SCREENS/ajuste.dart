import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:peloton/provider/apptex.dart';
import 'package:peloton/provider/tema.dart';
import 'package:local_auth/local_auth.dart';
import 'package:peloton/BD/db_manager.dart';

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String? _nombreUsuario;
  String? _correoUsuario; // ---> NUEVA VARIABLE PARA EL CORREO
  bool _cargando = true;

  // ---> NUEVA CLAVE GLOBAL PARA EL MENÚ DESPLEGABLE
  final GlobalKey _menuButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
  }

  // Método robusto corregido (Actualizado para cargar también el correo)
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
            // ---> ASUMIENDO QUE TU COLUMNA EN LA BD SE LLAMA 'correo' O 'email'
            // Cambia 'correo' por el nombre exacto de tu columna en la base de datos
            _correoUsuario = usuario.first['correo'] as String?;
            _cargando = false;
          });
          return;
        }
      }
    } catch (e) {
      print("Error cargando usuario en ajustes: $e");
    }

    if (mounted) setState(() => _cargando = false);
  }

  Future<bool> _validarHardware(BuildContext context) async {
    final LocalAuthentication auth = LocalAuthentication();
    try {
      bool canCheck =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canCheck) {
        AppStyles.showSnackBar(
          context,
          "Hardware biométrico no detectado",
          isError: true,
        );
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---> NUEVO MÉTODO PARA CERRAR SESIÓN
  void _cerrarSesion() {
    // Aquí va tu lógica para cerrar sesión (ej. borrar la tabla sesion_activa y navegar al Login)
    print("Cerrando sesión...");
    // Ejemplo: Navigator.pushReplacementNamed(context, '/login');
  }

  // ---> MÉTODO DEL MENÚ DESPLEGABLE INTEGRADO
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF0D1117)
            : const Color(0xFF1A237E),
        centerTitle: true,
        title: _cargando
            ? const SizedBox(
                width: 150,
                height: 16,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: Colors.white54,
                ),
              )
            : Text(
                "CONFIGURACIÓN SISTEMA",
                style: AppStyles.mainTitle(
                  context,
                ).copyWith(fontSize: 18, color: Colors.white, letterSpacing: 2),
              ),
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
                // ---> BOTÓN DEL MENÚ DESPLEGABLE CON LA CLAVE GLOBAL
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
                      ), // Indicador visual de que hay un menú
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN: APARIENCIA ---
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: AppStyles.accentColor(context),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text("Apariencia", style: AppStyles.mainTitle(context)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Personalice el modo visual para optimizar su flujo de trabajo en CALIPSO.",
              style: AppStyles.tableCell(
                context,
              ).copyWith(color: isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(height: 25),

            Container(
              decoration: AppStyles.tableDecoration(context).copyWith(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildThemeOption(
                    context,
                    title: "Modo Claro",
                    subtitle: "Interfaz brillante y nítida",
                    icon: Icons.light_mode_rounded,
                    mode: ThemeMode.light,
                    currentMode: themeProvider.themeMode,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                  ),
                  _buildThemeOption(
                    context,
                    title: "Modo Oscuro",
                    subtitle: "Ideal para turnos nocturnos o baja luz",
                    icon: Icons.dark_mode_rounded,
                    mode: ThemeMode.dark,
                    currentMode: themeProvider.themeMode,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                  ),
                  _buildThemeOption(
                    context,
                    title: "Seguir Sistema",
                    subtitle: "Sincronizar con los ajustes de la tablet",
                    icon: Icons.brightness_auto_rounded,
                    mode: ThemeMode.system,
                    currentMode: themeProvider.themeMode,
                    onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- SECCIÓN: SEGURIDAD Y ACCESO ---
            Row(
              children: [
                Icon(
                  Icons.security_outlined,
                  color: AppStyles.accentColor(context),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text("Seguridad y Acceso", style: AppStyles.mainTitle(context)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Configure los métodos de autenticación biométrica para su cuenta institucional.",
              style: AppStyles.tableCell(
                context,
              ).copyWith(color: isDark ? Colors.white54 : Colors.black54),
            ),
            const SizedBox(height: 25),

            Container(
              decoration: AppStyles.tableDecoration(context),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile(
                secondary: Icon(
                  Icons.fingerprint_rounded,
                  color: themeProvider.huellaHabilitada
                      ? Colors.green
                      : Colors.grey,
                  size: 28,
                ),
                title: Text(
                  "Activar Ingreso con Huella",
                  style: AppStyles.tableCell(
                    context,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  "Permitir el acceso rápido en la pantalla de inicio",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
                value: themeProvider.huellaHabilitada,
                activeColor: AppStyles.accentColor(context),
                onChanged: (bool value) async {
                  if (value) {
                    bool ok = await _validarHardware(context);
                    if (ok) themeProvider.setHuella(true);
                  } else {
                    themeProvider.setHuella(false);
                  }
                },
              ),
            ),
            const SizedBox(height: 40),

            // --- SECCIÓN: INFORMACIÓN Y LEGAL ---
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppStyles.accentColor(context),
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text("Información", style: AppStyles.mainTitle(context)),
              ],
            ),
            const SizedBox(height: 25),

            Container(
              decoration: AppStyles.tableDecoration(context),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.verified_user_outlined,
                      color: Colors.blue,
                    ),
                    title: Text(
                      "Acerca de CALIPSO",
                      style: AppStyles.tableCell(context),
                    ),
                    subtitle: Text(
                      "Versión 3.02.33+3 - Gestión Táctica",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        useRootNavigator: false,
                        applicationName: "CALIPSO",
                        applicationVersion: "3.02.33+3",
                        applicationIcon: Image.asset(
                          'assets/img/appstore.png',
                          width: 50,
                          height: 50,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Editor Táctico y Georreferenciado",
                                  style: AppStyles.mainTitle(
                                    context,
                                  ).copyWith(fontSize: 18),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  "Aplicación avanzada para la planificación operativa y gestión táctica sobre mapas digitales e imágenes estáticas.",
                                  style: AppStyles.tableCell(
                                    context,
                                  ).copyWith(height: 1.4),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  "Funcionalidades Principales:",
                                  style: AppStyles.tableCell(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppStyles.accentColor(context),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _buildBulletPoint(
                                  "Integración GPS y Mapas Híbridos en tiempo real.",
                                ),
                                _buildBulletPoint(
                                  "Dibujo vectorial de figuras tácticas (flechas, zonas, polígonos).",
                                ),
                                _buildBulletPoint(
                                  "Sistema de anotaciones de texto y trazado libre.",
                                ),
                                _buildBulletPoint(
                                  "Manipulación de capas, matrices de imagen y zoom.",
                                ),
                                _buildBulletPoint(
                                  "Persistencia de sesiones locales y exportación de reportes.",
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  "Arquitectura y Herramientas Internas:",
                                  style: AppStyles.tableCell(context).copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppStyles.accentColor(context),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _buildBulletPoint(
                                  "Renderizado de alto rendimiento con CustomPainter.",
                                ),
                                _buildBulletPoint(
                                  "Gestión de gestos matriciales (Matrix4).",
                                ),
                                _buildBulletPoint(
                                  "Base de datos SQLite local para sincronización de usuarios.",
                                ),
                                _buildBulletPoint(
                                  "Manejo nativo de permisos de ubicación y biometría.",
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    indent: 60,
                    color: isDark ? Colors.white10 : Colors.grey[200],
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                      color: Colors.orange,
                    ),
                    title: Text(
                      "Licencias de Software",
                      style: AppStyles.tableCell(context),
                    ),
                    subtitle: Text(
                      "Bibliotecas de código abierto utilizadas",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: "CALIPSO",
                      applicationVersion: "3.02.33+3",
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            _buildInfoCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: AppStyles.tableCell(context).copyWith(height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required VoidCallback onTap,
  }) {
    final bool isSelected = mode == currentMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeColor = AppStyles.accentColor(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? activeColor : Colors.grey,
          size: 26,
        ),
      ),
      title: Text(
        title,
        style: AppStyles.tableCell(context).copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 16,
          color: isSelected ? activeColor : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppStyles.tableCell(context).copyWith(
          fontSize: 12,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle_rounded, color: activeColor)
          : Icon(
              Icons.radio_button_off_rounded,
              color: Colors.grey.withOpacity(0.5),
            ),
      onTap: onTap,
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.blueGrey.withOpacity(0.1)
            : Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              "Los cambios se guardan localmente y se aplican a todas las pantallas del sistema.",
              style: AppStyles.tableCell(
                context,
              ).copyWith(fontSize: 12, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
