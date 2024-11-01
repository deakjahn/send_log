import 'package:flutter/material.dart';
import 'package:send_log/send_log.dart';

void main() {
  SendLogger(
    MyApp.APP_TITLE,
    // logFileInDebugMode: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  static const String APP_TITLE = 'Send Log Demo';

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MyApp.APP_TITLE,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> attachments = [];
  bool isHTML = false;
  final recipientController = TextEditingController(text: 'sendlog@example.com');
  final subjectController = TextEditingController(text: 'Test');
  final bodyController = TextEditingController(text: 'Mail body.');

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 3)).then((_) {
      logDebug('test', 'initState');
      logInfo('test', 'initState');
      logWarning('test', 'initState');
      logError('test', 'initState');
    });
  }

  Future<void> send() async {
    logInfo('test', 'send');
    String result = '';
    try {
      await SendLogger.launchEmailLog(subjectController.text, recipientController.text, bodyController.text);
      result = 'success';
    } catch (error) {
      result = error.toString();
    }

    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(MyApp.APP_TITLE),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: send,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: recipientController,
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Recipient'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: bodyController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(labelText: 'Body', border: OutlineInputBorder()),
                ),
              ),
            ),
            CheckboxListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
              title: const Text('HTML'),
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() => isHTML = value);
                }
              },
              value: isHTML,
            ),
          ],
        ),
      ),
    );
  }
}