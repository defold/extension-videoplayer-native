#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

#import <UIKit/UIKit.h>

@class VideoPlayerViewController;

@interface VideoPlayerAppDelegate : UIResponder <UIApplicationDelegate>

-(void) Create;
-(BOOL) IsCreated;
-(void) Destroy;

//-(void) Show;
//-(void) Hide;
//-(BOOL) IsHidden;

//@property (strong, nonatomic) UIWindow* m_Window;
@property (strong, nonatomic) VideoPlayerViewController* m_ViewController;
@end

#endif
