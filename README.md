
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

Add the package link (https://github.com/defold/extension-videoplayer/archive/master.zip)
to the project setting `project.dependencies`, and you should be good to go.

See the [manual](http://www.defold.com/manuals/libraries/) for further info.


# Lua API

## videoplayer.create(src=videoresource)

Opens a video from either a buffer or a link, and returns a handle to the videoplayer.
    
    function videoplayer_callback(self, video, event, data={})
        ...
    end

    local videoresource = resource.load("/assets/big_buck_bunny_720p_1mb.mp4")
    self.video = videoplayer.create(uri, settings={}, videoplayer_callback)

Where the `callback_fn` has the format:

    ...

## videoplayer.destroy(video)

Destroys the video


## videoplayer.set_visible(video, visible)

Shows or hides the video player view


## videoplayer.play(video) / videoplayer.stop(video) / videoplayer.pause(video)


# Example

*[main.script](main/main.script):*

    function init(self)
        local logosize = 128
        local screen_width = sys.get_config("display.width", 600)
        local screen_height = sys.get_config("display.height", 800)
        local scale_width = screen_width / logosize
        local scale_height = screen_height / logosize

        go.set("#sprite", "scale", vmath.vector3(scale_width, scale_height, 1) )

        if videoplayer ~= nil then
            local videoresource = resource.load("/videos/big_buck_bunny.webm")
            self.video = videoplayer.open(videoresource)
            self.videoinfo = videoplayer.get_info(self.video)
            self.videoheader = { width=self.videoinfo.width, height=self.videoinfo.height, type=resource.TEXTURE_TYPE_2D, format=resource.TEXTURE_FORMAT_RGB, num_mip_maps=1 }
            self.videoframe = videoplayer.get_frame(self.video)
        else
            print("Could not initialize videoplayer")
        end
    end

    function update(self, dt)
        if videoplayer ~= nil then
            videoplayer.update(self.video, dt)
            local path = go.get("#sprite", "texture0")
            resource.set_texture(path, self.videoheader, self.videoframe)
        end
    end

