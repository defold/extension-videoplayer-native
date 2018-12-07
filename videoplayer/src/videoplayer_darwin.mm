#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_private.h"

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

// ----------------------------------------------------------------------------

@interface VideoPlayerViewController : UIViewController {
    AVAsset* asset;
    AVPlayer* player;
    AVPlayerItem* playerItem;
    AVPlayerViewController* playerViewController;
}
    -(void) prepareVideoPlayer: (NSURL*) url;
    -(void) play;
@end

// ----------------------------------------------------------------------------

@interface VideoPlayerAppDelegate : UIResponder <UIApplicationDelegate>
    @property (strong, nonatomic) UIWindow* window;
    @property (strong, nonatomic) VideoPlayerViewController* viewController;
@end

// ----------------------------------------------------------------------------

@implementation VideoPlayerAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

-(BOOL) application:(UIApplication*) application didFinishLaunchingWithOptions:(NSDictionary*) launchOptions {
    dmLogInfo("VideoPlayerAppDelegate::didFinishLaunchingWithOptions()");
   
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.viewController = [[VideoPlayerViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = self.viewController;
    self.window.hidden = true;
    //[self.window makeKeyAndVisible];

    return YES;
}

// Maintenance methods

-(void) applicationWillResignActive:(UIApplication *)application {
    dmLogInfo("VideoPlayerViewController::applicationWillResignActive()");
}

-(void) applicationDidEnterBackground:(UIApplication *)application {
    dmLogInfo("VideoPlayerViewController::applicationDidEnterBackground()");
}

-(void) applicationWillEnterForeground:(UIApplication *)application {
    dmLogInfo("VideoPlayerViewController::applicationWillEnterForeground()");
}

-(void) applicationDidBecomeActive:(UIApplication *)application {
    dmLogInfo("VideoPlayerViewController::applicationDidBecomeActive()");
}

-(void) applicationWillTerminate:(UIApplication *)application {
    dmLogInfo("VideoPlayerViewController::applicationWillTerminate()");
}

@end

// ----------------------------------------------------------------------------

@implementation VideoPlayerViewController

-(void) prepareVideoPlayer: (NSURL*) url {
    dmLogInfo("VideoPlayerViewController::prepareVideoPlayer()");
    
    asset = [AVURLAsset URLAssetWithURL:url options:nil];
    playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    player = [AVPlayer playerWithPlayerItem:playerItem];
    [player addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    playerViewController = [AVPlayerViewController new];
    playerViewController.player = player;
    playerViewController.showsPlaybackControls = false;
    playerViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [self presentViewController:playerViewController animated:NO completion:nil];
}

-(void) play {
    [player play];
}

-(void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    dmLogInfo("VideoPlayerViewController::observeValueForKeyPath()");
    
    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusFailed) {
            dmLogInfo("AVPlayer Failed");
        } else if (player.status == AVPlayerStatusReadyToPlay) {
            dmLogInfo("AVPlayer Ready to Play");
            [self play];
        } /*else if (player.status == AVPlayerItemStatusUnknown) {
            dmLogInfo("AVPlayer Unknown");
        }*/
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    dmLogInfo("VideoPlayerViewController::supportedInterfaceOrientations()");
    return UIInterfaceOrientationMaskPortrait;
}

// View maintenance methods

-(void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    dmLogInfo("VideoPlayerViewController::didReceiveMemoryWarning()");
}

-(void) viewDidLoad {
    [super viewDidLoad];
    dmLogInfo("VideoPlayerViewController::viewDidLoad()");
}

-(void) viewDidUnload {
    [super viewDidUnload];
    dmLogInfo("VideoPlayerViewController::viewDidUnload()");
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    dmLogInfo("VideoPlayerViewController::viewWillAppear()");
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    dmLogInfo("VideoPlayerViewController::viewDidAppear()");
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    dmLogInfo("VideoPlayerViewController::viewWillDisappear()");
}

-(void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    dmLogInfo("VideoPlayerViewController::viewDidDisappear()");
}

-(BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    dmLogInfo("VideoPlayerViewController::shouldAutorotateToInterfaceOrientation()");
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

@end

// ----------------------------------------------------------------------------

VideoPlayerAppDelegate* g_VideoPlayerDelegate;

dmExtension::Result dmVideoPlayer::Init(dmExtension::Params* params) {
    dmLogInfo("dmVideoPlayer::Init()");    
    g_VideoPlayerDelegate = [[VideoPlayerAppDelegate alloc] init];
    dmExtension::RegisteriOSUIApplicationDelegate(g_VideoPlayerDelegate);
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params) {
    dmLogInfo("dmVideoPlayer::Exit()");
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Update(dmExtension::Params* params) {
    //dmLogInfo("dmVideoPlayer::Update()");
    return dmExtension::RESULT_OK;
}

int dmVideoPlayer::CreateWithUri(const char* uri, dmVideoPlayer::LuaCallback* cb) {
    dmLogInfo("dmVideoPlayer::CreateWithUri() '%s'", uri);
    [g_VideoPlayerDelegate.window makeKeyAndVisible];
    
    NSBundle* mainBundle = [NSBundle mainBundle];
    if(mainBundle == NULL) {
        dmLogInfo("mainBundle is null!");
        return dmExtension::RESULT_OK;
    } 
    
    NSString* path = [mainBundle pathForResource:@"assets/cutscene_2" ofType:@"mp4"];
    if(path == NULL) {
        dmLogInfo("path is null!");
        return dmExtension::RESULT_OK;
    }
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath: path];
    if(url == NULL) {
        dmLogInfo("url is null!");
        return dmExtension::RESULT_OK;
    }
    
    [g_VideoPlayerDelegate.viewController prepareVideoPlayer:url];    
    return dmExtension::RESULT_OK;
}

void dmVideoPlayer::Destroy(int video) {
    dmLogInfo("dmVideoPlayer::Destroy()");
}

void dmVideoPlayer::Show(int video) {
    dmLogInfo("dmVideoPlayer::Show()");
}

void dmVideoPlayer::Hide(int video) {
    dmLogInfo("dmVideoPlayer::Hide()");
}

void dmVideoPlayer::Start(int video) {
    dmLogInfo("dmVideoPlayer::Start()");
    //[g_VideoPlayerDelegate.viewController play];
}

void dmVideoPlayer::Stop(int video) {
    dmLogInfo("dmVideoPlayer::Stop()");
}

void dmVideoPlayer::Pause(int video) {
    dmLogInfo("dmVideoPlayer::Pause()");
}

void dmVideoPlayer::SetVisible(int video, int visible) {
    dmLogInfo("dmVideoPlayer::SetVisible()");
}

#endif
