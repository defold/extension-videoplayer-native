
# extension-videoplayer-native

This is a fullscreen videoplayer extension for **iOS** and **Android** using native OS functionality and components for videoplayback.

# Usage

Add the package link (https://github.com/defold/extension-videoplayer-native/archive/master.zip)
to the project setting `project.dependencies`, and you should be good to go.

See the [manual](http://www.defold.com/manuals/libraries/) for further info.

# Lua API

## videoplayer.create(uri, settings, callback)

Opens a video from either a uri, and returns a handle to the videoplayer.
    
```lua
function videoplayer_callback(self, video, event, data={})
    ...
end

self.handle = videoplayer.create("/assets/big_buck_bunny_720p_1mb.mp4", {play_sound = true}, videoplayer_callback)
```

## videoplayer.destroy(handle)

Destroys the video


## videoplayer.set_visible(handle, visible)

Shows or hides the video player view


## videoplayer.start(handle) / videoplayer.stop(handle) / videoplayer.pause(handle)


# Example

*[player.gui_script](main/player.gui_script):*
    
```lua

local function video_callback(self, video, event, data)
    if event == videoplayer.VIDEO_EVENT_READY then
        videoplayer.start(video)
    elseif event == videoplayer.VIDEO_EVENT_FINISHED then
        videoplayer.destroy(video)
        self.handle = nil
    end
end

local function window_callback(self, event, data)
    if not self.handle then
        return
    end

    if event == window.WINDOW_EVENT_FOCUS_LOST then
        videoplayer.pause(self.handle)
    elseif event == window.WINDOW_EVENT_FOCUS_GAINED then
        videoplayer.start(self.handle)
    end
end

function init(self)
    window.set_listener(window_callback)
    if videoplayer then
        self.handle = videoplayer.create("video.mp4", {play_sound = true}, video_callback)
    end
end
```


# Limitations

## Android

The android implementation uses the [MediaPlayer](https://developer.android.com/reference/android/media/MediaPlayer) in combination with a [SurfaceView](https://developer.android.com/reference/android/view/SurfaceView) to display the video.

Here's a list of [Supported Video Formats](https://developer.android.com/guide/topics/media/media-formats)


# iOS
TODO
