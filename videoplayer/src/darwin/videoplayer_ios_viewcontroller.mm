#if defined(DM_PLATFORM_IOS)
#include "videoplayer_darwin.h"
#include "videoplayer_darwin_helper.h"

@implementation VideoPlayerViewController

- (id)init {
    self = [super init];
    if (self != nil) {
        m_SelectedVideoId = INVALID_VIDEO_ID;
        m_NumVideos = 0;
        m_PrevWindow = [[[UIApplication sharedApplication]delegate] window];
        m_PrevRootViewController = m_PrevWindow.rootViewController;
        m_IsSubLayerActive = false;
        m_ResumeOnForeground = false;
    }
    return self;
}

-(void) AddSubLayer:(AVPlayerLayer*)layer {
    if(!m_IsSubLayerActive) {
        [self.view.layer addSublayer:layer];
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
    playerLayer.frame = self.view.bounds;
    [self AddSubLayer:playerLayer];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    dmLogInfo("Videoplayer: screenBounds: (%f x %f)", screenBounds.size.width, screenBounds.size.height);

    m_PrevWindow.rootViewController = self;

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
    if(!VideoPlayerDestroy(self, video)) {
        return;
    }
    m_PrevWindow.rootViewController = m_PrevRootViewController;
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
