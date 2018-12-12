#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_darwin_helper.h"

NSURL* GetUrlFromURI(const char* uri) {
    NSBundle* mainBundle = [NSBundle mainBundle];
    ReturnIfNull(mainBundle, NULL)
    
    NSString* nsURI = [NSString stringWithUTF8String:uri];
    NSString* file = [nsURI stringByDeletingPathExtension];
    NSString* ext = [nsURI pathExtension];
    NSString* resourcePath = [NSString stringWithFormat:@"%@%@", @"assets/", file];
    dmLogInfo("file: '%s', ext: '%s', resourcePath: '%s'", [file UTF8String], [ext UTF8String], [resourcePath UTF8String]);

    NSString* path = [mainBundle pathForResource:resourcePath ofType:ext];
    ReturnIfNull(path, NULL);
    
    return [[NSURL alloc] initFileURLWithPath: path];
}

#endif
