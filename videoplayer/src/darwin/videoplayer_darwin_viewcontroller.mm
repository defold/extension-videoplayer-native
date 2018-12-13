#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_darwin_viewcontroller.h"
#include "videoplayer_darwin_command_queue.h"
#include "videoplayer_darwin_helper.h"
#include "../videoplayer_private.h"
#include <dmsdk/sdk.h>    // Logging

@implementation VideoPlayerViewController

-(void) PrepareVideoPlayer: (NSURL*) url {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::PrepareVideoPlayer");
    
    m_Asset = [AVURLAsset URLAssetWithURL:url options:nil];
    if(Helper::GetInfoFromAsset(m_Asset, m_Width, m_Height)) {
        dmLogInfo("Video size: (%f x %f)", m_Width, m_Height);        
    }

    m_PlayerItem = [AVPlayerItem playerItemWithAsset:m_Asset];
    m_Player = [AVPlayer playerWithPlayerItem:m_PlayerItem];
    [m_Player addObserver:self forKeyPath:@"status" options:0 context:nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                          selector: @selector(PlayerItemDidReachEnd:)
                                          name: AVPlayerItemDidPlayToEndTimeNotification
                                          object: [m_Player currentItem]];
    
    m_PlayerViewController = [AVPlayerViewController new];
    m_PlayerViewController.player = m_Player;
    m_PlayerViewController.showsPlaybackControls = NO;
    m_PlayerViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    m_IsPaused = NO;

    [self presentViewController:m_PlayerViewController animated:NO completion:nil];
}

-(void) Start {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Start");
    /*if(m_IsPaused == YES) {
        //[m_Player resume];
    } else {
        [m_Player play];
    }*/
    //[self presentViewController:self.m_PlayerViewController animated:NO completion:nil];
    //[m_Player play];
}

-(void) Stop {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Stop");
    //[m_Player play];
}


-(void) Pause {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Pause");
    //[m_Player pause];
}

/*
-(void) Show {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Show");
    //[self presentViewController:playerViewController animated:NO completion:nil];
}

-(void) Hide {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::Hide");
    //[self dismissViewControllerAnimated:NO completion:nil];
}
*/

// ----------------------------------------------------------------------------
// CALLBACKS
// ----------------------------------------------------------------------------

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if (object == m_Player && [keyPath isEqualToString:@"status"]) {
        if (m_Player.status == AVPlayerStatusFailed) {
            dmLogInfo("AVPlayer Failed");
            dmVideoPlayer::Command cmd;
            memset(&cmd, 0, sizeof(cmd));
            cmd.m_Type = dmVideoPlayer::CMD_PREPARE_ERROR;
            //cmd.m_ID = info.videoId;
            //cmd.m_Callback = info->m_Callback;
            //CommandQueue::Queue(&cmd);
        } 
        else if (m_Player.status == AVPlayerStatusReadyToPlay) {
            dmLogInfo("AVPlayer Ready to Play");
            [m_Player play];

            //assert(id >= 0 && id < m_NumVideos);
            //SAndroidVideoInfo* info = &g_VideoContext.m_Videos[id];
            dmVideoPlayer::Command cmd;
            memset(&cmd, 0, sizeof(cmd));
            cmd.m_Type = dmVideoPlayer::CMD_PREPARE_OK;
            //cmd.m_ID = id;
            cmd.m_Width = m_Width;
            cmd.m_Height = m_Height;
            //cmd.m_Callback = info->m_Callback;
            //CommandQueue::Queue(&cmd);
        } 
    }
}

- (void)PlayerItemDidReachEnd:(NSNotification *)notification {
    dmLogInfo("SIMON DEBUG: VideoPlayerViewController::PlayerItemDidReachEnd");

    dmVideoPlayer::Command cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.m_Type = dmVideoPlayer::CMD_FINISHED;
    //cmd.m_ID = id;
    //cmd.m_Callback = info->m_Callback;
    //CommandQueue::Queue(&cmd);
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

@end

#endif
