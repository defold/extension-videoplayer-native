#pragma once

#if !defined(DLIB_LOG_DOMAIN)
#define DLIB_LOG_DOMAIN "VIDEOPLAYER"
#endif

#include <dmsdk/sdk.h>

#define DBGFNLOG dmLogWarning("%s: %s:%d:", __FILE__, __FUNCTION__, __LINE__); // debugging while developing only

namespace dmVideoPlayer
{

static const int MAX_NUM_VIDEOS = 1;

struct LuaCallback
{
    lua_State*  m_L;
    int         m_Self;
    int         m_Callback;
};

#define SETCONSTANT(name) name,
enum VideoEvent
{
#include "videoplayer_constants.h"
};
#undef SETCONSTANT

struct VideoEventInfo
{
    int             m_Id;
    VideoEvent      m_Event;
    int             m_Width;
    int             m_Height;
};

// Since the callbacks from the decoders (e.g. Java) can come at any time, we must ensure we only callback to Lua
// on the main thread. So we use a command buffer, which we use to callback during the extension Update() function
enum CommandType
{
    CMD_PREPARE_OK,
    CMD_FINISHED,
    CMD_PREPARE_ERROR,
};

struct Command
{
    CommandType m_Type;
    int         m_ID;
    int         m_Width;
    int         m_Height;
    LuaCallback m_Callback;
};


dmExtension::Result Init(dmExtension::Params* params);
dmExtension::Result Exit(dmExtension::Params* params);
dmExtension::Result Update(dmExtension::Params* params);

struct VideoPlayerCreateInfo
{
	LuaCallback* m_Callback;
	bool m_PlaySound;
};

int CreateWithUri(const char* uri, VideoPlayerCreateInfo createInfo);
//int CreateWithBuffer(dmBuffer::HBuffer buffer, void* video);
void Destroy(int video);
void Show(int video);
void Hide(int video);
void Start(int video);
void Stop(int video);
void Pause(int video);
void SetVisible(int video, int visible);


// common functions
void RunCallback(LuaCallback* cb, VideoEventInfo* cbinfo);
void RegisterCallback(lua_State* L, int index, LuaCallback* cb);
void UnregisterCallback(LuaCallback* cb);

void ProcessCommandQueue(int count, Command* commands);
void ClearCommandQueueFromID(int id, int count, dmVideoPlayer::Command* commands);

} // namespace
