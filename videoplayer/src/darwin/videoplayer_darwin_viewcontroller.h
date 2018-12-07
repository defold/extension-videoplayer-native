#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoPlayerViewController : UIViewController {
    AVAsset* asset;
    AVPlayer* player;
    AVPlayerItem* playerItem;
    AVPlayerViewController* playerViewController;
}
-(void) prepareVideoPlayer: (NSURL*) url;
-(void) play;
@end

#endif
