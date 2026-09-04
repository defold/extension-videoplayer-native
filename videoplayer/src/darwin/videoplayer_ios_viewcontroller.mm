#if defined(DM_PLATFORM_IOS)
#include "videoplayer_darwin.h"
#include "videoplayer_darwin_helper.h"

@interface DMVideoPlayerOverlayView : UIView
@end

@implementation DMVideoPlayerOverlayView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

@end

static UIWindow* FindTargetWindow() {
    UIApplication* application = [UIApplication sharedApplication];
    id<UIApplicationDelegate> delegate = application.delegate;
    UIWindow* delegateWindow = [delegate respondsToSelector:@selector(window)] ? delegate.window : nil;
    // Defold owns this window in the normal single-scene setup. Prefer it even when another
    // transient window is currently key (for example, a system dialog).
    if (delegateWindow != nil) {
        return delegateWindow;
    }

    UIWindow* fallbackWindow = nil;
    for (UIScene* scene in application.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        if (scene.activationState != UISceneActivationStateForegroundActive &&
            scene.activationState != UISceneActivationStateForegroundInactive) {
            continue;
        }

        for (UIWindow* candidate in ((UIWindowScene*)scene).windows) {
            if (candidate.isKeyWindow) {
                return candidate;
            }
            if (fallbackWindow == nil && !candidate.hidden) {
                fallbackWindow = candidate;
            }
        }
    }
    return fallbackWindow;
}

@implementation VideoPlayerViewController

- (id)init {
    self = [super init];
    if (self != nil) {
        m_SelectedVideoId = INVALID_VIDEO_ID;
        m_NumVideos = 0;
        m_TargetWindow = nil;
        m_TargetView = nil;
        m_PlayerView = nil;
        m_IsSubLayerActive = false;
        m_ResumeOnForeground = false;
    }
    return self;
}

// Target view = Defold's view (the window's rootViewController view). The video is drawn in a
// non-interactive UIView backed by AVPlayerLayer, WITHOUT replacing the rootViewController.
// Touches keep reaching Defold and the game decides when to skip (in Lua, via videoplayer.destroy) -
// same model as Android (FLAG_NOT_TOUCHABLE).
-(UIView*) TargetView {
    if (m_TargetView != nil) {
        return m_TargetView;
    }
    UIWindow* window = FindTargetWindow();
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
        if (m_PlayerView == nil || m_PlayerView.layer != layer) {
            dmLogError("Videoplayer: Player view is missing");
            return;
        }
        m_PlayerView.frame = targetView.bounds;
        [targetView addSubview:m_PlayerView];
        m_IsSubLayerActive = true;
    } else {
        dmLogError("Videoplayer: Already have active sublayer - remove it first");
    }
}

-(void) RemoveSubLayer:(AVPlayerLayer*)layer {
    if(m_IsSubLayerActive) {
        if (m_PlayerView.layer != layer) {
            dmLogError("Videoplayer: Unexpected player layer");
            return;
        }
        [m_PlayerView removeFromSuperview];
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

    m_PlayerView = [[DMVideoPlayerOverlayView alloc] initWithFrame:m_TargetView.bounds];
    m_PlayerView.userInteractionEnabled = NO;
    m_PlayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    AVPlayerLayer* playerLayer = (AVPlayerLayer*)m_PlayerView.layer;
    playerLayer.player = player;
    [self AddSubLayer:playerLayer];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    dmLogInfo("Videoplayer: screenBounds: (%f x %f)", screenBounds.size.width, screenBounds.size.height);

    int video = m_NumVideos;
    SDarwinVideoInfo& info = m_Videos[video];
    info.m_Asset = [asset retain];
    info.m_PlayerItem = [playerItem retain];
    info.m_Width = width;
    info.m_Height = height;
    info.m_Player = [player retain];
    info.m_PlayerLayer = [playerLayer retain];
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
    if (!VideoPlayerDestroy(self, video)) {
        return;
    }
    // The video is an overlay, so there is no rootViewController to restore. When the last video
    // is destroyed, drop the borrowed target references (they are owned by the app, not retained).
    if (m_NumVideos == 0) {
        [m_PlayerView release];
        m_PlayerView = nil;
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
