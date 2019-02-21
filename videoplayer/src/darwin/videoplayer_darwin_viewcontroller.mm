#if defined(DM_PLATFORM_IOS)
#include "videoplayer_darwin_viewcontroller.h"
#include "videoplayer_darwin_command_queue.h"
#include "videoplayer_darwin_helper.h"
#include <dmsdk/sdk.h>    // Logging
#include <algorithm>    // std::max

@implementation VideoPlayerViewController

static const int INALID_VIDEO_ID = -1;

static void QueueVideoCommand(dmVideoPlayer::CommandType commandType, SDarwinVideoInfo& info) {
    dmVideoPlayer::Command cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.m_Type          = commandType;
    cmd.m_ID            = info.m_VideoId;
    cmd.m_Callback      = info.m_Callback;
    cmd.m_Width         = (int)info.m_Width;
    cmd.m_Height        = (int)info.m_Height;
    CommandQueue::Queue(&cmd);
}

- (id)init {
    self = [super init];
    if (self != nil) {
        m_SelectedVideoId = INALID_VIDEO_ID;
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

-(int) Create:(NSURL*)url callback:(dmVideoPlayer::LuaCallback*)cb {
    if (m_NumVideos >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Videoplayer: Max number of videos opened: %d", dmVideoPlayer::MAX_NUM_VIDEOS);
        return INALID_VIDEO_ID;
    }

    float width = 0.0f, height = 0.0f;
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    if(Helper::GetInfoFromAsset(asset, width, height)) {
        dmLogInfo("Videoplayer: size: (%f x %f)", width, height);
    }

    m_SelectedVideoId = INALID_VIDEO_ID;
    
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer* player = [AVPlayer playerWithPlayerItem:playerItem];

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
    dmLogInfo("Videoplayer: Destroy video id: %d", video);
    
    if (m_NumVideos > dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Videoplayer: Invalid num videos: %d", m_NumVideos);
        return;
    }
    
    if (video >= m_NumVideos) {
        dmLogError("Videoplayer: Invalid video id: %d", video);
        return;
    }
    
    SDarwinVideoInfo& info = m_Videos[video];
    m_NumVideos = std::max(0, m_NumVideos - 1);
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [self RemoveSubLayer:info.m_PlayerLayer];

    [info.m_PlayerLayer setPlayer:nil];
    [info.m_PlayerLayer release];
    info.m_PlayerLayer = nil;

    [info.m_Player replaceCurrentItemWithPlayerItem: nil];
    [info.m_Player release];
    info.m_Player = nil;

    [info.m_PlayerItem release];
    info.m_PlayerItem = nil;

    [info.m_Asset release];
    info.m_Asset = nil;

    dmVideoPlayer::UnregisterCallback(&info.m_Callback);
    m_PrevWindow.rootViewController = m_PrevRootViewController;

    m_SelectedVideoId = INALID_VIDEO_ID;
}

-(bool) IsReady:(int)video {
    return (m_SelectedVideoId != INALID_VIDEO_ID) && (m_SelectedVideoId == video);
}

-(void) Start:(int)video {
    dmLogInfo("Videoplayer: Start");
    if([self IsReady:video]) {
        SDarwinVideoInfo& info = m_Videos[video];
        [info.m_Player play];
    } else {
        dmLogError("Videoplayer: No video to start!");
    }
}

-(void) Stop:(int)video {
    dmLogInfo("Videoplayer: Stop");
    if([self IsReady:video]) {
        SDarwinVideoInfo& info = m_Videos[video];
        [info.m_Player seekToTime:CMTimeMake(0, 1)];
        [info.m_Player pause];
    } else {
        dmLogError("Videoplayer: No video to stop!");
    }
}

-(void) Pause:(int)video {
    dmLogInfo("Videoplayer: Pause");
    if([self IsReady:video]) {
        SDarwinVideoInfo& info = m_Videos[video];
        [info.m_Player pause];
    } else {
        dmLogError("Videoplayer: No video to pause!");
    }
}

-(void) Show:(int)video {
    dmLogInfo("Videoplayer: Show");
    if([self IsReady:video]) {
        SDarwinVideoInfo& info = m_Videos[video];
        [self AddSubLayer:info.m_PlayerLayer];
    } else {
        dmLogError("Videoplayer: No video to show!");
    }
}

-(void) Hide:(int)video {
    dmLogInfo("Videoplayer: Hide");
    if([self IsReady:video]) {
        SDarwinVideoInfo& info = m_Videos[video];
        [self RemoveSubLayer:info.m_PlayerLayer];
    } else {
        dmLogError("Videoplayer: No video to hide!");
    }
}

// ----------------------------------------------------------------------------
// CALLBACKS
// ----------------------------------------------------------------------------

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    bool invalidParams = false;
    SDarwinVideoInfo* info = (SDarwinVideoInfo*)context;
    if(info == NULL) {
        dmLogError("Videoplayer: Video info missing!");
        QueueVideoCommand(dmVideoPlayer::CMD_PREPARE_ERROR, *info);
        return;
    }
    
    if (info->m_VideoId < 0 || info->m_VideoId >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Invalid video id: %d", info->m_VideoId);
        QueueVideoCommand(dmVideoPlayer::CMD_PREPARE_ERROR, *info);
        return;
    } 

    AVPlayer* player = info->m_Player;
    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusReadyToPlay) {
            m_SelectedVideoId = info->m_VideoId;
            QueueVideoCommand(dmVideoPlayer::CMD_PREPARE_OK, *info);
            return;
        } else {
            dmLogError("Videoplayer: Video %d not ready to play yet!", info->m_VideoId);
        }
    }
}

- (void)PlayerItemDidReachEnd:(NSNotification *)notification { 
    dmLogInfo("Videoplayer: PlayerItemDidReachEnd! video id: %d", m_SelectedVideoId);
    
    SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
    m_SelectedVideoId = INALID_VIDEO_ID;
    m_ResumeOnForeground = false;
    QueueVideoCommand(dmVideoPlayer::CMD_FINISHED, info);
}

-(void) AppEnteredBackground {
    dmLogInfo("Videoplayer: AppEnteredBackground! video id: %d", m_SelectedVideoId);
    if(m_SelectedVideoId != INALID_VIDEO_ID) {
        dmLogInfo("Videoplayer: AppEnteredBackground: Pause video");

        SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
        
        [info.m_Player pause];
        m_PauseTime = [info.m_Player currentTime];
        m_ResumeOnForeground = true;
    }
}

- (void) AppEnteredForeground {
    dmLogInfo("Videoplayer: AppEnteredForeground! video id: %d", m_SelectedVideoId);
    if((m_SelectedVideoId != INALID_VIDEO_ID) && m_ResumeOnForeground) {
        dmLogInfo("Videoplayer: AppEnteredForeground: Resume video");

        SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];

        [info.m_PlayerLayer setPlayer:nil];
        [info.m_Player replaceCurrentItemWithPlayerItem: nil];
        [info.m_Player replaceCurrentItemWithPlayerItem: info.m_PlayerItem];
        [info.m_PlayerLayer setPlayer:info.m_Player];
        
        [self ResumeFromPauseTime];
        m_ResumeOnForeground = false;
    }
}

-(void) ResumeFromPauseTime {
    dmLogInfo("Videoplayer: ResumeFromPauseTime! video id: %d", m_SelectedVideoId);

    if(m_SelectedVideoId != INALID_VIDEO_ID) {
        SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
        AVPlayer* player = info.m_Player;
        
        if(player.status == AVPlayerStatusReadyToPlay && player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            [player seekToTime:m_PauseTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
                [player play];
            }];
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self ResumeFromPauseTime];
            });
        }
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

@end

#endif
