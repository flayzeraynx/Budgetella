# Project-specific ProGuard rules.

# Kotlinx Serialization — keep @Serializable types' generated companions.
-keepclasseswithmembers class **$$serializer { *; }
-keepclassmembers class kotlinx.serialization.json.** { *; }
-keep,includedescriptorclasses class com.budgetella.app.**$$serializer { *; }
-keepclassmembers class com.budgetella.app.** { *** Companion; }
-keepclasseswithmembers class com.budgetella.app.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Firebase Firestore — model classes are reflected over.
-keepclassmembers class com.budgetella.app.data.model.** {
    *;
}

# Room
-keep class * extends androidx.room.RoomDatabase
-dontwarn androidx.room.paging.**

# Hilt / Dagger
-keep,allowobfuscation,allowshrinking @dagger.hilt.* class *
-keep class hilt_aggregated_deps.** { *; }

# Crashlytics
-keepattributes SourceFile,LineNumberTable
