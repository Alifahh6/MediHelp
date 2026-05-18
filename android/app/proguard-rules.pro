# flutter_local_notifications — fix TypeToken error (ProGuard/R8)
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }