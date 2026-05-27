#include "Logger.h"

static char g_dllDir[MAX_PATH] = {0};
static char g_logPath[MAX_PATH] = {0};

static char* my_strrchr(const char* str, int ch) {
    char* last = NULL;
    while (*str) {
        if (*str == (char)ch) {
            last = (char*)str;
        }
        str++;
    }
    return last;
}

static void CopyDirectoryFromPath(char* path) {
    char* slash1 = my_strrchr(path, '\\');
    char* slash2 = my_strrchr(path, '/');
    char* slash = slash1 > slash2 ? slash1 : slash2;
    if (slash) {
        *slash = '\0';
    }
}

void Logger_Init(HMODULE module) {
    HANDLE debugFile = CreateFileA("C:\\winemorpher_debug.log", GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (debugFile != INVALID_HANDLE_VALUE) {
        char buf[1024];
        char modulePath[MAX_PATH] = {0};
        DWORD res = GetModuleFileNameA(module, modulePath, MAX_PATH);
        wsprintfA(buf, "Logger_Init started: module=%p, GetModuleFileNameA res=%lu, path=%s\r\n", module, res, modulePath);
        DWORD written = 0;
        DWORD len = 0;
        while (buf[len] != '\0') len++;
        WriteFile(debugFile, buf, len, &written, NULL);
        CloseHandle(debugFile);
    }

    char modulePath[MAX_PATH] = {0};
    if (!GetModuleFileNameA(module, modulePath, MAX_PATH)) {
        GetCurrentDirectoryA(MAX_PATH, modulePath);
    }

    unsigned i = 0;
    for (; i < MAX_PATH - 1 && modulePath[i] != '\0'; ++i) {
        g_dllDir[i] = modulePath[i];
    }
    g_dllDir[i] = '\0';
    CopyDirectoryFromPath(g_dllDir);

    char separator = '\\';
    if (my_strrchr(g_dllDir, '/')) {
        separator = '/';
    }

    char logDir[MAX_PATH] = {0};
    wsprintfA(logDir, "%s%cWineMorpher_logs", g_dllDir, separator);
    CreateDirectoryA(logDir, NULL);

    wsprintfA(g_logPath, "%s%cwinemorpher.log", logDir, separator);

    HANDLE file = CreateFileA(g_logPath, GENERIC_WRITE, FILE_SHARE_READ, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (file != INVALID_HANDLE_VALUE) {
        const char* msg = "WineMorpher log started\r\n";
        DWORD written = 0;
        DWORD len = 0;
        while (msg[len] != '\0') len++;
        WriteFile(file, msg, len, &written, NULL);
        CloseHandle(file);
    }
}

void Log(const char* fmt, ...) {
    if (g_logPath[0] == '\0') {
        return;
    }

    SYSTEMTIME st;
    GetLocalTime(&st);

    HANDLE file = CreateFileA(g_logPath, GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (file == INVALID_HANDLE_VALUE) {
        return;
    }

    SetFilePointer(file, 0, NULL, FILE_END);

    char timeBuf[32];
    wsprintfA(timeBuf, "[%02u:%02u:%02u] ", st.wHour, st.wMinute, st.wSecond);
    DWORD written = 0;
    DWORD timeLen = 0;
    while (timeBuf[timeLen] != '\0') timeLen++;
    WriteFile(file, timeBuf, timeLen, &written, NULL);

    char msgBuf[1024];
    va_list args;
    va_start(args, fmt);
    int msgLen = wvsprintfA(msgBuf, fmt, args);
    va_end(args);

    if (msgLen > 0) {
        WriteFile(file, msgBuf, msgLen, &written, NULL);
    }

    const char* newline = "\r\n";
    WriteFile(file, newline, 2, &written, NULL);

    CloseHandle(file);
}

const char* Logger_DllDir(void) {
    return g_dllDir;
}
