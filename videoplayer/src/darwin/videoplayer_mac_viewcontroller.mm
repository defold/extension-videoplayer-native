#if defined(DM_PLATFORM_OSX)
#include "videoplayer_darwin.h"
#include "videoplayer_darwin_helper.h"
#include <QuartzCore/QuartzCore.h>

@implementation VideoPlayerViewController

- (id)init {
    self = [super init];
    if (self != nil) {
        m_SelectedVideoId = INVALID_VIDEO_ID;
        m_NumVideos = 0;
        m_IsSubLayerActive = false;
        m_ResumeOnForeground = false;
        m_TargetWindow = nil;
        m_TargetView = nil;
    }
    return self;
}

-(NSView*) TargetView {
    if (m_TargetView != nil) {
        return m_TargetView;
    }

    NSWindow* window = [NSApp mainWindow];
    if (window == nil) {
        window = [NSApp keyWindow];
    }
    if (window == nil) {
        NSArray<NSWindow*>* windows = [NSApp windows];
        if ([windows count] > 0) {
            window = [windows objectAtIndex:0];
        }
    }

    if (window == nil) {
        dmLogError("Videoplayer: No active window found for macOS playback");
        return nil;
    }

    m_TargetWindow = window;
    m_TargetView = [window contentView];
    [m_TargetView setWantsLayer:YES];
    return m_TargetView;
}

-(void) AddSubLayer:(AVPlayerLayer*)layer {
    NSView* targetView = [self TargetView];
    if (targetView == nil) {
        dmLogError("Videoplayer: Unable to attach layer, target view missing");
        return;
    }

    if(!m_IsSubLayerActive) {
        layer.frame = targetView.bounds;
        layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
        [targetView.layer addSublayer:layer];
        m_IsSubLayerActive = true;
    } else {
        dmLogError("Videoplayer: Already have active sublayer - remove it first");
    } 
}

-(void) RemoveSubLayer:(AVPlayerLayer*)layer {
    if(m_IsSubLayerActive) {
        [layer removeFromSuperlayer];
        m_IsSubLayerActive = false;
    } else {
        dmLogError("Videoplayer: No sublayer to remove");
    }
}

-(int) Create:(NSURL*)url callback:(dmVideoPlayer::LuaCallback*)cb playSound:(bool)playSound{
    if (m_NumVideos >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Videoplayer: Max number of videos opened: %d", dmVideoPlayer::MAX_NUM_VIDEOS);
        return INVALID_VIDEO_ID;
    }

    if ([self TargetView] == nil) {
        return INVALID_VIDEO_ID;
    }

    float width = 0.0f, height = 0.0f;
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    if(Helper::GetInfoFromAsset(asset, width, height)) {
        dmLogInfo("Videoplayer: size: (%f x %f)", width, height);
    }

    m_SelectedVideoId = INVALID_VIDEO_ID;
    
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer* player = [AVPlayer playerWithPlayerItem:playerItem];
    player.muted = !playSound;

    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    [self AddSubLayer:playerLayer];

    NSRect contentBounds = [m_TargetView bounds];
    dmLogInfo("Videoplayer: windowBounds: (%f x %f)", contentBounds.size.width, contentBounds.size.height);

    int video = m_NumVideos;
    SDarwinVideoInfo& info = m_Videos[video];
    info.m_Asset = asset;
    info.m_PlayerItem = playerItem;
    info.m_Width = width;
    info.m_Height = height;
    info.m_Player = player;
    info.m_PlayerLayer = playerLayer;
    info.m_VideoId = video;
    info.m_Callback = *cb;

    [player addObserver:self forKeyPath:@"status"
        options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
        context:&info];
    [playerItem addObserver:self forKeyPath:@"status"
        options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
        context:&info];

    [[NSNotificationCenter defaultCenter] addObserver: self
        selector: @selector(PlayerItemDidReachEnd:)
        name: AVPlayerItemDidPlayToEndTimeNotification
        object: [player currentItem]];

    [[NSNotificationCenter defaultCenter] addObserver: self
        selector: @selector(AppEnteredBackground)
        name:NSApplicationWillResignActiveNotification
        object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
        selector: @selector(AppEnteredForeground)
        name: NSApplicationDidBecomeActiveNotification
        object: nil];

    m_NumVideos++;
    return video;
}

-(void) Destroy:(int)video {
    VideoPlayerDestroy(self, video);
}

-(bool) IsReady:(int)video {
    return VideoPlayerIsReady(self, video);
}

-(void) Start:(int)video {
    VideoPlayerStart(self, video);
}

-(void) Stop:(int)video {
    VideoPlayerStop(self, video);
}

-(void) Pause:(int)video {
    VideoPlayerPause(self, video);
}

-(void) Show:(int)video {
    VideoPlayerShow(self, video);
}

-(void) Hide:(int)video {
    VideoPlayerHide(self, video);
}

// ----------------------------------------------------------------------------
// CALLBACKS
// ----------------------------------------------------------------------------

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    VideoPlayerObserveValueForKeyPath(self, keyPath, object, change, context);
}

- (void)PlayerItemDidReachEnd:(NSNotification *)notification { 
    VideoPlayerDidReachEnd(self);
}

-(void) AppEnteredBackground {
    VideoPlayerAppEnteredBackground(self);
}

- (void) AppEnteredForeground {
    VideoPlayerAppEnteredForeground(self);
}

-(void) ResumeFromPauseTime {
    VideoPlayerResumeFromPauseTime(self);
}

@end

#endif
