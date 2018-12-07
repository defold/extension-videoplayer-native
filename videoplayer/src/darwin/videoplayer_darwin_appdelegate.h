#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

#import <UIKit/UIKit.h>

@class VideoPlayerViewController;

@interface VideoPlayerAppDelegate : UIResponder <UIApplicationDelegate>
    @property (strong, nonatomic) UIWindow* window;
    @property (strong, nonatomic) VideoPlayerViewController* viewController;
@end

#endif
