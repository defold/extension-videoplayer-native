// -----------------------------------------------------------------------
// TODO: Remove this class and move logic to videoplayer_darwin.mm
// -----------------------------------------------------------------------

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
    }
    return self;
}

-(void) Exit {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Exit");
    dmExtension::UnregisteriOSUIApplicationDelegate(m_AppDelegate);
    [m_AppDelegate release];
    m_AppDelegate = NULL;
}

-(int) Create: (const char*) uri callback:(dmVideoPlayer::LuaCallback*)cb {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Create");
    
    [m_AppDelegate Create];

    //[m_AppDelegate.m_Window makeKeyAndVisible];
    //m_AppDelegate.window.hidden = false;
    
    NSURL* url = Helper::GetUrlFromURI(uri);    
    return [m_AppDelegate.m_ViewController Create:url callback:cb];
}

-(void) Destroy: (int)videoId {
    dmLogInfo("SIMON DEBUG: VideoPlayerController::Destroy");
    [m_AppDelegate.m_ViewController Destroy:videoId];
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

@end

#endif
