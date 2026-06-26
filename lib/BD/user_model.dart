class Usuario {
  final int? id;
  final String nombres;
  final String correo;
  final String password;

  Usuario({
    this.id,
    required international,
    required this.nombres,
    required this.correo,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombres': nombres,
      'correo': correo,
      'password': password,
    };
  }
}
