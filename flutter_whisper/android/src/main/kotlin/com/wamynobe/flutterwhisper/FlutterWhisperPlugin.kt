package com.wamynobe.flutterwhisper

import android.content.Context

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.whispercpp.whisper.WhisperContext
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlin.coroutines.*

class FlutterWhisperPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var whisper: com.whispercpp.whisper.WhisperContext?  = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_whisper")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }
    private fun loadBaseModel(){
        if (context != null) {
            val models = context!!.assets.list("models/")
            if (models != null) {
                whisper = com.whispercpp.whisper.WhisperContext.createContextFromAsset(context!!.assets, "models/" + models[0])
            }
        }

    }
    override fun onMethodCall(call: MethodCall, result: Result) {
        when(call.method) {
            "getPlatformName" -> result.success("Android_Tested")
            "initialize" -> {
                runBlocking {
                    launch {
                        loadBaseModel()
                    }
                }
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onDetachedFromEngine( binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }
}