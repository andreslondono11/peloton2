import 'package:flutter/material.dart';

class AppStyles {
  // --- 1. CONFIGURACIÓN DE COLORES DINÁMICOS ---

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primaryColor(BuildContext context) => const Color(0xFF1A237E);

  static Color accentColor(BuildContext context) {
    return isDark(context) ? Colors.blueGrey : const Color(0xFF1A237E);
  }

  // --- 2. ESTILOS DE TEXTO (Títulos, Celdas, Subtítulos) ---

  static TextStyle mainTitle(BuildContext context) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: isDark(context) ? Colors.white : primaryColor(context),
    );
  }

  static TextStyle tableCell(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      color: isDark(context) ? Colors.white70 : Colors.black87,
    );
  }

  // --- 3. TABLAS (DataTable y Encabezados) ---

  static DataTableThemeData tableTheme(BuildContext context) {
    return DataTableThemeData(
      headingRowColor: WidgetStateProperty.all(
        isDark(context) ? const Color(0xFF161B22) : primaryColor(context),
      ),
      headingTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      dataTextStyle: tableCell(context),
      horizontalMargin: 12,
      columnSpacing: 20,
    );
  }

  // Decoración para el contenedor que envuelve la tabla
  static BoxDecoration tableDecoration(BuildContext context) {
    return BoxDecoration(
      color: isDark(context) ? const Color(0xFF0D1117) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark(context)
            ? const Color(0xFF30363D)
            : Colors.grey.withOpacity(0.2),
      ),
    );
  }

  // --- 4. CARDS (Tarjetas de Información) ---

  static CardTheme cardTheme(BuildContext context) {
    return CardTheme(
      color: isDark(context) ? const Color(0xFF161B22) : Colors.white,
      elevation: isDark(context) ? 0 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark(context) ? const Color(0xFF30363D) : Colors.transparent,
        ),
      ),
    );
  }

  // --- 5. ICONOS ---

  static IconThemeData iconTheme(BuildContext context) {
    return IconThemeData(color: accentColor(context), size: 24);
  }

  // --- 6. INPUTS (Campos de Texto) ---

  static InputDecoration inputDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
  }) {
    final color = accentColor(context);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark(context) ? Colors.white60 : Colors.black54,
      ),
      prefixIcon: Icon(icon, color: color),
      filled: true,
      fillColor: isDark(context) ? const Color(0xFF0D1117) : Colors.grey[50],
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark(context) ? const Color(0xFF30363D) : Colors.grey[300]!,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 2),
      ),
    );
  }

  // --- 7. BOTONES ---

  static ButtonStyle primaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: accentColor(context),
      foregroundColor: isDark(context) ? Colors.black : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  // --- 8. ESTADOS (Snackbars de Error/Éxito) ---

  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Colors.green[800],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
