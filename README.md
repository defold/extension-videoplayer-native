
# extension-videoplayer-native

[![Build with bob](https://github.com/defold/extension-videoplayer-native/actions/workflows/bob.yml/badge.svg)](https://github.com/defold/extension-videoplayer-native/actions/workflows/bob.yml)

Fullscreen videoplayer extension for **iOS**, **macOS**, **Android**, **Windows**, and **HTML5** using native OS components or a web `<video>` overlay.

# Usage

Add the package link (https://github.com/defold/extension-videoplayer-native/archive/master.zip)
to the project setting `project.dependencies`.

To use this library in your Defold project, add the needed version URL to your `game.project` dependencies from [Releases](https://github.com/defold/extension-videoplayer-native/releases)

<img width="401" alt="image" src="https://user-images.githubusercontent.com/2209596/202223571-c77f0304-5202-4314-869d-7a90bbeec5ec.png">

## Bundle Resources

To ship a video with your build, add it to Defold bundle resources so it ends up in the final app package.

1. Place the file in a project folder.
2. Add the path to `game.project` under `bundle_resources` (comma-separated list).
3. Use a relative URI when calling `videoplayer.create`, matching the bundled path (e.g. `video.mp4` if you bundle it from the project root, or `assets/video.mp4` if you bundle `/assets/video.mp4`).

Example `game.project` entry:
```
bundle_resources = /res
```

Bundled resources work on **iOS**, **macOS**, **Android**, **Windows**, and **HTML5**.

### Platform layout under `res/`

This project already bundles `/res` (see `game.project`), and uses per-platform subfolders:

- `res/android/assets/` → files land in the APK assets root; use `videoplayer.create("file.mp4", ...)`.
- `res/ios/assets/` → files land in the app bundle root; use `videoplayer.create("file.mp4", ...)`.
- `res/osx/` → files land in the macOS app bundle root; use `videoplayer.create("file.mp4", ...)`.
- `res/web/` → files are copied to the HTML5 build root; use `videoplayer.create("file.mp4", ...)`.

If you need a subfolder in the bundle, mirror it under the platform folder (e.g. `res/ios/assets/videos/intro.mp4` → `videoplayer.create("videos/intro.mp4", ...)`).

### Playing video in the editor

The sample GUI script uses an editor-only path when running from the Defold editor:

- In `main/player.gui_script`, `is_editor_build` selects `res/ios/assets/big_buck_bunny_720p_1mb.mp4`.
- In bundled builds, it uses the bundled root path `big_buck_bunny_720p_1mb.mp4`.

If you want a different editor video, place it under `res/ios/assets/` and update the editor path in `main/player.gui_script`.


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

# Windows

- Uses Media Foundation (`IMFMediaEngine`) for playback.
- Renders to a fullscreen child window layered above the Defold HWND.
- Supports H.264/AAC in MP4 containers and file/URL sources supported by the OS.
