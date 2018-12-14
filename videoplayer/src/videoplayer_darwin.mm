#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_private.h"
#include "darwin/videoplayer_darwin_controller.h"
#include "darwin/videoplayer_darwin_command_queue.h"

VideoPlayerController* g_VideoPlayerController;

// ----------------------------------------------------------------------------

int dmVideoPlayer::CreateWithUri(const char* uri, dmVideoPlayer::LuaCallback* cb) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::CreateWithUri, cb:%p", cb);
    return [g_VideoPlayerController Create:uri callback:cb];
}

void dmVideoPlayer::Destroy(int video) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Destroy");
    dmVideoPlayer::ClearCommandQueueFromID(video, CommandQueue::GetCount(), CommandQueue::GetCommands());
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
    CommandQueue::Clear();
    [g_VideoPlayerController Exit];
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Update(dmExtension::Params* params) {
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Update");
    if (CommandQueue::IsEmpty()) {
        return dmExtension::RESULT_OK; 
    }
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::Update - CommandQueue not empty, processing %d commands", CommandQueue::GetCount());
    dmVideoPlayer::Command* cmd = CommandQueue::GetCommands();
    if(cmd == NULL) {
        dmLogInfo("SIMON DEBUG: dmVideoPlayer::Update GOT NULL COMMAND!");
    } else {
        dmLogInfo("SIMON DEBUG: dmVideoPlayer::Update Command info: type:%d, id:%d, w:%d, h:%d, cb:%p", cmd->m_Type, cmd->m_ID, cmd->m_Width, cmd->m_Height, cmd->m_Callback);
    }
    
    dmVideoPlayer::ProcessCommandQueue(CommandQueue::GetCount(), CommandQueue::GetCommands());
    CommandQueue::Clear();
    return dmExtension::RESULT_OK;
}

#endif
