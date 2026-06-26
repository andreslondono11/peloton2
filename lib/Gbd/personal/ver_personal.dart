import 'dart:io';
import 'package:flutter/material.dart';
import 'package:peloton/Gbd/personal/personal_reg.dart';

class DetallePersonalScreen extends StatelessWidget {
  final Personal personal;

  const DetallePersonalScreen({super.key, required this.personal});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    const Color azulInstitucional = Color(0xFF1A237E);
    final Color accentColor = isDark
        ? const Color(0xFF64B5F6)
        : azulInstitucional;
    final Color cardColor = isDark
        ? const Color(0xFF1E1E26)
        : const Color(0xFFF1F4F9);
    final Color dividerColor = isDark ? Colors.white10 : Colors.black12;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F13) : Colors.white,
      appBar: AppBar(
        title: const Text(
          "HOJA DE VIDA INSTITUCIONAL",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: isDark ? Colors.black : azulInstitucional,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(accentColor, isDark),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSectionCard(
                    title: "PERFIL Y SITUACIÓN",
                    icon: Icons.account_circle_outlined,
                    accent: accentColor,
                    cardBg: cardColor,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _dataRow(
                          "Grado Actual",
                          personal.grado,
                          isDark,
                          isBold: true,
                        ),
                        _dataRow("Cargo / Función", personal.cargo, isDark),
                        _dataRow(
                          "Estado Laboral",
                          personal.estado,
                          isDark,
                          customColor: personal.estado.contains("Retirado")
                              ? Colors.red
                              : Colors.green,
                        ),
                        _dataRow(
                          "Fecha de Ingreso",
                          personal.fechaIngreso,
                          isDark,
                        ),
                        _dataRow("Sexo", personal.sexo, isDark),
                      ],
                    ),
                  ),

                  _buildSectionCard(
                    title: "IDENTIFICACIÓN Y BIOMETRÍA",
                    icon: Icons.badge_outlined,
                    accent: accentColor,
                    cardBg: cardColor,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _dataRow(
                          "Documento",
                          "${personal.tipoDocumento} ${personal.numeroDocumento}",
                          isDark,
                        ),
                        _dataRow(
                          "Fecha Nacimiento",
                          personal.fechaNacimiento,
                          isDark,
                        ),
                        _dataRow(
                          "Ciudad Nacimiento",
                          personal.ciudadNacimiento,
                          isDark,
                        ),
                        _dataRow(
                          "País Nacimiento",
                          personal.paisNacimiento,
                          isDark,
                        ),
                        _dataRow(
                          "Grupo Sanguíneo",
                          personal.rh,
                          isDark,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  _buildSectionCard(
                    title: "INFORMACIÓN DE CONTACTO",
                    icon: Icons.contact_mail_outlined,
                    accent: accentColor,
                    cardBg: cardColor,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _dataRow("Teléfono", personal.telefono, isDark),
                        _dataRow("Correo", personal.correo, isDark),
                        _dataRow(
                          "Dirección Residencia",
                          personal.direccion,
                          isDark,
                        ),
                      ],
                    ),
                  ),

                  _buildSectionCard(
                    title: "REFERENCIAS FAMILIARES",
                    icon: Icons.family_restroom_outlined,
                    accent: accentColor,
                    cardBg: cardColor,
                    isDark: isDark,
                    child: Column(
                      children: [
                        _dataRow(
                          "Nombre del Padre",
                          personal.nombrePadre,
                          isDark,
                        ),
                        _dataRow(
                          "Teléfono Padre",
                          personal.telefonoPadre ?? "No Registra",
                          isDark,
                        ),
                        _dataRow(
                          "Nombre de la Madre",
                          personal.nombreMadre,
                          isDark,
                        ),
                        _dataRow(
                          "Teléfono Madre",
                          personal.telefonoMadre ?? "No Registra",
                          isDark,
                        ),
                        _dataRow(
                          "Nombre del Hijo(a)",
                          personal.nombreHijo ?? "No Registra",
                          isDark,
                        ),
                      ],
                    ),
                  ),

                  _buildSectionCard(
                    title: "CONTACTO DE EMERGENCIA",
                    icon: Icons.warning_amber_rounded,
                    accent: Colors.redAccent,
                    cardBg: isDark
                        ? const Color(0xFF2D1A1A)
                        : const Color(0xFFFFF5F5),
                    isDark: isDark,
                    child: Column(
                      children: [
                        _dataRow(
                          "Responsable",
                          personal.contactoEmergencia,
                          isDark,
                          isBold: true,
                        ),
                        _dataRow(
                          "Teléfono Urgencias",
                          personal.telefonoEmergencia,
                          isDark,
                          isBold: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(30),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : accent.withOpacity(0.05),
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(60)),
      ),
      child: Row(
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: accent, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8),
              ],
              image:
                  (personal.fotoPath != null &&
                      File(personal.fotoPath!).existsSync())
                  ? DecorationImage(
                      image: FileImage(File(personal.fotoPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: personal.fotoPath == null
                ? Icon(Icons.person, size: 50, color: accent.withOpacity(0.5))
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  personal.nombre.toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                Text(
                  personal.apellido.toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Chip(
                  label: Text(
                    personal.grado,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: accent,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color accent,
    required Color cardBg,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: accent,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Divider(height: 25, thickness: 0.5),
          child,
        ],
      ),
    );
  }

  Widget _dataRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? customColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white38 : Colors.black54,
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? "No Registra" : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: customColor ?? (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
