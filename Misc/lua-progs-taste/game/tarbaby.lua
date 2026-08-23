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

local count = animation.counter()
local f = {}

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
    f.walk7, f.walk8, f.walk9, f.walk10, f.walk11, f.walk12,
    f.walk13, f.walk14, f.walk15, f.walk16, f.walk17, f.walk18,
    f.walk19, f.walk20, f.walk21, f.walk22, f.walk23, f.walk24,
    f.walk25 = count(25)

f.run1, f.run2, f.run3, f.run4, f.run5, f.run6,
    f.run7, f.run8, f.run9, f.run10, f.run11, f.run12,
    f.run13, f.run14, f.run15, f.run16, f.run17, f.run18,
    f.run19, f.run20, f.run21, f.run22, f.run23, f.run24,
    f.run25 = count(25)

f.jump1, f.jump2, f.jump3, f.jump4, f.jump5, f.jump6 = count(6)

f.fly1, f.fly2, f.fly3, f.fly4 = count(4)

f.exp = count(1)

local FL_ONGROUND = 512
local MOVETYPE_BOUNCE = 10

--[[
==============================================================================

BLOB (Spawn)

==============================================================================
]]

local tbaby_stand1
tbaby_stand1 = animation.frame(f.walk1, function() return tbaby_stand1 end, ai.stand)

local tbaby_hang1
tbaby_hang1 = animation.frame(f.walk1, function() return tbaby_hang1 end, ai.stand)

local tbaby_walk = {}
tbaby_walk[1] = animation.frame(f.walk1, function() return tbaby_walk[2] end, ai.turn)
tbaby_walk[2] = animation.frame(f.walk2, function() return tbaby_walk[3] end, ai.turn)
tbaby_walk[3] = animation.frame(f.walk3, function() return tbaby_walk[4] end, ai.turn)
tbaby_walk[4] = animation.frame(f.walk4, function() return tbaby_walk[5] end, ai.turn)
tbaby_walk[5] = animation.frame(f.walk5, function() return tbaby_walk[6] end, ai.turn)
tbaby_walk[6] = animation.frame(f.walk6, function() return tbaby_walk[7] end, ai.turn)
tbaby_walk[7] = animation.frame(f.walk7, function() return tbaby_walk[8] end, ai.turn)
tbaby_walk[8] = animation.frame(f.walk8, function() return tbaby_walk[9] end, ai.turn)
tbaby_walk[9] = animation.frame(f.walk9, function() return tbaby_walk[10] end, ai.turn)
tbaby_walk[10] = animation.frame(f.walk10, function() return tbaby_walk[11] end, ai.turn)
tbaby_walk[11] = animation.frame(f.walk11, function() return tbaby_walk[12] end, function(self) ai.walk(self, 2) end)
tbaby_walk[12] = animation.frame(f.walk12, function() return tbaby_walk[13] end, function(self) ai.walk(self, 2) end)
tbaby_walk[13] = animation.frame(f.walk13, function() return tbaby_walk[14] end, function(self) ai.walk(self, 2) end)
tbaby_walk[14] = animation.frame(f.walk14, function() return tbaby_walk[15] end, function(self) ai.walk(self, 2) end)
tbaby_walk[15] = animation.frame(f.walk15, function() return tbaby_walk[16] end, function(self) ai.walk(self, 2) end)
tbaby_walk[16] = animation.frame(f.walk16, function() return tbaby_walk[17] end, function(self) ai.walk(self, 2) end)
tbaby_walk[17] = animation.frame(f.walk17, function() return tbaby_walk[18] end, function(self) ai.walk(self, 2) end)
tbaby_walk[18] = animation.frame(f.walk18, function() return tbaby_walk[19] end, function(self) ai.walk(self, 2) end)
tbaby_walk[19] = animation.frame(f.walk19, function() return tbaby_walk[20] end, function(self) ai.walk(self, 2) end)
tbaby_walk[20] = animation.frame(f.walk20, function() return tbaby_walk[21] end, function(self) ai.walk(self, 2) end)
tbaby_walk[21] = animation.frame(f.walk21, function() return tbaby_walk[22] end, function(self) ai.walk(self, 2) end)
tbaby_walk[22] = animation.frame(f.walk22, function() return tbaby_walk[23] end, function(self) ai.walk(self, 2) end)
tbaby_walk[23] = animation.frame(f.walk23, function() return tbaby_walk[24] end, function(self) ai.walk(self, 2) end)
tbaby_walk[24] = animation.frame(f.walk24, function() return tbaby_walk[25] end, function(self) ai.walk(self, 2) end)
tbaby_walk[25] = animation.frame(f.walk25, function() return tbaby_walk[1] end, function(self) ai.walk(self, 2) end)

local tbaby_run = {}
tbaby_run[1] = animation.frame(f.run1, function() return tbaby_run[2] end, fight.face)
tbaby_run[2] = animation.frame(f.run2, function() return tbaby_run[3] end, fight.face)
tbaby_run[3] = animation.frame(f.run3, function() return tbaby_run[4] end, fight.face)
tbaby_run[4] = animation.frame(f.run4, function() return tbaby_run[5] end, fight.face)
tbaby_run[5] = animation.frame(f.run5, function() return tbaby_run[6] end, fight.face)
tbaby_run[6] = animation.frame(f.run6, function() return tbaby_run[7] end, fight.face)
tbaby_run[7] = animation.frame(f.run7, function() return tbaby_run[8] end, fight.face)
tbaby_run[8] = animation.frame(f.run8, function() return tbaby_run[9] end, fight.face)
tbaby_run[9] = animation.frame(f.run9, function() return tbaby_run[10] end, fight.face)
tbaby_run[10] = animation.frame(f.run10, function() return tbaby_run[11] end, fight.face)
tbaby_run[11] = animation.frame(f.run11, function() return tbaby_run[12] end, function(self) ai.run(self, 2) end)
tbaby_run[12] = animation.frame(f.run12, function() return tbaby_run[13] end, function(self) ai.run(self, 2) end)
tbaby_run[13] = animation.frame(f.run13, function() return tbaby_run[14] end, function(self) ai.run(self, 2) end)
tbaby_run[14] = animation.frame(f.run14, function() return tbaby_run[15] end, function(self) ai.run(self, 2) end)
tbaby_run[15] = animation.frame(f.run15, function() return tbaby_run[16] end, function(self) ai.run(self, 2) end)
tbaby_run[16] = animation.frame(f.run16, function() return tbaby_run[17] end, function(self) ai.run(self, 2) end)
tbaby_run[17] = animation.frame(f.run17, function() return tbaby_run[18] end, function(self) ai.run(self, 2) end)
tbaby_run[18] = animation.frame(f.run18, function() return tbaby_run[19] end, function(self) ai.run(self, 2) end)
tbaby_run[19] = animation.frame(f.run19, function() return tbaby_run[20] end, function(self) ai.run(self, 2) end)
tbaby_run[20] = animation.frame(f.run20, function() return tbaby_run[21] end, function(self) ai.run(self, 2) end)
tbaby_run[21] = animation.frame(f.run21, function() return tbaby_run[22] end, function(self) ai.run(self, 2) end)
tbaby_run[22] = animation.frame(f.run22, function() return tbaby_run[23] end, function(self) ai.run(self, 2) end)
tbaby_run[23] = animation.frame(f.run23, function() return tbaby_run[24] end, function(self) ai.run(self, 2) end)
tbaby_run[24] = animation.frame(f.run24, function() return tbaby_run[25] end, function(self) ai.run(self, 2) end)
tbaby_run[25] = animation.frame(f.run25, function() return tbaby_run[1] end, function(self) ai.run(self, 2) end)

--============================================================================

local tbaby_jump = {}

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
            self.think = tbaby_run[1]
            self.movetype = C.MOVETYPE_STEP
            self.nextthink = quake.time() + 0.1
        end
        return -- not on ground yet
    end

    self.touch = subs.null
    self.think = tbaby_jump[1]
    self.nextthink = quake.time() + 0.1
end



local tbaby_fly = {}
tbaby_fly[1] = animation.frame(f.fly1, function() return tbaby_fly[2] end)
tbaby_fly[2] = animation.frame(f.fly2, function() return tbaby_fly[3] end)
tbaby_fly[3] = animation.frame(f.fly3, function() return tbaby_fly[4] end)
tbaby_fly[4] = animation.frame(f.fly4, function() return tbaby_fly[1] end, function(self)
    self.cnt = self.cnt + 1
    if self.cnt == 4 then
        tbaby_jump[5](self)
    end
end)

tbaby_jump[1] = animation.frame(f.jump1, function() return tbaby_jump[2] end, fight.face)
tbaby_jump[2] = animation.frame(f.jump2, function() return tbaby_jump[3] end, fight.face)
tbaby_jump[3] = animation.frame(f.jump3, function() return tbaby_jump[4] end, fight.face)
tbaby_jump[4] = animation.frame(f.jump4, function() return tbaby_jump[5] end, fight.face)
tbaby_jump[5] = animation.frame(f.jump5, function() return tbaby_jump[6] end, function(self)
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
tbaby_jump[6] = animation.frame(f.jump6, function() return tbaby_fly[1] end)

--============================================================================

local tbaby_die = {}
tbaby_die[1] = animation.frame(f.exp, function() return tbaby_die[2] end, function(self)
    self.takedamage = C.DAMAGE_NO
end)
tbaby_die[2] = animation.frame(f.exp, function() return tbaby_run[1] end, function(self)
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
    self.th_walk = tbaby_walk[1]
    self.th_run = tbaby_run[1]
    self.th_missile = tbaby_jump[1]
    self.th_melee = tbaby_jump[1]
    self.th_die = tbaby_die[1]

    monsters.walk_start(self)
end

quake.register_entity("monster_tarbaby", M.spawn)

return M
