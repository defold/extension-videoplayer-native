package com.defold.android.videoplayer;

import android.content.Context;

// TODO: Remove this class
class VideoplayerExtension {
	public static final String TAG = "defold-videoplayer";

	public static Movie Create(final Context context, String uri, int id) {
		Logger.log("VideoplayerExtension: Creating video");
		return new Movie(context, uri, id);
	}
	public static void Destroy(Movie movie) {
		Logger.log("VideoplayerExtension: Destroy video");
		movie.destroy();
	}

	public static void SetVisible(Movie movie, int visible) {
		Logger.log("VideoplayerExtension: SetVisible");
		movie.setVisible(visible);
	}
	public static void Start(Movie movie) {
		Logger.log("VideoplayerExtension: Starting video");
		movie.start();
	}
	public static void Stop(Movie movie) {
		Logger.log("VideoplayerExtension: Stopping video");
		movie.stop();
	}
	public static void Pause(Movie movie) {
		Logger.log("VideoplayerExtension: Pausing video");
		movie.pause();
	}
}
