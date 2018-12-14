#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#include "videoplayer_darwin_appdelegate.h"
#include "videoplayer_darwin_viewcontroller.h"
#include <dmsdk/sdk.h> // logging

@implementation VideoPlayerAppDelegate

@synthesize m_Window;
@synthesize m_ViewController;


// save old view controller!
-(BOOL) application:(UIApplication*) application didFinishLaunchingWithOptions:(NSDictionary*) launchOptions {
    dmLogInfo("SIMON DEBUG: VideoPlayerAppDelegate::didFinishLaunchingWithOptions");
    return YES;
}

-(void) Create {
	if([self IsCreated] == NO) {
		dmLogInfo("SIMON DEBUG: VideoPlayerAppDelegate::Create");
		m_Window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		m_ViewController = [[VideoPlayerViewController alloc] initWithNibName:nil bundle:nil];
		m_Window.rootViewController = m_ViewController;
		m_Window.hidden = NO;
		[m_Window makeKeyAndVisible];
	}
}


-(BOOL) IsCreated {
	return (m_Window != NULL) && (m_ViewController != NULL);
}

-(void) Destroy {
    dmLogInfo("SIMON DEBUG: VideoPlayerAppDelegate::Destroy");
    //[m_ViewController release]
    //[m_Window release]
}

-(void) Show {
    dmLogInfo("SIMON DEBUG: VideoPlayerAppDelegate::Show");
    m_Window.hidden = NO;
}

-(void) Hide {
    dmLogInfo("SIMON DEBUG: VideoPlayerAppDelegate::Hide");
    m_Window.hidden = YES;
}

-(BOOL) IsHidden {
    dmLogInfo("SIMON DEBUG: VideoPlayerAppDelegate::IsHidden: %d", m_Window.hidden);
    return m_Window.hidden;
}

@end

#endif
