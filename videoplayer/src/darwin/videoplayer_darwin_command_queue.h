#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once

namespace dmVideoPlayer {
    struct Command;
}

namespace CommandQueue {
    void Queue(dmVideoPlayer::Command* cmd);
    void Clear();
    
    int GetCount();
    dmVideoPlayer::Command* GetCommands();
    bool IsEmpty();
}

#endif


