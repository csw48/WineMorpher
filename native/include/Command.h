#pragma once
#include <stdint.h>
#include <stddef.h>

typedef enum {
    COMMAND_TYPE_INVALID = 0,
    COMMAND_TYPE_STATUS,
    COMMAND_TYPE_DISPLAY,
    COMMAND_TYPE_RESET,
    COMMAND_TYPE_MOUNT,
    COMMAND_TYPE_SCALE,
    COMMAND_TYPE_HPET_MORPH,
    COMMAND_TYPE_HPET_SCALE,
    COMMAND_TYPE_HPET_RESET,
    COMMAND_TYPE_ITEM,
    COMMAND_TYPE_ENCHANT_MH,
    COMMAND_TYPE_ENCHANT_OH,
    COMMAND_TYPE_ENCHANT_RESET,
    COMMAND_TYPE_RESET_ALL,
    COMMAND_TYPE_TITLE
} CommandType;

typedef struct {
    CommandType type;
    uint32_t value;
    float floatValue;
    int32_t extraValue;
} Command;

Command ParseCommand(const char* raw);
