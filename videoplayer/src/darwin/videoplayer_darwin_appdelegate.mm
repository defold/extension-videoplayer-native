#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#include "videoplayer_darwin_appdelegate.h"
#include "videoplayer_darwin_viewcontroller.h"
#include <dmsdk/sdk.h> // logging

@implementation VideoPlayerAppDelegate

@synthesize m_ViewController;

-(BOOL) application:(UIApplication*) application didFinishLaunchingWithOptions:(NSDictionary*) launchOptions {
    return YES;
}

-(void) Create {
    m_ViewController = [[[VideoPlayerViewController alloc] init] initWithNibName:nil bundle:nil];
}

-(void) Destroy {
    [m_ViewController release];
}

@end

#endif
