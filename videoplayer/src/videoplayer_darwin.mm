#if defined(DM_PLATFORM_IOS)
#include "videoplayer_private.h"
#include "darwin/videoplayer_darwin_helper.h"
#include "darwin/videoplayer_darwin_appdelegate.h"
#include "darwin/videoplayer_darwin_viewcontroller.h"
#include "darwin/videoplayer_darwin_command_queue.h"

VideoPlayerAppDelegate* g_AppDelegate         = NULL;
VideoPlayerViewController* g_ViewController   = NULL;

// ----------------------------------------------------------------------------

int dmVideoPlayer::CreateWithUri(const char* uri, dmVideoPlayer::LuaCallback* cb) {
    NSURL* url = Helper::GetUrlFromURI(uri);    
    return [g_ViewController Create:url callback:cb];
}

void dmVideoPlayer::Destroy(int video) {
    if(g_ViewController != NULL) {
        [g_ViewController Destroy:video];
    }
    dmVideoPlayer::ClearCommandQueueFromID(video, CommandQueue::GetCount(), CommandQueue::GetCommands());
}

void dmVideoPlayer::Show(int video) {
    if(g_ViewController != NULL) {
        [g_ViewController Show:video];
    }
}

void dmVideoPlayer::Hide(int video) {
    if(g_ViewController != NULL) {
        [g_ViewController Hide:video];
    }
}

void dmVideoPlayer::Start(int video) {
    if(g_ViewController != NULL) {
        [g_ViewController Start:video];
    }
}

void dmVideoPlayer::Stop(int video) {
    if(g_ViewController != NULL) {
        [g_ViewController Stop:video];
    }
}

void dmVideoPlayer::Pause(int video) {
    if(g_ViewController != NULL) {
        [g_ViewController Pause:video];
    }
}

void dmVideoPlayer::SetVisible(int video, int visible) {
    if(visible == 0) {
        Hide(video);
    } else {
        Show(video);
    }
}

// ----------------------------------------------------------------------------

dmExtension::Result dmVideoPlayer::Init(dmExtension::Params* params) {
    g_AppDelegate = [[VideoPlayerAppDelegate alloc] init];
    dmExtension::RegisteriOSUIApplicationDelegate(g_AppDelegate);

    if(g_ViewController == NULL) {
        g_ViewController = [[[VideoPlayerViewController alloc] init] initWithNibName:nil bundle:nil];
    }

    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params) {
    for(int i = 0; i < dmVideoPlayer::MAX_NUM_VIDEOS; ++i) {
        dmVideoPlayer::Destroy(i);
    }
    CommandQueue::Clear();

    if(g_ViewController != NULL) {
        [g_ViewController release];
        g_ViewController = NULL;
    }
    
    dmExtension::UnregisteriOSUIApplicationDelegate(g_AppDelegate);
    [g_AppDelegate release];
    g_AppDelegate = NULL;
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Update(dmExtension::Params* params) {
    if (CommandQueue::IsEmpty()) {
        return dmExtension::RESULT_OK; 
    }
    if(g_ViewController != NULL) {
        dmVideoPlayer::ProcessCommandQueue(CommandQueue::GetCount(), CommandQueue::GetCommands());
        CommandQueue::Clear();
    }
    return dmExtension::RESULT_OK;
}

#endif