import 'package:sqflite/sqflite.dart';
import 'package:peloton/Gbd/personal/personal_reg.dart';
import 'package:peloton/BD/db_manager.dart';

class DBPersonal {
  static final DBPersonal instance = DBPersonal._init();

  DBPersonal._init();

  // ✅ CONEXIÓN: Obtiene la BD del usuario logueado
  Future<Database> get database async {
    return await DBManager.instance.database;
  }

  // ✅ Insertar recibiendo un Mapa directo (útil para imports o sincronizaciones)
  Future<void> insertarDesdeMapa(Map<String, dynamic> data) async {
    final db = await DBManager.instance.database;
    await db.insert(
      'personal',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
      // Nota: 'replace' reemplaza SI el 'id' ya existe.
      // Si quieres que reemplace basado en la cédula, debes agregar UNIQUE a numero_documento en DBManager.
    );
  }

  // --- MÉTODOS CRUD ---

  // 1. Crear
  Future<int> insertar(Personal p) async {
    final db = await instance.database;
    return await db.insert('personal', p.toMap());
  }

  // 2. Leer (Listar)
  Future<List<Personal>> listar() async {
    final db = await instance.database;
    final res = await db.query('personal', orderBy: 'apellido ASC');

    if (res.isEmpty) return [];

    return res.map((map) => Personal.fromMap(map)).toList();
  }

  // 3. Editar (Actualizar)
  Future<int> actualizar(Personal p) async {
    final db = await instance.database;

    if (p.id == null) return 0;

    return await db.update(
      'personal',
      p.toMap(),
      where: 'id = ?',
      whereArgs: [p.id],
    );
  }

  // 4. Eliminar
  Future<int> eliminar(int id) async {
    final db = await instance.database;
    return await db.delete('personal', where: 'id = ?', whereArgs: [id]);
  }
}
