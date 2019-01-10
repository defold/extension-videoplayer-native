#include "videoplayer_private.h"

namespace dmVideoPlayer
{
/*
    struct VideoEventInfo
    {
        int             m_Id;
        VideoEvent      m_Event;
        int             m_Width;
        int             m_Height;
    };
*/    
void RunCallback(LuaCallback* cb, VideoEventInfo* info)
{
    dmLogInfo("SIMON DEBUG: dmVideoPlayer::RunCallback - %p, id:%d, w:%d, h:%d", cb, info->m_Id, info->m_Width, info->m_Height);

    
    if (cb->m_Callback == LUA_NOREF)
    {
        dmLogError("No callback set");
    }

    lua_State* L = cb->m_L;
    int top = lua_gettop(L);

    lua_rawgeti(L, LUA_REGISTRYINDEX, cb->m_Callback);
    // Setup self
    lua_rawgeti(L, LUA_REGISTRYINDEX, cb->m_Self);
    lua_pushvalue(L, -1);

    dmScript::SetInstance(L);

    if (!dmScript::IsInstanceValid(L))
    {
        dmLogError("Could not run Video callback because the instance has been deleted.");
        lua_pop(L, 2);
        assert(top == lua_gettop(L));
        return;
    }

    lua_pushnumber(L, (lua_Number)info->m_Id);
    lua_pushnumber(L, (lua_Number)info->m_Event);

    lua_newtable(L);
    if(info->m_Event == VIDEO_EVENT_READY)
    {
        lua_pushnumber(L, info->m_Width);
        lua_setfield(L, -2, "width");
        lua_pushnumber(L, info->m_Height);
        lua_setfield(L, -2, "height");
    }

    // 4 args: self, id, event, data
    int ret = lua_pcall(L, 4, 0, 0);
    if (ret != 0) {
        dmLogError("Error running Video callback: %s", lua_tostring(L,-1));
        lua_pop(L, 1);
    }
    assert(top == lua_gettop(L));
}


void UnregisterCallback(LuaCallback* cb)
{
    if( cb->m_Callback != LUA_NOREF )
        dmScript::Unref(cb->m_L, LUA_REGISTRYINDEX, cb->m_Callback);
    if( cb->m_Self != LUA_NOREF )
        dmScript::Unref(cb->m_L, LUA_REGISTRYINDEX, cb->m_Self);
    cb->m_L = 0;
    cb->m_Callback = LUA_NOREF;
    cb->m_Self = LUA_NOREF;
}

void RegisterCallback(lua_State* L, int index, LuaCallback* cb)
{
    luaL_checktype(L, index, LUA_TFUNCTION);
    lua_pushvalue(L, index);

    cb->m_Callback = dmScript::Ref(L, LUA_REGISTRYINDEX);
    dmScript::GetInstance(L);
    cb->m_Self = dmScript::Ref(L, LUA_REGISTRYINDEX);
    cb->m_L = dmScript::GetMainThread(L);
}

void ProcessCommandQueue(int count, Command* commands)
{
    for (uint32_t i=0; i != count; ++i)
    {
        Command* cmd = commands++;
        if (cmd->m_ID < 0)
            continue;

        VideoEventInfo eventinfo;
        eventinfo.m_Id = cmd->m_ID;

        switch (cmd->m_Type)
        {
        case CMD_PREPARE_OK:
            eventinfo.m_Event = VIDEO_EVENT_READY;
            eventinfo.m_Width = cmd->m_Width;
            eventinfo.m_Height = cmd->m_Height;
            break;

		case CMD_FINISHED:
            eventinfo.m_Event = VIDEO_EVENT_FINISHED;
			break;

        default:
            assert(false);
        }

        dmVideoPlayer::RunCallback(&cmd->m_Callback, &eventinfo);
    }
}

void ClearCommandQueueFromID(int id, int count, dmVideoPlayer::Command* commands)
{
    for (int i = 0; i < count; ++i)
    {
        dmVideoPlayer::Command& cmd = commands[i];
        if (cmd.m_ID == id)
        {
            cmd.m_ID = -1;
        }
    }
}


} // namespacew
