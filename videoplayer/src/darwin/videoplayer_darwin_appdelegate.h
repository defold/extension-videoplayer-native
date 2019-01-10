#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

#import <UIKit/UIKit.h>

@class VideoPlayerViewController;

@interface VideoPlayerAppDelegate : UIResponder <UIApplicationDelegate>

-(void) Create;
-(void) Destroy;

@property (strong, nonatomic) VideoPlayerViewController* m_ViewController;
@end

#endif
