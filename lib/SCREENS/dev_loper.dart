import 'package:flutter/material.dart';
import 'package:peloton/provider/apptex.dart';
import 'package:peloton/BD/db_manager.dart';
import 'package:provider/provider.dart';
import 'package:peloton/provider/tema.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DesarrolladorScreen extends StatefulWidget {
  const DesarrolladorScreen({super.key});

  @override
  State<DesarrolladorScreen> createState() => _DesarrolladorScreenState();
}

class _DesarrolladorScreenState extends State<DesarrolladorScreen> {
  String? _nombreUsuario;
  String? _correoUsuario;
  bool _cargando = true;
  bool _showUserMenu = false;

  // Variable para calcular el ancho del botón y alinear el menú
  final GlobalKey _userButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
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
            _correoUsuario = usuario.first['correo'] as String?;
            _cargando = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint("Error cargando usuario en desarrollador: $e");
    }
    if (mounted) setState(() => _cargando = false);
  }

  // ========================================================================
  // ACCIONES
  // ========================================================================
  void _mostrarPoliticasSeguridad() {
    final isDark = AppStyles.isDark(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.shield, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text("Políticas de Seguridad", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "1. PROTECCIÓN DE DATOS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Toda la información ingresaada en CALIPSO está encriptada localmente y no se transmite a servidores externos no autorizados.",
              ),
              SizedBox(height: 15),
              Text(
                "2. CONTROL DE ACCESO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "El acceso al sistema es restringido y personalizado. Cada sesión queda registrada con el ID del usuario responsable.",
              ),
              SizedBox(height: 15),
              Text(
                "3. RESPALDOS Y EVIDENCIAS",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Las evidencias físicas y digitales gestionadas son de exclusiva responsabilidad del usuario logueado. Se recomienda realizar respaldos periódicos.",
              ),
              SizedBox(height: 15),
              Text(
                "4. DESCONEXIÓN SEGURA",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Al cerrar sesión, se purga la memoria caché de la aplicación para evitar accesos no autorizados en caso de extravío del dispositivo.",
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "HE LEÍDO Y ACEPTO LAS POLÍTICAS",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.isDark(context)
            ? const Color(0xFF161B22)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("¿Cerrar sesión?"),
        content: const Text(
          "Se purgará la sesión actual y se reiniciará la aplicación.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "SALIR",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_logged_user_id');
      await prefs.setBool('mantener_sesion_activa', false);

      final db = await DBManager.instance.authDatabase;
      await db.delete('sesion_activa');
      await DBManager.instance.fullReset();

      if (mounted) {
        Restart.restartApp(webOrigin: "");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_showUserMenu) setState(() => _showUserMenu = false);
      },
      child: Scaffold(
        backgroundColor: AppStyles.isDark(context)
            ? const Color(0xFF0D1117)
            : Colors.grey[100],
        appBar: AppBar(
          foregroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            "DOCUMENTACIÓN TÉCNICA - CALIPSO",
            style: AppStyles.mainTitle(
              context,
            ).copyWith(color: Colors.white, fontSize: 16, letterSpacing: 1.5),
          ),
          backgroundColor: const Color(0xFF161B22),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(
                Icons.integration_instructions_outlined,
                color: Colors.blueAccent,
              ),
              onPressed: () {},
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Container(width: 1, color: Colors.white24),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                key: _userButtonKey, // Key para obtener el tamaño exacto
                onTap: () => setState(() => _showUserMenu = !_showUserMenu),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize
                        .min, // Importante para calcular el ancho real
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: Text(
                          _nombreUsuario != null && _nombreUsuario!.isNotEmpty
                              ? _nombreUsuario![0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _nombreUsuario ?? "Usuario",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _correoUsuario ?? "correo@ejemplo.com",
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _showUserMenu
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white54,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerProyecto(context),
                  const SizedBox(height: 35),

                  // ========================================================================
                  // NUEVA CARD DE POLÍTICAS EN EL CONTENIDO
                  // ========================================================================
                  _politicasCard(context),
                  const SizedBox(height: 35),

                  _tarjetaTecnologias(context),
                  const SizedBox(height: 35),
                  Text(
                    "Ecosistema de Desarrollo",
                    style: AppStyles.mainTitle(context).copyWith(
                      color: AppStyles.isDark(context)
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _gridDetallesTecnicos(context),
                  const SizedBox(height: 40),
                  _footerVersion(),
                ],
              ),
            ),

            // ========================================================================
            // MENÚ DESPLEGABLE ALINEADO PERFECTAMENTE
            // ========================================================================
            if (_showUserMenu) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => setState(() => _showUserMenu = false),
                  child: Container(
                    color: Colors.transparent,
                  ), // Fondo invisible para cerrar
                ),
              ),
              // Alineación exacta
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 60,
                    right: 12,
                  ), // 60px = altura AppBar, 12 = padding del botón
                  child: Container(
                    width:
                        _getUserButtonWidth() ??
                        250, // Usa el ancho calculado del botón
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppStyles.isDark(context)
                          ? const Color(0xFF1C2128)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppStyles.isDark(context)
                            ? Colors.white10
                            : Colors.black12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // _itemMenuSwitch(
                        //   icon: AppStyles.isDark(context) ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        //   titulo: AppStyles.isDark(context) ? "Modo Claro" : "Modo Oscuro",
                        //   valor: AppStyles.isDark(context),
                        //   onChanged: (bool value) {
                        //     final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
                        //     themeProvider.toggleTheme();
                        //   },
                        // ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Divider(height: 1, color: Colors.white24),
                        ),
                        _itemMenu(
                          icon: Icons.logout,
                          titulo: "Cerrar Sesión",
                          color: Colors.redAccent,
                          onTap: () {
                            setState(() => _showUserMenu = false);
                            _cerrarSesion();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // FUNCIÓN PARA CALCULAR EL ANCHO EXACTO DEL BOTÓN Y ALINEAR EL MENÚ
  // ========================================================================
  double? _getUserButtonWidth() {
    final renderBox =
        _userButtonKey.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size.width;
  }

  // ========================================================================
  // CARD DE POLÍTICAS DE SEGURIDAD
  // ========================================================================
  Widget _politicasCard(BuildContext context) {
    final isDark = AppStyles.isDark(context);
    return InkWell(
      onTap: _mostrarPoliticasSeguridad,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(isDark ? 0.05 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.shield_outlined,
              color: Colors.redAccent,
              size: 30,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "POLÍTICAS DE SEGURIDAD INSTITUCIONAL",
                    style: AppStyles.tableCell(context).copyWith(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Protección de datos, control de accesos, normativas de respaldo y protocolos de desconexión segura.",
                    style: TextStyle(
                      color: isDark ? Colors.blueGrey : Colors.black,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.redAccent.withOpacity(0.5),
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // WIDGETS DEL MENÚ DESPLEGABLE
  // ========================================================================
  Widget _itemMenu({
    required IconData icon,
    required String titulo,
    Color? color,
    required VoidCallback onTap,
  }) {
    final isDark = AppStyles.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? (isDark ? Colors.white70 : Colors.black54),
              size: 20,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: color ?? (isDark ? Colors.white : Colors.black87),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white24 : Colors.black26,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemMenuSwitch({
    required IconData icon,
    required String titulo,
    required bool valor,
    required Function(bool) onChanged,
  }) {
    final isDark = AppStyles.isDark(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: isDark ? Colors.white70 : Colors.black54, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Switch(
            value: valor,
            activeColor: Colors.blueAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // WIDGETS ORIGINALES
  // ========================================================================
  Widget _headerProyecto(BuildContext context) {
    final isDark = AppStyles.isDark(context);
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Colors.blueAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                "OBJETIVO DEL SISTEMA",
                style: AppStyles.tableCell(context).copyWith(
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            "Digitalizar y centralizar la gestión de personal, control de armamento y protocolos de inteligencia. El sistema garantiza la trazabilidad total de la información institucional mediante reportes dinámicos en PDF y Excel.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaTecnologias(BuildContext context) {
    final isDark = AppStyles.isDark(context);
    final techs = [
      {'label': 'PHP 8.x', 'desc': 'Backend & API REST', 'icon': Icons.dns},
      {
        'label': 'MySQL',
        'desc': 'Persistencia de Datos',
        'icon': Icons.storage,
      },
      {
        'label': 'Flutter 3.x',
        'desc': 'Core Multiplataforma',
        'icon': Icons.flutter_dash,
      },
      {
        'label': 'Dompdf',
        'desc': 'Motor de Reportes PDF',
        'icon': Icons.picture_as_pdf,
      },
      {
        'label': 'Excel API',
        'desc': 'Gestión de Libros/Hojas',
        'icon': Icons.table_chart,
      },
      {
        'label': 'Provider',
        'desc': 'Gestión de Estado',
        'icon': Icons.alt_route,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Stack Tecnológico",
          style: AppStyles.mainTitle(context).copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: techs
              .map(
                (t) => _chipTech(
                  context,
                  t['label'] as String,
                  t['desc'] as String,
                  t['icon'] as IconData,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _chipTech(
    BuildContext context,
    String label,
    String desc,
    IconData icon,
  ) {
    final isDark = AppStyles.isDark(context);
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0 : 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridDetallesTecnicos(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 3.5,
          children: [
            _infoCard(
              "Metodología",
              "Desarrollo Ágil con entregas incrementales.",
              Icons.terminal,
            ),
            _infoCard(
              "Escalabilidad",
              "Arquitectura modular para nuevos componentes.",
              Icons.trending_up,
            ),
            _infoCard(
              "Despliegue",
              "Configuración local o infraestructura cloud.",
              Icons.rocket_launch,
            ),
            _infoCard(
              "Seguridad",
              "Encriptación y niveles de acceso jerarquizados.",
              Icons.admin_panel_settings,
            ),
          ],
        );
      },
    );
  }

  Widget _infoCard(String titulo, String desc, IconData icono) {
    final isDark = AppStyles.isDark(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0 : 0.03),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icono, color: Colors.orangeAccent, size: 35),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 13,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerVersion() {
    final isDark = AppStyles.isDark(context);
    return Center(
      child: Text(
        "CALIPSO System v3.0.0-build.2026\nDesigned for Secure Institutional Environments",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 11,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
