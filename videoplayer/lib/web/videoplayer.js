var LibraryVideoplayer = {
    $DM_VIDEOPLAYER: {
        container: null,
        nextHandle: 0,
        videos: {},
        ensureContainer: function() {
            if (DM_VIDEOPLAYER.container) return DM_VIDEOPLAYER.container;

            var parent = document.getElementById('canvas');
            if (parent) {
                parent = parent.parentNode || document.body;
            } else {
                parent = document.body;
            }

            if (parent && (!parent.style.position || parent.style.position === 'static')) {
                parent.style.position = 'relative';
            }

            var container = document.createElement('div');
            container.id = 'dm-videoplayer-container';
            container.style.position = 'absolute';
            container.style.inset = '0';
            container.style.pointerEvents = 'none';
            container.style.overflow = 'hidden';
            parent.appendChild(container);

            DM_VIDEOPLAYER.container = container;
            return container;
        },
        dispatch: function(handle, event, video) {
            var width = video ? video.videoWidth : 0;
            var height = video ? video.videoHeight : 0;
            if (typeof Module !== 'undefined' && Module._dmVideoplayerDispatchEvent) {
                Module._dmVideoplayerDispatchEvent(handle, event, width, height);
            }
        }
    },

    dmVideoplayerHtml5Create__deps: ['$DM_VIDEOPLAYER'],
    dmVideoplayerHtml5Create: function(uriPtr, playSound) {
        var uri = UTF8ToString(uriPtr);
        var container = DM_VIDEOPLAYER.ensureContainer();

        var video = document.createElement('video');
        video.src = uri;
        video.preload = 'auto';
        video.playsInline = true;
        video.controls = false;
        video.autoplay = false;
        video.muted = !playSound;
        video.crossOrigin = 'anonymous';

        video.style.position = 'absolute';
        video.style.inset = '0';
        video.style.width = '100%';
        video.style.height = '100%';
        video.style.objectFit = 'contain';
        video.style.backgroundColor = 'black';
        video.style.pointerEvents = 'none';

        var handle = DM_VIDEOPLAYER.nextHandle++;

        var onReady = function() { DM_VIDEOPLAYER.dispatch(handle, 0, video); };
        var onEnded = function() { DM_VIDEOPLAYER.dispatch(handle, 1, video); };
        var onError = function() { DM_VIDEOPLAYER.dispatch(handle, 2, video); };

        video.addEventListener('loadeddata', onReady);
        video.addEventListener('ended', onEnded);
        video.addEventListener('error', onError);

        DM_VIDEOPLAYER.videos[handle] = {
            element: video,
            listeners: {
                loadeddata: onReady,
                ended: onEnded,
                error: onError
            }
        };

        container.appendChild(video);
        return handle;
    },

    dmVideoplayerHtml5Destroy__deps: ['$DM_VIDEOPLAYER'],
    dmVideoplayerHtml5Destroy: function(handle) {
        var data = DM_VIDEOPLAYER.videos[handle];
        if (!data) return;

        var video = data.element;
        video.pause();

        video.removeEventListener('loadeddata', data.listeners.loadeddata);
        video.removeEventListener('ended', data.listeners.ended);
        video.removeEventListener('error', data.listeners.error);

        if (video.parentNode) {
            video.parentNode.removeChild(video);
        }

        delete DM_VIDEOPLAYER.videos[handle];
    },

    dmVideoplayerHtml5Start__deps: ['$DM_VIDEOPLAYER'],
    dmVideoplayerHtml5Start: function(handle) {
        var data = DM_VIDEOPLAYER.videos[handle];
        if (!data) return;
        var video = data.element;

        var playPromise = video.play();
        if (playPromise && playPromise.catch) {
            playPromise.catch(function() {
                DM_VIDEOPLAYER.dispatch(handle, 2, video);
            });
        }
    },

    dmVideoplayerHtml5Stop__deps: ['$DM_VIDEOPLAYER'],
    dmVideoplayerHtml5Stop: function(handle) {
        var data = DM_VIDEOPLAYER.videos[handle];
        if (!data) return;
        var video = data.element;

        video.pause();
        try {
            video.currentTime = 0;
        } catch (e) {}
    },

    dmVideoplayerHtml5Pause__deps: ['$DM_VIDEOPLAYER'],
    dmVideoplayerHtml5Pause: function(handle) {
        var data = DM_VIDEOPLAYER.videos[handle];
        if (!data) return;
        data.element.pause();
    },

    dmVideoplayerHtml5SetVisible__deps: ['$DM_VIDEOPLAYER'],
    dmVideoplayerHtml5SetVisible: function(handle, visible) {
        var data = DM_VIDEOPLAYER.videos[handle];
        if (!data) return;
        data.element.style.display = visible ? 'block' : 'none';
    }
};

autoAddDeps(LibraryVideoplayer, '$DM_VIDEOPLAYER');
mergeInto(LibraryManager.library, LibraryVideoplayer);
