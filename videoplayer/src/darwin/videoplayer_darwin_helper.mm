#if defined(DM_PLATFORM_IOS)
#include "videoplayer_darwin_helper.h"
#include "../videoplayer_private.h"

namespace Helper {
    NSURL* GetUrlFromURI(const char* uri) {
        NSBundle* mainBundle = [NSBundle mainBundle];
        ReturnIf(mainBundle == NULL, NULL)
        
        NSString* nsURI = [NSString stringWithUTF8String:uri];
        NSString* file = [nsURI stringByDeletingPathExtension];
        NSString* ext = [nsURI pathExtension];
        NSString* resourcePath = [NSString stringWithFormat:@"%@%@", @"assets/", file];

        NSString* path = [mainBundle pathForResource:resourcePath ofType:ext];
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
