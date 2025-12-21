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
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.IllegalStateException;
import java.lang.IllegalArgumentException;

class Movie implements
	MediaPlayer.OnPreparedListener,
	MediaPlayer.OnCompletionListener {

	private int id;
	private String uri;
	private boolean playSound;

	private Activity activity;

	private MediaPlayer mediaPlayer;
	private VideoView videoView;
	private int currentPosition;

	private LinearLayout layout;

	private File cachedAssetFile;

	boolean destroyed;


	// Add more functions callback to C to convey messages
	private native void videoIsReady(int id, int width, int height);
	private native void videoIsFinished(int id);

	public Movie(final Context context, String _uri, int _id, boolean _playSound){
		Logger.log("Movie: Movie()");
		uri = _uri;
		id = _id;
		playSound = _playSound;

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
		if(playSound){
			mediaPlayer.setVolume(1.0f, 1.0f);
		}else{
			mediaPlayer.setVolume(0.0f, 0.0f);
		}

		Logger.log("Movie: new VideoView");
		videoView = new VideoView((Context)activity);
		videoView.setScaleMode(VideoView.ScaleMode.Fit);
		videoView.setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);

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

	// Resolve the media source:
	// 1) Non-asset URI/path -> pass through to MediaPlayer (URI or file path).
	// 2) Asset path -> try openFd() for uncompressed assets; if that fails (compressed),
	//    copy to cache and point MediaPlayer at the cached file.
	private void setDataSource() {
		String path = uri;
		try {
			if (!isAssetPath(path)) {
				Logger.log("Movie: setDataSource(): " + path);
				if (path.startsWith("http://") || path.startsWith("https://") || path.startsWith("content://") || path.startsWith("file://")) {
					mediaPlayer.setDataSource(activity, Uri.parse(path));
				} else {
					mediaPlayer.setDataSource(path);
				}
				return;
			}

			try (AssetFileDescriptor afd = activity.getAssets().openFd(path)) {
				Logger.log("Movie: openFd(): " + path);
				mediaPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
				return;
			} catch (FileNotFoundException e) {
				// Some packaging pipelines compress assets; compressed assets can't be opened with openFd().
				Logger.log("Movie: openFd() failed, falling back to cache copy: " + e.toString());
			}

			File cached = ensureAssetCopiedToCache(path);
			Logger.log("Movie: setDataSource(cache): " + cached.getAbsolutePath());
			mediaPlayer.setDataSource(cached.getAbsolutePath());
		} catch (IllegalStateException e) {
			Logger.log(e.toString());
		} catch (IllegalArgumentException e) {
			Logger.log(e.toString());
		} catch (IOException e) {
			Logger.log(e.toString());
		}
	}

	private boolean isAssetPath(String path) {
		return path != null && !path.startsWith("/") && path.indexOf("://") == -1;
	}

	private File ensureAssetCopiedToCache(String assetPath) throws IOException {
		if (cachedAssetFile != null && cachedAssetFile.exists() && cachedAssetFile.length() > 0) {
			return cachedAssetFile;
		}

		File cacheDir = new File(activity.getCacheDir(), "videoplayer-assets");
		if (!cacheDir.exists() && !cacheDir.mkdirs()) {
			throw new IOException("Failed to create cache dir: " + cacheDir.getAbsolutePath());
		}

		String safeName = assetPath.replace('/', '_').replace('\\', '_');
		File outFile = new File(cacheDir, safeName);

		if (outFile.exists() && outFile.length() > 0) {
			cachedAssetFile = outFile;
			return outFile;
		}

		try (InputStream in = activity.getAssets().open(assetPath);
			 OutputStream out = new FileOutputStream(outFile)) {
			byte[] buffer = new byte[64 * 1024];
			int read;
			while ((read = in.read(buffer)) != -1) {
				out.write(buffer, 0, read);
			}
			out.flush();
		}

		cachedAssetFile = outFile;
		return outFile;
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

				if (cachedAssetFile != null) {
					// Best-effort cleanup; log failures for diagnostics.
					boolean deleted = cachedAssetFile.delete();
					if (!deleted) {
						Logger.log("Movie: cache delete failed: " + cachedAssetFile.getAbsolutePath());
					}
					cachedAssetFile = null;
				}
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
