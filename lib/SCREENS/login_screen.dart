import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:sqflite/sqflite.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- NUEVA IMPORTACIÓN

import 'package:peloton/BD/adminpnael.dart';
import 'package:peloton/provider/tema.dart';
import 'package:peloton/provider/apptex.dart';
import '../BD/db_manager.dart';
import 'dashboard.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cor = TextEditingController();
  final _pas = TextEditingController();
  bool _mantenerSesion = false;
  bool _activarHuella = false;
  bool _mostrarBotonHuella = false;
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _verificarEstadoSesion();
  }

  @override
  void dispose() {
    _cor.dispose();
    _pas.dispose();
    super.dispose();
  }

  // Future<void> _verificarEstadoSesion() async {
  //   final db = await DBManager.instance.authDatabase;
  //   final prefs = await SharedPreferences.getInstance(); // <-- NUEVO

  //   final sesion = await db.query('sesion_activa', limit: 1);

  //   if (sesion.isEmpty) {
  //     // ---> CORRECCIÓN CRÍTICA: Si la tabla se borró, preguntamos a SharedPreferences
  //     final int? ultimoUserId = prefs.getInt('last_logged_user_id');
  //     if (ultimoUserId != null) {
  //       final bool mantener = prefs.getBool('mantener_sesion_activa') ?? false;
  //       if (mantener) {
  //         if (!mounted) return;
  //         await DBManager.instance.initUserSession(ultimoUserId);
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(builder: (context) => const DashboardScreen()),
  //         );
  //         return;
  //       }
  //     }
  //     return; // Si no hay nada en ningún lado, se queda en el Login
  //   }

  //   final bool mantener = sesion.first['mantener_sesion'] == 1;
  //   final bool usarHuella = sesion.first['usar_huella'] == 1;
  //   final int usuarioId = sesion.first['usuario_id'] as int;

  //   final usuario = await db.query(
  //     'usuarios',
  //     where: 'id = ? AND estado = "activo"',
  //     whereArgs: [usuarioId],
  //   );

  //   if (usuario.isEmpty) {
  //     await db.delete('sesion_activa');
  //     return;
  //   }

  //   if (!mounted) return;

  //   final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

  //   setState(() {
  //     _mostrarBotonHuella = usarHuella && themeProvider.huellaHabilitada;
  //     _activarHuella = usarHuella;
  //   });

  //   if (usarHuella && !themeProvider.huellaHabilitada) {
  //     await db.update('sesion_activa', {'usar_huella': 0}, where: 'id = 1');
  //   }

  //   if (mantener && !usarHuella) {
  //     if (!mounted) return;
  //     await DBManager.instance.initUserSession(usuarioId);
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(builder: (context) => const DashboardScreen()),
  //     );
  //   }
  // }

  Future<void> _verificarEstadoSesion() async {
    final db = await DBManager.instance.authDatabase;
    final prefs = await SharedPreferences.getInstance();

    final sesion = await db.query('sesion_activa', limit: 1);

    if (sesion.isEmpty) {
      // ---> Si la tabla se borró (Ejército), preguntamos a SharedPreferences
      final int? ultimoUserId = prefs.getInt('last_logged_user_id');
      if (ultimoUserId != null) {
        final bool mantener = prefs.getBool('mantener_sesion_activa') ?? false;
        if (mantener) {
          if (!mounted) return;
          await DBManager.instance.initUserSession(ultimoUserId);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
          return;
        }
      }
      return; // Si no hay nada, se queda en el Login
    }

    final int mantener =
        sesion.first['mantener_sesion'] as int; // CAMBIO AQUÍ: Es INT, no bool
    final int usarHuella =
        sesion.first['usar_huella'] as int; // CAMBIO AQUÍ: Es INT, no bool
    final int usuarioId = sesion.first['usuario_id'] as int;

    final usuario = await db.query(
      'usuarios',
      where: 'id = ? AND estado = "activo"',
      whereArgs: [usuarioId],
    );

    if (usuario.isEmpty) {
      await db.delete('sesion_activa');
      return;
    }

    if (!mounted) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    setState(() {
      // CAMBIO AQUÍ: Comparamos con 1 en vez de true/false
      _mostrarBotonHuella = (usarHuella == 1) && themeProvider.huellaHabilitada;
      _activarHuella = (usarHuella == 1);
    });

    // Si el usuario desactivó la huella desde la configuración global, la quitamos de la BD
    if (usarHuella == 1 && !themeProvider.huellaHabilitada) {
      await db.update('sesion_activa', {'usar_huella': 0}, where: 'id = 1');
    }

    // CAMBIO AQUÍ: Comparamos mantener con 1
    if (mantener == 1 && usarHuella != 1) {
      if (!mounted) return;
      await DBManager.instance.initUserSession(usuarioId);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  Future<void> _ingresoBiometrico() async {
    try {
      final bool canCheck = await auth.canCheckBiometrics;
      final bool isSupported = await auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        if (!mounted) return;
        AppStyles.showSnackBar(
          context,
          "Dispositivo no soporta biometría.",
          isError: true,
        );
        return;
      }
      await _verificarHuellaEnSegundoPlano();
    } catch (e) {
      if (!mounted) return;
      AppStyles.showSnackBar(
        context,
        "Error al verificar hardware: $e",
        isError: true,
      );
    }
  }

  Future<void> _verificarHuellaEnSegundoPlano() async {
    AuthenticationOptions(stickyAuth: true, biometricOnly: true);
    try {
      final bool exito = await auth.authenticate(
        localizedReason: 'Verifique su identidad para acceder a CALIPSO',
      );
      if (!mounted) return;
      if (exito) await _procesarIngresoExitoso();
    } catch (e) {
      if (!mounted) return;
      AppStyles.showSnackBar(
        context,
        "Error de autenticación: $e",
        isError: true,
      );
    }
  }

  Future<void> _procesarIngresoExitoso() async {
    final db = await DBManager.instance.authDatabase;
    final sesion = await db.query('sesion_activa', limit: 1);

    if (sesion.isEmpty || sesion.first['usar_huella'] != 1) {
      if (!mounted) return;
      AppStyles.showSnackBar(
        context,
        "Primero inicie sesión y active la huella.",
        isError: true,
      );
      return;
    }

    final int usuarioId = sesion.first['usuario_id'] as int;

    final usuario = await db.query(
      'usuarios',
      where: 'id = ? AND estado = "activo"',
      whereArgs: [usuarioId],
    );

    if (usuario.isEmpty) {
      await db.delete('sesion_activa');
      if (!mounted) return;
      AppStyles.showSnackBar(
        context,
        "Usuario desactivado por el administrador.",
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    await DBManager.instance.initUserSession(usuarioId);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }

  void _accesoAdmin() {
    final adminPassController = TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          "Acceso Administrativo",
          style: AppStyles.mainTitle(context).copyWith(fontSize: 20),
        ),
        content: TextField(
          controller: adminPassController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
          style: AppStyles.tableCell(context),
          decoration: AppStyles.inputDecoration(
            context,
            label: "Clave de administrador",
            icon: Icons.lock_person,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCELAR"),
          ),
          ElevatedButton(
            style: AppStyles.primaryButton(context),
            onPressed: () {
              if (adminPassController.text == themeProvider.adminPin) {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminPanel()),
                );
              } else {
                AppStyles.showSnackBar(
                  context,
                  "Clave incorrecta",
                  isError: true,
                );
              }
            },
            child: const Text("INGRESAR"),
          ),
        ],
      ),
    );
  }

  Future<void> _entrar() async {
    if (_cor.text.isEmpty || _pas.text.isEmpty) {
      AppStyles.showSnackBar(context, "Complete los campos", isError: true);
      return;
    }

    final db = await DBManager.instance.authDatabase;
    final prefs = await SharedPreferences.getInstance(); // <-- NUEVO

    final res = await db.query(
      'usuarios',
      where: 'correo = ? AND password = ? AND estado = "activo"',
      whereArgs: [_cor.text.trim(), _pas.text.trim()],
    );

    if (res.isNotEmpty) {
      int usuarioId = res.first['id'] as int;

      // ---> CORRECCIÓN CRÍTICA: Guardar en SharedPreferences como RESPALDO INDEPENDIENTE
      await prefs.setInt('last_logged_user_id', usuarioId);
      await prefs.setBool('mantener_sesion_activa', _mantenerSesion);

      // Tu lógica original para la tabla (para la huella digital)
      await db.insert('sesion_activa', {
        'id': 1,
        'usuario_id': usuarioId,
        'mantener_sesion': _mantenerSesion ? 1 : 0,
        'usar_huella': _activarHuella ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      if (!mounted) return;

      await DBManager.instance.initUserSession(usuarioId);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      if (!mounted) return;
      AppStyles.showSnackBar(
        context,
        "Credenciales incorrectas o usuario desactivado",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool huellaGlobalActiva = context
        .watch<ThemeProvider>()
        .huellaHabilitada;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 800) {
            return _buildMobileLayout(isDark, huellaGlobalActiva);
          }
          return _buildDesktopLayout(isDark, huellaGlobalActiva);
        },
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDark, bool huellaGlobalActiva) {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A237E) : Colors.black87,
                  image: const DecorationImage(
                    image: AssetImage('assets/img/ejc.png'),
                    fit: BoxFit.cover,
                    opacity: 0.15,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 30),
                      const Text(
                        "CALIPSO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 8,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        height: 2,
                        width: 100,
                        color: AppStyles.accentColor(context),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "GESTIÓN DE REGISTRO",
                        style: TextStyle(
                          color: Colors.white54,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60.0,
                  vertical: 40.0,
                ),
                child: _buildLoginForm(isDark, huellaGlobalActiva),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 25,
          right: 25,
          child: FloatingActionButton.small(
            backgroundColor: isDark ? Colors.white10 : Colors.black12,
            elevation: 0,
            onPressed: _accesoAdmin,
            child: Icon(
              Icons.admin_panel_settings,
              color: isDark ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, bool huellaGlobalActiva) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildLogo(120),
              const SizedBox(height: 20),
              const Text(
                "CALIPSO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 2,
                width: 60,
                color: AppStyles.accentColor(context),
              ),
              const SizedBox(height: 40),
              _buildLoginForm(isDark, huellaGlobalActiva),
            ],
          ),
        ),
        Positioned(
          bottom: 25,
          right: 25,
          child: FloatingActionButton.small(
            backgroundColor: isDark ? Colors.white10 : Colors.black12,
            elevation: 0,
            onPressed: _accesoAdmin,
            child: Icon(
              Icons.admin_panel_settings,
              color: isDark ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isDark, bool huellaGlobalActiva) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Iniciar Sesión", style: AppStyles.mainTitle(context)),
        const SizedBox(height: 40),
        TextField(
          controller: _cor,
          decoration: AppStyles.inputDecoration(
            context,
            label: "Correo",
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _pas,
          obscureText: true,
          decoration: AppStyles.inputDecoration(
            context,
            label: "Contraseña",
            icon: Icons.lock_outline,
          ),
        ),
        const SizedBox(height: 10),
        Theme(
          data: Theme.of(context).copyWith(
            unselectedWidgetColor: isDark ? Colors.white60 : Colors.black54,
          ),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "Mantener sesión iniciada",
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            value: _mantenerSesion,
            activeColor: const Color(0xFF1A237E),
            onChanged: (bool? value) =>
                setState(() => _mantenerSesion = value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            "Ingreso con huella digital",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: const Text(
            "Requiere iniciar sesión al menos una vez",
            style: TextStyle(fontSize: 10, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
          value: _activarHuella,
          activeColor: const Color(0xFF1A237E),
          onChanged: (bool value) => setState(() => _activarHuella = value),
          secondary: Icon(
            Icons.fingerprint,
            color: _activarHuella ? const Color(0xFF1A237E) : Colors.grey,
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: AppStyles.primaryButton(context),
            onPressed: _entrar,
            child: const Text(
              "INGRESAR",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_mostrarBotonHuella && huellaGlobalActiva)
          Center(
            child: Column(
              children: [
                const Text(
                  "O ingrese rápidamente:",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                IconButton(
                  icon: Icon(
                    Icons.fingerprint,
                    size: 55,
                    color: AppStyles.accentColor(context),
                  ),
                  onPressed: _ingresoBiometrico,
                ),
              ],
            ),
          ),
        const SizedBox(height: 30),
        _buildRegisterLink(),
      ],
    );
  }

  Widget _buildLogo([double size = 180]) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
    ),
    child: ClipOval(
      child: Image.asset(
        'assets/img/appstore.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, e, s) =>
            Icon(Icons.security, size: size * 0.6, color: Colors.white),
      ),
    ),
  );

  Widget _buildRegisterLink() => Center(
    child: TextButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RegistroScreen()),
      ),
      child: const Text(
        "¿No tiene usuario? Regístrese aquí",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
  );
}
