Send Log
========

Straightforward and simple log support with e-mail sending. The intended use case is easy collection of log data, allowing the user to send it to a support address when asking for help.

Log lines are written:

* debug mode: Flutter (colored lines) and Logcat console,
* release/profile mode: log file (can be selected in debug mode, too).

The log is rotated among a specified number of files when the specified maximum size is reached.

Unlike other logging solutions, this one closes and flushes the log file after each write. While this is obviously less efficient, it makes it possible to write to the same log file from different locations (eg. both from the Dart side and your underlying platform code).

The module supports packing the current log files into a ZIP archive and send it attached to an e-mail address. Its main intended use case is to support an _Ask for help_ item in the _Settings_ page of an app that attaches the log to a support request sent by the user.

## Usage

Call the constructor from your `main()` function:

```dart
void main() async {
  SendLogger(

    /// This name will appear as sender in the log lines, making it easier to spot them or filter on in Logcat.
    'YourAppName',
    /// The number of rotated log files kept. Defaults to 3.
    keepRotateCount: 5,
    /// File size limit to be exceded for a new log file. Defaults to 10 MB.
    rotateAtSizeBytes: 50 * 1024 * 1024,
    /// The frequency of rotation checks. Defaults to 5 minutes.
    rotateCheckInterval: const Duration(minutes: 10),

    /// The base filename. Defaults to 'log.txt'.
    logFilename: 'sendlog.txt',
    /// Whether to send debug logs to console (false) or file (true). Defaults to false.
    /// Release and profile modes always send to file.
    logFileInDebugMode: true,
  );
  runApp(...);
}
```

As soon as the constructor was called, you can use the following functions from anywhere in your code:

```dart
logInfo(String prefix, Object? message, [Object? error, StackTrace? stackTrace]);
logDebug(String prefix, Object? message, [Object? error, StackTrace? stackTrace]);
logWarning(String prefix, Object? message, [Object? error, StackTrace? stackTrace]);
logError(String prefix, Object? message, [Object? error, StackTrace? stackTrace]);
```

* The `prefix` will be prepended to the message.
* The `message` itself can be either a string or any object that has a `toString()` function.
* The `error` itself (practically an `Exception` or an `Error`) and the `stackTrace` will be suppressed in release mode and printed otherwise.

A convenience function helps print a formatted hex dump. It requires an integer list (which could be an `Uint8List`):

```dart
logHexDump(String prefix, Object? message, List<int> data, {int rowSize = 16, bool showAscii = true});
```

The required log level can be changed at any time using the usual `Level` values:

```dart
setLogLevel(Level.FINE);
```

Sending the logs can be initiated with:

```dart
await SendLogger.launchEmailLog('YourAppName', 'sendlog@example.com', 'message body');
```

which will call the e-mail app of the user's choice with the subject "Log (YourAppName)", the recipient address and the initial message body filled. The plugin **will not** send the message, this is up to the user to decide. It only starts the e-mail and attaches the zipped log files. However, it will return a logical value that you can use to decide what message to present to your user about success or failure.

## Status

The plugin is in current use in several published Android apps and users regularly and successfully send support requests with it. It isn't tested on iOS thoroughly, although the code is supposedly present. Tests and reports, as well as possible PRs on iOS and other platforms are welcome.