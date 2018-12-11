#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "../videoplayer_private.h"

@class VideoPlayerAppDelegate;

struct SDarwinVideoInfo {
    dmVideoPlayer::LuaCallback  m_Callback;
    //AVAsset* asset;
    // AVPlayerItem* playerItem;
};

struct SVideoPlayerContext {
    int m_NumVideos;
    SDarwinVideoInfo m_Videos[dmVideoPlayer::MAX_NUM_VIDEOS];
};

#endif
