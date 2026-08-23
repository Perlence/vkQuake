-- Port of tarbaby.qc from GPL-licensed CleanFixedQuakeC.
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
local ai = require("game.ai")
local fight = require("game.fight")
local animation = require("game.animation")
local combat = require("game.combat")
local monsters = require("game.monsters")
local subs = require("game.subs")
local weapons = require("game.weapons")

local M = {}
local FL_ONGROUND = 512
local MOVETYPE_BOUNCE = 10

--[[
==============================================================================

BLOB (Spawn)

==============================================================================
]]

local tbaby_stand1
tbaby_stand1 = animation.frame("walk1", function() return tbaby_stand1 end, ai.stand)

local tbaby_hang1
tbaby_hang1 = animation.frame("walk1", function() return tbaby_hang1 end, ai.stand)
local tbaby_walk1, tbaby_walk2, tbaby_walk3, tbaby_walk4, tbaby_walk5
local tbaby_walk6, tbaby_walk7, tbaby_walk8, tbaby_walk9, tbaby_walk10
local tbaby_walk11, tbaby_walk12, tbaby_walk13, tbaby_walk14, tbaby_walk15
local tbaby_walk16, tbaby_walk17, tbaby_walk18, tbaby_walk19, tbaby_walk20
local tbaby_walk21, tbaby_walk22, tbaby_walk23, tbaby_walk24, tbaby_walk25

tbaby_walk1 = animation.frame("walk1", function() return tbaby_walk2 end, ai.turn)
tbaby_walk2 = animation.frame("walk2", function() return tbaby_walk3 end, ai.turn)
tbaby_walk3 = animation.frame("walk3", function() return tbaby_walk4 end, ai.turn)
tbaby_walk4 = animation.frame("walk4", function() return tbaby_walk5 end, ai.turn)
tbaby_walk5 = animation.frame("walk5", function() return tbaby_walk6 end, ai.turn)
tbaby_walk6 = animation.frame("walk6", function() return tbaby_walk7 end, ai.turn)
tbaby_walk7 = animation.frame("walk7", function() return tbaby_walk8 end, ai.turn)
tbaby_walk8 = animation.frame("walk8", function() return tbaby_walk9 end, ai.turn)
tbaby_walk9 = animation.frame("walk9", function() return tbaby_walk10 end, ai.turn)
tbaby_walk10 = animation.frame("walk10", function() return tbaby_walk11 end, ai.turn)
tbaby_walk11 = animation.frame("walk11", function() return tbaby_walk12 end, function(self) ai.walk(self, 2) end)
tbaby_walk12 = animation.frame("walk12", function() return tbaby_walk13 end, function(self) ai.walk(self, 2) end)
tbaby_walk13 = animation.frame("walk13", function() return tbaby_walk14 end, function(self) ai.walk(self, 2) end)
tbaby_walk14 = animation.frame("walk14", function() return tbaby_walk15 end, function(self) ai.walk(self, 2) end)
tbaby_walk15 = animation.frame("walk15", function() return tbaby_walk16 end, function(self) ai.walk(self, 2) end)
tbaby_walk16 = animation.frame("walk16", function() return tbaby_walk17 end, function(self) ai.walk(self, 2) end)
tbaby_walk17 = animation.frame("walk17", function() return tbaby_walk18 end, function(self) ai.walk(self, 2) end)
tbaby_walk18 = animation.frame("walk18", function() return tbaby_walk19 end, function(self) ai.walk(self, 2) end)
tbaby_walk19 = animation.frame("walk19", function() return tbaby_walk20 end, function(self) ai.walk(self, 2) end)
tbaby_walk20 = animation.frame("walk20", function() return tbaby_walk21 end, function(self) ai.walk(self, 2) end)
tbaby_walk21 = animation.frame("walk21", function() return tbaby_walk22 end, function(self) ai.walk(self, 2) end)
tbaby_walk22 = animation.frame("walk22", function() return tbaby_walk23 end, function(self) ai.walk(self, 2) end)
tbaby_walk23 = animation.frame("walk23", function() return tbaby_walk24 end, function(self) ai.walk(self, 2) end)
tbaby_walk24 = animation.frame("walk24", function() return tbaby_walk25 end, function(self) ai.walk(self, 2) end)
tbaby_walk25 = animation.frame("walk25", function() return tbaby_walk1 end, function(self) ai.walk(self, 2) end)

local tbaby_run1, tbaby_run2, tbaby_run3, tbaby_run4, tbaby_run5
local tbaby_run6, tbaby_run7, tbaby_run8, tbaby_run9, tbaby_run10
local tbaby_run11, tbaby_run12, tbaby_run13, tbaby_run14, tbaby_run15
local tbaby_run16, tbaby_run17, tbaby_run18, tbaby_run19, tbaby_run20
local tbaby_run21, tbaby_run22, tbaby_run23, tbaby_run24, tbaby_run25

tbaby_run1 = animation.frame("run1", function() return tbaby_run2 end, fight.face)
tbaby_run2 = animation.frame("run2", function() return tbaby_run3 end, fight.face)
tbaby_run3 = animation.frame("run3", function() return tbaby_run4 end, fight.face)
tbaby_run4 = animation.frame("run4", function() return tbaby_run5 end, fight.face)
tbaby_run5 = animation.frame("run5", function() return tbaby_run6 end, fight.face)
tbaby_run6 = animation.frame("run6", function() return tbaby_run7 end, fight.face)
tbaby_run7 = animation.frame("run7", function() return tbaby_run8 end, fight.face)
tbaby_run8 = animation.frame("run8", function() return tbaby_run9 end, fight.face)
tbaby_run9 = animation.frame("run9", function() return tbaby_run10 end, fight.face)
tbaby_run10 = animation.frame("run10", function() return tbaby_run11 end, fight.face)
tbaby_run11 = animation.frame("run11", function() return tbaby_run12 end, function(self) ai.run(self, 2) end)
tbaby_run12 = animation.frame("run12", function() return tbaby_run13 end, function(self) ai.run(self, 2) end)
tbaby_run13 = animation.frame("run13", function() return tbaby_run14 end, function(self) ai.run(self, 2) end)
tbaby_run14 = animation.frame("run14", function() return tbaby_run15 end, function(self) ai.run(self, 2) end)
tbaby_run15 = animation.frame("run15", function() return tbaby_run16 end, function(self) ai.run(self, 2) end)
tbaby_run16 = animation.frame("run16", function() return tbaby_run17 end, function(self) ai.run(self, 2) end)
tbaby_run17 = animation.frame("run17", function() return tbaby_run18 end, function(self) ai.run(self, 2) end)
tbaby_run18 = animation.frame("run18", function() return tbaby_run19 end, function(self) ai.run(self, 2) end)
tbaby_run19 = animation.frame("run19", function() return tbaby_run20 end, function(self) ai.run(self, 2) end)
tbaby_run20 = animation.frame("run20", function() return tbaby_run21 end, function(self) ai.run(self, 2) end)
tbaby_run21 = animation.frame("run21", function() return tbaby_run22 end, function(self) ai.run(self, 2) end)
tbaby_run22 = animation.frame("run22", function() return tbaby_run23 end, function(self) ai.run(self, 2) end)
tbaby_run23 = animation.frame("run23", function() return tbaby_run24 end, function(self) ai.run(self, 2) end)
tbaby_run24 = animation.frame("run24", function() return tbaby_run25 end, function(self) ai.run(self, 2) end)
tbaby_run25 = animation.frame("run25", function() return tbaby_run1 end, function(self) ai.run(self, 2) end)

--============================================================================

local tbaby_jump1

---@param self entity
---@param other entity
---@return nil
local function tar_jump_touch(self, other)
    if other.takedamage ~= 0 and other.classname ~= self.classname then
        if self.velocity:length() > 400 then
            local ldmg = 10 + 10 * quake.random()
            combat.damage(other, self, self, ldmg)
            quake.sound(self, 1, "blob/hit1.wav", 1, C.ATTN_NORM)
        end
    else
        quake.sound(self, 1, "blob/land1.wav", 1, C.ATTN_NORM)
    end

    if not quake.check_bottom(self) then
        if (self.flags & FL_ONGROUND) ~= 0 then
            -- jump randomly to not get hung up
            self.touch = subs.null
            self.think = tbaby_run1
            self.movetype = C.MOVETYPE_STEP
            self.nextthink = quake.time() + 0.1
        end
        return -- not on ground yet
    end

    self.touch = subs.null
    self.think = tbaby_jump1
    self.nextthink = quake.time() + 0.1
end

local tbaby_jump5

local tbaby_fly1, tbaby_fly2, tbaby_fly3, tbaby_fly4

tbaby_fly1 = animation.frame("fly1", function() return tbaby_fly2 end)
tbaby_fly2 = animation.frame("fly2", function() return tbaby_fly3 end)
tbaby_fly3 = animation.frame("fly3", function() return tbaby_fly4 end)
tbaby_fly4 = animation.frame("fly4", function() return tbaby_fly1 end, function(self)
    self.cnt = self.cnt + 1
    if self.cnt == 4 then
        tbaby_jump5(self)
    end
end)

local tbaby_jump2, tbaby_jump3, tbaby_jump4, tbaby_jump6

tbaby_jump1 = animation.frame("jump1", function() return tbaby_jump2 end, fight.face)
tbaby_jump2 = animation.frame("jump2", function() return tbaby_jump3 end, fight.face)
tbaby_jump3 = animation.frame("jump3", function() return tbaby_jump4 end, fight.face)
tbaby_jump4 = animation.frame("jump4", function() return tbaby_jump5 end, fight.face)
tbaby_jump5 = animation.frame("jump5", function() return tbaby_jump6 end, function(self)
    self.movetype = MOVETYPE_BOUNCE
    self.touch = tar_jump_touch
    local vectors = quake.make_vectors(self.angles)
    self.origin = self.origin + quake.vec3(0, 0, 1)
    self.velocity = vectors.forward * 600 + quake.vec3(0, 0, 200)
    self.velocity = self.velocity + quake.vec3(0, 0, quake.random() * 150)
    if (self.flags & FL_ONGROUND) ~= 0 then
        self.flags = self.flags - FL_ONGROUND
    end
    self.cnt = 0
end)
tbaby_jump6 = animation.frame("jump6", function() return tbaby_fly1 end)

--============================================================================

local tbaby_die1, tbaby_die2

tbaby_die1 = animation.frame("exp", function() return tbaby_die2 end, function(self)
    self.takedamage = C.DAMAGE_NO
end)
tbaby_die2 = animation.frame("exp", function() return tbaby_run1 end, function(self)
    combat.radius_damage(self, self, 120, quake.world)

    quake.sound(self, C.CHAN_VOICE, "blob/death1.wav", 1, C.ATTN_NORM)
    self.origin = self.origin - self.velocity:normalized() * 8

    quake.write_byte(0, 23)
    quake.write_byte(0, 11)
    quake.write_coord(0, self.origin.x)
    quake.write_coord(0, self.origin.y)
    quake.write_coord(0, self.origin.z)

    weapons.become_explosion(self)
end)

--============================================================================

---QUAKED monster_tarbaby (1 0 0) (-16 -16 -24) (16 16 24) Ambush
---@param self entity
---@return nil
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end
    quake.precache_model2("progs/tarbaby.mdl")

    quake.precache_sound2("blob/death1.wav")
    quake.precache_sound2("blob/hit1.wav")
    quake.precache_sound2("blob/land1.wav")
    quake.precache_sound2("blob/sight1.wav")

    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP

    quake.set_model(self, "progs/tarbaby.mdl")

    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 40))
    self.health = 80

    self.th_stand = tbaby_stand1
    self.th_walk = tbaby_walk1
    self.th_run = tbaby_run1
    self.th_missile = tbaby_jump1
    self.th_melee = tbaby_jump1
    self.th_die = tbaby_die1

    monsters.walk_start(self)
end

quake.register_entity("monster_tarbaby", M.spawn)

return M
