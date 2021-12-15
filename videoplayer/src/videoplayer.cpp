#define LIB_NAME "VideoPlayer"
#define MODULE_NAME "videoplayer"

// Defold SDK
#include <dmsdk/sdk.h>

#if defined(DM_PLATFORM_ANDROID) || defined(DM_PLATFORM_IOS)

#include <stdlib.h>
#include <stdio.h>

#include "videoplayer_private.h"

static int Create(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 1);

	bool playSound = true;
	if(lua_istable(L, 2)){
		lua_getfield(L, 2, "play_sound");
		if(lua_isboolean(L, -1)){
			playSound = lua_toboolean(L, -1);
		}else if(!lua_isnil(L, -1)){
			return luaL_error(L, "%s.Create() Expected type of 'play_sound' to be boolean!", MODULE_NAME);
		}
		lua_pop(L, 1);
	}else if(!lua_isnil(L, 2)){
		return luaL_error(L, "%s.Create() #2 argument only supports table: %s", MODULE_NAME, lua_tostring(L, 1));
	}

    dmVideoPlayer::LuaCallback cb;
    dmVideoPlayer::RegisterCallback(L, 3, &cb);

	dmVideoPlayer::VideoPlayerCreateInfo createInfo;
	createInfo.m_Callback = &cb;
	createInfo.m_PlaySound = playSound;

    int video = 0;
    if (lua_isstring(L, 1) ) {
        const char* uri = luaL_checkstring(L, 1);
        video = dmVideoPlayer::CreateWithUri(uri, createInfo);
    }
    // else if() {
    //     dmScript::LuaHBuffer buffer = dmScript::CheckBuffer(L, 1);
    //     return luaL_error(L, "%s.create doesn't support buffers yet: %s", MODULE_NAME, uri);
    //     //video = dmVideoPlayer::CreateWithBuffer(*buffer, dmVideoPlayer::EventCallback, (void*)video);
    // }
    else {
        return luaL_error(L, "%s.Create() #1 argument only supports strings: %s", MODULE_NAME, lua_tostring(L, 1));
    }

	dmLogWarning("Video created: %d", video);

    if (video >= 0) {
        lua_pushnumber(L, video);
    } else {
        lua_pushnil(L);
        dmLogError("Failed to open video: %s", lua_tostring(L, 1));
    }
    return 1;
}

static int Destroy(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    int id = luaL_checknumber(L, 1);
    dmVideoPlayer::Destroy(id);
    return 0;
}

static int Start(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    int id = luaL_checknumber(L, 1);
    dmVideoPlayer::Start(id);
    return 0;
}

static int Stop(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    int id = luaL_checknumber(L, 1);
    dmVideoPlayer::Stop(id);
    return 0;
}

static int Pause(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    int id = luaL_checknumber(L, 1);
    dmVideoPlayer::Pause(id);
    return 0;
}

static int SetVisible(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    int id = luaL_checknumber(L, 1);
    int visible = luaL_checknumber(L, 2);
    dmVideoPlayer::SetVisible(id, visible);
    return 0;
}

static const luaL_reg Module_methods[] =
{
    {"create", Create},
    {"destroy", Destroy},
    {"start", Start},
    {"stop", Stop},
    {"pause", Pause},
    {"set_visible", SetVisible},
    {0, 0}
};

static void LuaInit(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    luaL_register(L, MODULE_NAME, Module_methods);


#define SETCONSTANT(name) \
        lua_pushnumber(L, (lua_Number)dmVideoPlayer:: name); \
        lua_setfield(L, -2, #name);\

#include "videoplayer_constants.h"

#undef SETCONSTANT


    lua_pop(L, 1);
}

static dmExtension::Result AppInitializeVideoPlayer(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result InitializeVideoPlayer(dmExtension::Params* params)
{
    if (dmVideoPlayer::Init(params) == dmExtension::RESULT_OK) {
        LuaInit(params->m_L);
        dmLogInfo("Registered %s extension", MODULE_NAME);
    } else {
        dmLogError("Failed to init %s extension", MODULE_NAME);
    }
    return dmExtension::RESULT_OK;
}

static dmExtension::Result UpdateVideoPlayer(dmExtension::Params* params)
{
    return dmVideoPlayer::Update(params);
}

static dmExtension::Result AppFinalizeVideoPlayer(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result FinalizeVideoPlayer(dmExtension::Params* params)
{
    return dmVideoPlayer::Exit(params);
}

#else

static dmExtension::Result AppInitializeVideoPlayer(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result InitializeVideoPlayer(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result UpdateVideoPlayer(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result AppFinalizeVideoPlayer(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result FinalizeVideoPlayer(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

#endif

DM_DECLARE_EXTENSION(VideoPlayer, LIB_NAME, AppInitializeVideoPlayer, AppFinalizeVideoPlayer, InitializeVideoPlayer, UpdateVideoPlayer, 0, FinalizeVideoPlayer)
