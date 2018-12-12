#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once
#include "../videoplayer_private.h"
#import <Foundation/Foundation.h>

@class VideoPlayerAppDelegate;
@class VideoPlayerViewController;

struct SDarwinVideoInfo {   
//	AVAsset* m_Asset;
//	AVPlayerItem* m_PlayerItem;
	dmVideoPlayer::LuaCallback m_Callback;
	//jobject m_Video;
};

@interface VideoPlayerController : NSObject {
		int 						m_NumVideos;
    	SDarwinVideoInfo 			m_Videos[dmVideoPlayer::MAX_NUM_VIDEOS];
		VideoPlayerAppDelegate* 	m_AppDelegate;
		VideoPlayerViewController* 	m_ViewController;		
	}
	-(id) init;
	-(void) Exit;

	-(int) Create: (const char*) uri callback:(dmVideoPlayer::LuaCallback*) cb;
	-(void) Destroy: (int)video;
	-(void) Show: (int)video;
	-(void) Hide: (int)video;
	-(void) Start: (int)video;
	-(void) Stop: (int)video;
	-(void) Pause: (int)video;
	-(void) SetVisible: (int)video isVisible:(int)visible;
	-(dmVideoPlayer::LuaCallback) getCallback: (int)video;
@end

#endif
