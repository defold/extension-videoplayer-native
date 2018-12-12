#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_darwin_controller.h"
#include "videoplayer_darwin_viewcontroller.h"
#include "videoplayer_darwin_appdelegate.h"
#include "videoplayer_darwin_helper.h"
#include "../videoplayer_private.h"

@implementation VideoPlayerController

-(id) init {
    if (self = [super init]) {
        m_AppDelegate = [[VideoPlayerAppDelegate alloc] init];
        m_ViewController = m_AppDelegate.viewController;
        dmExtension::RegisteriOSUIApplicationDelegate(m_AppDelegate);
        m_NumVideos = 0;
    }
    return self;
}

-(void) Exit {
    dmExtension::UnregisteriOSUIApplicationDelegate(m_AppDelegate);
    [m_AppDelegate release];
    m_AppDelegate = 0;
}

-(int) Create: (const char*) uri callback:(dmVideoPlayer::LuaCallback*) cb {
    DBGFNLOG;

    if (m_NumVideos >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Max number of videos opened: %d", dmVideoPlayer::MAX_NUM_VIDEOS);
        return -1;
    }
    int id = m_NumVideos;

    //[m_AppDelegate.window makeKeyAndVisible];
    //m_AppDelegate.window.hidden = false;
    
    NSURL* url = GetUrlFromURI(uri);    
    [m_ViewController PrepareVideoPlayer:url];

    //if (jvideo) {
        ++m_NumVideos;
        SDarwinVideoInfo& info = m_Videos[id];
        //info.m_Video = jvideo;
        info.m_Callback = *cb;
        return id;
    //}
    return -1;
}

-(void) Destroy: (int)video {
    DBGFNLOG;
    SDarwinVideoInfo& info = m_Videos[video];
    dmVideoPlayer::UnregisterCallback(&info.m_Callback);
    //info.m_Video = 0;
    --m_NumVideos;
}

-(void) Show: (int)video {
    DBGFNLOG;
    [m_AppDelegate Show];
}

-(void) Hide: (int)video {
    DBGFNLOG;
    [m_AppDelegate Hide];
}

-(void) Start: (int)video {
    DBGFNLOG;
    [m_ViewController Start];
}

-(void) Stop: (int)video {
    DBGFNLOG;
    [m_ViewController Stop];
}

-(void) Pause: (int)video {
    DBGFNLOG;
    [m_ViewController Pause];
}

-(void) SetVisible: (int)video isVisible:(int)visible {
    DBGFNLOG;
    if(visible == 0) {
        [self Hide:video];
    } else {
        [self Show:video];
    }
}

-(dmVideoPlayer::LuaCallback) getCallback: (int)video {
    DBGFNLOG;
}

@end

#endif
