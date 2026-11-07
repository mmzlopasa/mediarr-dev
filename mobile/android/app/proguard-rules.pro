# WorkManager, which runs the backup, keeps its queue in a Room database that is made by name when
# the app starts. When a plugin brings a newer Room than WorkManager was built with, R8 can remove
# that constructor, and the release build stops on start (NoSuchMethodException:
# androidx.work.impl.WorkDatabase_Impl.<init>). These keep every Room database whole.
-keep class * extends androidx.room.RoomDatabase { <init>(...); }
-keep class androidx.work.impl.WorkDatabase_Impl { *; }
-keepclassmembers class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
