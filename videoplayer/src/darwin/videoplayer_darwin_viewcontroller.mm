#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_darwin_viewcontroller.h"

// TODO: This is debug logging - remove when implementation finished
#include <dmsdk/sdk.h>
#define DBGFNLOG dmLogWarning("%s: %s:%d:", __FILE__, __FUNCTION__, __LINE__); // debugging while developing only

@implementation VideoPlayerViewController

-(void) PrepareVideoPlayer: (NSURL*) url {
    dmLogInfo("VideoPlayerViewController::PrepareVideoPlayer()");
    
    asset = [AVURLAsset URLAssetWithURL:url options:nil];
    playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    player = [AVPlayer playerWithPlayerItem:playerItem];
    [player addObserver:self forKeyPath:@"status" options:0 context:nil];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                          selector: @selector(PlayerItemDidReachEnd:)
                                          name: AVPlayerItemDidPlayToEndTimeNotification
                                          object: [player currentItem]];
    
    playerViewController = [AVPlayerViewController new];
    playerViewController.player = player;
    playerViewController.showsPlaybackControls = false;
    playerViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [self presentViewController:playerViewController animated:NO completion:nil];
}

-(void) Play {
    dmLogInfo("VideoPlayerViewController::Play()");
    [self Show];
    [player play];
}

-(void) Show {
    dmLogInfo("VideoPlayerViewController::Show()");
    //[self presentViewController:playerViewController animated:NO completion:nil];
}

-(void) Hide {
    dmLogInfo("VideoPlayerViewController::Hide()");
    //[self dismissViewControllerAnimated:NO completion:nil];
}

- (void)PlayerItemDidReachEnd:(NSNotification *)notification {
    dmLogInfo("VideoPlayerViewController::playerItemDidReachEnd()");
    [self Hide];
}

// ----------------------------------------------------------------------------
// SYSTEM CALLBACKS
// ----------------------------------------------------------------------------

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    dmLogInfo("VideoPlayerViewController::observeValueForKeyPath()");
    
    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusFailed) {
            dmLogInfo("AVPlayer Failed");
        } else if (player.status == AVPlayerStatusReadyToPlay) {
            dmLogInfo("AVPlayer Ready to Play");
            [self Play];
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
