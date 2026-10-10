# sherpa-onnx ("Hey Shefi" on the phone): its native code reads the Kotlin
# config classes' fields by name over JNI, so R8 must leave them unrenamed.
-keep class com.k2fsa.sherpa.onnx.** { *; }
