library send_log;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:logging/logging.dart';
import 'package:logging_appenders/logging_appenders.dart';
import 'package:path/path.dart' as p;
import 'package:send_log/src/file_appender.dart';

export 'package:logging/src/level.dart';

late Logger _logger;

class SendLogger {
  static const MethodChannel _channel = MethodChannel('hu.co.tramontana.sendlog/platform');
  final String appTitle;
  final int keepRotateCount;
  final int rotateAtSizeBytes;
  final Duration rotateCheckInterval;
  final bool logFileInDebugMode;

  SendLogger(
    this.appTitle, {
    this.keepRotateCount = 3,
    this.rotateAtSizeBytes = 10 * 1024 * 1024,
    this.rotateCheckInterval = const Duration(minutes: 5),
    this.logFileInDebugMode = false,
  }) {
    _logger = Logger(appTitle);
    _setup();
  }

  Future<void> _setup() async {
    hierarchicalLoggingEnabled = true;
    WidgetsFlutterBinding.ensureInitialized();
    if (kReleaseMode || kProfileMode || logFileInDebugMode) {
      Logger.root.level = Level.CONFIG;
      final path = await getLogPath('log.txt');
      await initialize(
        appTitle: appTitle,
        level: Level.CONFIG,
        useLogFile: true,
        releaseMode: kReleaseMode,
      );
      SendLogRotatingFileAppender(
        baseFilePath: path,
        keepRotateCount: keepRotateCount,
        rotateAtSizeBytes: rotateAtSizeBytes,
        rotateCheckInterval: rotateCheckInterval,
      ).attachToLogger(Logger.root);
    } else {
      Logger.root.level = Level.ALL;
      await initialize(
        appTitle: appTitle,
        level: Level.ALL,
        useLogFile: false,
        releaseMode: kReleaseMode,
      );
      PrintAppender(formatter: const _SendLogColorFormatter()).attachToLogger(Logger.root);
    }
  }

  static Future<bool> initialize({required String appTitle, required Level level, bool useLogFile = false, bool releaseMode = true}) async {
    final result = await _channel.invokeMethod<bool>('initialize', {
      'app_title': appTitle,
      'level': level.value,
      'use_log_file': useLogFile,
      'release_mode': releaseMode,
    });
    return result!;
  }

  static Future<String> getLogPath([String filename = '']) async {
    final result = await _channel.invokeMethod<String>('getLogPath', {
      'filename': filename,
    });
    return result!;
  }

  static Future<bool> setLevel(Level level) async {
    final result = await _channel.invokeMethod<bool>('setLevel', {
      'level': level.value,
    });
    return result!;
  }

  static Future<bool> _sendMail({
    String subject = '',
    List<String> recipients = const [],
    List<String> cc = const [],
    List<String> bcc = const [],
    String body = '',
    List<String>? attachmentPaths,
    bool isHTML = false,
  }) async {
    final result = await _channel.invokeMethod<bool>('sendMail', {
      'subject': subject,
      'body': body,
      'recipients': recipients,
      'cc': cc,
      'bcc': bcc,
      'attachment_paths': attachmentPaths,
      'is_html': isHTML,
    });
    return result!;
  }

  static Future<bool> launchEmailLog(String appTitle, String email, String body) async {
    final zipPath = await getLogPath('log.zip');
    final logFolder = await getLogPath();
    final files = Directory(logFolder) //
        .listSync(followLinks: false)
        .whereType<File>()
        .where((log) => p.extension(log.path) != '.zip')
        .map((log) => log)
        .toList();

    final zip = File(zipPath);
    if (zip.existsSync()) zip.deleteSync();
    await ZipFile.createFromFiles(
      sourceDir: Directory(logFolder),
      files: files,
      zipFile: zip,
    );

    return await _sendMail(
      body: body,
      subject: 'Log ($appTitle)',
      recipients: [email],
      attachmentPaths: [zipPath],
      isHTML: false,
    );
  }
}

Future<bool> setLogLevel(Level level) async {
  _logger.level = level;
  return await SendLogger.setLevel(level);
}

void logInfo(String prefix, Object? message, [Object? error, StackTrace? stackTrace]) => _logger.finest(
      '$prefix: $message',
      !kReleaseMode ? error : null,
      !kReleaseMode ? stackTrace : null,
    );

void logDebug(String prefix, Object? message, [Object? error, StackTrace? stackTrace]) => _logger.fine(
      '$prefix: $message',
      !kReleaseMode ? error : null,
      !kReleaseMode ? stackTrace : null,
    );

void logWarning(String prefix, Object? message, [Object? error, StackTrace? stackTrace]) => _logger.warning(
      '$prefix: $message',
      !kReleaseMode ? error : null,
      !kReleaseMode ? stackTrace : null,
    );

void logError(String prefix, Object? message, [Object? error, StackTrace? stackTrace]) => _logger.severe(
      '$prefix: $message',
      !kReleaseMode ? error : null,
      !kReleaseMode ? stackTrace : null,
    );

String logHexDump(String prefix, Object? message, List<int> data, {int rowSize = 16, bool showAscii = true}) {
  final str = StringBuffer();

  str.writeln(message);
  for (int i = 0; i < data.length; i += rowSize) {
    str.write('0x');
    str.write(i.toRadixString(16).padLeft(6, '0'));
    str.write(': ');

    for (int j = 0; j < rowSize; j++) {
      if (i + j < data.length) {
        str.write(data[i + j].toRadixString(16).padLeft(2, '0'));
        str.write(' ');
      } else
        str.write('   ');
    }

    if (showAscii) {
      str.write(' ');
      for (int j = 0; j < rowSize; j++) {
        if (i + j < data.length) {
          final c = data[i + j];
          if (c > 32 && c < 256)
            str.writeCharCode(c);
          else
            str.write('.');
        }
      }
    }
    str.writeln();
  }

  final dump = str.toString().trimRight();
  logInfo(prefix, dump);
  return dump;
}

class _SendLogColorFormatter extends LogRecordFormatter {
  final LogRecordFormatter wrappedFormatter;

  // ignore: unused_element
  const _SendLogColorFormatter([this.wrappedFormatter = const DefaultLogRecordFormatter()]);

  @override
  StringBuffer formatToStringBuffer(LogRecord rec, StringBuffer sb) {
    if (rec.level <= Level.FINE)
      sb.write('\x1B[32m');
    else if (rec.level <= Level.INFO)
      sb.write('\x1B[34m');
    else if (rec.level <= Level.WARNING)
      sb.write('\x1B[35m');
    else if (rec.level <= Level.SEVERE)
      sb.write('\x1B[31m');
    else
      sb.write('\x1B[1;31m');

    wrappedFormatter.formatToStringBuffer(rec, sb);
    sb.write('\x1B[0m');
    return sb;
  }
}