import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:diacritic/diacritic.dart';
import 'package:dio/dio.dart';
import 'package:filesize/filesize.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:encrypt/encrypt.dart' as enc;

enum DownloadAction { download, resume }

class MusicProvider extends ChangeNotifier {
  List<File> mp3Files = [];
  Map<String, double> progressValueMap = {};
  Map<String, String> localNotifierMap = {};
  List<MediaItem> mediaItems = [];
  List<MediaItem> decryptedMediaItems = [];
  String fileProcessResult = '';
  bool _isGranted = true;

  bool get isGranted => _isGranted;

  set isGranted(bool value) {
    _isGranted = value;
    notifyListeners();
  }

  String fileLocalRouteStr = '';
  Dio dio = Dio();
  List<int> sizes = [];

  //CancelToken cancelToken = CancelToken();

  //late double? percentNotifier = null;
  //late String? localNotifier = null;
  ////////////////////////////////

  /*String fileUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4';*/
/*
  String fileLocalRouteStr = '';
  Dio dio = Dio();
  Directory? dir;
  CancelToken cancelToken = CancelToken();
  late var percentNotifier = null;
  late var localNotifier = null;
  List<int> sizes = [];


 */
/* initializeLocalStorageRoute() async {
    dir = await getCacheDirectory();
    notifyListeners();
  }*/ /*


 */
/* deleteLocal() {
    localNotifier = null;
    percentNotifier = null;
    dir!.deleteSync(recursive: true);
    notifyListeners();
  }*/ /*


  checkOnLocal({
    required String fileUrl,
    required String fileLocalRouteStr,
  }) async {
    debugPrint('_checkOnLocal()...');
    localNotifier = '';
    File localFile = File(fileLocalRouteStr);
    String dir = path.dirname(fileLocalRouteStr);
    String basename = path.basenameWithoutExtension(fileLocalRouteStr);
    String extension = path.extension(fileLocalRouteStr);

    String localRouteToSaveFileStr = fileLocalRouteStr;
    sizes.clear();
    notifyListeners();
    int sumSizes = 0;
    int fileOriginSize = 0;
    bool fullFile = false;

    Response response = await dio.head(fileUrl);
    fileOriginSize = int.parse(response.headers.value('content-length')!);
    String localText = 'fileOriginSize: ${filesize(fileOriginSize)}\n\n';

    bool existsSync = localFile.existsSync();
    if (!existsSync) {
      localText += 'File "$basename$extension" does not exist \nin: "$dir"';
    } else {
      int fileLocalSize = localFile.lengthSync();
      sizes.add(fileLocalSize);
      notifyListeners();
      localText +=
      'localFile: "$basename$extension", fileLocalSize: ${filesize(fileLocalSize)}';

      int i = 1;
      localRouteToSaveFileStr = '$dir/$basename' '_$i$extension';
      File f = File(localRouteToSaveFileStr);
      while (f.existsSync()) {
        int tSize = f.lengthSync();
        sizes.add(tSize);
        notifyListeners();
        localText += '\nchunk: "$basename'
            '_$i$extension", fileLocalSize: ${filesize(tSize)}';
        i++;
        localRouteToSaveFileStr = '$dir/$basename' '_$i$extension';
        f = File(localRouteToSaveFileStr);
      }

      sumSizes = sizes.fold(0, (p, c) => p + c);
      localText +=
      '\n\nsize: ${filesize(sumSizes)}/${filesize(fileOriginSize)}';
      localText += '\nbytes: $sumSizes/$fileOriginSize';
      localText += '\n${(sumSizes / fileOriginSize * 100).toStringAsFixed(2)}%';
      fullFile = sumSizes == fileOriginSize;
    }
    double percent = sumSizes / fileOriginSize;
    localNotifier = localText;
    percentNotifier = fullFile ? 1 : percent == 0 ? null : percent;
  }

  cancel(String fileUrl) {
    cancelToken.cancel();
    percentNotifier = null;
    checkOnLocal(fileUrl: fileUrl, fileLocalRouteStr: fileLocalRouteStr);
  }

  onReceiveProgress(int received, int total) {
    if (!cancelToken.isCancelled) {
      int sum = sizes.fold(0, (p, c) => p + c);
      received += sum;

      percentNotifier = received / total;
      debugPrint(
          'percentNotifier: ${(percentNotifier * 100).toStringAsFixed(2)}');
    } else {
      debugPrint(
          'percentNotifier [AFTER CANCELED]: ${(percentNotifier * 100).toStringAsFixed(2)}');
    }
  }

  download(String fileUrl) {
    localNotifier = null;
    percentNotifier = 0;
    //fileUrl = urlTextEditingCtrl.text;
    fileLocalRouteStr = (dir != null) ? getLocalCacheFilesRoute(fileUrl, dir!) : '';

    getItemFileWithProgress(
        fileUrl: fileUrl, fileLocalRouteStr: fileLocalRouteStr);
  }

  Future<File?> getItemFileWithProgress({
    required String fileUrl,
    required String fileLocalRouteStr,
  }) async {
    debugPrint('getItemFileWithProgress()...');

    File localFile = File(fileLocalRouteStr);
    String dir = path.dirname(fileLocalRouteStr);
    String basename = path.basenameWithoutExtension(fileLocalRouteStr);
    String extension = path.extension(fileLocalRouteStr);

    String localRouteToSaveFileStr = fileLocalRouteStr;
    sizes.clear();
    notifyListeners();
    Response response = await dio.head(fileUrl);
    int fileOriginSize = int.parse(response.headers.value('content-length')!);
    Options? options;

    bool existsSync = localFile.existsSync();
    if (existsSync) {
      // Response response = await dio.head(fileUrl);
      // fileOriginSize = int.parse(response.headers.value('content-length')!);

      int fileLocalSize = localFile.lengthSync();
      sizes.add(fileLocalSize);
notifyListeners();
      int i = 1;
      localRouteToSaveFileStr = '$dir/$basename' '_$i$extension';
      File f = File(localRouteToSaveFileStr);
      while (f.existsSync()) {
        sizes.add(f.lengthSync());
        notifyListeners();
        i++;
        localRouteToSaveFileStr = '$dir/$basename' '_$i$extension';
        f = File(localRouteToSaveFileStr);
      }

      int sumSizes = sizes.fold(0, (p, c) => p + c);
      if (sumSizes < fileOriginSize) {
        options = Options(
          headers: {'Range': 'bytes=$sumSizes-'},
        );
      } else {
        percentNotifier = 1;

        debugPrint(
            'percentNotifier [ALREADY DOWNLOADED]: ${(percentNotifier * 100).toStringAsFixed(2)}');
        if (sizes.length == 1) {
          debugPrint('percentNotifier [ALREADY DOWNLOADED - ONE FILE]');
          checkOnLocal(fileUrl: fileUrl, fileLocalRouteStr: fileLocalRouteStr);
          return localFile;
        }
      }
    }

    if ((percentNotifier ?? 0) < 1) {
      if (cancelToken.isCancelled) {
        cancelToken = CancelToken();
      }

      try {
        await dio.download(fileUrl, localRouteToSaveFileStr,
            options: options,
            cancelToken: cancelToken,
            deleteOnError: false,
            onReceiveProgress: (int received, int total) =>
                onReceiveProgress(received, fileOriginSize));
      } catch (e) {
        debugPrint('..dio.download()...ERROR: "${e.toString()}"');
        return null;
      }
    }

    if (existsSync) {
      debugPrint('[ALREADY DOWNLOADED - MERGING FILES]');
      var raf = await localFile.open(mode: FileMode.writeOnlyAppend);

      int i = 1;
      String filePartLocalRouteStr = '$dir/$basename' '_$i$extension';
      File f = File(filePartLocalRouteStr);
      while (f.existsSync()) {
        raf = await raf.writeFrom(await f.readAsBytes());
        await f.delete();

        i++;
        filePartLocalRouteStr = '$dir/$basename' '_$i$extension';
        f = File(filePartLocalRouteStr);
      }
      await raf.close();
    }

    checkOnLocal(fileUrl: fileUrl, fileLocalRouteStr: fileLocalRouteStr);
    return localFile;
  }
*/

  /////////////////////

  Future<Directory?> get getExternalVisibleDir async {
    if (await Directory(
            '/storage/emulated/0/Android/data/com.example.play_music_background/MyEncFolder')
        .exists()) {
      final externalDir = Directory(
          '/storage/emulated/0/Android/data/com.example.play_music_background/MyEncFolder');
      return externalDir;
    } else {
      await Directory(
              '/storage/emulated/0/Android/data/com.example.play_music_background/MyEncFolder')
          .create(recursive: true);
      final externalDir = Directory(
          '/storage/emulated/0/Android/data/com.example.play_music_background/MyEncFolder');
      return externalDir;
    }
  }

  requestStoragePermission() async {
    if (!await Permission.storage.isGranted) {
      PermissionStatus result = await Permission.storage.request();
      if (result.isGranted) {
        isGranted = true;
      } else {
        isGranted = false;
      }
      notifyListeners();
    }
  }

  Future<void> loadTempFiles() async {
    final List<File> files = await getAllTempFiles();
    mp3Files = files;
    notifyListeners();
  }

  isFileInList(String fileName, List<File> mp3Files) {
    for (int i = 0; i < mp3Files.length; i++) {
      if (fileName ==
          mp3Files[i].path.substring(mp3Files[i].path.lastIndexOf('/') + 1)) {
        return true;
      }
    }
    return false;
  }

  Future<List<File>> getAllTempFiles() async {
    final Directory tempDir = await getTemporaryDirectory();
    final List<FileSystemEntity> files = tempDir.listSync(recursive: true);
    final List<File> mp3Files = files
        .where((file) =>
            file.path.endsWith('.mp3') &&
            FileSystemEntity.isFileSync(file.path))
        .map((file) => File(file.path))
        .toList();
    return mp3Files;
  }

  addDecryptedMediaItems(MediaItem mediaItem) {
    decryptedMediaItems.add(mediaItem);
    notifyListeners();
  }

  String getBaseUrl(pUrl) {
    final parse = Uri.parse(pUrl);
    final uri = parse.query != '' ? parse.replace(query: '') : parse;
    String url = uri.toString();
    if (url.endsWith('?')) url = url.replaceAll('?', '');
    return url;
  }

  String getLocalCacheFilesRoute(String url, Directory dir) {
    String temporaryDirectoryPath = dir.path;
    url = removeDiacritics(Uri.decodeFull(url)).replaceAll(' ', '_');
    var baseUrl = getBaseUrl(url);
    String fileBaseName = path.basename(baseUrl);
    return path.join(temporaryDirectoryPath, 'Files', fileBaseName);
  }

/*  getCacheDirectory() async {
    return await getTemporaryDirectory();
  }*/

//downloading using http client
/* Future<void> downloadAndCreate(Map<String, dynamic> song, Directory? d,
      AudioHandler audioHandler, int index) async {
    if (await canLaunchUrl(Uri.parse(song['url']))) {
      if (kDebugMode) {
        print('Data downloading...');
      }
      var request = await HttpClient().getUrl(Uri.parse(song['url']));
      var response = await request.close();
      var length = response.contentLength;
      var bytes = <int>[];
      var received = 0;

      response.listen(
        (List<int> newBytes) {
          bytes.addAll(newBytes);
          received += newBytes.length;
          double progress = received / length;
          progressValue = progress;
          progressValueMap['$index'] = progressValue;
          notifyListeners();
          if (kDebugMode) {
            print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
          }
        },
        onDone: () async {
          var encResult = _encryptData(Uint8List.fromList(bytes));
          String p = await _writeData(
              encResult, '${d!.path}/${song['title']}.mp3.aes');
          if (kDebugMode) {
            print('File Encrypted successfully...$p');
          }
          var filePath = await getNormalFile(d, '${song['title']}.mp3');
          song["url"] = filePath;
          final newMediaItem = MediaItem(
            id: song["id"],
            title: song["title"],
            album: song["album"],
            extras: {'url': song['url']},
            artUri: Uri.parse(song['artUri']!),
          );
          addDecryptedMediaItems(newMediaItem);
          audioHandler.addQueueItem(newMediaItem);
        },
        onError: (e) {
          if (kDebugMode) {
            print('Error downloading file: $e');
          }
        },
        cancelOnError: true,
      );
      notifyListeners();
    } else {
      if (kDebugMode) {
        print('Can\'t launch url');
      }
    }
  }*/

  //final download and cancel the download process code
/*  Future<void> downloadAndCreate(
      Map<String, dynamic> song,
      Directory? directory,
      AudioHandler audioHandler,
      int index,
      List<CancelToken> cancelTokens,
      ) async {

    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        song['url'],
        cancelToken: cancelTokens[index],
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (receivedBytes, totalBytes) {
          // Update progress and notify listeners
          final progress = receivedBytes / totalBytes;
          progressValue = progress;
          progressValueMap['$index'] = progressValue;
          if(kDebugMode){
            print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
          }
          notifyListeners();
        },
      );
      // The download completed successfully
      final encryptedFileDestination = '${directory!.path}/${song['title']}.mp3.aes';
      final encResult = _encryptData(Uint8List.fromList(response.data!));
      final encryptedFileFinalPath = await _writeData(encResult, encryptedFileDestination);

      if (kDebugMode) {
        print('File Encrypted successfully...$encryptedFileFinalPath');
      }
      var filePath = await getNormalFile(directory, '${song['title']}.mp3');
      song["url"] = filePath;
      final newMediaItem = MediaItem(
        id: song['id'],
        title: song['title'],
        album: song['album'],
        extras: {'url': filePath},
        artUri: Uri.parse(song['artUri']!),
      );

      addDecryptedMediaItems(newMediaItem);
      audioHandler.addQueueItem(newMediaItem);

      notifyListeners();
    } on DioError catch (e) {
      if (CancelToken.isCancel(e)) {
        // Request was cancelled
        if(kDebugMode){
          print('${e.message}');
        }
        return;
      }

      if (kDebugMode) {
        print('Error downloading file: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading file: $e');
      }
    }
  }*/

//checking download
  Future<void> downloadAndCreate(
    Map<String, dynamic> song,
    Directory? directory,
    AudioHandler audioHandler,
    int index,
    List<CancelToken> cancelTokens,
    int downloadButtonPressedCount,
  ) async {
    fileLocalRouteStr = getLocalCacheFilesRoute(song['url'], directory!);
    notifyListeners();
    await getItemFileWithProgress(
      fileUrl: song['url'],
      fileLocalRouteStr: fileLocalRouteStr,
      index: index,
      directory: directory,
      song: song,
      audioHandler: audioHandler,
      cancelTokens: cancelTokens,
      downloadButtonPressedCount: downloadButtonPressedCount,
    );

    /*final dio = Dio();
      final cancelToken = cancelTokens[index];
      final response = await dio.get<List<int>>(
        song['url'],
        cancelToken: cancelToken,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (receivedBytes, totalBytes) {
          final progress = receivedBytes / totalBytes;
          progressValue = progress;
          progressValueMap['$index'] = progressValue;
          if (kDebugMode) print('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
          notifyListeners();
        },
      );*/

/*

      final encryptedFileDestination = '${directory!.path}/${song['title']}.mp3.aes';
      final encResult = _encryptData(Uint8List.fromList(response.data!));
      final encryptedFileFinalPath = await _writeData(encResult, encryptedFileDestination);

      if (kDebugMode) print('File Encrypted successfully...$encryptedFileFinalPath');

      var filePath = await getNormalFile(directory, '${song['title']}.mp3');
      song['url'] = filePath;

      final newMediaItem = MediaItem(
        id: song['id'],
        title: song['title'],
        album: song['album'],
        extras: {'url': filePath},
        artUri: Uri.parse(song['artUri']!),
      );

      addDecryptedMediaItems(newMediaItem);
      audioHandler.addQueueItem(newMediaItem);

      notifyListeners();*/
  }

  Future<File?> getItemFileWithProgress({
    required String fileUrl,
    required String fileLocalRouteStr,
    required int index,
    required Directory? directory,
    required Map<String, dynamic> song,
    required AudioHandler audioHandler,
    required List<CancelToken> cancelTokens,
    required int downloadButtonPressedCount,
  }) async {
    debugPrint('getItemFileWithProgress()...');

    File localFile = File(fileLocalRouteStr);
    String dir = path.dirname(fileLocalRouteStr);

    String basename = path.basenameWithoutExtension(fileLocalRouteStr);

    String extension = path.extension(fileLocalRouteStr);

    String localRouteToSaveFileStr = fileLocalRouteStr;
    sizes.clear();
    notifyListeners();
    Response response = await dio.head(fileUrl);
    int fileOriginSize = int.parse(response.headers.value('content-length')!);
    Options? options;

    bool existsSync = localFile.existsSync();
    if (existsSync) {
      int fileLocalSize = localFile.lengthSync();
      sizes.add(fileLocalSize);
      notifyListeners();
      int i = 1;
      localRouteToSaveFileStr = '$dir/$basename' '_$i$extension';
      File f = File(localRouteToSaveFileStr);
      while (f.existsSync()) {
        sizes.add(f.lengthSync());
        notifyListeners();
        i++;
        localRouteToSaveFileStr = '$dir/$basename' '_$i$extension';
        f = File(localRouteToSaveFileStr);
      }

      int sumSizes = sizes.fold(0, (p, c) => p + c);
      if (sumSizes < fileOriginSize) {
        options = Options(
          headers: {'Range': 'bytes=$sumSizes-'},
        );
      } else {
        progressValueMap['$index'] = 1;
        notifyListeners();
        debugPrint(
            'percentNotifier [ALREADY DOWNLOADED]: ${(progressValueMap['$index']! * 100).toStringAsFixed(2)}');
        if (sizes.length == 1) {
          debugPrint('percentNotifier [ALREADY DOWNLOADED - ONE FILE]');
          checkOnLocal(
              fileUrl: fileUrl,
              fileLocalRouteStr: fileLocalRouteStr,
              index: index);
          return localFile;
        }
      }
    }

    if ((progressValueMap['$index'] ?? 0) < 1) {
      if (cancelTokens[index].isCancelled) {
        cancelTokens[index] = CancelToken();
      }

      try {
        await dio.download(fileUrl, localRouteToSaveFileStr,
            options: options,
            //options: Options(responseType: ResponseType.bytes),
            cancelToken: cancelTokens[index],
            deleteOnError: false,
            onReceiveProgress: (int received, int total) => onReceiveProgress(
                received, fileOriginSize, index, cancelTokens[index]));

        // The download completed successfully
// Read the file bytes using Dart's file handling API
        File file = File(localRouteToSaveFileStr);
        Uint8List fileBytes = await file.readAsBytes();
        final encryptedFileDestination = '${file.path}.aes';
        final encResult = _encryptData(fileBytes);
        final encryptedFileFinalPath =
            await _writeData(encResult, encryptedFileDestination);

        if (kDebugMode) {
          print('File Encrypted successfully...$encryptedFileFinalPath');
        }
        var filePath = await getNormalFile(
            encryptedFileDestination, '${song['title']}.mp3');

        song["url"] = filePath;
        final newMediaItem = MediaItem(
          id: song['id'],
          title: song['title'],
          album: song['album'],
          extras: {'url': filePath},
          artUri: Uri.parse(song['artUri']!),
        );

        addDecryptedMediaItems(newMediaItem);
        audioHandler.addQueueItem(newMediaItem);
        loadTempFiles();
        notifyListeners();
        if (downloadButtonPressedCount > 1) {
          File file2 = File('${directory!.path}/Files/${song['title']}.mp3');
          final baseFile = file2;
          deleteLocal(index, file);
          deleteLocalBaseFile(index, baseFile);
        }else{
          deleteLocal(index, file);
        }

      } catch (e) {
        debugPrint('..dio.download()...ERROR: "${e.toString()}"');
        return null;
      }
    }

    if (existsSync) {
      debugPrint('[ALREADY DOWNLOADED - MERGING FILES]');
      var raf = await localFile.open(mode: FileMode.writeOnlyAppend);

      int i = 1;
      String filePartLocalRouteStr = '$dir/$basename' '_$i$extension';
      File f = File(filePartLocalRouteStr);
      while (f.existsSync()) {
        raf = await raf.writeFrom(await f.readAsBytes());
        await f.delete();

        i++;
        filePartLocalRouteStr = '$dir/$basename' '_$i$extension';
        f = File(filePartLocalRouteStr);
      }
      await raf.close();
    }

    checkOnLocal(
        fileUrl: fileUrl, fileLocalRouteStr: fileLocalRouteStr, index: index);
    return localFile;
  }

  onReceiveProgress(
      int received, int total, int index, CancelToken cancelToken) {
    if (!cancelToken.isCancelled) {
      int sum = sizes.fold(0, (p, c) => p + c);
      received += sum;

      progressValueMap['$index'] = received / total;
      notifyListeners();
      debugPrint(
          'percentNotifier: ${(progressValueMap['$index']! * 100).toStringAsFixed(2)}');
    } else {
      debugPrint(
          'percentNotifier [AFTER CANCELED]: ${(progressValueMap['$index']! * 100).toStringAsFixed(2)}');
    }
  }

  cancel(Map<String, dynamic> song, int index, List<CancelToken> cancelTokens) {
    cancelTokens[index].cancel();
    checkOnLocal(
        fileUrl: song['url'],
        fileLocalRouteStr: fileLocalRouteStr,
        index: index);
  }

  deleteLocal(int index, File file) {
    progressValueMap['$index'] = 0;
    localNotifierMap['$index'] = '';
    notifyListeners();
    file.deleteSync(recursive: true);
  }

  deleteLocalBaseFile(int index,File baseFile) {
    baseFile.deleteSync(recursive: true);
  }
  checkOnLocal({
    required String fileUrl,
    required String fileLocalRouteStr,
    required int index,
  }) async {
    debugPrint('_checkOnLocal()...');
    localNotifierMap['$index'] = '';
    notifyListeners();
    File localFile = File(fileLocalRouteStr);
    String dir = path.dirname(fileLocalRouteStr);
    String basename = path.basenameWithoutExtension(fileLocalRouteStr);
    String extension = path.extension(fileLocalRouteStr);

    String localRouteToSaveFileStr = fileLocalRouteStr;
    sizes.clear();
    int sumSizes = 0;
    int fileOriginSize = 0;
    bool fullFile = false;

    Response response = await dio.head(fileUrl);
    fileOriginSize = int.parse(response.headers.value('content-length')!);
    String localText = 'fileOriginSize: ${filesize(fileOriginSize)}\n\n';

    bool existsSync = localFile.existsSync();
    if (!existsSync) {
      localText += 'File "$basename$extension" does not exist \nin: "$dir"';
    } else {
      int fileLocalSize = localFile.lengthSync();
      sizes.add(fileLocalSize);
      localText +=
          'localFile: "$basename$extension", fileLocalSize: ${filesize(fileLocalSize)}';

      int i = 1;
      localRouteToSaveFileStr = '$dir/$basename' '_$i$extension';
      File f = File(localRouteToSaveFileStr);
      while (f.existsSync()) {
        int tSize = f.lengthSync();
        sizes.add(tSize);
        localText += '\nchunk: "$basename'
            '_$i$extension", fileLocalSize: ${filesize(tSize)}';
        i++;
        localRouteToSaveFileStr = '$dir/$basename' '_$i$extension';
        f = File(localRouteToSaveFileStr);
      }

      sumSizes = sizes.fold(0, (p, c) => p + c);
      localText +=
          '\n\nsize: ${filesize(sumSizes)}/${filesize(fileOriginSize)}';
      localText += '\nbytes: $sumSizes/$fileOriginSize';
      localText += '\n${(sumSizes / fileOriginSize * 100).toStringAsFixed(2)}%';
      fullFile = sumSizes == fileOriginSize;
    }
    double percent = sumSizes / fileOriginSize;
    localNotifierMap['$index'] = localText;
    progressValueMap['$index'] = (fullFile
        ? 1
        : percent == 0
            ? 0
            : percent);
    notifyListeners();
  }

//Resume downloading
/*  void resumeDownload(
      Map<String, dynamic> song,
      Directory? directory,
      AudioHandler audioHandler,
      int index,
      List<CancelToken> cancelTokens,
      ) {
    if (filePaths.containsKey(index)) {
      final String? filePath = filePaths[index];
      if (filePath != null) {
        // Resume the download using the stored file path
        downloadAndCreate(song, directory, audioHandler, index, cancelTokens, filePath: filePath);
      }
    }
  }*/

  /* void cancelDownload(
    int index,
    List<CancelToken> cancelTokens,
  ) {
    cancelTokens[index].cancel('Cancelled');
    progressValueMap['$index'] = 0;
    notifyListeners();
    cancelTokens[index] = CancelToken();

  }*/

  Future<String> getNormalFile(
    String encryptedFileDestination,
    String fileName,
  ) async {
    try {
      Uint8List encData = await _readData(encryptedFileDestination);
      var plainData = await _decryptData(encData);
      var tempFile = await _createTempFile(fileName);

      tempFile.writeAsBytesSync(plainData);
      if (kDebugMode) {
        print('File Decrypted Successfully... ');
      }
      fileProcessResult = 'File Decrypted Successfully...';
      notifyListeners();
      return tempFile.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error : ${e.toString()}');
      }
      return '';
    }
  }

  Future<bool> checkIfFileExists(String filePath) async {
    File file = File(filePath);
    return await file.exists();
  }

  _encryptData(Uint8List plainString) {
    if (kDebugMode) {
      print('Encrypting File...');
    }

    final encrypted =
        MyEncrypt.myEncrypter.encryptBytes(plainString, iv: MyEncrypt.myIv);

    return encrypted.bytes;
  }

  _writeData(encResult, String fileNamedWithPath) async {
    if (kDebugMode) {
      print('Writing data...');
    }

    File f = File(fileNamedWithPath);
    await f.writeAsBytes(encResult);
    return f.absolute.toString();
  }

  _readData(String fileNamedWithPath) async {
    if (kDebugMode) {
      print('Reading data...');
    }

    File f = File(fileNamedWithPath);
    return await f.readAsBytes();
  }

  _decryptData(Uint8List encData) {
    if (kDebugMode) {
      print('File decryption in progress...');
    }
    enc.Encrypted en = enc.Encrypted(encData);
    return MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIv);
  }

  Future<File> _createTempFile(String fileName) async {
    final directory = await getTemporaryDirectory();
    final tempFilePath = '${directory.path}/$fileName';
    return File(tempFilePath);
  }
}

class MyEncrypt {
  static final myKey = enc.Key.fromUtf8('AshikujjamanAshikujjamanKazol299');
  static final myIv = enc.IV.fromUtf8('KazolAshikujjama');
  static final myEncrypter = enc.Encrypter(enc.AES(myKey));
}
