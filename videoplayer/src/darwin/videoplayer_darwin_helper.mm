#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#include "videoplayer_darwin_helper.h"
#include "../videoplayer_private.h"

namespace Helper {
    NSURL* GetUrlFromURI(const char* uri) {
        NSString* nsURI = [NSString stringWithUTF8String:uri];
        NSURL* url = [NSURL URLWithString:nsURI];
        if (url && url.scheme && [url.scheme length] > 0) {
            return url;
        }

        NSFileManager* fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:nsURI]) {
            return [NSURL fileURLWithPath:nsURI];
        }

        NSBundle* mainBundle = [NSBundle mainBundle];
        ReturnIf(mainBundle == NULL, NULL)
        
        NSString* file = [nsURI stringByDeletingPathExtension];
        NSString* ext = [nsURI pathExtension];
        NSString* resourcePath = [NSString stringWithFormat:@"%@%@", @"assets/", file];

        NSString* path = [mainBundle pathForResource:resourcePath ofType:ext];

        if (path == NULL) {
            path = [mainBundle pathForResource:file ofType:ext];
        }

        ReturnIf(path == NULL, NULL);
        
        return [[NSURL alloc] initFileURLWithPath: path];
    }

    BOOL GetInfoFromAsset(const AVURLAsset* asset, float& width, float& height) {
        NSArray<AVAssetTrack*>* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        ReturnIf(tracks == NULL, FALSE);

        int numTracks = [tracks count];
        ReturnIf(numTracks == 0, FALSE);

        AVAssetTrack* track = tracks[0];
        ReturnIf(track == NULL, FALSE)

        width = track.naturalSize.width;
        height = track.naturalSize.height;
        return TRUE;
    }
}

#endif
