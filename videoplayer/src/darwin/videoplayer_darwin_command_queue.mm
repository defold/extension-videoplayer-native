#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_darwin_command_queue.h"
#include "../videoplayer_private.h"

namespace CommandQueue {
	static dmArray<dmVideoPlayer::Command> g_CmdQueue;

	void Queue(dmVideoPlayer::Command* cmd) {
	    if (g_CmdQueue.Full()) {
	        g_CmdQueue.OffsetCapacity(8);
	    }
	    g_CmdQueue.Push(*cmd);
	}

	void Clear() {
	    g_CmdQueue.SetSize(0);
	}

	int GetCount() {
		return g_CmdQueue.Size();
	}

	dmVideoPlayer::Command* GetCommands() {
		return &g_CmdQueue[0];
	}

	bool IsEmpty() {
		return g_CmdQueue.Empty();
	}
}

#endif
