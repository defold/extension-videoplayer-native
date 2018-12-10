
# extension-videoplayer-native


# MVP 1

* Lua api: create/destroy (with callback function), show/hide
* Only one view
* No set position/size
* No tap to escape

# MVP 2

* Tap to escape
* ...


# FAQ

## How do I use this extension?

Add the package link (https://github.com/defold/extension-videoplayer-native/archive/master.zip)
to the project setting `project.dependencies`, and you should be good to go.

See the [manual](http://www.defold.com/manuals/libraries/) for further info.


# Lua API

## videoplayer.create(src=videoresource)

Opens a video from either a buffer or a link, and returns a handle to the videoplayer.
    
```lua
function videoplayer_callback(self, video, event, data={})
    ...
end

local videoresource = resource.load("/assets/big_buck_bunny_720p_1mb.mp4")
self.video = videoplayer.create(uri, settings={}, videoplayer_callback)
```

Where the `callback_fn` has the format:

    ...

## videoplayer.destroy(video)

Destroys the video


## videoplayer.set_visible(video, visible)

Shows or hides the video player view


## videoplayer.play(video) / videoplayer.stop(video) / videoplayer.pause(video)


# Example

*[player.gui_script](main/player.gui_script):*
    
```lua
function video_callback(self, video, event, data)
    if event == videoplayer.VIDEO_EVENT_READY then
        videoplayer.start(video)
    elseif event == videoplayer.VIDEO_EVENT_FINISHED then
        video_end(self, video)
    end
end

function video_begin(self)
    if videoplayer then
        self.video = videoplayer.create("video.mp4", {}, video_callback)
    else
        print("Could not initialize fullscreen videoplayer (on this platform?)")
    end
end

function video_end(self, video)
    if video ~= nil then
        videoplayer.destroy(video)
    end

    self.video = nil;
end

function window_callback(self, event, data)
    if self.video == nil then
        return
    end

    if event == window.WINDOW_EVENT_FOCUS_LOST then
        videoplayer.pause(self.video)
    elseif event == window.WINDOW_EVENT_FOCUS_GAINED then
        videoplayer.start(self.video)
    end
end

function init(self)
    self.video = nil

    window.set_listener(window_callback)
    video_begin(self)
end
```
