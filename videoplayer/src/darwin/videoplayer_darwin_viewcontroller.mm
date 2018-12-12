#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_darwin_viewcontroller.h"
#include <dmsdk/sdk.h>
#define DBGFNLOG dmLogWarning("%s: %s:%d:", __FILE__, __FUNCTION__, __LINE__); // debugging while developing only

@implementation VideoPlayerViewController

-(void) PrepareVideoPlayer: (NSURL*) url {
    DBGFNLOG;
    
    m_Asset = [AVURLAsset URLAssetWithURL:url options:nil];
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
    m_IsPaused = YES;

    [self presentViewController:m_PlayerViewController animated:NO completion:nil];
}

-(void) Start {
    DBGFNLOG;
    if(m_IsPaused == YES) {
        //[m_Player resume];
    } else {
        [m_Player play];
    }
}

-(void) Stop {
    DBGFNLOG;
    [m_Player play];
}


-(void) Pause {
    DBGFNLOG;
    [m_Player pause];
}

/*
-(void) Show {
    DBGFNLOG;
    //[self presentViewController:playerViewController animated:NO completion:nil];
}

-(void) Hide {
    DBGFNLOG;
    //[self dismissViewControllerAnimated:NO completion:nil];
}
*/

- (void)PlayerItemDidReachEnd:(NSNotification *)notification {
    DBGFNLOG;
}

// ----------------------------------------------------------------------------
// SYSTEM CALLBACKS
// ----------------------------------------------------------------------------

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    DBGFNLOG;
    
    if (object == m_Player && [keyPath isEqualToString:@"status"]) {
        if (m_Player.status == AVPlayerStatusFailed) {
            dmLogInfo("AVPlayer Failed");
        } else if (m_Player.status == AVPlayerStatusReadyToPlay) {
            dmLogInfo("AVPlayer Ready to Play");
            [self Start];
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
