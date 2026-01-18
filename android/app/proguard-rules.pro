 # Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 保持自定义的模型类
-keep class com.airlur.breeze.models.** { *; }

# 移除调试日志
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# 优化数字操作
-optimizations !code/simplification/arithmetic

# 移除未使用的资源
-keep class **.R$* {
    public static final int *;
}

# Google ML Kit 忽略缺失语言包警告
# 因为我们只依赖了中文包，所以忽略其他语言包的缺失警告
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.latin.**