#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "../videoplayer_private.h"

#ifndef ReturnIfNull
#define ReturnIfNull(x, y)    \
if(x == NULL) {               \
    dmLogInfo(#x" is null!"); \
    return y;                 \
}                             \
#endif

-(NSURL*) GetUrlFromURI: (const char*)uri;

#endif
