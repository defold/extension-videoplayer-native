// -----------------------------------------------------------------------
// TODO: Remove this class and move logic to videoplayer_darwin.mm
// -----------------------------------------------------------------------

#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once
#include "../videoplayer_private.h"
#import <Foundation/Foundation.h>

@class VideoPlayerAppDelegate;
@class VideoPlayerViewController;

@interface VideoPlayerController : NSObject {
		VideoPlayerAppDelegate* 	m_AppDelegate;
	}
	-(id) init;
	-(void) Exit;

	-(int) Create: (const char*) uri callback:(dmVideoPlayer::LuaCallback*)cb;
	-(void) Destroy: (int)video;
	-(void) Show: (int)video;
	-(void) Hide: (int)video;
	-(void) Start: (int)video;
	-(void) Stop: (int)video;
	-(void) Pause: (int)video;
	-(void) SetVisible: (int)video isVisible:(int)visible;
@end

#endif
