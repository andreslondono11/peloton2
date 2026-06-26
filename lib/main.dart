// import 'package:flutter/material.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'dart:io';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:peloton/provider/tema.dart';
// import 'package:peloton/intro.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // <-- 1. IMPORTAR
// import 'package:peloton/BD/db_manager.dart'; // <-- 2. IMPORTAR

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// void main() async {
//   // 1. Obligatorio para procesos async antes de runApp
//   WidgetsFlutterBinding.ensureInitialized();

//   // --- CARGA INICIAL DE PREFERENCIAS (PIN Y TEMA) ---
//   final themeProvider = ThemeProvider();
//   await themeProvider.cargarPreferencias();

//   // 2. INICIALIZACIÓN DE LA BASE DE DATOS
//   if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
//     sqfliteFfiInit();
//     databaseFactory = databaseFactoryFfi;
//   } else {
//     try {
//       await getDatabasesPath();
//     } catch (e) {
//       sqfliteFfiInit();
//       databaseFactory = databaseFactoryFfi;
//     }
//   }

//   // --- 3. NUEVO: RECUPERAR EL ÚLTIMO USUARIO QUE INICIÓ SESIÓN ---
//   final prefs = await SharedPreferences.getInstance();
//   final int? ultimoUserId = prefs.getInt('last_logged_user_id');

//   if (ultimoUserId != null) {
//     // Si alguien ya había entrado antes, pre-cargamos su base de datos en silencio
//     // para que no se quede en blanco cuando la app se abre
//     await DBManager.instance.initUserSession(ultimoUserId);
//   }
//   // ----------------------------------------------------------------------

//   // 4. Forzar modo Horizontal (Landscape)
//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.landscapeLeft,
//     DeviceOrientation.landscapeRight,
//   ]);

//   // 5. Lanzar la App
//   runApp(
//     ChangeNotifierProvider.value(value: themeProvider, child: const MyApp()),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Consumer<ThemeProvider>(
//       builder: (context, themeProvider, child) {
//         return MaterialApp(
//           navigatorKey: navigatorKey,
//           debugShowCheckedModeBanner: false,
//           title: 'CALIPSO - Gestión Institucional',
//           theme: themeProvider.lightTheme,
//           darkTheme: themeProvider.darkTheme,
//           themeMode: themeProvider.themeMode,
//           home: const CALIPSOSplashScreen(),
//         );
//       },
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:peloton/SEGURIDAD/estadi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:peloton/provider/tema.dart';
// import 'package:peloton/provider/stats_provider.dart'; // <-- NUEVO IMPORT
import 'package:peloton/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peloton/BD/db_manager.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  // 1. Obligatorio para procesos async antes de runApp
  WidgetsFlutterBinding.ensureInitialized();

  // --- CARGA INICIAL DE PREFERENCIAS (PIN Y TEMA) ---
  final themeProvider = ThemeProvider();
  await themeProvider.cargarPreferencias();

  // --- NUEVO: INICIALIZAR STATS PROVIDER Y CARGAR DATOS GUARDADOS ---
  final statsProvider = StatsProvider();
  await statsProvider
      .cargarEstadisticas(); // Carga lo que había antes de cerrar la app

  // 2. INICIALIZACIÓN DE LA BASE DE DATOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  } else {
    try {
      await getDatabasesPath();
    } catch (e) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // --- RECUPERAR EL ÚLTIMO USUARIO QUE INICIÓ SESIÓN ---
  final prefs = await SharedPreferences.getInstance();
  final int? ultimoUserId = prefs.getInt('last_logged_user_id');

  if (ultimoUserId != null) {
    await DBManager.instance.initUserSession(ultimoUserId);
  }

  // 4. Forzar modo Horizontal (Landscape)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 5. Lanzar la App usando MultiProvider
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(
          value: statsProvider,
        ), // <-- INYECTADO AQUÍ
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'CALIPSO - Gestión Institucional',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const CALIPSOSplashScreen(),
        );
      },
    );
  }
}
