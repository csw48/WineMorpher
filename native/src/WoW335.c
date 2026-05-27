#include "WoW335.h"
#include "Logger.h"

#define P_CLIENT_CONNECTION 0x00C79CE0
#define P_OBJECT_MGR_OFFSET 0x2ED0
#define UNIT_FIELD_DISPLAYID (0x43 * 4)
#define UNIT_FIELD_NATIVEDISPLAYID (0x44 * 4)
#define UNIT_FIELD_MOUNTDISPLAYID (0x45 * 4)
#define OBJECT_FIELD_SCALE_X (0x04 * 4)
#define PLAYER_VISIBLE_ITEM_BASE 283
#define PLAYER_CHOSEN_TITLE (0x141 * 4)
#define PLAYER_KNOWN_TITLES_BASE 0x272
#define MAIN_HAND_SLOT 16
#define OFF_HAND_SLOT 17
#define LUA_GLOBALSINDEX -10002

typedef int(__cdecl* FrameScriptExecuteFn)(const char*, const char*, int);
typedef void* (__cdecl* GetLuaStateFn)(void);
typedef void(__cdecl* LuaGetfieldFn)(void*, int, const char*);
typedef const char* (__cdecl* LuaTolstringFn)(void*, int, size_t*);
typedef void(__cdecl* LuaSettopFn)(void*, int);
typedef void(__attribute__((thiscall)) *UpdateDisplayInfoFn)(void*, int);

static FrameScriptExecuteFn g_frameScriptExecute = NULL;
static GetLuaStateFn g_getLuaState = (GetLuaStateFn)0x00817DB0;
static LuaGetfieldFn g_luaGetfield = NULL;
static LuaTolstringFn g_luaTolstring = NULL;
static LuaSettopFn g_luaSettop = NULL;
static UpdateDisplayInfoFn g_updateDisplayInfo = (UpdateDisplayInfoFn)0x0073E410;

uint32_t g_activeMount = 0;
uint64_t g_localGuid = 0;
int32_t g_activeItems[19] = {0};
uint32_t g_activeEnchantMH = 0;
uint32_t g_activeEnchantOH = 0;
uint32_t g_activeTitle = 0;
uint32_t g_activePetDisplay = 0;
float g_activePetScale = 0.0f;

static uint32_t g_activeDisplay = 0;
static uint32_t g_originalDisplay = 0;
static BOOL g_hasOriginalDisplay = FALSE;
static uint32_t g_originalItems[19] = {0};
static BOOL g_hasOriginalItem[19] = {0};
static uintptr_t g_playerObject = 0;
static uintptr_t g_playerDescriptors = 0;
static float g_activeScale = 0.0f;

// Custom helper string and memory functions to avoid standard C library dependencies
static unsigned long my_strlen(const char* s) {
    unsigned long len = 0;
    while (s[len]) len++;
    return len;
}

static void* my_memcpy(void* dest, const void* src, unsigned long n) {
    char* d = (char*)dest;
    const char* s = (const char*)src;
    for (unsigned long i = 0; i < n; ++i) {
        d[i] = s[i];
    }
    return dest;
}

static int my_memcmp(const void* s1, const void* s2, unsigned long n) {
    const unsigned char* p1 = (const unsigned char*)s1;
    const unsigned char* p2 = (const unsigned char*)s2;
    for (unsigned long i = 0; i < n; ++i) {
        if (p1[i] != p2[i]) {
            return p1[i] - p2[i];
        }
    }
    return 0;
}

static BOOL IsReadable(const void* ptr, size_t size) {
    MEMORY_BASIC_INFORMATION mbi = {0};
    if (!ptr || !VirtualQuery(ptr, &mbi, sizeof(mbi))) {
        return FALSE;
    }

    const uintptr_t start = (uintptr_t)ptr;
    const uintptr_t end = start + size;
    const uintptr_t regionEnd = (uintptr_t)mbi.BaseAddress + mbi.RegionSize;
    if (end > regionEnd || mbi.State != MEM_COMMIT) {
        return FALSE;
    }

    const DWORD protect = mbi.Protect & 0xff;
    return protect == PAGE_READONLY || protect == PAGE_READWRITE ||
           protect == PAGE_EXECUTE_READ || protect == PAGE_EXECUTE_READWRITE ||
           protect == PAGE_WRITECOPY || protect == PAGE_EXECUTE_WRITECOPY;
}

static BOOL IsWritable(void* ptr, size_t size) {
    MEMORY_BASIC_INFORMATION mbi = {0};
    if (!ptr || !VirtualQuery(ptr, &mbi, sizeof(mbi))) {
        return FALSE;
    }

    const uintptr_t start = (uintptr_t)ptr;
    const uintptr_t end = start + size;
    const uintptr_t regionEnd = (uintptr_t)mbi.BaseAddress + mbi.RegionSize;
    if (end > regionEnd || mbi.State != MEM_COMMIT) {
        return FALSE;
    }

    const DWORD protect = mbi.Protect & 0xff;
    return protect == PAGE_READWRITE || protect == PAGE_EXECUTE_READWRITE ||
           protect == PAGE_WRITECOPY || protect == PAGE_EXECUTE_WRITECOPY;
}

static BOOL ReadU32(uintptr_t address, uint32_t* out) {
    if (!IsReadable((const void*)address, sizeof(uint32_t))) {
        return FALSE;
    }
    *out = *(const uint32_t*)address;
    return TRUE;
}

static BOOL ReadU64(uintptr_t address, uint64_t* out) {
    if (!IsReadable((const void*)address, sizeof(uint64_t))) {
        return FALSE;
    }
    *out = *(const uint64_t*)address;
    return TRUE;
}

static BOOL WriteU32(uintptr_t address, uint32_t value) {
    void* ptr = (void*)address;
    if (!IsWritable(ptr, sizeof(uint32_t))) {
        DWORD oldProtect = 0;
        if (!VirtualProtect(ptr, sizeof(uint32_t), PAGE_READWRITE, &oldProtect)) {
            return FALSE;
        }
        *(uint32_t*)address = value;
        VirtualProtect(ptr, sizeof(uint32_t), oldProtect, &oldProtect);
        return TRUE;
    }

    *(uint32_t*)address = value;
    return TRUE;
}

static BOOL WriteFloat(uintptr_t address, float value) {
    void* ptr = (void*)address;
    if (!IsWritable(ptr, sizeof(float))) {
        DWORD oldProtect = 0;
        if (!VirtualProtect(ptr, sizeof(float), PAGE_READWRITE, &oldProtect)) {
            return FALSE;
        }
        *(float*)address = value;
        VirtualProtect(ptr, sizeof(float), oldProtect, &oldProtect);
        return TRUE;
    }

    *(float*)address = value;
    return TRUE;
}

static uint32_t GetVisibleItemField(uint32_t slotId) {
    static const uint32_t slotMap[20] = {
        0,
        0,  // 1 Head
        1,  // 2 Neck
        2,  // 3 Shoulder
        3,  // 4 Shirt
        4,  // 5 Chest
        5,  // 6 Waist
        6,  // 7 Legs
        7,  // 8 Feet
        8,  // 9 Wrist
        9,  // 10 Hands
        10, // 11 Finger 1
        11, // 12 Finger 2
        12, // 13 Trinket 1
        13, // 14 Trinket 2
        14, // 15 Back
        15, // 16 Main hand
        16, // 17 Off hand
        17, // 18 Ranged
        18  // 19 Tabard
    };

    if (slotId < 1 || slotId > 19) {
        return 0;
    }

    return (PLAYER_VISIBLE_ITEM_BASE + slotMap[slotId] * 2) * 4;
}

static uint32_t GetVisibleEnchantField(uint32_t slotId) {
    uint32_t itemField = GetVisibleItemField(slotId);
    if (!itemField) {
        return 0;
    }
    return itemField + 4;
}

static BOOL MarkTitleKnown(uintptr_t descriptors, uint32_t titleId) {
    if (!titleId || titleId >= 192) {
        return TRUE;
    }

    const uint32_t field = PLAYER_KNOWN_TITLES_BASE + (titleId / 32);
    const uint32_t bit = titleId % 32;
    uint32_t current = 0;
    ReadU32(descriptors + field * 4, &current);
    return WriteU32(descriptors + field * 4, current | (1u << bit));
}

static BOOL PatternScan(uintptr_t start, uint32_t size, const char* pattern, const char* mask, uintptr_t* result) {
    const uint32_t len = (uint32_t)my_strlen(mask);
    if (!len || len > size) {
        return FALSE;
    }

    for (uint32_t i = 0; i <= size - len; ++i) {
        BOOL found = TRUE;
        for (uint32_t j = 0; j < len; ++j) {
            const char* current = (const char*)(start + i + j);
            if (!IsReadable(current, 1) || (mask[j] != '?' && *current != pattern[j])) {
                found = FALSE;
                break;
            }
        }
        if (found) {
            *result = start + i;
            return TRUE;
        }
    }
    return FALSE;
}

static uintptr_t PlayerDescriptor(BOOL verbose) {
    uint32_t clientConnection = 0;
    uint32_t objectManager = 0;
    uint64_t localGuid = 0;
    uint32_t playerObject = 0;
    uint32_t descriptors = 0;

    if (!ReadU32(P_CLIENT_CONNECTION, &clientConnection)) {
        if (verbose) Log("PlayerDescriptor: Failed to read P_CLIENT_CONNECTION (0x%08X)", P_CLIENT_CONNECTION);
        return 0;
    }
    if (!clientConnection) {
        if (verbose) Log("PlayerDescriptor: clientConnection is NULL");
        return 0;
    }

    if (!ReadU32(clientConnection + P_OBJECT_MGR_OFFSET, &objectManager)) {
        if (verbose) Log("PlayerDescriptor: Failed to read objectManager at 0x%08X", clientConnection + P_OBJECT_MGR_OFFSET);
        return 0;
    }
    if (!objectManager) {
        if (verbose) Log("PlayerDescriptor: objectManager is NULL");
        return 0;
    }

    if (!ReadU64(objectManager + 0xC0, &localGuid)) {
        if (verbose) Log("PlayerDescriptor: Failed to read localGuid at 0x%08X", objectManager + 0xC0);
        return 0;
    }
    if (!localGuid) {
        if (verbose) Log("PlayerDescriptor: localGuid is 0");
        return 0;
    }
    g_localGuid = localGuid;

    if (verbose) {
        Log("PlayerDescriptor: localGuid = 0x%08X%08X",
            (uint32_t)(localGuid >> 32), (uint32_t)(localGuid & 0xFFFFFFFF));
    }

    uintptr_t current = 0;
    if (!ReadU32(objectManager + 0xAC, &current)) {
        if (verbose) Log("PlayerDescriptor: Failed to read firstObject at 0x%08X", objectManager + 0xAC);
        return 0;
    }
    if (verbose) Log("PlayerDescriptor: Traversal starting from firstObject = 0x%08X", current);

    unsigned count = 0;
    while (current && count < 200) {
        uint64_t guid = 0;
        uint32_t type = 0;
        uint32_t obj_desc = 0;

        if (!ReadU64(current + 0x30, &guid)) {
            if (verbose) Log("PlayerDescriptor: Traversal failed to read GUID at 0x%08X", current + 0x30);
            break;
        }

        ReadU32(current + 0x14, &type);
        ReadU32(current + 0x08, &obj_desc);

        if (verbose) {
            Log("PlayerDescriptor: Object [%u] at 0x%08X, Type=%u, Descriptors=0x%08X, GUID=0x%08X%08X",
                count, current, type, obj_desc,
                (uint32_t)(guid >> 32), (uint32_t)(guid & 0xFFFFFFFF));
        }

        if (guid == localGuid) {
            if (verbose) Log("PlayerDescriptor: MATCH! Found local player object at 0x%08X", current);
            playerObject = current;
            g_playerObject = current;
            break;
        }

        if (!ReadU32(current + 0x3C, &current)) {
            if (verbose) Log("PlayerDescriptor: Traversal failed to read nextObject at 0x%08X", current + 0x3C);
            break;
        }
        count++;
    }

    if (!playerObject) {
        if (verbose) Log("PlayerDescriptor: Local player object not found in traversal");
        return 0;
    }

    if (!ReadU32(playerObject + 0x08, &descriptors)) {
        if (verbose) Log("PlayerDescriptor: Failed to read descriptors at 0x%08X", playerObject + 0x08);
        return 0;
    }
    if (!descriptors) {
        if (verbose) Log("PlayerDescriptor: descriptors is NULL");
        return 0;
    }

    uint64_t objectGuid = 0;
    if (!ReadU64(descriptors, &objectGuid)) {
        if (verbose) Log("PlayerDescriptor: Failed to read objectGuid at 0x%08X", descriptors);
        return 0;
    }
    if (objectGuid != localGuid) {
        if (verbose) {
            Log("PlayerDescriptor: objectGuid (0x%08X%08X) != localGuid (0x%08X%08X)",
                (uint32_t)(objectGuid >> 32), (uint32_t)(objectGuid & 0xFFFFFFFF),
                (uint32_t)(localGuid >> 32), (uint32_t)(localGuid & 0xFFFFFFFF));
        }
        return 0;
    }

    g_playerDescriptors = descriptors;
    return descriptors;
}

static void SetStatus(const char* status) {
    if (!status || !g_frameScriptExecute) {
        return;
    }

    char escaped[512] = {0};
    unsigned w = 0;
    for (unsigned r = 0; status[r] && w + 2 < sizeof(escaped); ++r) {
        if (status[r] == '\'' || status[r] == '\\') {
            escaped[w++] = '\\';
        }
        escaped[w++] = status[r];
    }

    char script[700] = {0};
    wsprintfA(script, "WINEMORPHER_STATUS = '%s'", escaped);
    g_frameScriptExecute(script, "WineMorpher", 0);
}

void __attribute__((naked)) MountMorphHook(void) {
    __asm__ __volatile__(
        ".intel_syntax noprefix\n"
        "push ebx\n"
        "cmp edx, 0x45\n"
        "jne hook_done\n"
        "cmp ecx, 0\n"
        "je hook_done\n"
        "mov ebx, dword ptr [%1]\n"
        "cmp ebx, 0\n"
        "je hook_done\n"
        "cmp eax, ebx\n"
        "jne hook_done\n"
        "mov ebx, dword ptr [%0]\n"
        "cmp ebx, 0\n"
        "je hook_done\n"
        "mov ecx, ebx\n"
        "hook_done:\n"
        "pop ebx\n"
        "mov [eax+edx*4], ecx\n"
        "pop ebp\n"
        "ret 8\n"
        ".att_syntax\n"
        :
        : "m"(g_activeMount), "m"(g_playerDescriptors)
    );
}

static BOOL Hook(void* toHook, void* function, int length) {
    if (length < 5) return FALSE;
    DWORD oldProtect = 0;
    if (!VirtualProtect(toHook, length, PAGE_EXECUTE_READWRITE, &oldProtect)) {
        return FALSE;
    }
    for (int i = 0; i < length; ++i) {
        ((char*)toHook)[i] = (char)0x90; // NOP
    }
    uint32_t relativeAddress = ((uint32_t)function - (uint32_t)toHook) - 5;
    *(unsigned char*)toHook = 0xE9;
    *(uint32_t*)((uint32_t)toHook + 1) = relativeAddress;
    DWORD tempProtect = 0;
    VirtualProtect(toHook, length, oldProtect, &tempProtect);
    return TRUE;
}

void WoW335_Init(void) {
    const uintptr_t base = (uintptr_t)GetModuleHandleA(NULL);
    uintptr_t result = 0;

    if (PatternScan(base, 0x800000,
        "\x55\x8B\xEC\x81\xEC\x00\x00\x00\x00\x53\x8B\x5D\x08\x56\x57\x85\xDB\x74",
        "xxxxx????xxxxxxxxx", &result)) {
        g_frameScriptExecute = (FrameScriptExecuteFn)result;
        Log("Found FrameScript_Execute at 0x%08X", (unsigned)result);
    } else {
        g_frameScriptExecute = (FrameScriptExecuteFn)0x00819210;
        Log("Using fallback FrameScript_Execute at 0x00819210");
    }

    if (PatternScan(base, 0x800000,
        "\x55\x8B\xEC\x83\xEC\x10\x53\x56\x8B\x75\x08\x57\x8B\x7D\x0C\x85\xF6",
        "xxxxxxxxxxxxxxxx", &result)) {
        g_luaGetfield = (LuaGetfieldFn)result;
        Log("Found lua_getfield at 0x%08X", (unsigned)result);
    } else {
        g_luaGetfield = (LuaGetfieldFn)0x0084E590;
        Log("Using fallback lua_getfield at 0x0084E590");
    }

    if (PatternScan(base, 0x800000,
        "\x55\x8B\xEC\x51\x8B\x45\x0C\x53\x56\x8B\x75\x08\x57\x85\xC0\x75\x0C",
        "xxxxxxxxxxxxxxxx", &result)) {
        g_luaTolstring = (LuaTolstringFn)result;
        Log("Found lua_tolstring at 0x%08X", (unsigned)result);
    } else {
        g_luaTolstring = (LuaTolstringFn)0x0084E0E0;
        Log("Using fallback lua_tolstring at 0x0084E0E0");
    }

    if (PatternScan(base, 0x800000,
        "\x55\x8B\xEC\x8B\x45\x0C\x85\xC0\x78\x12\x8B\x55\x08\x8B\x0A\x8D\x14\xC1\x3B\x52\x08\x76\x1D",
        "xxxxxxxxxxxxxxxxxxxxxxx", &result)) {
        g_luaSettop = (LuaSettopFn)result;
        Log("Found lua_settop at 0x%08X", (unsigned)result);
    } else {
        g_luaSettop = (LuaSettopFn)0x0084DBF0;
        Log("Using fallback lua_settop at 0x0084DBF0");
    }

    // Install the Mount Morph Assembly Hook at WoW.exe base + 0x343BAC (offset 0x343BAC)
    uintptr_t mountHookAddr = base + 0x343BAC;
    if (IsReadable((const void*)mountHookAddr, 6)) {
        unsigned char originalBytes[6];
        my_memcpy(originalBytes, (const void*)mountHookAddr, 6);
        Log("Original bytes at mount hook address 0x%08X: %02X %02X %02X %02X %02X %02X",
            mountHookAddr,
            originalBytes[0], originalBytes[1], originalBytes[2],
            originalBytes[3], originalBytes[4], originalBytes[5]);

        if (originalBytes[0] != 0x89 || originalBytes[1] != 0x0C || originalBytes[2] != 0x90 ||
            originalBytes[3] != 0x5D || originalBytes[4] != 0xC2) {
            Log("Mount hook pattern mismatch; skipping hook install");
            return;
        }

        if (Hook((void*)mountHookAddr, MountMorphHook, 6)) {
            Log("Successfully installed Mount Hook at 0x%08X", mountHookAddr);
        } else {
            Log("Failed to install Mount Hook");
        }
    } else {
        Log("ERROR: Mount hook address 0x%08X is not readable!", mountHookAddr);
    }
}

BOOL WoW335_IsLuaReady(void) {
    if (!g_getLuaState || !g_luaGetfield || !g_luaTolstring || !g_luaSettop) {
        return FALSE;
    }

    void* lua = g_getLuaState();
    if (!lua) {
        return FALSE;
    }

    g_luaGetfield(lua, LUA_GLOBALSINDEX, "WINEMORPHER_LUA_READY");
    size_t len = 0;
    const char* value = g_luaTolstring(lua, -1, &len);
    const BOOL ready = value && len == 4 && my_memcmp(value, "TRUE", 4) == 0;
    g_luaSettop(lua, -2);
    return ready;
}

BOOL WoW335_SetLuaGlobal(const char* assignment) {
    if (!g_frameScriptExecute || !assignment) {
        return FALSE;
    }
    return g_frameScriptExecute(assignment, "WineMorpher", 0) != 0;
}

BOOL WoW335_ConsumeCommand(char* out, unsigned outSize) {
    if (!out || outSize == 0 || !g_getLuaState || !g_luaGetfield || !g_luaTolstring || !g_luaSettop) {
        return FALSE;
    }

    out[0] = '\0';
    void* lua = g_getLuaState();
    if (!lua) {
        return FALSE;
    }

    g_luaGetfield(lua, LUA_GLOBALSINDEX, "WINEMORPHER_CMD");
    size_t len = 0;
    const char* value = g_luaTolstring(lua, -1, &len);
    if (!value || len == 0) {
        g_luaSettop(lua, -2);
        return FALSE;
    }

    if (len >= outSize) {
        len = outSize - 1;
    }
    my_memcpy(out, value, len);
    out[len] = '\0';
    g_luaSettop(lua, -2);

    WoW335_SetLuaGlobal("WINEMORPHER_CMD = ''");
    return TRUE;
}

BOOL WoW335_ApplyDisplay(uint32_t displayId, char* status, unsigned statusSize) {
    (void)statusSize;
    Log("WoW335_ApplyDisplay called with ID %u", displayId);
    const uintptr_t descriptors = PlayerDescriptor(TRUE);
    if (!descriptors) {
        wsprintfA(status, "no player descriptors yet");
        SetStatus(status);
        Log("WoW335_ApplyDisplay failed: descriptors is NULL");
        return FALSE;
    }

    uint32_t current = 0;
    if (!ReadU32(descriptors + UNIT_FIELD_DISPLAYID, &current)) {
        wsprintfA(status, "cannot read display field");
        SetStatus(status);
        Log("WoW335_ApplyDisplay failed: cannot read display ID at 0x%08X", descriptors + UNIT_FIELD_DISPLAYID);
        return FALSE;
    }

    if (!g_hasOriginalDisplay) {
        g_originalDisplay = current;
        g_hasOriginalDisplay = TRUE;
        Log("Saved original display id %u", g_originalDisplay);
    }

    g_activeDisplay = displayId;
    BOOL success1 = WriteU32(descriptors + UNIT_FIELD_DISPLAYID, displayId);
    BOOL success2 = WriteU32(descriptors + UNIT_FIELD_NATIVEDISPLAYID, displayId);
    if (!success1 || !success2) {
        wsprintfA(status, "failed to write display %u", displayId);
        SetStatus(status);
        Log("WoW335_ApplyDisplay failed: write1=%d, write2=%d at 0x%08X", success1, success2, descriptors + UNIT_FIELD_DISPLAYID);
        return FALSE;
    }

    wsprintfA(status, "display morph active: %u", displayId);
    SetStatus(status);
    Log("%s", status);

    if (g_playerObject) {
        g_updateDisplayInfo((void*)g_playerObject, 1);
        Log("WoW335_ApplyDisplay: Called UpdateDisplayInfo(0x%08X, 1)", g_playerObject);
    }
    return TRUE;
}

BOOL WoW335_ResetDisplay(char* status, unsigned statusSize) {
    (void)statusSize;
    Log("WoW335_ResetDisplay called");
    const uintptr_t descriptors = PlayerDescriptor(TRUE);
    g_activeDisplay = 0;

    if (!descriptors) {
        wsprintfA(status, "no player descriptors yet");
        SetStatus(status);
        Log("WoW335_ResetDisplay failed: descriptors is NULL");
        return FALSE;
    }
    if (!g_hasOriginalDisplay) {
        wsprintfA(status, "nothing to reset");
        SetStatus(status);
        Log("WoW335_ResetDisplay failed: no original display saved");
        return FALSE;
    }

    BOOL success1 = WriteU32(descriptors + UNIT_FIELD_DISPLAYID, g_originalDisplay);
    BOOL success2 = WriteU32(descriptors + UNIT_FIELD_NATIVEDISPLAYID, g_originalDisplay);
    if (!success1 || !success2) {
        wsprintfA(status, "failed to restore display %u", g_originalDisplay);
        SetStatus(status);
        Log("WoW335_ResetDisplay failed: write1=%d, write2=%d at 0x%08X", success1, success2, descriptors + UNIT_FIELD_DISPLAYID);
        return FALSE;
    }

    wsprintfA(status, "restored display %u", g_originalDisplay);
    SetStatus(status);
    Log("%s", status);

    if (g_playerObject) {
        g_updateDisplayInfo((void*)g_playerObject, 1);
        Log("WoW335_ResetDisplay: Called UpdateDisplayInfo(0x%08X, 1)", g_playerObject);
    }
    return TRUE;
}

BOOL WoW335_ApplyMount(uint32_t displayId, char* status, unsigned statusSize) {
    (void)statusSize;
    Log("WoW335_ApplyMount called with ID %u", displayId);
    const uintptr_t descriptors = PlayerDescriptor(TRUE);
    if (!descriptors) {
        wsprintfA(status, "no player descriptors yet");
        SetStatus(status);
        Log("WoW335_ApplyMount failed: descriptors is NULL");
        return FALSE;
    }

    g_activeMount = displayId;

    uint32_t currentMount = 0;
    ReadU32(descriptors + UNIT_FIELD_MOUNTDISPLAYID, &currentMount);

    if (currentMount != 0 || displayId == 0) {
        if (!WriteU32(descriptors + UNIT_FIELD_MOUNTDISPLAYID, displayId)) {
            wsprintfA(status, "failed to write mount %u", displayId);
            SetStatus(status);
            Log("WoW335_ApplyMount failed: cannot write mount ID at 0x%08X", descriptors + UNIT_FIELD_MOUNTDISPLAYID);
            return FALSE;
        }

        if (g_playerObject) {
            g_updateDisplayInfo((void*)g_playerObject, 1);
            Log("WoW335_ApplyMount: Called UpdateDisplayInfo(0x%08X, 1)", g_playerObject);
        }
    }

    if (displayId == 0) {
        wsprintfA(status, "mount morph reset");
    } else {
        wsprintfA(status, "mount morph active: %u", displayId);
    }
    SetStatus(status);
    Log("%s", status);
    return TRUE;
}

BOOL WoW335_ApplyScale(float scale, char* status, unsigned statusSize) {
    (void)statusSize;
    
    int whole = (int)scale;
    int frac = (int)((scale - whole) * 100);
    if (frac < 0) frac = -frac;
    Log("WoW335_ApplyScale called with scale %d.%02d", whole, frac);

    const uintptr_t descriptors = PlayerDescriptor(TRUE);
    if (!descriptors) {
        wsprintfA(status, "no player descriptors yet");
        SetStatus(status);
        Log("WoW335_ApplyScale failed: descriptors is NULL");
        return FALSE;
    }

    g_activeScale = scale;
    if (!WriteFloat(descriptors + OBJECT_FIELD_SCALE_X, scale)) {
        wsprintfA(status, "failed to write scale");
        SetStatus(status);
        Log("WoW335_ApplyScale failed: cannot write scale at 0x%08X", descriptors + OBJECT_FIELD_SCALE_X);
        return FALSE;
    }

    wsprintfA(status, "character scale active: %d.%02d", whole, frac);
    SetStatus(status);
    Log("%s", status);

    if (g_playerObject) {
        g_updateDisplayInfo((void*)g_playerObject, 1);
        Log("WoW335_ApplyScale: Called UpdateDisplayInfo(0x%08X, 1)", g_playerObject);
    }
    return TRUE;
}

BOOL WoW335_ApplyItem(uint32_t slotId, int32_t itemId, char* status, unsigned statusSize) {
    (void)statusSize;
    uint32_t itemField = GetVisibleItemField(slotId);
    uint32_t slotIndex = slotId - 1;
    if (!itemField) return FALSE;

    Log("WoW335_ApplyItem called: slot %u, item %d", slotId, itemId);
    
    const uintptr_t descriptors = PlayerDescriptor(TRUE);
    if (!descriptors) {
        wsprintfA(status, "no player descriptors yet");
        SetStatus(status);
        return FALSE;
    }

    uint32_t currentItem = 0;
    ReadU32(descriptors + itemField, &currentItem);

    if (!g_hasOriginalItem[slotIndex] && itemId != 0) {
        g_originalItems[slotIndex] = currentItem;
        g_hasOriginalItem[slotIndex] = TRUE;
        Log("Saved original item for slot %u: %u", slotId, currentItem);
    }

    uint32_t writeVal = 0;
    if (itemId == 0) {
        g_activeItems[slotIndex] = 0;
        writeVal = g_hasOriginalItem[slotIndex] ? g_originalItems[slotIndex] : currentItem;
    } else {
        g_activeItems[slotIndex] = itemId;
        writeVal = (itemId == -1) ? 0 : (uint32_t)itemId;
    }
    
    BOOL success = WriteU32(descriptors + itemField, writeVal);
    if (success) {
        if (itemId == 0) {
            wsprintfA(status, "item morph reset: slot %u -> %u", slotId, writeVal);
        } else {
            wsprintfA(status, "item morph active: slot %u -> %d", slotId, itemId);
        }
        SetStatus(status);
        if (g_playerObject) {
            g_updateDisplayInfo((void*)g_playerObject, 1);
        }
    }
    return success;
}

BOOL WoW335_ApplyEnchantMH(uint32_t enchantId, char* status, unsigned statusSize) {
    (void)statusSize;
    uint32_t enchantField = GetVisibleEnchantField(MAIN_HAND_SLOT);
    g_activeEnchantMH = enchantId;
    Log("WoW335_ApplyEnchantMH called: %u", enchantId);
    
    const uintptr_t descriptors = PlayerDescriptor(TRUE);
    if (!descriptors) return FALSE;
    
    BOOL success = WriteU32(descriptors + enchantField, enchantId);
    if (success) {
        wsprintfA(status, "mh enchant active: %u", enchantId);
        SetStatus(status);
        if (g_playerObject) {
            g_updateDisplayInfo((void*)g_playerObject, 1);
        }
    }
    return success;
}

BOOL WoW335_ApplyEnchantOH(uint32_t enchantId, char* status, unsigned statusSize) {
    (void)statusSize;
    uint32_t enchantField = GetVisibleEnchantField(OFF_HAND_SLOT);
    g_activeEnchantOH = enchantId;
    Log("WoW335_ApplyEnchantOH called: %u", enchantId);
    
    const uintptr_t descriptors = PlayerDescriptor(TRUE);
    if (!descriptors) return FALSE;
    
    BOOL success = WriteU32(descriptors + enchantField, enchantId);
    if (success) {
        wsprintfA(status, "oh enchant active: %u", enchantId);
        SetStatus(status);
        if (g_playerObject) {
            g_updateDisplayInfo((void*)g_playerObject, 1);
        }
    }
    return success;
}

BOOL WoW335_ApplyTitle(uint32_t titleId, char* status, unsigned statusSize) {
    (void)statusSize;
    g_activeTitle = titleId;
    Log("WoW335_ApplyTitle called: %u", titleId);

    const uintptr_t descriptors = PlayerDescriptor(TRUE);
    if (!descriptors) {
        wsprintfA(status, "no player descriptors yet");
        SetStatus(status);
        return FALSE;
    }

    BOOL success = TRUE;
    if (titleId) {
        success &= MarkTitleKnown(descriptors, titleId);
    }
    success &= WriteU32(descriptors + PLAYER_CHOSEN_TITLE, titleId);
    if (success) {
        if (titleId) {
            wsprintfA(status, "title active: %u", titleId);
        } else {
            wsprintfA(status, "title reset");
        }
        SetStatus(status);
    }
    return success;
}

static BOOL FindPetObject(uint64_t localGuid, uintptr_t* outPetObject, uintptr_t* outPetDescriptors, BOOL verbose) {
    uint32_t clientConnection = 0;
    uint32_t objectManager = 0;
    
    if (!ReadU32(P_CLIENT_CONNECTION, &clientConnection) || !clientConnection) return FALSE;
    if (!ReadU32(clientConnection + P_OBJECT_MGR_OFFSET, &objectManager) || !objectManager) return FALSE;
    
    uintptr_t current = 0;
    if (!ReadU32(objectManager + 0xAC, &current)) return FALSE;
    
    unsigned count = 0;
    while (current && count < 200) {
        uint32_t type = 0;
        ReadU32(current + 0x14, &type);
        
        if (type == 3) { // TYPEID_UNIT (creatures / pets)
            uintptr_t petDesc = 0;
            if (ReadU32(current + 0x08, &petDesc) && petDesc) {
                uint64_t summonedBy = 0;
                uint64_t createdBy = 0;
                ReadU64(petDesc + 14 * 4, &summonedBy);
                ReadU64(petDesc + 16 * 4, &createdBy);
                if (summonedBy == localGuid || createdBy == localGuid) {
                    if (verbose) Log("FindPetObject: Found matching pet unit at 0x%08X", current);
                    *outPetObject = current;
                    *outPetDescriptors = petDesc;
                    return TRUE;
                }
            }
        }
        
        if (!ReadU32(current + 0x3C, &current)) break;
        count++;
    }
    return FALSE;
}

BOOL WoW335_ApplyPetMorph(uint32_t displayId, char* status, unsigned statusSize) {
    (void)statusSize;
    g_activePetDisplay = displayId;
    Log("WoW335_ApplyPetMorph called: %u", displayId);
    
    if (!g_localGuid) {
        wsprintfA(status, "no local player GUID yet");
        SetStatus(status);
        return FALSE;
    }
    
    uintptr_t petObject = 0;
    uintptr_t petDesc = 0;
    if (!FindPetObject(g_localGuid, &petObject, &petDesc, TRUE)) {
        wsprintfA(status, "no active pet found");
        SetStatus(status);
        return FALSE;
    }
    
    BOOL success1 = WriteU32(petDesc + UNIT_FIELD_DISPLAYID, displayId);
    BOOL success2 = WriteU32(petDesc + UNIT_FIELD_NATIVEDISPLAYID, displayId);
    if (success1 && success2) {
        wsprintfA(status, "pet morph active: %u", displayId);
        SetStatus(status);
        g_updateDisplayInfo((void*)petObject, 1);
    }
    return success1 && success2;
}

BOOL WoW335_ApplyPetScale(float scale, char* status, unsigned statusSize) {
    (void)statusSize;
    g_activePetScale = scale;
    
    int whole = (int)scale;
    int frac = (int)((scale - whole) * 100);
    if (frac < 0) frac = -frac;
    Log("WoW335_ApplyPetScale called: %d.%02d", whole, frac);
    
    if (!g_localGuid) return FALSE;
    
    uintptr_t petObject = 0;
    uintptr_t petDesc = 0;
    if (!FindPetObject(g_localGuid, &petObject, &petDesc, TRUE)) {
        return FALSE;
    }
    
    BOOL success = WriteFloat(petDesc + OBJECT_FIELD_SCALE_X, scale);
    if (success) {
        wsprintfA(status, "pet scale active: %d.%02d", whole, frac);
        SetStatus(status);
        g_updateDisplayInfo((void*)petObject, 1);
    }
    return success;
}

BOOL WoW335_ResetAll(char* status, unsigned statusSize) {
    Log("WoW335_ResetAll called");
    for (int i = 0; i < 19; ++i) {
        g_activeItems[i] = 0;
    }
    g_activeMount = 0;
    g_activeScale = 0.0f;
    g_activePetDisplay = 0;
    g_activePetScale = 0.0f;
    g_activeEnchantMH = 0;
    g_activeEnchantOH = 0;
    g_activeTitle = 0;
    
    // Reset player display to original
    WoW335_ResetDisplay(status, statusSize);

    const uintptr_t descriptors = PlayerDescriptor(FALSE);
    if (descriptors) {
        WriteU32(descriptors + PLAYER_CHOSEN_TITLE, 0);
    }
    
    // Also refresh display info
    if (g_playerObject) {
        g_updateDisplayInfo((void*)g_playerObject, 1);
    }
    
    wsprintfA(status, "all morphs reset successfully");
    SetStatus(status);
    return TRUE;
}

BOOL WoW335_ReapplyActiveDisplay(void) {
    const uintptr_t descriptors = PlayerDescriptor(FALSE);
    if (!descriptors) {
        return FALSE;
    }

    BOOL success = TRUE;
    BOOL needs_redraw = FALSE;

    // 1. Maintain active character display ID
    if (g_activeDisplay) {
        uint32_t current1 = 0;
        uint32_t current2 = 0;
        ReadU32(descriptors + UNIT_FIELD_DISPLAYID, &current1);
        ReadU32(descriptors + UNIT_FIELD_NATIVEDISPLAYID, &current2);
        
        if (current1 != g_activeDisplay) {
            success &= WriteU32(descriptors + UNIT_FIELD_DISPLAYID, g_activeDisplay);
            needs_redraw = TRUE;
        }
        if (current2 != g_activeDisplay) {
            success &= WriteU32(descriptors + UNIT_FIELD_NATIVEDISPLAYID, g_activeDisplay);
            needs_redraw = TRUE;
        }
    }

    // 2. Maintain active mount display ID (only if currently mounted)
    if (g_activeMount) {
        uint32_t currentMount = 0;
        ReadU32(descriptors + UNIT_FIELD_MOUNTDISPLAYID, &currentMount);
        if (currentMount != 0 && currentMount != g_activeMount) {
            success &= WriteU32(descriptors + UNIT_FIELD_MOUNTDISPLAYID, g_activeMount);
            needs_redraw = TRUE;
            Log("WoW335_ReapplyActiveDisplay: Detected mount change, reapplied %u", g_activeMount);
        }
    }

    // 3. Maintain active character scale
    if (g_activeScale > 0.01f) {
        float currentScale = 0.0f;
        if (IsReadable((const void*)(descriptors + OBJECT_FIELD_SCALE_X), sizeof(float))) {
            currentScale = *(const float*)(descriptors + OBJECT_FIELD_SCALE_X);
            if (currentScale < g_activeScale - 0.01f || currentScale > g_activeScale + 0.01f) {
                success &= WriteFloat(descriptors + OBJECT_FIELD_SCALE_X, g_activeScale);
                needs_redraw = TRUE;
                Log("WoW335_ReapplyActiveDisplay: Detected scale change, reapplied");
            }
        }
    }

    // 4. Maintain active player gear items
    for (uint32_t i = 0; i < 19; ++i) {
        int32_t activeItem = g_activeItems[i];
        if (activeItem != 0) {
            uint32_t currentItem = 0;
            uint32_t writeVal = (activeItem == -1) ? 0 : (uint32_t)activeItem;
            uint32_t itemField = GetVisibleItemField(i + 1);
            ReadU32(descriptors + itemField, &currentItem);
            if (currentItem != writeVal) {
                success &= WriteU32(descriptors + itemField, writeVal);
                needs_redraw = TRUE;
                Log("WoW335_ReapplyActiveDisplay: Reapplied item morph for slot %u -> %d", i + 1, activeItem);
            }
        }
    }

    // 5. Maintain active weapon enchants
    if (g_activeEnchantMH) {
        uint32_t currentEnchant = 0;
        uint32_t enchantField = GetVisibleEnchantField(MAIN_HAND_SLOT);
        ReadU32(descriptors + enchantField, &currentEnchant);
        if (currentEnchant != g_activeEnchantMH) {
            success &= WriteU32(descriptors + enchantField, g_activeEnchantMH);
            needs_redraw = TRUE;
            Log("WoW335_ReapplyActiveDisplay: Reapplied MH enchant -> %u", g_activeEnchantMH);
        }
    }
    if (g_activeEnchantOH) {
        uint32_t currentEnchant = 0;
        uint32_t enchantField = GetVisibleEnchantField(OFF_HAND_SLOT);
        ReadU32(descriptors + enchantField, &currentEnchant);
        if (currentEnchant != g_activeEnchantOH) {
            success &= WriteU32(descriptors + enchantField, g_activeEnchantOH);
            needs_redraw = TRUE;
            Log("WoW335_ReapplyActiveDisplay: Reapplied OH enchant -> %u", g_activeEnchantOH);
        }
    }

    if (g_activeTitle) {
        uint32_t currentTitle = 0;
        ReadU32(descriptors + PLAYER_CHOSEN_TITLE, &currentTitle);
        if (currentTitle != g_activeTitle) {
            success &= WriteU32(descriptors + PLAYER_CHOSEN_TITLE, g_activeTitle);
            Log("WoW335_ReapplyActiveDisplay: Reapplied title -> %u", g_activeTitle);
        }
    }

    if (needs_redraw && g_playerObject) {
        g_updateDisplayInfo((void*)g_playerObject, 1);
    }

    // 6. Maintain active pet display and scale
    if (g_localGuid && (g_activePetDisplay || g_activePetScale > 0.01f)) {
        uintptr_t petObject = 0;
        uintptr_t petDesc = 0;
        if (FindPetObject(g_localGuid, &petObject, &petDesc, FALSE)) {
            BOOL petNeedsRedraw = FALSE;
            
            if (g_activePetDisplay) {
                uint32_t currentPet1 = 0;
                uint32_t currentPet2 = 0;
                ReadU32(petDesc + UNIT_FIELD_DISPLAYID, &currentPet1);
                ReadU32(petDesc + UNIT_FIELD_NATIVEDISPLAYID, &currentPet2);
                if (currentPet1 != g_activePetDisplay) {
                    success &= WriteU32(petDesc + UNIT_FIELD_DISPLAYID, g_activePetDisplay);
                    petNeedsRedraw = TRUE;
                }
                if (currentPet2 != g_activePetDisplay) {
                    success &= WriteU32(petDesc + UNIT_FIELD_NATIVEDISPLAYID, g_activePetDisplay);
                    petNeedsRedraw = TRUE;
                }
            }
            
            if (g_activePetScale > 0.01f) {
                float currentPetScale = 0.0f;
                if (IsReadable((const void*)(petDesc + OBJECT_FIELD_SCALE_X), sizeof(float))) {
                    currentPetScale = *(const float*)(petDesc + OBJECT_FIELD_SCALE_X);
                    if (currentPetScale < g_activePetScale - 0.01f || currentPetScale > g_activePetScale + 0.01f) {
                        success &= WriteFloat(petDesc + OBJECT_FIELD_SCALE_X, g_activePetScale);
                        petNeedsRedraw = TRUE;
                    }
                }
            }
            
            if (petNeedsRedraw && petObject) {
                g_updateDisplayInfo((void*)petObject, 1);
            }
        }
    }

    return success;
}
