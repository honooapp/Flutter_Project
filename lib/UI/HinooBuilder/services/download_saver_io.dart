import 'dart:io';

import 'package:honoo/env/env.dart';
import 'package:share_plus/share_plus.dart';

import 'download_saver_base.dart';

class _DownloadSaverIo implements DownloadSaver {
  @override
  Future<String> save(List<DownloadImage> images, {String? message}) async {
    if (images.isEmpty) {
      return 'Nessuna immagine da scaricare.';
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final List<XFile> files = images
          .map((img) => XFile.fromData(
                img.bytes,
                name: img.filename,
                mimeType: 'image/png',
              ))
          .toList(growable: false);
      await Share.shareXFiles(files, text: message ?? '');
      return 'Condividi o salva le immagini dalle opzioni di sistema.';
    }

    final Directory targetDir = await _resolveDownloadDirectory();
    final List<String> savedPaths = <String>[];
    for (final DownloadImage img in images) {
      final String filePath = _joinPaths(targetDir.path, img.filename);
      final File file = File(filePath);
      await file.writeAsBytes(img.bytes, flush: true);
      savedPaths.add(file.path);
    }
    return 'Immagini salvate in ${targetDir.path}';
  }

  Future<Directory> _resolveDownloadDirectory() async {
    final String folderName = 'hinoo_${DateTime.now().millisecondsSinceEpoch}';
    Directory? base;
    if (Platform.isMacOS || Platform.isLinux) {
      final String home = readEnv('HOME');
      if (home.isNotEmpty) {
        final Directory downloads = Directory(_joinPaths(home, 'Downloads'));
        if (downloads.existsSync()) base = downloads;
      }
    } else if (Platform.isWindows) {
      final String userProfile = readEnv('USERPROFILE');
      if (userProfile.isNotEmpty) {
        final Directory downloads =
            Directory(_joinPaths(userProfile, 'Downloads'));
        if (downloads.existsSync()) base = downloads;
      }
    }

    base ??= await Directory.systemTemp.createTemp('hinoo_download_base_');
    final Directory target = Directory(_joinPaths(base.path, folderName));
    if (!target.existsSync()) {
      await target.create(recursive: true);
    }
    return target;
  }

  String _joinPaths(String parent, String child) {
    if (parent.endsWith(Platform.pathSeparator)) {
      return '$parent$child';
    }
    return '$parent${Platform.pathSeparator}$child';
  }
}

DownloadSaver getDownloadSaverImpl() => _DownloadSaverIo();
