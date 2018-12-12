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
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::CreateWithUri");
    return [g_VideoPlayerController Create:uri callback:cb];
}

void dmVideoPlayer::Destroy(int video) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Destroy");
    dmVideoPlayer::ClearCommandQueueFromID(video, g_CmdQueue.Size(), &g_CmdQueue[0]);
    [g_VideoPlayerController Destroy:video];
}

void dmVideoPlayer::Show(int video) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Show");
    [g_VideoPlayerController Show:video];
}

void dmVideoPlayer::Hide(int video) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Hide");
    [g_VideoPlayerController Hide:video];
}

void dmVideoPlayer::Start(int video) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Start");
    [g_VideoPlayerController Start:video];
}

void dmVideoPlayer::Stop(int video) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Stop");
    [g_VideoPlayerController Stop:video];
}

void dmVideoPlayer::Pause(int video) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Pause");
    [g_VideoPlayerController Pause:video];
}

void dmVideoPlayer::SetVisible(int video, int visible) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::SetVisible");
    [g_VideoPlayerController SetVisible:video isVisible:visible];
}

// ----------------------------------------------------------------------------

dmExtension::Result dmVideoPlayer::Init(dmExtension::Params* params) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Init");
    g_VideoPlayerController = [[VideoPlayerController alloc] init];
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Exit");
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
    dmVideoPlayer::ProcessCommandQueue(g_CmdQueue.Size(), &g_CmdQueue[0]);
    g_CmdQueue.SetSize(0);
    return dmExtension::RESULT_OK;
}

#endif
