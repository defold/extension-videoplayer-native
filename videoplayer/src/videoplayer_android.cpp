#if defined(DM_PLATFORM_ANDROID)

#include "videoplayer_private.h"

#define MOVIE_CLASS_NAME Movie
#define MOVIE_JAVA_CLASS_NAME "Lcom/defold/android/videoplayer/Movie;"

struct SAndroidVideoInfo
{
    dmVideoPlayer::LuaCallback  m_Callback;
    jobject                     m_Video;
};

struct SVideoPlayerContext
{
    jobject   m_Activity;
    jclass    m_Class;

    jmethodID m_CreateFn;
    jmethodID m_DestroyFn;
    jmethodID m_StartFn;
    jmethodID m_StopFn;
    jmethodID m_PauseFn;
    jmethodID m_SetVisibleFn;

    int                 m_NumVideos;
    SAndroidVideoInfo   m_Videos[dmVideoPlayer::MAX_NUM_VIDEOS];

    dmArray<dmVideoPlayer::Command>    m_CmdQueue; // TODO: Create mutex to protect the queue
};

SVideoPlayerContext g_VideoContext;

static JNIEnv* Attach()
{
    JNIEnv* env;
    dmGraphics::GetNativeAndroidJavaVM()->AttachCurrentThread(&env, NULL);
    return env;
}

static jclass GetClass(JNIEnv* env, const char* classname)
{
    jclass activity_class = env->FindClass("android/app/NativeActivity");
    jmethodID get_class_loader = env->GetMethodID(activity_class, "getClassLoader", "()Ljava/lang/ClassLoader;");
    jobject cls = env->CallObjectMethod(dmGraphics::GetNativeAndroidActivity(), get_class_loader);
    jclass class_loader = env->FindClass("java/lang/ClassLoader");
    jmethodID find_class = env->GetMethodID(class_loader, "loadClass", "(Ljava/lang/String;)Ljava/lang/Class;");

    jstring str_class_name = env->NewStringUTF(classname);
    jclass outcls = (jclass)env->CallObjectMethod(cls, find_class, str_class_name);
    env->DeleteLocalRef(str_class_name);
    return outcls;
}

struct AttachScope
{
    AttachScope() : env(Attach()) {}
    ~AttachScope() { dmGraphics::GetNativeAndroidJavaVM()->DetachCurrentThread(); }
    JNIEnv* env;
};

static void QueueCommand(dmVideoPlayer::Command* cmd)
{
    // TODO: mutex lock!
    if (g_VideoContext.m_CmdQueue.Full())
    {
        g_VideoContext.m_CmdQueue.OffsetCapacity(8);
    }
    g_VideoContext.m_CmdQueue.Push(*cmd);
}

static void ClearCommandQueue()
{
    // TODO: mutex lock!
    g_VideoContext.m_CmdQueue.SetSize(0);
}


#ifdef __cplusplus
extern "C" {
#endif

    JNIEXPORT void JNICALL Java_com_defold_android_videoplayer_Movie_videoIsReady(JNIEnv* env, jobject video, jint id, jint width, jint height)
    {
        dmLogWarning("%s:%d:", __FUNCTION__, __LINE__);
        assert(id >= 0 && id < g_VideoContext.m_NumVideos);

        SAndroidVideoInfo* info = &g_VideoContext.m_Videos[id];

        dmVideoPlayer::Command cmd;
        memset(&cmd, 0, sizeof(cmd));
        cmd.m_Type = dmVideoPlayer::CMD_PREPARE_OK;
        cmd.m_ID = id;
        cmd.m_Width = width;
        cmd.m_Height = height;
        cmd.m_Callback = info->m_Callback;
        QueueCommand(&cmd);
    }

    JNIEXPORT void JNICALL Java_com_defold_android_videoplayer_Movie_videoIsFinished(JNIEnv* env, jobject video, jint id)
    {
        dmLogWarning("%s:%d:", __FUNCTION__, __LINE__);
        assert(id >= 0 && id < g_VideoContext.m_NumVideos);

        SAndroidVideoInfo* info = &g_VideoContext.m_Videos[id];

        dmVideoPlayer::Command cmd;
        memset(&cmd, 0, sizeof(cmd));
        cmd.m_Type = dmVideoPlayer::CMD_FINISHED;
        cmd.m_ID = id;
        cmd.m_Callback = info->m_Callback;
        QueueCommand(&cmd);
    }

#ifdef __cplusplus
}
#endif


int dmVideoPlayer::CreateWithUri(const char* uri, dmVideoPlayer::LuaCallback* cb)
{
    DBGFNLOG;

    if (g_VideoContext.m_NumVideos >= MAX_NUM_VIDEOS)
    {
        dmLogError("Max number of videos opened: %d", MAX_NUM_VIDEOS);
        return -1;
    }

    int id = g_VideoContext.m_NumVideos;

    AttachScope scope;
    jstring juri = scope.env->NewStringUTF(uri);
    jobject jvideo = scope.env->CallStaticObjectMethod(g_VideoContext.m_Class, g_VideoContext.m_CreateFn, dmGraphics::GetNativeAndroidActivity(), juri, id);
    jvideo = (jobject)scope.env->NewGlobalRef(jvideo);
    scope.env->DeleteLocalRef(juri);
    if (jvideo)
    {
        ++g_VideoContext.m_NumVideos;
        SAndroidVideoInfo& info = g_VideoContext.m_Videos[id];
        info.m_Video = jvideo;
        info.m_Callback = *cb;
        return id;
    }
    return -1;
}

void dmVideoPlayer::Destroy(int video)
{
    DBGFNLOG;
    // TODO: mutex lock!
    if(g_VideoContext.m_CmdQueue.Size() > 0) {
        dmVideoPlayer::ClearCommandQueueFromID(video, g_VideoContext.m_CmdQueue.Size(), &g_VideoContext.m_CmdQueue[0]);
    }

    AttachScope scope;
    SAndroidVideoInfo& info = g_VideoContext.m_Videos[video];
    scope.env->CallStaticVoidMethod(g_VideoContext.m_Class, g_VideoContext.m_DestroyFn, info.m_Video);
    scope.env->DeleteGlobalRef(info.m_Video);
    dmVideoPlayer::UnregisterCallback(&info.m_Callback);
    info.m_Video = 0;
	--g_VideoContext.m_NumVideos;
}

void dmVideoPlayer::SetVisible(int video, int visible)
{
    DBGFNLOG;
    AttachScope scope;
    SAndroidVideoInfo& info = g_VideoContext.m_Videos[video];
    scope.env->CallStaticVoidMethod(g_VideoContext.m_Class, g_VideoContext.m_SetVisibleFn, info.m_Video, visible);
}

void dmVideoPlayer::Start(int video)
{
    DBGFNLOG;
    AttachScope scope;
    SAndroidVideoInfo& info = g_VideoContext.m_Videos[video];
    scope.env->CallStaticVoidMethod(g_VideoContext.m_Class, g_VideoContext.m_StartFn, info.m_Video);
}

void dmVideoPlayer::Stop(int video)
{
    DBGFNLOG;
    AttachScope scope;
    SAndroidVideoInfo& info = g_VideoContext.m_Videos[video];
    scope.env->CallStaticVoidMethod(g_VideoContext.m_Class, g_VideoContext.m_StopFn, info.m_Video);
}

void dmVideoPlayer::Pause(int video)
{
    DBGFNLOG;
    AttachScope scope;
    SAndroidVideoInfo& info = g_VideoContext.m_Videos[video];
    scope.env->CallStaticVoidMethod(g_VideoContext.m_Class, g_VideoContext.m_PauseFn, info.m_Video);
}


dmExtension::Result dmVideoPlayer::Init(dmExtension::Params* params)
{
    DBGFNLOG;
    AttachScope scope;
    JNIEnv* env = scope.env;
    jclass cls                          = GetClass(env, "com.defold.android.videoplayer.VideoplayerExtension");
    g_VideoContext.m_Activity    = dmGraphics::GetNativeAndroidActivity();
    g_VideoContext.m_Class       = (jclass)env->NewGlobalRef(cls);

    // TODO: Skip the VideoPlayer class altogether, and create/invoke the Movie class directly
    g_VideoContext.m_CreateFn    = env->GetStaticMethodID(cls, "Create", "(Landroid/content/Context;Ljava/lang/String;I)" MOVIE_JAVA_CLASS_NAME);
    g_VideoContext.m_DestroyFn   = env->GetStaticMethodID(cls, "Destroy", "(" MOVIE_JAVA_CLASS_NAME ")V");
    g_VideoContext.m_SetVisibleFn= env->GetStaticMethodID(cls, "SetVisible", "(" MOVIE_JAVA_CLASS_NAME "I)V");
    g_VideoContext.m_StartFn     = env->GetStaticMethodID(cls, "Start", "(" MOVIE_JAVA_CLASS_NAME ")V");
    g_VideoContext.m_StopFn      = env->GetStaticMethodID(cls, "Stop", "(" MOVIE_JAVA_CLASS_NAME ")V");
    g_VideoContext.m_PauseFn     = env->GetStaticMethodID(cls, "Pause", "(" MOVIE_JAVA_CLASS_NAME ")V");

    g_VideoContext.m_NumVideos   = 0;

    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params)
{
    while(g_VideoContext.m_NumVideos > 0)
    {
        dmVideoPlayer::Destroy(0);
    }
    AttachScope scope;
    scope.env->DeleteGlobalRef(g_VideoContext.m_Class);
    ClearCommandQueue();
    return dmExtension::RESULT_OK;;
}

dmExtension::Result dmVideoPlayer::Update(dmExtension::Params* params)
{
    if (g_VideoContext.m_CmdQueue.Empty())
        return dmExtension::RESULT_OK; // avoid a lock (~300us on iPhone 4s)
    //dmMutex::ScopedLock lk(g_VideoContext.m_Mutex);
    dmVideoPlayer::ProcessCommandQueue(g_VideoContext.m_CmdQueue.Size(), &g_VideoContext.m_CmdQueue[0]);
    g_VideoContext.m_CmdQueue.SetSize(0);
    return dmExtension::RESULT_OK;
}

#endif
