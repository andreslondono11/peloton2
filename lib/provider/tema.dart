import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = "theme_mode";
  static const String _pinKey = "admin_pin";
  static const String _huellaKey = "huella_habilitada";

  ThemeMode _themeMode = ThemeMode.system;
  String _adminPin = "0000";
  bool _huellaHabilitada = false;

  ThemeMode get themeMode => _themeMode;
  String get adminPin => _adminPin;
  bool get huellaHabilitada => _huellaHabilitada;

  ThemeProvider() {
    cargarPreferencias();
  }

  // --- CARGA DE PREFERENCIAS ---
  Future<void> cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Cargar Tema
    int? themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    // 2. Cargar PIN
    _adminPin = prefs.getString(_pinKey) ?? "0000";

    // 3. Cargar Preferencia de Huella
    _huellaHabilitada = prefs.getBool(_huellaKey) ?? false;

    notifyListeners();
  }

  // --- LÓGICA DEL TEMA ---
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  // --- LÓGICA DEL PIN ---
  Future<void> setAdminPin(String newPin) async {
    if (newPin.length == 4) {
      _adminPin = newPin;
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pinKey, newPin);
    }
  }

  // --- LÓGICA DE LA HUELLA ---
  Future<void> setHuella(bool valor) async {
    _huellaHabilitada = valor;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_huellaKey, valor);
  }

  // --- CONFIGURACIÓN DE TEMA CLARO ---
  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1A237E),
        brightness: Brightness.light,
        error: Colors.red[700],
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF1A237E)),
        headingTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(color: Colors.black87),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF1A237E), size: 24),
    );
  }

  // --- CONFIGURACIÓN DE TEMA OSCURO ---
  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.cyanAccent,
        brightness: Brightness.dark,
        surface: const Color(0xFF161B22),
        error: const Color(0xFFCF6679),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161B22),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF30363D), width: 1),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF161B22)),
        headingTextStyle: const TextStyle(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(color: Colors.white70),
      ),
      iconTheme: const IconThemeData(color: Colors.cyanAccent, size: 24),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF30363D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
        ),
      ),
    );
  }
}
