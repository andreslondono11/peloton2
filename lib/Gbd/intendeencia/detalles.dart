import 'dart:io';
import 'package:flutter/material.dart';

class DetalleRegistroScreen extends StatelessWidget {
  final dynamic registro; // Recibe el objeto de tipo Intendencia

  const DetalleRegistroScreen({super.key, required this.registro});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color colorMilitar = const Color(0xFF1A237E);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: const Text("DETALLES DE REGISTRO"),
        backgroundColor: colorMilitar,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- CABECERA CON FOTO ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorMilitar,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 30, top: 10),
              child: Column(
                children: [
                  Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          registro.fotoPath != null &&
                              registro.fotoPath!.isNotEmpty
                          ? Image.file(
                              File(registro.fotoPath!),
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.person, size: 100, color: colorMilitar),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "${registro.grado} ${registro.apellidosNombres}"
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    "N° REGISTRO: ${registro.no}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- SECCIÓN OBSERVACIONES ---
                  _buildSectionCard(
                    isDark,
                    "OBSERVACIONES",
                    Icons.comment,
                    Text(
                      registro.observaciones != null &&
                              registro.observaciones!.isNotEmpty
                          ? registro.observaciones!
                          : "Sin observaciones registradas.",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- TABLA DE EQUIPO ---
                  _buildSectionCard(
                    isDark,
                    "INVENTARIO DE EQUIPO",
                    Icons.inventory_2,
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      children: [
                        _buildTableHeader(),
                        ...registro.equipo.entries.map((entry) {
                          return _buildTableRow(entry.key, entry.value);
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para crear los contenedores de secciones
  Widget _buildSectionCard(
    bool isDark,
    String title,
    IconData icon,
    Widget content,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1A237E), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          content,
        ],
      ),
    );
  }

  // Encabezado de la tabla
  TableRow _buildTableHeader() {
    return const TableRow(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "IMPLEMENTO",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "ESTADO",
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // Fila de la tabla (Formatea los nombres de las keys de la BD)
  TableRow _buildTableRow(String key, dynamic value) {
    // Limpia el nombre: 'camisetas_verdes' -> 'CAMISETAS VERDES'
    String label = key.replaceAll('_', ' ').toUpperCase();

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            value.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
