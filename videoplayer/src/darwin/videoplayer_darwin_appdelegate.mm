#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#include "videoplayer_darwin_appdelegate.h"
#include "videoplayer_darwin_viewcontroller.h"

// TODO: This is debug logging - remove when implementation finished
#include <dmsdk/sdk.h>
#define DBGFNLOG dmLogWarning("%s: %s:%d:", __FILE__, __FUNCTION__, __LINE__); // debugging while developing only

@implementation VideoPlayerAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

-(BOOL) application:(UIApplication*) application didFinishLaunchingWithOptions:(NSDictionary*) launchOptions {
    DBGFNLOG;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[VideoPlayerViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = self.viewController;
    self.window.hidden = true;
    return YES;
}
@end

#endif
