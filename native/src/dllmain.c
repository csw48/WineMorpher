#include "Command.h"
#include "Logger.h"
#include "WoW335.h"

#include <windows.h>

static HMODULE g_module = NULL;
static HWND g_wowWindow = NULL;
static UINT_PTR g_timerId = 0x574D; // WM
static volatile BOOL g_running = TRUE;
static BOOL g_luaAnnounced = FALSE;

static BOOL IsWindowOwnedByCurrentProcess(HWND hwnd) {
    if (!hwnd) {
        return FALSE;
    }
    DWORD pid = 0;
    GetWindowThreadProcessId(hwnd, &pid);
    return pid == GetCurrentProcessId();
}

static HWND FindWowWindow(void) {
    HWND hwnd = FindWindowA("GxWindowClass", NULL);
    if (IsWindowOwnedByCurrentProcess(hwnd)) return hwnd;

    hwnd = FindWindowA("GxWindowClassD3d", NULL);
    if (IsWindowOwnedByCurrentProcess(hwnd)) return hwnd;

    return NULL;
}

static void HandleCommand(const char* raw) {
    const Command command = ParseCommand(raw ? raw : "");
    char status[256] = {0};

    switch (command.type) {
    case COMMAND_TYPE_STATUS:
        wsprintfA(status, "DLL loaded; active display polling ready");
        WoW335_SetLuaGlobal("WINEMORPHER_DLL_LOADED = 'TRUE'");
        WoW335_SetLuaGlobal("TRANSMORPHER_DLL_LOADED = 'TRUE'");
        {
            char script[400] = {0};
            wsprintfA(script, "WINEMORPHER_STATUS = '%s'", status);
            WoW335_SetLuaGlobal(script);
        }
        Log("STATUS requested");
        break;
    case COMMAND_TYPE_DISPLAY:
        WoW335_ApplyDisplay(command.value, status, sizeof(status));
        break;
    case COMMAND_TYPE_RESET:
        WoW335_ResetDisplay(status, sizeof(status));
        break;
    case COMMAND_TYPE_MOUNT:
        WoW335_ApplyMount(command.value, status, sizeof(status));
        break;
    case COMMAND_TYPE_SCALE:
        WoW335_ApplyScale(command.floatValue, status, sizeof(status));
        break;
    case COMMAND_TYPE_HPET_MORPH:
        WoW335_ApplyPetMorph(command.value, status, sizeof(status));
        break;
    case COMMAND_TYPE_HPET_SCALE:
        WoW335_ApplyPetScale(command.floatValue, status, sizeof(status));
        break;
    case COMMAND_TYPE_HPET_RESET:
        WoW335_ApplyPetMorph(0, status, sizeof(status));
        WoW335_ApplyPetScale(0.0f, status, sizeof(status));
        break;
    case COMMAND_TYPE_ITEM:
        WoW335_ApplyItem(command.value, command.extraValue, status, sizeof(status));
        break;
    case COMMAND_TYPE_ENCHANT_MH:
        WoW335_ApplyEnchantMH(command.value, status, sizeof(status));
        break;
    case COMMAND_TYPE_ENCHANT_OH:
        WoW335_ApplyEnchantOH(command.value, status, sizeof(status));
        break;
    case COMMAND_TYPE_ENCHANT_RESET:
        WoW335_ApplyEnchantMH(0, status, sizeof(status));
        WoW335_ApplyEnchantOH(0, status, sizeof(status));
        break;
    case COMMAND_TYPE_TITLE:
        WoW335_ApplyTitle(command.value, status, sizeof(status));
        break;
    case COMMAND_TYPE_RESET_ALL:
        WoW335_ResetAll(status, sizeof(status));
        break;
    case COMMAND_TYPE_INVALID:
    default:
        Log("Invalid command ignored: %s", raw ? raw : "");
        break;
    }
}

static void SplitAndHandleCommands(char* cmdString) {
    char* p = cmdString;
    char* start = p;
    while (*p) {
        if (*p == '|') {
            *p = '\0';
            if (*start != '\0') {
                HandleCommand(start);
            }
            start = p + 1;
        }
        p++;
    }
    if (*start != '\0') {
        HandleCommand(start);
    }
}

static void CALLBACK TimerProc(HWND hwnd, UINT uMsg, UINT_PTR idEvent, DWORD dwTime) {
    (void)hwnd; (void)uMsg; (void)idEvent; (void)dwTime;
    if (!g_running) {
        return;
    }

    if (!g_luaAnnounced && WoW335_IsLuaReady()) {
        WoW335_SetLuaGlobal("WINEMORPHER_DLL_LOADED = 'TRUE'");
        WoW335_SetLuaGlobal("TRANSMORPHER_DLL_LOADED = 'TRUE'");
        WoW335_SetLuaGlobal("WINEMORPHER_STATUS = 'DLL loaded and ready'");
        g_luaAnnounced = TRUE;
        Log("Lua bridge ready");
    }

    char command[4096] = {0};
    if (WoW335_ConsumeCommand(command, sizeof(command))) {
        Log("Command string received: %s", command);
        SplitAndHandleCommands(command);
    }

    WoW335_ReapplyActiveDisplay();
}

static DWORD WINAPI WorkerThread(LPVOID param) {
    (void)param;
    Log("Worker thread started");
    WoW335_Init();

    for (int waited = 0; g_running && waited < 60000; waited += 250) {
        g_wowWindow = FindWowWindow();
        if (g_wowWindow) {
            break;
        }
        Sleep(250);
    }

    if (!g_wowWindow) {
        Log("No WoW window found; DLL loaded but timer not installed");
        return 0;
    }

    Log("Found WoW window 0x%p", g_wowWindow);
    g_timerId = SetTimer(g_wowWindow, g_timerId, 100, TimerProc);
    if (!g_timerId) {
        Log("ERROR: SetTimer failed, err=%lu", GetLastError());
    } else {
        Log("Timer installed");
    }

    while (g_running) {
        Sleep(1000);
    }
    return 0;
}
BOOL WINAPI DllMain(HINSTANCE instance, DWORD reason, LPVOID reserved) {
    (void)reserved;

    if (reason == DLL_PROCESS_ATTACH) {
        g_module = instance;
        DisableThreadLibraryCalls(instance);
        Logger_Init(instance);
        Log("WineMorpher winemorpher.dll attached");
        HANDLE thread = CreateThread(NULL, 0, WorkerThread, NULL, 0, NULL);
        if (thread) {
            CloseHandle(thread);
        } else {
            Log("ERROR: CreateThread failed, err=%lu", GetLastError());
        }
    } else if (reason == DLL_PROCESS_DETACH) {
        g_running = FALSE;
        if (g_wowWindow && g_timerId) {
            KillTimer(g_wowWindow, g_timerId);
        }
        Log("WineMorpher detached");
    }
    return TRUE;
}
