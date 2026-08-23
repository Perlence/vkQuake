--[[ Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

See file, 'COPYING', for details.
]]
-- Port of dog.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local ai = require("game.ai")
local animation = require("game.animation")
local combat = require("game.combat")
local fight = require("game.fight")
local gibs = require("game.gibs")
local monsters = require("game.monsters")
local subs = require("game.subs")

local M = {}

local count = animation.counter()
local f = {}

f.attack1, f.attack2, f.attack3, f.attack4, f.attack5, f.attack6,
    f.attack7, f.attack8 = count(8)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
    f.death7, f.death8, f.death9 = count(9)

f.deathb1, f.deathb2, f.deathb3, f.deathb4, f.deathb5, f.deathb6,
    f.deathb7, f.deathb8, f.deathb9 = count(9)

f.pain1, f.pain2, f.pain3, f.pain4, f.pain5, f.pain6 = count(6)

f.painb1, f.painb2, f.painb3, f.painb4, f.painb5, f.painb6,
    f.painb7, f.painb8, f.painb9, f.painb10, f.painb11, f.painb12,
    f.painb13, f.painb14, f.painb15, f.painb16 = count(16)

f.run1, f.run2, f.run3, f.run4, f.run5, f.run6,
    f.run7, f.run8, f.run9, f.run10, f.run11, f.run12 = count(12)

f.leap1, f.leap2, f.leap3, f.leap4, f.leap5, f.leap6,
    f.leap7, f.leap8, f.leap9 = count(9)

f.stand1, f.stand2, f.stand3, f.stand4, f.stand5, f.stand6,
    f.stand7, f.stand8, f.stand9 = count(9)

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
    f.walk7, f.walk8 = count(8)

--[[
==============================================================================

DOG (Rottweiler)

==============================================================================
]]

local dog_leap1, dog_run1
local dog_jump_touch

---@param self entity
---@return nil
local function dog_bite(self)
    if not self.enemy then
        return
    end

    fight.charge(self, 10)

    if not combat.can_damage(self.enemy, self) then
        return
    end

    local delta = self.enemy.origin - self.origin

    if delta:length() > 100 then
        return
    end

    local ldmg = (quake.random() + quake.random() + quake.random()) * 8
    combat.damage(self.enemy, self, self, ldmg)
end

---@param self entity
---@param other entity
---@return nil
function dog_jump_touch(self, other)
    if self.health <= 0 then
        return
    end

    if other.takedamage ~= 0 then
        if self.velocity:length() > 300 then
            local ldmg = 10 + 10 * quake.random()
            combat.damage(other, self, self, ldmg)
        end
    end

    if not quake.check_bottom(self) then
        if (self.flags & C.FL_ONGROUND) ~= 0 then
            -- jump randomly to not get hung up
            self.touch = subs.null
            self.think = dog_leap1
            self.nextthink = quake.time() + 0.1
        end
        return -- not on ground yet
    end

    self.touch = subs.null
    self.think = dog_run1
    self.nextthink = quake.time() + 0.1
end

local dog_stand1, dog_stand2, dog_stand3, dog_stand4, dog_stand5
local dog_stand6, dog_stand7, dog_stand8, dog_stand9

dog_stand1 = animation.frame(f.stand1, function() return dog_stand2 end, ai.stand)
dog_stand2 = animation.frame(f.stand2, function() return dog_stand3 end, ai.stand)
dog_stand3 = animation.frame(f.stand3, function() return dog_stand4 end, ai.stand)
dog_stand4 = animation.frame(f.stand4, function() return dog_stand5 end, ai.stand)
dog_stand5 = animation.frame(f.stand5, function() return dog_stand6 end, ai.stand)
dog_stand6 = animation.frame(f.stand6, function() return dog_stand7 end, ai.stand)
dog_stand7 = animation.frame(f.stand7, function() return dog_stand8 end, ai.stand)
dog_stand8 = animation.frame(f.stand8, function() return dog_stand9 end, ai.stand)
dog_stand9 = animation.frame(f.stand9, function() return dog_stand1 end, ai.stand)

local dog_walk1, dog_walk2, dog_walk3, dog_walk4, dog_walk5, dog_walk6, dog_walk7, dog_walk8

dog_walk1 = animation.frame(f.walk1, function() return dog_walk2 end, function(self)
    if quake.random() < 0.2 then
        quake.sound(self, C.CHAN_VOICE, "dog/idle.wav", 1, C.ATTN_IDLE)
    end
    ai.walk(self, 8)
end)
dog_walk2 = animation.frame(f.walk2, function() return dog_walk3 end, function(self) ai.walk(self, 8) end)
dog_walk3 = animation.frame(f.walk3, function() return dog_walk4 end, function(self) ai.walk(self, 8) end)
dog_walk4 = animation.frame(f.walk4, function() return dog_walk5 end, function(self) ai.walk(self, 8) end)
dog_walk5 = animation.frame(f.walk5, function() return dog_walk6 end, function(self) ai.walk(self, 8) end)
dog_walk6 = animation.frame(f.walk6, function() return dog_walk7 end, function(self) ai.walk(self, 8) end)
dog_walk7 = animation.frame(f.walk7, function() return dog_walk8 end, function(self) ai.walk(self, 8) end)
dog_walk8 = animation.frame(f.walk8, function() return dog_walk1 end, function(self) ai.walk(self, 8) end)

local dog_run2, dog_run3, dog_run4, dog_run5, dog_run6, dog_run7, dog_run8
local dog_run9, dog_run10, dog_run11, dog_run12

dog_run1 = animation.frame(f.run1, function() return dog_run2 end, function(self)
    if quake.random() < 0.2 then
        quake.sound(self, C.CHAN_VOICE, "dog/idle.wav", 1, C.ATTN_IDLE)
    end
    ai.run(self, 16)
end)
dog_run2 = animation.frame(f.run2, function() return dog_run3 end, function(self) ai.run(self, 32) end)
dog_run3 = animation.frame(f.run3, function() return dog_run4 end, function(self) ai.run(self, 32) end)
dog_run4 = animation.frame(f.run4, function() return dog_run5 end, function(self) ai.run(self, 20) end)
dog_run5 = animation.frame(f.run5, function() return dog_run6 end, function(self) ai.run(self, 64) end)
dog_run6 = animation.frame(f.run6, function() return dog_run7 end, function(self) ai.run(self, 32) end)
dog_run7 = animation.frame(f.run7, function() return dog_run8 end, function(self) ai.run(self, 16) end)
dog_run8 = animation.frame(f.run8, function() return dog_run9 end, function(self) ai.run(self, 32) end)
dog_run9 = animation.frame(f.run9, function() return dog_run10 end, function(self) ai.run(self, 32) end)
dog_run10 = animation.frame(f.run10, function() return dog_run11 end, function(self) ai.run(self, 20) end)
dog_run11 = animation.frame(f.run11, function() return dog_run12 end, function(self) ai.run(self, 64) end)
dog_run12 = animation.frame(f.run12, function() return dog_run1 end, function(self) ai.run(self, 32) end)

local dog_atta1, dog_atta2, dog_atta3, dog_atta4, dog_atta5, dog_atta6, dog_atta7, dog_atta8

dog_atta1 = animation.frame(f.attack1, function() return dog_atta2 end, function(self) fight.charge(self, 10) end)
dog_atta2 = animation.frame(f.attack2, function() return dog_atta3 end, function(self) fight.charge(self, 10) end)
dog_atta3 = animation.frame(f.attack3, function() return dog_atta4 end, function(self) fight.charge(self, 10) end)
dog_atta4 = animation.frame(f.attack4, function() return dog_atta5 end, function(self)
    quake.sound(self, C.CHAN_VOICE, "dog/dattack1.wav", 1, C.ATTN_NORM)
    dog_bite(self)
end)
dog_atta5 = animation.frame(f.attack5, function() return dog_atta6 end, function(self) fight.charge(self, 10) end)
dog_atta6 = animation.frame(f.attack6, function() return dog_atta7 end, function(self) fight.charge(self, 10) end)
dog_atta7 = animation.frame(f.attack7, function() return dog_atta8 end, function(self) fight.charge(self, 10) end)
dog_atta8 = animation.frame(f.attack8, function() return dog_run1 end, function(self) fight.charge(self, 10) end)

local dog_leap2, dog_leap3, dog_leap4, dog_leap5, dog_leap6, dog_leap7, dog_leap8, dog_leap9

dog_leap1 = animation.frame(f.leap1, function() return dog_leap2 end, fight.face)
dog_leap2 = animation.frame(f.leap2, function() return dog_leap3 end, function(self)
    fight.face(self)

    self.touch = dog_jump_touch
    local vectors = quake.make_vectors(self.angles)
    self.origin = self.origin + quake.vec3(0, 0, 1)
    self.velocity = vectors.forward * 300 + quake.vec3(0, 0, 200)
    if (self.flags & C.FL_ONGROUND) ~= 0 then
        self.flags = self.flags - C.FL_ONGROUND
    end
end)
dog_leap3 = animation.frame(f.leap3, function() return dog_leap4 end)
dog_leap4 = animation.frame(f.leap4, function() return dog_leap5 end)
dog_leap5 = animation.frame(f.leap5, function() return dog_leap6 end)
dog_leap6 = animation.frame(f.leap6, function() return dog_leap7 end)
dog_leap7 = animation.frame(f.leap7, function() return dog_leap8 end)
dog_leap8 = animation.frame(f.leap8, function() return dog_leap9 end)
dog_leap9 = animation.frame(f.leap9, function() return dog_leap9 end)

local dog_pain1, dog_pain2, dog_pain3, dog_pain4, dog_pain5, dog_pain6

dog_pain1 = animation.frame(f.pain1, function() return dog_pain2 end)
dog_pain2 = animation.frame(f.pain2, function() return dog_pain3 end)
dog_pain3 = animation.frame(f.pain3, function() return dog_pain4 end)
dog_pain4 = animation.frame(f.pain4, function() return dog_pain5 end)
dog_pain5 = animation.frame(f.pain5, function() return dog_pain6 end)
dog_pain6 = animation.frame(f.pain6, function() return dog_run1 end)

local dog_painb1, dog_painb2, dog_painb3, dog_painb4, dog_painb5, dog_painb6
local dog_painb7, dog_painb8, dog_painb9, dog_painb10, dog_painb11, dog_painb12
local dog_painb13, dog_painb14, dog_painb15, dog_painb16

dog_painb1 = animation.frame(f.painb1, function() return dog_painb2 end)
dog_painb2 = animation.frame(f.painb2, function() return dog_painb3 end)
dog_painb3 = animation.frame(f.painb3, function() return dog_painb4 end, function(self) ai.pain(self, 4) end)
dog_painb4 = animation.frame(f.painb4, function() return dog_painb5 end, function(self) ai.pain(self, 12) end)
dog_painb5 = animation.frame(f.painb5, function() return dog_painb6 end, function(self) ai.pain(self, 12) end)
dog_painb6 = animation.frame(f.painb6, function() return dog_painb7 end, function(self) ai.pain(self, 2) end)
dog_painb7 = animation.frame(f.painb7, function() return dog_painb8 end)
dog_painb8 = animation.frame(f.painb8, function() return dog_painb9 end, function(self) ai.pain(self, 4) end)
dog_painb9 = animation.frame(f.painb9, function() return dog_painb10 end)
dog_painb10 = animation.frame(f.painb10, function() return dog_painb11 end, function(self) ai.pain(self, 10) end)
dog_painb11 = animation.frame(f.painb11, function() return dog_painb12 end)
dog_painb12 = animation.frame(f.painb12, function() return dog_painb13 end)
dog_painb13 = animation.frame(f.painb13, function() return dog_painb14 end)
dog_painb14 = animation.frame(f.painb14, function() return dog_painb15 end)
dog_painb15 = animation.frame(f.painb15, function() return dog_painb16 end)
dog_painb16 = animation.frame(f.painb16, function() return dog_run1 end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function dog_pain(self, _attacker, _damage)
    quake.sound(self, C.CHAN_VOICE, "dog/dpain1.wav", 1, C.ATTN_NORM)

    if quake.random() > 0.5 then
        dog_pain1(self)
    else
        dog_painb1(self)
    end
end

local dog_die1, dog_die2, dog_die3, dog_die4, dog_die5, dog_die6, dog_die7, dog_die8, dog_die9

dog_die1 = animation.frame(f.death1, function() return dog_die2 end)
dog_die2 = animation.frame(f.death2, function() return dog_die3 end)
dog_die3 = animation.frame(f.death3, function() return dog_die4 end)
dog_die4 = animation.frame(f.death4, function() return dog_die5 end)
dog_die5 = animation.frame(f.death5, function() return dog_die6 end)
dog_die6 = animation.frame(f.death6, function() return dog_die7 end)
dog_die7 = animation.frame(f.death7, function() return dog_die8 end)
dog_die8 = animation.frame(f.death8, function() return dog_die9 end)
dog_die9 = animation.frame(f.death9, function() return dog_die9 end)

local dog_dieb1, dog_dieb2, dog_dieb3, dog_dieb4, dog_dieb5, dog_dieb6, dog_dieb7, dog_dieb8, dog_dieb9

dog_dieb1 = animation.frame(f.deathb1, function() return dog_dieb2 end)
dog_dieb2 = animation.frame(f.deathb2, function() return dog_dieb3 end)
dog_dieb3 = animation.frame(f.deathb3, function() return dog_dieb4 end)
dog_dieb4 = animation.frame(f.deathb4, function() return dog_dieb5 end)
dog_dieb5 = animation.frame(f.deathb5, function() return dog_dieb6 end)
dog_dieb6 = animation.frame(f.deathb6, function() return dog_dieb7 end)
dog_dieb7 = animation.frame(f.deathb7, function() return dog_dieb8 end)
dog_dieb8 = animation.frame(f.deathb8, function() return dog_dieb9 end)
dog_dieb9 = animation.frame(f.deathb9, function() return dog_dieb9 end)

---@param self entity
---@return nil
local function dog_die(self)
    -- check for gib
    if self.health < -35 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        gibs.throw_head(self, "progs/h_dog.mdl", self.health)
        return
    end

    -- regular death
    quake.sound(self, C.CHAN_VOICE, "dog/ddeath.wav", 1, C.ATTN_NORM)
    self.solid = C.SOLID_NOT

    if quake.random() > 0.5 then
        dog_die1(self)
    else
        dog_dieb1(self)
    end
end

--============================================================================

---Returns TRUE if a melee attack would hit right now
---@param self entity
---@return boolean
local function check_dog_melee(self)
    if quake.globals.enemy_range == C.RANGE_MELEE then
        -- FIXME: check canreach
        self.attack_state = C.AS_MELEE
        return true
    end
    return false
end

---@param self entity
---@return boolean
local function check_dog_jump(self)
    if self.origin.z + self.mins.z > self.enemy.origin.z + self.enemy.mins.z + 0.75 * self.enemy.size.z then
        return false
    end

    if self.origin.z + self.maxs.z < self.enemy.origin.z + self.enemy.mins.z + 0.25 * self.enemy.size.z then
        return false
    end

    local dist = self.enemy.origin - self.origin
    dist = quake.vec3(dist.x, dist.y, 0)

    local d = dist:length()

    if d < 80 then
        return false
    end

    if d > 150 then
        return false
    end

    return true
end

---@param self entity
---@return boolean
function M.check_attack(self)
    -- if close enough for slashing, go for it
    if check_dog_melee(self) then
        self.attack_state = C.AS_MELEE
        return true
    end

    if check_dog_jump(self) then
        self.attack_state = C.AS_MISSILE
        return true
    end

    return false
end

--===========================================================================

---QUAKED monster_dog (1 0 0) (-32 -32 -24) (32 32 40) Ambush
---@param self entity
---@return nil
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end
    quake.precache_model("progs/h_dog.mdl")
    quake.precache_model("progs/dog.mdl")

    quake.precache_sound("dog/dattack1.wav")
    quake.precache_sound("dog/ddeath.wav")
    quake.precache_sound("dog/dpain1.wav")
    quake.precache_sound("dog/dsight.wav")
    quake.precache_sound("dog/idle.wav")

    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP

    quake.set_model(self, "progs/dog.mdl")

    quake.set_size(self, quake.vec3(-32, -32, -24), quake.vec3(32, 32, 40))
    self.health = 25

    self.th_stand = dog_stand1
    self.th_walk = dog_walk1
    self.th_run = dog_run1
    self.th_pain = dog_pain
    self.th_die = dog_die
    self.th_melee = dog_atta1
    self.th_missile = dog_leap1
    self.check_attack = M.check_attack
    monsters.walk_start(self)
end

quake.register_entity("monster_dog", M.spawn)

return M
