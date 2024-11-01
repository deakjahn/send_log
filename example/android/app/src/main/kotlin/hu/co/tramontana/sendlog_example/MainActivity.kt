package hu.co.tramontana.sendlog_example

import android.os.*
import io.flutter.embedding.android.FlutterActivity
import hu.co.tramontana.sendlog.*
import io.flutter.embedding.android.*
import io.flutter.embedding.engine.*

class MainActivity: FlutterActivity() {

  override fun onCreate(savedInstanceState: Bundle?) {
    Log.init(this)
    super.onCreate(savedInstanceState)
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    Log.info("platform", "configureFlutterEngine")
    Log.debug("platform", "configureFlutterEngine")
    super.configureFlutterEngine(flutterEngine)
  }

  override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
    Log.warning("platform", "cleanUpFlutterEngine")
    Log.error("platform", "cleanUpFlutterEngine")
    super.cleanUpFlutterEngine(flutterEngine)
  }

}