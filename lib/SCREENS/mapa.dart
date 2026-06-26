import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scribble/scribble.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

// ==========================================
// MODELOS DE DATOS
// ==========================================

class TextNote {
  Offset position;
  String text;
  Color color;
  double fontSize;
  TextNote({
    required this.position,
    required this.text,
    required this.color,
    this.fontSize = 16.0,
  });
}

class DibujoFigura {
  String tipo;
  Offset inicio;
  Offset fin;
  Color color;
  double grosor;
  double escala;
  bool relleno;

  DibujoFigura({
    required this.tipo,
    required this.inicio,
    required this.fin,
    required this.color,
    required this.grosor,
    required this.escala,
    this.relleno = false,
  });
}

// ==========================================
// WIDGETS AUXILIARES Y PAINTERS
// ==========================================

/// Pintor de Figuras
class FigurasPainter extends CustomPainter {
  final List<DibujoFigura> figuras;
  final Offset? inicioActual;
  final Offset? finActual;
  final Color colorActual;
  final double grosorActual;
  final String tipoActual;
  final double escalaActual;

  const FigurasPainter({
    required this.figuras,
    this.inicioActual,
    this.finActual,
    required this.colorActual,
    required this.grosorActual,
    required this.tipoActual,
    required this.escalaActual,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var fig in figuras) {
      _dibujarForma(
        canvas,
        fig.tipo,
        fig.inicio,
        fig.fin,
        fig.color,
        fig.grosor,
        fig.escala,
        fig.relleno,
      );
    }

    if (inicioActual != null && finActual != null) {
      _dibujarForma(
        canvas,
        tipoActual,
        inicioActual!,
        finActual!,
        colorActual,
        grosorActual,
        escalaActual,
        false,
      );
    }
  }

  void _dibujarForma(
    Canvas canvas,
    String tipo,
    Offset ini,
    Offset fin,
    Color color,
    double grosor,
    double escala,
    bool relleno,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = grosor
      ..style = relleno ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Offset finEscalado = Offset(
      ini.dx + (fin.dx - ini.dx) * escala,
      ini.dy + (fin.dy - ini.dy) * escala,
    );
    Rect rect = Rect.fromPoints(ini, finEscalado);
    double w = rect.width;
    double h = rect.height;

    switch (tipo) {
      // ==========================================
      // 1. FIGURAS GEOMÉTRICAS
      // ==========================================
      case 'linea':
        canvas.drawLine(ini, finEscalado, paint);
        break;
      case 'cuadrado':
      case 'rectangulo':
        canvas.drawRect(rect, paint);
        break;
      case 'circulo':
        canvas.drawCircle(ini, w / 2, paint);
        break;
      case 'ovalo':
        canvas.drawOval(rect, paint);
        break;
      case 'triangulo':
        canvas.drawPath(
          Path()
            ..moveTo(ini.dx, ini.dy)
            ..lineTo(finEscalado.dx, finEscalado.dy)
            ..lineTo(ini.dx, finEscalado.dy)
            ..close(),
          paint,
        );
        break;
      case 'rombo':
        canvas.drawPath(
          Path()
            ..moveTo(rect.center.dx, rect.top)
            ..lineTo(rect.right, rect.center.dy)
            ..lineTo(rect.center.dx, rect.bottom)
            ..lineTo(rect.left, rect.center.dy)
            ..close(),
          paint,
        );
        break;
      case 'hexagono':
        _dibujarPoligono(canvas, rect.center, w / 2, 6, paint);
        break;
      case 'pentagono':
        _dibujarPoligono(canvas, rect.center, w / 2, 5, paint);
        break;
      case 'estrella5':
        _dibujarEstrella(canvas, rect.center, w / 2, 5, paint);
        break;
      case 'estrella4':
        _dibujarEstrella(canvas, rect.center, w / 2, 4, paint);
        break;
      case 'cruz':
        canvas.drawLine(
          Offset(rect.center.dx, rect.top),
          Offset(rect.center.dx, rect.bottom),
          paint,
        );
        canvas.drawLine(
          Offset(rect.left, rect.center.dy),
          Offset(rect.right, rect.center.dy),
          paint,
        );
        break;
      case 'equis':
        canvas.drawLine(rect.topLeft, rect.bottomRight, paint);
        canvas.drawLine(rect.topRight, rect.bottomLeft, paint);
        break;
      case 'marco':
        canvas.drawRect(rect.deflate(w * 0.2), paint);
        break;
      case 'lente':
        canvas.drawOval(rect, paint);
        canvas.drawLine(
          Offset(rect.right, rect.top),
          Offset(rect.left, rect.bottom),
          paint,
        );
        break;

      // ==========================================
      // 2. FLECHAS (Incluyendo Diagonales)
      // ==========================================
      case 'flecha_derecha':
      case 'flecha_izquierda':
      case 'flecha_arriba':
      case 'flecha_abajo':
        _dibujarFlecha(canvas, rect, tipo, paint);
        break;
      case 'flecha_diagonal_arriba_derecha': // NUEVO
        _dibujarFlechaDiagonal(canvas, rect, 1, -1, paint); // x+, y-
        break;
      case 'flecha_diagonal_arriba_izquierda': // NUEVO
        _dibujarFlechaDiagonal(canvas, rect, -1, -1, paint); // x-, y-
        break;
      case 'flecha_diagonal_abajo_derecha': // NUEVO
        _dibujarFlechaDiagonal(canvas, rect, 1, 1, paint); // x+, y+
        break;
      case 'flecha_diagonal_abajo_izquierda': // NUEVO
        _dibujarFlechaDiagonal(canvas, rect, -1, 1, paint); // x-, y+
        break;

      // ==========================================
      // 3. SÍMBOLOS MILITARES
      // ==========================================
      case 'escudo':
      case 'escudo_militar':
        // Forma clásica de escudo
        canvas.drawPath(
          Path()
            ..moveTo(rect.center.dx, rect.top)
            ..quadraticBezierTo(
              rect.right,
              rect.top,
              rect.right,
              rect.top + h * 0.4,
            )
            ..lineTo(rect.right, rect.bottom)
            ..quadraticBezierTo(
              rect.center.dx,
              rect.bottom - h * 0.2,
              rect.left,
              rect.bottom,
            )
            ..lineTo(rect.left, rect.top + h * 0.4)
            ..quadraticBezierTo(rect.left, rect.top, rect.center.dx, rect.top)
            ..close(),
          paint,
        );
        break;
      case 'medalla_estrella':
        // Círculo exterior
        canvas.drawCircle(rect.center, w / 2, paint);
        // Estrella de 5 puntas en el centro
        _dibujarEstrella(canvas, rect.center, w * 0.35, 5, paint);
        break;
      case 'explosion':
        // Radial simple
        for (int i = 0; i < 8; i++) {
          double angle = (math.pi * 2 / 8) * i;
          double x1 = rect.center.dx + math.cos(angle) * (w * 0.15);
          double y1 = rect.center.dy + math.sin(angle) * (h * 0.15);
          double x2 = rect.center.dx + math.cos(angle) * (w * 0.45);
          double y2 = rect.center.dy + math.sin(angle) * (h * 0.45);
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
        }
        canvas.drawCircle(rect.center, w * 0.1, paint);
        break;
      case 'bayoneta':
        // Filo
        canvas.drawLine(
          Offset(rect.center.dx, rect.bottom),
          Offset(rect.center.dx, rect.top),
          paint,
        );
        // Punta
        Path punta = Path()
          ..moveTo(rect.center.dx - w * 0.1, rect.top + h * 0.15)
          ..lineTo(rect.center.dx, rect.top)
          ..lineTo(rect.center.dx + w * 0.1, rect.top + h * 0.15)
          ..close();
        canvas.drawPath(punta, paint);
        // Guarda
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(rect.center.dx, rect.bottom),
            width: w * 0.3,
            height: h * 0.05,
          ),
          paint,
        );
        break;
      case 'insignia':
        // Estrella simple sobre base
        _dibujarEstrella(
          canvas,
          Offset(rect.center.dx, rect.center.dy - h * 0.1),
          w * 0.3,
          5,
          paint,
        );
        canvas.drawLine(
          Offset(rect.center.dx, rect.center.dy),
          Offset(rect.center.dx, rect.bottom),
          paint,
        );
        break;

      // ==========================================
      // 4. SITIOS DE REFERENCIA (MAPA)
      // ==========================================
      case 'ubicacion':
        // Pin de ubicación clásico
        canvas.drawPath(
          Path()
            ..moveTo(rect.topCenter.dx, rect.topCenter.dy)
            ..quadraticBezierTo(
              rect.right,
              rect.top + h * 0.7,
              rect.bottomCenter.dx,
              rect.bottomCenter.dy,
            )
            ..quadraticBezierTo(
              rect.left,
              rect.top + h * 0.7,
              rect.topCenter.dx,
              rect.topCenter.dy,
            )
            ..close(),
          paint,
        );
        break;
      case 'montana':
        // Tres picos
        canvas.drawPath(
          Path()
            ..moveTo(ini.dx, finEscalado.dy)
            ..lineTo(ini.dx + w * 0.25, rect.top + h * 0.2)
            ..lineTo(ini.dx + w * 0.5, finEscalado.dy)
            ..lineTo(ini.dx + w * 0.75, rect.top) // Pico central más alto
            ..lineTo(finEscalado.dx, finEscalado.dy)
            ..lineTo(ini.dx, finEscalado.dy)
            ..close(),
          paint,
        );
        break;
      case 'olas':
        // Tres olas estilizadas
        double cy = rect.center.dy;
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(ini.dx + w * 0.25, cy),
            radius: w * 0.2,
          ),
          -math.pi,
          math.pi,
          false,
          paint,
        );
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(rect.center.dx, cy - h * 0.1),
            radius: w * 0.25,
          ),
          -math.pi,
          math.pi,
          false,
          paint,
        );
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(finEscalado.dx - w * 0.25, cy),
            radius: w * 0.2,
          ),
          -math.pi,
          math.pi,
          false,
          paint,
        );
        break;
      case 'bosque':
        // Grupo de árboles
        for (int i = 0; i < 3; i++) {
          double tx = ini.dx + (w * 0.2) + (i * w * 0.3);
          Path arbol = Path()
            ..moveTo(tx - w * 0.12, finEscalado.dy)
            ..lineTo(tx + w * 0.12, finEscalado.dy)
            ..lineTo(tx, rect.top + h * 0.2)
            ..close();
          canvas.drawPath(arbol, paint);
          // Tronco
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(tx, finEscalado.dy - h * 0.05),
              width: w * 0.04,
              height: h * 0.15,
            ),
            paint,
          );
        }
        break;
      case 'fortaleza':
      case 'location_city':
        // Dos torres y muralla central
        canvas.drawRect(
          Rect.fromLTWH(ini.dx, rect.top, w * 0.3, h),
          paint,
        ); // Torre I
        canvas.drawRect(
          Rect.fromLTWH(finEscalado.dx - w * 0.3, rect.top, w * 0.3, h),
          paint,
        ); // Torre D
        canvas.drawRect(
          Rect.fromLTWH(ini.dx + w * 0.3, rect.top + h * 0.4, w * 0.4, h * 0.6),
          paint,
        ); // Centro
        // Almenas (dientes)
        for (int i = 0; i < 3; i++) {
          double x = ini.dx + w * 0.35 + (i * w * 0.12);
          canvas.drawRect(
            Rect.fromLTWH(x, rect.top + h * 0.4, w * 0.08, h * 0.1),
            paint,
          );
        }
        break;
      case 'bandera':
        // Asta
        canvas.drawLine(
          Offset(ini.dx, ini.dy),
          Offset(ini.dx, finEscalado.dy),
          paint,
        );
        // Tela ondeando
        Path tela = Path()
          ..moveTo(ini.dx, ini.dy)
          ..quadraticBezierTo(
            rect.center.dx,
            rect.top + h * 0.3,
            finEscalado.dx,
            (ini.dy + finEscalado.dy) / 2,
          )
          ..quadraticBezierTo(
            rect.center.dx,
            rect.bottom - h * 0.3,
            ini.dx,
            finEscalado.dy,
          )
          ..close();
        canvas.drawPath(tela, paint);
        break;
      case 'avion':
        // Silueta de avión
        Path avion = Path()
          ..moveTo(ini.dx + w * 0.4, finEscalado.dy) // Cola
          ..lineTo(rect.center.dx, rect.top) // Punta
          ..lineTo(finEscalado.dx - w * 0.4, finEscalado.dy) // Cola
          ..lineTo(rect.right, rect.center.dy) // Ala der
          ..lineTo(rect.center.dx, rect.top + h * 0.3)
          ..lineTo(rect.left, rect.center.dy) // Ala izq
          ..close();
        canvas.drawPath(avion, paint);
        break;
      case 'barco':
        // Casco curvo
        Path casco = Path()
          ..moveTo(ini.dx + w * 0.1, rect.top + h * 0.5)
          ..quadraticBezierTo(
            rect.center.dx,
            finEscalado.dy + h * 0.1,
            finEscalado.dx - w * 0.1,
            rect.top + h * 0.5,
          )
          ..lineTo(finEscalado.dx - w * 0.1, finEscalado.dy)
          ..lineTo(ini.dx + w * 0.1, finEscalado.dy)
          ..close();
        canvas.drawPath(casco, paint);
        // Mástil y vela
        canvas.drawLine(
          Offset(rect.center.dx, finEscalado.dy),
          Offset(rect.center.dx, rect.top + h * 0.2),
          paint,
        );
        Path vela = Path()
          ..moveTo(rect.center.dx, finEscalado.dy)
          ..lineTo(rect.center.dx + w * 0.2, rect.top + h * 0.3)
          ..lineTo(rect.center.dx, rect.top + h * 0.2)
          ..close();
        canvas.drawPath(vela, paint);
        break;
      case 'colina':
        // Colina suave
        canvas.drawPath(
          Path()
            ..moveTo(ini.dx, finEscalado.dy)
            ..quadraticBezierTo(
              rect.center.dx,
              rect.top,
              finEscalado.dx,
              finEscalado.dy,
            )
            ..close(),
          paint,
        );
        break;
      case 'globo':
        // Esfera con meridianos
        canvas.drawCircle(rect.center, w / 2, paint);
        canvas.drawLine(
          Offset(rect.center.dx, rect.top),
          Offset(rect.center.dx, rect.bottom),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(center: rect.center, width: w, height: h * 0.5),
          paint,
        ); // Ecuador
        break;
      case 'brujula':
        // Círculo y cruz
        canvas.drawCircle(rect.center, w / 2, paint);
        canvas.drawLine(rect.centerLeft, rect.centerRight, paint);
        canvas.drawLine(rect.topCenter, rect.bottomCenter, paint);
        // Aguja norte
        Path aguja = Path()
          ..moveTo(rect.center.dx, rect.top + h * 0.2)
          ..lineTo(rect.center.dx - w * 0.1, rect.center.dy)
          ..lineTo(rect.center.dx + w * 0.1, rect.center.dy)
          ..close();
        canvas.drawPath(aguja, paint);
        break;

      // ==========================================
      // 5. OTROS (Dimensiones, Fusiones, etc)
      // ==========================================
      case 'tripunto':
        canvas.drawCircle(ini, 5, paint);
        canvas.drawCircle(finEscalado, 5, paint);
        canvas.drawCircle(Offset(finEscalado.dx, ini.dy), 5, paint);
        break;
      case 'dimension':
        canvas.drawLine(ini, finEscalado, paint);
        canvas.drawLine(
          Offset(ini.dx, ini.dy - 10),
          Offset(ini.dx, ini.dy + 10),
          paint,
        );
        canvas.drawLine(
          Offset(finEscalado.dx, finEscalado.dy - 10),
          Offset(finEscalado.dx, finEscalado.dy + 10),
          paint,
        );
        break;
      case 'fusion':
        Path p = Path()
          ..moveTo(ini.dx, ini.dy)
          ..lineTo(rect.center.dx, rect.center.dy)
          ..close();
        Path p2 = Path()
          ..moveTo(finEscalado.dx, finEscalado.dy)
          ..lineTo(rect.center.dx, rect.center.dy)
          ..close();
        canvas.drawPath(p, paint);
        canvas.drawPath(p2, paint);
        break;
      case 'separacion':
        canvas.drawLine(
          Offset(ini.dx, ini.dy),
          Offset(finEscalado.dx - 20, finEscalado.dy - 20),
          paint,
        );
        canvas.drawLine(
          Offset(finEscalado.dx, finEscalado.dy),
          Offset(ini.dx + 20, ini.dy + 20),
          paint,
        );
        break;
      case 'esquina':
        canvas.drawLine(rect.topLeft, Offset(rect.right, rect.top), paint);
        canvas.drawLine(rect.topLeft, Offset(rect.left, rect.bottom), paint);
        break;
      case 'carga':
        canvas.drawArc(rect, -math.pi, math.pi, false, paint);
        canvas.drawLine(
          Offset(rect.left, rect.center.dy),
          Offset(rect.right, rect.center.dy),
          paint,
        );
        break;
      case 'corazon':
        canvas.drawPath(
          Path()
            ..moveTo(rect.center.dx, rect.bottom)
            ..quadraticBezierTo(
              rect.left,
              rect.top,
              rect.center.dx,
              rect.top + h * 0.3,
            )
            ..quadraticBezierTo(
              rect.right,
              rect.top,
              rect.center.dx,
              rect.bottom,
            )
            ..close(),
          paint,
        );
        break;
      case 'nube':
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(rect.center.dx - w * 0.2, rect.center.dy),
            width: w * 0.5,
            height: h * 0.5,
          ),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(rect.center.dx + w * 0.2, rect.center.dy),
            width: w * 0.5,
            height: h * 0.5,
          ),
          paint,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(rect.center.dx, rect.top + h * 0.3),
            width: w * 0.5,
            height: h * 0.5,
          ),
          paint,
        );
        break;
      case 'rayo':
        canvas.drawPath(
          Path()
            ..moveTo(rect.center.dx - w * 0.1, rect.top)
            ..lineTo(rect.left, rect.center.dy)
            ..lineTo(rect.center.dx - w * 0.05, rect.center.dy)
            ..lineTo(rect.right, rect.bottom)
            ..lineTo(rect.center.dx + w * 0.1, rect.center.dy + h * 0.1)
            ..close(),
          paint,
        );
        break;
      case 'gota':
        canvas.drawPath(
          Path()
            ..moveTo(rect.center.dx, rect.top)
            ..quadraticBezierTo(
              rect.right,
              rect.center.dy,
              rect.center.dx,
              rect.bottom,
            )
            ..quadraticBezierTo(
              rect.left,
              rect.center.dy,
              rect.center.dx,
              rect.top,
            )
            ..close(),
          paint,
        );
        break;
    }
  }

  void _dibujarFlechaDiagonal(
    Canvas canvas,
    Rect rect,
    int dirX,
    int dirY,
    Paint paint,
  ) {
    Offset center = rect.center;
    double length = math.min(rect.width, rect.height) * 0.4;

    // Calcular inicio y fin basado en dirección (-1 o 1)
    Offset inicio = Offset(
      center.dx - (length * dirX),
      center.dy - (length * dirY),
    );
    Offset fin = Offset(
      center.dx + (length * dirX),
      center.dy + (length * dirY),
    );

    canvas.drawLine(inicio, fin, paint);

    // Dibujar cabeza
    double headSize = length * 0.3;
    Path head = Path();

    // Vectores perpendiculares para la base de la flecha
    int perpX = -dirY;
    int perpY = dirX;

    head.moveTo(fin.dx, fin.dy);
    head.lineTo(
      fin.dx - (dirX * headSize) + (perpX * headSize * 0.5),
      fin.dy - (dirY * headSize) + (perpY * headSize * 0.5),
    );
    head.lineTo(
      fin.dx - (dirX * headSize) - (perpX * headSize * 0.5),
      fin.dy - (dirY * headSize) - (perpY * headSize * 0.5),
    );
    head.close();

    canvas.drawPath(head, paint..style = PaintingStyle.stroke);
  }

  void _dibujarPoligono(
    Canvas canvas,
    Offset center,
    double radius,
    int sides,
    Paint paint,
  ) {
    Path path = Path();
    double angle = (2 * math.pi) / sides;
    for (int i = 0; i <= sides; i++) {
      double x = center.dx + radius * math.cos(i * angle - math.pi / 2);
      double y = center.dy + radius * math.sin(i * angle - math.pi / 2);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  void _dibujarEstrella(
    Canvas canvas,
    Offset center,
    double radius,
    int points,
    Paint paint,
  ) {
    Path path = Path();
    double innerRadius = radius * 0.4;
    for (int i = 0; i < points * 2; i++) {
      double r = i.isEven ? radius : innerRadius;
      double x = center.dx + r * math.cos(i * math.pi / points - math.pi / 2);
      double y = center.dy + r * math.sin(i * math.pi / points - math.pi / 2);
      if (i == 0)
        path.moveTo(x, y);
      else
        path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _dibujarFlecha(Canvas canvas, Rect rect, String tipo, Paint paint) {
    Offset ini, fin;
    double headSize = rect.width * 0.3;
    if (tipo == 'flecha_derecha') {
      ini = rect.centerLeft;
      fin = rect.centerRight;
    } else if (tipo == 'flecha_izquierda') {
      ini = rect.centerRight;
      fin = rect.centerLeft;
    } else if (tipo == 'flecha_arriba') {
      ini = rect.bottomCenter;
      fin = rect.topCenter;
      headSize = rect.height * 0.3;
    } else {
      ini = rect.topCenter;
      fin = rect.bottomCenter;
      headSize = rect.height * 0.3;
    }
    canvas.drawLine(ini, fin, paint);
    Path head = Path();
    if (tipo.contains('derecha') || tipo.contains('izquierda')) {
      head.moveTo(fin.dx, fin.dy);
      head.lineTo(
        fin.dx - (tipo.contains('derecha') ? headSize : -headSize),
        fin.dy - headSize / 2,
      );
      head.lineTo(
        fin.dx - (tipo.contains('derecha') ? headSize : -headSize),
        fin.dy + headSize / 2,
      );
    } else {
      head.moveTo(fin.dx, fin.dy);
      head.lineTo(
        fin.dx - headSize / 2,
        fin.dy - (tipo.contains('arriba') ? -headSize : headSize),
      );
      head.lineTo(
        fin.dx + headSize / 2,
        fin.dy - (tipo.contains('arriba') ? -headSize : headSize),
      );
    }
    head.close();
    canvas.drawPath(head, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant FigurasPainter oldDelegate) =>
      oldDelegate.figuras.length != figuras.length ||
      oldDelegate.inicioActual != inicioActual ||
      oldDelegate.finActual != finActual ||
      oldDelegate.escalaActual != escalaActual;
}

// /// Pintor de Cuadrícula
// class CuadriculaPainter extends CustomPainter {
//   final bool isDark;
//   const CuadriculaPainter({required this.isDark});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = isDark
//           ? Colors.white.withOpacity(0.08)
//           : Colors.black.withOpacity(0.08)
//       ..strokeWidth = 1;
//     for (double i = 0; i <= size.width; i += 50)
//       canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
//     for (double i = 0; i <= size.height; i += 50)
//       canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter old) => false;
// }

//quitarlo

class CuadriculaPainter extends CustomPainter {
  final Color color;
  final double spacing; // Tamaño de la cuadrícula

  const CuadriculaPainter({
    required this.color,
    this.spacing = 50.0, // Valor por defecto
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1; // Grosor de la línea

    // Dibujar líneas verticales
    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Dibujar líneas horizontales
    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CuadriculaPainter oldDelegate) {
    // Repintar si cambia el color o el espaciado
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}

// ==========================================
// PÁGINA PRINCIPAL
// ==========================================

class MapaDibujoPage extends StatefulWidget {
  const MapaDibujoPage({super.key});

  @override
  State<MapaDibujoPage> createState() => _MapaDibujoPageState();
}

class _MapaDibujoPageState extends State<MapaDibujoPage>
    with WidgetsBindingObserver {
  late ScribbleNotifier notifier;
  GoogleMapController? _mapController;
  final ImagePicker _picker = ImagePicker();
  final TransformationController _viewController = TransformationController();
  final GlobalKey _globalKeyParaCaptura = GlobalKey();

  Uint8List? _mapaImagen;
  final ValueNotifier<Matrix4> _mapMatrix = ValueNotifier(Matrix4.identity());
  final ValueNotifier<double> _opacidadImagen = ValueNotifier(1.0);

  bool _verCuadricula = true;
  bool _verMapa = true;
  bool _modoFiguras = false;
  bool _modoMoverImagen = false;
  bool _modoTexto = false;
  bool _esBorrador = false;
  bool _panelExtendido = false;
  String _figuraSeleccionada = "cuadrado";

  Color _colorActual = Colors.black;
  Color _colorFondo = Colors.transparent;
  double _grosorActual = 2.0;
  double _tamanoTexto = 16.0;

  final List<TextNote> _notasTexto = [];
  final List<DibujoFigura> _figuras = [];
  Offset? _puntoInicioFigura;
  Offset? _puntoFinFigura;

  //experimento
  // ... otras variables
  Color _colorCuadricula = Colors.black.withOpacity(0.1); // Color inicial
  double _tamanoCuadricula = 60.0; // Tamaño inicial (50px)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    notifier = ScribbleNotifier();
    notifier.setColor(Colors.black);
    notifier.setStrokeWidth(_grosorActual);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarSesionTemporal();
      _mostrarAlertaBetaEntrada();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // --- PERSISTENCIA ---
  Future<void> _guardarSesionTemporal() async {
    try {
      RenderRepaintBoundary? boundary =
          _globalKeyParaCaptura.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/calipso_sesion_temp.png');
          await file.writeAsBytes(byteData.buffer.asUint8List());
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('calipso_sesion_activa', true);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sesión guardada."),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error guardando sesión: $e");
    }
  }

  Future<void> _cargarSesionTemporal() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('calipso_sesion_activa') ?? false) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/calipso_sesion_temp.png');
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        setState(() {
          _mapaImagen = bytes;
          _modoMoverImagen = false;
        });
        notifier.clear();
        _figuras.clear();
        _notasTexto.clear();
        await prefs.setBool('calipso_sesion_activa', false);
      }
    }
  }

  // --- SELECTOR DE COLOR PROFESIONAL ---
  void _abrirSelectorColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color tempColor = _colorActual;
        return AlertDialog(
          title: const Text(
            "Seleccionar Color",
            // style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: tempColor,
              onColorChanged: (Color color) {
                tempColor = color;
                setState(() {
                  _colorActual = color;
                  if (!_esBorrador && !_modoFiguras) {
                    notifier.setColor(
                      color == Colors.transparent ? Colors.black : color,
                    );
                  }
                });
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <TextButton>[
            TextButton(
              child: const Text("LISTO", style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _cambiarColorFondo(Color nuevoColor) {
    setState(() => _colorFondo = nuevoColor);
  }

  // --- EDICIÓN DE FIGURAS ---
  DibujoFigura? _obtenerFiguraEnPosicion(Offset posicion) {
    for (int i = _figuras.length - 1; i >= 0; i--) {
      final fig = _figuras[i];
      Offset finEscalado = Offset(
        fig.inicio.dx + (fig.fin.dx - fig.inicio.dx) * fig.escala,
        fig.inicio.dy + (fig.fin.dy - fig.inicio.dy) * fig.escala,
      );
      Rect rect = Rect.fromPoints(fig.inicio, finEscalado);
      if (rect.contains(posicion)) return fig;
    }
    return null;
  }

  void _mostrarOpcionesFigura(DibujoFigura figura) {
    double tempEscala = figura.escala;
    Color tempColor = figura.color;
    bool tempRelleno = figura.relleno;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewPadding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "EDITAR FIGURA",
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF161B22),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                // Selector Borde/Relleno
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () =>
                            setModalState(() => tempRelleno = false),
                        child: Row(
                          children: [
                            Icon(
                              Icons.crop_square,
                              color: !tempRelleno
                                  ? (isDark
                                        ? Colors.blue
                                        : const Color(0xFF1A237E))
                                  : Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "BORDE",
                              style: TextStyle(
                                color: !tempRelleno
                                    ? (isDark
                                          ? Colors.blue
                                          : const Color(0xFF1A237E))
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () =>
                            setModalState(() => tempRelleno = true),
                        child: Row(
                          children: [
                            Icon(
                              Icons.square,
                              color: tempRelleno
                                  ? (isDark
                                        ? Colors.blue
                                        : const Color(0xFF1A237E))
                                  : Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              "RELLENO",
                              style: TextStyle(
                                color: tempRelleno
                                    ? (isDark
                                          ? Colors.blue
                                          : const Color(0xFF1A237E))
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                // Selector de Color Profesional para Figura
                GestureDetector(
                  onTap: () {
                    Color backupColor = tempColor;
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: tempColor,
                            onColorChanged: (Color color) =>
                                setModalState(() => tempColor = color),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("LISTO"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: tempColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Center(
                      child: Text(
                        "Cambiar Color",
                        style: TextStyle(
                          color: tempColor.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Divider(
                  color: isDark ? Colors.white10 : Colors.black12,
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tamaño:",
                      style: TextStyle(
                        color: isDark ? Colors.grey : Colors.black54,
                      ),
                    ),
                    Text(
                      "${(tempEscala * 100).toInt()}%",
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF161B22),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: tempEscala,
                  min: 0.2,
                  max: 3.0,
                  activeColor: isDark ? Colors.blue : const Color(0xFF1A237E),
                  onChanged: (v) => setModalState(() => tempEscala = v),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () {
                      setState(() => _figuras.remove(figura));
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text(
                      "ELIMINAR FIGURA",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.blue
                          : const Color(0xFF1A237E),
                    ),
                    onPressed: () {
                      setState(() {
                        figura.color = tempColor;
                        figura.escala = tempEscala;
                        figura.relleno = tempRelleno;
                      });
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      "APLICAR CAMBIOS",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ALERTAS Y DIALOGOS ---
  Future<void> _verificarPermisosUbicacion() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) status = await Permission.locationWhenInUse.request();
    if (status.isPermanentlyDenied) openAppSettings();
  }

  void _mostrarAlertaBetaEntrada() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              minWidth: 300,
            ),
            child: AlertDialog(
              backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.orangeAccent, width: 1),
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: isDark ? Colors.red : Colors.redAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "MODO EXPERIMENTAL",
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF161B22),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Text(
                "Esta función se encuentra en fase de prueba.\n\nSe recomienda guardar copias frecuentes.",
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF161B22),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "ENTENDIDO",
                    style: TextStyle(
                      color: isDark ? Colors.blue : const Color(0xFF1A237E),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoNuevaNota(Offset localPos) {
    final TextEditingController _notaController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double currentTextSize = _tamanoTexto;
    Color currentTextColor = _colorActual;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
          title: Text(
            "Nueva Anotación",
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    "Color: ",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Color tempColor = currentTextColor;
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          content: SingleChildScrollView(
                            child: ColorPicker(
                              pickerColor: tempColor,
                              onColorChanged: (color) {
                                setDialogState(() => currentTextColor = color);
                              },
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: Builder(
                                builder: (context) {
                                  // Calculamos si el color es oscuro o claro para elegir el color del texto
                                  // usando luminancia estándar
                                  bool isDarkColor =
                                      tempColor.computeLuminance() < 0.5;
                                  Color textColor = isDarkColor
                                      ? Colors.red
                                      : Colors.black;

                                  return Text(
                                    "LISTO",
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: currentTextColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notaController,
                autofocus: true,
                style: TextStyle(
                  color: currentTextColor,
                  fontSize: currentTextSize,
                ),
                decoration: InputDecoration(
                  hintText: "Escribe el reporte aquí...",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white24 : Colors.black87,
                  ),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1A237E), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    "Tamaño: ",
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: currentTextSize,
                      min: 10.0,
                      max: 48.0,
                      activeColor: const Color(0xFF1A237E),
                      label: "${currentTextSize.toInt()}",
                      onChanged: (v) {
                        setDialogState(() => currentTextSize = v);
                        setState(() => _tamanoTexto = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCELAR"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF1A237E)
                    : Colors.white70,
              ),
              onPressed: () {
                if (_notaController.text.isNotEmpty) {
                  setState(() {
                    _notasTexto.add(
                      TextNote(
                        position: localPos,
                        text: _notaController.text,
                        color: currentTextColor,
                        fontSize: currentTextSize,
                      ),
                    );
                    _colorActual = currentTextColor;
                  });
                  Navigator.pop(context);
                }
              },
              child: Text(
                "AÑADIR",
                style: TextStyle(
                  color: isDark ? Colors.white54 : const Color(0xFF1A237E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- GUARDADO ---
  Future<void> _guardarDibujo() async {
    try {
      RenderRepaintBoundary? boundary =
          _globalKeyParaCaptura.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final directory = await getApplicationDocumentsDirectory();
      final String nombreArchivo =
          'CALIPSO_${DateTime.now().millisecondsSinceEpoch}.png';
      final String path = '${directory.path}/$nombreArchivo';
      final File file = File(path);
      await file.writeAsBytes(pngBytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A237E),
          content: Text("Dibujo guardado: $nombreArchivo"),
          action: SnackBarAction(
            label: "EXPORTAR",
            textColor: Colors.greenAccent,
            onPressed: () => Share.shareXFiles([
              XFile(path),
            ], text: 'Reporte Táctico CALIPSO'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al procesar el dibujo"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- MODALES DE HERRAMIENTAS ---
  void _showGeometricModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          color: Color(0xFF161B22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          children: [
            const Text(
              "FIGURAS TÁCTICAS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: GridView.count(
                crossAxisCount: 6,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
                children: [
                  // ==========================================
                  // 1. FIGURAS GEOMÉTRICAS
                  // ==========================================
                  _geoOption(Icons.horizontal_rule, "Línea", "linea"),
                  _geoOption(
                    Icons.check_box_outline_blank,
                    "Cuadrado",
                    "cuadrado",
                  ),
                  _geoOption(Icons.crop_din, "Rectángulo", "rectangulo"),
                  _geoOption(
                    Icons.radio_button_unchecked,
                    "Círculo",
                    "circulo",
                  ),
                  _geoOption(Icons.circle_outlined, "Óvalo", "ovalo"),
                  _geoOption(Icons.change_history, "Triángulo", "triangulo"),
                  _geoOption(Icons.hexagon_outlined, "Hexágono", "hexagono"),
                  _geoOption(Icons.pentagon_outlined, "Pentágono", "pentagono"),
                  _geoOption(Icons.diamond_outlined, "Rombo", "rombo"),
                  _geoOption(Icons.star_outline, "Estrella 5", "estrella5"),
                  _geoOption(
                    Icons.filter_tilt_shift,
                    "Estrella 4",
                    "estrella4",
                  ),
                  _geoOption(Icons.add, "Cruz", "cruz"),
                  _geoOption(Icons.close, "Equis", "equis"),
                  _geoOption(Icons.crop_square, "Marco", "marco"),
                  _geoOption(Icons.lens_outlined, "Lente", "lente"),

                  // ==========================================
                  // 2. FLECHAS (Incluyendo Diagonales)
                  // ==========================================
                  _geoOption(
                    Icons.arrow_right_alt,
                    "Flecha →",
                    "flecha_derecha",
                  ),
                  _geoOption(Icons.arrow_back, "Flecha ←", "flecha_izquierda"),
                  _geoOption(Icons.arrow_upward, "Flecha ↑", "flecha_arriba"),
                  _geoOption(Icons.arrow_downward, "Flecha ↓", "flecha_abajo"),

                  // Nuevas flechas diagonales
                  _geoOption(
                    Icons.arrow_upward,
                    "Flecha ↗",
                    "flecha_diagonal_arriba_derecha",
                  ),
                  _geoOption(
                    Icons.arrow_upward,
                    "Flecha ↖",
                    "flecha_diagonal_arriba_izquierda",
                  ),
                  _geoOption(
                    Icons.arrow_downward,
                    "Flecha ↘",
                    "flecha_diagonal_abajo_derecha",
                  ),
                  _geoOption(
                    Icons.arrow_downward,
                    "Flecha ↙",
                    "flecha_diagonal_abajo_izquierda",
                  ),

                  // ==========================================
                  // 3. SÍMBOLOS MILITARES
                  // ==========================================
                  _geoOption(Icons.shield_outlined, "Escudo", "escudo"),
                  _geoOption(
                    Icons.shield_outlined,
                    "Escudo Mil.",
                    "escudo_militar",
                  ),
                  _geoOption(Icons.star, "Medalla", "medalla_estrella"),
                  _geoOption(
                    Icons.local_fire_department,
                    "Explosión",
                    "explosion",
                  ),
                  _geoOption(Icons.sports_kabaddi, "Bayoneta", "bayoneta"),
                  _geoOption(Icons.local_police, "Insignia", "insignia"),

                  // ==========================================
                  // 4. SITIOS DE REFERENCIA (MAPA)
                  // ==========================================
                  _geoOption(
                    Icons.location_on_outlined,
                    "Ubicación",
                    "ubicacion",
                  ),
                  _geoOption(Icons.terrain, "Montaña", "montana"),
                  _geoOption(Icons.waves, "Olas", "olas"),
                  _geoOption(Icons.grass, "Bosque", "bosque"),
                  _geoOption(Icons.location_city, "Fortaleza", "fortaleza"),
                  _geoOption(Icons.flag, "Bandera", "bandera"),
                  _geoOption(Icons.flight, "Avión", "avion"),
                  _geoOption(Icons.directions_boat, "Barco", "barco"),
                  _geoOption(Icons.landscape, "Colina", "colina"),
                  _geoOption(Icons.public, "Globo", "globo"),
                  _geoOption(Icons.explore, "Brújula", "brujula"),

                  // ==========================================
                  // 5. OTROS (Dimensiones, Fusiones, etc)
                  // ==========================================
                  _geoOption(Icons.trip_origin, "Tri-Punto", "tripunto"),
                  _geoOption(
                    Icons.linear_scale_outlined,
                    "Dimensión",
                    "dimension",
                  ),
                  _geoOption(Icons.merge_type, "Fusión", "fusion"),
                  _geoOption(Icons.call_split, "Separación", "separacion"),
                  _geoOption(Icons.rounded_corner, "Esquina", "esquina"),
                  _geoOption(Icons.data_usage, "Carga", "carga"),
                  _geoOption(Icons.favorite_border, "Corazón", "corazon"),
                  _geoOption(Icons.cloud_outlined, "Nube", "nube"),
                  _geoOption(Icons.flash_on, "Rayo", "rayo"),
                  _geoOption(Icons.water_drop_outlined, "Gota", "gota"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _geoOption(IconData icon, String label, String tipo) {
    bool isSel = _figuraSeleccionada == tipo;
    return GestureDetector(
      onTap: () {
        setState(() => _figuraSeleccionada = tipo);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSel
              ? const Color(0xFF1A237E)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSel ? Colors.blue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSel ? Colors.white : Colors.grey, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 7),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoFondo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
        title: Text(
          "Color de Fondo",
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Wrap(
          spacing: 10,
          children: [
            _opcionFondo(Colors.transparent, "Transparente", isDark),
            _opcionFondo(Colors.black, "Negro", isDark),
            _opcionFondo(Colors.white, "Blanco", isDark),
            _opcionFondo(const Color(0xFF0D1117), "Oscuro App", isDark),
            _opcionFondo(Colors.grey[200]!, "Claro App", isDark),
            _opcionFondo(const Color(0xFF2E2E2E), "Gris Oscuro", isDark),
            //los mios
            _opcionFondo(const Color(0xFF556B2F), "Verde Oliva", isDark),
            _opcionFondo(const Color(0xFF228B22), "Verde Bosque", isDark),
            _opcionFondo(const Color(0xFFF5DEB3), "Arena", isDark),
            _opcionFondo(const Color(0xFF8B4513), "Marron Tierra", isDark),
            _opcionFondo(const Color(0xFF87CEEB), "Azul Marino", isDark),
            _opcionFondo(const Color(0xFF001F3F), "Azul Cielo", isDark),
            _opcionFondo(const Color(0xFF800000), "Granate", isDark),
            _opcionFondo(const Color(0xFF8B0000), "Rojo Oscuro", isDark),
          ],
        ),
      ),
    );
  }

  Widget _opcionFondo(Color color, String label, bool isDark) {
    return GestureDetector(
      onTap: () {
        _cambiarColorFondo(color);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _colorFondo == color ? Colors.blue : Colors.grey,
                width: 1,
              ),
            ),
            child: color == Colors.transparent
                ? const Icon(Icons.check_box_outline_blank, color: Colors.grey)
                : null,
          ),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // --- MAPAS Y UBICACIÓN ---
  void _mostrarDialogoOrigen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              title: Text(
                "ORIGEN DEL FONDO",
                style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.cyanAccent),
              title: const Text(
                "Google Maps",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _abrirSelectorMapa();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: Colors.purpleAccent,
              ),
              title: const Text(
                "Galería",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _cargarDesdeGaleria();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cargarDesdeGaleria() async {
    final XFile? img = await _picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() {
        _mapaImagen = bytes;
        _mapMatrix.value = Matrix4.identity();
        _modoMoverImagen = true;
      });
    }
  }

  LatLng? _parsearDMS(String input) {
    final regex = RegExp(r'(\d+)\s+(\d+)\s+([\d.]+)\s+([NSEOWnseow])');
    final match = regex.firstMatch(input);
    if (match != null) {
      double lat =
          double.parse(match.group(1)!) +
          (double.parse(match.group(2)!) / 60) +
          (double.parse(match.group(3)!) / 3600);
      String dirLat = match.group(4)!.toUpperCase();
      if (dirLat == 'S') lat *= -1;
      final match2 = regex.firstMatch(input.substring(match.end));
      if (match2 != null) {
        double lon =
            double.parse(match2.group(1)!) +
            (double.parse(match2.group(2)!) / 60) +
            (double.parse(match2.group(3)!) / 3600);
        String dirLon = match2.group(4)!.toUpperCase();
        if (dirLon == 'W' || dirLon == 'O') lon *= -1;
        return LatLng(lat, lon);
      }
    }
    return null;
  }

  Future<void> _irAMiUbicacion() async {
    await _verificarPermisosUbicacion();
    if (await Permission.locationWhenInUse.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16,
            ),
          ),
        );
      } catch (e) {
        debugPrint("Error obteniendo ubicación GPS: $e");
      }
    }
  }

  void _abrirSelectorMapa() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          width: MediaQuery.of(context).size.width * 0.98,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1A237E),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              title: SearchAnchor(
                builder: (BuildContext context, SearchController controller) {
                  return SearchBar(
                    controller: controller,
                    hintText: "Ciudad o GMS (ej: 4° 34' N)...",
                    hintStyle: WidgetStateProperty.all(
                      const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    backgroundColor: WidgetStateProperty.all(
                      Colors.white.withOpacity(0.1),
                    ),
                    elevation: WidgetStateProperty.all(0),
                    textStyle: WidgetStateProperty.all(
                      const TextStyle(color: Colors.white),
                    ),
                    onTap: () => controller.openView(),
                    onChanged: (_) => controller.openView(),
                    leading: const Icon(Icons.search, color: Colors.white54),
                  );
                },
                suggestionsBuilder:
                    (BuildContext context, SearchController controller) async {
                      if (controller.text.isEmpty) return [];
                      LatLng? coordsDMS = _parsearDMS(controller.text);
                      if (coordsDMS != null) {
                        return [
                          ListTile(
                            leading: const Icon(
                              Icons.gps_fixed,
                              color: Colors.greenAccent,
                            ),
                            title: Text(
                              "Ir a: ${coordsDMS.latitude.toStringAsFixed(4)}, ${coordsDMS.longitude.toStringAsFixed(4)}",
                            ),
                            onTap: () {
                              _mapController?.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(target: coordsDMS, zoom: 16),
                                ),
                              );
                              controller.closeView(controller.text);
                            },
                          ),
                        ];
                      }
                      try {
                        List<Location> locations = await locationFromAddress(
                          controller.text,
                        );
                        return List<
                          ListTile
                        >.generate(locations.length > 3 ? 3 : locations.length, (
                          index,
                        ) {
                          final loc = locations[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                            ),
                            title: Text(
                              "${loc.latitude.toStringAsFixed(3)}, ${loc.longitude.toStringAsFixed(3)}",
                            ),
                            onTap: () {
                              _mapController?.animateCamera(
                                CameraUpdate.newCameraPosition(
                                  CameraPosition(
                                    target: LatLng(loc.latitude, loc.longitude),
                                    zoom: 16,
                                  ),
                                ),
                              );
                              controller.closeView(controller.text);
                            },
                          );
                        });
                      } catch (e) {
                        return [const ListTile(title: Text("Sin resultados"))];
                      }
                    },
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.check_circle,
                    color: Colors.greenAccent,
                    size: 30,
                  ),
                  onPressed: () async {
                    final imageBytes = await _mapController?.takeSnapshot();
                    if (imageBytes != null) {
                      setState(() {
                        _mapaImagen = imageBytes;
                        _mapMatrix.value = Matrix4.identity();
                        _modoMoverImagen = true;
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(4.5709, -74.2973),
                    zoom: 12,
                  ),
                  mapType: MapType.hybrid,
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
                const IgnorePointer(
                  child: Center(
                    child: Icon(Icons.add, color: Colors.white, size: 45),
                  ),
                ),
                Positioned(
                  right: 15,
                  top: 100,
                  child: Column(
                    children: [
                      _mapActionButton(
                        Icons.add,
                        () => _mapController?.animateCamera(
                          CameraUpdate.zoomIn(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _mapActionButton(
                        Icons.remove,
                        () => _mapController?.animateCamera(
                          CameraUpdate.zoomOut(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _mapActionButton(
                        Icons.my_location,
                        _irAMiUbicacion,
                        color: Colors.lightBlueAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mapActionButton(
    IconData icon,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return FloatingActionButton.small(
      heroTag: null,
      backgroundColor: const Color(0xFF161B22).withOpacity(0.9),
      onPressed: onTap,
      child: Icon(icon, color: color),
    );
  }

  void _gestionarTap(TapUpDetails details) {
    if (!_modoTexto) return;
    final Offset localPos = _viewController.toScene(details.localPosition);
    _mostrarDialogoNuevaNota(localPos);
  }

  void _voltearImagenHorizontal() {
    final m = _mapMatrix.value.clone();
    m.storage[0] = -m.storage[0];
    m.storage[1] = -m.storage[1];
    m.storage[2] = -m.storage[2];
    _mapMatrix.value = m;
  }

  void _voltearImagenVertical() {
    final m = _mapMatrix.value.clone();
    m.storage[4] = -m.storage[4];
    m.storage[5] = -m.storage[5];
    m.storage[6] = -m.storage[6];
    _mapMatrix.value = m;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        title: const Text(
          "CALIPSO | EDITOR TÁCTICO",
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(_verCuadricula ? Icons.grid_on : Icons.grid_off),
            tooltip: "Cuadrícula",
            onPressed: () {
              setState(() => _verCuadricula = !_verCuadricula);
            },
          ),
          // IconButton(
          //   icon: const Icon(Icons.location_on, color: Colors.redAccent),
          //   onPressed: () async {
          //     await _verificarPermisosUbicacion();
          //   },
          // ),
          IconButton(
            icon: Icon(
              _mapaImagen == null ? Icons.add_a_photo : Icons.no_photography,
            ),
            color: _mapaImagen == null ? Colors.white : Colors.redAccent,
            onPressed: _mapaImagen == null
                ? _mostrarDialogoOrigen
                : () => setState(() => _mapaImagen = null),
          ),
          IconButton(
            tooltip: "Guardar Temporalmente",
            icon: const Icon(
              Icons.save_as_outlined,
              color: Colors.yellowAccent,
            ),
            onPressed: _guardarSesionTemporal,
          ),
          IconButton(
            icon: const Icon(
              Icons.save,
              color: Color.fromARGB(255, 12, 156, 17),
            ),
            onPressed: _guardarDibujo,
          ),
        ],
      ),
      body: Stack(
        children: [
          RepaintBoundary(
            key: _globalKeyParaCaptura,
            child: InteractiveViewer(
              transformationController: _viewController,
              panEnabled: !_modoMoverImagen,
              minScale: 0.1,
              maxScale: 5.0,
              child: GestureDetector(
                onTapUp: _gestionarTap,
                child: SizedBox(
                  width: 2500,
                  height: 2500,
                  child: Stack(
                    children: [
                      Positioned.fill(child: Container(color: _colorFondo)),
                      // if (_verCuadricula)
                      //   Positioned.fill(
                      //     child: CustomPaint(
                      //       painter: CuadriculaPainter(isDark: isDark),
                      //     ),
                      //   ),

                      // Antes:
                      // if (_verCuadricula) Positioned.fill(child: CustomPaint(painter: CuadriculaPainter(isDark: isDark))),

                      // Ahora:
                      if (_verCuadricula)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CuadriculaPainter(
                              color: _colorCuadricula,
                              spacing: _tamanoCuadricula,
                            ),
                          ),
                        ),
                      if (_mapaImagen != null && _verMapa)
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !_modoMoverImagen,
                            child: MatrixGestureDetector(
                              onMatrixUpdate: (m, tm, sm, rm) {
                                _mapMatrix.value = m;
                              },
                              child: AnimatedBuilder(
                                animation: Listenable.merge([
                                  _mapMatrix,
                                  _opacidadImagen,
                                ]),
                                builder: (ctx, child) => Transform(
                                  transform: _mapMatrix.value,
                                  child: Center(
                                    child: Opacity(
                                      opacity: _opacidadImagen.value,
                                      child: Image.memory(_mapaImagen!),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring:
                              _modoMoverImagen || _modoTexto || _modoFiguras,
                          child: Scribble(notifier: notifier),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: !_modoFiguras,
                          child: GestureDetector(
                            onPanStart: (details) {
                              DibujoFigura? figuraTocada =
                                  _obtenerFiguraEnPosicion(
                                    details.localPosition,
                                  );
                              if (figuraTocada != null) {
                                _mostrarOpcionesFigura(figuraTocada);
                              } else {
                                setState(() {
                                  _puntoInicioFigura = details.localPosition;
                                  _puntoFinFigura = details.localPosition;
                                });
                              }
                            },
                            onPanUpdate: (details) {
                              if (_puntoInicioFigura != null)
                                setState(
                                  () => _puntoFinFigura = details.localPosition,
                                );
                            },
                            onPanEnd: (details) {
                              if (_puntoInicioFigura != null &&
                                  _puntoFinFigura != null) {
                                setState(() {
                                  _figuras.add(
                                    DibujoFigura(
                                      tipo: _figuraSeleccionada,
                                      inicio: _puntoInicioFigura!,
                                      fin: _puntoFinFigura!,
                                      color: _colorActual,
                                      grosor: _grosorActual,
                                      escala: 1.0,
                                    ),
                                  );
                                  _puntoInicioFigura = null;
                                  _puntoFinFigura = null;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: true,
                          child: CustomPaint(
                            painter: FigurasPainter(
                              figuras: _figuras,
                              inicioActual: _puntoInicioFigura,
                              finActual: _puntoFinFigura,
                              colorActual: _colorActual,
                              grosorActual: _grosorActual,
                              tipoActual: _figuraSeleccionada,
                              escalaActual: 1.0,
                            ),
                          ),
                        ),
                      ),
                      ..._notasTexto.map(
                        (nota) => Positioned(
                          left: nota.position.dx,
                          top: nota.position.dy,
                          child: GestureDetector(
                            onLongPress: () =>
                                setState(() => _notasTexto.remove(nota)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              // FONDO NEGRO ELIMINADO
                              child: Text(
                                nota.text,
                                style: TextStyle(
                                  color: nota.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: nota.fontSize,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 16,
            child: Column(
              children: [
                _actionFab(Icons.undo, Colors.orange, () => notifier.undo()),
                const SizedBox(height: 12),
                _actionFab(Icons.delete_forever, Colors.redAccent, () {
                  notifier.clear();
                  setState(() {
                    _notasTexto.clear();
                    _figuras.clear();
                  });
                }),
              ],
            ),
          ),
          if (_modoMoverImagen && _mapaImagen != null)
            Positioned(
              left: 16,
              top: 16,
              child: Column(
                children: [
                  _actionFab(
                    Icons.swap_horiz,
                    Colors.cyanAccent,
                    _voltearImagenHorizontal,
                  ),
                  const SizedBox(height: 12),
                  _actionFab(
                    Icons.swap_vert,
                    Colors.cyanAccent,
                    _voltearImagenVertical,
                  ),
                ],
              ),
            ),
          _buildBottomPanel(isDark),
        ],
      ),
    );
  }

  Widget _actionFab(IconData icon, Color color, VoidCallback onTap) {
    return FloatingActionButton.small(
      heroTag: null,
      backgroundColor: const Color(0xFF161B22),
      onPressed: onTap,
      child: Icon(icon, color: color),
    );
  }

  Widget _buildBottomPanel(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _panelExtendido = !_panelExtendido),
            child: Container(
              width: 25,
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A237E) : Colors.blueGrey,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(12),
                ),
              ),
              child: Icon(
                _panelExtendido ? Icons.chevron_right : Icons.chevron_left,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: _panelExtendido ? 120 : 0,
            margin: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF161B22).withOpacity(0.95)
                  : Colors.white.withOpacity(0.85),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(20),
              ),
              boxShadow: _panelExtendido
                  ? [const BoxShadow(color: Colors.black45, blurRadius: 10)]
                  : [],
            ),
            child: _panelExtendido
                ? SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 5,
                    ),
                    child: Column(
                      children: [
                        _miniToolBtn(
                          Icons.format_color_fill,
                          "FONDO",
                          false,
                          _mostrarDialogoFondo,
                          color: _colorFondo != Colors.transparent
                              ? _colorFondo
                              : (isDark ? Colors.grey : Colors.black),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _miniToolBtn(
                              Icons.edit,
                              "TRAZO",
                              !_modoMoverImagen &&
                                  !_esBorrador &&
                                  !_modoTexto &&
                                  !_modoFiguras,
                              () {
                                setState(
                                  () => _modoMoverImagen = _modoTexto =
                                      _esBorrador = _modoFiguras = false,
                                );
                                notifier.setColor(_colorActual);
                              },
                            ),
                            _miniToolBtn(
                              Icons.hexagon_outlined,

                              "FIGURA",
                              _modoFiguras,
                              () {
                                setState(() => _modoFiguras = true);
                                _modoMoverImagen = _modoTexto = _esBorrador =
                                    false;
                                _showGeometricModal(context);
                              },
                            ),
                            _miniToolBtn(
                              Icons.text_fields,
                              "TEXTO",
                              _modoTexto,
                              () {
                                setState(() => _modoTexto = true);
                                _modoMoverImagen = _esBorrador = _modoFiguras =
                                    false;
                              },
                            ),
                            _toolBtn(
                              Icons.auto_fix_high,
                              "BORRAR",
                              _esBorrador,
                              () {
                                setState(() => _esBorrador = true);
                                _modoMoverImagen = false;
                                _modoTexto = false;
                                _modoFiguras = false;
                                notifier.setEraser();
                              },
                            ),
                            _miniToolBtn(
                              Icons.crop_rotate,
                              "Mover",
                              _modoMoverImagen,
                              () {
                                setState(() => _modoMoverImagen = true);
                                _modoTexto = _esBorrador = _modoFiguras = false;
                              },
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 20),
                        if (!_modoTexto) ...[
                          const Icon(
                            Icons.linear_scale,
                            size: 16,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            height: 90,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Slider(
                                value: _grosorActual.clamp(1.0, 20.0),
                                min: 1.0,
                                max: 20.0,
                                activeColor: const Color(0xFF1A237E),
                                onChanged: (v) {
                                  setState(() => _grosorActual = v);
                                  notifier.setStrokeWidth(v);
                                },
                              ),
                            ),
                          ),
                          Text(
                            "${_grosorActual.toInt()} pt",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if (_modoTexto) ...[
                          const Icon(
                            Icons.format_size,
                            size: 16,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            height: 90,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Slider(
                                value: _tamanoTexto.clamp(10.0, 48.0),
                                min: 10.0,
                                max: 48.0,
                                activeColor: const Color(0xFF1A237E),
                                onChanged: (v) =>
                                    setState(() => _tamanoTexto = v),
                              ),
                            ),
                          ),
                          Text(
                            "${_tamanoTexto.toInt()}",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if (_mapaImagen != null) ...[
                          const Divider(color: Colors.white10, height: 20),
                          const Icon(
                            Icons.opacity,
                            size: 16,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            height: 90,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Slider(
                                value: _opacidadImagen.value,
                                min: 0.1,
                                max: 1.0,
                                activeColor: Colors.blueGrey,
                                onChanged: (v) =>
                                    setState(() => _opacidadImagen.value = v),
                              ),
                            ),
                          ),
                          Text(
                            "${(_opacidadImagen.value * 100).toInt()}%",
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        const Divider(color: Colors.white10, height: 20),
                        InkWell(
                          onTap: _abrirSelectorColor,
                          child: Container(
                            width: double.infinity,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _colorActual,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Center(
                              child: Text(
                                "COLOR",
                                style: TextStyle(
                                  color: _colorActual.computeLuminance() > 0.5
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ... controles anteriores ...
                        const Divider(
                          color: Colors.blueGrey,
                          indent: 25,
                          endIndent: 25,
                          height: 20,
                        ),

                        // --- CONTROL DE CUADRÍCULA (NUEVO) ---
                        const Icon(Icons.grid_on, size: 16, color: Colors.grey),
                        Text(
                          "Cuadrícula",
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),

                        // 1. Slider para el Tamaño
                        SizedBox(
                          height: 90,
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              value: _tamanoCuadricula.clamp(
                                20.0,
                                200.0,
                              ), // Entre 20px y 200px
                              min: 20.0,
                              max: 200.0,
                              activeColor: Colors.blueAccent,
                              onChanged: (v) =>
                                  setState(() => _tamanoCuadricula = v),
                            ),
                          ),
                        ),
                        Text(
                          "${_tamanoCuadricula.toInt()}",
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // 2. Botón para cambiar el Color
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            // Mostrar selector de color específico para la cuadrícula
                            Color tempColor = _colorCuadricula;
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Color de Cuadrícula"),
                                content: SingleChildScrollView(
                                  child: ColorPicker(
                                    pickerColor: tempColor,
                                    onColorChanged: (color) {
                                      setState(() => _colorCuadricula = color);
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("LISTO"),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            height: 30,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _colorCuadricula,
                              // color: _colorActual,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: Text(
                              'Cuadrilla',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _colorCuadricula.computeLuminance() > 0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _miniToolBtn(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap, {
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 45,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: active ? Border.all(color: Colors.blue, width: 1.5) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? const Color(0xFF1A237E) : (color ?? Colors.grey),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 7,
                color: active ? const Color(0xFF1A237E) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolBtn(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return IconButton(
      icon: Column(
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFF1A237E) : Colors.grey,
            size: 22,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 7,
              color: active ? const Color(0xFF1A237E) : Colors.grey,
            ),
          ),
        ],
      ),
      onPressed: onTap,
    );
  }
}
