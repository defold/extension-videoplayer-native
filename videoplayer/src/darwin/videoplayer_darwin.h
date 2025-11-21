#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

#include "videoplayer_darwin_viewcontroller.h"
#include "videoplayer_darwin_command_queue.h"
#include <dmsdk/sdk.h>

extern const int INVALID_VIDEO_ID;

void QueueVideoCommand(dmVideoPlayer::CommandType commandType, SDarwinVideoInfo& info);

bool VideoPlayerIsReady(VideoPlayerViewController* controller, int video);
void VideoPlayerStart(VideoPlayerViewController* controller, int video);
void VideoPlayerStop(VideoPlayerViewController* controller, int video);
void VideoPlayerPause(VideoPlayerViewController* controller, int video);
void VideoPlayerShow(VideoPlayerViewController* controller, int video);
void VideoPlayerHide(VideoPlayerViewController* controller, int video);
bool VideoPlayerDestroy(VideoPlayerViewController* controller, int video);

void VideoPlayerObserveValueForKeyPath(VideoPlayerViewController* controller, NSString* keyPath, id object, NSDictionary* change, void* context);
void VideoPlayerDidReachEnd(VideoPlayerViewController* controller);
void VideoPlayerAppEnteredBackground(VideoPlayerViewController* controller);
void VideoPlayerAppEnteredForeground(VideoPlayerViewController* controller);
void VideoPlayerResumeFromPauseTime(VideoPlayerViewController* controller);

#endif
