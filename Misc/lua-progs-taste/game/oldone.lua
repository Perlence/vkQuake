-- Port of oldone.qc from GPL-licensed CleanFixedQuakeC.
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
local C = require("game.constants")
local animation = require("game.animation")
local gibs = require("game.gibs")

local count = animation.counter()
local f = {}

f.old1, f.old2, f.old3, f.old4, f.old5, f.old6,
    f.old7, f.old8, f.old9, f.old10, f.old11, f.old12,
    f.old13, f.old14, f.old15, f.old16, f.old17, f.old18,
    f.old19, f.old20, f.old21, f.old22, f.old23, f.old24,
    f.old25, f.old26, f.old27, f.old28, f.old29, f.old30,
    f.old31, f.old32, f.old33, f.old34, f.old35, f.old36,
    f.old37, f.old38, f.old39, f.old40, f.old41, f.old42,
    f.old43, f.old44, f.old45, f.old46 = count(46)

f.shake1, f.shake2, f.shake3, f.shake4, f.shake5, f.shake6,
    f.shake7, f.shake8, f.shake9, f.shake10, f.shake11, f.shake12,
    f.shake13, f.shake14, f.shake15, f.shake16, f.shake17, f.shake18,
    f.shake19, f.shake20, f.shake21 = count(21)

local CHAN_VOICE = 2
local DAMAGE_YES = 1
local MSG_BROADCAST = 0
local MSG_ALL = 2
local SVC_TEMPENTITY = 23
local SVC_FINALE = 31
local SVC_CDTRACK = 32
local TE_TELEPORT = 11

--[[
==============================================================================

OLD ONE (Shub-Niggurath)

==============================================================================
]]

local old_idle = animation.loop("oldone.old_idle", {
    { f.old1 },
    { f.old2 },
    { f.old3 },
    { f.old4 },
    { f.old5 },
    { f.old6 },
    { f.old7 },
    { f.old8 },
    { f.old9 },
    { f.old10 },
    { f.old11 },
    { f.old12 },
    { f.old13 },
    { f.old14 },
    { f.old15 },
    { f.old16 },
    { f.old17 },
    { f.old18 },
    { f.old19 },
    { f.old20 },
    { f.old21 },
    { f.old22 },
    { f.old23 },
    { f.old24 },
    { f.old25 },
    { f.old26 },
    { f.old27 },
    { f.old28 },
    { f.old29 },
    { f.old30 },
    { f.old31 },
    { f.old32 },
    { f.old33 },
    { f.old34 },
    { f.old35 },
    { f.old36 },
    { f.old37 },
    { f.old38 },
    { f.old39 },
    { f.old40 },
    { f.old41 },
    { f.old42 },
    { f.old43 },
    { f.old44 },
    { f.old45 },
    { f.old46 },
})

local old_thrash, finale_1, finale_2, finale_3, finale_4
old_thrash = animation.hold("oldone.old_thrash", {
    { f.shake1, function() quake.light_style(0, "m") end },
    { f.shake2, function() quake.light_style(0, "k") end },
    { f.shake3, function() quake.light_style(0, "k") end },
    { f.shake4, function() quake.light_style(0, "i") end },
    { f.shake5, function() quake.light_style(0, "g") end },
    { f.shake6, function() quake.light_style(0, "e") end },
    { f.shake7, function() quake.light_style(0, "c") end },
    { f.shake8, function() quake.light_style(0, "a") end },
    { f.shake9, function() quake.light_style(0, "c") end },
    { f.shake10, function() quake.light_style(0, "e") end },
    { f.shake11, function() quake.light_style(0, "g") end },
    { f.shake12, function() quake.light_style(0, "i") end },
    { f.shake13, function() quake.light_style(0, "k") end },
    { f.shake14, function() quake.light_style(0, "m") end },
    { f.shake15, function(self)
        quake.light_style(0, "m")
        self.cnt = self.cnt + 1
        if self.cnt ~= 3 then
            self.think = old_thrash
        end
    end },
    { f.shake16, function() quake.light_style(0, "g") end },
    { f.shake17, function() quake.light_style(0, "c") end },
    { f.shake18, function() quake.light_style(0, "b") end },
    { f.shake19, function() quake.light_style(0, "a") end },
    { f.shake20, function(self) finale_4(self) end },
})

--============================================================================

---@param self entity
---@return nil
finale_1 = quake.register_callback("oldone.finale_1", function(self)
    quake.globals.intermission_exittime = quake.time() + 10000000 -- never allow exit
    quake.globals.intermission_running = 1

    -- find the intermission spot
    local pos = quake.find(quake.world, "classname", "info_intermission")
    if not pos then
        error("no info_intermission")
    end
    local pl = quake.find(quake.world, "classname", "misc_teleporttrain")
    if not pl then
        error("no teleporttrain")
    end
    quake.remove(pl)

    quake.write_byte(MSG_ALL, SVC_FINALE)
    quake.write_string(MSG_ALL, "")

    pl = quake.find(quake.world, "classname", "player")
    while pl do
        pl.view_ofs = quake.vec3(0, 0, 0)
        quake.globals.other.v_angle = pos.mangle
        pl.angles = quake.globals.other.v_angle
        pl.fixangle = 1 -- turn this way immediately
        pl.map = self.map
        pl.nextthink = quake.time() + 0.5
        pl.takedamage = C.DAMAGE_NO
        pl.solid = C.SOLID_NOT
        pl.movetype = C.MOVETYPE_NONE
        pl.modelindex = 0
        quake.set_origin(pl, pos.origin)
        pl = quake.find(pl, "classname", "player")
    end

    -- make fake versions of all players as standins, and move the real
    -- players to the intermission spot

    -- wait for 1 second
    local timer = quake.spawn()
    timer.nextthink = quake.time() + 1
    timer.think = finale_2
end)

---@param self entity
---@return nil
finale_2 = quake.register_callback("oldone.finale_2", function(self)
    -- start a teleport splash inside shub
    local shub = assert(quake.globals.shub, "finale has no shub")
    local o = shub.origin - quake.vec3(0, 100, 0)
    quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
    quake.write_byte(MSG_BROADCAST, TE_TELEPORT)
    quake.write_coord(MSG_BROADCAST, o.x)
    quake.write_coord(MSG_BROADCAST, o.y)
    quake.write_coord(MSG_BROADCAST, o.z)

    quake.sound(shub, CHAN_VOICE, "misc/r_tele1.wav", 1, C.ATTN_NORM)

    self.nextthink = quake.time() + 2
    self.think = finale_3
end)

---@param _self entity
---@return nil
finale_3 = quake.register_callback("oldone.finale_3", function(_self)
    -- start shub thrashing wildly
    local shub = assert(quake.globals.shub, "finale has no shub")
    shub.think = old_thrash
    quake.sound(shub, CHAN_VOICE, "boss2/death.wav", 1, C.ATTN_NORM)
    quake.light_style(0, "abcdefghijklmlkjihgfedcb")
end)

---@param self entity
---@return nil
function finale_4(self)
    -- throw tons of meat chunks
    quake.sound(self, CHAN_VOICE, "boss2/pop2.wav", 1, C.ATTN_NORM)

    local oldo = self.origin

    local z = 16
    while z <= 144 do
        local x = -64
        while x <= 64 do
            local y = -64
            while y <= 64 do
                self.origin = quake.vec3(oldo.x + x, oldo.y + y, oldo.z + z)

                local r = quake.random()
                if r < 0.3 then
                    gibs.throw(self, "progs/gib1.mdl", -999)
                elseif r < 0.6 then
                    gibs.throw(self, "progs/gib2.mdl", -999)
                else
                    gibs.throw(self, "progs/gib3.mdl", -999)
                end
                y = y + 32
            end
            x = x + 32
        end
        z = z + 96
    end
    -- start the end text
    quake.write_byte(MSG_ALL, SVC_FINALE)
    quake.write_string(MSG_ALL, "Congratulations and well done! You have\nbeaten the hideous Shub-Niggurath, and\nher hundreds of ugly changelings and\nmonsters. You have proven that your\nskill and your cunning are greater than\nall the powers of Quake. You are the\nmaster now. Id Software salutes you.")

    -- put a player model down
    local n = quake.spawn()
    quake.set_model(n, "progs/player.mdl")
    oldo = oldo - quake.vec3(32, 264, 0)
    quake.set_origin(n, oldo)
    n.angles = quake.vec3(0, 290, 0)
    n.frame = 1

    quake.remove(self)

    -- switch cd track
    quake.write_byte(MSG_ALL, SVC_CDTRACK)
    quake.write_byte(MSG_ALL, 3)
    quake.write_byte(MSG_ALL, 3)
    quake.light_style(0, "m")
end

--============================================================================

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local oldone_pain = quake.register_callback("oldone.oldone_pain", function(self, _attacker, _damage)
    self.health = 40000
end)

---QUAKED monster_oldone (1 0 0) (-16 -16 -24) (16 16 32)
---@param self entity
---@return nil
local function spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end

    quake.precache_model2("progs/oldone.mdl")

    quake.precache_sound2("boss2/death.wav")
    quake.precache_sound2("boss2/idle.wav")
    quake.precache_sound2("boss2/sight.wav")
    quake.precache_sound2("boss2/pop2.wav")

    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP

    quake.set_model(self, "progs/oldone.mdl")
    quake.set_size(self, quake.vec3(-160, -128, -24), quake.vec3(160, 128, 256))

    -- kill by telefrag
    self.health = 40000
    self.think = old_idle
    self.nextthink = quake.time() + 0.1
    self.takedamage = DAMAGE_YES
    self.th_pain = oldone_pain
    self.th_die = finale_1
    quake.globals.shub = self

    quake.globals.total_monsters = quake.globals.total_monsters + 1
end

quake.register_entity("monster_oldone", spawn)
