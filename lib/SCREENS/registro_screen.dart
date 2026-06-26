import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:peloton/BD/db_manager.dart';
import 'package:peloton/SCREENS/login_screen.dart';
import 'package:peloton/provider/apptex.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _nomController = TextEditingController();
  final _corController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  bool _isEmailValid(String email) {
    return RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(email);
  }

  Future<bool> _correoExiste(String correo) async {
    try {
      final db = await DBManager.instance.authDatabase;
      final resultado = await db.query(
        'usuarios',
        columns: ['id'],
        where: 'correo = ?',
        whereArgs: [correo.toLowerCase()],
        limit: 1,
      );
      return resultado.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _registrarUsuario() async {
    // 1. CERRAR EL TECLADO INMEDIATAMENTE AL PRESIONAR EL BOTÓN
    FocusScope.of(context).unfocus();

    final nombre = _nomController.text.trim();
    final correo = _corController.text.trim().toLowerCase();
    final pass = _passController.text.trim();

    if (nombre.isEmpty || correo.isEmpty || pass.isEmpty) {
      AppStyles.showSnackBar(
        context,
        "Todos los campos son obligatorios",
        isError: true,
      );
      return;
    }

    if (!_isEmailValid(correo)) {
      AppStyles.showSnackBar(
        context,
        "Ingresa un correo válido",
        isError: true,
      );
      return;
    }

    if (pass.length < 6) {
      AppStyles.showSnackBar(
        context,
        "La contraseña debe tener al menos 6 caracteres",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final existe = await _correoExiste(correo);
      if (existe) {
        if (!mounted) return;
        AppStyles.showSnackBar(
          context,
          "Este correo ya está registrado.",
          isError: true,
        );
        setState(() => _isLoading = false);
        return;
      }

      final db = await DBManager.instance.authDatabase;
      await db.insert('usuarios', {
        'nombres': nombre,
        'correo': correo,
        'password': pass,
        'rol': 'usuario',
        'estado': 'activo',
        'fecha_creacion': DateTime.now().toIso8601String(),
        'ultimo_acceso': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarDialogoExito(nombre);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppStyles.showSnackBar(
        context,
        "Error al registrar: ${e.toString()}",
        isError: true,
      );
    }
  }

  void _mostrarDialogoExito(String nombre) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        icon: Icon(
          Icons.check_circle,
          color: AppStyles.accentColor(context),
          size: 60,
        ),
        title: Text(
          "¡Registro Exitoso!",
          style: AppStyles.mainTitle(context).copyWith(fontSize: 22),
        ),
        content: Text(
          "Usuario $nombre creado correctamente.",
          textAlign: TextAlign.center,
          style: AppStyles.tableCell(context),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: AppStyles.primaryButton(context),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text("IR AL LOGIN"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _corController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SOLUCIÓN CLAVE: Usar LayoutBuilder para evitar el bucle de layout
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si el ancho es menor a 800, usamos diseño vertical (seguro para móviles)
        // Esto evita que el Row explote cuando el teclado ocupa la mitad de la pantalla
        if (constraints.maxWidth < 800) {
          return _buildMobileLayout();
        } else {
          return _buildDesktopLayout();
        }
      },
    );
  }

  // LAYOUT SEGURO PARA MÓVIL (Nunca se congela)
  Widget _buildMobileLayout() {
    return Scaffold(
      resizeToAvoidBottomInset: true, // En móvil sí dejamos que se ajuste
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D1117),
          image: DecorationImage(
            image: AssetImage('assets/img/ejc.png'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildLogo(80),
                  const SizedBox(height: 20),
                  const Text(
                    "CALIPSO",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: _buildFormulario(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // LAYOUT PARA ESCRITORIO/TABLET (Protegido contra bucles)
  Widget _buildDesktopLayout() {
    return Scaffold(
      resizeToAvoidBottomInset:
          false, // PROHIBIDO que el teclado redimensione aquí
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0D1117),
                image: DecorationImage(
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
                    _buildLogo(180),
                    const SizedBox(height: 30),
                    const Text(
                      "CALIPSO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 35,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
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
                      style: TextStyle(color: Colors.white54, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(60.0),
                child: _buildFormulario(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FORMULARIO REUTILIZABLE (Separado para no repetir código)
  Widget _buildFormulario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Crear Cuenta", style: AppStyles.mainTitle(context)),
        const SizedBox(height: 8),
        Text(
          "Complete los datos para el nuevo usuario",
          style: AppStyles.tableCell(context).copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _nomController,
          style: AppStyles.tableCell(context),
          textCapitalization: TextCapitalization.words,
          decoration: AppStyles.inputDecoration(
            context,
            label: "Nombres Completos",
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _corController,
          style: AppStyles.tableCell(context),
          keyboardType: TextInputType.emailAddress,
          decoration: AppStyles.inputDecoration(
            context,
            label: "Correo Electrónico",
            icon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passController,
          style: AppStyles.tableCell(context),
          obscureText: true,
          decoration: AppStyles.inputDecoration(
            context,
            label: "Contraseña (mín. 6 caracteres)",
            icon: Icons.lock_outline,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: AppStyles.primaryButton(context),
            onPressed: _isLoading ? null : _registrarUsuario,
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "REGISTRAR USUARIO",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "¿Ya tiene una cuenta? Regrese al Login",
              style: AppStyles.tableCell(context).copyWith(
                color: AppStyles.accentColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // LOGO AJUSTABLE
  Widget _buildLogo(double size) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppStyles.accentColor(context).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/img/appstore.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, e, s) => Icon(
            Icons.security,
            size: size * 0.5,
            color: AppStyles.accentColor(context),
          ),
        ),
      ),
    );
  }
}
