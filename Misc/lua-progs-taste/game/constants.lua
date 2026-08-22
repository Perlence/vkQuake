-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local M = {
    AS_STRAIGHT = 1,
    AS_SLIDING = 2,
    AS_MELEE = 3,
    AS_MISSILE = 4,

    ATTN_NONE = 0,
    ATTN_NORM = 1,
    CHAN_ITEM = 3,
    CHAN_VOICE = 2,

    DAMAGE_NO = 0,
    DAMAGE_AIM = 2,

    FL_FLY = 1,
    FL_SWIM = 2,
    FL_CLIENT = 8,
    FL_NOTARGET = 128,
    FL_MONSTER = 32,
    FL_GODMODE = 64,

    IT_INVISIBILITY = 524288,
    IT_ARMOR1 = 8192,
    IT_ARMOR2 = 16384,
    IT_ARMOR3 = 32768,

    MOVETYPE_NONE = 0,
    MOVETYPE_WALK = 3,
    MOVETYPE_STEP = 4,
    MOVETYPE_PUSH = 7,
    MOVETYPE_BOUNCE = 10,

    MSG_ALL = 2,
    RANGE_MELEE = 0,
    RANGE_NEAR = 1,
    RANGE_MID = 2,
    RANGE_FAR = 3,

    SOLID_NOT = 0,
    SOLID_SLIDEBOX = 3,
    SVC_KILLEDMONSTER = 14,
}

return M
