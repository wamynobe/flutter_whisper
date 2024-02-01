package com.wamynobe.flutterwhisper

import android.content.Context
import android.os.Handler
import android.os.Looper

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.whispercpp.whisper.WhisperContext
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.DelicateCoroutinesApi
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.MainScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.newSingleThreadContext
import kotlinx.coroutines.runBlocking
import java.util.logging.Logger
import kotlin.concurrent.thread
import kotlin.coroutines.*

class FlutterWhisperPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var whisper: com.whispercpp.whisper.WhisperContext?  = null
    private lateinit var eventChannel: EventChannel
    private val eventHandler = MyEventChannelHandler()


    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_whisper")
        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "flutter_whisper/onStartListenning")
        eventChannel.setStreamHandler(eventHandler)
        Logger.getLogger("FlutterWhisperPlugin").info("start")
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
    @OptIn(ExperimentalCoroutinesApi::class, DelicateCoroutinesApi::class)
    override fun onMethodCall(call: MethodCall, result: Result) {
        when(call.method) {
            "getPlatformName" -> result.success("Android_Tested")
            "initialize" -> {
                runBlocking(Dispatchers.IO) {
                    launch {
                        loadBaseModel()
                    }
                }


                result.success(true)
            }
            "start" -> {
                newSingleThreadContext(
                    "WhisperListeningThread"

                ).use {
                    ctx ->runBlocking(ctx) {

                    launch {
                        for (i in 1..10) {
                            Logger.getLogger("FlutterWhisperPlugin").info("send event $i")
                            eventHandler.sendEvent(i)
                            delay(1000)
                        }
                    }
                }
                }


            }
            "stop" -> {
                if(whisper == null){
                 return;
                }
                // stop the whisper
                runBlocking {
                    launch {
                        whisper!!.release()

                    }
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }



    class MyEventChannelHandler : EventChannel.StreamHandler, CoroutineScope by MainScope(){
        fun sendEvent(eventData: Any) {
            Handler(Looper.getMainLooper()).post {
                Logger.getLogger("FlutterWhisperPlugin").info("eventSink $eventSink")
                Logger.getLogger("FlutterWhisperPlugin").info("send event $eventData")
                eventSink?.success(eventData)
            }
        }

        private var eventSink: EventChannel.EventSink? = null

        override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
            Logger.getLogger("FlutterWhisperPlugin").info("onListen $sink")

            eventSink = sink
        }

        override fun onCancel(arguments: Any?) {
            Logger.getLogger("FlutterWhisperPlugin").info("onCancel")

            eventSink = null
        }
    }


    override fun onDetachedFromEngine( binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
    }
}