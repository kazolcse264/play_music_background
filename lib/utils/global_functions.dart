import 'dart:io';
import 'dart:isolate';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';

import '../providers/music_provider.dart';

Future<dynamic> useEncryptDataIsolate(Uint8List fileBytes,String encryptedFileDestination) async {
  final ReceivePort receivePort = ReceivePort();

  try {
    await Isolate.spawn(encryptData, [receivePort.sendPort, fileBytes,encryptedFileDestination]);
  } on Object {
    if (kDebugMode) {
      print("Isolate Failed");
    }
    receivePort.close();
  }
  final response = await receivePort.first;
  if (kDebugMode) {
    print('Encryption Done...');
  }
  return response;
}

Future<dynamic> useDecryptDataIsolate(Uint8List encData) async {
  final ReceivePort receivePort = ReceivePort();

  try {
    await Isolate.spawn(decryptData, [receivePort.sendPort, encData]);
  } on Object {
    if (kDebugMode) {
      print("Isolate Failed");
    }
    receivePort.close();
  }
  final response = await receivePort.first;
  return response;
}

Future<dynamic> useWriteDataIsolate(
    Uint8List fileBytes, String encryptedFileDestination) async {
  final ReceivePort receivePort = ReceivePort();

  try {
    await Isolate.spawn(
        writeData, [receivePort.sendPort, fileBytes, encryptedFileDestination]);
  } on Object {
    if (kDebugMode) {
      print("Isolate Failed");
    }
    receivePort.close();
  }
  final response = await receivePort.first;
  if (kDebugMode) {
    print('Encryption Done...');
  }
  return response;
}

Future<dynamic> useReadDataIsolate(String encryptedFileDestination) async {
  final ReceivePort receivePort = ReceivePort();
  if (kDebugMode) {
    print('File path: $encryptedFileDestination');
  }
  try {
    await Isolate.spawn(
        readData, [receivePort.sendPort, encryptedFileDestination]);
  } on Object {
    if (kDebugMode) {
      print("Isolate Failed");
    }
    receivePort.close();
  }

  final response = await receivePort.first;
  return response;
}

Future<File> useCreateTempFileIsolate(String fileName) async {
  final ReceivePort receivePort = ReceivePort();

  try {
    await Isolate.spawn(createTempFile, [receivePort.sendPort, fileName]);
    final response = await receivePort.first as File?;
    if (response != null) {
      return response;
    } else {
      throw Exception('Failed to create temporary file.');
    }
  } on Object {
    if (kDebugMode) {
      print("Isolate Failed");
    }
    receivePort.close();
    throw Exception('Failed to create temporary file.');
  }
}

encryptData(List<dynamic> args) async {
  SendPort resultPort = args[0];
  Uint8List plainString = args[1];
  String encryptedFileDestination = args[2];
  if (kDebugMode) {
    print('Encrypting File...');
  }
  final encrypted =
  MyEncrypt.myEncrypter.encryptBytes(plainString, iv: MyEncrypt.myIv);

  File f = File(encryptedFileDestination);
  await f.writeAsBytes(encrypted.bytes);
  Isolate.exit(resultPort, f.absolute.toString());
}

writeData(List<dynamic> args) async {
  SendPort resultPort = args[0];
  Uint8List encResult = args[1];
  String encryptedFileDestination = args[2];
  if (kDebugMode) {
    print('Writing data...');
  }
  File f = File(encryptedFileDestination);
  await f.writeAsBytes(encResult);
  Isolate.exit(resultPort, f.absolute.toString());

}

readData(List<dynamic> args) async {
  SendPort resultPort = args[0];
  String fileNamedWithPath = args[1];

  if (kDebugMode) {
    print('Reading data...');
  }
  File f = File(fileNamedWithPath);
  final bytes = await f.readAsBytes();
  Isolate.exit(resultPort, bytes);
}

decryptData(List<dynamic> args) {
  SendPort resultPort = args[0];
  Uint8List encData = args[1];
  if (kDebugMode) {
    print('File decryption in progress...');
  }
  enc.Encrypted en = enc.Encrypted(encData);
  Isolate.exit(
      resultPort, MyEncrypt.myEncrypter.decryptBytes(en, iv: MyEncrypt.myIv));
}

createTempFile(List<dynamic> args) async {
  SendPort resultPort = args[0];
  String fileName = args[1];
  // final directory = await getTemporaryDirectory();
  final Directory directory = Directory.systemTemp;
  final tempFilePath = '${directory.path}/$fileName';
  Isolate.exit(resultPort, File(tempFilePath));
}