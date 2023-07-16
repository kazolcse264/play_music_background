import 'package:flutter/material.dart';
import 'dart:io' show Directory;

import 'package:diacritic/diacritic.dart';
import 'package:path/path.dart' as path;


void showMsg(BuildContext context, String msg,{int? second}) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration:  Duration(
          seconds: second ?? 1,
        ),
      ),
    );

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

getCacheDirectory() async {
  //return await getTemporaryDirectory();
  //return await getExternalStorageDirectory();
  final Directory tempDir = Directory.systemTemp;
  return tempDir;
}

