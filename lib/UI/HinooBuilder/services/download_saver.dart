import 'download_saver_base.dart';
import 'download_saver_io.dart'
    if (dart.library.html) 'download_saver_web.dart';

export 'download_saver_base.dart';

DownloadSaver getDownloadSaver() => getDownloadSaverImpl();
