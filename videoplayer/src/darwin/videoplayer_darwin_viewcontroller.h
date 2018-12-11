#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoPlayerViewController : UIViewController {
    AVAsset* asset;				// Move to types.h?
    AVPlayerItem* playerItem;	// Move to types.h?

    AVPlayer* player;			
    AVPlayerViewController* playerViewController;
}
-(void) PrepareVideoPlayer: (NSURL*) url;
-(void) Play;
-(void) Show;
-(void) Hide;
@end

#endif
