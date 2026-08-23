-- Port of world.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

--[[  Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
]]

local quake = require("quake")
local weapons = require("game.weapons")

local M = {}
local g = quake.globals

---@return nil
local function init_body_que()
    g.bodyque_head = quake.spawn()
    g.bodyque_head.classname = "bodyque"
    g.bodyque_head.owner = quake.spawn()
    g.bodyque_head.owner.classname = "bodyque"
    g.bodyque_head.owner.owner = quake.spawn()
    g.bodyque_head.owner.owner.classname = "bodyque"
    g.bodyque_head.owner.owner.owner = quake.spawn()
    g.bodyque_head.owner.owner.owner.classname = "bodyque"
    g.bodyque_head.owner.owner.owner.owner = g.bodyque_head
end

---@return nil
function M.main()
    quake.dprint("main function\n")

    -- these are just commands the the prog compiler to copy these files
    quake.precache_file("progs.dat")
    quake.precache_file("gfx.wad")
    quake.precache_file("quake.rc")
    quake.precache_file("default.cfg")
    quake.precache_file("end1.bin")
    quake.precache_file2("end2.bin")
    quake.precache_file("demo1.dem")
    quake.precache_file("demo2.dem")
    quake.precache_file("demo3.dem")

    -- these are all of the lumps from the cached.ls files
    local files = {
        "gfx/palette.lmp", "gfx/colormap.lmp", "gfx/complete.lmp", "gfx/inter.lmp",
        "gfx/ranking.lmp", "gfx/vidmodes.lmp", "gfx/finale.lmp", "gfx/conback.lmp",
        "gfx/qplaque.lmp", "gfx/menudot1.lmp", "gfx/menudot2.lmp", "gfx/menudot3.lmp",
        "gfx/menudot4.lmp", "gfx/menudot5.lmp", "gfx/menudot6.lmp", "gfx/menuplyr.lmp",
        "gfx/bigbox.lmp", "gfx/dim_modm.lmp", "gfx/dim_drct.lmp", "gfx/dim_ipx.lmp",
        "gfx/dim_tcp.lmp", "gfx/dim_mult.lmp", "gfx/mainmenu.lmp", "gfx/box_tl.lmp",
        "gfx/box_tm.lmp", "gfx/box_tr.lmp", "gfx/box_ml.lmp", "gfx/box_mm.lmp",
        "gfx/box_mm2.lmp", "gfx/box_mr.lmp", "gfx/box_bl.lmp", "gfx/box_bm.lmp",
        "gfx/box_br.lmp", "gfx/sp_menu.lmp", "gfx/ttl_sgl.lmp", "gfx/ttl_main.lmp",
        "gfx/ttl_cstm.lmp", "gfx/mp_menu.lmp", "gfx/netmen1.lmp", "gfx/netmen2.lmp",
        "gfx/netmen3.lmp", "gfx/netmen4.lmp", "gfx/netmen5.lmp", "gfx/sell.lmp",
        "gfx/help0.lmp", "gfx/help1.lmp", "gfx/help2.lmp", "gfx/help3.lmp",
        "gfx/help4.lmp", "gfx/help5.lmp", "gfx/pause.lmp", "gfx/loading.lmp",
        "gfx/p_option.lmp", "gfx/p_load.lmp", "gfx/p_save.lmp", "gfx/p_multi.lmp",
    }
    for _, file in ipairs(files) do quake.precache_file(file) end
    quake.precache_file2("gfx/pop.lmp")

    -- sounds loaded by C code
    quake.precache_sound("misc/menu1.wav")
    quake.precache_sound("misc/menu2.wav")
    quake.precache_sound("misc/menu3.wav")
    quake.precache_sound("ambience/water1.wav")
    quake.precache_sound("ambience/wind2.wav")

    -- shareware
    quake.precache_file("maps/start.bsp")
    for i = 1, 8 do quake.precache_file("maps/e1m" .. i .. ".bsp") end

    -- registered
    quake.precache_file2("gfx/pop.lmp")
    for episode = 2, 3 do
        for map = 1, 7 do quake.precache_file2("maps/e" .. episode .. "m" .. map .. ".bsp") end
    end
    for map = 1, 8 do quake.precache_file2("maps/e4m" .. map .. ".bsp") end
    quake.precache_file2("maps/end.bsp")
    for map = 1, 6 do quake.precache_file2("maps/dm" .. map .. ".bsp") end
end

--=======================
--[[QUAKED worldspawn (0 0 0) ?
Only used for the world entity.
Set message to the level name.
Set sounds to the cd track to play.

World Types:
0: medieval
1: metal
2: base
]]
--=======================
---@param self entity
---@return nil
function M.worldspawn(self)
    g.lastspawn = quake.world
    init_body_que()

    -- custom map attributes
    if self.model == "maps/e1m8.bsp" then quake.cvar_set("sv_gravity", "100")
    else quake.cvar_set("sv_gravity", "800") end

    -- the area based ambient sounds MUST be the first precache_sounds
    -- player precaches
    -- get weapon precaches
    weapons.precache()

    -- sounds used from C physics code
    quake.precache_sound("demon/dland2.wav") -- landing thud
    quake.precache_sound("misc/h2ohit1.wav") -- landing splash

    -- setup precaches always needed
    local sounds = {
        "items/itembk2.wav", -- item respawn sound
        "player/plyrjmp8.wav", -- player jump
        "player/land.wav", -- player landing
        "player/land2.wav", -- player hurt landing
        "player/drown1.wav", -- drowning pain
        "player/drown2.wav", -- drowning pain
        "player/gasp1.wav", -- gasping for air
        "player/gasp2.wav", -- taking breath
        "player/h2odeath.wav", -- drowning death
        "misc/talk.wav", -- talk
        "player/teledth1.wav", -- telefrag
        "misc/r_tele1.wav", -- teleport sounds
        "misc/r_tele2.wav", "misc/r_tele3.wav", "misc/r_tele4.wav", "misc/r_tele5.wav",
        "weapons/lock4.wav", -- ammo pick up
        "weapons/pkup.wav", -- weapon up
        "items/armor1.wav", -- armor up
        "weapons/lhit.wav", --lightning
        "weapons/lstart.wav", --lightning start
        "items/damage3.wav",
        "misc/power.wav", --lightning for boss
    }
    for _, sound in ipairs(sounds) do quake.precache_sound(sound) end

    -- player gib sounds
    for _, sound in ipairs({"player/gib.wav", "player/udeath.wav", "player/tornoff2.wav"}) do quake.precache_sound(sound) end
    -- player pain sounds
    for i = 1, 6 do quake.precache_sound("player/pain" .. i .. ".wav") end
    -- player death sounds
    for i = 1, 5 do quake.precache_sound("player/death" .. i .. ".wav") end
    -- ax sounds
    quake.precache_sound("weapons/ax1.wav") -- ax swoosh
    quake.precache_sound("player/axhit1.wav") -- ax hit meat
    quake.precache_sound("player/axhit2.wav") -- ax hit world
    quake.precache_sound("player/h2ojump.wav") -- player jumping into water
    quake.precache_sound("player/slimbrn2.wav") -- player enter slime
    quake.precache_sound("player/inh2o.wav") -- player enter water
    quake.precache_sound("player/inlava.wav") -- player enter lava
    quake.precache_sound("misc/outwater.wav") -- leaving water sound
    quake.precache_sound("player/lburn1.wav") -- lava burn
    quake.precache_sound("player/lburn2.wav") -- lava burn
    quake.precache_sound("misc/water1.wav") -- swimming
    quake.precache_sound("misc/water2.wav") -- swimming

    local models = {
        "progs/player.mdl", "progs/eyes.mdl", "progs/h_player.mdl", "progs/gib1.mdl",
        "progs/gib2.mdl", "progs/gib3.mdl", "progs/s_bubble.spr", -- drowning bubbles
        "progs/s_explod.spr", -- sprite explosion
        "progs/v_axe.mdl", "progs/v_shot.mdl", "progs/v_nail.mdl", "progs/v_rock.mdl",
        "progs/v_shot2.mdl", "progs/v_nail2.mdl", "progs/v_rock2.mdl",
        "progs/bolt.mdl", "progs/bolt2.mdl", -- for lightning gun
        "progs/bolt3.mdl", -- for boss shock
        "progs/lavaball.mdl", -- for testing
        "progs/missile.mdl", "progs/grenade.mdl", "progs/spike.mdl", "progs/s_spike.mdl",
        "progs/backpack.mdl", "progs/zom_gib.mdl", "progs/v_light.mdl",
    }
    for _, model in ipairs(models) do quake.precache_model(model) end

    -- Setup light animation tables. 'a' is total darkness, 'z' is maxbright.
    quake.light_style(0, "m") -- 0 normal
    quake.light_style(1, "mmnmmommommnonmmonqnmmo") -- 1 FLICKER (first variety)
    quake.light_style(2, "abcdefghijklmnopqrstuvwxyzyxwvutsrqponmlkjihgfedcba") -- 2 SLOW STRONG PULSE
    quake.light_style(3, "mmmmmaaaaammmmmaaaaaabcdefgabcdefg") -- 3 CANDLE (first variety)
    quake.light_style(4, "mamamamamama") -- 4 FAST STROBE
    quake.light_style(5, "jklmnopqrstuvwxyzyxwvutsrqponmlkj") -- 5 GENTLE PULSE 1
    quake.light_style(6, "nmonqnmomnmomomno") -- 6 FLICKER (second variety)
    quake.light_style(7, "mmmaaaabcdefgmmmmaaaammmaamm") -- 7 CANDLE (second variety)
    quake.light_style(8, "mmmaaammmaaammmabcdefaaaammmmabcdefmmmaaaa") -- 8 CANDLE (third variety)
    quake.light_style(9, "aaaaaaaazzzzzzzz") -- 9 SLOW STROBE (fourth variety)
    quake.light_style(10, "mmamammmmammamamaaamammma") -- 10 FLUORESCENT FLICKER
    quake.light_style(11, "abcdefghijklmnopqrrqponmlkjihgfedcba") -- 11 SLOW PULSE NOT FADE TO BLACK
    -- styles 32-62 are assigned by the light program for switchable lights
    quake.light_style(63, "a") -- 63 testing
end

---@return nil
function M.start_frame()
    g.teamplay = quake.cvar("teamplay")
    g.skill = quake.cvar("skill")
    g.framecount = g.framecount + 1
end

--[[
==============================================================================

BODY QUE

==============================================================================
]]

-- just here so spawn functions don't complain after the world
-- creates bodyques
---@param _self entity
---@return nil
function M.bodyque(_self) end

-- make a body que entry for the given ent so the ent can be
-- respawned elsewhere
---@param ent entity
---@return nil
function M.copy_to_body_que(ent)
    local body = g.bodyque_head
    body.angles = ent.angles
    body.model = ent.model
    body.modelindex = ent.modelindex
    body.frame = ent.frame
    body.colormap = ent.colormap
    body.movetype = ent.movetype
    body.velocity = ent.velocity
    body.flags = 0
    quake.set_origin(body, ent.origin)
    quake.set_size(body, ent.mins, ent.maxs)
    g.bodyque_head = body.owner
end

quake.register_entity("worldspawn", M.worldspawn)
quake.register_entity("bodyque", M.bodyque)

return M
