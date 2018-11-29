package com.defold.android.videoplayer;

import android.app.Activity;

import android.content.res.AssetFileDescriptor;
import android.content.Context;
import android.media.MediaPlayer;
import android.net.Uri;

import android.view.Gravity;
import android.view.SurfaceHolder;
import android.view.View;
import android.view.ViewGroup.LayoutParams;
import android.view.ViewGroup.MarginLayoutParams;
import android.view.WindowManager;
import android.widget.LinearLayout;

import java.lang.Runnable;

import java.io.IOException;
import java.io.FileNotFoundException;
import java.lang.IllegalStateException;
import java.lang.IllegalArgumentException;

class Movie implements
	MediaPlayer.OnPreparedListener,
	MediaPlayer.OnCompletionListener {

	private static final String LINK = "http://mirrors.standaloneinstaller.com/video-sample/Panasonic_HDC_TM_700_P_50i.mp4";
	//private static final String FILE = "big_buck_bunny_720p_1mb.mp4";
	private static final String FILE = "cutscene_3.mp4";

	private int id;
	private String uri;

	private Activity activity;

	private MediaPlayer mediaPlayer;
	private VideoView videoView;
	private int currentPosition;

	private LinearLayout layout;

	boolean destroyed;


	// Add more functions callback to C to convey messages
	private native void videoIsReady(int id, int width, int height);
	private native void videoIsFinished(int id);

	public Movie(final Context context, String _uri, int _id){
		Logger.log("Movie: Movie()");
		uri = _uri;
		id = _id;

		destroyed = false;

		activity = (Activity)context;

		final Movie instance = this;
		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				instance.setup();
			}
		});
	}

	private void setup() {
		Logger.log("Movie: setup()");

		currentPosition = 0;

		mediaPlayer = new MediaPlayer();
		mediaPlayer.setScreenOnWhilePlaying(true);
		mediaPlayer.setOnPreparedListener(this);
		mediaPlayer.setOnCompletionListener(this);

		Logger.log("Movie: new VideoView");
		videoView = new VideoView((Context)activity);

		final Movie instance = this;
		videoView.getHolder().addCallback(new SurfaceHolder.Callback(){
			@Override
			public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
				Logger.log("Movie: surfaceChanged");
			}

			@Override
			public void surfaceCreated(SurfaceHolder holder) {
				Logger.log("Movie: surfaceCreated");
				if(destroyed)return;

				try{
					instance.mediaPlayer.setDisplay(holder);
					instance.mediaPlayer.reset();
					setDataSource();
					instance.mediaPlayer.prepareAsync();
				}catch(IllegalStateException e) {
					Logger.log(e.toString());
				}
			}

			@Override
			public void surfaceDestroyed(SurfaceHolder holder) {
				Logger.log("Movie: surfaceDestroyed");
				if(destroyed)return;

				instance.currentPosition = instance.mediaPlayer.getCurrentPosition();
				instance.mediaPlayer.reset();
			}
		});

		MarginLayoutParams params = new MarginLayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT);
		params.setMargins(0, 0, 0, 0);

		layout = new LinearLayout(activity);
		layout.setOrientation(LinearLayout.VERTICAL);
		layout.setGravity(Gravity.CENTER);
		layout.addView(videoView, params);
		layout.setSystemUiVisibility(
			View.SYSTEM_UI_FLAG_LAYOUT_STABLE
			| View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
			| View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
			| View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
			| View.SYSTEM_UI_FLAG_FULLSCREEN
			| View.SYSTEM_UI_FLAG_IMMERSIVE
		);

		WindowManager.LayoutParams windowParams = new WindowManager.LayoutParams();
		windowParams.gravity = Gravity.CENTER;
		windowParams.x = Gravity.CENTER;
		windowParams.y = Gravity.CENTER;
		windowParams.width = WindowManager.LayoutParams.MATCH_PARENT;
		windowParams.height = WindowManager.LayoutParams.MATCH_PARENT;
		windowParams.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL;

		WindowManager wm = activity.getWindowManager();
		wm.addView(layout, windowParams);

		Logger.log("Movie: setup() end");
	}

	private void setDataSource() {
		try {
			String path = uri;
			Logger.log("Movie: openFd(): " + path);
			AssetFileDescriptor afd = activity.getAssets().openFd(path);
			mediaPlayer.setDataSource(afd.getFileDescriptor(),afd.getStartOffset(),afd.getLength());
			afd.close();
			//mediaPlayer.setDataSource(LINK);
		} catch (IllegalStateException e) {
			Logger.log(e.toString());
		} catch (IllegalArgumentException e) {
			Logger.log(e.toString());
		} catch (IOException e) {
			Logger.log(e.toString());
		}
	}

	@Override
	public void onPrepared(final MediaPlayer mediaPlayer){
		Logger.log("Movie: Movie onPrepared()");

		videoView.setSize(mediaPlayer.getVideoWidth(), mediaPlayer.getVideoHeight());

		try{
			mediaPlayer.seekTo(currentPosition);
		}catch(IllegalStateException e) {
			Logger.log(e.toString());
		}

		videoIsReady(id, mediaPlayer.getVideoWidth(), mediaPlayer.getVideoHeight()); // Call into the native code
	}

	@Override
	public void onCompletion(MediaPlayer mp) {
		Logger.log("Movie: onCompletion");
		videoIsFinished(id);
	}

	public void destroy(){
		Logger.log("Movie: destroy()");

		destroyed = true;
		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				if (mediaPlayer != null) {
					mediaPlayer.release();
					mediaPlayer = null;
				}

				WindowManager wm = activity.getWindowManager();
				wm.removeView(layout);
			}
		});
	}

	private void setVisibleInternal(int visible)
	{
		videoView.setVisibility((visible != 0) ? View.VISIBLE : View.GONE);
	}

	public void setVisible(final int visible) {
		Logger.log("Movie: setVisible()");
		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				setVisibleInternal(visible);
			}
		});
	}

	public int isVisible() {
		return videoView.isShown() ? 1 : 0;
	}

	public void start(){
		Logger.log("Movie: Movie start()");
		mediaPlayer.start();
	}

	public void stop(){
		Logger.log("Movie: Movie stop()");
		mediaPlayer.stop();
	}

	public void pause(){
		Logger.log("Movie: Movie pause()");
		mediaPlayer.pause();
	}
}
