// // // import 'dart:async';
// // // import 'package:sqflite/sqflite.dart';
// // // import 'package:path/path.dart';

// // // class DBManager {
// // //   static final DBManager instance = DBManager._init();

// // //   Database? _globalDb;
// // //   Database? _userDb;
// // //   int? _currentUserId;

// // //   DBManager._init();

// // //   int? get currentUserId => _currentUserId;

// // //   Future<Database> get database async {
// // //     if (_userDb != null) return _userDb!;
// // //     if (_globalDb != null) return _globalDb!;
// // //     _globalDb = await _initGlobalDb();
// // //     return _globalDb!;
// // //   }

// // //   Future<Database> get authDatabase async {
// // //     if (_globalDb != null) return _globalDb!;
// // //     _globalDb = await _initGlobalDb();
// // //     return _globalDb!;
// // //   }

// // //   /// Inicializa o cambia la base de datos al usuario especificado.
// // //   /// Versión 13: Corrige columnas faltantes en intendencia (grado, cintela).
// // //   Future<void> initUserSession(int userId) async {
// // //     _currentUserId = userId;
// // //     final dbPath = await getDatabasesPath();
// // //     final path = join(dbPath, 'calipso_user_$userId.db');

// // //     if (_userDb != null) {
// // //       await _userDb!.close();
// // //       _userDb = null;
// // //     }

// // //     _userDb = await openDatabase(
// // //       path,
// // //       version: 13, // ---> ACTUALIZADO A V13
// // //       onCreate: (db, version) async {
// // //         await _createDataTables(db);
// // //       },
// // //       onUpgrade: (db, oldVersion, newVersion) async {
// // //         // --- Migraciones Progresivas ---

// // //         final tables = await db.rawQuery(
// // //           "SELECT name FROM sqlite_master WHERE type='table' AND name='minutas'",
// // //         );
// // //         if (tables.isEmpty) {
// // //           await db.execute(
// // //             'CREATE TABLE minutas (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT)',
// // //           );
// // //         }

// // //         if (oldVersion < 2) await _createDataTables(db);
// // //         if (oldVersion < 3) await _createDataTables(db);

// // //         if (oldVersion < 4) {
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE inteligencia ADD COLUMN imagen TEXT",
// // //           );
// // //         }
// // //         if (oldVersion < 5) {
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE inteligencia ADD COLUMN adjuntos TEXT",
// // //           );
// // //         }
// // //         if (oldVersion < 6) {
// // //           await _createDataTables(db);
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE inteligencia ADD COLUMN imagen TEXT",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE inteligencia ADD COLUMN adjuntos TEXT",
// // //           );
// // //         }
// // //         if (oldVersion < 7) {
// // //           await _createDataTables(db);
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE operacional ADD COLUMN imagen TEXT",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE operacional ADD COLUMN adjuntos TEXT",
// // //           );
// // //         }

// // //         // Versión 8: Alineación 'grd'
// // //         if (oldVersion < 8) {
// // //           await _createDataTables(db);
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE inventario_armamento ADD COLUMN grd TEXT",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE inventario_especial ADD COLUMN grd TEXT",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE comunicaciones ADD COLUMN grd TEXT",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE expediente ADD COLUMN grd TEXT",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE inventario_miras ADD COLUMN grd TEXT",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE intendencia ADD COLUMN grd TEXT",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE armamento ADD COLUMN observaciones TEXT",
// // //           );
// // //         }

// // //         // Versión 9: Agregar tabla 'exde'
// // //         if (oldVersion < 9) {
// // //           await _createDataTables(db);
// // //         }

// // //         // Versión 10: Corrección 'impronta' en inventario_miras
// // //         if (oldVersion < 10) {
// // //           await _createDataTables(db);
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE inventario_miras ADD COLUMN impronta_mira_nimrod TEXT",
// // //           );
// // //         }

// // //         // Versión 11: Corrige el error de 'gdo' en comunicaciones
// // //         if (oldVersion < 11) {
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE comunicaciones ADD COLUMN gdo TEXT",
// // //           );
// // //         }

// // //         // Versión 12: Corrige columnas en inventario_miras
// // //         if (oldVersion < 12) {
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE inventario_miras ADD COLUMN numero_avn TEXT",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE inventario_miras ADD COLUMN numero_miras_mor TEXT",
// // //           );
// // //         }

// // //         // ---> VERSIÓN 13 NUEVA: Corrige columnas mal nombradas en la pantalla de intendencia
// // //         if (oldVersion < 13) {
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE intendencia ADD COLUMN grado TEXT",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE intendencia ADD COLUMN cintela INTEGER DEFAULT 0",
// // //           );
// // //         }
// // //       },
// // //     );
// // //   }

// // //   Future<void> closeUserSession() async {
// // //     if (_userDb != null) {
// // //       await _userDb!.close();
// // //       _userDb = null;
// // //       _currentUserId = null;
// // //     }
// // //   }

// // //   // ========================================================================
// // //   // NUEVO MÉTODO: Limpia toda la memoria de bases de datos antes de restaurar
// // //   // ========================================================================
// // //   Future<void> fullReset() async {
// // //     if (_userDb != null) {
// // //       await _userDb!.close();
// // //       _userDb = null;
// // //     }
// // //     if (_globalDb != null) {
// // //       await _globalDb!.close();
// // //       _globalDb = null;
// // //     }
// // //     _currentUserId = null;
// // //   }

// // //   Future<Database> _initGlobalDb() async {
// // //     final dbPath = await getDatabasesPath();
// // //     final path = join(dbPath, 'tablet_app.db');

// // //     return await openDatabase(
// // //       path,
// // //       version: 35,
// // //       onCreate: (db, version) async {
// // //         await _createAuthTables(db);
// // //       },
// // //       onUpgrade: (db, oldVersion, newVersion) async {
// // //         if (oldVersion < 32) {
// // //           await _ejecutarSeguro(
// // //             db,
// // //             "ALTER TABLE usuarios ADD COLUMN estado TEXT DEFAULT 'activo'",
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             'ALTER TABLE usuarios ADD COLUMN fecha_creacion TEXT',
// // //           );
// // //           await _ejecutarSeguro(
// // //             db,
// // //             'ALTER TABLE sesion_activa ADD COLUMN usar_huella INTEGER DEFAULT 0',
// // //           );
// // //         }
// // //         if (oldVersion < 35) {
// // //           print("Actualizando DB Global a v35...");
// // //         }
// // //       },
// // //     );
// // //   }

// // //   Future _createAuthTables(Database db) async {
// // //     await db.execute('''
// // //       CREATE TABLE IF NOT EXISTS usuarios (
// // //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// // //         nombres TEXT NOT NULL,
// // //         correo TEXT,
// // //         password TEXT NOT NULL,
// // //         rol TEXT DEFAULT 'usuario',
// // //         estado TEXT DEFAULT 'activo',
// // //         fecha_creacion TEXT,
// // //         ultimo_acceso TEXT
// // //       )
// // //     ''');

// // //     await db.execute('''
// // //       CREATE TABLE IF NOT EXISTS sesion_activa (
// // //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// // //         usuario_id INTEGER,
// // //         mantener_sesion INTEGER DEFAULT 0,
// // //         usar_huella INTEGER DEFAULT 0,
// // //         FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
// // //       )
// // //     ''');
// // //   }

// // //   Future _createDataTables(Database db) async {
// // //     // 1. MINUTAS
// // //     await db.execute(
// // //       'CREATE TABLE IF NOT EXISTS minutas (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT)',
// // //     );

// // //     // 2. INTELIGENCIA
// // //     await db.execute(
// // //       'CREATE TABLE IF NOT EXISTS inteligencia (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, medio TEXT, anotaciones TEXT, imagen TEXT, adjuntos TEXT)',
// // //     );

// // //     // 3. OPERACIONAL
// // //     await db.execute(
// // //       'CREATE TABLE IF NOT EXISTS operacional (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT, imagen TEXT, adjuntos TEXT)',
// // //     );

// // //     // 4. ARMAMENTO (PARTE GENERAL)
// // //     await db.execute(
// // //       'CREATE TABLE IF NOT EXISTS armamento (id INTEGER PRIMARY KEY AUTOINCREMENT, clase TEXT NOT NULL UNIQUE, cargo INTEGER DEFAULT 0, mano INTEGER DEFAULT 0, deposito INTEGER DEFAULT 0, total INTEGER DEFAULT 0, observaciones TEXT)',
// // //     );

// // //     // 5. INVENTARIO_ARMAMENTO
// // //     await db.execute('''
// // //       CREATE TABLE IF NOT EXISTS inventario_armamento (
// // //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// // //         categoria TEXT,
// // //         grd TEXT,
// // //         apellidos_nombres TEXT,
// // //         n_arma TEXT,
// // //         municion_556 INTEGER DEFAULT 0,
// // //         proveedores_556 INTEGER DEFAULT 0,
// // //         municion_esl_556 INTEGER DEFAULT 0,
// // //         municion_esl_762 INTEGER DEFAULT 0,
// // //         canon INTEGER DEFAULT 0,
// // //         granada_mano INTEGER DEFAULT 0,
// // //         granada_60 INTEGER DEFAULT 0,
// // //         granada_humo INTEGER DEFAULT 0,
// // //         bengalas INTEGER DEFAULT 0,
// // //         granada_lacrimogena INTEGER DEFAULT 0,
// // //         trampa_iluminacion INTEGER DEFAULT 0,
// // //         granada_aturdidora INTEGER DEFAULT 0,
// // //         porta_arma INTEGER DEFAULT 0,
// // //         casco INTEGER DEFAULT 0,
// // //         foto_patrimonio TEXT,
// // //         observaciones TEXT
// // //       )
// // //     ''');

// // //     // 6. COMUNICACIONES
// // //     await db.execute('''
// // //       CREATE TABLE IF NOT EXISTS comunicaciones (
// // //         id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, gdo TEXT, nombres TEXT, clase_radio TEXT, no_radio TEXT,
// // //         antena_tubular INTEGER DEFAULT 0, antena_latigo INTEGER DEFAULT 0, arnes INTEGER DEFAULT 0, microtelefono INTEGER DEFAULT 0,
// // //         bolso INTEGER DEFAULT 0, base_antena INTEGER DEFAULT 0, tapa_baterias INTEGER DEFAULT 0, base_latigo INTEGER DEFAULT 0,
// // //         base_tubular INTEGER DEFAULT 0, antena_flexible INTEGER DEFAULT 0, baterias INTEGER DEFAULT 0, perillas INTEGER DEFAULT 0,
// // //         cargador INTEGER DEFAULT 0, protector INTEGER DEFAULT 0, clip INTEGER DEFAULT 0, antena_gps INTEGER DEFAULT 0,
// // //         cargador_apx INTEGER DEFAULT 0, antena_gps_5602 INTEGER DEFAULT 0, chaleco INTEGER DEFAULT 0, paneles INTEGER DEFAULT 0,
// // //         gps_garmin INTEGER DEFAULT 0, flecher INTEGER DEFAULT 0, observaciones TEXT
// // //       )
// // //     ''');

// // //     // 7. EXPEDIENTE
// // //     await db.execute('''
// // //       CREATE TABLE IF NOT EXISTS expediente (
// // //         id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, nombres TEXT, n_elemento TEXT,
// // //         canino INTEGER DEFAULT 0, valium INTEGER DEFAULT 0, ecaex INTEGER DEFAULT 0, tubo_pvc INTEGER DEFAULT 0,
// // //         tubo_metalico INTEGER DEFAULT 0, guindo_20m INTEGER DEFAULT 0, cuerda_50m INTEGER DEFAULT 0, gancho_3puntas INTEGER DEFAULT 0,
// // //         boca_pato INTEGER DEFAULT 0, estuche_verde INTEGER DEFAULT 0, perla INTEGER DEFAULT 0, bolso_transporte INTEGER DEFAULT 0,
// // //         auriculares INTEGER DEFAULT 0, tes_prueba INTEGER DEFAULT 0, unidad_electrica INTEGER DEFAULT 0, cabeza_busqueda INTEGER DEFAULT 0,
// // //         pinzas_sog INTEGER DEFAULT 0, cargas_huecas INTEGER DEFAULT 0, pentolita_1kg INTEGER DEFAULT 0, pentolita_1_2kg INTEGER DEFAULT 0,
// // //         pentolita_1_4kg INTEGER DEFAULT 0, mecha_lenta INTEGER DEFAULT 0, cordon_12gr INTEGER DEFAULT 0,
// // //         detonador_comun INTEGER DEFAULT 0, cordon_6gr INTEGER DEFAULT 0, cordon_3gr INTEGER DEFAULT 0, detonadores_electric INTEGER DEFAULT 0,
// // //         detonadores_inelectric INTEGER DEFAULT 0, observacion TEXT
// // //       )
// // //     ''');

// // //     // 8. INVENTARIO_ESPECIAL
// // //     await db.execute('''
// // //       CREATE TABLE IF NOT EXISTS inventario_especial (
// // //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// // //         categoria TEXT,
// // //         grd TEXT,
// // //         apellidos_nombres TEXT,
// // //         n_arma TEXT,
// // //         m_762_eslb INTEGER DEFAULT 0,
// // //         m_556_eslb INTEGER DEFAULT 0,
// // //         m_762_sub INTEGER DEFAULT 0,
// // //         m_9mm INTEGER DEFAULT 0,
// // //         g_im26 INTEGER DEFAULT 0,
// // //         g_humo INTEGER DEFAULT 0,
// // //         g_40mm INTEGER DEFAULT 0,
// // //         g_lacrimogena INTEGER DEFAULT 0,
// // //         canon INTEGER DEFAULT 0,
// // //         trampa_ilu INTEGER DEFAULT 0,
// // //         casco_kevlar INTEGER DEFAULT 0,
// // //         lentes INTEGER DEFAULT 0,
// // //         prov_762 INTEGER DEFAULT 0,
// // //         prov_9mm INTEGER DEFAULT 0,
// // //         porta_arma INTEGER DEFAULT 0,
// // //         supresor INTEGER DEFAULT 0,
// // //         foto_path TEXT
// // //       )
// // //     ''');

// // //     // 9. INVENTARIO_MIRAS
// // //     await db.execute('''
// // //       CREATE TABLE IF NOT EXISTS inventario_miras (
// // //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// // //         grd TEXT,
// // //         apellidos_nombres TEXT,
// // //         numero_avenida TEXT,
// // //         numero_avn TEXT,
// // //         numero_mira_mor TEXT,
// // //         numero_miras_mor TEXT,
// // //         numero_mira_nimrod TEXT,
// // //         impronta_mira_nimrod TEXT,
// // //         foto_path TEXT
// // //       )
// // //     ''');

// // //     // 10. INTENDENCIA (Actualizado con 'grado' y 'cintela')
// // //     await db.execute('''
// // //       CREATE TABLE IF NOT EXISTS intendencia (
// // //         id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, grado TEXT, apellidos_nombres TEXT,
// // //         camuflado_1 TEXT, camuflado_2 TEXT, equipo_campana INTEGER DEFAULT 0, botas_par INTEGER DEFAULT 0,
// // //         camisetas_verdes INTEGER DEFAULT 0, medias_negras INTEGER DEFAULT 0, marmita INTEGER DEFAULT 0,
// // //         hamaca INTEGER DEFAULT 0, poncho_pixelado INTEGER DEFAULT 0, cintura INTEGER DEFAULT 0, cintela INTEGER DEFAULT 0, colchoneta INTEGER DEFAULT 0,
// // //         estuche_jarro_cantimplora INTEGER DEFAULT 0, boxer INTEGER DEFAULT 0, toalla_verde INTEGER DEFAULT 0,
// // //         foto_path TEXT, observaciones TEXT
// // //       )
// // //     ''');

// // //     // 11. PERSONAL
// // //     await db.execute('''
// // //       CREATE TABLE IF NOT EXISTS personal (
// // //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// // //         grado TEXT,
// // //         nombre TEXT,
// // //         apellido TEXT,
// // //         rh TEXT,
// // //         tipo_documento TEXT,
// // //         numero_documento TEXT,
// // //         fecha_nacimiento TEXT,
// // //         ciudad_nacimiento TEXT,
// // //         pais_nacimiento TEXT,
// // //         sexo TEXT,
// // //         direccion TEXT,
// // //         telefono TEXT,
// // //         correo TEXT,
// // //         cargo TEXT,
// // //         fecha_ingreso TEXT,
// // //         estado TEXT,
// // //         foto_path TEXT,
// // //         nombre_padre TEXT,
// // //         telefono_padre TEXT,
// // //         nombre_madre TEXT,
// // //         telefono_madre TEXT,
// // //         nombre_hijo TEXT,
// // //         contacto_emergencia TEXT,
// // //         telefono_emergencia TEXT
// // //       )
// // //     ''');

// // //     // 12. TABLA 'EXDE'
// // //     await db.execute('''
// // //       CREATE TABLE IF NOT EXISTS exde (
// // //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// // //         no INTEGER,
// // //         grd TEXT,
// // //         nombres TEXT,
// // //         n_elemento TEXT,
// // //         canino INTEGER DEFAULT 0,
// // //         valom INTEGER DEFAULT 0,
// // //         ecaex INTEGER DEFAULT 0,
// // //         tubo_pvc INTEGER DEFAULT 0,
// // //         tubo_metalico INTEGER DEFAULT 0,
// // //         guindo_20m INTEGER DEFAULT 0,
// // //         cuerda_50m INTEGER DEFAULT 0,
// // //         gancho_3puntas INTEGER DEFAULT 0,
// // //         boca_pato INTEGER DEFAULT 0,
// // //         estuche_verde INTEGER DEFAULT 0,
// // //         pera INTEGER DEFAULT 0,
// // //         bolso_transporte INTEGER DEFAULT 0,
// // //         auriculares INTEGER DEFAULT 0,
// // //         tes_prueba INTEGER DEFAULT 0,
// // //         unidad_electrica INTEGER DEFAULT 0,
// // //         cabeza_busqueda INTEGER DEFAULT 0,
// // //         pinzas_sog INTEGER DEFAULT 0,
// // //         cargas_huecas INTEGER DEFAULT 0,
// // //         pentolita_1kg INTEGER DEFAULT 0,
// // //         pentolita_1_2kg INTEGER DEFAULT 0,
// // //         pentolita_1_4kg INTEGER DEFAULT 0,
// // //         pentolita_1_8kg INTEGER DEFAULT 0,
// // //         mecha_lenta INTEGER DEFAULT 0,
// // //         cordon_12gr INTEGER DEFAULT 0,
// // //         detonador_comun INTEGER DEFAULT 0,
// // //         cordon_6gr INTEGER DEFAULT 0,
// // //         cordon_3gr INTEGER DEFAULT 0,
// // //         detonadores_elec INTEGER DEFAULT 0,
// // //         detonadores_inelec INTEGER DEFAULT 0,
// // //         observacion TEXT
// // //       )
// // //     ''');
// // //   }

// // //   Future<void> _ejecutarSeguro(Database db, String sql) async {
// // //     try {
// // //       await db.execute(sql);
// // //     } catch (e) {
// // //       print("Info SQL (ignorado si existe): $e");
// // //     }
// // //   }
// // // }

// // import 'dart:async';
// // import 'dart:io';
// // import 'package:sqflite/sqflite.dart';
// // import 'package:path/path.dart';

// // class DBManager {
// //   static final DBManager instance = DBManager._init();

// //   Database? _globalDb;
// //   Database? _userDb;
// //   int? _currentUserId;

// //   DBManager._init();

// //   int? get currentUserId => _currentUserId;

// //   // --- CORRECCIÓN 1: Getter de base de datos general ---
// //   // Ahora sabe exactamente cuál devolver según si hay sesión o no.
// //   Future<Database> get database async {
// //     if (_userDb != null && _currentUserId != null) return _userDb!;
// //     if (_globalDb != null) return _globalDb!;
// //     _globalDb = await _initGlobalDb();
// //     return _globalDb!;
// //   }

// //   Future<Database> get authDatabase async {
// //     if (_globalDb != null) return _globalDb!;
// //     _globalDb = await _initGlobalDb();
// //     return _globalDb!;
// //   }

// //   /// Inicializa o cambia la base de datos al usuario especificado.
// //   Future<void> initUserSession(int userId) async {
// //     _currentUserId = userId;
// //     final dbPath = await getDatabasesPath();
// //     final path = join(dbPath, 'calipso_user_$userId.db');

// //     if (_userDb != null) {
// //       await _userDb!.close();
// //       _userDb = null; // Limpiar memoria
// //     }

// //     _userDb = await openDatabase(
// //       path,
// //       version: 13,
// //       onCreate: (db, version) async {
// //         await _createDataTables(db);
// //       },
// //       onUpgrade: (db, oldVersion, newVersion) async {
// //         final tables = await db.rawQuery(
// //           "SELECT name FROM sqlite_master WHERE type='table' AND name='minutas'",
// //         );
// //         if (tables.isEmpty) {
// //           await db.execute(
// //             'CREATE TABLE minutas (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT)',
// //           );
// //         }

// //         if (oldVersion < 2) await _createDataTables(db);
// //         if (oldVersion < 3) await _createDataTables(db);

// //         if (oldVersion < 4) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inteligencia ADD COLUMN imagen TEXT",
// //           );
// //         }
// //         if (oldVersion < 5) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inteligencia ADD COLUMN adjuntos TEXT",
// //           );
// //         }
// //         if (oldVersion < 6) {
// //           await _createDataTables(db);
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inteligencia ADD COLUMN imagen TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inteligencia ADD COLUMN adjuntos TEXT",
// //           );
// //         }
// //         if (oldVersion < 7) {
// //           await _createDataTables(db);
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE operacional ADD COLUMN imagen TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE operacional ADD COLUMN adjuntos TEXT",
// //           );
// //         }
// //         if (oldVersion < 8) {
// //           await _createDataTables(db);
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_armamento ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_especial ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE comunicaciones ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE expediente ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_miras ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE intendencia ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE armamento ADD COLUMN observaciones TEXT",
// //           );
// //         }
// //         if (oldVersion < 9) {
// //           await _createDataTables(db);
// //         }
// //         if (oldVersion < 10) {
// //           await _createDataTables(db);
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_miras ADD COLUMN impronta_mira_nimrod TEXT",
// //           );
// //         }
// //         if (oldVersion < 11) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE comunicaciones ADD COLUMN gdo TEXT",
// //           );
// //         }
// //         if (oldVersion < 12) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_miras ADD COLUMN numero_avn TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_miras ADD COLUMN numero_miras_mor TEXT",
// //           );
// //         }
// //         if (oldVersion < 13) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE intendencia ADD COLUMN grado TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE intendencia ADD COLUMN cintela INTEGER DEFAULT 0",
// //           );
// //         }
// //       },
// //     );
// //   }

// //   Future<void> closeUserSession() async {
// //     if (_userDb != null) {
// //       await _userDb!.close();
// //       _userDb = null;
// //       _currentUserId = null;
// //     }
// //   }

// //   // --- CORRECCIÓN 2: fullReset mejorado ---
// //   Future<void> fullReset() async {
// //     if (_userDb != null) {
// //       await _userDb!.close();
// //       _userDb = null;
// //     }
// //     if (_globalDb != null) {
// //       await _globalDb!.close();
// //       _globalDb = null;
// //     }
// //     _currentUserId = null;
// //   }

// //   // =========================================================================
// //   // --- NUEVA FUNCIÓN MÁGICA PARA RESTAURAR BACKUPS SIN ERRORES ---
// //   // =========================================================================
// //   /// Debes llamar a ESTA función cuando quieras restaurar un archivo .db
// //   Future<void> restaurarBackup(File backupFile) async {
// //     // 1. Matamos cualquier conexión abierta en memoria
// //     await fullReset();

// //     // 2. Determinamos a dónde va el backup (Global o de Usuario)
// //     String pathDestino;
// //     if (_currentUserId != null) {
// //       final dbPath = await getDatabasesPath();
// //       pathDestino = join(dbPath, 'calipso_user_$_currentUserId.db');
// //     } else {
// //       final dbPath = await getDatabasesPath();
// //       pathDestino = join(dbPath, 'tablet_app.db');
// //     }

// //     // 3. Sobrescribimos el archivo físico en el disco
// //     // Si el archivo ya existe, lo borramos para evitar conflictos de permisos
// //     if (await File(pathDestino).exists()) {
// //       await File(pathDestino).delete();
// //     }
// //     await backupFile.copy(pathDestino);

// //     // 4. ¡CRUCIAL! Forzamos a que el get database vuelva a abrir el archivo NUEVO
// //     // No llamamos a openDatabase aquí, dejamos que el getter lo haga cuando se necesite
// //     print("Backup restaurado correctamente en: $pathDestino");
// //   }

// //   // =========================================================================
// //   // --- NUEVA FUNCIÓN: "Hacer ejercito" (Limpiar tablas de forma segura) ---
// //   // =========================================================================
// //   /// Usa esto en vez de DROP TABLE. Borra los datos pero mantiene la tabla viva.
// //   Future<void> limpiarTabla(String nombreTabla) async {
// //     final db = await database;
// //     try {
// //       await db.delete(nombreTabla);
// //       print("Tabla $nombreTabla limpiada correctamente.");
// //     } catch (e) {
// //       print("Error al limpiar $nombreTabla: $e");
// //     }
// //   }

// //   /// Si quieres limpiar TODAS las tablas de golpe
// //   Future<void> limpiarTodaLaData() async {
// //     final db = await database;
// //     final tablas = [
// //       'minutas',
// //       'inteligencia',
// //       'operacional',
// //       'armamento',
// //       'inventario_armamento',
// //       'comunicaciones',
// //       'expediente',
// //       'inventario_especial',
// //       'inventario_miras',
// //       'intendencia',
// //       'personal',
// //       'exde',
// //     ];

// //     for (var tabla in tablas) {
// //       try {
// //         await db.delete(tabla);
// //       } catch (e) {
// //         // Ignorar si la tabla no existe por alguna razón
// //       }
// //     }
// //     print("Ejercito completado: Todas las tablas fueron vaciadas.");
// //   }

// //   Future<Database> _initGlobalDb() async {
// //     final dbPath = await getDatabasesPath();
// //     final path = join(dbPath, 'tablet_app.db');

// //     return await openDatabase(
// //       path,
// //       version: 35,
// //       onCreate: (db, version) async {
// //         await _createAuthTables(db);
// //       },
// //       onUpgrade: (db, oldVersion, newVersion) async {
// //         if (oldVersion < 32) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE usuarios ADD COLUMN estado TEXT DEFAULT 'activo'",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             'ALTER TABLE usuarios ADD COLUMN fecha_creacion TEXT',
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             'ALTER TABLE sesion_activa ADD COLUMN usar_huella INTEGER DEFAULT 0',
// //           );
// //         }
// //         if (oldVersion < 35) {
// //           print("Actualizando DB Global a v35...");
// //         }
// //       },
// //     );
// //   }

// //   Future _createAuthTables(Database db) async {
// //     await db.execute('''
// //       CREATE TABLE IF NOT EXISTS usuarios (
// //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// //         nombres TEXT NOT NULL,
// //         correo TEXT,
// //         password TEXT NOT NULL,
// //         rol TEXT DEFAULT 'usuario',
// //         estado TEXT DEFAULT 'activo',
// //         fecha_creacion TEXT,
// //         ultimo_acceso TEXT
// //       )
// //     ''');

// //     await db.execute('''
// //       CREATE TABLE IF NOT EXISTS sesion_activa (
// //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// //         usuario_id INTEGER,
// //         mantener_sesion INTEGER DEFAULT 0,
// //         usar_huella INTEGER DEFAULT 0,
// //         FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
// //       )
// //     ''');
// //   }

// //   Future _createDataTables(Database db) async {
// //     await db.execute(
// //       'CREATE TABLE IF NOT EXISTS minutas (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT)',
// //     );
// //     await db.execute(
// //       'CREATE TABLE IF NOT EXISTS inteligencia (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, medio TEXT, anotaciones TEXT, imagen TEXT, adjuntos TEXT)',
// //     );
// //     await db.execute(
// //       'CREATE TABLE IF NOT EXISTS operacional (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT, imagen TEXT, adjuntos TEXT)',
// //     );
// //     await db.execute(
// //       'CREATE TABLE IF NOT EXISTS armamento (id INTEGER PRIMARY KEY AUTOINCREMENT, clase TEXT NOT NULL UNIQUE, cargo INTEGER DEFAULT 0, mano INTEGER DEFAULT 0, deposito INTEGER DEFAULT 0, total INTEGER DEFAULT 0, observaciones TEXT)',
// //     );

// //     await db.execute(
// //       '''CREATE TABLE IF NOT EXISTS inventario_armamento (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, categoria TEXT, grd TEXT, apellidos_nombres TEXT, n_arma TEXT,
// //       municion_556 INTEGER DEFAULT 0, proveedores_556 INTEGER DEFAULT 0, municion_esl_556 INTEGER DEFAULT 0,
// //       municion_esl_762 INTEGER DEFAULT 0, canon INTEGER DEFAULT 0, granada_mano INTEGER DEFAULT 0,
// //       granada_60 INTEGER DEFAULT 0, granada_humo INTEGER DEFAULT 0, bengalas INTEGER DEFAULT 0,
// //       granada_lacrimogena INTEGER DEFAULT 0, trampa_iluminacion INTEGER DEFAULT 0, granada_aturdidora INTEGER DEFAULT 0,
// //       porta_arma INTEGER DEFAULT 0, casco INTEGER DEFAULT 0, foto_patrimonio TEXT, observaciones TEXT)''',
// //     );

// //     await db.execute(
// //       '''CREATE TABLE IF NOT EXISTS comunicaciones (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, gdo TEXT, nombres TEXT, clase_radio TEXT, no_radio TEXT,
// //       antena_tubular INTEGER DEFAULT 0, antena_latigo INTEGER DEFAULT 0, arnes INTEGER DEFAULT 0, microtelefono INTEGER DEFAULT 0,
// //       bolso INTEGER DEFAULT 0, base_antena INTEGER DEFAULT 0, tapa_baterias INTEGER DEFAULT 0, base_latigo INTEGER DEFAULT 0,
// //       base_tubular INTEGER DEFAULT 0, antena_flexible INTEGER DEFAULT 0, baterias INTEGER DEFAULT 0, perillas INTEGER DEFAULT 0,
// //       cargador INTEGER DEFAULT 0, protector INTEGER DEFAULT 0, clip INTEGER DEFAULT 0, antena_gps INTEGER DEFAULT 0,
// //       cargador_apx INTEGER DEFAULT 0, antena_gps_5602 INTEGER DEFAULT 0, chaleco INTEGER DEFAULT 0, paneles INTEGER DEFAULT 0,
// //       gps_garmin INTEGER DEFAULT 0, flecher INTEGER DEFAULT 0, observaciones TEXT)''',
// //     );

// //     await db.execute('''CREATE TABLE IF NOT EXISTS expediente (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, nombres TEXT, n_elemento TEXT,
// //       canino INTEGER DEFAULT 0, valium INTEGER DEFAULT 0, ecaex INTEGER DEFAULT 0, tubo_pvc INTEGER DEFAULT 0,
// //       tubo_metalico INTEGER DEFAULT 0, guindo_20m INTEGER DEFAULT 0, cuerda_50m INTEGER DEFAULT 0, gancho_3puntas INTEGER DEFAULT 0,
// //       boca_pato INTEGER DEFAULT 0, estuche_verde INTEGER DEFAULT 0, perla INTEGER DEFAULT 0, bolso_transporte INTEGER DEFAULT 0,
// //       auriculares INTEGER DEFAULT 0, tes_prueba INTEGER DEFAULT 0, unidad_electrica INTEGER DEFAULT 0, cabeza_busqueda INTEGER DEFAULT 0,
// //       pinzas_sog INTEGER DEFAULT 0, cargas_huecas INTEGER DEFAULT 0, pentolita_1kg INTEGER DEFAULT 0, pentolita_1_2kg INTEGER DEFAULT 0,
// //       pentolita_1_4kg INTEGER DEFAULT 0, mecha_lenta INTEGER DEFAULT 0, cordon_12gr INTEGER DEFAULT 0,
// //       detonador_comun INTEGER DEFAULT 0, cordon_6gr INTEGER DEFAULT 0, cordon_3gr INTEGER DEFAULT 0, detonadores_electric INTEGER DEFAULT 0,
// //       detonadores_inelectric INTEGER DEFAULT 0, observacion TEXT)''');

// //     await db.execute('''CREATE TABLE IF NOT EXISTS inventario_especial (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, categoria TEXT, grd TEXT, apellidos_nombres TEXT, n_arma TEXT,
// //       m_762_eslb INTEGER DEFAULT 0, m_556_eslb INTEGER DEFAULT 0, m_762_sub INTEGER DEFAULT 0,
// //       m_9mm INTEGER DEFAULT 0, g_im26 INTEGER DEFAULT 0, g_humo INTEGER DEFAULT 0, g_40mm INTEGER DEFAULT 0,
// //       g_lacrimogena INTEGER DEFAULT 0, canon INTEGER DEFAULT 0, trampa_ilu INTEGER DEFAULT 0, casco_kevlar INTEGER DEFAULT 0,
// //       lentes INTEGER DEFAULT 0, prov_762 INTEGER DEFAULT 0, prov_9mm INTEGER DEFAULT 0, porta_arma INTEGER DEFAULT 0,
// //       supresor INTEGER DEFAULT 0, foto_path TEXT)''');

// //     await db.execute('''CREATE TABLE IF NOT EXISTS inventario_miras (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, grd TEXT, apellidos_nombres TEXT, numero_avenida TEXT,
// //       numero_avn TEXT, numero_mira_mor TEXT, numero_miras_mor TEXT,
// //       numero_mira_nimrod TEXT, impronta_mira_nimrod TEXT, foto_path TEXT)''');

// //     await db.execute('''CREATE TABLE IF NOT EXISTS intendencia (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, grado TEXT, apellidos_nombres TEXT,
// //       camuflado_1 TEXT, camuflado_2 TEXT, equipo_campana INTEGER DEFAULT 0, botas_par INTEGER DEFAULT 0,
// //       camisetas_verdes INTEGER DEFAULT 0, medias_negras INTEGER DEFAULT 0, marmita INTEGER DEFAULT 0,
// //       hamaca INTEGER DEFAULT 0, poncho_pixelado INTEGER DEFAULT 0, cintura INTEGER DEFAULT 0, cintela INTEGER DEFAULT 0, colchoneta INTEGER DEFAULT 0,
// //       estuche_jarro_cantimplora INTEGER DEFAULT 0, boxer INTEGER DEFAULT 0, toalla_verde INTEGER DEFAULT 0,
// //       foto_path TEXT, observaciones TEXT)''');

// //     await db.execute(
// //       '''CREATE TABLE IF NOT EXISTS personal (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, grado TEXT, nombre TEXT, apellido TEXT, rh TEXT,
// //       tipo_documento TEXT, numero_documento TEXT, fecha_nacimiento TEXT, ciudad_nacimiento TEXT,
// //       pais_nacimiento TEXT, sexo TEXT, direccion TEXT, telefono TEXT, correo TEXT, cargo TEXT,
// //       fecha_ingreso TEXT, estado TEXT, foto_path TEXT, nombre_padre TEXT, telefono_padre TEXT,
// //       nombre_madre TEXT, telefono_madre TEXT, nombre_hijo TEXT, contacto_emergencia TEXT, telefono_emergencia TEXT)''',
// //     );

// //     await db.execute('''CREATE TABLE IF NOT EXISTS exde (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, nombres TEXT, n_elemento TEXT,
// //       canino INTEGER DEFAULT 0, valom INTEGER DEFAULT 0, ecaex INTEGER DEFAULT 0, tubo_pvc INTEGER DEFAULT 0,
// //       tubo_metalico INTEGER DEFAULT 0, guindo_20m INTEGER DEFAULT 0, cuerda_50m INTEGER DEFAULT 0, gancho_3puntas INTEGER DEFAULT 0,
// //       boca_pato INTEGER DEFAULT 0, estuche_verde INTEGER DEFAULT 0, pera INTEGER DEFAULT 0, bolso_transporte INTEGER DEFAULT 0,
// //       auriculares INTEGER DEFAULT 0, tes_prueba INTEGER DEFAULT 0, unidad_electrica INTEGER DEFAULT 0, cabeza_busqueda INTEGER DEFAULT 0,
// //       pinzas_sog INTEGER DEFAULT 0, cargas_huecas INTEGER DEFAULT 0, pentolita_1kg INTEGER DEFAULT 0, pentolita_1_2kg INTEGER DEFAULT 0,
// //       pentolita_1_4kg INTEGER DEFAULT 0, pentolita_1_8kg INTEGER DEFAULT 0, mecha_lenta INTEGER DEFAULT 0, cordon_12gr INTEGER DEFAULT 0,
// //       detonador_comun INTEGER DEFAULT 0, cordon_6gr INTEGER DEFAULT 0, cordon_3gr INTEGER DEFAULT 0, detonadores_elec INTEGER DEFAULT 0,
// //       detonadores_inelec INTEGER DEFAULT 0, observacion TEXT)''');
// //   }

// //   Future<void> _ejecutarSeguro(Database db, String sql) async {
// //     try {
// //       await db.execute(sql);
// //     } catch (e) {
// //       print("Info SQL (ignorado si existe): $e");
// //     }
// //   }
// // }

// // import 'dart:async';
// // import 'dart:io';
// // import 'package:sqflite/sqflite.dart';
// // import 'package:path/path.dart';

// // class DBManager {
// //   static final DBManager instance = DBManager._init();

// //   Database? _globalDb;
// //   Database? _userDb;
// //   int? _currentUserId;

// //   DBManager._init();

// //   int? get currentUserId => _currentUserId;

// //   // --- CORRECCIÓN 1: Getter de base de datos general ---
// //   Future<Database> get database async {
// //     if (_userDb != null && _currentUserId != null) return _userDb!;
// //     if (_globalDb != null && _globalDb!.isOpen)
// //       return _globalDb!; // <-- CAMBIO AQUÍ
// //     _globalDb = await _initGlobalDb();
// //     return _globalDb!;
// //   }

// //   // =========================================================================
// //   // --- LA SOLUCIÓN AL ERROR: authDatabase a prueba de cierres inesperados ---
// //   // =========================================================================
// //   Future<Database> get authDatabase async {
// //     // Si la base de datos existe PERO está cerrada (por el reemplazo del ZIP), la abrimos de nuevo
// //     if (_globalDb != null && !_globalDb!.isOpen) {
// //       _globalDb = null;
// //     }

// //     if (_globalDb != null) return _globalDb!;
// //     _globalDb = await _initGlobalDb();
// //     return _globalDb!;
// //   }

// //   /// Inicializa o cambia la base de datos al usuario especificado.
// //   Future<void> initUserSession(int userId) async {
// //     _currentUserId = userId;
// //     final dbPath = await getDatabasesPath();
// //     final path = join(dbPath, 'calipso_user_$userId.db');

// //     if (_userDb != null) {
// //       await _userDb!.close();
// //       _userDb = null; // Limpiar memoria
// //     }

// //     _userDb = await openDatabase(
// //       path,
// //       version: 13,
// //       onCreate: (db, version) async {
// //         await _createDataTables(db);
// //       },
// //       onUpgrade: (db, oldVersion, newVersion) async {
// //         final tables = await db.rawQuery(
// //           "SELECT name FROM sqlite_master WHERE type='table' AND name='minutas'",
// //         );
// //         if (tables.isEmpty) {
// //           await db.execute(
// //             'CREATE TABLE minutas (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT)',
// //           );
// //         }

// //         if (oldVersion < 2) await _createDataTables(db);
// //         if (oldVersion < 3) await _createDataTables(db);

// //         if (oldVersion < 4) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inteligencia ADD COLUMN imagen TEXT",
// //           );
// //         }
// //         if (oldVersion < 5) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inteligencia ADD COLUMN adjuntos TEXT",
// //           );
// //         }
// //         if (oldVersion < 6) {
// //           await _createDataTables(db);
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inteligencia ADD COLUMN imagen TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inteligencia ADD COLUMN adjuntos TEXT",
// //           );
// //         }
// //         if (oldVersion < 7) {
// //           await _createDataTables(db);
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE operacional ADD COLUMN imagen TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE operacional ADD COLUMN adjuntos TEXT",
// //           );
// //         }
// //         if (oldVersion < 8) {
// //           await _createDataTables(db);
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_armamento ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_especial ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE comunicaciones ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE expediente ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_miras ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE intendencia ADD COLUMN grd TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE armamento ADD COLUMN observaciones TEXT",
// //           );
// //         }
// //         if (oldVersion < 9) {
// //           await _createDataTables(db);
// //         }
// //         if (oldVersion < 10) {
// //           await _createDataTables(db);
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_miras ADD COLUMN impronta_mira_nimrod TEXT",
// //           );
// //         }
// //         if (oldVersion < 11) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE comunicaciones ADD COLUMN gdo TEXT",
// //           );
// //         }
// //         if (oldVersion < 12) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_miras ADD COLUMN numero_avn TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE inventario_miras ADD COLUMN numero_miras_mor TEXT",
// //           );
// //         }
// //         if (oldVersion < 13) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE intendencia ADD COLUMN grado TEXT",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE intendencia ADD COLUMN cintela INTEGER DEFAULT 0",
// //           );
// //         }
// //       },
// //     );
// //   }

// //   Future<void> closeUserSession() async {
// //     if (_userDb != null) {
// //       await _userDb!.close();
// //       _userDb = null;
// //       _currentUserId = null;
// //     }
// //   }

// //   // --- CORRECCIÓN 2: fullReset mejorado ---
// //   Future<void> fullReset() async {
// //     if (_userDb != null) {
// //       try {
// //         await _userDb!.close();
// //       } catch (_) {}
// //       _userDb = null;
// //     }
// //     if (_globalDb != null) {
// //       try {
// //         await _globalDb!.close();
// //       } catch (_) {}
// //       _globalDb = null;
// //     }
// //     _currentUserId = null;
// //   }

// //   Future<void> restaurarBackup(File backupFile) async {
// //     await fullReset();

// //     String pathDestino;
// //     if (_currentUserId != null) {
// //       final dbPath = await getDatabasesPath();
// //       pathDestino = join(dbPath, 'calipso_user_$_currentUserId.db');
// //     } else {
// //       final dbPath = await getDatabasesPath();
// //       pathDestino = join(dbPath, 'tablet_app.db');
// //     }

// //     if (await File(pathDestino).exists()) {
// //       await File(pathDestino).delete();
// //     }
// //     await backupFile.copy(pathDestino);

// //     print("Backup restaurado correctamente en: $pathDestino");
// //   }

// //   Future<void> limpiarTabla(String nombreTabla) async {
// //     final db = await database;
// //     try {
// //       await db.delete(nombreTabla);
// //       print("Tabla $nombreTabla limpiada correctamente.");
// //     } catch (e) {
// //       print("Error al limpiar $nombreTabla: $e");
// //     }
// //   }

// //   Future<void> limpiarTodaLaData() async {
// //     final db = await database;
// //     final tablas = [
// //       'minutas',
// //       'inteligencia',
// //       'operacional',
// //       'armamento',
// //       'inventario_armamento',
// //       'comunicaciones',
// //       'expediente',
// //       'inventario_especial',
// //       'inventario_miras',
// //       'intendencia',
// //       'personal',
// //       'exde',
// //     ];

// //     for (var tabla in tablas) {
// //       try {
// //         await db.delete(tabla);
// //       } catch (e) {
// //         // Ignorar si la tabla no existe
// //       }
// //     }
// //     print("Ejercito completado: Todas las tablas fueron vaciadas.");
// //   }

// //   Future<Database> _initGlobalDb() async {
// //     final dbPath = await getDatabasesPath();
// //     final path = join(dbPath, 'tablet_app.db');

// //     return await openDatabase(
// //       path,
// //       version: 35,
// //       onCreate: (db, version) async {
// //         await _createAuthTables(db);
// //       },
// //       onUpgrade: (db, oldVersion, newVersion) async {
// //         if (oldVersion < 32) {
// //           await _ejecutarSeguro(
// //             db,
// //             "ALTER TABLE usuarios ADD COLUMN estado TEXT DEFAULT 'activo'",
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             'ALTER TABLE usuarios ADD COLUMN fecha_creacion TEXT',
// //           );
// //           await _ejecutarSeguro(
// //             db,
// //             'ALTER TABLE sesion_activa ADD COLUMN usar_huella INTEGER DEFAULT 0',
// //           );
// //         }
// //         if (oldVersion < 35) {
// //           print("Actualizando DB Global a v35...");
// //         }
// //       },
// //     );
// //   }

// //   Future _createAuthTables(Database db) async {
// //     await db.execute('''
// //       CREATE TABLE IF NOT EXISTS usuarios (
// //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// //         nombres TEXT NOT NULL,
// //         correo TEXT,
// //         password TEXT NOT NULL,
// //         rol TEXT DEFAULT 'usuario',
// //         estado TEXT DEFAULT 'activo',
// //         fecha_creacion TEXT,
// //         ultimo_acceso TEXT
// //       )
// //     ''');

// //     await db.execute('''
// //       CREATE TABLE IF NOT EXISTS sesion_activa (
// //         id INTEGER PRIMARY KEY AUTOINCREMENT,
// //         usuario_id INTEGER,
// //         mantener_sesion INTEGER DEFAULT 0,
// //         usar_huella INTEGER DEFAULT 0,
// //         FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
// //       )
// //     ''');
// //   }

// //   Future _createDataTables(Database db) async {
// //     await db.execute(
// //       'CREATE TABLE IF NOT EXISTS minutas (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT)',
// //     );
// //     await db.execute(
// //       'CREATE TABLE IF NOT EXISTS inteligencia (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, medio TEXT, anotaciones TEXT, imagen TEXT, adjuntos TEXT)',
// //     );
// //     await db.execute(
// //       'CREATE TABLE IF NOT EXISTS operacional (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT, imagen TEXT, adjuntos TEXT)',
// //     );
// //     await db.execute(
// //       'CREATE TABLE IF NOT EXISTS armamento (id INTEGER PRIMARY KEY AUTOINCREMENT, clase TEXT NOT NULL UNIQUE, cargo INTEGER DEFAULT 0, mano INTEGER DEFAULT 0, deposito INTEGER DEFAULT 0, total INTEGER DEFAULT 0, observaciones TEXT)',
// //     );

// //     await db.execute(
// //       '''CREATE TABLE IF NOT EXISTS inventario_armamento (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, categoria TEXT, grd TEXT, apellidos_nombres TEXT, n_arma TEXT,
// //       municion_556 INTEGER DEFAULT 0, proveedores_556 INTEGER DEFAULT 0, municion_esl_556 INTEGER DEFAULT 0,
// //       municion_esl_762 INTEGER DEFAULT 0, canon INTEGER DEFAULT 0, granada_mano INTEGER DEFAULT 0,
// //       granada_60 INTEGER DEFAULT 0, granada_humo INTEGER DEFAULT 0, bengalas INTEGER DEFAULT 0,
// //       granada_lacrimogena INTEGER DEFAULT 0, trampa_iluminacion INTEGER DEFAULT 0, granada_aturdidora INTEGER DEFAULT 0,
// //       porta_arma INTEGER DEFAULT 0, casco INTEGER DEFAULT 0, foto_patrimonio TEXT, observaciones TEXT)''',
// //     );

// //     await db.execute(
// //       '''CREATE TABLE IF NOT EXISTS comunicaciones (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, gdo TEXT, nombres TEXT, clase_radio TEXT, no_radio TEXT,
// //       antena_tubular INTEGER DEFAULT 0, antena_latigo INTEGER DEFAULT 0, arnes INTEGER DEFAULT 0, microtelefono INTEGER DEFAULT 0,
// //       bolso INTEGER DEFAULT 0, base_antena INTEGER DEFAULT 0, tapa_baterias INTEGER DEFAULT 0, base_latigo INTEGER DEFAULT 0,
// //       base_tubular INTEGER DEFAULT 0, antena_flexible INTEGER DEFAULT 0, batterias INTEGER DEFAULT 0, perillas INTEGER DEFAULT 0,
// //       cargador INTEGER DEFAULT 0, protector INTEGER DEFAULT 0, clip INTEGER DEFAULT 0, antena_gps INTEGER DEFAULT 0,
// //       cargador_apx INTEGER DEFAULT 0, antena_gps_5602 INTEGER DEFAULT 0, chaleco INTEGER DEFAULT 0, paneles INTEGER DEFAULT 0,
// //       gps_garmin INTEGER DEFAULT 0, flecher INTEGER DEFAULT 0, observaciones TEXT)''',
// //     );

// //     await db.execute('''CREATE TABLE IF NOT EXISTS expediente (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, nombres TEXT, n_elemento TEXT,
// //       canino INTEGER DEFAULT 0, valium INTEGER DEFAULT 0, ecaex INTEGER DEFAULT 0, tubo_pvc INTEGER DEFAULT 0,
// //       tubo_metalico INTEGER DEFAULT 0, guindo_20m INTEGER DEFAULT 0, cuerda_50m INTEGER DEFAULT 0, gancho_3puntas INTEGER DEFAULT 0,
// //       boca_pato INTEGER DEFAULT 0, estuche_verde INTEGER DEFAULT 0, perla INTEGER DEFAULT 0, bolso_transporte INTEGER DEFAULT 0,
// //       auriculares INTEGER DEFAULT 0, tes_prueba INTEGER DEFAULT 0, unidad_electrica INTEGER DEFAULT 0, cabeza_busqueda INTEGER DEFAULT 0,
// //       pinzas_sog INTEGER DEFAULT 0, cargas_huecas INTEGER DEFAULT 0, pentolita_1kg INTEGER DEFAULT 0, pentolita_1_2kg INTEGER DEFAULT 0,
// //       pentolita_1_4kg INTEGER DEFAULT 0, mecha_lenta INTEGER DEFAULT 0, cordon_12gr INTEGER DEFAULT 0,
// //       detonador_comun INTEGER DEFAULT 0, cordon_6gr INTEGER DEFAULT 0, cordon_3gr INTEGER DEFAULT 0, detonadores_electric INTEGER DEFAULT 0,
// //       detonadores_inelectric INTEGER DEFAULT 0, observacion TEXT)''');

// //     await db.execute('''CREATE TABLE IF NOT EXISTS inventario_especial (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, categoria TEXT, grd TEXT, apellidos_nombres TEXT, n_arma TEXT,
// //       m_762_eslb INTEGER DEFAULT 0, m_556_eslb INTEGER DEFAULT 0, m_762_sub INTEGER DEFAULT 0,
// //       m_9mm INTEGER DEFAULT 0, g_im26 INTEGER DEFAULT 0, g_humo INTEGER DEFAULT 0, g_40mm INTEGER DEFAULT 0,
// //       g_lacrimogena INTEGER DEFAULT 0, canon INTEGER DEFAULT 0, trampa_ilu INTEGER DEFAULT 0, casco_kevlar INTEGER DEFAULT 0,
// //       lentes INTEGER DEFAULT 0, prov_762 INTEGER DEFAULT 0, prov_9mm INTEGER DEFAULT 0, porta_arma INTEGER DEFAULT 0,
// //       supresor INTEGER DEFAULT 0, foto_path TEXT)''');

// //     await db.execute('''CREATE TABLE IF NOT EXISTS inventario_miras (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, grd TEXT, apellidos_nombres TEXT, numero_avenida TEXT,
// //       numero_avn TEXT, numero_mira_mor TEXT, numero_miras_mor TEXT,
// //       numero_mira_nimrod TEXT, impronta_mira_nimrod TEXT, foto_path TEXT)''');

// //     await db.execute('''CREATE TABLE IF NOT EXISTS intendencia (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, grado TEXT, apellidos_nombres TEXT,
// //       camuflado_1 TEXT, camuflado_2 TEXT, equipo_campana INTEGER DEFAULT 0, botas_par INTEGER DEFAULT 0,
// //       camisetas_verdes INTEGER DEFAULT 0, medias_negras INTEGER DEFAULT 0, marmita INTEGER DEFAULT 0,
// //       hamaca INTEGER DEFAULT 0, poncho_pixelado INTEGER DEFAULT 0, cintura INTEGER DEFAULT 0, cintela INTEGER DEFAULT 0, colchoneta INTEGER DEFAULT 0,
// //       estuche_jarro_cantimplora INTEGER DEFAULT 0, boxer INTEGER DEFAULT 0, toalla_verde INTEGER DEFAULT 0,
// //       foto_path TEXT, observaciones TEXT)''');

// //     await db.execute(
// //       '''CREATE TABLE IF NOT EXISTS personal (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, grado TEXT, nombre TEXT, apellido TEXT, rh TEXT,
// //       tipo_documento TEXT, numero_documento TEXT, fecha_nacimiento TEXT, ciudad_nacimiento TEXT,
// //       pais_nacimiento TEXT, sexo TEXT, direccion TEXT, telefono TEXT, correo TEXT, cargo TEXT,
// //       fecha_ingreso TEXT, estado TEXT, foto_path TEXT, nombre_padre TEXT, telefono_padre TEXT,
// //       nombre_mother TEXT, telefono_mother TEXT, nombre_hijo TEXT, contacto_emergencia TEXT, telefono_emergencia TEXT)''',
// //     );

// //     await db.execute('''CREATE TABLE IF NOT EXISTS exde (
// //       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, nombres TEXT, n_elemento TEXT,
// //       canino INTEGER DEFAULT 0, valom INTEGER DEFAULT 0, ecaex INTEGER DEFAULT 0, tubo_pvc INTEGER DEFAULT 0,
// //       tubo_metalico INTEGER DEFAULT 0, guindo_20m INTEGER DEFAULT 0, cuerda_50m INTEGER DEFAULT 0, gancho_3puntas INTEGER DEFAULT 0,
// //       boca_pato INTEGER DEFAULT 0, estuche_verde INTEGER DEFAULT 0, pera INTEGER DEFAULT 0, bolso_transporte INTEGER DEFAULT 0,
// //       auriculares INTEGER DEFAULT 0, tes_prueba INTEGER DEFAULT 0, unidad_electrica INTEGER DEFAULT 0, cabeza_busqueda INTEGER DEFAULT 0,
// //       pinzas_sog INTEGER DEFAULT 0, cargas_huecas INTEGER DEFAULT 0, pentolita_1kg INTEGER DEFAULT 0, pentolita_1_2kg INTEGER DEFAULT 0,
// //       pentolita_1_4kg INTEGER DEFAULT 0, pentolita_1_8kg INTEGER DEFAULT 0, mecha_lenta INTEGER DEFAULT 0, cordon_12gr INTEGER DEFAULT 0,
// //       detonador_comun INTEGER DEFAULT 0, cordon_6gr INTEGER DEFAULT 0, cordon_3gr INTEGER DEFAULT 0, detonadores_elec INTEGER DEFAULT 0,
// //       detonadores_inelec INTEGER DEFAULT 0, observacion TEXT)''');
// //   }

// //   Future<void> _ejecutarSeguro(Database db, String sql) async {
// //     try {
// //       await db.execute(sql);
// //     } catch (e) {
// //       print("Info SQL (ignorado si existe): $e");
// //     }
// //   }
// // }

// import 'dart:async';
// import 'dart:io';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// class DBManager {
//   static final DBManager instance = DBManager._init();

//   Database? _globalDb;
//   Database? _userDb;
//   int? _currentUserId;

//   DBManager._init();

//   int? get currentUserId => _currentUserId;

//   // --- Getter de base de datos general ---
//   Future<Database> get database async {
//     if (_userDb != null && _currentUserId != null) return _userDb!;
//     if (_globalDb != null && _globalDb!.isOpen) return _globalDb!;
//     _globalDb = await _initGlobalDb();
//     return _globalDb!;
//   }

//   // --- authDatabase a prueba de cierres inesperados ---
//   Future<Database> get authDatabase async {
//     if (_globalDb != null && !_globalDb!.isOpen) {
//       _globalDb = null;
//     }

//     if (_globalDb != null) return _globalDb!;
//     _globalDb = await _initGlobalDb();
//     return _globalDb!;
//   }

//   /// Inicializa o cambia la base de datos al usuario especificado.
//   Future<void> initUserSession(int userId) async {
//     _currentUserId = userId;
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, 'calipso_user_$userId.db');

//     if (_userDb != null) {
//       await _userDb!.close();
//       _userDb = null; // Limpiar memoria
//     }

//     _userDb = await openDatabase(
//       path,
//       version: 14, // ✅ AUMENTÉ LA VERSIÓN A 14
//       onCreate: (db, version) async {
//         await _createDataTables(db);
//       },
//       onUpgrade: (db, oldVersion, newVersion) async {
//         final tables = await db.rawQuery(
//           "SELECT name FROM sqlite_master WHERE type='table' AND name='minutas'",
//         );
//         if (tables.isEmpty) {
//           await db.execute(
//             'CREATE TABLE minutas (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT)',
//           );
//         }

//         if (oldVersion < 2) await _createDataTables(db);
//         if (oldVersion < 3) await _createDataTables(db);

//         if (oldVersion < 4) {
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE inteligencia ADD COLUMN imagen TEXT",
//           );
//         }
//         if (oldVersion < 5) {
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE inteligencia ADD COLUMN adjuntos TEXT",
//           );
//         }
//         if (oldVersion < 6) {
//           await _createDataTables(db);
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE inteligencia ADD COLUMN imagen TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE inteligencia ADD COLUMN adjuntos TEXT",
//           );
//         }
//         if (oldVersion < 7) {
//           await _createDataTables(db);
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE operacional ADD COLUMN imagen TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE operacional ADD COLUMN adjuntos TEXT",
//           );
//         }
//         if (oldVersion < 8) {
//           await _createDataTables(db);
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE inventario_armamento ADD COLUMN grd TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE inventario_especial ADD COLUMN grd TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE comunicaciones ADD COLUMN grd TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE expediente ADD COLUMN grd TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE inventario_miras ADD COLUMN grd TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE intendencia ADD COLUMN grd TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE armamento ADD COLUMN observaciones TEXT",
//           );
//         }
//         if (oldVersion < 9) {
//           await _createDataTables(db);
//         }
//         if (oldVersion < 10) {
//           await _createDataTables(db);
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE inventario_miras ADD COLUMN impronta_mira_nimrod TEXT",
//           );
//         }
//         if (oldVersion < 11) {
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE comunicaciones ADD COLUMN gdo TEXT",
//           );
//         }
//         if (oldVersion < 12) {
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE inventario_miras ADD COLUMN numero_avn TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE inventario_miras ADD COLUMN numero_miras_mor TEXT",
//           );
//         }
//         if (oldVersion < 13) {
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE intendencia ADD COLUMN grado TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE intendencia ADD COLUMN cintela INTEGER DEFAULT 0",
//           );
//         }

//         // ✅ NUEVA MIGRACIÓN PARA CORREGIR EL ERROR DE personal
//         if (oldVersion < 14) {
//           // Se agregan las columnas que faltaban con el nombre correcto
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE personal ADD COLUMN nombre_madre TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE personal ADD COLUMN telefono_madre TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE personal ADD COLUMN nombre_hijo TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE personal ADD COLUMN contacto_emergencia TEXT",
//           );
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE personal ADD COLUMN telefono_emergencia TEXT",
//           );
//         }
//       },
//     );
//   }

//   Future<void> closeUserSession() async {
//     if (_userDb != null) {
//       await _userDb!.close();
//       _userDb = null;
//       _currentUserId = null;
//     }
//   }

//   // --- fullReset mejorado ---
//   Future<void> fullReset() async {
//     if (_userDb != null) {
//       try {
//         await _userDb!.close();
//       } catch (_) {}
//       _userDb = null;
//     }
//     if (_globalDb != null) {
//       try {
//         await _globalDb!.close();
//       } catch (_) {}
//       _globalDb = null;
//     }
//     _currentUserId = null;
//   }

//   Future<void> restaurarBackup(File backupFile) async {
//     await fullReset();

//     String pathDestino;
//     if (_currentUserId != null) {
//       final dbPath = await getDatabasesPath();
//       pathDestino = join(dbPath, 'calipso_user_$_currentUserId.db');
//     } else {
//       final dbPath = await getDatabasesPath();
//       pathDestino = join(dbPath, 'tablet_app.db');
//     }

//     if (await File(pathDestino).exists()) {
//       await File(pathDestino).delete();
//     }
//     await backupFile.copy(pathDestino);

//     print("Backup restaurado correctamente en: $pathDestino");
//   }

//   Future<void> limpiarTabla(String nombreTabla) async {
//     final db = await database;
//     try {
//       await db.delete(nombreTabla);
//       print("Tabla $nombreTabla limpiada correctamente.");
//     } catch (e) {
//       print("Error al limpiar $nombreTabla: $e");
//     }
//   }

//   Future<void> limpiarTodaLaData() async {
//     final db = await database;
//     final tablas = [
//       'minutas',
//       'inteligencia',
//       'operacional',
//       'armamento',
//       'inventario_armamento',
//       'comunicaciones',
//       'expediente',
//       'inventario_especial',
//       'inventario_miras',
//       'intendencia',
//       'personal',
//       'exde',
//     ];

//     for (var tabla in tablas) {
//       try {
//         await db.delete(tabla);
//       } catch (e) {
//         // Ignorar si la tabla no existe
//       }
//     }
//     print("Ejercito completado: Todas las tablas fueron vaciadas.");
//   }

//   Future<Database> _initGlobalDb() async {
//     final dbPath = await getDatabasesPath();
//     final path = join(dbPath, 'tablet_app.db');

//     return await openDatabase(
//       path,
//       version: 35,
//       onCreate: (db, version) async {
//         await _createAuthTables(db);
//       },
//       onUpgrade: (db, oldVersion, newVersion) async {
//         if (oldVersion < 32) {
//           await _ejecutarSeguro(
//             db,
//             "ALTER TABLE usuarios ADD COLUMN estado TEXT DEFAULT 'activo'",
//           );
//           await _ejecutarSeguro(
//             db,
//             'ALTER TABLE usuarios ADD COLUMN fecha_creacion TEXT',
//           );
//           await _ejecutarSeguro(
//             db,
//             'ALTER TABLE sesion_activa ADD COLUMN usar_huella INTEGER DEFAULT 0',
//           );
//         }
//         if (oldVersion < 35) {
//           print("Actualizando DB Global a v35...");
//         }
//       },
//     );
//   }

//   Future _createAuthTables(Database db) async {
//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS usuarios (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         nombres TEXT NOT NULL,
//         correo TEXT,
//         password TEXT NOT NULL,
//         rol TEXT DEFAULT 'usuario',
//         estado TEXT DEFAULT 'activo',
//         fecha_creacion TEXT,
//         ultimo_acceso TEXT
//       )
//     ''');

//     await db.execute('''
//       CREATE TABLE IF NOT EXISTS sesion_activa (
//         id INTEGER PRIMARY KEY AUTOINCREMENT,
//         usuario_id INTEGER,
//         mantener_sesion INTEGER DEFAULT 0,
//         usar_huella INTEGER DEFAULT 0,
//         FOREIGN KEY (usuario_id) REFERENCES usuarios (id)
//       )
//     ''');
//   }

//   Future _createDataTables(Database db) async {
//     await db.execute(
//       'CREATE TABLE IF NOT EXISTS minutas (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT)',
//     );
//     await db.execute(
//       'CREATE TABLE IF NOT EXISTS inteligencia (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, medio TEXT, anotaciones TEXT, imagen TEXT, adjuntos TEXT)',
//     );
//     await db.execute(
//       'CREATE TABLE IF NOT EXISTS operacional (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT, imagen TEXT, adjuntos TEXT)',
//     );
//     await db.execute(
//       'CREATE TABLE IF NOT EXISTS armamento (id INTEGER PRIMARY KEY AUTOINCREMENT, clase TEXT NOT NULL UNIQUE, cargo INTEGER DEFAULT 0, mano INTEGER DEFAULT 0, deposito INTEGER DEFAULT 0, total INTEGER DEFAULT 0, observaciones TEXT)',
//     );

//     await db.execute(
//       '''CREATE TABLE IF NOT EXISTS inventario_armamento (
//       id INTEGER PRIMARY KEY AUTOINCREMENT, categoria TEXT, grd TEXT, apellidos_nombres TEXT, n_arma TEXT,
//       municion_556 INTEGER DEFAULT 0, proveedores_556 INTEGER DEFAULT 0, municion_esl_556 INTEGER DEFAULT 0,
//       municion_esl_762 INTEGER DEFAULT 0, canon INTEGER DEFAULT 0, granada_mano INTEGER DEFAULT 0,
//       granada_60 INTEGER DEFAULT 0, granada_humo INTEGER DEFAULT 0, bengalas INTEGER DEFAULT 0,
//       granada_lacrimogena INTEGER DEFAULT 0, trampa_iluminacion INTEGER DEFAULT 0, granada_aturdidora INTEGER DEFAULT 0,
//       porta_arma INTEGER DEFAULT 0, casco INTEGER DEFAULT 0, foto_patrimonio TEXT, observaciones TEXT)''',
//     );

//     await db.execute(
//       '''CREATE TABLE IF NOT EXISTS comunicaciones (
//       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, gdo TEXT, nombres TEXT, clase_radio TEXT, no_radio TEXT,
//       antena_tubular INTEGER DEFAULT 0, antena_latigo INTEGER DEFAULT 0, arnes INTEGER DEFAULT 0, microtelefono INTEGER DEFAULT 0,
//       bolso INTEGER DEFAULT 0, base_antena INTEGER DEFAULT 0, tapa_baterias INTEGER DEFAULT 0, base_latigo INTEGER DEFAULT 0,
//       base_tubular INTEGER DEFAULT 0, antena_flexible INTEGER DEFAULT 0, batterias INTEGER DEFAULT 0, perillas INTEGER DEFAULT 0,
//       cargador INTEGER DEFAULT 0, protector INTEGER DEFAULT 0, clip INTEGER DEFAULT 0, antena_gps INTEGER DEFAULT 0,
//       cargador_apx INTEGER DEFAULT 0, antena_gps_5602 INTEGER DEFAULT 0, chaleco INTEGER DEFAULT 0, paneles INTEGER DEFAULT 0,
//       gps_garmin INTEGER DEFAULT 0, flecher INTEGER DEFAULT 0, observaciones TEXT)''',
//     );

//     await db.execute('''CREATE TABLE IF NOT EXISTS expediente (
//       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, nombres TEXT, n_elemento TEXT,
//       canino INTEGER DEFAULT 0, valium INTEGER DEFAULT 0, ecaex INTEGER DEFAULT 0, tubo_pvc INTEGER DEFAULT 0,
//       tubo_metalico INTEGER DEFAULT 0, guindo_20m INTEGER DEFAULT 0, cuerda_50m INTEGER DEFAULT 0, gancho_3puntas INTEGER DEFAULT 0,
//       boca_pato INTEGER DEFAULT 0, estuche_verde INTEGER DEFAULT 0, perla INTEGER DEFAULT 0, bolso_transporte INTEGER DEFAULT 0,
//       auriculares INTEGER DEFAULT 0, tes_prueba INTEGER DEFAULT 0, unidad_electrica INTEGER DEFAULT 0, cabeza_busqueda INTEGER DEFAULT 0,
//       pinzas_sog INTEGER DEFAULT 0, cargas_huecas INTEGER DEFAULT 0, pentolita_1kg INTEGER DEFAULT 0, pentolita_1_2kg INTEGER DEFAULT 0,
//       pentolita_1_4kg INTEGER DEFAULT 0, mecha_lenta INTEGER DEFAULT 0, cordon_12gr INTEGER DEFAULT 0,
//       detonador_comun INTEGER DEFAULT 0, cordon_6gr INTEGER DEFAULT 0, cordon_3gr INTEGER DEFAULT 0, detonadores_electric INTEGER DEFAULT 0,
//       detonadores_inelectric INTEGER DEFAULT 0, observacion TEXT)''');

//     await db.execute('''CREATE TABLE IF NOT EXISTS inventario_especial (
//       id INTEGER PRIMARY KEY AUTOINCREMENT, categoria TEXT, grd TEXT, apellidos_nombres TEXT, n_arma TEXT,
//       m_762_eslb INTEGER DEFAULT 0, m_556_eslb INTEGER DEFAULT 0, m_762_sub INTEGER DEFAULT 0,
//       m_9mm INTEGER DEFAULT 0, g_im26 INTEGER DEFAULT 0, g_humo INTEGER DEFAULT 0, g_40mm INTEGER DEFAULT 0,
//       g_lacrimogena INTEGER DEFAULT 0, canon INTEGER DEFAULT 0, trampa_ilu INTEGER DEFAULT 0, casco_kevlar INTEGER DEFAULT 0,
//       lentes INTEGER DEFAULT 0, prov_762 INTEGER DEFAULT 0, prov_9mm INTEGER DEFAULT 0, porta_arma INTEGER DEFAULT 0,
//       supresor INTEGER DEFAULT 0, foto_path TEXT)''');

//     await db.execute('''CREATE TABLE IF NOT EXISTS inventario_miras (
//       id INTEGER PRIMARY KEY AUTOINCREMENT, grd TEXT, apellidos_nombres TEXT, numero_avenida TEXT,
//       numero_avn TEXT, numero_mira_mor TEXT, numero_miras_mor TEXT,
//       numero_mira_nimrod TEXT, impronta_mira_nimrod TEXT, foto_path TEXT)''');

//     await db.execute('''CREATE TABLE IF NOT EXISTS intendencia (
//       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, grado TEXT, apellidos_nombres TEXT,
//       camuflado_1 TEXT, camuflado_2 TEXT, equipo_campana INTEGER DEFAULT 0, botas_par INTEGER DEFAULT 0,
//       camisetas_verdes INTEGER DEFAULT 0, medias_negras INTEGER DEFAULT 0, marmita INTEGER DEFAULT 0,
//       hamaca INTEGER DEFAULT 0, poncho_pixelado INTEGER DEFAULT 0, cintura INTEGER DEFAULT 0, cintela INTEGER DEFAULT 0, colchoneta INTEGER DEFAULT 0,
//       estuche_jarro_cantimplora INTEGER DEFAULT 0, boxer INTEGER DEFAULT 0, toalla_verde INTEGER DEFAULT 0,
//       foto_path TEXT, observaciones TEXT)''');

//     // ✅ CORRECCIÓN AQUÍ: Cambié "nombre_mother" por "nombre_madre" y "telefono_mother" por "telefono_madre"
//     await db.execute(
//       '''CREATE TABLE IF NOT EXISTS personal (
//       id INTEGER PRIMARY KEY AUTOINCREMENT, grado TEXT, nombre TEXT, apellido TEXT, rh TEXT,
//       tipo_documento TEXT, numero_documento TEXT, fecha_nacimiento TEXT, ciudad_nacimiento TEXT,
//       pais_nacimiento TEXT, sexo TEXT, direccion TEXT, telefono TEXT, correo TEXT, cargo TEXT,
//       fecha_ingreso TEXT, estado TEXT, foto_path TEXT, nombre_padre TEXT, telefono_padre TEXT,
//       nombre_madre TEXT, telefono_madre TEXT, nombre_hijo TEXT, contacto_emergencia TEXT, telefono_emergencia TEXT)''',
//     );

//     await db.execute('''CREATE TABLE IF NOT EXISTS exde (
//       id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, nombres TEXT, n_elemento TEXT,
//       canino INTEGER DEFAULT 0, valom INTEGER DEFAULT 0, ecaex INTEGER DEFAULT 0, tubo_pvc INTEGER DEFAULT 0,
//       tubo_metalico INTEGER DEFAULT 0, guindo_20m INTEGER DEFAULT 0, cuerda_50m INTEGER DEFAULT 0, gancho_3puntas INTEGER DEFAULT 0,
//       boca_pato INTEGER DEFAULT 0, estuche_verde INTEGER DEFAULT 0, pera INTEGER DEFAULT 0, bolso_transporte INTEGER DEFAULT 0,
//       auriculares INTEGER DEFAULT 0, tes_prueba INTEGER DEFAULT 0, unidad_electrica INTEGER DEFAULT 0, cabeza_busqueda INTEGER DEFAULT 0,
//       pinzas_sog INTEGER DEFAULT 0, cargas_huecas INTEGER DEFAULT 0, pentolita_1kg INTEGER DEFAULT 0, pentolita_1_2kg INTEGER DEFAULT 0,
//       pentolita_1_4kg INTEGER DEFAULT 0, pentolita_1_8kg INTEGER DEFAULT 0, mecha_lenta INTEGER DEFAULT 0, cordon_12gr INTEGER DEFAULT 0,
//       detonador_comun INTEGER DEFAULT 0, cordon_6gr INTEGER DEFAULT 0, cordon_3gr INTEGER DEFAULT 0, detonadores_elec INTEGER DEFAULT 0,
//       detonadores_inelec INTEGER DEFAULT 0, observacion TEXT)''');
//   }

//   Future<void> _ejecutarSeguro(Database db, String sql) async {
//     try {
//       await db.execute(sql);
//     } catch (e) {
//       print("Info SQL (ignorado si existe): $e");
//     }
//   }
// }

import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBManager {
  static final DBManager instance = DBManager._init();

  Database? _globalDb;
  Database? _userDb;
  int? _currentUserId;

  DBManager._init();

  int? get currentUserId => _currentUserId;

  Future<Database> get database async {
    if (_userDb != null && _currentUserId != null) return _userDb!;
    if (_globalDb != null && _globalDb!.isOpen) return _globalDb!;
    _globalDb = await _initGlobalDb();
    return _globalDb!;
  }

  Future<Database> get authDatabase async {
    if (_globalDb != null && !_globalDb!.isOpen) {
      _globalDb = null;
    }
    if (_globalDb != null) return _globalDb!;
    _globalDb = await _initGlobalDb();
    return _globalDb!;
  }

  /// Inicializa o cambia la base de datos al usuario especificado.
  Future<void> initUserSession(int userId) async {
    _currentUserId = userId;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'calipso_user_$userId.db');

    if (_userDb != null) {
      await _userDb!.close();
      _userDb = null;
    }

    _userDb = await openDatabase(
      path,
      version: 14,
      onCreate: (db, version) async {
        await _createDataTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='minutas'",
        );
        if (tables.isEmpty) {
          await db.execute(
            'CREATE TABLE minutas (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT)',
          );
        }

        if (oldVersion < 2) await _createDataTables(db);
        if (oldVersion < 3) await _createDataTables(db);

        if (oldVersion < 4) {
          await _ejecutarSeguro(
            db,
            "ALTER TABLE inteligencia ADD COLUMN imagen TEXT",
          );
        }
        if (oldVersion < 5) {
          await _ejecutarSeguro(
            db,
            "ALTER TABLE inteligencia ADD COLUMN adjuntos TEXT",
          );
        }
        if (oldVersion < 6) {
          await _createDataTables(db);
          await _ejecutarSeguro(
            db,
            "ALTER TABLE inteligencia ADD COLUMN imagen TEXT",
          );
          await _ejecutarSeguro(
            db,
            "ALTER TABLE inteligencia ADD COLUMN adjuntos TEXT",
          );
        }
        if (oldVersion < 7) {
          await _createDataTables(db);
          await _ejecutarSeguro(
            db,
            "ALTER TABLE operacional ADD COLUMN imagen TEXT",
          );
          await _ejecutarSeguro(
            db,
            "ALTER TABLE operacional ADD COLUMN adjuntos TEXT",
          );
        }
        if (oldVersion < 8) {
          await _createDataTables(db);
          await _ejecutarSeguro(
            db,
            "ALTER TABLE inventario_armamento ADD COLUMN grd TEXT",
          );
          await _ejecutarSeguro(
            db,
            "ALTER TABLE inventario_especial ADD COLUMN grd TEXT",
          );
          await _ejecutarSeguro(
            db,
            "ALTER TABLE comunicaciones ADD COLUMN grd TEXT",
          );
          await _ejecutarSeguro(
            db,
            "ALTER TABLE expediente ADD COLUMN grd TEXT",
          );
          await _ejecutarSeguro(
            db,
            "ALTER TABLE inventario_miras ADD COLUMN grd TEXT",
          );
          await _ejecutarSeguro(
            db,
            "ALTER TABLE intendencia ADD COLUMN grd TEXT",
          );
          await _ejecutarSeguro(
            db,
            "ALTER TABLE armamento ADD COLUMN observaciones TEXT",
          );
        }
        if (oldVersion < 9) await _createDataTables(db);

        if (oldVersion < 10) {
          await _createDataTables(db);
          await _ejecutarSeguro(
            db,
            "ALTER TABLE inventario_miras ADD COLUMN impronta_mira_nimrod TEXT",
          );
        }
        if (oldVersion < 11) {
          await _ejecutarSeguro(
            db,
            "ALTER TABLE comunicaciones ADD COLUMN gdo TEXT",
          );
        }
        if (oldVersion < 12) {
          await _ejecutarSeguro(
            db,
            "ALTER TABLE inventario_miras ADD COLUMN numero_avn TEXT",
          );
          await _ejecutarSeguro(
            db,
            "ALTER TABLE inventario_miras ADD COLUMN numero_miras_mor TEXT",
          );
        }
        if (oldVersion < 13) {
          await _ejecutarSeguro(
            db,
            "ALTER TABLE intendencia ADD COLUMN grado TEXT",
          );
          await _ejecutarSeguro(
            db,
            "ALTER TABLE intendencia ADD COLUMN cintela INTEGER DEFAULT 0",
          );
        }

        // ---> VERSIÓN 14: Corrige "batterias" a "baterias" o recrea si falta
        if (oldVersion < 14) {
          await _repararTablaComunicaciones(db);
        }
      },
    );
  }

  Future<void> closeUserSession() async {
    if (_userDb != null) {
      await _userDb!.close();
      _userDb = null;
      _currentUserId = null;
    }
  }

  Future<void> fullReset() async {
    if (_userDb != null) {
      try {
        await _userDb!.close();
      } catch (_) {}
      _userDb = null;
    }
    if (_globalDb != null) {
      try {
        await _globalDb!.close();
      } catch (_) {}
      _globalDb = null;
    }
    _currentUserId = null;
  }

  Future<void> restaurarBackup(File backupFile) async {
    await fullReset();
    String pathDestino;
    if (_currentUserId != null) {
      final dbPath = await getDatabasesPath();
      pathDestino = join(dbPath, 'calipso_user_$_currentUserId.db');
    } else {
      final dbPath = await getDatabasesPath();
      pathDestino = join(dbPath, 'tablet_app.db');
    }
    if (await File(pathDestino).exists()) await File(pathDestino).delete();
    await backupFile.copy(pathDestino);
    print("Backup restaurado correctamente en: $pathDestino");
  }

  Future<void> limpiarTabla(String nombreTabla) async {
    final db = await database;
    try {
      await db.delete(nombreTabla);
      print("Tabla $nombreTabla limpiada correctamente.");
    } catch (e) {
      print("Error al limpiar $nombreTabla: $e");
    }
  }

  Future<void> limpiarTodaLaData() async {
    final db = await database;
    final tablas = [
      'minutas',
      'inteligencia',
      'operacional',
      'armamento',
      'inventario_armamento',
      'comunicaciones',
      'expediente',
      'inventario_especial',
      'inventario_miras',
      'intendencia',
      'personal',
      'exde',
    ];
    for (var tabla in tablas) {
      try {
        await db.delete(tabla);
      } catch (e) {}
    }
    print("Ejercito completado: Todas las tablas fueron vaciadas.");
  }

  Future<Database> _initGlobalDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tablet_app.db');
    return await openDatabase(
      path,
      version: 35,
      onCreate: (db, version) async {
        await _createAuthTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 32) {
          await _ejecutarSeguro(
            db,
            "ALTER TABLE usuarios ADD COLUMN estado TEXT DEFAULT 'activo'",
          );
          await _ejecutarSeguro(
            db,
            'ALTER TABLE usuarios ADD COLUMN fecha_creacion TEXT',
          );
          await _ejecutarSeguro(
            db,
            'ALTER TABLE sesion_activa ADD COLUMN usar_huella INTEGER DEFAULT 0',
          );
        }
      },
    );
  }

  Future _createAuthTables(Database db) async {
    await db.execute('''CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT, nombres TEXT NOT NULL, correo TEXT,
        password TEXT NOT NULL, rol TEXT DEFAULT 'usuario', estado TEXT DEFAULT 'activo',
        fecha_creacion TEXT, ultimo_acceso TEXT)''');
    await db.execute('''CREATE TABLE IF NOT EXISTS sesion_activa (
        id INTEGER PRIMARY KEY AUTOINCREMENT, usuario_id INTEGER,
        mantener_sesion INTEGER DEFAULT 0, usar_huella INTEGER DEFAULT 0,
        FOREIGN KEY (usuario_id) REFERENCES usuarios (id))''');
  }

  // =========================================================================
  // FUNCIÓN DE REPARACIÓN DEFINITIVA A PRUEBA DE FALLOS
  // =========================================================================
  Future<void> _repararTablaComunicaciones(Database db) async {
    try {
      // 1. Verificar si la tabla existe actualmente
      final tableCheck = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='comunicaciones'",
      );

      if (tableCheck.isEmpty) {
        // CASO A: La tabla no existe (se borró o nunca se creó). La creamos limpia.
        print("Tabla 'comunicaciones' no encontrada. Creándola limpia...");
        await db.execute(
          '''CREATE TABLE comunicaciones (
          id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, gdo TEXT, nombres TEXT, clase_radio TEXT, no_radio TEXT,
          antena_tubular INTEGER DEFAULT 0, antena_latigo INTEGER DEFAULT 0, arnes INTEGER DEFAULT 0, microtelefono INTEGER DEFAULT 0,
          bolso INTEGER DEFAULT 0, base_antena INTEGER DEFAULT 0, tapa_baterias INTEGER DEFAULT 0, base_latigo INTEGER DEFAULT 0,
          base_tubular INTEGER DEFAULT 0, antena_flexible INTEGER DEFAULT 0, baterias INTEGER DEFAULT 0, perillas INTEGER DEFAULT 0,
          cargador INTEGER DEFAULT 0, protector INTEGER DEFAULT 0, clip INTEGER DEFAULT 0, antena_gps INTEGER DEFAULT 0,
          cargador_apx INTEGER DEFAULT 0, antena_gps_5602 INTEGER DEFAULT 0, chaleco INTEGER DEFAULT 0, paneles INTEGER DEFAULT 0,
          gps_garmin INTEGER DEFAULT 0, flecher INTEGER DEFAULT 0, observaciones TEXT)''',
        );
        return;
      }

      // CASO B: La tabla existe. Verificamos si tiene el error de tipeo "batterias"
      final columns = await db.rawQuery("PRAGMA table_info(comunicaciones)");
      bool tieneErrorBatterias = columns.any(
        (col) => col['name'] == 'batterias',
      );

      if (!tieneErrorBatterias) {
        // Si no tiene el error, verificamos si ya tiene la columna correcta "baterias"
        bool tieneBaterias = columns.any((col) => col['name'] == 'baterias');
        if (tieneBaterias) {
          print(
            "Tabla 'comunicaciones' ya está correcta. No se necesita reparación.",
          );
          return;
        }
      }

      // CASO C: Tiene el error. Procedemos a reparar transfiriendo datos
      print("Reparando tabla 'comunicaciones' (batterias -> baterias)...");

      await db.execute(
        '''CREATE TABLE IF NOT EXISTS comunicaciones_temp (
        id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, gdo TEXT, nombres TEXT, clase_radio TEXT, no_radio TEXT,
        antena_tubular INTEGER DEFAULT 0, antena_latigo INTEGER DEFAULT 0, arnes INTEGER DEFAULT 0, microtelefono INTEGER DEFAULT 0,
        bolso INTEGER DEFAULT 0, base_antena INTEGER DEFAULT 0, tapa_baterias INTEGER DEFAULT 0, base_latigo INTEGER DEFAULT 0,
        base_tubular INTEGER DEFAULT 0, antena_flexible INTEGER DEFAULT 0, baterias INTEGER DEFAULT 0, perillas INTEGER DEFAULT 0,
        cargador INTEGER DEFAULT 0, protector INTEGER DEFAULT 0, clip INTEGER DEFAULT 0, antena_gps INTEGER DEFAULT 0,
        cargador_apx INTEGER DEFAULT 0, antena_gps_5602 INTEGER DEFAULT 0, chaleco INTEGER DEFAULT 0, paneles INTEGER DEFAULT 0,
        gps_garmin INTEGER DEFAULT 0, flecher INTEGER DEFAULT 0, observaciones TEXT)''',
      );

      // Copiamos datos (usando batterias si existe, o 0 si no)
      String colBaterias = tieneErrorBatterias ? 'batterias' : '0';
      await db.execute('''INSERT INTO comunicaciones_temp 
        SELECT id, no, grd, gdo, nombres, clase_radio, no_radio, antena_tubular, antena_latigo, arnes, microtelefono,
        bolso, base_antena, tapa_baterias, base_latigo, base_tubular, antena_flexible, $colBaterias, perillas, cargador, protector,
        clip, antena_gps, cargador_apx, antena_gps_5602, chaleco, paneles, gps_garmin, flecher, observaciones 
        FROM comunicaciones''');

      await db.execute('DROP TABLE comunicaciones');
      await db.execute(
        'ALTER TABLE comunicaciones_temp RENAME TO comunicaciones',
      );

      print("Tabla 'comunicaciones' reparada exitosamente.");
    } catch (e) {
      print("Error durante la reparación de comunicaciones: $e");
    }
  }

  Future _createDataTables(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS minutas (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS inteligencia (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, medio TEXT, anotaciones TEXT, imagen TEXT, adjuntos TEXT)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS operacional (id INTEGER PRIMARY KEY AUTOINCREMENT, fecha TEXT, hora TEXT, asunto TEXT, anotaciones TEXT, imagen TEXT, adjuntos TEXT)',
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS armamento (id INTEGER PRIMARY KEY AUTOINCREMENT, clase TEXT NOT NULL UNIQUE, cargo INTEGER DEFAULT 0, mano INTEGER DEFAULT 0, deposito INTEGER DEFAULT 0, total INTEGER DEFAULT 0, observaciones TEXT)',
    );

    await db.execute(
      '''CREATE TABLE IF NOT EXISTS inventario_armamento (
      id INTEGER PRIMARY KEY AUTOINCREMENT, categoria TEXT, grd TEXT, apellidos_nombres TEXT, n_arma TEXT,
      municion_556 INTEGER DEFAULT 0, proveedores_556 INTEGER DEFAULT 0, municion_esl_556 INTEGER DEFAULT 0,
      municion_esl_762 INTEGER DEFAULT 0, canon INTEGER DEFAULT 0, granada_mano INTEGER DEFAULT 0,
      granada_60 INTEGER DEFAULT 0, granada_humo INTEGER DEFAULT 0, bengalas INTEGER DEFAULT 0,
      granada_lacrimogena INTEGER DEFAULT 0, trampa_iluminacion INTEGER DEFAULT 0, granada_aturdidora INTEGER DEFAULT 0,
      porta_arma INTEGER DEFAULT 0, casco INTEGER DEFAULT 0, foto_patrimonio TEXT, observaciones TEXT)''',
    );

    // ✅ CORREGIDO: "baterias" escrito correctamente
    await db.execute(
      '''CREATE TABLE IF NOT EXISTS comunicaciones (
      id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, gdo TEXT, nombres TEXT, clase_radio TEXT, no_radio TEXT,
      antena_tubular INTEGER DEFAULT 0, antena_latigo INTEGER DEFAULT 0, arnes INTEGER DEFAULT 0, microtelefono INTEGER DEFAULT 0,
      bolso INTEGER DEFAULT 0, base_antena INTEGER DEFAULT 0, tapa_baterias INTEGER DEFAULT 0, base_latigo INTEGER DEFAULT 0,
      base_tubular INTEGER DEFAULT 0, antena_flexible INTEGER DEFAULT 0, baterias INTEGER DEFAULT 0, perillas INTEGER DEFAULT 0,
      cargador INTEGER DEFAULT 0, protector INTEGER DEFAULT 0, clip INTEGER DEFAULT 0, antena_gps INTEGER DEFAULT 0,
      cargador_apx INTEGER DEFAULT 0, antena_gps_5602 INTEGER DEFAULT 0, chaleco INTEGER DEFAULT 0, paneles INTEGER DEFAULT 0,
      gps_garmin INTEGER DEFAULT 0, flecher INTEGER DEFAULT 0, observaciones TEXT)''',
    );

    await db.execute('''CREATE TABLE IF NOT EXISTS expediente (
      id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, nombres TEXT, n_elemento TEXT,
      canino INTEGER DEFAULT 0, valium INTEGER DEFAULT 0, ecaex INTEGER DEFAULT 0, tubo_pvc INTEGER DEFAULT 0,
      tubo_metalico INTEGER DEFAULT 0, guindo_20m INTEGER DEFAULT 0, cuerda_50m INTEGER DEFAULT 0, gancho_3puntas INTEGER DEFAULT 0,
      boca_pato INTEGER DEFAULT 0, estuche_verde INTEGER DEFAULT 0, perla INTEGER DEFAULT 0, bolso_transporte INTEGER DEFAULT 0,
      auriculares INTEGER DEFAULT 0, tes_prueba INTEGER DEFAULT 0, unidad_electrica INTEGER DEFAULT 0, cabeza_busqueda INTEGER DEFAULT 0,
      pinzas_sog INTEGER DEFAULT 0, cargas_huecas INTEGER DEFAULT 0, pentolita_1kg INTEGER DEFAULT 0, pentolita_1_2kg INTEGER DEFAULT 0,
      pentolita_1_4kg INTEGER DEFAULT 0, mecha_lenta INTEGER DEFAULT 0, cordon_12gr INTEGER DEFAULT 0,
      detonador_comun INTEGER DEFAULT 0, cordon_6gr INTEGER DEFAULT 0, cordon_3gr INTEGER DEFAULT 0, detonadores_electric INTEGER DEFAULT 0,
      detonadores_inelectric INTEGER DEFAULT 0, observacion TEXT)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS inventario_especial (
      id INTEGER PRIMARY KEY AUTOINCREMENT, categoria TEXT, grd TEXT, apellidos_nombres TEXT, n_arma TEXT,
      m_762_eslb INTEGER DEFAULT 0, m_556_eslb INTEGER DEFAULT 0, m_762_sub INTEGER DEFAULT 0,
      m_9mm INTEGER DEFAULT 0, g_im26 INTEGER DEFAULT 0, g_humo INTEGER DEFAULT 0, g_40mm INTEGER DEFAULT 0,
      g_lacrimogena INTEGER DEFAULT 0, canon INTEGER DEFAULT 0, trampa_ilu INTEGER DEFAULT 0, casco_kevlar INTEGER DEFAULT 0,
      lentes INTEGER DEFAULT 0, prov_762 INTEGER DEFAULT 0, prov_9mm INTEGER DEFAULT 0, porta_arma INTEGER DEFAULT 0,
      supresor INTEGER DEFAULT 0, foto_path TEXT)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS inventario_miras (
      id INTEGER PRIMARY KEY AUTOINCREMENT, grd TEXT, apellidos_nombres TEXT, numero_avenida TEXT,
      numero_avn TEXT, numero_mira_mor TEXT, numero_miras_mor TEXT,
      numero_mira_nimrod TEXT, impronta_mira_nimrod TEXT, foto_path TEXT)''');

    await db.execute('''CREATE TABLE IF NOT EXISTS intendencia (
      id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, grado TEXT, apellidos_nombres TEXT,
      camuflado_1 TEXT, camuflado_2 TEXT, equipo_campana INTEGER DEFAULT 0, botas_par INTEGER DEFAULT 0,
      camisetas_verdes INTEGER DEFAULT 0, medias_negras INTEGER DEFAULT 0, marmita INTEGER DEFAULT 0,
      hamaca INTEGER DEFAULT 0, poncho_pixelado INTEGER DEFAULT 0, cintura INTEGER DEFAULT 0, cintela INTEGER DEFAULT 0, colchoneta INTEGER DEFAULT 0,
      estuche_jarro_cantimplora INTEGER DEFAULT 0, boxer INTEGER DEFAULT 0, toalla_verde INTEGER DEFAULT 0,
      foto_path TEXT, observaciones TEXT)''');

    await db.execute(
      '''CREATE TABLE IF NOT EXISTS personal (
      id INTEGER PRIMARY KEY AUTOINCREMENT, grado TEXT, nombre TEXT, apellido TEXT, rh TEXT,
      tipo_documento TEXT, numero_documento TEXT, fecha_nacimiento TEXT, ciudad_nacimiento TEXT,
      pais_nacimiento TEXT, sexo TEXT, direccion TEXT, telefono TEXT, correo TEXT, cargo TEXT,
      fecha_ingreso TEXT, estado TEXT, foto_path TEXT, nombre_padre TEXT, telefono_padre TEXT,
      nombre_madre TEXT, telefono_madre TEXT, nombre_hijo TEXT, contacto_emergencia TEXT, telefono_emergencia TEXT)''',
    );

    await db.execute('''CREATE TABLE IF NOT EXISTS exde (
      id INTEGER PRIMARY KEY AUTOINCREMENT, no INTEGER, grd TEXT, nombres TEXT, n_elemento TEXT,
      canino INTEGER DEFAULT 0, valom INTEGER DEFAULT 0, ecaex INTEGER DEFAULT 0, tubo_pvc INTEGER DEFAULT 0,
      tubo_metalico INTEGER DEFAULT 0, guindo_20m INTEGER DEFAULT 0, cuerda_50m INTEGER DEFAULT 0, gancho_3puntas INTEGER DEFAULT 0,
      boca_pato INTEGER DEFAULT 0, estuche_verde INTEGER DEFAULT 0, pera INTEGER DEFAULT 0, bolso_transporte INTEGER DEFAULT 0,
      auriculares INTEGER DEFAULT 0, tes_prueba INTEGER DEFAULT 0, unidad_electrica INTEGER DEFAULT 0, cabeza_busqueda INTEGER DEFAULT 0,
      pinzas_sog INTEGER DEFAULT 0, cargas_huecas INTEGER DEFAULT 0, pentolita_1kg INTEGER DEFAULT 0, pentolita_1_2kg INTEGER DEFAULT 0,
      pentolita_1_4kg INTEGER DEFAULT 0, pentolita_1_8kg INTEGER DEFAULT 0, mecha_lenta INTEGER DEFAULT 0, cordon_12gr INTEGER DEFAULT 0,
      detonador_comun INTEGER DEFAULT 0, cordon_6gr INTEGER DEFAULT 0, cordon_3gr INTEGER DEFAULT 0, detonadores_elec INTEGER DEFAULT 0,
      detonadores_inelec INTEGER DEFAULT 0, observacion TEXT)''');
  }

  Future<void> _ejecutarSeguro(Database db, String sql) async {
    try {
      await db.execute(sql);
    } catch (e) {
      print("Info SQL (ignorado si existe): $e");
    }
  }
}
