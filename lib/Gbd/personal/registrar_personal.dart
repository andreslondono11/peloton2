import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peloton/BD/data_personal.dart';
import 'package:peloton/Gbd/personal/personal_reg.dart';
import 'package:peloton/BD/db_manager.dart';

class RegistroPersonalScreen extends StatefulWidget {
  final Personal? personal;

  const RegistroPersonalScreen({super.key, this.personal});

  @override
  State<RegistroPersonalScreen> createState() => _RegistroPersonalScreenState();
}

class _RegistroPersonalScreenState extends State<RegistroPersonalScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final _picker = ImagePicker();
  String? _nombreUsuario;

  // --- CONTROLADORES ---
  final _graCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _apeCtrl = TextEditingController();
  final _rhCtrl = TextEditingController();
  final _docCtrl = TextEditingController();
  final _fNacCtrl = TextEditingController();
  final _ciuCtrl = TextEditingController();
  final _paiCtrl = TextEditingController();
  final _dirCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _corCtrl = TextEditingController();
  final _carCtrl = TextEditingController();
  final _fIngCtrl = TextEditingController();
  final _nomPCtrl = TextEditingController();
  final _telPCtrl = TextEditingController();
  final _nomMCtrl = TextEditingController();
  final _telMCtrl = TextEditingController();
  final _nomHCtrl = TextEditingController();
  final _conECtrl = TextEditingController();
  final _telECtrl = TextEditingController();

  String _rh = 'O+';
  String _sexo = 'M';
  String _tDoc = 'CC';
  String _estado = 'Activo';

  @override
  void initState() {
    super.initState();
    if (widget.personal != null) {
      _cargarDatosParaEditar();
    }
    _cargarNombreUsuario();
  }

  // ✅ SOLUCIÓN DEFINITIVA: Sin filtro de mantener_sesion
  Future<void> _cargarNombreUsuario() async {
    try {
      final db =
          await DBManager.instance.authDatabase; // BD Global (tablet_app.db)
      final sesion = await db.query('sesion_activa');

      if (sesion.isNotEmpty) {
        // Tomamos directamente el primer usuario activo, sin validar mantener_sesion
        int usuarioId = sesion.first['usuario_id'] as int;

        final usuario = await db.query(
          'usuarios',
          where: 'id = ?',
          whereArgs: [usuarioId],
          limit: 1,
        );

        if (usuario.isNotEmpty && mounted) {
          setState(() {
            _nombreUsuario = usuario.first['nombres'] as String?;
          });
        } else if (mounted) {
          // Por si acaso el ID existe en sesión pero fue borrado de usuarios
          setState(() => _nombreUsuario = "Error ID");
        }
      } else if (mounted) {
        // Si la tabla está completamente vacía
        setState(() => _nombreUsuario = "Sin sesión");
      }
    } catch (e) {
      print("Error cargando usuario en intendencia: $e");
      if (mounted) setState(() => _nombreUsuario = "Sin sesión");
    }
  }

  void _cargarDatosParaEditar() {
    final p = widget.personal!;
    _graCtrl.text = p.grado;
    _nomCtrl.text = p.nombre;
    _apeCtrl.text = p.apellido;
    _docCtrl.text = p.numeroDocumento;
    _fNacCtrl.text = p.fechaNacimiento;
    _ciuCtrl.text = p.ciudadNacimiento;
    _paiCtrl.text = p.paisNacimiento;
    _dirCtrl.text = p.direccion;
    _telCtrl.text = p.telefono;
    _corCtrl.text = p.correo;
    _carCtrl.text = p.cargo;
    _fIngCtrl.text = p.fechaIngreso;
    _nomPCtrl.text = p.nombrePadre;
    _telPCtrl.text = p.telefonoPadre ?? "";
    _nomMCtrl.text = p.nombreMadre;
    _telMCtrl.text = p.telefonoMadre ?? "";
    _nomHCtrl.text = p.nombreHijo ?? "";
    _conECtrl.text = p.contactoEmergencia;
    _telECtrl.text = p.telefonoEmergencia;

    setState(() {
      _rh = p.rh;
      _sexo = p.sexo;
      _tDoc = p.tipoDocumento;
      _estado = p.estado;
      if (p.fotoPath != null && File(p.fotoPath!).existsSync()) {
        _image = File(p.fotoPath!);
      }
    });
  }

  Future<void> _obtenerImagen(ImageSource source) async {
    Navigator.pop(context);
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> _guardar() async {
    if (_formKey.currentState!.validate()) {
      final p = Personal(
        id: widget.personal?.id,
        grado: _graCtrl.text.toUpperCase(),
        nombre: _nomCtrl.text,
        apellido: _apeCtrl.text,
        rh: _rh,
        tipoDocumento: _tDoc,
        numeroDocumento: _docCtrl.text,
        fechaNacimiento: _fNacCtrl.text,
        ciudadNacimiento: _ciuCtrl.text,
        paisNacimiento: _paiCtrl.text,
        sexo: _sexo,
        direccion: _dirCtrl.text,
        telefono: _telCtrl.text,
        correo: _corCtrl.text,
        cargo: _carCtrl.text,
        fechaIngreso: _fIngCtrl.text,
        estado: _estado,
        fotoPath: _image?.path,
        nombrePadre: _nomPCtrl.text,
        telefonoPadre: _telPCtrl.text,
        nombreMadre: _nomMCtrl.text,
        telefonoMadre: _telMCtrl.text,
        nombreHijo: _nomHCtrl.text,
        contactoEmergencia: _conECtrl.text,
        telefonoEmergencia: _telECtrl.text,
      );

      if (widget.personal == null) {
        await DBPersonal.instance.insertar(p);
      } else {
        await DBPersonal.instance.actualizar(p);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.personal == null ? "✅ Registrado" : "✅ Actualizado",
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryBlue = Color(0xFF1A237E);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.personal == null ? "REGISTRO PERSONAL" : "EDITAR PERFIL",
        ),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    _nombreUsuario != null && _nombreUsuario!.isNotEmpty
                        ? _nombreUsuario![0].toUpperCase()
                        : "?",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _nombreUsuario ?? "Usuario",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildFotoHeader(primaryBlue, isDark),
              const SizedBox(height: 20),

              _buildSeccion("DATOS BÁSICOS", Icons.person, isDark, [
                _buildInput(_graCtrl, "Grado"),
                _buildInput(_nomCtrl, "Nombres"),
                _buildInput(_apeCtrl, "Apellidos"),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        "RH",
                        ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'],
                        _rh,
                        (v) => setState(() => _rh = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdown(
                        "Sexo",
                        ['M', 'F', 'Otro'],
                        _sexo,
                        (v) => setState(() => _sexo = v!),
                      ),
                    ),
                  ],
                ),
                _buildInput(_fNacCtrl, "Fecha de Nacimiento"),
                _buildInput(_ciuCtrl, "Ciudad de Nacimiento"),
                _buildInput(_paiCtrl, "País de Nacimiento"),
                _buildInput(_dirCtrl, "Dirección"),
              ]),

              _buildSeccion("DOCUMENTACIÓN", Icons.badge, isDark, [
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        "Tipo",
                        ['CC', 'TI', 'CE'],
                        _tDoc,
                        (v) => setState(() => _tDoc = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInput(
                        _docCtrl,
                        "Número Cédula",
                        num: true,
                        soloNumeros: true,
                      ),
                    ),
                  ],
                ),
              ]),

              _buildSeccion("CONTACTO Y LABORAL", Icons.contact_mail, isDark, [
                _buildInput(_telCtrl, "Teléfono", num: true),
                _buildInput(_corCtrl, "Correo Electrónico"),
                _buildInput(_carCtrl, "Cargo actual"),
                _buildInput(_fIngCtrl, "Fecha de Ingreso"),
                _buildDropdown(
                  "Estado",
                  ['Activo', 'Retirado', 'Comisión'],
                  _estado,
                  (v) => setState(() => _estado = v!),
                ),
              ]),

              _buildSeccion("FAMILIA Y EMERGENCIA", Icons.emergency, isDark, [
                _buildInput(_nomPCtrl, "Nombre del Padre"),
                _buildInput(_telPCtrl, "Teléfono del Padre", num: true),
                _buildInput(_nomMCtrl, "Nombre de la Madre"),
                _buildInput(_telMCtrl, "Teléfono de la Madre", num: true),
                _buildInput(_nomHCtrl, "Nombre del Hijo(a)"),
                _buildInput(
                  _conECtrl,
                  "Contacto Emergencia",
                  color: isDark ? Colors.red.withOpacity(0.15) : Colors.red[50],
                ),
                _buildInput(
                  _telECtrl,
                  "Tel. Emergencia",
                  num: true,
                  color: isDark ? Colors.red.withOpacity(0.15) : Colors.red[50],
                ),
              ]),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _guardar,
                child: const Text(
                  "GUARDAR CAMBIOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFotoHeader(Color color, bool isDark) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 65,
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300],
            backgroundImage: _image != null ? FileImage(_image!) : null,
            child: _image == null
                ? Icon(
                    Icons.add_a_photo,
                    size: 40,
                    color: isDark ? Colors.grey[400] : Colors.white,
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _seleccionarOrigenImagen,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: color,
                child: const Icon(Icons.edit, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(
    String titulo,
    IconData icono,
    bool isDark,
    List<Widget> campos,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: isDark ? Colors.white : const Color(0xFF1A237E),
        collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
        leading: Icon(
          icono,
          color: isDark ? Colors.blueAccent : const Color(0xFF1A237E),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: campos),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    TextEditingController ctrl,
    String label, {
    bool num = false,
    bool soloNumeros = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: num ? TextInputType.number : TextInputType.text,
        inputFormatters: soloNumeros
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          filled: color != null,
          fillColor: color,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Requerido" : null,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String value,
    Function(String?) onChange,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
        ),
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
        onChanged: onChange,
      ),
    );
  }

  void _seleccionarOrigenImagen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Galería'),
              onTap: () => _obtenerImagen(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => _obtenerImagen(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}
