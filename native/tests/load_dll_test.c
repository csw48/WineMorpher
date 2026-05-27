#include <windows.h>
#include <stdio.h>

int main(void) {
    printf("Diagnostic: Loading mods/dinput8.dll...\n");
    HMODULE mod = LoadLibraryA("mods/dinput8.dll");
    if (!mod) {
        printf("FAILED: error code %lu\n", GetLastError());
        return 1;
    }
    printf("SUCCESS!\n");
    FreeLibrary(mod);
    return 0;
}
