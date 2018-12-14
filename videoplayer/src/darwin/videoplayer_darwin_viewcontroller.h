#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#include "../videoplayer_private.h"

struct SDarwinVideoInfo {   
	int 						m_VideoId;
	dmVideoPlayer::LuaCallback*	m_Callback;

	AVURLAsset* 				m_Asset;
	AVPlayerItem* 				m_PlayerItem;
	AVPlayer* 					m_Player;
	AVPlayerViewController* 	m_PlayerViewController;

	float 						m_Width;
	float 						m_Height;
	BOOL 						m_IsPaused;
};

@interface VideoPlayerViewController : UIViewController {
		int 						m_NumVideos;
		SDarwinVideoInfo 			m_Videos[dmVideoPlayer::MAX_NUM_VIDEOS];
	}
	-(int) Create:(NSURL*)url callback:(dmVideoPlayer::LuaCallback*)cb;
	-(void) Destroy:(int)videoId;
	
	-(void) Start;
	-(void) Stop;
	-(void) Pause;
//	-(void) Show;
//	-(void) Hide;
@end

#endif
