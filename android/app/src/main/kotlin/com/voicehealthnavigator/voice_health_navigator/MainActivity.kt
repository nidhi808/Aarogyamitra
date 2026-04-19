package com.voicehealthnavigator.voice_health_navigator

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.FileOutputStream
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.aarogyamitra.asset_helper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "copyLargeAsset") {
                val assetName = call.argument<String>("assetName")
                val targetPath = call.argument<String>("targetPath")
                
                if (assetName != null && targetPath != null) {
                    try {
                        copyFile(assetName, targetPath)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("COPY_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Missing assetName or targetPath", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun copyFile(assetName: String, targetPath: String) {
        val assetManager = assets
        // Flutter assets are prefixed with 'flutter_assets/' on the Android side
        val inputStream = assetManager.open("flutter_assets/$assetName")
        val outFile = File(targetPath)
        val outStream = FileOutputStream(outFile)

        val buffer = ByteArray(1024 * 1024) // 1MB buffer
        var read: Int
        while (inputStream.read(buffer).also { read = it } != -1) {
            outStream.write(buffer, 0, read)
        }
        
        inputStream.close()
        outStream.flush()
        outStream.close()
    }
}
