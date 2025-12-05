#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#include "videoplayer_darwin.h"
#include <algorithm>

const int INVALID_VIDEO_ID = -1;

void QueueVideoCommand(dmVideoPlayer::CommandType commandType, SDarwinVideoInfo& info) {
    dmVideoPlayer::Command cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.m_Type          = commandType;
    cmd.m_ID            = info.m_VideoId;
    cmd.m_Callback      = info.m_Callback;
    cmd.m_Width         = (int)info.m_Width;
    cmd.m_Height        = (int)info.m_Height;
    CommandQueue::Queue(&cmd);
}

bool VideoPlayerIsReady(VideoPlayerViewController* controller, int video) {
    return (controller->m_SelectedVideoId != INVALID_VIDEO_ID) && (controller->m_SelectedVideoId == video);
}

void VideoPlayerStart(VideoPlayerViewController* controller, int video) {
    dmLogInfo("Videoplayer: Start");
    if(VideoPlayerIsReady(controller, video)) {
        SDarwinVideoInfo& info = controller->m_Videos[video];
        [info.m_Player play];
    } else {
        dmLogError("Videoplayer: No video to start!");
    }
}

void VideoPlayerStop(VideoPlayerViewController* controller, int video) {
    dmLogInfo("Videoplayer: Stop");
    if(VideoPlayerIsReady(controller, video)) {
        SDarwinVideoInfo& info = controller->m_Videos[video];
        [info.m_Player seekToTime:CMTimeMake(0, 1)];
        [info.m_Player pause];
    } else {
        dmLogError("Videoplayer: No video to stop!");
    }
}

void VideoPlayerPause(VideoPlayerViewController* controller, int video) {
    dmLogInfo("Videoplayer: Pause");
    if(VideoPlayerIsReady(controller, video)) {
        SDarwinVideoInfo& info = controller->m_Videos[video];
        [info.m_Player pause];
    } else {
        dmLogError("Videoplayer: No video to pause!");
    }
}

void VideoPlayerShow(VideoPlayerViewController* controller, int video) {
    dmLogInfo("Videoplayer: Show");
    if(VideoPlayerIsReady(controller, video)) {
        SDarwinVideoInfo& info = controller->m_Videos[video];
        [controller AddSubLayer:info.m_PlayerLayer];
    } else {
        dmLogError("Videoplayer: No video to show!");
    }
}

void VideoPlayerHide(VideoPlayerViewController* controller, int video) {
    dmLogInfo("Videoplayer: Hide");
    if(VideoPlayerIsReady(controller, video)) {
        SDarwinVideoInfo& info = controller->m_Videos[video];
        [controller RemoveSubLayer:info.m_PlayerLayer];
    } else {
        dmLogError("Videoplayer: No video to hide!");
    }
}

bool VideoPlayerDestroy(VideoPlayerViewController* controller, int video) {
    dmLogInfo("Videoplayer: Destroy video id: %d", video);
    
    if (controller->m_NumVideos > dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Videoplayer: Invalid num videos: %d", controller->m_NumVideos);
        return false;
    }
    
    if (video >= controller->m_NumVideos) {
        dmLogError("Videoplayer: Invalid video id: %d", video);
        return false;
    }
    
    SDarwinVideoInfo& info = controller->m_Videos[video];
    controller->m_NumVideos = std::max(0, controller->m_NumVideos - 1);
    [[NSNotificationCenter defaultCenter] removeObserver: controller];
    [info.m_Player removeObserver:controller forKeyPath:@"status"];
    [info.m_PlayerItem removeObserver:controller forKeyPath:@"status"];
    
    [controller RemoveSubLayer:info.m_PlayerLayer];

    [info.m_PlayerLayer setPlayer:nil];
    info.m_PlayerLayer = nil;

    [info.m_Player replaceCurrentItemWithPlayerItem: nil];
    info.m_Player = nil;
    info.m_PlayerItem = nil;
    info.m_Asset = nil;

    dmVideoPlayer::UnregisterCallback(&info.m_Callback);
    controller->m_SelectedVideoId = INVALID_VIDEO_ID;

    return true;
}

void VideoPlayerObserveValueForKeyPath(VideoPlayerViewController* controller, NSString* keyPath, id object, NSDictionary* change, void* context) {
    SDarwinVideoInfo* info = (SDarwinVideoInfo*)context;
    if(info == NULL) {
        dmLogError("Videoplayer: Video info missing!");
        return;
    }
    
    if (info->m_VideoId < 0 || info->m_VideoId >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Invalid video id: %d", info->m_VideoId);
        QueueVideoCommand(dmVideoPlayer::CMD_PREPARE_ERROR, *info);
        return;
    } 

    AVPlayer* player = info->m_Player;
    AVPlayerItem* item = info->m_PlayerItem;

    if ((object == player || object == item) && [keyPath isEqualToString:@"status"]) {
        if (item && object == item) {
            AVPlayerItemStatus itemStatus = item.status;
            if (itemStatus == AVPlayerItemStatusReadyToPlay) {
                controller->m_SelectedVideoId = info->m_VideoId;
                QueueVideoCommand(dmVideoPlayer::CMD_PREPARE_OK, *info);
                return;
            } else if (itemStatus == AVPlayerItemStatusFailed) {
                dmLogError("Videoplayer: Video %d failed to prepare", info->m_VideoId);
                QueueVideoCommand(dmVideoPlayer::CMD_PREPARE_ERROR, *info);
                return;
            } else {
                dmLogInfo("Videoplayer: Video %d still preparing", info->m_VideoId);
            }
        } else if (object == player) {
            AVPlayerStatus playerStatus = player.status;
            if (playerStatus == AVPlayerStatusReadyToPlay) {
                controller->m_SelectedVideoId = info->m_VideoId;
                QueueVideoCommand(dmVideoPlayer::CMD_PREPARE_OK, *info);
                return;
            } else if (playerStatus == AVPlayerStatusFailed) {
                dmLogError("Videoplayer: Video %d failed to prepare", info->m_VideoId);
                QueueVideoCommand(dmVideoPlayer::CMD_PREPARE_ERROR, *info);
                return;
            } else {
                dmLogInfo("Videoplayer: Video %d still preparing", info->m_VideoId);
            }
        }
    }
}

void VideoPlayerDidReachEnd(VideoPlayerViewController* controller) {
    dmLogInfo("Videoplayer: PlayerItemDidReachEnd! video id: %d", controller->m_SelectedVideoId);
    
    SDarwinVideoInfo& info = controller->m_Videos[controller->m_SelectedVideoId];
    controller->m_SelectedVideoId = INVALID_VIDEO_ID;
    controller->m_ResumeOnForeground = false;
    QueueVideoCommand(dmVideoPlayer::CMD_FINISHED, info);
}

void VideoPlayerAppEnteredBackground(VideoPlayerViewController* controller) {
    dmLogInfo("Videoplayer: AppEnteredBackground! video id: %d", controller->m_SelectedVideoId);
    if(controller->m_SelectedVideoId != INVALID_VIDEO_ID) {
        dmLogInfo("Videoplayer: AppEnteredBackground: Pause video");

        SDarwinVideoInfo& info = controller->m_Videos[controller->m_SelectedVideoId];
        
        [info.m_Player pause];
        controller->m_PauseTime = [info.m_Player currentTime];
        controller->m_ResumeOnForeground = true;
    }
}

void VideoPlayerResumeFromPauseTime(VideoPlayerViewController* controller) {
    dmLogInfo("Videoplayer: ResumeFromPauseTime! video id: %d", controller->m_SelectedVideoId);

    if(controller->m_SelectedVideoId != INVALID_VIDEO_ID) {
        SDarwinVideoInfo& info = controller->m_Videos[controller->m_SelectedVideoId];
        AVPlayer* player = info.m_Player;
        
        if(player.status == AVPlayerStatusReadyToPlay) {
            dmLogInfo("Videoplayer: seek and play. video id: %d", controller->m_SelectedVideoId);
            [player seekToTime:controller->m_PauseTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
            [player play];
        } else {
            dmLogInfo("Videoplayer: player not ready, waiting. video id: %d", controller->m_SelectedVideoId);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                VideoPlayerResumeFromPauseTime(controller);
            });
        }
    }
}

void VideoPlayerAppEnteredForeground(VideoPlayerViewController* controller) {
    dmLogInfo("Videoplayer: AppEnteredForeground! video id: %d", controller->m_SelectedVideoId);
    if((controller->m_SelectedVideoId != INVALID_VIDEO_ID) && controller->m_ResumeOnForeground) {
        dmLogInfo("Videoplayer: AppEnteredForeground: Resume video");

        SDarwinVideoInfo& info = controller->m_Videos[controller->m_SelectedVideoId];

        [info.m_PlayerLayer setPlayer:nil];
        [info.m_Player replaceCurrentItemWithPlayerItem: nil];
        [info.m_Player replaceCurrentItemWithPlayerItem: info.m_PlayerItem];
        [info.m_PlayerLayer setPlayer:info.m_Player];
        
        VideoPlayerResumeFromPauseTime(controller);
        controller->m_ResumeOnForeground = false;
    }
}

#endif
