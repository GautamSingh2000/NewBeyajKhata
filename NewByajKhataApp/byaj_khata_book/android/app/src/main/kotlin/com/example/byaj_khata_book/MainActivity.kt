package com.example.byaj_khata_book

import android.media.MediaScannerConnection
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.example.save_to_gallery"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "scanFile") {
                val path = call.arguments as String

                MediaScannerConnection.scanFile(
                    this,
                    arrayOf(path),
                    null
                ) { _, _ -> }

                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
