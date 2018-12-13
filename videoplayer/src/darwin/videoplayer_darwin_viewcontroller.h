#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoPlayerViewController : UIViewController {
	    AVAsset* m_Asset;				// Move to types.h?
	    AVPlayerItem* m_PlayerItem;	// Move to types.h?
	    float m_Width;
	    float m_Height;

	    AVPlayer* m_Player;			
	    AVPlayerViewController* m_PlayerViewController;
	    BOOL m_IsPaused;
	}
	-(void) PrepareVideoPlayer: (NSURL*) url;
	-(void) Start;
	-(void) Stop;
	-(void) Pause;
//	-(void) Show;
//	-(void) Hide;
@end

#endif
