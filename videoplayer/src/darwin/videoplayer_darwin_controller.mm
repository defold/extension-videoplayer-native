#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)

#include "videoplayer_darwin_controller.h"
#include "videoplayer_darwin_viewcontroller.h"
#include "videoplayer_darwin_appdelegate.h"
#include "videoplayer_darwin_types.h"
#include <dmsdk/sdk.h>
#define DBGFNLOG dmLogWarning("%s: %s:%d:", __FILE__, __FUNCTION__, __LINE__); // debugging while developing only



@implementation VideoPlayerController

@synthesize appDelegate;
@synthesize viewController;

SVideoPlayerContext g_VideoContext;

#define ReturnIfNull(x,y)             \
if(x == NULL) {                       \
    dmLogInfo("##y is null!");        \
    return NULL;                      \
}                                     \

-(NSURL*) GetUrlFromURI((const char*)uri) {
    NSBundle* mainBundle = [NSBundle mainBundle];
    if(mainBundle == NULL) {
        dmLogInfo("mainBundle is null!");
        return dmExtension::RESULT_OK;
    } 
    
    NSString* nsURI = [NSString stringWithUTF8String:uri];
    NSString* file = [nsURI stringByDeletingPathExtension];
    NSString* ext = [nsURI pathExtension];
    NSString* resourcePath = [NSString stringWithFormat:@"%@%@", @"assets/", file];
    dmLogInfo("file: '%s', ext: '%s', resourcePath: '%s'", [file UTF8String], [ext UTF8String], [resourcePath UTF8String]);

    NSString* path = [mainBundle pathForResource:resourcePath ofType:ext];
    if(path == NULL) {
        dmLogInfo("path is null!");
        return dmExtension::RESULT_OK;
    }
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath: path];
    if(url == NULL) {
        dmLogInfo("url is null!");
        return dmExtension::RESULT_OK;
    }

}



-(int) Create: (const char*) uri callback:(dmVideoPlayer::LuaCallback*) cb {
    DBGFNLOG;

    if (g_VideoContext.m_NumVideos >= MAX_NUM_VIDEOS) {
        dmLogError("Max number of videos opened: %d", MAX_NUM_VIDEOS);
        return -1;
    }
    int id = g_VideoContext.m_NumVideos;



    // ------------------------------------------------------------------------


    //[g_VideoContext.m_VideoPlayerDelegate.window makeKeyAndVisible];
    //g_VideoContext.m_VideoPlayerDelegate.window.hidden = false;
    
    NSBundle* mainBundle = [NSBundle mainBundle];
    if(mainBundle == NULL) {
        dmLogInfo("mainBundle is null!");
        return dmExtension::RESULT_OK;
    } 
    
    NSString* nsURI = [NSString stringWithUTF8String:uri];
    NSString* file = [nsURI stringByDeletingPathExtension];
    NSString* ext = [nsURI pathExtension];
    NSString* resourcePath = [NSString stringWithFormat:@"%@%@", @"assets/", file];
    dmLogInfo("file: '%s', ext: '%s', resourcePath: '%s'", [file UTF8String], [ext UTF8String], [resourcePath UTF8String]);

    NSString* path = [mainBundle pathForResource:resourcePath ofType:ext];
    if(path == NULL) {
        dmLogInfo("path is null!");
        return dmExtension::RESULT_OK;
    }
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath: path];
    if(url == NULL) {
        dmLogInfo("url is null!");
        return dmExtension::RESULT_OK;
    }
    
    [g_VideoContext.m_VideoPlayerDelegate.viewController PrepareVideoPlayer:url];



    // ------------------------------------------------------------------------



    /*if (jvideo) {
        ++g_VideoContext.m_NumVideos;
        SDarwinVideoInfo& info = g_VideoContext.m_Videos[id];
        info.m_Video = jvideo;
        info.m_Callback = *cb;
        return id;
    }*/
    return -1;

}

-(void) Destroy: (int)video {
    DBGFNLOG;
}

-(void) Show: (int)video {
    DBGFNLOG;
}

-(void) Hide: (int)video {
    DBGFNLOG;
}

-(void) Start: (int)video {
    DBGFNLOG;
}

-(void) Stop: (int)video {
    DBGFNLOG;
}

-(void) Pause: (int)video {
    DBGFNLOG;
}

-(void) SetVisible: (int)video isVisible:(int)visible {
    DBGFNLOG;
}

-(dmVideoPlayer::LuaCallback) getCallback: (int)video {
    DBGFNLOG;

}

@end


// ----------------------------------------------------------------------------
// 
// ----------------------------------------------------------------------------



int dmVideoPlayer::Create(const char* uri, dmVideoPlayer::LuaCallback* cb) {
    dmLogInfo("dmVideoPlayer::CreateWithUri() '%s'", uri);

    if (g_VideoContext.m_NumVideos >= MAX_NUM_VIDEOS) {
        dmLogError("Max number of videos opened: %d", MAX_NUM_VIDEOS);
        return -1;
    }
    int id = g_VideoContext.m_NumVideos;



    // ------------------------------------------------------------------------



    //[g_VideoContext.m_VideoPlayerDelegate.window makeKeyAndVisible];
    //g_VideoContext.m_VideoPlayerDelegate.window.hidden = false;
    
    NSBundle* mainBundle = [NSBundle mainBundle];
    if(mainBundle == NULL) {
        dmLogInfo("mainBundle is null!");
        return dmExtension::RESULT_OK;
    } 
    
    NSString* nsURI = [NSString stringWithUTF8String:uri];
    NSString* file = [nsURI stringByDeletingPathExtension];
    NSString* ext = [nsURI pathExtension];
    NSString* resourcePath = [NSString stringWithFormat:@"%@%@", @"assets/", file];
    dmLogInfo("file: '%s', ext: '%s', resourcePath: '%s'", [file UTF8String], [ext UTF8String], [resourcePath UTF8String]);

    NSString* path = [mainBundle pathForResource:resourcePath ofType:ext];
    if(path == NULL) {
        dmLogInfo("path is null!");
        return dmExtension::RESULT_OK;
    }
    
    NSURL* url = [[NSURL alloc] initFileURLWithPath: path];
    if(url == NULL) {
        dmLogInfo("url is null!");
        return dmExtension::RESULT_OK;
    }
    
    [g_VideoContext.m_VideoPlayerDelegate.viewController PrepareVideoPlayer:url];



    // ------------------------------------------------------------------------



    /*if (jvideo) {
        ++g_VideoContext.m_NumVideos;
        SDarwinVideoInfo& info = g_VideoContext.m_Videos[id];
        info.m_Video = jvideo;
        info.m_Callback = *cb;
        return id;
    }*/
    return -1;
}

void dmVideoPlayer::Destroy(int video) {
    DBGFNLOG;
    dmVideoPlayer::ClearCommandQueueFromID(video, g_VideoContext.m_CmdQueue.Size(), &g_VideoContext.m_CmdQueue[0]);
    SDarwinVideoInfo& info = g_VideoContext.m_Videos[video];
    dmVideoPlayer::UnregisterCallback(&info.m_Callback);
    //info.m_Video = 0;
    --g_VideoContext.m_NumVideos;
}

void dmVideoPlayer::Show(int video) {
    DBGFNLOG;
    //g_VideoContext.m_VideoPlayerDelegate.window.hidden = false;
    [g_VideoContext.m_VideoPlayerDelegate.viewController Show];
}

void dmVideoPlayer::Hide(int video) {
    DBGFNLOG;
    //g_VideoContext.m_VideoPlayerDelegate.window.hidden = true;
    [g_VideoContext.m_VideoPlayerDelegate.viewController Hide];
}

void dmVideoPlayer::Start(int video) {
    DBGFNLOG;
    Show(0);
    [g_VideoContext.m_VideoPlayerDelegate.viewController Play];
}

void dmVideoPlayer::Stop(int video) {
    DBGFNLOG;
}

void dmVideoPlayer::Pause(int video) {
    DBGFNLOG;
}

void dmVideoPlayer::SetVisible(int video, int visible) {
    DBGFNLOG;
    if(visible == 0) {
        Hide(video);
    } else {
        Show(video);
    }
}

#endif
