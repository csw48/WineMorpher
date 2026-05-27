#pragma once
#include <stdint.h>
#include <windows.h>

void WoW335_Init(void);
BOOL WoW335_IsLuaReady(void);
BOOL WoW335_SetLuaGlobal(const char* assignment);
BOOL WoW335_ConsumeCommand(char* out, unsigned outSize);
BOOL WoW335_ApplyDisplay(uint32_t displayId, char* status, unsigned statusSize);
BOOL WoW335_ResetDisplay(char* status, unsigned statusSize);
BOOL WoW335_ApplyMount(uint32_t displayId, char* status, unsigned statusSize);
BOOL WoW335_ApplyScale(float scale, char* status, unsigned statusSize);
BOOL WoW335_ApplyItem(uint32_t slotId, int32_t itemId, char* status, unsigned statusSize);
BOOL WoW335_ApplyEnchantMH(uint32_t enchantId, char* status, unsigned statusSize);
BOOL WoW335_ApplyEnchantOH(uint32_t enchantId, char* status, unsigned statusSize);
BOOL WoW335_ApplyTitle(uint32_t titleId, char* status, unsigned statusSize);
BOOL WoW335_ApplyPetMorph(uint32_t displayId, char* status, unsigned statusSize);
BOOL WoW335_ApplyPetScale(float scale, char* status, unsigned statusSize);
BOOL WoW335_ResetAll(char* status, unsigned statusSize);
BOOL WoW335_ReapplyActiveDisplay(void);
