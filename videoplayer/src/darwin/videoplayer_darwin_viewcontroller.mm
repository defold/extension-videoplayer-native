#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_darwin_viewcontroller.h"
#include "videoplayer_darwin_command_queue.h"
#include "videoplayer_darwin_helper.h"
#include <dmsdk/sdk.h>    // Logging

@implementation VideoPlayerViewController

-(int) Create:(NSURL*)url callback:(dmVideoPlayer::LuaCallback*)cb {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Create");

    if (m_NumVideos >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Max number of videos opened: %d", dmVideoPlayer::MAX_NUM_VIDEOS);
        return -1;
    }

    float width = 0.0f, height = 0.0f;
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    if(Helper::GetInfoFromAsset(asset, width, height)) {
        dmLogInfo("SIMON DEBUG: Video size: (%f x %f)", width, height);
    }

    AVPlayerItem* playerItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer* player = [AVPlayer playerWithPlayerItem:playerItem];

    AVPlayerViewController* playerViewController = [AVPlayerViewController new];
    playerViewController.player = player;
    playerViewController.showsPlaybackControls = NO;
    playerViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    m_PrevWindow = [[[UIApplication sharedApplication]delegate] window];
    m_PrevViewController = [m_PrevWindow rootViewController];
    
    UIWindow* window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.rootViewController = self;
    window.hidden = YES;

    //[self presentViewController:playerViewController animated:NO completion:nil];
        
    m_SelectedVideoId = -1;
    int videoId = m_NumVideos;

    SDarwinVideoInfo& info = m_Videos[videoId];
    info.m_Asset = asset;
    info.m_PlayerItem = playerItem;
    info.m_Width = width;
    info.m_Height = height;
    info.m_Player = player;
    info.m_PlayerViewController = playerViewController;
    info.m_Window = window;
    info.m_IsPaused = NO; 
    info.m_VideoId = videoId;
    info.m_Callback = *cb;
    dmLogInfo("SIMON DEBUG: Video id: %d", videoId);

    [player addObserver:self forKeyPath:@"status" options:0 context:&info];
    [[NSNotificationCenter defaultCenter] addObserver: self
    selector: @selector(PlayerItemDidReachEnd:)
    name: AVPlayerItemDidPlayToEndTimeNotification
    object: [player currentItem]];

    m_NumVideos++;
    return videoId;
}

-(void) Destroy:(int)videoId {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Destroy");
    if (m_NumVideos > dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("SIMON DEBUG: Invalid video id: %d", videoId);
        return;
    }
    SDarwinVideoInfo& info = m_Videos[videoId];
    [info.m_Window release];
    [info.m_PlayerViewController release];
    [info.m_Player release];
    dmVideoPlayer::UnregisterCallback(&info.m_Callback);
    [m_PrevWindow makeKeyAndVisible];
}

-(void) Start {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Start");
    if(m_SelectedVideoId != -1) {
        SDarwinVideoInfo& info = m_Videos[m_SelectedVideoId];
        info.m_Window.hidden = NO;
        [self presentViewController:info.m_PlayerViewController animated:NO completion:nil];
        [info.m_Player play];
        dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Start - PLAYING!");
    } else {
        dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Start - Player not ready!");
    }
}

-(void) Stop {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Stop");
    m_SelectedVideoId = -1;
}


-(void) Pause {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Pause");
}

-(void) Show {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Show");
}

-(void) Hide {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Hide");
}


// ----------------------------------------------------------------------------
// CALLBACKS
// ----------------------------------------------------------------------------

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {

    SDarwinVideoInfo* info = (SDarwinVideoInfo*)context;
    if(info == NULL) {
        dmLogInfo("SIMON DEBUG: observeValueForKeyPath - info was NULL!");
        return;
    }
    
    if (info->m_VideoId >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("SIMON DEBUG: Invalid video id: %d", info->m_VideoId);
        return;
    } else {
        dmLogInfo("SIMON DEBUG: observeValueForKeyPath - videoId is %d", info->m_VideoId);
        dmLogInfo("SIMON DEBUG: observeValueForKeyPath - W x H is %f x %f", info->m_Width, info->m_Height);
        dmLogInfo("SIMON DEBUG: observeValueForKeyPath - info->m_Callback is %p", &info->m_Callback);
    }

    AVPlayer* player = info->m_Player;

    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusFailed) {
            dmLogInfo("SIMON DEBUG: AVPlayer Failed");
            dmVideoPlayer::Command cmd;
            memset(&cmd, 0, sizeof(cmd));
            cmd.m_Type          = dmVideoPlayer::CMD_PREPARE_ERROR;
            cmd.m_ID            = info->m_VideoId;
            cmd.m_Callback      = info->m_Callback;
            CommandQueue::Queue(&cmd);
        } 
        else if (player.status == AVPlayerStatusReadyToPlay) {
            dmLogInfo("SIMON DEBUG: AVPlayer Ready to Play");
            m_SelectedVideoId = info->m_VideoId;
            //[player play];

            //assert(id >= 0 && id < m_NumVideos);
            //SAndroidVideoInfo* info = &g_VideoContext.m_Videos[id];
            dmVideoPlayer::Command cmd;
            memset(&cmd, 0, sizeof(cmd));
            cmd.m_Type          = dmVideoPlayer::CMD_PREPARE_OK;
            cmd.m_ID            = info->m_VideoId;
            cmd.m_Callback      = info->m_Callback;
            cmd.m_Width         = (int)info->m_Width;
            cmd.m_Height        = (int)info->m_Height;
            CommandQueue::Queue(&cmd);
            dmLogInfo("SIMON DEBUG: Queued CMD_PREPARE_OK");
        } 
    }
}

- (void)PlayerItemDidReachEnd:(NSNotification *)notification {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::PlayerItemDidReachEnd");
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
