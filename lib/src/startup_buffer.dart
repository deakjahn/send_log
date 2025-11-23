import 'package:logging/logging.dart';

class StartupBuffer {
  final _buffer = <LogRecord>[];
  void Function(LogRecord record)? _sink;

  void add(LogRecord record) {
    if (_sink != null)
      _sink!.call(record);
    else
      _buffer.add(record);
  }

  void forwardTo(void Function(LogRecord record) sink) {
    _sink = sink;
    for (final record in _buffer) sink(record);
    _buffer.clear();
  }
}