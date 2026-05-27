#include "Command.h"

// Helper comparison and string parsing to avoid standard library
static int my_strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

static int my_strncmp(const char* s1, const char* s2, unsigned long n) {
    while (n && *s1 && (*s1 == *s2)) {
        s1++;
        s2++;
        n--;
    }
    if (n == 0) return 0;
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

static unsigned long my_strtoul10(const char* str, const char** endptr) {
    unsigned long res = 0;
    while (*str >= '0' && *str <= '9') {
        unsigned long next = res * 10 + (*str - '0');
        if (next < res) {
            // overflow occurred
            if (endptr) *endptr = str;
            return 0;
        }
        res = next;
        str++;
    }
    if (endptr) *endptr = str;
    return res;
}

static float my_strtof(const char* str, const char** endptr) {
    float res = 0.0f;
    const char* p = str;
    
    while (*p >= '0' && *p <= '9') {
        res = res * 10.0f + (*p - '0');
        p++;
    }
    
    if (*p == '.') {
        p++;
        float dec = 0.1f;
        while (*p >= '0' && *p <= '9') {
            res += (*p - '0') * dec;
            dec *= 0.1f;
            p++;
        }
    }
    
    if (endptr) *endptr = p;
    return res;
}

static int parse_u32_strict(const char* str, uint32_t* out) {
    const char* end = NULL;
    unsigned long value = 0;

    if (!str || *str == '\0') {
        return 0;
    }

    value = my_strtoul10(str, &end);
    if (!end || *end != '\0') {
        return 0;
    }

    *out = (uint32_t)value;
    return 1;
}

static int parse_float_strict(const char* str, float* out) {
    const char* end = NULL;
    float value = 0.0f;

    if (!str || *str == '\0') {
        return 0;
    }

    value = my_strtof(str, &end);
    if (!end || *end != '\0') {
        return 0;
    }

    *out = value;
    return 1;
}

Command ParseCommand(const char* raw) {
    Command cmd;
    cmd.type = COMMAND_TYPE_INVALID;
    cmd.value = 0;
    cmd.floatValue = 0.0f;
    cmd.extraValue = 0;

    if (!raw) {
        return cmd;
    }

    if (my_strcmp(raw, "STATUS") == 0) {
        cmd.type = COMMAND_TYPE_STATUS;
        return cmd;
    }

    if (my_strcmp(raw, "RESET") == 0) {
        cmd.type = COMMAND_TYPE_RESET;
        return cmd;
    }

    if (my_strcmp(raw, "RESET:ALL") == 0) {
        cmd.type = COMMAND_TYPE_RESET_ALL;
        return cmd;
    }

    if (my_strcmp(raw, "MOUNT_RESET") == 0) {
        cmd.type = COMMAND_TYPE_MOUNT;
        cmd.value = 0;
        return cmd;
    }

    if (my_strcmp(raw, "HPET_RESET") == 0 || my_strcmp(raw, "PET_RESET") == 0) {
        cmd.type = COMMAND_TYPE_HPET_RESET;
        return cmd;
    }

    if (my_strcmp(raw, "ENCHANT_RESET") == 0 || my_strcmp(raw, "ENCHANT_RESET_MH") == 0 || my_strcmp(raw, "ENCHANT_RESET_OH") == 0) {
        cmd.type = COMMAND_TYPE_ENCHANT_RESET;
        return cmd;
    }

    if (my_strcmp(raw, "TITLE_RESET") == 0) {
        cmd.type = COMMAND_TYPE_TITLE;
        cmd.value = 0;
        return cmd;
    }

    if (my_strncmp(raw, "DISPLAY:", 8) == 0) {
        const char* valStr = raw + 8;
        uint32_t value = 0;
        if (!parse_u32_strict(valStr, &value) || value == 0) return cmd;
        cmd.type = COMMAND_TYPE_DISPLAY;
        cmd.value = value;
        return cmd;
    }

    if (my_strncmp(raw, "MORPH:", 6) == 0) {
        const char* valStr = raw + 6;
        uint32_t value = 0;
        if (!parse_u32_strict(valStr, &value) || value == 0) return cmd;
        cmd.type = COMMAND_TYPE_DISPLAY;
        cmd.value = value;
        return cmd;
    }

    if (my_strncmp(raw, "MOUNT:", 6) == 0) {
        const char* valStr = raw + 6;
        uint32_t value = 0;
        if (!parse_u32_strict(valStr, &value)) return cmd;
        cmd.type = COMMAND_TYPE_MOUNT;
        cmd.value = value;
        return cmd;
    }

    if (my_strncmp(raw, "MOUNT_MORPH:", 12) == 0) {
        const char* valStr = raw + 12;
        uint32_t value = 0;
        if (!parse_u32_strict(valStr, &value)) return cmd;
        cmd.type = COMMAND_TYPE_MOUNT;
        cmd.value = value;
        return cmd;
    }

    if (my_strncmp(raw, "SCALE:", 6) == 0) {
        const char* valStr = raw + 6;
        float value = 0.0f;
        if (!parse_float_strict(valStr, &value) || value < 0.01f || value > 10.0f) return cmd;
        cmd.type = COMMAND_TYPE_SCALE;
        cmd.floatValue = value;
        return cmd;
    }

    if (my_strncmp(raw, "HPET_MORPH:", 11) == 0) {
        const char* valStr = raw + 11;
        uint32_t value = 0;
        if (!parse_u32_strict(valStr, &value)) return cmd;
        cmd.type = COMMAND_TYPE_HPET_MORPH;
        cmd.value = value;
        return cmd;
    }

    if (my_strncmp(raw, "PET_MORPH:", 10) == 0) {
        const char* valStr = raw + 10;
        uint32_t value = 0;
        if (!parse_u32_strict(valStr, &value)) return cmd;
        cmd.type = COMMAND_TYPE_HPET_MORPH;
        cmd.value = value;
        return cmd;
    }

    if (my_strncmp(raw, "HPET_SCALE:", 11) == 0) {
        const char* valStr = raw + 11;
        float value = 0.0f;
        if (!parse_float_strict(valStr, &value) || value < 0.01f || value > 10.0f) return cmd;
        cmd.type = COMMAND_TYPE_HPET_SCALE;
        cmd.floatValue = value;
        return cmd;
    }

    if (my_strncmp(raw, "ENCHANT_MH:", 11) == 0) {
        const char* valStr = raw + 11;
        uint32_t value = 0;
        if (!parse_u32_strict(valStr, &value)) return cmd;
        cmd.type = COMMAND_TYPE_ENCHANT_MH;
        cmd.value = value;
        return cmd;
    }

    if (my_strncmp(raw, "ENCHANT_OH:", 11) == 0) {
        const char* valStr = raw + 11;
        uint32_t value = 0;
        if (!parse_u32_strict(valStr, &value)) return cmd;
        cmd.type = COMMAND_TYPE_ENCHANT_OH;
        cmd.value = value;
        return cmd;
    }

    if (my_strncmp(raw, "TITLE:", 6) == 0) {
        const char* valStr = raw + 6;
        uint32_t value = 0;
        if (!parse_u32_strict(valStr, &value) || value == 0) return cmd;
        cmd.type = COMMAND_TYPE_TITLE;
        cmd.value = value;
        return cmd;
    }

    if (my_strncmp(raw, "ITEM:", 5) == 0) {
        const char* p = raw + 5;
        const char* end = NULL;
        unsigned long slot = my_strtoul10(p, &end);
        if (slot >= 1 && slot <= 19 && end && *end == ':') {
            p = end + 1;
            int32_t itemId = 0;
            if (p[0] == '-' && p[1] == '1') {
                if (p[2] != '\0') return cmd;
                itemId = -1;
            } else {
                uint32_t parsedItem = 0;
                if (!parse_u32_strict(p, &parsedItem)) return cmd;
                itemId = (int32_t)parsedItem;
            }
            cmd.type = COMMAND_TYPE_ITEM;
            cmd.value = (uint32_t)slot;
            cmd.extraValue = itemId;
            return cmd;
        }
    }

    return cmd;
}
