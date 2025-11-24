
# extension-videoplayer-native

Fullscreen videoplayer extension for **iOS**, **macOS**, **Android**, and **HTML5** using native OS components or a web `<video>` overlay.

# Usage

Add the package link (https://github.com/defold/extension-videoplayer-native/archive/master.zip)
to the project setting `project.dependencies`.


See the [manual](http://www.defold.com/manuals/libraries/) for further info.

# Lua API

## videoplayer.create(uri, settings, callback)

Opens a video from either a uri, and returns a handle to the videoplayer.
`settings.play_sound` (default true) controls whether audio is muted.
    
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

## HTML5

- Uses a single `<video>` element layered above the canvas; one handle at a time.
- Autoplay with sound requires a user gesture on most browsers; start playback after a tap/click.
- Element is hidden with `set_visible(false)`; positioning is fullscreen by default.

## Android

The android implementation uses the [MediaPlayer](https://developer.android.com/reference/android/media/MediaPlayer) in combination with a [SurfaceView](https://developer.android.com/reference/android/view/SurfaceView) to display the video.

Here's a list of [Supported Video Formats](https://developer.android.com/guide/topics/media/media-formats)

# macOS

- Uses `AVPlayer`/`AVPlayerViewController` in a fullscreen window layered over the Defold view.
- One video at a time; `set_visible(false)` hides but keeps the player alive.
- H.264/AAC is the safest choice; other codecs depend on system support.


# iOS

- Uses `AVPlayer`/`AVPlayerViewController` for playback with system controls hidden.
- Plays fullscreen above the Defold view; visibility is controlled via `set_visible`.
- Supports H.264/AAC streams and local/bundled files resolvable via `videoplayer.create` URI.
- Pause/resume is handled in the sample by window focus callbacks; adopt similar handling if your app relies on focus changes.
