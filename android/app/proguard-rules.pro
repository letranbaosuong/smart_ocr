############################
# KEEP FLUTTER SDK
############################
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

############################
# ML Kit Text Recognition
############################
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

############################
# Google Mobile Ads
############################
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

############################
# Google Translate API / Translator package
############################
-keep class com.google.cloud.translate.** { *; }
-dontwarn com.google.cloud.translate.**

############################
# Kotlin & Coroutines (nếu có dùng)
############################
-dontwarn kotlin.**
-keep class kotlin.** { *; }
-keepclassmembers class kotlin.** { *; }

############################
# Prevent Obfuscation of Flutter Plugin Registrants
############################
-keep class *PluginRegistrant** { *; }

############################
# Optional: Keep all public classes & methods in your app (safer)
############################
-keep public class * {
    public protected *;
}
