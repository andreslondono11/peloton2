// import 'package:flutter/material.dart';
// import 'dart:async';

// // IMPORTACIONES CRÍTICAS
// import 'package:peloton/BD/db_manager.dart';
// import 'package:peloton/SCREENS/dashboard.dart';
// import 'package:peloton/SCREENS/login_screen.dart';
// import 'package:peloton/provider/apptex.dart'; // Importamos tus estilos robustos

// class CALIPSOSplashScreen extends StatefulWidget {
//   const CALIPSOSplashScreen({super.key});

//   @override
//   State<CALIPSOSplashScreen> createState() => _CALIPSOSplashScreenState();
// }

// class _CALIPSOSplashScreenState extends State<CALIPSOSplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     );

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

//     _controller.forward();
//     _validarSesionYNav();
//   }

//   Future<void> _validarSesionYNav() async {
//     try {
//       final db = await DBManager.instance.database;

//       // Validación de persistencia de sesión
//       final List<Map<String, dynamic>> sesion = await db.query(
//         'sesion_activa',
//         where: 'mantener_sesion = ?',
//         whereArgs: [1],
//       );

//       bool debeAutoLoguear = sesion.isNotEmpty;

//       // Tiempo de exposición del branding
//       await Future.delayed(const Duration(seconds: 3));

//       if (!mounted) return;

//       Navigator.of(context).pushReplacement(
//         PageRouteBuilder(
//           pageBuilder: (context, animation, secondaryAnimation) =>
//               debeAutoLoguear ? const DashboardScreen() : const LoginScreen(),
//           transitionsBuilder: (context, animation, secondaryAnimation, child) {
//             return FadeTransition(opacity: animation, child: child);
//           },
//           transitionDuration: const Duration(milliseconds: 800),
//         ),
//       );
//     } catch (e) {
//       debugPrint("Error en el arranque de CALIPSO: $e");
//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (context) => const LoginScreen()),
//         );
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Usamos los colores del tema para que el Splash no "brille" si estamos en modo oscuro
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final accentColor = AppStyles.accentColor(context);

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       body: FadeTransition(
//         opacity: _fadeAnimation,
//         child: Container(
//           width: double.infinity,
//           height: double.infinity,
//           decoration: BoxDecoration(
//             gradient: RadialGradient(
//               colors: isDark
//                   ? [
//                       const Color.fromARGB(255, 60, 63, 44),
//                       const Color.fromARGB(255, 5, 6, 7),
//                     ]
//                   : [
//                       const Color.fromARGB(255, 60, 63, 44),
//                       const Color.fromARGB(255, 5, 6, 7),
//                     ],
//               radius: 1.0,
//               center: Alignment.center,
//             ),
//           ),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Hero(
//                 tag: 'logo_calipso',
//                 child: Image.asset(
//                   'assets/img/appstore.png',
//                   width: 280,
//                   height: 280,

//                   fit: BoxFit.fill,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 "CALIPSO",
//                 style: AppStyles.mainTitle(context).copyWith(
//                   fontSize: 48,
//                   color: Colors
//                       .white, // El nombre de la app siempre en blanco sobre el degradado
//                   letterSpacing: 8.0,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 "SISTEMA INTEGRAL DE GESTIÓN PREMIUM Vers. 3.0",
//                 style: TextStyle(
//                   color: accentColor.withOpacity(0.7),
//                   fontSize: 12,
//                   fontWeight: FontWeight.w300,
//                   letterSpacing: 3.0,
//                 ),
//               ),
//               const SizedBox(height: 80),
//               SizedBox(
//                 width: 250,
//                 child: Column(
//                   children: [
//                     LinearProgressIndicator(
//                       backgroundColor: Colors.white10,
//                       color: accentColor,
//                       minHeight: 2,
//                     ),
//                     const SizedBox(height: 15),
//                     Text(
//                       "VERIFICANDO CREDENCIALES...",
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.4),
//                         fontSize: 9,
//                         letterSpacing: 2,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'dart:async';

// IMPORTACIONES CRÍTICAS
import 'package:peloton/BD/db_manager.dart';
import 'package:peloton/SCREENS/dashboard.dart';
import 'package:peloton/SCREENS/login_screen.dart';
import 'package:peloton/provider/apptex.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- NUEVA IMPORTACIÓN

class CALIPSOSplashScreen extends StatefulWidget {
  const CALIPSOSplashScreen({super.key});

  @override
  State<CALIPSOSplashScreen> createState() => _CALIPSOSplashScreenState();
}

class _CALIPSOSplashScreenState extends State<CALIPSOSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
    _validarSesionYNav(); // Llamada sin await para que la animación corra libre
  }

  Future<void> _validarSesionYNav() async {
    try {
      // ====================================================================
      // NUEVA LÓGICA: Leer desde SharedPreferences (No se pisa entre usuarios)
      // ====================================================================
      final prefs = await SharedPreferences.getInstance();
      final int? ultimoUserId = prefs.getInt('last_logged_user_id');
      final bool mantenerSesion =
          prefs.getBool('mantener_sesion_activa') ?? true;

      bool debeAutoLoguear = (ultimoUserId != null && mantenerSesion);

      // Si hay sesión guardada, asegurarnos de que la BD de ese usuario esté abierta
      // (El main.dart ya lo debería haber hecho, pero esto es un refuerzo de seguridad)
      if (debeAutoLoguear) {
        await DBManager.instance.initUserSession(ultimoUserId!);
      }

      // Tiempo de exposición del branding
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              debeAutoLoguear ? const DashboardScreen() : const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      debugPrint("Error en el arranque de CALIPSO: $e");
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usamos los colores del tema para que el Splash no "brille" si estamos en modo oscuro
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppStyles.accentColor(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: isDark
                  ? [
                      const Color.fromARGB(255, 60, 63, 44),
                      const Color.fromARGB(255, 5, 6, 7),
                    ]
                  : [
                      const Color.fromARGB(255, 60, 63, 44),
                      const Color.fromARGB(255, 5, 6, 7),
                    ],
              radius: 1.0,
              center: Alignment.center,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'logo_calipso',
                child: Image.asset(
                  'assets/img/appstore.png',
                  width: 280,
                  height: 280,
                  fit: BoxFit.fill,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "CALIPSO",
                style: AppStyles.mainTitle(context).copyWith(
                  fontSize: 48,
                  color: Colors.white,
                  letterSpacing: 8.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "SISTEMA INTEGRAL DE GESTIÓN PREMIUM Vers. 3.0",
                style: TextStyle(
                  color: accentColor.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: 80),
              SizedBox(
                width: 250,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      color: accentColor,
                      minHeight: 2,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "VERIFICANDO CREDENCIALES...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
