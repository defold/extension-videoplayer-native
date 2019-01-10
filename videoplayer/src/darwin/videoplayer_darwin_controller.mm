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
        dmExtension::RegisteriOSUIApplicationDelegate(m_AppDelegate);
        m_ViewController = NULL;
    }
    return self;
}

-(void) Exit {    
    dmExtension::UnregisteriOSUIApplicationDelegate(m_AppDelegate);
    [m_AppDelegate release];
    m_AppDelegate = NULL;
}

-(int) Create: (const char*) uri callback:(dmVideoPlayer::LuaCallback*)cb {
    m_ViewController = [[[VideoPlayerViewController alloc] init] initWithNibName:nil bundle:nil];
    NSURL* url = Helper::GetUrlFromURI(uri);    
    return [m_ViewController Create:url callback:cb];
}

-(void) Destroy: (int)video {
    [m_ViewController Destroy:video];
    [m_ViewController release];
    m_ViewController = NULL;
}

-(void) Show: (int)video {
    [m_ViewController Show:video];
}

-(void) Hide: (int)video {
    [m_ViewController Hide:video];
}

-(void) Start: (int)video {
    [m_ViewController Start:video];
}

-(void) Stop: (int)video {
    [m_ViewController Stop:video];
}

-(void) Pause: (int)video {
    [m_ViewController Pause:video];
}

-(void) SetVisible: (int)video isVisible:(int)visible {
    if(visible == 0) {
        [self Hide:video];
    } else {
        [self Show:video];
    }
}

@end

#endif
