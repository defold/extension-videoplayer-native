#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_private.h"
#include "darwin/videoplayer_darwin_controller.h"
#include "darwin/videoplayer_darwin_command_queue.h"

VideoPlayerController* g_VideoPlayerController;

// ----------------------------------------------------------------------------

int dmVideoPlayer::CreateWithUri(const char* uri, dmVideoPlayer::LuaCallback* cb) {
    return [g_VideoPlayerController Create:uri callback:cb];
}

void dmVideoPlayer::Destroy(int video) {
    dmVideoPlayer::ClearCommandQueueFromID(video, CommandQueue::GetCount(), CommandQueue::GetCommands());
    [g_VideoPlayerController Destroy:video];
}

void dmVideoPlayer::Show(int video) {
    [g_VideoPlayerController Show:video];
}

void dmVideoPlayer::Hide(int video) {
    [g_VideoPlayerController Hide:video];
}

void dmVideoPlayer::Start(int video) {
    [g_VideoPlayerController Start:video];
}

void dmVideoPlayer::Stop(int video) {
    [g_VideoPlayerController Stop:video];
}

void dmVideoPlayer::Pause(int video) {
    [g_VideoPlayerController Pause:video];
}

void dmVideoPlayer::SetVisible(int video, int visible) {
    [g_VideoPlayerController SetVisible:video isVisible:visible];
}

// ----------------------------------------------------------------------------

dmExtension::Result dmVideoPlayer::Init(dmExtension::Params* params) {
    g_VideoPlayerController = [[VideoPlayerController alloc] init];
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params) {
    for(int i = 0; i < dmVideoPlayer::MAX_NUM_VIDEOS; ++i) {
        dmVideoPlayer::Destroy(i);
    }
    CommandQueue::Clear();
    [g_VideoPlayerController Exit];
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Update(dmExtension::Params* params) {
    if (CommandQueue::IsEmpty()) {
        return dmExtension::RESULT_OK; 
    }    
    dmVideoPlayer::ProcessCommandQueue(CommandQueue::GetCount(), CommandQueue::GetCommands());
    CommandQueue::Clear();
    return dmExtension::RESULT_OK;
}

#endif
