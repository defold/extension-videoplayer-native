package com.defold.android.videoplayer;

import android.content.Context;

// TODO: Remove this class
class VideoplayerExtension {
	public static final String TAG = "defold-videoplayer";


	public static Movie Create(final Context context, String uri, int id, boolean playSound) {
		Logger.log("VideoplayerExtension: Creating video");
		return new Movie(context, uri, id, playSound);
	}
	public static void Destroy(Movie movie) {
		Logger.log("VideoplayerExtension: Destroy video");
		if(!IsValid(movie))return;
		movie.destroy();
	}

	public static void SetVisible(Movie movie, int visible) {
		Logger.log("VideoplayerExtension: SetVisible");
		if(!IsValid(movie))return;
		movie.setVisible(visible);
	}
	public static void Start(Movie movie) {
		Logger.log("VideoplayerExtension: Starting video");
		if(!IsValid(movie))return;
		movie.start();
	}
	public static void Stop(Movie movie) {
		Logger.log("VideoplayerExtension: Stopping video");
		if(!IsValid(movie))return;
		movie.stop();
	}
	public static void Pause(Movie movie) {
		Logger.log("VideoplayerExtension: Pausing video");
		if(!IsValid(movie))return;
		movie.pause();
	}

	private static boolean IsValid(Movie movie){
		if(movie==null){
			Logger.log("VideoplayerExtension: ERROR: movie==null");
			return false;
		}
		return true;
	}
}
