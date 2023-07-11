import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

import 'package:path/path.dart' as path;
import 'package:system_info2/system_info2.dart';
import 'dart:io' as io;
import '../page_manager.dart';
import '../play_song_screen.dart';
import '../providers/music_provider.dart';
import '../providers/theme_provider.dart';
import '../services/service_locator.dart';
import '../utils/global_functions.dart';
import '../utils/helper_functions.dart';

/*Future<int> useIsolate(int c) async{
  final ReceivePort receivePort = ReceivePort();

  try{
    await Isolate.spawn(runTask, [receivePort.sendPort,c]);
  } on Object{
    print("Isolate Failed");
    receivePort.close();
  }
  final response = await receivePort.first;
  print('isolate');
  print('data Processed ${response}');
  return response;
}

int runTask(List<dynamic> args){
  SendPort  resultPort = args[0];
  int value = 0;
  for(int i = 0;i<args[1];i++) {
    value=i++;
    print(value);
    Future.delayed(const Duration(milliseconds: 100));
  }
  Isolate.exit(resultPort,value);
}*/

class SongCard extends StatefulWidget {
  const SongCard({
    Key? key,
    required this.song,
    required this.index,
    required this.audioList,
  }) : super(key: key);

  final Map<String, dynamic> song;
  final int index;
  final List<dynamic> audioList;

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  final audioHandler = getIt<AudioHandler>();

  bool backResult = true;
  static const noFilesStr = 'No Files';

  final double maxAvailableMemory = 0.80; // Max limit of available memory
  final availableCores = Platform.numberOfProcessors;

  DateTime? before;
  int? minSpeed;
  int? maxSpeed;
  int sumPrevSize = 0;

  String fileLocalRouteStr = '';
  Dio dio = Dio();
  Directory? dir;
  TextEditingController urlTextEditingCtrl = TextEditingController();

  List<CancelToken> cancelTokenList = [];
  List<DateTime> percentUpdate = [];

  final percentTotalNotifier = ValueNotifier<double?>(null);
  final percentNotifier = ValueNotifier<List<ValueNotifier<double?>>?>(null);
  final speedNotifier = ValueNotifier<double?>(null);
  final multipartNotifier = ValueNotifier<bool>(false);
  final localNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    //cancelTokens = List.generate(artUriList.length, (_) => CancelToken());
    initializeLocalStorageRoute();
    super.initState();
  }

  @override
  void dispose() {
    audioHandler.customAction('dispose');
    super.dispose();
  }

  initializeLocalStorageRoute() async {
    dir = await getCacheDirectory();
    debugPrint('initState() - dir: "${dir?.path}"');
  }

  _download(String fileUrl, Map<String, dynamic> song,
      MusicProvider musicProvider, int songIndex) async {
    before = DateTime.now();
    debugPrint('_download()...');
    localNotifier.value = null;
    percentNotifier.value = [];
    percentTotalNotifier.value = 0;
    percentUpdate = [];
    cancelTokenList.clear();
    speedNotifier.value = null;
    minSpeed = null;
    maxSpeed = null;
    fileUrl;

    fileLocalRouteStr = getLocalCacheFilesRoute(fileUrl, dir!);
    final File file = File(fileLocalRouteStr);

    String fileBasename = path.basename(fileLocalRouteStr);
    String fileDir = path.dirname(fileLocalRouteStr);
    final bool fileLocalExists = file.existsSync();
    final int fileLocalSize = fileLocalExists ? file.lengthSync() : 0;
    final int? fileOriginSize = await _getOriginFileSize(fileUrl);
    final int maxMemoryUsage = await _getMaxMemoryUsage();

    if (fileOriginSize == null) {
      _cancel(fileUrl);
      return;
    }

    int optimalMaxParallelDownloads = 1;
    int chunkSize = fileOriginSize;
    if (true) {
      optimalMaxParallelDownloads =
          _calculateOptimalMaxParallelDownloads(fileOriginSize, maxMemoryUsage);
      chunkSize = (chunkSize / optimalMaxParallelDownloads).ceil();

      File chunkSizeFile = File('$fileDir/_chunkSize');
      if (!chunkSizeFile.existsSync()) {
        debugPrint('_download() - Creating chunkSizeFile...');
        chunkSizeFile.createSync(recursive: true);
        chunkSizeFile.writeAsStringSync(chunkSize.toString());
        debugPrint('_download() - Creating chunkSizeFile... DONE');
      } else {
        debugPrint('_download() - Reading chunkSize from chunkSizeFile...');
        chunkSize = int.parse(chunkSizeFile.readAsStringSync());
      }

      File optimalMaxParallelDownloadsFile =
          File('$fileDir/_maxParallelDownloads');
      if (!optimalMaxParallelDownloadsFile.existsSync()) {
        debugPrint('_download() - Creating optimalMaxParallelDownloadsFile...');
        optimalMaxParallelDownloadsFile.createSync(recursive: true);
        optimalMaxParallelDownloadsFile
            .writeAsStringSync(optimalMaxParallelDownloads.toString());
        debugPrint(
            '_download() - Creating optimalMaxParallelDownloadsFile... DONE');
      } else {
        debugPrint(
            '_download() - Reading optimalMaxParallelDownloads from optimalMaxParallelDownloadsFile...');
        optimalMaxParallelDownloads =
            int.parse(optimalMaxParallelDownloadsFile.readAsStringSync());
      }
    }

    debugPrint('_download() - fileBasename: "$fileBasename"');
    debugPrint('_download() - fileDir: "$fileDir"');
    debugPrint('_download() - fileLocalExists: "$fileLocalExists"');
    debugPrint(
        '_download() - fileLocalSize: "$fileLocalSize" (${filesize(fileLocalSize)})');
    debugPrint(
        '_download() - fileOriginSize: "$fileOriginSize" (${filesize(fileOriginSize)})');
    debugPrint('_download() - multipart: "${multipartNotifier.value}"');
    debugPrint(
        '_download() - maxMemoryUsage: "$maxMemoryUsage" (${filesize(maxMemoryUsage)})');
    debugPrint(
        '_download() - optimalMaxParallelDownloads: "$optimalMaxParallelDownloads"');
    debugPrint(
        '_download() - chunkSize: "$chunkSize" (${filesize(chunkSize)})');

    if (fileLocalSize < fileOriginSize) {
      String tBasename = path.basenameWithoutExtension(fileLocalRouteStr);

      final List<Future> tasks = [];
      List<ValueNotifier<double?>> tempNotifier = [];
      for (int i = 0; i < optimalMaxParallelDownloads; i++) {
        tempNotifier.add(ValueNotifier<double?>(null));
        percentNotifier.value = List.from(tempNotifier);
        cancelTokenList.add(CancelToken());
        percentUpdate.add(DateTime.now());
        final start = i * chunkSize;
        var end = (i + 1) * chunkSize - 1;
        if (fileLocalExists && end > fileLocalSize - 1) {
          end = fileLocalSize - 1;
        }

        String fileName = '$fileDir/$tBasename' '_$i';
        debugPrint(
            '_download() - [index: "$i"] - fileName: "${path.basename(fileName)}", fileOriginChunkSize: "${end - start}", start: "$start", end: "$end"');
        final Future<File?> task = getChunkFileWithProgress(
          fileUrl: fileUrl,
          fileLocalRouteStr: fileName,
          fileOriginChunkSize: end - start,
          start: start,
          end: end,
          index: i,
          songTitle: song['title'],
          songIndex: songIndex,
        );
        tasks.add(task);
      }

      List? results;
      try {
        debugPrint('_download() - TRY await Future.wait(tasks)...');
        results = await Future.wait(tasks);
      } catch (e) {
        debugPrint(
            '_download() - TRY await Future.wait(tasks) - ERROR: "${e.toString()}"');
        return;
      }
      debugPrint('_download() - TRY await Future.wait(tasks)...DONE');

      /// WRITE BYTES
      if (results.isNotEmpty) {
        debugPrint('_download() - MERGING...');
        for (File result in results) {
          debugPrint(
              '_download() - MERGING - file: "${path.basename(result.path)}"...');
          file.writeAsBytesSync(
            result.readAsBytesSync(),
            mode: FileMode.writeOnlyAppend,
          );
          result.delete();
        }
        debugPrint('_download() - MERGING...DONE');
      }

     /* await mergeAesFiles( fileDir, optimalMaxParallelDownloads,'${song['title']}');*/



    } else {
      percentNotifier.value = List.from([ValueNotifier<double>(1.0)]);
      debugPrint('_download() - [ALREADY DOWNLOADED]');
    }

    if (file.existsSync()) {
      debugPrint(
          '_download() - DONE - fileLocalRouteStr: "$fileLocalRouteStr"');
    } else {
      debugPrint('_download() - DONE - NO FILE');
    }
    DateTime after = DateTime.now();
    Duration diff = after.difference(before!);
    debugPrint('_download()... DURATION: \n'
        '${diff.inSeconds} seconds \n'
        '${diff.inMilliseconds} milliseconds');

    debugPrint('_download()... SPEED: '
        'min: "${filesize(minSpeed ?? 0)} / second", '
        'max: "${filesize(maxSpeed ?? 0)} / second" ');

    final totalElapsed =
        after.millisecondsSinceEpoch - before!.millisecondsSinceEpoch;

    /// CONVERT TO SECONDS AND GET THE SPEED IN BYTES PER SECOND
    final totalSpeed = file.lengthSync() / totalElapsed * 1000;
    debugPrint('_download()... SPEED: \n${filesize(totalSpeed.round())}ps');
    await _checkOnLocal(fileUrl: fileUrl, fileLocalRouteStr: fileLocalRouteStr);


    //After completing download notification showing
    showDownloadCompleteNotification(song['title'], songIndex);
    List<String> encryptedFilePaths = [];
    List<String> decryptedFilePaths = [];
    Future.delayed(const Duration(seconds: 50)).then((value) async {
        for(var i = 0; i < optimalMaxParallelDownloads; i++) {
           encryptedFilePaths.add('$fileDir/${song['title']}_$i.aes');
           decryptedFilePaths.add('/data/user/0/com.example.play_music_background/code_cache/${song['title']}_$i.mp3');
        }
        final mergedEncryptedFilePath = '$fileDir/${song['title']}.aes';
        final mergedDecryptedFilePath = '/data/user/0/com.example.play_music_background/code_cache/${song['title']}.mp3';
        await mergeAesFiles(encryptedFilePaths, mergedEncryptedFilePath);
        await mergeAesFiles(encryptedFilePaths, mergedDecryptedFilePath);
        for (String filePath in encryptedFilePaths) {
          removeFile(filePath);
        }
        for (String filePath in decryptedFilePaths) {
          removeFile(filePath);
        }
        song["url"] = mergedDecryptedFilePath;
        final newMediaItem = MediaItem(
          id: song['id'],
          title: song['title'],
          album: song['album'],
          extras: {'url': song["url"]},
          artUri: Uri.parse(song['artUri']!),
        );
        musicProvider.addDecryptedMediaItems(newMediaItem);
        audioHandler.addQueueItem(newMediaItem);
        print(newMediaItem);
        musicProvider.loadTempFiles();
        setState(() {});
        final pageManager = getIt<PageManager>();
        pageManager.play();

    });


    /*After Downloading completed successfully, encrytion decryption process will start*/
/*
    File fileForEncrypt = File(fileLocalRouteStr);
    Uint8List fileBytes = await fileForEncrypt.readAsBytes();
    final encryptedFileDestination = '${fileForEncrypt.path}.aes';

    final encResult = await useEncryptDataIsolate(fileBytes);

    final encryptedFileFinalPath = await useWriteDataIsolate(encResult, encryptedFileDestination);
    if (kDebugMode) {
      print('File Encrypted successfully...$encryptedFileFinalPath');
    }
    var filePath =
        await getNormalFile(encryptedFileDestination, '${song['title']}.mp3');

    song["url"] = filePath;
    final newMediaItem = MediaItem(
      id: song['id'],
      title: song['title'],
      album: song['album'],
      extras: {'url': filePath},
      artUri: Uri.parse(song['artUri']!),
    );
    musicProvider.addDecryptedMediaItems(newMediaItem);
    audioHandler.addQueueItem(newMediaItem);*/

    /*deleteLocal(fileForEncrypt);*/
  }

  void removeFile(String filePath) {
    final file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
      print('File deleted: $filePath');
    } else {
      print('File not found: $filePath');
    }
  }


  Future<void> mergeAesFiles(List<String> filePaths, String mergedFilePath) async {
    final mergedFile = File(mergedFilePath);
    final mergedFileAccess = await mergedFile.open(mode: FileMode.write);

    for (String filePath in filePaths) {
      final file = File(filePath);
      final fileAccess = await file.open(mode: FileMode.read);
      final fileSize = await file.length();

      await mergedFileAccess.writeFrom(await fileAccess.read(fileSize));
      await fileAccess.close();
    }

    await mergedFileAccess.close();
    if (kDebugMode) {
      print('File merged successfully...');
    }
  }

  Future<void> mergeDecryptedFiles(List<String> filePaths, String mergedFilePath) async {
    final mergedFile = File(mergedFilePath);
    final mergedFileAccess = await mergedFile.open(mode: FileMode.write);

    for (String filePath in filePaths) {
      final file = File(filePath);
      final fileAccess = await file.open(mode: FileMode.read);
      final fileSize = await file.length();

      await mergedFileAccess.writeFrom(await fileAccess.read(fileSize));
      await fileAccess.close();
    }

    await mergedFileAccess.close();
    if (kDebugMode) {
      print('Files merged successfully...');
    }
  }





/*  Future<void> mergeAesFiles(String sourceFolderPath, int totalParts,String songName) async {
    final mergedFile = File(sourceFolderPath);
    await mergedFile.parent.create(recursive: true);
    final mergedFileAccess = await mergedFile.open(mode: FileMode.write);
    print('called before');
    for (int i = 0; i < totalParts; i++) {
      print('called');
      final partFilePath = '$sourceFolderPath/${songName}_$i.aes';
      final partFile = File(partFilePath);
      print('partFile = $partFile');
      final partFileAccess = await partFile.open(mode: FileMode.read);

      const bufferSize = 64 * 1024; // 64KB buffer size (adjust as needed)
      final buffer = Uint8List(bufferSize);

      int bytesRead;
      while ((bytesRead = await partFileAccess.readInto(buffer)) > 0) {
        await mergedFileAccess.writeFrom(buffer, 0, bytesRead);
      }

      await partFileAccess.close();
    }

    await mergedFileAccess.close();
  }*/

  _cancel(String fileUrl) {
    for (CancelToken cancelToken in cancelTokenList) {
      cancelToken.cancel();
    }

    percentTotalNotifier.value = null;
    percentNotifier.value = null;
    speedNotifier.value = null;

    var dir = path.dirname(fileLocalRouteStr);
    int sumSizes = 0;
    final localDir = Directory(dir);

    if (localDir.existsSync()) {
      List<FileSystemEntity> files = localDir.listSync(
        recursive: true,
        followLinks: false,
      );

      for (FileSystemEntity file in files) {
        if (file is File) {
          sumSizes += file.lengthSync();
        }
      }
    }
    sumPrevSize = sumSizes;

    _checkOnLocal(fileUrl: fileUrl, fileLocalRouteStr: fileLocalRouteStr);
  }

  Future<int?> _getOriginFileSize(String url) async {
    int fileOriginSize = 0;

    /// GET ORIGIN FILE SIZE - BEGIN
    Response response = await dio
        .head(url, options: Options())
        .timeout(const Duration(seconds: 20));
    try {
      response = await dio.head(url);
    } on io.SocketException catch (_) {
      debugPrint(
          '_getOriginFileSize() - TRY dio.head() - ERROR: - SocketException');
      return null;
    } on TimeoutException catch (_) {
      debugPrint(
          '_getOriginFileSize() - TRY dio.head() - ERROR:  - TimeoutException');
      return null;
    } catch (e) {
      debugPrint(
          '_getOriginFileSize() - TRY dio.head() - ERROR: "${e.toString()}"');
      return null;
      // rethrow;
    }

    fileOriginSize = int.parse(response.headers.value('content-length')!);

    /// GET ORIGIN FILE SIZE - END

    return fileOriginSize;
  }

  Future<int> _getMaxMemoryUsage() async {
    final freePhysicalMemory = SysInfo.getFreePhysicalMemory();
    final maxMemoryUsage = (freePhysicalMemory * maxAvailableMemory).round();
    return maxMemoryUsage;
  }

  int _calculateOptimalMaxParallelDownloads(int fileSize, int maxMemoryUsage) {
    final maxPartSize = (maxMemoryUsage / availableCores).floor();
    final maxParallelDownloads = (fileSize / maxPartSize).ceil();

    final result = maxParallelDownloads > availableCores
        ? availableCores
        : ((maxParallelDownloads + availableCores) / 2).floor();

    return result;
  }

  _onReceiveProgress(int received, int total, index, sizes, String songTitle,
      int songIndex) async {
    var cancelToken = cancelTokenList.elementAt(index);
    if (!cancelToken.isCancelled) {
      int sum = sizes.fold(0, (p, c) => p + c);
      received += sum;
      var valueNew = received / total;
      percentNotifier.value?[index].value = valueNew;

      DateTime timeOld = percentUpdate[index];
      DateTime timeNew = DateTime.now();
      percentUpdate[index] = timeNew;
      final timeDifference = timeNew.difference(timeOld).inMilliseconds / 1000;

      List? percentList = percentNotifier.value;
      double? totalPercent =
          percentList?.fold(0, (p, c) => (p ?? 0) + (c.value ?? 0));
      totalPercent = totalPercent == null
          ? null
          : totalPercent / (percentList?.length ?? 1);
      totalPercent = (totalPercent ?? 0) > 1.0 ? 1.0 : totalPercent;
      percentTotalNotifier.value = totalPercent;

      if (timeDifference == 0) {
        return;
      }

      var dir = path.dirname(fileLocalRouteStr);
      int sumSizes = 0;
      final localDir = Directory(dir);

      if (localDir.existsSync()) {
        List<FileSystemEntity> files = localDir.listSync(
          recursive: true,
          followLinks: false,
        );

        for (FileSystemEntity file in files) {
          if (file is File) {
            sumSizes += file.lengthSync();
          }
        }
      }

      final totalElapsed = DateTime.now().millisecondsSinceEpoch -
          before!.millisecondsSinceEpoch;
      // Rest of your progress handling code goes here...

      /// CONVERT TO SECONDS AND GET THE SPEED IN BYTES PER SECOND

      final totalSpeed = (sumSizes - sumPrevSize) / totalElapsed * 1000;

      speedNotifier.value = totalSpeed;
      String percent = (valueNew * 100).toStringAsFixed(2);
      await performDownloading(valueNew, received, total, songTitle, songIndex);
      if ((percentNotifier.value?[index].value ?? 0).toInt() == 1){
         // Read file bytes
         String fileName = path.basenameWithoutExtension(fileLocalRouteStr);
         // Append the index value and underscore to the file name
         String modifiedFileName = '${fileName}_$index';
           final File newFile = File(path.join(path.dirname(fileLocalRouteStr), modifiedFileName));
           Uint8List fileBytes = await newFile.readAsBytes();

           // Encryption
           final encryptedFileDestination = '${newFile.path}.aes';
           final encResult = await useEncryptDataIsolate(fileBytes);
           await useWriteDataIsolate(encResult, encryptedFileDestination);
           // Decryption
         await getNormalFile(encryptedFileDestination, '$modifiedFileName.mp3');

      }
   /*   if (valueNew <= 0.2) {
        // Calculate the size of the first 20% of the data
        int first20PercentSize = (total * 0.2).toInt();
        await performDownloading(
            valueNew, received, total, songTitle, songIndex);
        // Read file bytes
        String fileName = path.basenameWithoutExtension(fileLocalRouteStr);
        // Append the index value and underscore to the file name
        String modifiedFileName = '${fileName}_$index';
        if (((received / total) * 100).round() ==
            ((first20PercentSize / total) * 100).round()) {
          final File newFile = File(
              path.join(path.dirname(fileLocalRouteStr), modifiedFileName));
          Uint8List fileBytes = await newFile.readAsBytes();

          // Encryption
          final encryptedFileDestination = '${newFile.path}_0.aes';
          final encResult = await useEncryptDataIsolate(fileBytes);
          final encryptedFileFinalPath =
              await useWriteDataIsolate(encResult, encryptedFileDestination);
        }
      }
      else if (valueNew > 0.2 && valueNew <= 0.4) {
        // Calculate the size range for 20% to 40%
        int first20PercentSize = (total * 0.2).toInt();
        int second20PercentSize = (total * 0.4).toInt();

        // Calculate the received data within the 20% to 40% range
        int receivedInRange = received - first20PercentSize;
        int downloadingPercentSize = second20PercentSize - first20PercentSize;
        // Perform your desired actions with the downloaded data within the range
        await performDownloading(
            valueNew, received, total, songTitle, songIndex);
        // Read file bytes
        String fileName = path.basenameWithoutExtension(fileLocalRouteStr);
        // Append the index value and underscore to the file name
        String modifiedFileName = '${fileName}_$index';
        if (((received / total) * 100).round() ==
            ((second20PercentSize / total) * 100).round()) {

            final File newFile = File(
              path.join(path.dirname(fileLocalRouteStr), modifiedFileName));
          Uint8List fileBytes = await newFile.readAsBytes();

          // Encryption
          final encryptedFileDestination = '${newFile.path}_1.aes';
          final encResult = await useEncryptDataIsolate(fileBytes);
          final encryptedFileFinalPath =
          await useWriteDataIsolate(encResult, encryptedFileDestination);
        }
      }
      else if (valueNew > 0.4 && valueNew <= 0.6) {
        // Calculate the size of the first 20% of the data
        // Calculate the size range for 20% to 40%
        int first40PercentSize = (total * 0.4).toInt();
        int second60PercentSize = (total * 0.6).toInt();

        // Calculate the received data within the 20% to 40% range
        int receivedInRange = received - first40PercentSize;
        int downloadingPercentSize = second60PercentSize - first40PercentSize;
        // Perform your desired actions with the downloaded data within the range
        await performDownloading(
            valueNew, received, total, songTitle, songIndex);
        print('third = $receivedInRange');
      }
      else if (valueNew > 0.6 && valueNew <= 0.8) {
        // Calculate the size of the first 20% of the data
        // Calculate the size range for 20% to 40%
        int first60PercentSize = (total * 0.6).toInt();
        int second80PercentSize = (total * 0.8).toInt();

        // Calculate the received data within the 20% to 40% range
        int receivedInRange = received - first60PercentSize;
        int downloadingPercentSize = second80PercentSize - first60PercentSize;
        // Perform your desired actions with the downloaded data within the range
        await performDownloading(
            valueNew, received, total, songTitle, songIndex);
        print('fourth = $receivedInRange');
      }
      else if (valueNew > 0.8 && valueNew <= 1.0) {
        // Calculate the size of the first 20% of the data
        // Calculate the size range for 20% to 40%
        int first80PercentSize = (total * 0.8).toInt();
        int second100PercentSize = total;

        // Calculate the received data within the 20% to 40% range
        int receivedInRange = received - first80PercentSize;
        int downloadingPercentSize = second100PercentSize - first80PercentSize;
        // Perform your desired actions with the downloaded data within the range
        await performDownloading(
            valueNew, received, total, songTitle, songIndex);
        print('final = $receivedInRange');
      }*/

      int speed = speedNotifier.value?.ceil() ?? 0;

      if (minSpeed == null || (minSpeed ?? 99999) > speed) {
        minSpeed = speed.round();
      }
      if (maxSpeed == null || (maxSpeed ?? -1) < speed) {
        maxSpeed = speed.round();
      }

      debugPrint('_onReceiveProgress(index: "$index")...'
          'percent: "$percent", '
          'speed: "${filesize(speed)} / second"');
    } else {
      debugPrint(
          '_onReceiveProgress(index: "$index")...percentNotifier [AFTER CANCELED]: ${(percentNotifier.value![index].value! * 100).toStringAsFixed(2)}');
    }
  }

  void updateDownloadProgressNotification(double progress, double downloadingMb,
      double totalMb, String songTitle, int index) async {
    FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_progress',
      'Download Progress',
      icon: 'ic_download',
      importance: Importance.high,
      priority: Priority.high,
      onlyAlertOnce: true,
      showWhen: false,
      showProgress: true,
      maxProgress: 100,
      progress: progress.toInt(),
    );
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Update the notification with the download progress
    await notifications.show(
      index,
      songTitle,
      '$downloadingMb MB / $totalMb MB',
      platformChannelSpecifics,
      payload: 'progress',
    );
  }

  void showDownloadCompleteNotification(String songTitle, int index) async {
    FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_complete',
      'Download Complete',
      icon: 'ic_check',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Show the download complete notification
    await notifications.show(
      index,
      'Downloading Completed',
      '$songTitle has been downloaded',
      platformChannelSpecifics,
      payload: 'complete',
    );
  }

  Future<File?> getChunkFileWithProgress({
    required String fileUrl,
    required String fileLocalRouteStr,
    required int fileOriginChunkSize,
    required String songTitle,
    required int songIndex,
    int start = 0,
    int? end,
    int index = 0,
  }) async {
    debugPrint('getChunkFileWithProgress(index: "$index")...');

    File localFile = File(fileLocalRouteStr);
    String dir = path.dirname(fileLocalRouteStr);
    String basename = path.basenameWithoutExtension(fileLocalRouteStr);

    debugPrint(
        'getChunkFileWithProgress(index: "$index") - basename: "$basename"...');
    String localRouteToSaveFileStr = fileLocalRouteStr;
    List<int> sizes = [];
    Options options = Options(
      headers: {'Range': 'bytes=$start-$end'},
    );

    bool existsSync = localFile.existsSync();
    debugPrint(
        'getChunkFileWithProgress(index: "$index") - existsChunk: "$existsSync');
    if (existsSync) {
      int fileLocalSize = localFile.lengthSync();
      debugPrint(
          'getChunkFileWithProgress(index: "$index") - existsChunk: "$basename", fileLocalSize: "$fileLocalSize" - ${filesize(fileLocalSize)}');
      sizes.add(fileLocalSize);

      int i = 1;
      localRouteToSaveFileStr = '$dir/$basename' '_$i.part';
      File f = File(localRouteToSaveFileStr);
      while (f.existsSync()) {
        int chunkSize = f.lengthSync();
        debugPrint(
            'getChunkFileWithProgress(index: "$index") - existsChunk: "$basename'
            '_$i.part", chunkSize: "$chunkSize" - ${filesize(chunkSize)}');
        sizes.add(chunkSize);
        i++;
        localRouteToSaveFileStr = '$dir/$basename' '_$i.part';
        f = File(localRouteToSaveFileStr);
      }

      int sumSizes = sizes.fold(0, (p, c) => p + c);
      if (sumSizes < fileOriginChunkSize) {
        debugPrint(
            'getChunkFileWithProgress(index: "$index") - CREATING Chunk: "$basename'
            '_$i.part"');
        int starBytes = start + sumSizes;
        debugPrint(
            'getChunkFileWithProgress(index: "$index") - FETCH Options: sumSizes: "$sumSizes", start: "$start", end: "$end"');
        debugPrint(
            'getChunkFileWithProgress(index: "$index") - FETCH Options: "bytes=$starBytes-$end"');
        options = Options(
          headers: {'Range': 'bytes=${start + sumSizes}-$end'},
        );
      } else {
        percentNotifier.value![index].value = 1.0;

        debugPrint(
            'getChunkFileWithProgress(index: "$index") - [ALREADY DOWNLOADED]');
        if (sizes.length == 1) {
          debugPrint(
              'getChunkFileWithProgress(index: "$index") - [ALREADY DOWNLOADED - ONE FILE]');
          // _checkOnLocal(fileUrl: fileUrl, fileLocalRouteStr: fileLocalRouteStr);
          return localFile;
        }
      }
    }

//download section
    if ((percentNotifier.value?[index].value ?? 0) < 1) {
      CancelToken cancelToken = cancelTokenList.elementAt(index);
      if (cancelToken.isCancelled) {
        cancelToken = CancelToken();
      }
      try {
        debugPrint(
            'getChunkFileWithProgress(index: "$index") - TRY dio.download()...');
        await dio.download(fileUrl, localRouteToSaveFileStr,
            options: options,
            cancelToken: cancelToken,
            deleteOnError: false,
            onReceiveProgress: (int received, int total) => _onReceiveProgress(
                received,
                fileOriginChunkSize,
                index,
                sizes,
                songTitle,
                songIndex));
      } catch (e) {
        debugPrint(
            'getChunkFileWithProgress(index: "$index") - TRY dio.download() - ERROR: "${e.toString()}"');
        rethrow;
      }
    }

    if (existsSync) {
      debugPrint(
          'getChunkFileWithProgress(index: "$index") - CHUNKS DOWNLOADED - MERGING FILES...');
      var raf = await localFile.open(mode: FileMode.writeOnlyAppend);

      int i = 1;
      String filePartLocalRouteStr = '$dir/$basename' '_$i.part';
      File f = File(filePartLocalRouteStr);
      while (f.existsSync()) {
        await raf.writeFrom(await f.readAsBytes());
        await f.delete();

        i++;
        filePartLocalRouteStr = '$dir/$basename' '_$i.part';
        f = File(filePartLocalRouteStr);
      }
      await raf.close();
    }

    debugPrint(
        'getChunkFileWithProgress(index: "$index") - RETURN FILE: "$basename"');
    return localFile;
  }

  _checkOnLocal({
    required String fileUrl,
    required String fileLocalRouteStr,
  }) async {
    debugPrint('_checkOnLocal()...');
    List<FileSystemEntity>? files;
    localNotifier.value = '';
    String dir = path.dirname(fileLocalRouteStr);
    int sumSizes = 0;

    debugPrint('_checkOnLocal() - _getOriginFileSize()...');
    int? fileOriginSize = await _getOriginFileSize(fileUrl);
    String localText = 'fileOriginSize: ${filesize(fileOriginSize)}\n';
    debugPrint(
        '_checkOnLocal() - fileOriginSize:"${filesize(fileOriginSize)}"');

    if (fileOriginSize == null) {
      localText = 'fileOriginSize: -\n';
      localNotifier.value = localText;
      return;
    }

    final localDir = Directory(dir);
    final localDirExists = localDir.existsSync();
    debugPrint('_checkOnLocal() - localDirExists:"$localDirExists"');
    if (localDirExists) {
      files = localDir.listSync(
        recursive: true,
        followLinks: false,
      );

      if (files.isEmpty) {
        localText += '\n$noFilesStr\n';
      } else {
        files.sort((a, b) => a.path.compareTo(b.path));
        for (FileSystemEntity file in files) {
          if (file is File) {
            String filepath = file.path;
            int tSize = file.lengthSync();
            sumSizes += tSize;

            String basename = path.basename(filepath);
            if (basename.startsWith('_')) {
              String value = file.readAsStringSync();
              localText += '\nFile: "$basename", Value: $value';
            } else {
              localText += '\nFile: "$basename", Size: ${filesize(tSize)}';
            }
          }
        }

        localText +=
            '\n\nSize: ${filesize(sumSizes)}/${filesize(fileOriginSize)}';
        localText += '\nBytes: $sumSizes/$fileOriginSize';
        localText +=
            '\n${(sumSizes / fileOriginSize * 100).toStringAsFixed(2)}%';
      }
    }

    if (files == null || files.isEmpty == true) {
      localText += '\n$noFilesStr\n';
    }
    localNotifier.value = localText;
  }

  /* deleteLocal(File file) {
    localNotifier.value = null;
    percentNotifier.value = null;
    percentTotalNotifier.value = null;
    speedNotifier.value = null;
    sumPrevSize = 0;
    file.deleteSync(recursive: true);
  }*/

  Future<String> getNormalFile(
    String encryptedFileDestination,
    String fileName,
  ) async {
    try {
      final encData = await useReadDataIsolate(encryptedFileDestination);
      var plainData = await useDecryptDataIsolate(encData);
      var tempFile = await useCreateTempFileIsolate(fileName);
      tempFile.writeAsBytesSync(plainData);
      if (kDebugMode) {
        print('File Decrypted Successfully... ');
      }
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final musicProvider = Provider.of<MusicProvider>(context, listen: false);
    var isFileLocal = musicProvider.isFileInList(
        '${widget.audioList[widget.index]['title']}.mp3',
        musicProvider.mp3Files);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        tileColor:
            themeProvider.isDarkMode ? Colors.grey.shade900 : Colors.white,
        leading: Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            color:
                themeProvider.isDarkMode ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30.0),
            child: CachedNetworkImage(
              imageUrl: widget.song['artUri'],
              fit: BoxFit.fitWidth,
              placeholder: (context, url) => const CircularProgressIndicator(
                  color: Colors.blue, strokeWidth: 2),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
        title: Text(
          widget.song['title'],
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color:
                    themeProvider.isDarkMode ? Colors.white : Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Text(
          widget.song['album'],
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
        ),

        //backResult is checking for file is downloading or just playing
        trailing: (isFileLocal)
            ? InkWell(
                child: const SizedBox(
                    height: 50,
                    width: 120,
                    child: Center(
                      child: Text(
                        'Play Now',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                        ),
                      ),
                    )),
                onTap: () async {
                  widget.song["url"] =
                      '/data/user/0/com.example.play_music_background/code_cache/${widget.song['title']}.mp3';

                  final newMediaItem = MediaItem(
                    id: widget.song["id"],
                    title: widget.song["title"],
                    album: widget.song["album"],
                    extras: {'url': widget.song['url']},
                    artUri: Uri.parse(widget.song['artUri']!),
                  );
                  audioHandler.addQueueItem(newMediaItem);
                  final pageManager = getIt<PageManager>();
                  pageManager.play();
                  if (mounted) {
                    bool? result = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PlaySongScreen(song: widget.song, justPlay: true),
                      ),
                    );

                    if (result != null) {
                      setState(() {
                        backResult = result;
                      });
                      //backResult is true
                    }
                  }
                },
              )
            : (backResult)
                ? InkWell(
                    onTap: () async {
                      final newMediaItem = MediaItem(
                        id: widget.song["id"],
                        title: widget.song["title"],
                        album: widget.song["album"],
                        extras: {'url': widget.song['url']},
                        artUri: Uri.parse(widget.song['artUri']!),
                      );
                      audioHandler.addQueueItem(newMediaItem);
                      final pageManager = getIt<PageManager>();
                      pageManager.play();
                      if (mounted) {
                        bool? result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaySongScreen(
                                song: widget.song, justPlay: false),
                          ),
                        );

                        if (result != null) {
                          setState(() {
                            backResult = result;
                          });
                          //backResult is false
                        }
                      }
                       _download(widget.song["url"], widget.song, musicProvider, widget.index);
                    },
                    child: const SizedBox(
                        height: 50,
                        width: 120,
                        child: Center(
                            child: Text(
                          'Play and Download',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ))),
                  )
                : SizedBox(
                    height: 50,
                    width: 100,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ValueListenableBuilder<List<ValueNotifier<double?>>?>(
                            valueListenable: percentNotifier,
                            builder: (context, percentList, _) {
                              double? totalPercent = percentList?.fold(
                                  0, (p, c) => (p ?? 0) + (c.value ?? 0));
                              totalPercent = totalPercent ?? 0;
                              if (percentList != null &&
                                  percentList.isNotEmpty) {
                                totalPercent =
                                    totalPercent / percentList.length;
                              }
                              totalPercent =
                                  (totalPercent > 1.0 ? 1.0 : totalPercent) *
                                      100;
                              if (percentList == null ||
                                  percentList.isEmpty == true) {
                                return const Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        value: 100,
                                        // color: Colors.grey,
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return ValueListenableBuilder<double?>(
                                  valueListenable: percentList.first,
                                  builder: (context, percent, _) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        SizedBox(
                                          width: 35,
                                          height: 35,
                                          child: CircularProgressIndicator(
                                            value:
                                                percent == 0 ? null : percent,
                                            valueColor: themeProvider.isDarkMode
                                                ? const AlwaysStoppedAnimation<
                                                    Color>(Colors.white)
                                                : AlwaysStoppedAnimation<Color>(
                                                    Colors.grey.shade900),
                                          ),
                                        ),
                                        Text(
                                          '${((percent ?? 0) * 100).toStringAsFixed(0)}%',
                                        ),
                                      ],
                                    );
                                  });
                            }),
                        ValueListenableBuilder<double?>(
                            valueListenable: percentTotalNotifier,
                            builder: (context, percent, _) {
                              return IconButton(
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.grey.shade900,
                                  iconSize: 35,
                                  //heroTag: null,
                                  onPressed: () async {
                                    percent == 0 || percent == 1
                                        ? null
                                        : percent == null
                                            ? {
                                                 _download(
                                                    widget.song["url"],
                                                    widget.song,
                                                    musicProvider,
                                                    widget.index),
                                              }
                                            : localNotifier.value != null
                                                ? _download(
                                                    widget.song["url"],
                                                    widget.song,
                                                    musicProvider,
                                                    widget.index)
                                                : _cancel(widget.song["url"]);
                                  },
                                  tooltip:
                                      percent == null ? 'Download' : 'Cancel',
                                  icon: (percent == 0)
                                      ? SizedBox(
                                          width: 60,
                                          child:
                                              Image.asset('assets/spinner.gif'),
                                        )
                                      : (percent == 1)
                                          ? const Icon(
                                              Icons.download_done_rounded)
                                          : (percent == null)
                                              ? const Icon(
                                                  Icons.download_rounded)
                                              : (localNotifier.value != null)
                                                  ? const Icon(
                                                      Icons.download_rounded)
                                                  : const Icon(
                                                      Icons.cancel_rounded));
                            }),
                      ],
                    ),
                  ),
        /* trailing: (isFileLocal)
            ? InkWell(
                onTap: () async {
                  widget.song["url"] =
                      '/data/user/0/com.example.play_music_background/cache/${widget.song['title']}.mp3';

                  final newMediaItem = MediaItem(
                    id: widget.song["id"],
                    title: widget.song["title"],
                    album: widget.song["album"],
                    extras: {'url': widget.song['url']},
                    artUri: Uri.parse(widget.song['artUri']!),
                  );
                  if (kDebugMode) {
                    print(musicProvider.decryptedMediaItems);
                  }
                  audioHandler.addQueueItem(newMediaItem);
                  final pageManager = getIt<PageManager>();
                  pageManager.play();
                  if (mounted) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlaySongScreen(song: widget.song),
                        ));
                  }
                },
                child: Container(
                  height: 50,
                  width: 50,
                  color: themeProvider.isDarkMode
                      ? Colors.grey.shade900
                      : Colors.white,
                  child: Icon(
                    Icons.play_circle,
                    color: themeProvider.isDarkMode
                        ? Colors.white
                        : Colors.grey.shade900,
                    size: 35,
                  ),
                ),
              )
            : SizedBox(
                height: 50,
                width: 100,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ValueListenableBuilder<List<ValueNotifier<double?>>?>(
                        valueListenable: percentNotifier,
                        builder: (context, percentList, _) {
                          double? totalPercent = percentList?.fold(
                              0, (p, c) => (p ?? 0) + (c.value ?? 0));
                          totalPercent = totalPercent ?? 0;
                          if (percentList != null && percentList.isNotEmpty) {
                            totalPercent = totalPercent / percentList.length;
                          }
                          totalPercent =
                              (totalPercent > 1.0 ? 1.0 : totalPercent) * 100;
                          if (percentList == null ||
                              percentList.isEmpty == true) {
                            return const Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    value: 100,
                                    // color: Colors.grey,
                                    color: Colors.transparent,
                                  ),
                                ),
                              ],
                            );
                          }
                          return ValueListenableBuilder<double?>(
                              valueListenable: percentList.first,
                              builder: (context, percent, _) {

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 35,
                                      height: 35,
                                      child: CircularProgressIndicator(
                                        value: percent == 0 ? null : percent,
                                        valueColor: themeProvider.isDarkMode
                                            ? const AlwaysStoppedAnimation<
                                                Color>(Colors.white)
                                            : AlwaysStoppedAnimation<Color>(
                                                Colors.grey.shade900),
                                      ),
                                    ),
                                    Text(
                                      '${((percent ?? 0) * 100).toStringAsFixed(0)}%',
                                    ),
                                  ],
                                );
                              });
                        }),
                    ValueListenableBuilder<double?>(
                        valueListenable: percentTotalNotifier,
                        builder: (context, percent, _) {
                          return IconButton(
                              color: themeProvider.isDarkMode
                                  ? Colors.white
                                  : Colors.grey.shade900,
                              iconSize: 35,
                              //heroTag: null,
                              onPressed: () {
                                percent == 0 || percent == 1
                                    ? null
                                    : percent == null
                                        ? {
                                            _download(widget.song["url"], widget.song, musicProvider),
                                          }
                                        : localNotifier.value != null
                                            ? _download(widget.song["url"],
                                                widget.song, musicProvider)
                                            : _cancel(widget.song["url"]);
                              },
                              tooltip: percent == null ? 'Download' : 'Cancel',
                              icon: (percent == 0)
                                  ? SizedBox(
                                      width: 60,
                                      child: Image.asset('assets/spinner.gif'),
                                    )
                                  : (percent == 1)
                                      ? const Icon(Icons.download_done_rounded)
                                      : (percent == null)
                                          ? const Icon(Icons.download_rounded)
                                          : (localNotifier.value != null)
                                              ? const Icon(
                                                  Icons.download_rounded)
                                              : const Icon(Icons.cancel_rounded)
                              );
                        }),
                  ],
                ),
              ),*/
      ),
    );
  }

 Future<void> performDownloading(double valueNew, int received, int total,
      String songTitle, int songIndex) async {
    var downloadingMb = (received / 1048576).toStringAsFixed(2);
    var totalMb = (total / 1048576).toStringAsFixed(2);
    updateDownloadProgressNotification(
      double.parse((valueNew * 100).toStringAsFixed(2)),
      double.parse(downloadingMb),
      double.parse(totalMb),
      songTitle,
      songIndex,
    );
  }
}
