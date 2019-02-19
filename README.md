
# extension-videoplayer-native

This is a full-screen videoplayer extension for iOS, Android, OSX and Windows.

# Usage

Add the package link (https://github.com/defold/extension-videoplayer-native/archive/master.zip)
to the project setting `project.dependencies`, and you should be good to go.

See the [manual](http://www.defold.com/manuals/libraries/) for further info.


# Lua API

## videoplayer.create(uri, settings, callback)

Opens a video from either a buffer or a link, and returns a handle to the videoplayer.
    
```lua
function videoplayer_callback(self, video, event, data={})
    ...
end

local videoresource = resource.load("/assets/big_buck_bunny_720p_1mb.mp4")
self.handle = videoplayer.create(uri, {}, videoplayer_callback)
```

## videoplayer.destroy(handle)

Destroys the video


## videoplayer.set_visible(handle, visible)

Shows or hides the video player view


## videoplayer.play(handle) / videoplayer.stop(handle) / videoplayer.pause(handle)


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
        self.handle = videoplayer.create("video.mp4", {}, video_callback)
    end
end
```
