package hu.co.tramontana.sendlog

import android.app.*
import android.content.*
import java.io.*
import java.text.*
import java.util.*
import kotlin.math.*
import kotlin.text.*

@Suppress("unused")
object Log {
  public var TAG = "SendLog"
  public var filename = "log.txt"
  public var level = 0
  public var useLogFile = false
  private lateinit var logFile: File

  enum class Level(val value: Int) {
    ALL(0),
    FINEST(300),
    FINER(400),
    FINE(500),
    CONFIG(700),
    INFO(800),
    WARNING(900),
    SEVERE(1000),
    SHOUT(1200),
    OFF(2000)
  }

  fun init(context: Context) {
    val logFolder = File(context.filesDir, "logs").apply {
      mkdirs()
    }
    logFile = logFolder.resolve(filename)
  }

  private fun timestamp(): String = SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSSSSS", Locale.getDefault()).format(Calendar.getInstance().time)

  @JvmStatic
  fun info(prefix: String, message: Any?) {
    if (Level.FINEST.value > level) {
      if (useLogFile)
        logFile.appendText("${timestamp()} FINEST $TAG - $prefix: $message\n")
      else
        android.util.Log.i(TAG, "$prefix: $message")
    }
  }

  @JvmStatic
  fun debug(prefix: String, message: Any?) {
    if (Level.FINE.value > level) {
      if (useLogFile)
        logFile.appendText("${timestamp()} FINE $TAG - $prefix: $message\n")
      else
        android.util.Log.d(TAG, "$prefix: $message")
    }
  }

  @JvmStatic
  fun warning(prefix: String, message: Any?) {
    if (Level.WARNING.value > level) {
      if (useLogFile)
        logFile.appendText("${timestamp()} WARNING $TAG - $prefix: $message\n")
      else
        android.util.Log.w(TAG, "$prefix: $message")
    }
  }

  @JvmStatic
  fun error(prefix: String, message: Any?) {
    if (Level.SEVERE.value > level) {
      if (useLogFile)
        logFile.appendText("${timestamp()} SEVERE $TAG - $prefix: $message\n")
      else
        android.util.Log.e(TAG, "$prefix: $message")
    }
  }

  @OptIn(ExperimentalStdlibApi::class)
  private fun toHex(x: Int, size: Int): String {
    val hex = HexFormat {
      upperCase = false
      number.removeLeadingZeros = false
    }
    return x.toHexString(hex).takeLast(size).padStart(size, '0')
  }

  @JvmStatic
  @JvmOverloads
  fun hexDump(prefix: String, message: Any?, data: IntArray, rowSize: Int = 16, showAscii: Boolean = true) {
    val str = StringBuilder()
    str.appendLine(message)

    for (i in data.indices step rowSize) {
      str.append("0x${toHex(i, 6)}: ")
      for (j in 0 until rowSize)
        str.append(if (i + j < data.size) "${toHex(data[i + j], 2)} " else "   ")
      if (showAscii) {
        str.append(" ")
        for (j in 0 until rowSize) {
          if (i + j < data.size) {
            val c = data[i + j]
            str.append(if (c in 33..255) c.toChar() else '.')
          }
        }
      }
      str.appendLine()
    }

    info(prefix, str.toString().trimEnd())
  }
}