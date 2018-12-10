#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_private.h"
#include "darwin/videoplayer_darwin_viewcontroller.h"
#include "darwin/videoplayer_darwin_appdelegate.h"


struct SDarwinVideoInfo
{
    dmVideoPlayer::LuaCallback  m_Callback;
    //jobject                     m_Video;
    VideoPlayerAppDelegate* g_VideoPlayerDelegate;
};

struct SVideoPlayerContext
{
    /*
    jobject   m_Activity;
    jclass    m_Class;

    jmethodID m_CreateFn;
    jmethodID m_DestroyFn;
    jmethodID m_StartFn;
    jmethodID m_StopFn;
    jmethodID m_PauseFn;
    jmethodID m_SetVisibleFn;
    */

    int                 m_NumVideos;
    SDarwinVideoInfo    m_Videos[dmVideoPlayer::MAX_NUM_VIDEOS];

    dmArray<dmVideoPlayer::Command>    m_CmdQueue; // TODO: Create mutex to protect the queue
} g_VideoContext;

VideoPlayerAppDelegate* g_VideoPlayerDelegate;


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------



static void QueueCommand(dmVideoPlayer::Command* cmd) {
    if (g_VideoContext.m_CmdQueue.Full()) {
        g_VideoContext.m_CmdQueue.OffsetCapacity(8);
    }
    g_VideoContext.m_CmdQueue.Push(*cmd);
}

static void ClearCommandQueue() {
    g_VideoContext.m_CmdQueue.SetSize(0);
}



// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------



int dmVideoPlayer::CreateWithUri(const char* uri, dmVideoPlayer::LuaCallback* cb) {
    dmLogInfo("dmVideoPlayer::CreateWithUri() '%s'", uri);

    if (g_VideoContext.m_NumVideos >= MAX_NUM_VIDEOS) {
        dmLogError("Max number of videos opened: %d", MAX_NUM_VIDEOS);
        return -1;
    }
    int id = g_VideoContext.m_NumVideos;



    // ------------------------------------------------------------------------



    //[g_VideoPlayerDelegate.window makeKeyAndVisible];
    g_VideoPlayerDelegate.window.hidden = false;
    
    NSBundle* mainBundle = [NSBundle mainBundle];
    if(mainBundle == NULL) {
        dmLogInfo("mainBundle is null!");
        return dmExtension::RESULT_OK;
    } 
    
    NSString* nsURI = [NSString stringWithUTF8String:uri];
    NSString* file = [nsURI stringByDeletingPathExtension];
    NSString* ext = [nsURI pathExtension];
    NSString* resourcePath = [NSString stringWithFormat:@"%@%@", @"assets/", file];
    dmLogInfo("file: '%s', ext: '%s', resourcePath: '%s'", [file UTF8String], [ext UTF8String], [resourcePath UTF8String]);

    NSString* path = [mainBundle pathForResource:resourcePath ofType:ext];
    if(path == NULL) {
        dmLogInfo("path is null!");
        return dmExtension::RESULT_OK;
    }
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath: path];
    if(url == NULL) {
        dmLogInfo("url is null!");
        return dmExtension::RESULT_OK;
    }
    
    [g_VideoPlayerDelegate.viewController PrepareVideoPlayer:url];



    // ------------------------------------------------------------------------



    /*if (jvideo) {
        ++g_VideoContext.m_NumVideos;
        SDarwinVideoInfo& info = g_VideoContext.m_Videos[id];
        info.m_Video = jvideo;
        info.m_Callback = *cb;
        return id;
    }*/
    return -1;
}

void dmVideoPlayer::Destroy(int video) {
    DBGFNLOG;
    dmVideoPlayer::ClearCommandQueueFromID(video, g_VideoContext.m_CmdQueue.Size(), &g_VideoContext.m_CmdQueue[0]);
    SDarwinVideoInfo& info = g_VideoContext.m_Videos[video];
    dmVideoPlayer::UnregisterCallback(&info.m_Callback);
    //info.m_Video = 0;
    --g_VideoContext.m_NumVideos;
}

void dmVideoPlayer::Show(int video) {
    DBGFNLOG;
    //g_VideoPlayerDelegate.window.hidden = false;
    //[g_VideoPlayerDelegate.viewController Show];
}

void dmVideoPlayer::Hide(int video) {
    DBGFNLOG;
    //g_VideoPlayerDelegate.window.hidden = true;
    //[g_VideoPlayerDelegate.viewController Hide];
}

void dmVideoPlayer::Start(int video) {
    DBGFNLOG;
    Show(0);
    [g_VideoPlayerDelegate.viewController Play];
}

void dmVideoPlayer::Stop(int video) {
    DBGFNLOG;
}

void dmVideoPlayer::Pause(int video) {
    DBGFNLOG;
}

void dmVideoPlayer::SetVisible(int video, int visible) {
    DBGFNLOG;
    if(visible == 0) {
        Hide(video);
    } else {
        Show(video);
    }
}



// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------



dmExtension::Result dmVideoPlayer::Init(dmExtension::Params* params) {
    DBGFNLOG;
    g_VideoPlayerDelegate = [[VideoPlayerAppDelegate alloc] init];
    dmExtension::RegisteriOSUIApplicationDelegate(g_VideoPlayerDelegate);
    g_VideoContext.m_NumVideos = 0;
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params) {
    DBGFNLOG;
    for( int i = 0; i < dmVideoPlayer::MAX_NUM_VIDEOS; ++i) {
        dmVideoPlayer::Destroy(i);
    }
    ClearCommandQueue();
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Update(dmExtension::Params* params) {
    if (g_VideoContext.m_CmdQueue.Empty()) {
        return dmExtension::RESULT_OK; 
    }
    dmVideoPlayer::ProcessCommandQueue(g_VideoContext.m_CmdQueue.Size(), &g_VideoContext.m_CmdQueue[0]);
    g_VideoContext.m_CmdQueue.SetSize(0);
    return dmExtension::RESULT_OK;
}

#endif
