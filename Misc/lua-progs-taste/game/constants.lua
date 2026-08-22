-- Derived from GPL-licensed Quake game code in CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")

local M = {
    AS_STRAIGHT = 1,
    AS_SLIDING = 2,
    AS_MELEE = 3,
    AS_MISSILE = 4,

    ATTN_NONE = 0,
    ATTN_NORM = 1,
    ATTN_IDLE = 2,
    ATTN_STATIC = 3,
    CHAN_WEAPON = 1,
    CHAN_VOICE = 2,
    CHAN_ITEM = 3,
    CHAN_BODY = 4,

    DAMAGE_NO = 0,
    DAMAGE_AIM = 2,

    FL_FLY = 1,
    FL_SWIM = 2,
    FL_CLIENT = 8,
    FL_NOTARGET = 128,
    FL_MONSTER = 32,
    FL_GODMODE = 64,
    FL_ONGROUND = 512,

    IT_INVISIBILITY = 524288,
    IT_ARMOR1 = 8192,
    IT_ARMOR2 = 16384,
    IT_ARMOR3 = 32768,

    MOVETYPE_NONE = 0,
    MOVETYPE_WALK = 3,
    MOVETYPE_STEP = 4,
    MOVETYPE_PUSH = 7,
    MOVETYPE_BOUNCE = 10,

    MSG_BROADCAST = 0,
    MSG_ALL = 2,
    RANGE_MELEE = 0,
    RANGE_NEAR = 1,
    RANGE_MID = 2,
    RANGE_FAR = 3,

    SOLID_NOT = 0,
    SOLID_BBOX = 2,
    SOLID_SLIDEBOX = 3,

    EF_MUZZLEFLASH = 2,
    SVC_KILLEDMONSTER = 14,
    SVC_TEMPENTITY = 23,
    TE_EXPLOSION = 3,
    TE_LIGHTNING1 = 5,

    VEC_ORIGIN = quake.vec3(0, 0, 0),
    VEC_HULL2_MIN = quake.vec3(-32, -32, -24),
    VEC_HULL2_MAX = quake.vec3(32, 32, 64),
}

return M
