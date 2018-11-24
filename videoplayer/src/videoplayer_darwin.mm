#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_private.h"

dmExtension::Result dmVideoPlayer::Init(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Update(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

int dmVideoPlayer::CreateWithUri(const char* uri, dmVideoPlayer::LuaCallback* cb)
{
    return dmExtension::RESULT_OK;
}

void dmVideoPlayer::Destroy(int video)
{
}

void dmVideoPlayer::Show(int video)
{
}

void dmVideoPlayer::Hide(int video)
{
}

void dmVideoPlayer::Start(int video)
{
}

void dmVideoPlayer::Stop(int video)
{
}

void dmVideoPlayer::Pause(int video)
{
}

void dmVideoPlayer::SetVisible(int video, int visible)
{
}

#endif
