#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
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
    AVPlayerLayer*              m_PlayerLayer;

    float                       m_Width;
    float                       m_Height;
};

#if defined(DM_PLATFORM_IOS)
#import <UIKit/UIKit.h>
@interface VideoPlayerViewController : UIViewController {
    @public
        int                         m_SelectedVideoId;
        int                         m_NumVideos;
        SDarwinVideoInfo            m_Videos[dmVideoPlayer::MAX_NUM_VIDEOS];
        UIWindow*                   m_PrevWindow;
        UIViewController*           m_PrevRootViewController;
        CMTime                      m_PauseTime;
        bool                        m_IsSubLayerActive;
        bool                        m_ResumeOnForeground;
    }
    -(int) Create:(NSURL*)url callback:(dmVideoPlayer::LuaCallback*)cb playSound:(bool)playSound;
    -(void) Destroy:(int)video;
    -(bool) IsReady:(int)video;
    -(void) Start:(int)video;
    -(void) Stop:(int)video;
    -(void) Pause:(int)video;
    -(void) Show:(int)video;
    -(void) Hide:(int)video;
    -(void) AddSubLayer:(AVPlayerLayer*)layer;
    -(void) RemoveSubLayer:(AVPlayerLayer*)layer;
@end
#elif defined(DM_PLATFORM_OSX)
#import <Cocoa/Cocoa.h>
@interface VideoPlayerViewController : NSViewController {
    @public
        int                         m_SelectedVideoId;
        int                         m_NumVideos;
        SDarwinVideoInfo            m_Videos[dmVideoPlayer::MAX_NUM_VIDEOS];
        NSWindow*                   m_TargetWindow;
        NSView*                     m_TargetView;
        CMTime                      m_PauseTime;
        bool                        m_IsSubLayerActive;
        bool                        m_ResumeOnForeground;
    }
    -(int) Create:(NSURL*)url callback:(dmVideoPlayer::LuaCallback*)cb playSound:(bool)playSound;
    -(void) Destroy:(int)video;
    -(bool) IsReady:(int)video;
    -(void) Start:(int)video;
    -(void) Stop:(int)video;
    -(void) Pause:(int)video;
    -(void) Show:(int)video;
    -(void) Hide:(int)video;
    -(void) AddSubLayer:(AVPlayerLayer*)layer;
    -(void) RemoveSubLayer:(AVPlayerLayer*)layer;
    -(NSView*) TargetView;
@end
#endif

#endif
