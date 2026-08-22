-- Port of shalrath.qc from GPL-licensed CleanFixedQuakeC.
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
local animation = require("game.animation")
local combat = require("game.combat")
local fight = require("game.fight")
local gibs = require("game.gibs")
local monsters = require("game.monsters")
local subs = require("game.subs")
local weapons = require("game.weapons")

local M = {}
local ATTN_IDLE = 2
local CHAN_WEAPON = 1
local DAMAGE_YES = 1
local EF_MUZZLEFLASH = 2
local MOVETYPE_FLYMISSILE = 9
local SOLID_BBOX = 2

--[[
==============================================================================

SHAL-RATH (Vore)

==============================================================================
]]

local shal_missile

local shal_stand
shal_stand = animation.frame("walk1", function() return shal_stand end, ai.stand)

local shal_walk1, shal_walk2, shal_walk3, shal_walk4, shal_walk5, shal_walk6
local shal_walk7, shal_walk8, shal_walk9, shal_walk10, shal_walk11, shal_walk12

shal_walk1 = animation.frame("walk2", function() return shal_walk2 end, function(self)
    if quake.random() < 0.2 then
        quake.sound(self, C.CHAN_VOICE, "shalrath/idle.wav", 1, ATTN_IDLE)
    end
    ai.walk(self, 6)
end)
shal_walk2 = animation.frame("walk3", function() return shal_walk3 end, function(self) ai.walk(self, 4) end)
shal_walk3 = animation.frame("walk4", function() return shal_walk4 end, function(self) ai.walk(self, 0) end)
shal_walk4 = animation.frame("walk5", function() return shal_walk5 end, function(self) ai.walk(self, 0) end)
shal_walk5 = animation.frame("walk6", function() return shal_walk6 end, function(self) ai.walk(self, 0) end)
shal_walk6 = animation.frame("walk7", function() return shal_walk7 end, function(self) ai.walk(self, 0) end)
shal_walk7 = animation.frame("walk8", function() return shal_walk8 end, function(self) ai.walk(self, 5) end)
shal_walk8 = animation.frame("walk9", function() return shal_walk9 end, function(self) ai.walk(self, 6) end)
shal_walk9 = animation.frame("walk10", function() return shal_walk10 end, function(self) ai.walk(self, 5) end)
shal_walk10 = animation.frame("walk11", function() return shal_walk11 end, function(self) ai.walk(self, 0) end)
shal_walk11 = animation.frame("walk12", function() return shal_walk12 end, function(self) ai.walk(self, 4) end)
shal_walk12 = animation.frame("walk1", function() return shal_walk1 end, function(self) ai.walk(self, 5) end)

local shal_run1, shal_run2, shal_run3, shal_run4, shal_run5, shal_run6
local shal_run7, shal_run8, shal_run9, shal_run10, shal_run11, shal_run12

shal_run1 = animation.frame("walk2", function() return shal_run2 end, function(self)
    if quake.random() < 0.2 then
        quake.sound(self, C.CHAN_VOICE, "shalrath/idle.wav", 1, ATTN_IDLE)
    end
    ai.run(self, 6)
end)
shal_run2 = animation.frame("walk3", function() return shal_run3 end, function(self) ai.run(self, 4) end)
shal_run3 = animation.frame("walk4", function() return shal_run4 end, function(self) ai.run(self, 0) end)
shal_run4 = animation.frame("walk5", function() return shal_run5 end, function(self) ai.run(self, 0) end)
shal_run5 = animation.frame("walk6", function() return shal_run6 end, function(self) ai.run(self, 0) end)
shal_run6 = animation.frame("walk7", function() return shal_run7 end, function(self) ai.run(self, 0) end)
shal_run7 = animation.frame("walk8", function() return shal_run8 end, function(self) ai.run(self, 5) end)
shal_run8 = animation.frame("walk9", function() return shal_run9 end, function(self) ai.run(self, 6) end)
shal_run9 = animation.frame("walk10", function() return shal_run10 end, function(self) ai.run(self, 5) end)
shal_run10 = animation.frame("walk11", function() return shal_run11 end, function(self) ai.run(self, 0) end)
shal_run11 = animation.frame("walk12", function() return shal_run12 end, function(self) ai.run(self, 4) end)
shal_run12 = animation.frame("walk1", function() return shal_run1 end, function(self) ai.run(self, 5) end)

local shal_missile
local shal_attack1, shal_attack2, shal_attack3, shal_attack4, shal_attack5, shal_attack6
local shal_attack7, shal_attack8, shal_attack9, shal_attack10, shal_attack11

shal_attack1 = animation.frame("attack1", function() return shal_attack2 end, function(self)
    quake.sound(self, C.CHAN_VOICE, "shalrath/attack.wav", 1, C.ATTN_NORM)
    fight.face(self)
end)
shal_attack2 = animation.frame("attack2", function() return shal_attack3 end, fight.face)
shal_attack3 = animation.frame("attack3", function() return shal_attack4 end, fight.face)
shal_attack4 = animation.frame("attack4", function() return shal_attack5 end, fight.face)
shal_attack5 = animation.frame("attack5", function() return shal_attack6 end, fight.face)
shal_attack6 = animation.frame("attack6", function() return shal_attack7 end, fight.face)
shal_attack7 = animation.frame("attack7", function() return shal_attack8 end, fight.face)
shal_attack8 = animation.frame("attack8", function() return shal_attack9 end, fight.face)
shal_attack9 = animation.frame("attack9", function() return shal_attack10 end, function(self) shal_missile(self) end)
shal_attack10 = animation.frame("attack10", function() return shal_attack11 end, fight.face)
shal_attack11 = animation.frame("attack11", function() return shal_run1 end)

local shal_pain1, shal_pain2, shal_pain3, shal_pain4, shal_pain5

shal_pain1 = animation.frame("pain1", function() return shal_pain2 end)
shal_pain2 = animation.frame("pain2", function() return shal_pain3 end)
shal_pain3 = animation.frame("pain3", function() return shal_pain4 end)
shal_pain4 = animation.frame("pain4", function() return shal_pain5 end)
shal_pain5 = animation.frame("pain5", function() return shal_run1 end)

local shal_death1, shal_death2, shal_death3, shal_death4, shal_death5, shal_death6
local shal_death7

shal_death1 = animation.frame("death1", function() return shal_death2 end)
shal_death2 = animation.frame("death2", function() return shal_death3 end)
shal_death3 = animation.frame("death3", function() return shal_death4 end)
shal_death4 = animation.frame("death4", function() return shal_death5 end)
shal_death5 = animation.frame("death5", function() return shal_death6 end)
shal_death6 = animation.frame("death6", function() return shal_death7 end)
shal_death7 = animation.frame("death7", function() return shal_death7 end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function shalrath_pain(self, _attacker, _damage)
    if self.pain_finished > quake.time() then
        return
    end

    quake.sound(self, C.CHAN_VOICE, "shalrath/pain.wav", 1, C.ATTN_NORM)
    shal_pain1(self)
    self.pain_finished = quake.time() + 3
end

---@param self entity
---@return nil
local function shalrath_die(self)
    -- check for gib
    if self.health < -90 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw_head(self, "progs/h_shal.mdl", self.health)
        gibs.throw(self, "progs/gib1.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        return
    end

    quake.sound(self, C.CHAN_VOICE, "shalrath/death.wav", 1, C.ATTN_NORM)
    shal_death1(self)
    self.solid = C.SOLID_NOT
end

--[[
================
ShalMissile
================
]]
local shal_missile_touch
local shal_home

---@param self entity
---@return nil
function shal_missile(self)
    local dir = (self.enemy.origin + quake.vec3(0, 0, 10) - self.origin):normalized()
    local dist = (self.enemy.origin - self.origin):length()
    local flytime = dist * 0.002
    if flytime < 0.1 then
        flytime = 0.1
    end

    self.effects = self.effects | EF_MUZZLEFLASH
    quake.sound(self, CHAN_WEAPON, "shalrath/attack2.wav", 1, C.ATTN_NORM)

    local missile = quake.spawn()
    missile.owner = self

    missile.solid = SOLID_BBOX
    missile.movetype = MOVETYPE_FLYMISSILE
    quake.set_model(missile, "progs/v_spike.mdl")

    quake.set_size(missile, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))

    missile.origin = self.origin + quake.vec3(0, 0, 10)
    missile.velocity = dir * 400
    missile.avelocity = quake.vec3(300, 300, 300)
    missile.nextthink = flytime + quake.time()
    missile.think = shal_home
    missile.enemy = self.enemy
    missile.touch = shal_missile_touch
end

---@param self entity
---@return nil
shal_home = function(self)
    local vtemp = self.enemy.origin + quake.vec3(0, 0, 10)
    if self.enemy.health < 1 then
        quake.remove(self)
        return
    end
    local dir = (vtemp - self.origin):normalized()
    if quake.cvar("skill") == 3 then
        self.velocity = dir * 350
    else
        self.velocity = dir * 250
    end
    self.nextthink = quake.time() + 0.2
    self.think = shal_home
end

---@param self entity
---@param other entity
---@return nil
shal_missile_touch = function(self, other)
    if other == self.owner then
        -- don't explode on owner
        return
    end

    if other.classname == "monster_zombie" then
        combat.damage(other, self, self, 110)
    end
    combat.radius_damage(self, self.owner, 40, quake.world)
    quake.sound(self, CHAN_WEAPON, "weapons/r_exp3.wav", 1, C.ATTN_NORM)

    quake.write_byte(0, 23)
    quake.write_byte(0, 3)
    quake.write_coord(0, self.origin.x)
    quake.write_coord(0, self.origin.y)
    quake.write_coord(0, self.origin.z)

    self.velocity = quake.vec3(0, 0, 0)
    self.touch = subs.null
    quake.set_model(self, "progs/s_explod.spr")
    self.solid = C.SOLID_NOT
    weapons.explode(self)
end

--=================================================================

---QUAKED monster_shalrath (1 0 0) (-32 -32 -24) (32 32 48) Ambush
---@param self entity
---@return nil
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end
    quake.precache_model2("progs/shalrath.mdl")
    quake.precache_model2("progs/h_shal.mdl")
    quake.precache_model2("progs/v_spike.mdl")

    quake.precache_sound2("shalrath/attack.wav")
    quake.precache_sound2("shalrath/attack2.wav")
    quake.precache_sound2("shalrath/death.wav")
    quake.precache_sound2("shalrath/idle.wav")
    quake.precache_sound2("shalrath/pain.wav")
    quake.precache_sound2("shalrath/sight.wav")

    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP

    quake.set_model(self, "progs/shalrath.mdl")
    quake.set_size(self, quake.vec3(-32, -32, -24), quake.vec3(32, 32, 64))
    self.health = 400

    self.th_stand = shal_stand
    self.th_walk = shal_walk1
    self.th_run = shal_run1
    self.th_die = shalrath_die
    self.th_pain = shalrath_pain
    self.th_missile = shal_attack1

    self.think = monsters.walk_start
    self.nextthink = quake.time() + 0.1 + quake.random() * 0.1
end

quake.register_entity("monster_shalrath", M.spawn)

return M
