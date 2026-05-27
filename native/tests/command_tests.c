#include "Command.h"
#include <stdio.h>
#include <stdlib.h>

static void expect(int condition, const char* message) {
    if (!condition) {
        fprintf(stderr, "FAIL: %s\n", message);
        exit(1);
    }
}

static void parsesStatus(void) {
    Command cmd = ParseCommand("STATUS");
    expect(cmd.type == COMMAND_TYPE_STATUS, "STATUS should parse as status");
}

static void parsesDisplay(void) {
    Command cmd = ParseCommand("DISPLAY:20578");
    expect(cmd.type == COMMAND_TYPE_DISPLAY, "DISPLAY should parse as display");
    expect(cmd.value == 20578, "DISPLAY should keep numeric display id");
}

static void parsesReset(void) {
    Command cmd = ParseCommand("RESET");
    expect(cmd.type == COMMAND_TYPE_RESET, "RESET should parse as reset");
}

static void parsesMount(void) {
    Command cmd = ParseCommand("MOUNT:24043");
    expect(cmd.type == COMMAND_TYPE_MOUNT, "MOUNT should parse as mount");
    expect(cmd.value == 24043, "MOUNT should keep numeric display id");

    Command cmd0 = ParseCommand("MOUNT:0");
    expect(cmd0.type == COMMAND_TYPE_MOUNT, "MOUNT:0 should parse as mount");
    expect(cmd0.value == 0, "MOUNT:0 should keep 0 display id");
}

static void parsesScale(void) {
    Command cmd = ParseCommand("SCALE:2.5");
    expect(cmd.type == COMMAND_TYPE_SCALE, "SCALE:2.5 should parse as scale");
    expect(cmd.floatValue >= 2.49f && cmd.floatValue <= 2.51f, "SCALE:2.5 should keep float value");

    Command cmd2 = ParseCommand("SCALE:0.75");
    expect(cmd2.type == COMMAND_TYPE_SCALE, "SCALE:0.75 should parse as scale");
    expect(cmd2.floatValue >= 0.74f && cmd2.floatValue <= 0.76f, "SCALE:0.75 should keep float value");
    
    Command cmd3 = ParseCommand("SCALE:1");
    expect(cmd3.type == COMMAND_TYPE_SCALE, "SCALE:1 should parse as scale");
    expect(cmd3.floatValue >= 0.99f && cmd3.floatValue <= 1.01f, "SCALE:1 should keep float value");
}

static void parsesItemAndEnchant(void) {
    Command item = ParseCommand("ITEM:16:49623");
    expect(item.type == COMMAND_TYPE_ITEM, "ITEM should parse as item");
    expect(item.value == 16, "ITEM should keep slot id");
    expect(item.extraValue == 49623, "ITEM should keep item id");

    Command hidden = ParseCommand("ITEM:1:-1");
    expect(hidden.type == COMMAND_TYPE_ITEM, "ITEM:-1 should parse as hidden item");
    expect(hidden.value == 1, "ITEM:-1 should keep slot id");
    expect(hidden.extraValue == -1, "ITEM:-1 should keep hidden sentinel");

    Command mh = ParseCommand("ENCHANT_MH:3789");
    expect(mh.type == COMMAND_TYPE_ENCHANT_MH, "ENCHANT_MH should parse");
    expect(mh.value == 3789, "ENCHANT_MH should keep enchant id");

    Command oh = ParseCommand("ENCHANT_OH:3789");
    expect(oh.type == COMMAND_TYPE_ENCHANT_OH, "ENCHANT_OH should parse");
    expect(oh.value == 3789, "ENCHANT_OH should keep enchant id");

    expect(ParseCommand("ENCHANT_RESET_MH").type == COMMAND_TYPE_ENCHANT_RESET, "ENCHANT_RESET_MH should parse");
    expect(ParseCommand("ENCHANT_RESET_OH").type == COMMAND_TYPE_ENCHANT_RESET, "ENCHANT_RESET_OH should parse");
}

static void parsesTitle(void) {
    Command title = ParseCommand("TITLE:177");
    expect(title.type == COMMAND_TYPE_TITLE, "TITLE should parse as title");
    expect(title.value == 177, "TITLE should keep title id");

    Command reset = ParseCommand("TITLE_RESET");
    expect(reset.type == COMMAND_TYPE_TITLE, "TITLE_RESET should parse as title");
    expect(reset.value == 0, "TITLE_RESET should reset title id");
}

static void rejectsBadCommands(void) {
    expect(ParseCommand("").type == COMMAND_TYPE_INVALID, "empty command should be invalid");
    expect(ParseCommand("DISPLAY:0").type == COMMAND_TYPE_INVALID, "zero display id should be invalid");
    expect(ParseCommand("DISPLAY:not-number").type == COMMAND_TYPE_INVALID, "non-numeric display id should be invalid");
    expect(ParseCommand("SPELL:123").type == COMMAND_TYPE_INVALID, "unknown command should be invalid");
    expect(ParseCommand("MOUNT:not-number").type == COMMAND_TYPE_INVALID, "non-numeric mount id should be invalid");
    expect(ParseCommand("SCALE:not-number").type == COMMAND_TYPE_INVALID, "non-numeric scale should be invalid");
    expect(ParseCommand("SCALE:0.001").type == COMMAND_TYPE_INVALID, "too small scale should be invalid");
    expect(ParseCommand("SCALE:11.0").type == COMMAND_TYPE_INVALID, "too large scale should be invalid");
    expect(ParseCommand("ITEM:0:123").type == COMMAND_TYPE_INVALID, "slot 0 should be invalid");
    expect(ParseCommand("ITEM:20:123").type == COMMAND_TYPE_INVALID, "slot 20 should be invalid");
    expect(ParseCommand("ITEM:16:not-number").type == COMMAND_TYPE_INVALID, "non-numeric item should be invalid");
    expect(ParseCommand("ENCHANT_MH:not-number").type == COMMAND_TYPE_INVALID, "non-numeric mh enchant should be invalid");
    expect(ParseCommand("TITLE:not-number").type == COMMAND_TYPE_INVALID, "non-numeric title should be invalid");
}

int main(void) {
    parsesStatus();
    parsesDisplay();
    parsesReset();
    parsesMount();
    parsesScale();
    parsesItemAndEnchant();
    parsesTitle();
    rejectsBadCommands();
    printf("command_tests passed\n");
    return 0;
}
