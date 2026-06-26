import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DocxExporter {
  /// Genera y exporta un archivo Word (.docx) con la tabla de datos.
  static Future<void> exportToWord(
    List<Map<String, dynamic>> data, {
    required Function(String) onError,
  }) async {
    try {
      // 1. Construir el XML del contenido (Word/document.xml)
      String xmlContent = _buildDocumentXml(data);

      // 2. Codificar el XML a bytes
      List<int> xmlBytes = utf8.encode(xmlContent);

      // 3. Crear el archivo ZIP (El .docx es un archivo ZIP)
      final archive = Archive();

      // Estructura mínima de carpetas necesarias para un .docx válido
      archive.addFile(
        ArchiveFile('[Content_Types].xml', 0, utf8.encode(_contentTypesXml)),
      );
      archive.addFile(ArchiveFile('_rels/.rels', 0, utf8.encode(_relsXml)));
      archive.addFile(
        ArchiveFile(
          'word/_rels/document.xml.rels',
          0,
          utf8.encode(_documentRelsXml),
        ),
      );
      archive.addFile(
        ArchiveFile('word/document.xml', xmlBytes.length, xmlBytes),
      );
      archive.addFile(
        ArchiveFile('word/styles.xml', 0, utf8.encode(_stylesXml)),
      );

      // 4. Comprimir el archivo
      final zipBytes = ZipEncoder().encode(archive);

      if (zipBytes == null) {
        throw Exception("No se pudo comprimir el archivo");
      }

      // 5. Guardar temporalmente y compartir
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/Reporte_Inteligencia_${DateTime.now().millisecondsSinceEpoch}.docx';
      final file = File(path);
      await file.writeAsBytes(zipBytes);

      // Compartir/Descargar
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Reporte Word Inteligencia');
    } catch (e) {
      onError("Error generando Word: $e");
    }
  }

  // --- ESTRUCTURA XML PRINCIPAL ---

  /// Construye el XML con la tabla y los datos
  static String _buildDocumentXml(List<Map<String, dynamic>> data) {
    final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Generar filas de datos
    String rowsXml = '';
    for (var m in data) {
      rowsXml +=
          '''
        <w:tr>
          <w:tc><w:p><w:pPr><w:jc w:val="left"/></w:pPr><w:r><w:t>${_escapeXml(m['fecha'] ?? '')}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:pPr><w:jc w:val="left"/></w:pPr><w:r><w:t>${_escapeXml(m['hora'] ?? '')}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:pPr><w:jc w:val="left"/></w:pPr><w:r><w:t>${_escapeXml(m['asunto'] ?? '')}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:pPr><w:jc w:val="left"/></w:pPr><w:r><w:t>${_escapeXml(m['medio'] ?? '')}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:pPr><w:jc w:val="left"/></w:pPr><w:r><w:t>${_escapeXml(m['anotaciones'] ?? '')}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:t>${(m['imagen'] != null && m['imagen'].toString().isNotEmpty) ? 'Sí' : 'No'}</w:t></w:r></w:p></w:tc>
          <w:tc><w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:t>${(m['adjuntos'] != null && m['adjuntos'].toString().isNotEmpty) ? 'Sí' : 'No'}</w:t></w:r></w:p></w:tc>
        </w:tr>
      ''';
    }

    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    
    <!-- TÍTULO -->
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:before="200" w:after="200"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:b/>
          <w:sz w:val="36"/>
          <w:color w:val="2E5090"/>
        </w:rPr>
        <w:t>REPORTE LIBRO DE INTELIGENCIA</w:t>
      </w:r>
    </w:p>

    <!-- FECHA DE GENERACIÓN -->
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
        <w:spacing w:before="0" w:after="400"/>
      </w:pPr>
      <w:r>
        <w:rPr>
          <w:i/>
          <w:sz w:val="20"/>
        </w:rPr>
        <w:t>Generado: $now</w:t>
      </w:r>
    </w:p>

    <!-- TABLA -->
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="0" w:type="auto"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="4" w:space="0" w:color="000000"/>
          <w:left w:val="single" w:sz="4" w:space="0" w:color="000000"/>
          <w:bottom w:val="single" w:sz="4" w:space="0" w:color="000000"/>
          <w:right w:val="single" w:sz="4" w:space="0" w:color="000000"/>
          <w:insideH w:val="single" w:sz="4" w:space="0" w:color="000000"/>
          <w:insideV w:val="single" w:sz="4" w:space="0" w:color="000000"/>
        </w:tblBorders>
      </w:tblPr>
      
      <!-- ENCABEZADO DE LA TABLA -->
      <w:tr>
        <w:trPr>
           <w:tblHeader/>
        </w:trPr>
        <w:tc>
            <w:tcPr><w:shd w:fill="4F81BD"/><w:tcW w:w="2000" w:type="dxa"/></w:tcPr>
            <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="FFFFFF"/></w:rPr><w:t>Fecha</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
            <w:tcPr><w:shd w:fill="4F81BD"/><w:tcW w:w="1200" w:type="dxa"/></w:tcPr>
            <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="FFFFFF"/></w:rPr><w:t>Hora</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
            <w:tcPr><w:shd w:fill="4F81BD"/><w:tcW w:w="2500" w:type="dxa"/></w:tcPr>
            <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="FFFFFF"/></w:rPr><w:t>Asunto</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
            <w:tcPr><w:shd w:fill="4F81BD"/><w:tcW w:w="2500" w:type="dxa"/></w:tcPr>
            <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="FFFFFF"/></w:rPr><w:t>Medio</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
            <w:tcPr><w:shd w:fill="4F81BD"/><w:tcW w:w="5000" w:type="dxa"/></w:tcPr>
            <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="FFFFFF"/></w:rPr><w:t>Anotaciones</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
            <w:tcPr><w:shd w:fill="4F81BD"/><w:tcW w:w="1000" w:type="dxa"/></w:tcPr>
            <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="FFFFFF"/></w:rPr><w:t>Img</w:t></w:r></w:p>
        </w:tc>
        <w:tc>
            <w:tcPr><w:shd w:fill="4F81BD"/><w:tcW w:w="1000" w:type="dxa"/></w:tcPr>
            <w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:rPr><w:b/><w:color w:val="FFFFFF"/></w:rPr><w:t>Adj</w:t></w:r></w:p>
        </w:tc>
      </w:tr>

      <!-- FILAS DE DATOS -->
      $rowsXml
    </w:tbl>
    
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>''';
  }

  // --- HELPER PARA ESCAPAR CARACTERES XML ---
  static String _escapeXml(String? text) {
    if (text == null) return '';
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // --- DEFINICIONES XML REQUERIDAS POR EL FORMATO DOCX (STANDARD) ---

  static String get _contentTypesXml =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>''';

  static String get _relsXml =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static String get _documentRelsXml =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

  static String get _stylesXml =>
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>
        <w:sz w:val="22"/>
        <w:szCs w:val="22"/>
      </w:rPr>
    </w:rPrDefault>
  </w:docDefaults>
</w:styles>''';
}
