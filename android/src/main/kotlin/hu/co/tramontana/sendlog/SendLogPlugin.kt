package hu.co.tramontana.sendlog

import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.*
import android.content.*
import android.content.pm.ResolveInfo
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.*
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar
import android.content.pm.PackageManager
import android.content.ClipData
import android.content.ClipDescription
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import androidx.core.text.HtmlCompat
import java.io.File

private const val SUBJECT = "subject"
private const val BODY = "body"
private const val RECIPIENTS = "recipients"
private const val CC = "cc"
private const val BCC = "bcc"
private const val ATTACHMENT_PATHS = "attachment_paths"
private const val IS_HTML = "is_html"
private const val REQUEST_CODE_SEND = 607

class SendLogPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  private lateinit var context: Context
  private var activity: Activity? = null
  private var channelResult: Result? = null

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    val channel = MethodChannel(flutterPluginBinding.flutterEngine.dartExecutor, "hu.co.tramontana.sendlog/platform")
    context = flutterPluginBinding.applicationContext
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
  }

  override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
    activity = activityPluginBinding.activity
    activityPluginBinding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
    activity = activityPluginBinding.activity
    activityPluginBinding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initialize" -> {
        Log.TAG = call.argument<String>("app_title")!!
        Log.level = call.argument<Int>("level")!!
        Log.useLogFile = call.argument<Boolean>("use_log_file")!!
        Log.releaseMode = call.argument<Boolean>("release_mode")!!
        result.success(true)
      }

      "getLogPath" -> {
        Log.filename = call.argument<String>("filename")!!
        var path = java.io.File(context.filesDir, "logs").apply {
          mkdirs()
        }
        if (Log.filename.isNotEmpty())
          path = path.resolve(Log.filename)
        result.success(path.absolutePath)
      }

      "setLevel" -> {
        Log.level = call.argument<Int>("level")!!
        result.success(true)
      }

      "sendMail" -> {
        this.channelResult = result
        sendEmail(call, result)
        // If the call threw an exception, Flutter already sent a result to the channel,
        // so we don't need to send a result from onActivityResult anymore.
      }

      else ->
        result.notImplemented()
    }
  }

  private fun sendEmail(options: MethodCall, callback: Result) {
    val body = options.argument<String>(BODY)
    val isHtml = options.argument<Boolean>(IS_HTML) ?: false
    val attachmentPaths = options.argument<ArrayList<String>>(ATTACHMENT_PATHS) ?: ArrayList()
    val subject = options.argument<String>(SUBJECT)
    val recipients = options.argument<ArrayList<String>>(RECIPIENTS)
    val cc = options.argument<ArrayList<String>>(CC)
    val bcc = options.argument<ArrayList<String>>(BCC)

    var text: CharSequence? = null
    var html: String? = null
    body?.let {
      text = if (isHtml) HtmlCompat.fromHtml(it, HtmlCompat.FROM_HTML_MODE_LEGACY) else it
      html = if (isHtml) it else null
    }
    val attachmentUris = attachmentPaths.map {
      FileProvider.getUriForFile(context, activity!!.packageName + ".logprovider", File(it))
    }

    val intent = Intent()
    if (attachmentUris.isEmpty()) {
      intent.action = Intent.ACTION_SENDTO
      intent.data = Uri.parse("mailto:")
    } else {
      if (attachmentUris.size == 1) {
        // https://github.com/sidlatau/flutter_email_sender/issues/91
        // ACTION_SENDTO here does not work on some devices
        intent.action = Intent.ACTION_SEND
        intent.data = Uri.parse("mailto:")
        intent.putExtra(Intent.EXTRA_STREAM, attachmentUris.first())
        // Add a selector intent to make sure that only email apps are shown, instead of just any app that can
        // handle the attached file(s). This is done because the intent data is ignored for ACTION_SEND and
        // ACTION_SEND_MULTIPLE.
        // https://stackoverflow.com/questions/2197741/how-to-send-emails-from-my-android-application
        intent.selector = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:"))

        // From the ACTION_SEND_MULTIPLE docs:
        // "This allows you to use FLAG_GRANT_READ_URI_PERMISSION when sharing content: URIs [...] If you don't set
        // a ClipData, it will be copied there for you when calling Context#startActivity(Intent)."
        // However, this doesn't always seem to be happening, so we have to do the dirty work ourselves.
        val clipItems = attachmentUris.map { ClipData.Item(it) }
        val clipDescription = ClipDescription("", arrayOf("application/octet-stream"))
        val clipData = ClipData(clipDescription, clipItems.first())
        for (item in clipItems.drop(1))
          clipData.addItem(item)
        intent.clipData = clipData
      } else {
        intent.action = Intent.ACTION_SEND_MULTIPLE
        intent.type = "text/plain";
        intent.putParcelableArrayListExtra(Intent.EXTRA_STREAM, ArrayList(attachmentUris))
      }
      intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }

    text?.let {
      intent.putExtra(Intent.EXTRA_TEXT, it)
    }
    html?.let {
      intent.putExtra(Intent.EXTRA_HTML_TEXT, it)
    }
    subject?.let {
      intent.putExtra(Intent.EXTRA_SUBJECT, it)
    }
    recipients?.let {
      intent.putExtra(Intent.EXTRA_EMAIL, listArrayToArray(it))
    }
    cc?.let {
      intent.putExtra(Intent.EXTRA_CC, listArrayToArray(it))
    }
    bcc?.let {
      intent.putExtra(Intent.EXTRA_BCC, listArrayToArray(it))
    }

    if (activity?.packageManager?.resolveActivity(intent, 0) != null)
      activity?.startActivityForResult(intent, REQUEST_CODE_SEND)
    else
      callback.error("email_error", "No email clients found", null)
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    return when (requestCode) {
      REQUEST_CODE_SEND -> {
        channelResult?.success(true)
        channelResult = null
        true
      }

      else -> {
        channelResult?.success(false)
        channelResult = null
        false
      }
    }
  }

  private fun listArrayToArray(list: ArrayList<String>): Array<String> = list.toArray(arrayOfNulls<String>(list.size))
}