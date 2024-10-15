import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';

/// A file appender which will rotate the log file once it reaches
/// [rotateAtSizeBytes] bytes. Will keep [keepRotateCount] number of files.
class SendLogRotatingFileAppender extends BaseLogAppender {
  final String baseFilePath;
  final int keepRotateCount;
  final int rotateAtSizeBytes;
  final Duration rotateCheckInterval;
  final Clock clock;

  SendLogRotatingFileAppender({
    LogRecordFormatter? formatter,
    required this.baseFilePath,
    this.keepRotateCount = 3,
    this.rotateAtSizeBytes = 10 * 1024 * 1024,
    this.rotateCheckInterval = const Duration(minutes: 5),
    this.clock = const Clock(),
  }) : super(formatter) {
    _outputFile = File(baseFilePath);
    if (!_outputFile.parent.existsSync()) {
      throw StateError('When initializing file logger, ${_outputFile.parent} must exist.');
    }
    _maybeRotate();
  }

  DateTime? _nextRotateCheck = DateTime.now();
  late File _outputFile;

  /// Returns all available rotated logs, starting from the most current one.
  List<File> getAllLogFiles() => Iterable.generate(keepRotateCount, (idx) => idx) //
      .map((rotation) => _fileNameForRotation(rotation))
      .map((fileName) => File(fileName))
      .takeWhile((file) => file.existsSync())
      .toList(growable: false);

  static int id = 0;
  final int instanceId = id++;

  @override
  void handle(LogRecord record) {
    try {
      _outputFile.writeAsStringSync(
        "${formatter.format(record)}\n",
        mode: FileMode.append,
        flush: true,
      );
    } catch (error, stackTrace) {
      print('Error while writing log $error $stackTrace');
    }
    _maybeRotate();
  }

  String _fileNameForRotation(int rotation) => (rotation == 0) ? baseFilePath : '$baseFilePath.$rotation';

  /// rotates the file, if it is larger than [rotateAtSizeBytes]
  Future<bool> _maybeRotate() async {
    if (_nextRotateCheck?.isAfter(clock.now()) != false) {
      return false;
    }
    _nextRotateCheck = null;
    try {
      try {
        final length = await File(_outputFile.path).length();
        if (length < rotateAtSizeBytes) {
          return false;
        }
      } on FileSystemException catch (_) {
        // if .length() throws an error, ignore it.
        return false;
      } catch (error, stackTrace) {
        print('Error while checking log file length $error $stackTrace');
        rethrow;
      }

      for (var i = keepRotateCount - 1; i >= 0; i--) {
        final file = File(_fileNameForRotation(i));
        if (file.existsSync()) {
          try {
            await file.rename(_fileNameForRotation(i + 1));
          } on FileSystemException catch (_) {
            if (i == 0) {
              await file.rename(_fileNameForRotation(i + 1));
            } else
              rethrow;
          }
        }
      }

      return true;
    } finally {
      _nextRotateCheck = clock.now().add(rotateCheckInterval);
    }
  }
}