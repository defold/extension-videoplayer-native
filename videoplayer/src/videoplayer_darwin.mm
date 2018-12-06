#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_private.h"

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>

// ----------------------------------------------------------------------------

@interface VideoPlayerViewController : UIViewController {
    AVAsset *asset;
    AVPlayer *player;
    AVPlayerItem *playerItem;
    AVPlayerViewController *playerViewController;
}
-(void) prepareVideoPlayer: (NSURL*) url;
@end

// ----------------------------------------------------------------------------

@interface VideoPlayerAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) VideoPlayerViewController *viewController;
@end

// ----------------------------------------------------------------------------

@implementation VideoPlayerAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.viewController = [[VideoPlayerViewController alloc] initWithNibName:@"VideoPlayerViewController" bundle:nil];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    /*
    NSString *path = [[NSBundle mainBundle] pathForResource:@"big_buck_bunny_720p_1mb" ofType:@"mp4"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath: path];
    [self.viewController prepareVideoPlayer:url];
     */
    return YES;
}

// Maintenance methods

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillTerminate:(UIApplication *)application {
}

@end

// ----------------------------------------------------------------------------

@implementation VideoPlayerViewController

-(void) prepareVideoPlayer: (NSURL*) url {
    asset = [AVURLAsset URLAssetWithURL:url options:nil];
    playerItem = [AVPlayerItem playerItemWithAsset:asset];
    
    player = [AVPlayer playerWithPlayerItem:playerItem];
    [player addObserver:self forKeyPath:@"status" options:0 context:nil];
    
    playerViewController = [AVPlayerViewController new];
    playerViewController.player = player;
    playerViewController.showsPlaybackControls = false;
    playerViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:playerViewController animated:NO completion:nil];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    
    if (object == player && [keyPath isEqualToString:@"status"]) {
        if (player.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayer Failed");
        } else if (player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayer Ready to Play");
            [player play];
        } else if (player.status == AVPlayerItemStatusUnknown) {
            NSLog(@"AVPlayer Unknown");
        }
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
    //return UIInterfaceOrientationMaskLandscapeRight;
}

// View maintenance methods

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"big_buck_bunny_720p_1mb" ofType:@"mp4"];
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"cutscene_2" ofType:@"mp4"];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cutscene_3" ofType:@"mp4"];
    NSURL *url = [[NSURL alloc] initFileURLWithPath: path];
    [self prepareVideoPlayer:url];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

@end

// ----------------------------------------------------------------------------

dmExtension::Result dmVideoPlayer::Init(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Update(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

int dmVideoPlayer::CreateWithUri(const char* uri, dmVideoPlayer::LuaCallback* cb)
{
    return dmExtension::RESULT_OK;
}

void dmVideoPlayer::Destroy(int video)
{
}

void dmVideoPlayer::Show(int video)
{
}

void dmVideoPlayer::Hide(int video)
{
}

void dmVideoPlayer::Start(int video)
{
}

void dmVideoPlayer::Stop(int video)
{
}

void dmVideoPlayer::Pause(int video)
{
}

void dmVideoPlayer::SetVisible(int video, int visible)
{
}

#endif
