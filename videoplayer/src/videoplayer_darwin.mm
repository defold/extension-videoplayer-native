#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_private.h"
#include "darwin/videoplayer_darwin_viewcontroller.h"
#include "darwin/videoplayer_darwin_appdelegate.h"



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
