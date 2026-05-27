#pragma once
#include <windows.h>

void Logger_Init(HMODULE module);
void Log(const char* fmt, ...);
const char* Logger_DllDir(void);
