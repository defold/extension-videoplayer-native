#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#include "videoplayer_darwin_appdelegate.h"

@implementation VideoPlayerAppDelegate
-(BOOL) application:(UIApplication*) application didFinishLaunchingWithOptions:(NSDictionary*) launchOptions {
    return YES;
}
@end

#endif
