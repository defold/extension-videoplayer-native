#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_darwin_viewcontroller.h"
#include <dmsdk/sdk.h>
#define DBGFNLOG dmLogWarning("%s: %s:%d:", __FILE__, __FUNCTION__, __LINE__); // debugging while developing only

@implementation VideoPlayerViewController

-(void) prepareVideoPlayer: (NSURL*) url {
    dmLogInfo("VideoPlayerViewController::prepareVideoPlayer()");
    
    asset = [AVURLAsset URLAssetWithURL:url options:nil];
    playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    player = [AVPlayer playerWithPlayerItem:playerItem];
    [player addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    playerViewController = [AVPlayerViewController new];
    playerViewController.player = player;
    playerViewController.showsPlaybackControls = false;
    playerViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [self presentViewController:playerViewController animated:NO completion:nil];
}

-(void) play {
    [player play];
}

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    dmLogInfo("VideoPlayerViewController::observeValueForKeyPath()");
    
    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusFailed) {
            dmLogInfo("AVPlayer Failed");
        } else if (player.status == AVPlayerStatusReadyToPlay) {
            dmLogInfo("AVPlayer Ready to Play");
            [self play];
        } 
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    dmLogInfo("VideoPlayerViewController::supportedInterfaceOrientations()");
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    dmLogInfo("VideoPlayerViewController::shouldAutorotateToInterfaceOrientation()");
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

@end

#endif
