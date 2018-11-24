package com.defold.android.videoplayer;

import android.content.Context;
import android.util.Log;

// TODO: Remove this class

class VideoplayerExtension {
    public static final String TAG = "defold-videoplayer";

    private static void LOG(String message) {
        Log.v("defold-videoplayer", message);
    }

    public static Movie Create(final Context context, String uri, int id) {
        LOG("VideoplayerExtension: Creating video");
        return new Movie(context, uri, id);
    }
    public static void Destroy(Movie movie) {
        LOG("VideoplayerExtension: Destroy video");
        movie.destroy();
    }

    public static void SetVisible(Movie movie, int visible) {
        LOG("VideoplayerExtension: SetVisible");
        movie.setVisible(visible);
    }
    public static void Start(Movie movie) {
        LOG("VideoplayerExtension: Starting video");
        movie.start();
    }
    public static void Stop(Movie movie) {
        LOG("VideoplayerExtension: Stopping video");
        movie.stop();
    }
    public static void Pause(Movie movie) {
        LOG("VideoplayerExtension: Pausing video");
        movie.pause();
    }
}
