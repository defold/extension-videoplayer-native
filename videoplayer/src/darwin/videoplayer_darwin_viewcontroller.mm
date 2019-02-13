#if defined(DM_PLATFORM_IOS)
#include "videoplayer_darwin_viewcontroller.h"
#include "videoplayer_darwin_command_queue.h"
#include "videoplayer_darwin_helper.h"
#include <dmsdk/sdk.h>    // Logging
#include <algorithm>    // std::max

@implementation VideoPlayerViewController

- (id)init {
    self = [super init];
    if (self != nil) {
        m_PrevWindow = [[[UIApplication sharedApplication]delegate] window];
        m_PrevRootViewController = m_PrevWindow.rootViewController;
    }
    return self;
}

-(int) Create:(NSURL*)url callback:(dmVideoPlayer::LuaCallback*)cb {
    if (m_NumVideos >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Max number of videos opened: %d", dmVideoPlayer::MAX_NUM_VIDEOS);
        return -1;
    }

    float width = 0.0f, height = 0.0f;
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    if(Helper::GetInfoFromAsset(asset, width, height)) {
        dmLogInfo("Video size: (%f x %f)", width, height);
    }

    m_SelectedVideoId = -1;
    
    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer* player = [AVPlayer playerWithPlayerItem:playerItem];

    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:playerLayer];

    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    dmLogInfo("screenBounds: (%f x %f)", screenBounds.size.width, screenBounds.size.height);

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

    [player addObserver:self forKeyPath:@"status" options:0 context:&info];
    [[NSNotificationCenter defaultCenter] addObserver: self
    selector: @selector(PlayerItemDidReachEnd:)
    name: AVPlayerItemDidPlayToEndTimeNotification
    object: [player currentItem]];
    m_NumVideos++;
    [player play];

    // HAX TEST
    //m_SelectedVideoId = info.m_VideoId;
        
    return video;
}

-(void) Destroy:(int)video {
    if (m_NumVideos > dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Invalid video id: %d", video);
        return;
    }
    
    SDarwinVideoInfo& info = m_Videos[video];
    m_NumVideos = std::max(0, m_NumVideos - 1);
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    [info.m_PlayerLayer removeFromSuperlayer];
    [info.m_PlayerLayer release];
    info.m_PlayerLayer = nil;
    
    [info.m_Player release];
    info.m_Player = nil;
    
    dmVideoPlayer::UnregisterCallback(&info.m_Callback);
    m_PrevWindow.rootViewController = m_PrevRootViewController;
}

-(bool) IsReady:(int)video {
    dmLogInfo("IsReady video id: %d, m_SelectedVideoId: %d", video, m_SelectedVideoId);
    return m_SelectedVideoId == video;
    /*
    if(m_SelectedVideoId != video) {
        return false;
    }

    SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
    if(info.m_PlayerLayer == nil) {
        dmLogInfo("IsReady info.m_PlayerLayer is nil!");
        return false;
    }
    
    bool isReady = info.m_PlayerLayer.readyForDisplay == YES;
    dmLogInfo("IsReady isReady: %d", info.m_PlayerLayer.readyForDisplay);
    return isReady;
    */ 
}

-(void) Start:(int)video {
    dmLogInfo("Start!");
    if([self IsReady:video]) {
        SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
        [info.m_Player play];
    } else {
        dmLogError("No video to start!");
    }
}

-(void) Stop:(int)video {
    dmLogInfo("Stop!");
    if([self IsReady:video]) {
        SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
        [info.m_Player seekToTime:CMTimeMake(0, 1)];
        [info.m_Player pause];
    } else {
        dmLogError("No video to stop!");
    }
}

-(void) Pause:(int)video {
    dmLogInfo("Pause!");
    if([self IsReady:video]) {
        SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
        [info.m_Player pause];
    } else {
        dmLogError("No video to pause!");
    }
}

-(void) Show:(int)video {
    dmLogInfo("Show!");
    if([self IsReady:video]) {
        SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
        //info.m_Window.hidden = NO;
    } else {
        dmLogError("No video to show!");
    }
}

-(void) Hide:(int)video {
    dmLogInfo("Hide!");
    if([self IsReady:video]) {
        SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
        //info.m_Window.hidden = YES;
    } else {
        dmLogError("No video to hide!");
    }
}

// ----------------------------------------------------------------------------
// CALLBACKS
// ----------------------------------------------------------------------------

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    dmLogInfo("HALLAUJA!");
    
    bool invalidParams = false;
    SDarwinVideoInfo* info = (SDarwinVideoInfo*)context;
    if(info == NULL) {
        dmLogError("Video info missing!");
        invalidParams = true;
    }

    dmLogInfo("HALLAUJA 2!");
    
    if (info->m_VideoId >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Invalid video id: %d", info->m_VideoId);
        invalidParams = true;
    } 

    if(!invalidParams) {
        AVPlayer* player = info->m_Player;
        dmLogInfo("HALLAUJA 4!");
        if (object == player && [keyPath isEqualToString:@"status"]) {
            dmLogInfo("HALLAUJA 5!");
            if (player.status == AVPlayerStatusReadyToPlay) {
                dmLogInfo("HALLAUJA 6!");
                m_SelectedVideoId = info->m_VideoId;
                dmVideoPlayer::Command cmd;
                memset(&cmd, 0, sizeof(cmd));
                cmd.m_Type          = dmVideoPlayer::CMD_PREPARE_OK;
                cmd.m_ID            = info->m_VideoId;
                cmd.m_Callback      = info->m_Callback;
                cmd.m_Width         = (int)info->m_Width;
                cmd.m_Height        = (int)info->m_Height;
                CommandQueue::Queue(&cmd);
                return;
            } else {
                dmLogError("Video %d not ready to play yet!", info->m_VideoId);
            }
        }
    }

    dmLogInfo("HALLAUJA 3!");
    
    // Error!
    dmVideoPlayer::Command cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.m_Type          = dmVideoPlayer::CMD_PREPARE_ERROR;
    cmd.m_ID            = info->m_VideoId;
    cmd.m_Callback      = info->m_Callback;
    CommandQueue::Queue(&cmd);
}

- (void)PlayerItemDidReachEnd:(NSNotification *)notification {
    dmLogInfo("PlayerItemDidReachEnd!");
    
    SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
    m_SelectedVideoId = -1;
    dmVideoPlayer::Command cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.m_Type          = dmVideoPlayer::CMD_FINISHED;
    cmd.m_ID            = info.m_VideoId;
    cmd.m_Callback      = info.m_Callback;
    cmd.m_Width         = (int)info.m_Width;
    cmd.m_Height        = (int)info.m_Height;
    CommandQueue::Queue(&cmd);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

@end

#endif
