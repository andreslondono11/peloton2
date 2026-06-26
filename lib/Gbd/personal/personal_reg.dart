class Personal {
  final int? id;
  final String grado, nombre, apellido, rh, tipoDocumento, numeroDocumento;
  final String fechaNacimiento, ciudadNacimiento, paisNacimiento, sexo;
  final String direccion, telefono, correo, cargo, fechaIngreso, estado;
  final String? fotoPath; // Puede ser nulo si no se toma foto
  final String nombrePadre, telefonoPadre, nombreMadre, telefonoMadre;
  final String nombreHijo, contactoEmergencia, telefonoEmergencia;

  Personal({
    this.id,
    required this.grado,
    required this.nombre,
    required this.apellido,
    required this.rh,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.fechaNacimiento,
    required this.ciudadNacimiento,
    required this.paisNacimiento,
    required this.sexo,
    required this.direccion,
    required this.telefono,
    required this.correo,
    required this.cargo,
    required this.fechaIngreso,
    required this.estado,
    this.fotoPath,
    required this.nombrePadre,
    required this.telefonoPadre,
    required this.nombreMadre,
    required this.telefonoMadre,
    required this.nombreHijo,
    required this.contactoEmergencia,
    required this.telefonoEmergencia,
  });

  // Convertir a Mapa para insertar o actualizar en SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'grado': grado,
      'nombre': nombre,
      'apellido': apellido,
      'rh': rh,
      'tipo_documento': tipoDocumento,
      'numero_documento': numeroDocumento, // Nombre correcto de columna
      'fecha_nacimiento': fechaNacimiento,
      'ciudad_nacimiento': ciudadNacimiento,
      'pais_nacimiento': paisNacimiento,
      'sexo': sexo,
      'direccion': direccion,
      'telefono': telefono,
      'correo': correo,
      'cargo': cargo,
      'fecha_ingreso': fechaIngreso,
      'estado': estado,
      'foto_path': fotoPath,
      'nombre_padre': nombrePadre,
      'telefono_padre': telefonoPadre,
      'nombre_madre': nombreMadre,
      'telefono_madre': telefonoMadre,
      'nombre_hijo': nombreHijo,
      'contacto_emergencia': contactoEmergencia,
      'telefono_emergencia': telefonoEmergencia,
    };
  }

  // Factory con validaciones para recuperar datos de la BD
  factory Personal.fromMap(Map<String, dynamic> map) => Personal(
    id: map['id'],
    grado: map['grado']?.toString() ?? "",
    nombre: map['nombre']?.toString() ?? "",
    apellido: map['apellido']?.toString() ?? "",
    rh: map['rh']?.toString() ?? "S/O",
    tipoDocumento: map['tipo_documento']?.toString() ?? "",
    // CORRECCIÓN AQUÍ: Se eliminó el guion bajo extra en 'documento'
    numeroDocumento: map['numero_documento']?.toString() ?? "",
    fechaNacimiento: map['fecha_nacimiento']?.toString() ?? "",
    ciudadNacimiento: map['ciudad_nacimiento']?.toString() ?? "",
    paisNacimiento: map['pais_nacimiento']?.toString() ?? "",
    sexo: map['sexo']?.toString() ?? "",
    direccion: map['direccion']?.toString() ?? "",
    telefono: map['telefono']?.toString() ?? "",
    correo: map['correo']?.toString() ?? "",
    cargo: map['cargo']?.toString() ?? "",
    fechaIngreso: map['fecha_ingreso']?.toString() ?? "",
    estado: map['estado']?.toString() ?? "",
    fotoPath: map['foto_path'],
    nombrePadre: map['nombre_padre']?.toString() ?? "N/A",
    telefonoPadre: map['telefono_padre']?.toString() ?? "N/A",
    nombreMadre: map['nombre_madre']?.toString() ?? "N/A",
    telefonoMadre: map['telefono_madre']?.toString() ?? "N/A",
    nombreHijo: map['nombre_hijo']?.toString() ?? "N/A",
    contactoEmergencia: map['contacto_emergencia']?.toString() ?? "",
    telefonoEmergencia: map['telefono_emergencia']?.toString() ?? "",
  );
}
