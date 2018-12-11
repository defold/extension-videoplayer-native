#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

@class VideoPlayerAppDelegate;
@class VideoPlayerViewController;

namespace dmVideoPlayer {
	struct LuaCallback;
}

@interface VideoPlayerController
	-(int) Create: (const char*) uri callback:(dmVideoPlayer::LuaCallback*) cb;
	-(void) Destroy: (int)video;
	-(void) Show: (int)video;
	-(void) Hide: (int)video;
	-(void) Start: (int)video;
	-(void) Stop: (int)video;
	-(void) Pause: (int)video;
	-(void) SetVisible: (int)video isVisible:(int)visible;
	-(dmVideoPlayer::LuaCallback) getCallback: (int)video;

	@property (strong, nonatomic) VideoPlayerAppDelegate* appDelegate;
	@property (strong, nonatomic) VideoPlayerViewController* viewController;
@end

#endif
