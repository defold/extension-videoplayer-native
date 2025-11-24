#if defined(DM_PLATFORM_HTML5)

#include "videoplayer_private.h"

#include <dmsdk/dlib/array.h>
#include <emscripten/emscripten.h>
#include <string.h>

namespace dmVideoPlayer
{

struct Html5Context
{
    int                     m_Handle;
    LuaCallback             m_Callback;
    dmArray<Command>        m_CmdQueue;
};

static Html5Context g_Context;

static void QueueCommand(Command* cmd)
{
    if (g_Context.m_CmdQueue.Full())
    {
        g_Context.m_CmdQueue.OffsetCapacity(4);
    }
    g_Context.m_CmdQueue.Push(*cmd);
}

extern "C"
{
    EMSCRIPTEN_KEEPALIVE void dmVideoplayerDispatchEvent(int handle, int event, int width, int height)
    {
        if (handle != g_Context.m_Handle)
            return;

        Command cmd;
        memset(&cmd, 0, sizeof(cmd));
        cmd.m_ID = handle;
        cmd.m_Callback = g_Context.m_Callback;

        switch (event)
        {
        case VIDEO_EVENT_READY:
            cmd.m_Type = CMD_PREPARE_OK;
            cmd.m_Width = width;
            cmd.m_Height = height;
            break;
        case VIDEO_EVENT_FINISHED:
            cmd.m_Type = CMD_FINISHED;
            break;
        case VIDEO_EVENT_FAILED:
            cmd.m_Type = CMD_PREPARE_ERROR;
            break;
        default:
            dmLogWarning("Unknown HTML5 video event: %d", event);
            return;
        }

        QueueCommand(&cmd);
    }

    int dmVideoplayerHtml5Create(const char* uri, int playSound);
    void dmVideoplayerHtml5Destroy(int handle);
    void dmVideoplayerHtml5Start(int handle);
    void dmVideoplayerHtml5Stop(int handle);
    void dmVideoplayerHtml5Pause(int handle);
    void dmVideoplayerHtml5SetVisible(int handle, int visible);
}

int CreateWithUri(const char* uri, const VideoPlayerCreateInfo& createInfo)
{
    if (g_Context.m_Handle >= 0)
    {
        dmLogError("Max number of videos opened: %d", MAX_NUM_VIDEOS);
        return -1;
    }

    int handle = dmVideoplayerHtml5Create(uri, createInfo.m_PlaySound ? 1 : 0);

    if (handle >= 0)
    {
        g_Context.m_Handle = handle;
        g_Context.m_Callback = *createInfo.m_Callback;
    }

    return handle;
}

void Destroy(int video)
{
    if (video != g_Context.m_Handle)
        return;

    if (!g_Context.m_CmdQueue.Empty())
    {
        ClearCommandQueueFromID(video, g_Context.m_CmdQueue.Size(), &g_Context.m_CmdQueue[0]);
    }

    dmVideoplayerHtml5Destroy(video);

    UnregisterCallback(&g_Context.m_Callback);
    g_Context.m_Handle = -1;
}

void SetVisible(int video, int visible)
{
    if (video != g_Context.m_Handle)
        return;

    dmVideoplayerHtml5SetVisible(video, visible);
}

void Start(int video)
{
    if (video != g_Context.m_Handle)
        return;

    dmVideoplayerHtml5Start(video);
}

void Stop(int video)
{
    if (video != g_Context.m_Handle)
        return;

    dmVideoplayerHtml5Stop(video);
}

void Pause(int video)
{
    if (video != g_Context.m_Handle)
        return;

    dmVideoplayerHtml5Pause(video);
}

dmExtension::Result Init(dmExtension::Params* params)
{
    g_Context.m_Handle = -1;
    g_Context.m_Callback.m_L = 0;
    g_Context.m_Callback.m_Callback = LUA_NOREF;
    g_Context.m_Callback.m_Self = LUA_NOREF;
    g_Context.m_CmdQueue.SetCapacity(4);
    return dmExtension::RESULT_OK;
}

dmExtension::Result Exit(dmExtension::Params* params)
{
    if (g_Context.m_Handle >= 0)
    {
        Destroy(g_Context.m_Handle);
    }
    g_Context.m_CmdQueue.SetSize(0);
    return dmExtension::RESULT_OK;
}

dmExtension::Result Update(dmExtension::Params* params)
{
    if (g_Context.m_CmdQueue.Empty())
        return dmExtension::RESULT_OK;

    ProcessCommandQueue(g_Context.m_CmdQueue.Size(), &g_Context.m_CmdQueue[0]);
    g_Context.m_CmdQueue.SetSize(0);
    return dmExtension::RESULT_OK;
}

} // namespace dmVideoPlayer

#endif // defined(DM_PLATFORM_HTML5)
