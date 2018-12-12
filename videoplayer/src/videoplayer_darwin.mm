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
    return [g_VideoPlayerController Create:uri callback:cb];
}

void dmVideoPlayer::Destroy(int video) {
    dmVideoPlayer::ClearCommandQueueFromID(video, g_CmdQueue.Size(), &g_CmdQueue[0]);
    [g_VideoPlayerController Destroy:video]
}

void dmVideoPlayer::Show(int video) {
    [g_VideoPlayerController Show:video]
}

void dmVideoPlayer::Hide(int video) {
    [g_VideoPlayerController Hide:video]
}

void dmVideoPlayer::Start(int video) {
    [g_VideoPlayerController Start:video]
}

void dmVideoPlayer::Stop(int video) {
    [g_VideoPlayerController Stop:video]
}

void dmVideoPlayer::Pause(int video) {
    [g_VideoPlayerController Pause:video]
}

void dmVideoPlayer::SetVisible(int video, int visible) {
    [g_VideoPlayerController SetVisible:video isVisible:visible]
}

// ----------------------------------------------------------------------------

dmExtension::Result dmVideoPlayer::Init(dmExtension::Params* params) {
    DBGFNLOG;
    g_VideoPlayerController = [[VideoPlayerController alloc] init];
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params) {
    DBGFNLOG;
    for(int i = 0; i < dmVideoPlayer::MAX_NUM_VIDEOS; ++i) {
        dmVideoPlayer::Destroy(i);
    }
    ClearCommandQueue();
    [g_VideoPlayerController Exit];
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Update(dmExtension::Params* params) {
    if (g_CmdQueue.Empty()) {
        return dmExtension::RESULT_OK; 
    }
    dmVideoPlayer::ProcessCommandQueue(g_cmdQueue.Size(), &g_CmdQueue[0]);
    g_CmdQueue.SetSize(0);
    return dmExtension::RESULT_OK;
}

#endif
