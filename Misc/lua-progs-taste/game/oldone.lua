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

local M = {}
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

local finale_1, finale_2, finale_3, finale_4

local old_idle1, old_idle2, old_idle3, old_idle4, old_idle5, old_idle6
local old_idle7, old_idle8, old_idle9, old_idle10, old_idle11, old_idle12
local old_idle13, old_idle14, old_idle15, old_idle16, old_idle17, old_idle18
local old_idle19, old_idle20, old_idle21, old_idle22, old_idle23, old_idle24
local old_idle25, old_idle26, old_idle27, old_idle28, old_idle29, old_idle30
local old_idle31, old_idle32, old_idle33, old_idle34, old_idle35, old_idle36
local old_idle37, old_idle38, old_idle39, old_idle40, old_idle41, old_idle42
local old_idle43, old_idle44, old_idle45, old_idle46

old_idle1 = animation.frame("old1", function() return old_idle2 end)
old_idle2 = animation.frame("old2", function() return old_idle3 end)
old_idle3 = animation.frame("old3", function() return old_idle4 end)
old_idle4 = animation.frame("old4", function() return old_idle5 end)
old_idle5 = animation.frame("old5", function() return old_idle6 end)
old_idle6 = animation.frame("old6", function() return old_idle7 end)
old_idle7 = animation.frame("old7", function() return old_idle8 end)
old_idle8 = animation.frame("old8", function() return old_idle9 end)
old_idle9 = animation.frame("old9", function() return old_idle10 end)
old_idle10 = animation.frame("old10", function() return old_idle11 end)
old_idle11 = animation.frame("old11", function() return old_idle12 end)
old_idle12 = animation.frame("old12", function() return old_idle13 end)
old_idle13 = animation.frame("old13", function() return old_idle14 end)
old_idle14 = animation.frame("old14", function() return old_idle15 end)
old_idle15 = animation.frame("old15", function() return old_idle16 end)
old_idle16 = animation.frame("old16", function() return old_idle17 end)
old_idle17 = animation.frame("old17", function() return old_idle18 end)
old_idle18 = animation.frame("old18", function() return old_idle19 end)
old_idle19 = animation.frame("old19", function() return old_idle20 end)
old_idle20 = animation.frame("old20", function() return old_idle21 end)
old_idle21 = animation.frame("old21", function() return old_idle22 end)
old_idle22 = animation.frame("old22", function() return old_idle23 end)
old_idle23 = animation.frame("old23", function() return old_idle24 end)
old_idle24 = animation.frame("old24", function() return old_idle25 end)
old_idle25 = animation.frame("old25", function() return old_idle26 end)
old_idle26 = animation.frame("old26", function() return old_idle27 end)
old_idle27 = animation.frame("old27", function() return old_idle28 end)
old_idle28 = animation.frame("old28", function() return old_idle29 end)
old_idle29 = animation.frame("old29", function() return old_idle30 end)
old_idle30 = animation.frame("old30", function() return old_idle31 end)
old_idle31 = animation.frame("old31", function() return old_idle32 end)
old_idle32 = animation.frame("old32", function() return old_idle33 end)
old_idle33 = animation.frame("old33", function() return old_idle34 end)
old_idle34 = animation.frame("old34", function() return old_idle35 end)
old_idle35 = animation.frame("old35", function() return old_idle36 end)
old_idle36 = animation.frame("old36", function() return old_idle37 end)
old_idle37 = animation.frame("old37", function() return old_idle38 end)
old_idle38 = animation.frame("old38", function() return old_idle39 end)
old_idle39 = animation.frame("old39", function() return old_idle40 end)
old_idle40 = animation.frame("old40", function() return old_idle41 end)
old_idle41 = animation.frame("old41", function() return old_idle42 end)
old_idle42 = animation.frame("old42", function() return old_idle43 end)
old_idle43 = animation.frame("old43", function() return old_idle44 end)
old_idle44 = animation.frame("old44", function() return old_idle45 end)
old_idle45 = animation.frame("old45", function() return old_idle46 end)
old_idle46 = animation.frame("old46", function() return old_idle1 end)

local old_thrash1, old_thrash2, old_thrash3, old_thrash4, old_thrash5, old_thrash6
local old_thrash7, old_thrash8, old_thrash9, old_thrash10, old_thrash11, old_thrash12
local old_thrash13, old_thrash14, old_thrash15, old_thrash16, old_thrash17, old_thrash18
local old_thrash19, old_thrash20

old_thrash1 = animation.frame("shake1", function() return old_thrash2 end, function() quake.light_style(0, "m") end)
old_thrash2 = animation.frame("shake2", function() return old_thrash3 end, function() quake.light_style(0, "k") end)
old_thrash3 = animation.frame("shake3", function() return old_thrash4 end, function() quake.light_style(0, "k") end)
old_thrash4 = animation.frame("shake4", function() return old_thrash5 end, function() quake.light_style(0, "i") end)
old_thrash5 = animation.frame("shake5", function() return old_thrash6 end, function() quake.light_style(0, "g") end)
old_thrash6 = animation.frame("shake6", function() return old_thrash7 end, function() quake.light_style(0, "e") end)
old_thrash7 = animation.frame("shake7", function() return old_thrash8 end, function() quake.light_style(0, "c") end)
old_thrash8 = animation.frame("shake8", function() return old_thrash9 end, function() quake.light_style(0, "a") end)
old_thrash9 = animation.frame("shake9", function() return old_thrash10 end, function() quake.light_style(0, "c") end)
old_thrash10 = animation.frame("shake10", function() return old_thrash11 end, function() quake.light_style(0, "e") end)
old_thrash11 = animation.frame("shake11", function() return old_thrash12 end, function() quake.light_style(0, "g") end)
old_thrash12 = animation.frame("shake12", function() return old_thrash13 end, function() quake.light_style(0, "i") end)
old_thrash13 = animation.frame("shake13", function() return old_thrash14 end, function() quake.light_style(0, "k") end)
old_thrash14 = animation.frame("shake14", function() return old_thrash15 end, function() quake.light_style(0, "m") end)
old_thrash15 = animation.frame("shake15", function() return old_thrash16 end, function(self)
    quake.light_style(0, "m")
    self.cnt = self.cnt + 1
    if self.cnt ~= 3 then
        self.think = old_thrash1
    end
end)
old_thrash16 = animation.frame("shake16", function() return old_thrash17 end, function() quake.light_style(0, "g") end)
old_thrash17 = animation.frame("shake17", function() return old_thrash18 end, function() quake.light_style(0, "c") end)
old_thrash18 = animation.frame("shake18", function() return old_thrash19 end, function() quake.light_style(0, "b") end)
old_thrash19 = animation.frame("shake19", function() return old_thrash20 end, function() quake.light_style(0, "a") end)
old_thrash20 = animation.frame("shake20", function() return old_thrash20 end, function(self) finale_4(self) end)

--============================================================================

---@param self entity
---@return nil
finale_1 = function(self)
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
end

---@param self entity
---@return nil
finale_2 = function(self)
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
end

---@param _self entity
---@return nil
finale_3 = function(_self)
    -- start shub thrashing wildly
    local shub = assert(quake.globals.shub, "finale has no shub")
    shub.think = old_thrash1
    quake.sound(shub, CHAN_VOICE, "boss2/death.wav", 1, C.ATTN_NORM)
    quake.light_style(0, "abcdefghijklmlkjihgfedcb")
end

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
local function oldone_pain(self, _attacker, _damage)
    self.health = 40000
end

---QUAKED monster_oldone (1 0 0) (-16 -16 -24) (16 16 32)
---@param self entity
---@return nil
function M.spawn(self)
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
    self.think = old_idle1
    self.nextthink = quake.time() + 0.1
    self.takedamage = DAMAGE_YES
    self.th_pain = oldone_pain
    self.th_die = finale_1
    quake.globals.shub = self

    quake.globals.total_monsters = quake.globals.total_monsters + 1
end

quake.register_entity("monster_oldone", M.spawn)

return M
