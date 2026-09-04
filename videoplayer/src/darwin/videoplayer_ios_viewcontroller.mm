#if defined(DM_PLATFORM_IOS)
#include "videoplayer_darwin.h"
#include "videoplayer_darwin_helper.h"

@implementation VideoPlayerViewController

- (id)init {
    self = [super init];
    if (self != nil) {
        m_SelectedVideoId = INVALID_VIDEO_ID;
        m_NumVideos = 0;
        m_TargetWindow = nil;
        m_TargetView = nil;
        m_IsSubLayerActive = false;
        m_ResumeOnForeground = false;
    }
    return self;
}

// Target view = Defold's view (the window's rootViewController view). The video is drawn as a
// CALayer ON TOP of it, WITHOUT replacing the rootViewController. A CALayer is not part of the
// responder chain, so touches keep reaching Defold and the game decides when to skip (in Lua,
// via videoplayer.stop) - same model as Android (FLAG_NOT_TOUCHABLE). Mirrors the macOS player.
-(UIView*) TargetView {
    if (m_TargetView != nil) {
        return m_TargetView;
    }
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if (window == nil) {
        window = [[UIApplication sharedApplication] keyWindow];
    }
    if (window == nil) {
        dmLogError("Videoplayer: No active window found for iOS playback");
        return nil;
    }
    m_TargetWindow = window;
    m_TargetView = window.rootViewController.view != nil ? window.rootViewController.view : window;
    return m_TargetView;
}

-(void) AddSubLayer:(AVPlayerLayer*)layer {
    UIView* targetView = [self TargetView];
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
        dmLogError("No sublayer to remove");
    }
}

-(int) Create:(NSURL*)url callback:(dmVideoPlayer::LuaCallback*)cb playSound:(bool)playSound{
    if (m_NumVideos >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Videoplayer: Max number of videos opened: %d", dmVideoPlayer::MAX_NUM_VIDEOS);
        return INVALID_VIDEO_ID;
    }

    // Render as an overlay on top of Defold's view (do not replace the rootViewController).
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
    [self AddSubLayer:playerLayer];   // sized to the target view (overlay above Defold)

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    dmLogInfo("Videoplayer: screenBounds: (%f x %f)", screenBounds.size.width, screenBounds.size.height);

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
        name:UIApplicationDidEnterBackgroundNotification
        object: nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
        selector: @selector(AppEnteredForeground)
        name: UIApplicationWillEnterForegroundNotification
        object: nil];

    m_NumVideos++;
    return video;
}

-(void) Destroy:(int)video {
    VideoPlayerDestroy(self, video);   // removes the sublayer and decrements m_NumVideos
    // The video is an overlay, so there is no rootViewController to restore. When the last video
    // is destroyed, drop the borrowed target references (they are owned by the app, not retained).
    if (m_NumVideos == 0) {
        m_TargetView = nil;
        m_TargetWindow = nil;
    }
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

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

@end

#endif
