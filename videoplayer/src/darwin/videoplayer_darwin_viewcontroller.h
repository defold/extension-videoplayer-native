#if defined(DM_PLATFORM_IOS)
#pragma once
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#include "../videoplayer_private.h"

struct SDarwinVideoInfo {   
    int                         m_VideoId;
    dmVideoPlayer::LuaCallback  m_Callback;

    AVURLAsset*                 m_Asset;
    AVPlayerItem*               m_PlayerItem;
    AVPlayer*                   m_Player;
    AVPlayerViewController*     m_PlayerViewController;
    UIWindow*                   m_Window;
    
    float                       m_Width;
    float                       m_Height;
};

@interface VideoPlayerViewController : UIViewController {
        int                         m_SelectedVideoId;
        int                         m_NumVideos;
        SDarwinVideoInfo            m_Videos[dmVideoPlayer::MAX_NUM_VIDEOS];
        UIWindow*                   m_PrevWindow;
    }
    -(int) Create:(NSURL*)url callback:(dmVideoPlayer::LuaCallback*)cb;
    -(void) Destroy:(int)video;
    -(bool) IsReady:(int)video;
    -(void) Start:(int)video;
    -(void) Stop:(int)video;
    -(void) Pause:(int)video;
    -(void) Show:(int)video;
    -(void) Hide:(int)video;
@end

#endif
