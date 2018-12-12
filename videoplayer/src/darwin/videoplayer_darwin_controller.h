#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

@class VideoPlayerAppDelegate;
@class VideoPlayerViewController;

namespace dmVideoPlayer {
	struct LuaCallback;
}

struct SDarwinVideoInfo {   
    // AVAsset* m_Asset;
    // AVPlayerItem* m_PlayerItem;
    dmVideoPlayer::LuaCallback m_Callback;
};

@interface VideoPlayerController {
		int 						m_NumVideos;
    	SDarwinVideoInfo 			m_Videos[dmVideoPlayer::MAX_NUM_VIDEOS];
		VideoPlayerAppDelegate* 	m_AppDelegate;
		VideoPlayerViewController* 	m_ViewController;		
	}
	-(VideoPlayerController) init;
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
