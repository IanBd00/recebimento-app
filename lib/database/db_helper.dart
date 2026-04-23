import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), 'recebimento.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE pendencias(id INTEGER PRIMARY KEY AUTOINCREMENT, codigo_dun14 TEXT, data_hora TEXT)",
        );
      },
    );
  }

  static Future<void> salvarOffline(String dun14) async {
    final db = await initDb();
    await db.insert('pendencias', {
      'codigo_dun14': dun14,
      'data_hora': DateTime.now().toIso8601String(),
    });
  }
}