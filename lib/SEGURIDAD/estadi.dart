import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsProvider extends ChangeNotifier {
  int _totalImagenes = 0;
  int _totalAudios = 0;
  int _totalDocumentos = 0;
  int _totalRegistrosBD = 0;

  // Getters
  int get totalImagenes => _totalImagenes;
  int get totalAudios => _totalAudios;
  int get totalDocumentos => _totalDocumentos;
  int get totalRegistrosBD => _totalRegistrosBD;
  int get totalArchivosGenerales =>
      _totalImagenes + _totalAudios + _totalDocumentos;

  // ========================================================================
  // NUEVO: Cargar estadísticas guardadas al iniciar la app
  // ========================================================================
  Future<void> cargarEstadisticas() async {
    final prefs = await SharedPreferences.getInstance();
    _totalImagenes = prefs.getInt('stats_imagenes') ?? 0;
    _totalAudios = prefs.getInt('stats_audios') ?? 0;
    _totalDocumentos = prefs.getInt('stats_documentos') ?? 0;
    _totalRegistrosBD = prefs.getInt('stats_registrosBD') ?? 0;
    notifyListeners();
  }

  // Función para sumar archivos según su tipo y guardar en memoria
  void registrarArchivo(String ruta) {
    final extension = ruta.split('.').last.toLowerCase();

    if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(extension)) {
      _totalImagenes++;
      _guardarEnDisco('stats_imagenes', _totalImagenes);
    } else if (['mp3', 'wav', 'm4a', 'aac', 'ogg', 'amr'].contains(extension)) {
      _totalAudios++;
      _guardarEnDisco('stats_audios', _totalAudios);
    } else if ([
      'pdf',
      'xls',
      'xlsx',
      'doc',
      'docx',
      'csv',
    ].contains(extension)) {
      _totalDocumentos++;
      _guardarEnDisco('stats_documentos', _totalDocumentos);
    }

    notifyListeners();
  }

  // Función para establecer los registros totales de la BD
  void setRegistrosBD(int total) {
    _totalRegistrosBD = total;
    _guardarEnDisco('stats_registrosBD', _totalRegistrosBD);
    notifyListeners();
  }

  // Función para resetear
  void resetear() {
    _totalImagenes = 0;
    _totalAudios = 0;
    _totalDocumentos = 0;
    _totalRegistrosBD = 0;

    // Borrar del disco también
    _guardarEnDisco('stats_imagenes', 0);
    _guardarEnDisco('stats_audios', 0);
    _guardarEnDisco('stats_documentos', 0);
    _guardarEnDisco('stats_registrosBD', 0);

    notifyListeners();
  }

  // ========================================================================
  // AUXILIAR: Guarda el número en segundo plano sin frenar la UI
  // ========================================================================
  void _guardarEnDisco(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }
}
