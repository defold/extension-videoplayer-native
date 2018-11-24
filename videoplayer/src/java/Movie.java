package com.defold.android.videoplayer;

import android.app.Activity;

import android.content.res.AssetFileDescriptor;
import android.content.Context;
import android.media.MediaPlayer;
import android.net.Uri;

import android.view.Gravity;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceHolder.Callback;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewGroup.LayoutParams;
import android.view.ViewGroup.MarginLayoutParams;
import android.view.Window;
import android.view.WindowManager;
import android.widget.LinearLayout;

import java.lang.Runnable;

import android.util.Log;
import java.io.File;
import java.io.IOException;
import java.io.FileNotFoundException;

import java.io.InputStream;

class Movie implements MediaPlayer.OnPreparedListener {

    private static void LOG(String message) {
        Log.v("defold-videoplayer", message);
    }

    private static final String LINK = "https://www.sample-videos.com/video/mp4/720/big_buck_bunny_720p_1mb.mp4";
    private static final String FILE = "big_buck_bunny_720p_1mb.mp4";

    private int id;
    private String uri;

    private boolean isReady;
    private boolean firstShow;
    private MediaPlayer mediaPlayer;

    private SurfaceView surfaceView;
    private Surface surface;
    private LinearLayout layout;
    private WindowManager.LayoutParams windowParams;

    private Activity activity;

    // Add more functions callback to C to convey messages
    private native void videoIsReady(int id, int width, int height);

    private static void setup(final Movie instance, Context context) {
        LOG("MOVIE: setup()");
        final Activity activity = (Activity)context;

        instance.mediaPlayer = new MediaPlayer();

        try {
            // FILE ACCESS:
            //instance.mediaPlayer.setDataSource(context, Uri.fromFile(new File(FILE)), null);
            //instance.mediaPlayer.setDataSource(context, instance.videoSource, null);
            //AssetFileDescriptor afd = context.getResources().getAssets().openFd("cutscene_1.webm");

            // InputStream is = context.getResources().getAssets().open("cutscene_1.webm");
            // String s = getStringFromInputStream(is);
            // LOG("MOVIE: HELOOO");
            // LOG(s);
            String path = FILE; // instance.uri;
            LOG("MOVIE: uri: " + instance.uri);
            LOG("MOVIE: openFd(): " + path);
            AssetFileDescriptor afd = context.getResources().getAssets().openFd(path);
            instance.mediaPlayer.setDataSource(afd.getFileDescriptor(),afd.getStartOffset(),afd.getLength());
            //instance.mediaPlayer.setDataSource(LINK);
        } catch (FileNotFoundException e) {
            LOG(e.toString());
            return;
        } catch (IOException e) {
            LOG(e.toString());
            return;
        }
        instance.mediaPlayer.setOnPreparedListener(instance);

        LOG("MOVIE: new SurfaceView");
        instance.surfaceView = new SurfaceView(context);
        ViewGroup viewGroup = (ViewGroup)activity.findViewById(android.R.id.content);
        //viewGroup.addView(instance.surfaceView, 400, 400);
        viewGroup.addView(instance.surfaceView, new ViewGroup.LayoutParams(400, 400));
        //instance.surfaceView.setVisibility(View.GONE);
        //instance.surfaceView.setVisibility(View.INVISIBLE);
        // int index = viewGroup.indexOfChild(instance.surfaceView);
        // for(int i = 0; i<index; i++)
        // {
        //     viewGroup.bringChildToFront(viewGroup.getChildAt(i));
        // }

        LOG("MOVIE: instance.surfaceView.getHolder");
        SurfaceHolder holder = instance.surfaceView.getHolder();
        holder.addCallback(new Callback(){
            @Override
            public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
                LOG("MOVIE: surfaceChanged");
            }

            @Override
            public void surfaceCreated(SurfaceHolder holder) {
                LOG("MOVIE: surfaceCreated");
                instance.surface = holder.getSurface();
                instance.mediaPlayer.prepareAsync();
            }

            @Override
            public void surfaceDestroyed(SurfaceHolder holder) {
                LOG("MOVIE: surfaceDestroyed");
            }
        });

        // mediaPlayer.setOnErrorListener(new MediaPlayer.OnErrorListener() {
        //         @Override
        //         public boolean onError(MediaPlayer mp, int what, int extra) {
        //             if (extra == MediaPlayer.MEDIA_ERROR_SERVER_DIED
        //                     || extra == MediaPlayer.MEDIA_ERROR_MALFORMED) {
        //                 LOG("MOVIE: error on playing");
        //             } else if (extra == MediaPlayer.MEDIA_ERROR_IO) {
        //                 LOG("MOVIE: error on playing");
        //                 return false;
        //             }
        //             return false;
        //         }
        //     });

        // mPlayer.setOnBufferingUpdateListener(new MediaPlayer.OnBufferingUpdateListener() {
        //     public void onBufferingUpdate(MediaPlayer mp, int percent) {
        //         Log.e("onBufferingUpdate", "" + percent);
        //     }
        // });

        instance.mediaPlayer.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
            @Override
            public void onCompletion(MediaPlayer mp) {
                LOG("MOVIE: onCompletion: Yes");
                //sendPlayerStatus("completed");
            }
        });

        // instance.mediaPlayer.setOnInfoListener(new MediaPlayer.OnInfoListener() {
        //     @Override
        //     public boolean onInfo(MediaPlayer mp, int what, int extra) {
        //      LOG("MOVIE: onInfo");
        //         return false;
        //     }
        // });

        MarginLayoutParams params = new MarginLayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT);
        params.setMargins(0, 0, 0, 0);

        LinearLayout layout = new LinearLayout(activity);
        layout.setOrientation(LinearLayout.VERTICAL); // option?
        layout.addView(instance.surfaceView, params);

        instance.layout = layout;
        instance.firstShow = true;

        instance.windowParams = new WindowManager.LayoutParams();
        instance.windowParams.gravity = Gravity.TOP | Gravity.LEFT;
        instance.windowParams.x = WindowManager.LayoutParams.MATCH_PARENT;
        instance.windowParams.y = WindowManager.LayoutParams.MATCH_PARENT;
        instance.windowParams.width = WindowManager.LayoutParams.MATCH_PARENT;
        instance.windowParams.height = WindowManager.LayoutParams.MATCH_PARENT;
        instance.windowParams.flags = WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL;

        instance.layout.setLayoutParams(instance.windowParams);

        LOG("MOVIE: setup() end");
    }

    public Movie(final Context context, String _uri, int _id){
        LOG("MOVIE: Movie()");
        uri = _uri;
        id = _id;

        isReady = false;

        this.activity = (Activity)context;

        final Movie instance = this;
        this.activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                Movie.setup(instance, context);
            }
        });
    }

    @Override
    public void onPrepared(MediaPlayer mediaPlayer){
        LOG("MOVIE: Movie onPrepared()");
        mediaPlayer.setSurface(surface);
        isReady = true;

        videoIsReady(id, mediaPlayer.getVideoWidth(), mediaPlayer.getVideoHeight()); // Call into the native code
    }

    public void destroy(){
        LOG("MOVIE: Movie destroy()");
        if (mediaPlayer != null) {
            mediaPlayer.stop();
            mediaPlayer.release();
        }
    }

    // public void update() {
    //     if(canvas == null || (mediaPlayer != null && !mediaPlayer.isPlaying())) {
    //         return;
    //     }

    //     //LOG("MOVIE: Movie Update");
    // }


    private void setVisibleInternal(int visible)
    {
        surfaceView.setVisibility((visible != 0) ? View.VISIBLE : View.GONE);
        if( visible != 0 && firstShow )
        {
            firstShow = false;
            WindowManager wm = activity.getWindowManager();
            wm.addView(layout, windowParams);
        }
    }

    public void setVisible(final int visible) {
        LOG("MOVIE: Movie setVisible()");
        activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                setVisibleInternal(visible);
            }
        });
    }

    public int isVisible(final int id) {
        return surfaceView.isShown() ? 1 : 0;
    }

    private void setPositionInternal(int x, int y, int width, int height)
    {
        windowParams.x = x;
        windowParams.y = y;
        windowParams.width = width >= 0 ? width : WindowManager.LayoutParams.MATCH_PARENT;
        windowParams.height = height >= 0 ? height : WindowManager.LayoutParams.MATCH_PARENT;

        if (surfaceView.getVisibility() == View.VISIBLE) {
            WindowManager wm = activity.getWindowManager();
            wm.updateViewLayout(layout, windowParams);
        }
    }

    public void setPosition(final int x, final int y, final int width, final int height) {
        this.activity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                setPositionInternal(x, y, width, height);
            }
        });
    }

    public void start(){
        LOG("MOVIE: Movie start()");

        mediaPlayer.setLooping(true); // only for debugging purposes, should be a separate setting or function
        //mediaPlayer.setScreenOnWhilePlaying(true); // seemed to crash after a while?
        mediaPlayer.start();
    }

    public void stop(){
        LOG("MOVIE: Movie stop()");
        mediaPlayer.stop();
    }

    public void pause(){
        LOG("MOVIE: Movie pause()");
        mediaPlayer.pause();
    }
}
