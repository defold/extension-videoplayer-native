#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#pragma once
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#if !defined(ReturnIfFail)
#define ReturnIf(test, ret) \
if(test) { \
	return ret; \
}
#endif

namespace Helper {
	NSURL* GetUrlFromURI(const char* uri);
	BOOL GetInfoFromAsset(const AVURLAsset* asset, float& width, float& height);	
}

#endif
