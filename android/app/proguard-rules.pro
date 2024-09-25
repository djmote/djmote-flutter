-keep class com.trackingauthoritymusic.BuildConfig { *; }
-keep class com.pickupmvp.BuildConfig { *; }
-keep class com.rapruler.BuildConfig { *; }
-keep class com.fantasyjams.BuildConfig { *; }
-keep class com.djmote.app.BuildConfig { *; }


# APP LINKS RULES -- START
# SPDX-FileCopyrightText: 2016, microG Project Team
# SPDX-License-Identifier: CC0-1.0

# Keep AutoSafeParcelables
-keep public class * extends org.microg.safeparcel.AutoSafeParcelable {
    @org.microg.safeparcel.SafeParcelable.Field *;
    @org.microg.safeparcel.SafeParceled *;
}

# Keep asInterface method cause it's accessed from SafeParcel
-keepattributes InnerClasses
-keepclassmembers interface * extends android.os.IInterface {
    public static class *;
}
-keep public class * extends android.os.Binder { public static *; }
# APP LINKS RULES -- END
