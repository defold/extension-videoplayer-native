#if defined(DM_PLATFORM_WINDOWS)

#include "videoplayer_private.h"

#include <dmsdk/dlib/array.h>
#include <dmsdk/graphics/graphics_native.h>

#if defined(WINVER) && (WINVER < 0x0602)
#undef WINVER
#define WINVER 0x0602
#elif !defined(WINVER)
#define WINVER 0x0602
#endif

#if defined(_WIN32_WINNT) && (_WIN32_WINNT < 0x0602)
#undef _WIN32_WINNT
#define _WIN32_WINNT 0x0602
#elif !defined(_WIN32_WINNT)
#define _WIN32_WINNT 0x0602
#endif

#include <windows.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfmediaengine.h>
#include <mferror.h>

#include <stdio.h>
#include <string.h>

namespace dmVideoPlayer
{

static const uint32_t MAX_PATH_LEN = 1024;
static const char* VIDEO_WINDOW_CLASS = "DefoldVideoPlayerWindow";

struct WindowsVideoContext;

class MediaEngineNotify : public IMFMediaEngineNotify
{
public:
    explicit MediaEngineNotify(WindowsVideoContext* context)
        : m_Context(context)
        , m_RefCount(1)
    {
    }

    STDMETHODIMP QueryInterface(REFIID riid, void** ppv)
    {
        if (!ppv)
            return E_POINTER;

        if (riid == __uuidof(IMFMediaEngineNotify) || riid == __uuidof(IUnknown))
        {
            *ppv = static_cast<IMFMediaEngineNotify*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = 0;
        return E_NOINTERFACE;
    }

    STDMETHODIMP_(ULONG) AddRef()
    {
        return (ULONG)InterlockedIncrement(&m_RefCount);
    }

    STDMETHODIMP_(ULONG) Release()
    {
        ULONG count = (ULONG)InterlockedDecrement(&m_RefCount);
        if (count == 0)
        {
            delete this;
        }
        return count;
    }

    STDMETHODIMP EventNotify(DWORD meEvent, DWORD_PTR param1, DWORD param2);

private:
    WindowsVideoContext* m_Context;
    LONG m_RefCount;
};

struct WindowsVideoContext
{
    int                     m_Handle;
    LuaCallback             m_Callback;
    dmArray<Command>        m_CmdQueue;
    CRITICAL_SECTION        m_CmdMutex;

    IMFMediaEngine*         m_Engine;
    IMFMediaEngineClassFactory* m_Factory;
    IMFAttributes*          m_Attributes;
    MediaEngineNotify*      m_Notify;

    HWND                    m_ParentWindow;
    HWND                    m_VideoWindow;
    uint32_t                m_WindowWidth;
    uint32_t                m_WindowHeight;
    bool                    m_Visible;
    bool                    m_VisibleRequested;
    bool                    m_ShowOnTimeUpdate;
    bool                    m_StartIssued;
    bool                    m_ReadySent;

    bool                    m_ComInitialized;
    bool                    m_MfStarted;
};

static WindowsVideoContext g_Context;
static bool g_WindowClassRegistered = false;

static LRESULT CALLBACK VideoWindowProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam)
{
    if (msg == WM_ERASEBKGND)
    {
        HDC hdc = (HDC)wparam;
        RECT rect;
        GetClientRect(hwnd, &rect);
        HBRUSH brush = (HBRUSH)GetStockObject(BLACK_BRUSH);
        FillRect(hdc, &rect, brush);
        return 1;
    }
    return DefWindowProc(hwnd, msg, wparam, lparam);
}

static void SafeRelease(IUnknown* ptr)
{
    if (ptr)
        ptr->Release();
}

static bool HasScheme(const char* uri)
{
    return strstr(uri, "://") != 0;
}

static bool FileExists(const char* path)
{
    DWORD attrs = GetFileAttributesA(path);
    return attrs != INVALID_FILE_ATTRIBUTES && !(attrs & FILE_ATTRIBUTE_DIRECTORY);
}

static void GetDirname(const char* path, char* out, uint32_t out_len)
{
    if (!path || !out || out_len == 0)
        return;

    size_t len = strlen(path);
    if (len >= out_len)
        len = out_len - 1;

    memcpy(out, path, len);
    out[len] = '\0';

    char* last_slash = strrchr(out, '/');
    char* last_backslash = strrchr(out, '\\');
    char* last_sep = last_slash > last_backslash ? last_slash : last_backslash;
    if (last_sep)
    {
        *last_sep = '\0';
    }
}

static void JoinPath(const char* dir, const char* file, char* out, uint32_t out_len)
{
    if (!dir || !file || !out || out_len == 0)
        return;

    size_t dir_len = strlen(dir);
    if (dir_len > 0 && (dir[dir_len - 1] == '/' || dir[dir_len - 1] == '\\'))
    {
        snprintf(out, out_len, "%s%s", dir, file);
    }
    else
    {
        snprintf(out, out_len, "%s\\%s", dir, file);
    }
}

static const char* ResolveUri(const char* uri, char* resolved, uint32_t resolved_len)
{
    if (HasScheme(uri))
        return uri;

    if (FileExists(uri))
        return uri;

    char app_path[MAX_PATH_LEN] = {0};
    DWORD length = GetModuleFileNameA(NULL, app_path, (DWORD)sizeof(app_path));
    if (length > 0 && length < sizeof(app_path))
    {
        char dir_path[MAX_PATH_LEN] = {0};
        GetDirname(app_path, dir_path, sizeof(dir_path));
        JoinPath(dir_path, uri, resolved, resolved_len);
        if (FileExists(resolved))
            return resolved;
    }

    return uri;
}

static bool Utf8ToWide(const char* text, wchar_t* out, int out_len)
{
    int len = MultiByteToWideChar(CP_UTF8, 0, text, -1, out, out_len);
    if (len == 0 && GetLastError() == ERROR_INVALID_PARAMETER)
    {
        len = MultiByteToWideChar(CP_ACP, 0, text, -1, out, out_len);
    }
    return len > 0;
}

static void QueueCommand(Command* cmd)
{
    EnterCriticalSection(&g_Context.m_CmdMutex);
    if (g_Context.m_CmdQueue.Full())
    {
        g_Context.m_CmdQueue.OffsetCapacity(4);
    }
    g_Context.m_CmdQueue.Push(*cmd);
    LeaveCriticalSection(&g_Context.m_CmdMutex);
}

static void ClearCommandQueue()
{
    EnterCriticalSection(&g_Context.m_CmdMutex);
    g_Context.m_CmdQueue.SetSize(0);
    LeaveCriticalSection(&g_Context.m_CmdMutex);
}

static void QueuePrepareOk()
{
    if (g_Context.m_ReadySent)
        return;

    DWORD width = 0;
    DWORD height = 0;
    if (g_Context.m_Engine)
    {
        g_Context.m_Engine->GetNativeVideoSize(&width, &height);
    }

    Command cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.m_Type = CMD_PREPARE_OK;
    cmd.m_ID = g_Context.m_Handle;
    cmd.m_Width = (int)width;
    cmd.m_Height = (int)height;
    cmd.m_Callback = g_Context.m_Callback;
    QueueCommand(&cmd);
    g_Context.m_ReadySent = true;
}

static void QueueFinished()
{
    Command cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.m_Type = CMD_FINISHED;
    cmd.m_ID = g_Context.m_Handle;
    cmd.m_Callback = g_Context.m_Callback;
    QueueCommand(&cmd);
}

static void QueueFailed()
{
    Command cmd;
    memset(&cmd, 0, sizeof(cmd));
    cmd.m_Type = CMD_PREPARE_ERROR;
    cmd.m_ID = g_Context.m_Handle;
    cmd.m_Callback = g_Context.m_Callback;
    QueueCommand(&cmd);
}

STDMETHODIMP MediaEngineNotify::EventNotify(DWORD meEvent, DWORD_PTR param1, DWORD param2)
{
    (void)param1;
    (void)param2;

    if (!m_Context || m_Context->m_Handle < 0)
        return S_OK;

    switch (meEvent)
    {
        case MF_MEDIA_ENGINE_EVENT_LOADEDMETADATA:
        case MF_MEDIA_ENGINE_EVENT_CANPLAY:
            QueuePrepareOk();
            break;
        case MF_MEDIA_ENGINE_EVENT_TIMEUPDATE:
            if (g_Context.m_ShowOnTimeUpdate && g_Context.m_VideoWindow && g_Context.m_Engine)
            {
                double time = g_Context.m_Engine->GetCurrentTime();
                if (time > 0.01)
                {
                    g_Context.m_Visible = true;
                    ShowWindow(g_Context.m_VideoWindow, SW_SHOW);
                    g_Context.m_ShowOnTimeUpdate = false;
                }
            }
            break;
        case MF_MEDIA_ENGINE_EVENT_ENDED:
            QueueFinished();
            break;
        case MF_MEDIA_ENGINE_EVENT_ERROR:
            QueueFailed();
            break;
        default:
            break;
    }

    return S_OK;
}

static void UpdateOverlayWindow()
{
    if (!g_Context.m_ParentWindow || !g_Context.m_VideoWindow)
        return;

    RECT rect = {0, 0, 0, 0};
    if (!GetClientRect(g_Context.m_ParentWindow, &rect))
        return;

    uint32_t width = (uint32_t)(rect.right - rect.left);
    uint32_t height = (uint32_t)(rect.bottom - rect.top);

    if (width == 0 || height == 0)
        return;

    if (width != g_Context.m_WindowWidth || height != g_Context.m_WindowHeight)
    {
        g_Context.m_WindowWidth = width;
        g_Context.m_WindowHeight = height;
        SetWindowPos(g_Context.m_VideoWindow, HWND_TOP, 0, 0,
                     (int)width, (int)height,
                     SWP_NOACTIVATE | (g_Context.m_Visible ? SWP_SHOWWINDOW : SWP_HIDEWINDOW));
    }
}

static bool EnsureVideoWindow()
{
    if (g_Context.m_VideoWindow)
        return true;

    g_Context.m_ParentWindow = dmGraphics::GetNativeWindowsHWND();
    if (!g_Context.m_ParentWindow)
    {
        dmLogError("VideoPlayer: failed to get native HWND");
        return false;
    }

    RECT rect = {0, 0, 0, 0};
    GetClientRect(g_Context.m_ParentWindow, &rect);
    g_Context.m_WindowWidth = (uint32_t)(rect.right - rect.left);
    g_Context.m_WindowHeight = (uint32_t)(rect.bottom - rect.top);

    if (!g_WindowClassRegistered)
    {
        WNDCLASSEXA wc;
        memset(&wc, 0, sizeof(wc));
        wc.cbSize = sizeof(wc);
        wc.lpfnWndProc = VideoWindowProc;
        wc.hInstance = GetModuleHandle(NULL);
        wc.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
        wc.lpszClassName = VIDEO_WINDOW_CLASS;
        if (!RegisterClassExA(&wc))
        {
            dmLogError("VideoPlayer: failed to register window class");
            return false;
        }
        g_WindowClassRegistered = true;
    }

    g_Context.m_VideoWindow = CreateWindowExA(
        0,
        VIDEO_WINDOW_CLASS,
        "",
        WS_CHILD | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
        0, 0,
        (int)g_Context.m_WindowWidth,
        (int)g_Context.m_WindowHeight,
        g_Context.m_ParentWindow,
        NULL,
        GetModuleHandle(NULL),
        NULL);

    if (!g_Context.m_VideoWindow)
    {
        dmLogError("VideoPlayer: failed to create video window");
        return false;
    }

    SetWindowPos(g_Context.m_VideoWindow, HWND_TOP, 0, 0,
                 (int)g_Context.m_WindowWidth,
                 (int)g_Context.m_WindowHeight,
                 SWP_NOACTIVATE | SWP_HIDEWINDOW);
    g_Context.m_Visible = false;
    return true;
}

static bool EnsureMediaEngine(bool play_sound)
{
    if (g_Context.m_Engine)
        return true;

    if (!EnsureVideoWindow())
        return false;

    HRESULT hr = MFCreateAttributes(&g_Context.m_Attributes, 1);
    if (FAILED(hr))
    {
        dmLogError("VideoPlayer: MFCreateAttributes failed (0x%08x)", (unsigned)hr);
        goto cleanup;
    }

    g_Context.m_Notify = new MediaEngineNotify(&g_Context);
    hr = g_Context.m_Attributes->SetUnknown(MF_MEDIA_ENGINE_CALLBACK, g_Context.m_Notify);
    if (FAILED(hr))
    {
        dmLogError("VideoPlayer: SetUnknown failed (0x%08x)", (unsigned)hr);
        goto cleanup;
    }

    hr = g_Context.m_Attributes->SetUINT64(MF_MEDIA_ENGINE_PLAYBACK_HWND, (UINT64)(UINT_PTR)g_Context.m_VideoWindow);
    if (FAILED(hr))
    {
        dmLogError("VideoPlayer: Set playback HWND failed (0x%08x)", (unsigned)hr);
        goto cleanup;
    }

    hr = CoCreateInstance(CLSID_MFMediaEngineClassFactory, NULL, CLSCTX_INPROC_SERVER,
                          IID_PPV_ARGS(&g_Context.m_Factory));
    if (FAILED(hr))
    {
        dmLogError("VideoPlayer: MFMediaEngine factory failed (0x%08x)", (unsigned)hr);
        goto cleanup;
    }

    hr = g_Context.m_Factory->CreateInstance(0, g_Context.m_Attributes, &g_Context.m_Engine);
    if (FAILED(hr))
    {
        dmLogError("VideoPlayer: CreateInstance failed (0x%08x)", (unsigned)hr);
        goto cleanup;
    }

    g_Context.m_Engine->SetMuted(play_sound ? FALSE : TRUE);
    return true;

cleanup:
    if (g_Context.m_Engine)
    {
        g_Context.m_Engine->Shutdown();
    }
    SafeRelease(g_Context.m_Engine);
    SafeRelease(g_Context.m_Factory);
    SafeRelease(g_Context.m_Attributes);
    g_Context.m_Engine = 0;
    g_Context.m_Factory = 0;
    g_Context.m_Attributes = 0;
    if (g_Context.m_Notify)
    {
        g_Context.m_Notify->Release();
        g_Context.m_Notify = 0;
    }
    return false;
}

int dmVideoPlayer::CreateWithUri(const char* uri, const VideoPlayerCreateInfo& createInfo)
{
    DBGFNLOG;

    if (g_Context.m_Handle >= 0)
    {
        dmLogError("Max number of videos opened: %d", MAX_NUM_VIDEOS);
        return -1;
    }

    if (!g_Context.m_MfStarted)
    {
        dmLogError("VideoPlayer: Media Foundation not initialized");
        return -1;
    }

    if (!EnsureMediaEngine(createInfo.m_PlaySound))
        return -1;

    char resolved[MAX_PATH_LEN] = {0};
    const char* source = ResolveUri(uri, resolved, sizeof(resolved));

    wchar_t wide_source[MAX_PATH_LEN] = {0};
    if (!Utf8ToWide(source, wide_source, MAX_PATH_LEN))
    {
        dmLogError("VideoPlayer: failed to convert URI to wide string");
        return -1;
    }

    BSTR bstr = SysAllocString(wide_source);
    if (!bstr)
    {
        dmLogError("VideoPlayer: failed to allocate URI string");
        return -1;
    }

    HRESULT hr = g_Context.m_Engine->SetSource(bstr);
    SysFreeString(bstr);

    if (FAILED(hr))
    {
        dmLogError("VideoPlayer: SetSource failed (0x%08x)", (unsigned)hr);
        return -1;
    }

    g_Context.m_Handle = 0;
    g_Context.m_Callback = *createInfo.m_Callback;
    g_Context.m_VisibleRequested = true;
    g_Context.m_ShowOnTimeUpdate = false;
    g_Context.m_StartIssued = false;
    g_Context.m_ReadySent = false;
    return g_Context.m_Handle;
}

void dmVideoPlayer::Destroy(int video)
{
    DBGFNLOG;
    if (video != g_Context.m_Handle)
        return;

    EnterCriticalSection(&g_Context.m_CmdMutex);
    if (g_Context.m_CmdQueue.Size() > 0)
    {
        dmVideoPlayer::ClearCommandQueueFromID(video, g_Context.m_CmdQueue.Size(), &g_Context.m_CmdQueue[0]);
    }
    LeaveCriticalSection(&g_Context.m_CmdMutex);

    if (g_Context.m_Engine)
    {
        g_Context.m_Engine->Pause();
        g_Context.m_Engine->Shutdown();
    }

    SafeRelease(g_Context.m_Engine);
    SafeRelease(g_Context.m_Factory);
    SafeRelease(g_Context.m_Attributes);

    g_Context.m_Engine = 0;
    g_Context.m_Factory = 0;
    g_Context.m_Attributes = 0;

    if (g_Context.m_VideoWindow)
    {
        DestroyWindow(g_Context.m_VideoWindow);
        g_Context.m_VideoWindow = 0;
    }

    if (g_Context.m_Notify)
    {
        g_Context.m_Notify->Release();
        g_Context.m_Notify = 0;
    }

    dmVideoPlayer::UnregisterCallback(&g_Context.m_Callback);
    g_Context.m_Handle = -1;
    g_Context.m_ReadySent = false;
}

void dmVideoPlayer::SetVisible(int video, int visible)
{
    DBGFNLOG;
    if (video != g_Context.m_Handle || !g_Context.m_VideoWindow)
        return;

    g_Context.m_VisibleRequested = visible != 0;
    if (!g_Context.m_VisibleRequested)
    {
        g_Context.m_Visible = false;
        ShowWindow(g_Context.m_VideoWindow, SW_HIDE);
    }
    else if (g_Context.m_StartIssued)
    {
        g_Context.m_ShowOnTimeUpdate = true;
    }
}

void dmVideoPlayer::Start(int video)
{
    DBGFNLOG;
    if (video != g_Context.m_Handle || !g_Context.m_Engine)
        return;

    g_Context.m_StartIssued = true;
    if (g_Context.m_VisibleRequested && !g_Context.m_Visible)
    {
        g_Context.m_ShowOnTimeUpdate = true;
    }
    g_Context.m_Engine->Play();
}

void dmVideoPlayer::Stop(int video)
{
    DBGFNLOG;
    if (video != g_Context.m_Handle || !g_Context.m_Engine)
        return;

    g_Context.m_Engine->Pause();
    g_Context.m_Engine->SetCurrentTime(0.0);
}

void dmVideoPlayer::Pause(int video)
{
    DBGFNLOG;
    if (video != g_Context.m_Handle || !g_Context.m_Engine)
        return;

    g_Context.m_Engine->Pause();
}

dmExtension::Result dmVideoPlayer::Init(dmExtension::Params* params)
{
    g_Context.m_Handle = -1;
    g_Context.m_Callback.m_L = 0;
    g_Context.m_Callback.m_Callback = LUA_NOREF;
    g_Context.m_Callback.m_Self = LUA_NOREF;
    g_Context.m_CmdQueue.SetCapacity(4);
    InitializeCriticalSection(&g_Context.m_CmdMutex);

    HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
    g_Context.m_ComInitialized = (hr == S_OK || hr == S_FALSE);
    if (FAILED(hr) && hr != RPC_E_CHANGED_MODE)
    {
        dmLogError("VideoPlayer: CoInitializeEx failed (0x%08x)", (unsigned)hr);
    }

    hr = MFStartup(MF_VERSION);
    g_Context.m_MfStarted = SUCCEEDED(hr);
    if (!g_Context.m_MfStarted)
    {
        dmLogError("VideoPlayer: MFStartup failed (0x%08x)", (unsigned)hr);
    }

    g_Context.m_Engine = 0;
    g_Context.m_Factory = 0;
    g_Context.m_Attributes = 0;
    g_Context.m_Notify = 0;
    g_Context.m_ParentWindow = 0;
    g_Context.m_VideoWindow = 0;
    g_Context.m_WindowWidth = 0;
    g_Context.m_WindowHeight = 0;
    g_Context.m_Visible = false;
    g_Context.m_VisibleRequested = false;
    g_Context.m_ShowOnTimeUpdate = false;
    g_Context.m_StartIssued = false;
    g_Context.m_ReadySent = false;

    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Exit(dmExtension::Params* params)
{
    if (g_Context.m_Handle >= 0)
    {
        Destroy(g_Context.m_Handle);
    }

    ClearCommandQueue();
    DeleteCriticalSection(&g_Context.m_CmdMutex);

    if (g_Context.m_MfStarted)
    {
        MFShutdown();
        g_Context.m_MfStarted = false;
    }

    if (g_Context.m_ComInitialized)
    {
        CoUninitialize();
        g_Context.m_ComInitialized = false;
    }

    return dmExtension::RESULT_OK;
}

dmExtension::Result dmVideoPlayer::Update(dmExtension::Params* params)
{
    UpdateOverlayWindow();

    EnterCriticalSection(&g_Context.m_CmdMutex);
    if (g_Context.m_CmdQueue.Empty())
    {
        LeaveCriticalSection(&g_Context.m_CmdMutex);
        return dmExtension::RESULT_OK;
    }

    ProcessCommandQueue(g_Context.m_CmdQueue.Size(), &g_Context.m_CmdQueue[0]);
    g_Context.m_CmdQueue.SetSize(0);
    LeaveCriticalSection(&g_Context.m_CmdMutex);
    return dmExtension::RESULT_OK;
}

} // namespace dmVideoPlayer

#endif
