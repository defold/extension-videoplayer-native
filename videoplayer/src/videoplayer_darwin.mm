#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_private.h"
#include "darwin/videoplayer_darwin_controller.h"

dmArray<dmVideoPlayer::Command> g_CmdQueue;
VideoPlayerController* g_VideoPlayerController;

static void QueueCommand(dmVideoPlayer::Command* cmd) {
    if (g_CmdQueue.Full()) {
        g_CmdQueue.OffsetCapacity(8);
    }
    g_CmdQueue.Push(*cmd);
}

static void ClearCommandQueue() {
    g_CmdQueue.SetSize(0);
}

// ----------------------------------------------------------------------------

int dmVideoPlayer::CreateWithUri(const char* uri, dmVideoPlayer::LuaCallback* cb) {
    return g_VideoPlayerController->Create(uri, cb);
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
    //g_VideoContext.m_VideoPlayerDelegate.window.hidden = false;
    [g_VideoContext.m_VideoPlayerDelegate.viewController Show];
}

void dmVideoPlayer::Hide(int video) {
    DBGFNLOG;
    //g_VideoContext.m_VideoPlayerDelegate.window.hidden = true;
    [g_VideoContext.m_VideoPlayerDelegate.viewController Hide];
}

void dmVideoPlayer::Start(int video) {
    DBGFNLOG;
    Show(0);
    [g_VideoContext.m_VideoPlayerDelegate.viewController Play];
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
    g_VideoPlayerController = new VideoPlayerController();
    dmExtension::RegisteriOSUIApplicationDelegate(videoPlayerDelegate);
    g_VideoContext.m_VideoPlayerDelegate = videoPlayerDelegate;
    g_VideoContext.m_NumVideos = 0;
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params) {
    DBGFNLOG;
    for( int i = 0; i < dmVideoPlayer::MAX_NUM_VIDEOS; ++i) {
        dmVideoPlayer::Destroy(i);
    }
    ClearCommandQueue();

    dmExtension::UnregisteriOSUIApplicationDelegate(g_VideoContext.m_VideoPlayerDelegate);
    [g_VideoContext.m_VideoPlayerDelegate release];
    g_VideoContext.m_VideoPlayerDelegate = 0;
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
