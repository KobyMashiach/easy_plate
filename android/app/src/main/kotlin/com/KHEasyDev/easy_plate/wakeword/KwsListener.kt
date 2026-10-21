package com.KHEasyDev.easy_plate.wakeword

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.k2fsa.sherpa.onnx.FeatureConfig
import com.k2fsa.sherpa.onnx.KeywordSpotter
import com.k2fsa.sherpa.onnx.KeywordSpotterConfig
import com.k2fsa.sherpa.onnx.OnlineModelConfig
import com.k2fsa.sherpa.onnx.OnlineTransducerModelConfig
import java.util.Collections

/**
 * Spots "Hey Shefi" on the phone itself, the way the system assistants do
 * it: a small keyword-spotting model (sherpa-onnx, zh-en zipformer working
 * on English phonemes, about 5 MB, in assets/kws) reads the microphone in
 * 100 ms chunks and answers
 * only "heard it" or nothing. No audio leaves the phone and no speech
 * service runs until the words are heard; only the request that follows
 * them goes to the speech recognizer (in the floating panel or the chat).
 *
 * The phrase is written as it is pronounced, in ARPAbet phonemes: "hey
 * SHEF-ee", like "chef" (HH EY1 SH EH1 F IY0, assets/kws/keywords.txt).
 * Phonemes rather than spellings, because the spelling-based model missed
 * that pronunciation while this one catches it.
 *
 * It still needs the microphone open while it listens, so Android shows its
 * microphone indicator; only the system's own assistant may use the
 * low-power hardware detector. Runs on its own thread; [onHeard] is posted
 * to the main thread.
 */
class KwsListener(
    context: Context,
    private val onHeard: (command: String) -> Unit,
) {
    private val app = context.applicationContext
    private val main = Handler(Looper.getMainLooper())
    // Mutated on the main thread (suspend/resume), read by the audio thread
    // through [active] on every chunk: the synchronized wrapper makes each
    // call atomic and visible across the two.
    private val suspended: MutableSet<String> = Collections.synchronizedSet(mutableSetOf())

    @Volatile private var running = false
    @Volatile private var thread: Thread? = null

    private val active get() = running && suspended.isEmpty()

    fun start() {
        if (running) return
        running = true
        launch()
    }

    fun stop() {
        running = false
        thread?.interrupt()
        thread = null
    }

    /** Releases the microphone while [reason] holds; [resume] gives it back. */
    fun suspend(reason: String) {
        suspended.add(reason)
    }

    fun resume(reason: String) {
        if (suspended.remove(reason)) launch()
    }

    /** Kept for the controller's language change: the model has no language. */
    fun restart() {}

    private fun launch() {
        if (!active || thread?.isAlive == true) return
        thread = Thread({ loop() }, "hey-shefi").apply {
            priority = Thread.NORM_PRIORITY - 1
            start()
        }
    }

    @SuppressLint("MissingPermission")
    private fun loop() {
        if (app.checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            retryLater(30_000)
            return
        }
        // A call has the line.
        val audio = app.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (audio.mode != AudioManager.MODE_NORMAL) {
            retryLater(3_000)
            return
        }
        val spotter = spotter() ?: return
        val stream = spotter.createStream("")
        val minBuffer = AudioRecord.getMinBufferSize(RATE, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT)
        // The raw microphone where the phone offers it: the voice-processing
        // sources (VOICE_RECOGNITION on Samsung) strip the 2-8 kHz band
        // where "sh" and "f" live, and the model then hears "hai" but never
        // "shefi".
        val unprocessed = audio.getProperty(AudioManager.PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED) == "true"
        val source = if (unprocessed) MediaRecorder.AudioSource.UNPROCESSED else MediaRecorder.AudioSource.MIC
        val recorder = try {
            AudioRecord(
                source,
                RATE,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                maxOf(minBuffer, CHUNK * 2 * 4),
            )
        } catch (e: Exception) {
            Log.w(TAG, "AudioRecord refused", e)
            stream.release()
            retryLater(10_000)
            return
        }
        if (recorder.state != AudioRecord.STATE_INITIALIZED) {
            recorder.release()
            stream.release()
            retryLater(10_000)
            return
        }
        Log.i(TAG, "listening on the device (source=${if (unprocessed) "unprocessed" else "mic"})")
        var heard = false
        try {
            recorder.startRecording()
            val debug = Log.isLoggable(TAG, Log.DEBUG)
            // The audio dump (below) only in a debuggable build: on a store
            // build anyone with adb could switch the tag on and have the
            // microphone written to external storage.
            val dumpAudio = debug &&
                (app.applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
            var chunks = 0
            var level = 0f
            val pcm = ShortArray(CHUNK)
            val samples = FloatArray(CHUNK)
            while (active && !Thread.currentThread().isInterrupted) {
                val read = recorder.read(pcm, 0, pcm.size)
                if (read <= 0) continue
                var energy = 0.0
                for (i in 0 until read) {
                    val v = pcm[i] / 32768f
                    samples[i] = v
                    energy += v * v
                }
                // Automatic gain: the model only spots speech at a normal
                // level (it misses the same phrase 6 dB quieter), and a
                // phone across the room hears it far quieter than that.
                // Fast attack, slow release, capped so silence stays quiet.
                val rms = Math.sqrt(energy / read).toFloat()
                level = if (rms > level) rms else level * 0.97f + rms * 0.03f
                val gain = minOf(MAX_GAIN, TARGET_LEVEL / maxOf(level, 1e-4f))
                for (i in 0 until read) samples[i] = (samples[i] * gain).coerceIn(-1f, 1f)
                if (dumpAudio) dump(samples, read)
                stream.acceptWaveform(if (read == CHUNK) samples else samples.copyOf(read), RATE)
                while (spotter.isReady(stream)) spotter.decode(stream)
                val result = spotter.getResult(stream)
                // Level and partial tokens, only when asked for:
                //   adb shell setprop log.tag.WakeWord DEBUG
                if (debug && ++chunks % 10 == 0) {
                    Log.d(TAG, "rms=${"%.4f".format(rms)} gain=${"%.1f".format(gain)} tokens=${result.tokens.joinToString(" ")}")
                }
                if (result.keyword.isNotBlank()) {
                    spotter.reset(stream)
                    heard = true
                    break
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "listening stopped", e)
        } finally {
            try {
                recorder.stop()
            } catch (_: Exception) {
            }
            recorder.release()
            stream.release()
        }
        if (thread === Thread.currentThread()) thread = null
        if (heard) {
            Log.i(TAG, "Hey Shefi heard on the device")
            main.post { onHeard("") }
        } else if (active) {
            // Stopped by an error rather than by a pause: start again.
            retryLater(2_000)
        }
    }

    // Debug only: what the model hears (after gain), the last 30 seconds in
    // order, 16 kHz mono 16-bit, rewritten every second to the app's
    // external files folder (adb pull …/files/kws_dump.pcm). Allocated on
    // the first dump (about 1 MB), so a listener without the debug log tag
    // never holds it. Only the audio thread touches it; successive threads
    // are ordered by Thread.start, and the default synchronized lazy covers
    // the publication anyway.
    private val ring by lazy { ShortArray(30 * RATE) }
    private var ringPos = 0
    private var ringFilled = false
    private var sinceWrite = 0

    private fun dump(samples: FloatArray, count: Int) {
        for (i in 0 until count) {
            ring[ringPos] = (samples[i] * 32767f).toInt().toShort()
            ringPos = (ringPos + 1) % ring.size
            if (ringPos == 0) ringFilled = true
        }
        sinceWrite += count
        if (sinceWrite < RATE) return
        sinceWrite = 0
        try {
            val total = if (ringFilled) ring.size else ringPos
            val bytes = java.nio.ByteBuffer.allocate(total * 2).order(java.nio.ByteOrder.LITTLE_ENDIAN)
            val first = if (ringFilled) ringPos else 0
            for (i in 0 until total) bytes.putShort(ring[(first + i) % ring.size])
            java.io.File(app.getExternalFilesDir(null), "kws_dump.pcm").writeBytes(bytes.array())
        } catch (_: Exception) {
        }
    }

    private fun retryLater(ms: Long) {
        if (thread === Thread.currentThread()) thread = null
        main.postDelayed({ launch() }, ms)
    }

    companion object {
        private const val TAG = "WakeWord"
        private const val RATE = 16_000
        private const val CHUNK = 1_600 // 100 ms
        private const val TARGET_LEVEL = 0.12f
        private const val MAX_GAIN = 10f

        // One model per process: loading it takes a moment and some memory.
        @Volatile private var shared: KeywordSpotter? = null

        @Synchronized
        private fun KwsListener.spotter(): KeywordSpotter? {
            shared?.let { return it }
            return try {
                val config = KeywordSpotterConfig().apply {
                    featConfig = FeatureConfig().apply {
                        sampleRate = RATE
                        featureDim = 80
                    }
                    modelConfig = OnlineModelConfig().apply {
                        transducer = OnlineTransducerModelConfig().apply {
                            encoder = "kws/encoder.int8.onnx"
                            decoder = "kws/decoder.onnx"
                            joiner = "kws/joiner.int8.onnx"
                        }
                        tokens = "kws/tokens.txt"
                        numThreads = 1
                        provider = "cpu"
                    }
                    keywordsFile = "kws/keywords.txt"
                    maxActivePaths = 4
                }
                KeywordSpotter(app.assets, config).also { shared = it }
            } catch (e: Throwable) {
                Log.e(TAG, "keyword model failed to load", e)
                null
            }
        }
    }
}
