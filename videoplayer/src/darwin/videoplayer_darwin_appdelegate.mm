#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#include "videoplayer_darwin_appdelegate.h"
#include "videoplayer_darwin_viewcontroller.h"
#include <dmsdk/sdk.h>
#define DBGFNLOG dmLogWarning("%s: %s:%d:", __FILE__, __FUNCTION__, __LINE__); // debugging while developing only

@implementation VideoPlayerAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;


// save old view controller!
-(BOOL) application:(UIApplication*) application didFinishLaunchingWithOptions:(NSDictionary*) launchOptions {
    DBGFNLOG;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[VideoPlayerViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = self.viewController;
    self.window.hidden = YES;
    return YES;
}

-(void) Show {
    self.window.hidden = NO;
}

-(void) Hide {
    self.window.hidden = YES;
}

-(BOOL) IsHidden {
	return self.window.hidden;
}

@end

#endif
