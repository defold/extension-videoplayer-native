#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_darwin_controller.h"
#include "videoplayer_darwin_viewcontroller.h"
#include "videoplayer_darwin_appdelegate.h"
#include "videoplayer_darwin_helper.h"
#include "../videoplayer_private.h"

@implementation VideoPlayerController

-(id) init {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::init");
    if (self = [super init]) {
        dmLogInfo("SIMON DEBUG: VideoPlayerController -> Entered main init");
        m_AppDelegate = [[VideoPlayerAppDelegate alloc] init];
        dmExtension::RegisteriOSUIApplicationDelegate(m_AppDelegate);
        m_NumVideos = 0;
    }
    return self;
}

-(void) Exit {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Exit");
    dmExtension::UnregisteriOSUIApplicationDelegate(m_AppDelegate);
    [m_AppDelegate release];
    m_AppDelegate = 0;
}

-(int) Create: (const char*) uri callback:(dmVideoPlayer::LuaCallback*) cb {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Create");

    if (m_NumVideos >= dmVideoPlayer::MAX_NUM_VIDEOS) {
        dmLogError("Max number of videos opened: %d", dmVideoPlayer::MAX_NUM_VIDEOS);
        return -1;
    }
 
    [m_AppDelegate Create];

    //[m_AppDelegate.m_Window makeKeyAndVisible];
    //m_AppDelegate.window.hidden = false;
    
    NSURL* url = GetUrlFromURI(uri);    
    [m_AppDelegate.m_ViewController PrepareVideoPlayer:url];

    //if (jvideo) {
        int id = m_NumVideos;
        SDarwinVideoInfo& info = m_Videos[id];
        //info.m_Video = jvideo;
        info.m_Callback = *cb;
        m_NumVideos++;
        return id;
    //}
    return -1;
}

-(void) Destroy: (int)video {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Destroy");
    
    SDarwinVideoInfo& info = m_Videos[video];
    dmVideoPlayer::UnregisterCallback(&info.m_Callback);
    //info.m_Video = 0;
    m_NumVideos--;
}

-(void) Show: (int)video {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Show");
    [m_AppDelegate Show];
}

-(void) Hide: (int)video {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Hide");
    [m_AppDelegate Hide];
}

-(void) Start: (int)video {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Start");
    [m_AppDelegate.m_ViewController Start];
}

-(void) Stop: (int)video {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Stop");
    [m_AppDelegate.m_ViewController Stop];
}

-(void) Pause: (int)video {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Pause");
    [m_AppDelegate.m_ViewController Pause];
}

-(void) SetVisible: (int)video isVisible:(int)visible {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::SetVisible");
    if(visible == 0) {
        [self Hide:video];
    } else {
        [self Show:video];
    }
}

-(dmVideoPlayer::LuaCallback) getCallback: (int)video {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::getCallback");
    return m_Videos[video].m_Callback;
}

@end

#endif
