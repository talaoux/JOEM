import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Écrit un CV (PDF ou image) dans le dossier `cvs/` de l'espace de
/// stockage persistant de l'app et retourne son chemin absolu — le CV vit
/// comme un vrai fichier sur le disque plutôt qu'en BLOB dans SQLite, pour
/// ne jamais dépasser la limite d'un `CursorWindow` Android (~2 Mo par
/// ligne) quand le fichier est un peu lourd (voir `AppDatabase`, migration
/// v10 -> v11).
Future<String> saveCvFile(Uint8List bytes, String fileName) async {
  final supportDir = await getApplicationSupportDirectory();
  final cvsDir = Directory('${supportDir.path}/cvs');
  if (!await cvsDir.exists()) {
    await cvsDir.create(recursive: true);
  }

  final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
  final path = '${cvsDir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
  await File(path).writeAsBytes(bytes, flush: true);
  return path;
}
