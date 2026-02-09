package com.ningapi.services

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.util.Log
import java.util.Locale
import kotlinx.coroutines.CompletableDeferred

class TtsService private constructor(context: Context) {

    companion object {
        @Volatile
        private var INSTANCE: TtsService? = null
        private const val TAG = "TtsService"

        fun getInstance(context: Context): TtsService {
            return INSTANCE ?: synchronized(this) {
                INSTANCE ?: TtsService(context).also { INSTANCE = it }
            }
        }
    }

    private var textToSpeech: TextToSpeech? = null
    var isInitialized = false
        private set
    private var speakCompletionDeferred: CompletableDeferred<Unit>? = null

    init {
        textToSpeech = TextToSpeech(context.applicationContext) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val result = textToSpeech?.setLanguage(Locale.FRANCE)
                if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                    Log.e(TAG, "Language not supported")
                } else {
                    isInitialized = true
                    Log.d(TAG, "TTS Initialized")
                    
                    textToSpeech?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                        override fun onStart(utteranceId: String?) {
                            Log.d(TAG, "TTS Started: $utteranceId")
                        }

                        override fun onDone(utteranceId: String?) {
                            Log.d(TAG, "TTS Done: $utteranceId")
                            speakCompletionDeferred?.complete(Unit)
                            speakCompletionDeferred = null
                        }

                        override fun onError(utteranceId: String?) {
                            Log.e(TAG, "TTS Error: $utteranceId")
                            speakCompletionDeferred?.completeExceptionally(Exception("TTS Error"))
                            speakCompletionDeferred = null
                        }
                    })
                    
                    textToSpeech?.setSpeechRate(0.8f) 
                }
            } else {
                Log.e(TAG, "Initialization failed")
            }
        }
    }

    suspend fun speak(text: String) {
        if (!isInitialized) {
             Log.w(TAG, "TTS not initialized yet")
             return
        }

        stop()
        
        Log.d(TAG, "Speaking: $text")
        
        speakCompletionDeferred = CompletableDeferred()
        
        val params = android.os.Bundle()
        params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, "utteranceId")
        
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, params, "utteranceId")
        
        try {
            speakCompletionDeferred?.await()
        } catch (e: Exception) {
            Log.e(TAG, "Error awaiting speech completion", e)
        }
    }

    fun speakAsync(text: String) {
        if (!isInitialized) return
        
        stop() 
        
        Log.d(TAG, "Speaking async: $text")
        
        val params = android.os.Bundle()
        textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, params, "asyncUtteranceId")
    }

    fun stop() {
        if (textToSpeech?.isSpeaking == true || speakCompletionDeferred != null) {
            textToSpeech?.stop()
            speakCompletionDeferred?.cancel()
            speakCompletionDeferred = null
            Log.d(TAG, "TTS Stopped")
        }
    }

    fun shutdown() {
        textToSpeech?.shutdown()
    }
}
