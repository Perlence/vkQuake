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

local dog_leap, dog_run

---@param self entity
---@param other entity
---@return nil
local dog_jump_touch = quake.register_function("dog.dog_jump_touch", function(self, other)
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
            self.think = dog_leap
            self.nextthink = quake.time() + 0.1
        end
        return -- not on ground yet
    end

    self.touch = subs.null
    self.think = dog_run
    self.nextthink = quake.time() + 0.1
end)

local dog_stand = animation.loop("dog.dog_stand", {
    { f.stand1, ai.stand },
    { f.stand2, ai.stand },
    { f.stand3, ai.stand },
    { f.stand4, ai.stand },
    { f.stand5, ai.stand },
    { f.stand6, ai.stand },
    { f.stand7, ai.stand },
    { f.stand8, ai.stand },
    { f.stand9, ai.stand },
})

local dog_walk = animation.loop("dog.dog_walk", {
    { f.walk1, function(self)
        if quake.random() < 0.2 then
            quake.sound(self, C.CHAN_VOICE, "dog/idle.wav", 1, C.ATTN_IDLE)
        end
        ai.walk(self, 8)
    end },
    { f.walk2, function(self) ai.walk(self, 8) end },
    { f.walk3, function(self) ai.walk(self, 8) end },
    { f.walk4, function(self) ai.walk(self, 8) end },
    { f.walk5, function(self) ai.walk(self, 8) end },
    { f.walk6, function(self) ai.walk(self, 8) end },
    { f.walk7, function(self) ai.walk(self, 8) end },
    { f.walk8, function(self) ai.walk(self, 8) end },
})

dog_run = animation.loop("dog.dog_run", {
    { f.run1, function(self)
        if quake.random() < 0.2 then
            quake.sound(self, C.CHAN_VOICE, "dog/idle.wav", 1, C.ATTN_IDLE)
        end
        ai.run(self, 16)
    end },
    { f.run2, function(self) ai.run(self, 32) end },
    { f.run3, function(self) ai.run(self, 32) end },
    { f.run4, function(self) ai.run(self, 20) end },
    { f.run5, function(self) ai.run(self, 64) end },
    { f.run6, function(self) ai.run(self, 32) end },
    { f.run7, function(self) ai.run(self, 16) end },
    { f.run8, function(self) ai.run(self, 32) end },
    { f.run9, function(self) ai.run(self, 32) end },
    { f.run10, function(self) ai.run(self, 20) end },
    { f.run11, function(self) ai.run(self, 64) end },
    { f.run12, function(self) ai.run(self, 32) end },
})

local dog_atta = animation.sequence("dog.dog_atta", {
    { f.attack1, function(self) fight.charge(self, 10) end },
    { f.attack2, function(self) fight.charge(self, 10) end },
    { f.attack3, function(self) fight.charge(self, 10) end },
    { f.attack4, function(self)
        quake.sound(self, C.CHAN_VOICE, "dog/dattack1.wav", 1, C.ATTN_NORM)
        dog_bite(self)
    end },
    { f.attack5, function(self) fight.charge(self, 10) end },
    { f.attack6, function(self) fight.charge(self, 10) end },
    { f.attack7, function(self) fight.charge(self, 10) end },
    { f.attack8, function(self) fight.charge(self, 10) end },
}, function() return dog_run end)

dog_leap = animation.hold("dog.dog_leap", {
    { f.leap1, fight.face },
    { f.leap2, function(self)
        fight.face(self)

        self.touch = dog_jump_touch
        local vectors = quake.make_vectors(self.angles)
        self.origin = self.origin + quake.vec3(0, 0, 1)
        self.velocity = vectors.forward * 300 + quake.vec3(0, 0, 200)
        if (self.flags & C.FL_ONGROUND) ~= 0 then
            self.flags = self.flags - C.FL_ONGROUND
        end
    end },
    { f.leap3 },
    { f.leap4 },
    { f.leap5 },
    { f.leap6 },
    { f.leap7 },
    { f.leap8 },
    { f.leap9 },
})

local dog_pain = animation.sequence("dog.dog_pain", {
    { f.pain1 },
    { f.pain2 },
    { f.pain3 },
    { f.pain4 },
    { f.pain5 },
    { f.pain6 },
}, function() return dog_run end)

local dog_painb = animation.sequence("dog.dog_painb", {
    { f.painb1 },
    { f.painb2 },
    { f.painb3, function(self) ai.pain(self, 4) end },
    { f.painb4, function(self) ai.pain(self, 12) end },
    { f.painb5, function(self) ai.pain(self, 12) end },
    { f.painb6, function(self) ai.pain(self, 2) end },
    { f.painb7 },
    { f.painb8, function(self) ai.pain(self, 4) end },
    { f.painb9 },
    { f.painb10, function(self) ai.pain(self, 10) end },
    { f.painb11 },
    { f.painb12 },
    { f.painb13 },
    { f.painb14 },
    { f.painb15 },
    { f.painb16 },
}, function() return dog_run end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local dog_pain_handler = quake.register_function("dog.dog_pain_handler", function(self, _attacker, _damage)
    quake.sound(self, C.CHAN_VOICE, "dog/dpain1.wav", 1, C.ATTN_NORM)

    if quake.random() > 0.5 then
        dog_pain(self)
    else
        dog_painb(self)
    end
end)

local dog_die = animation.hold("dog.dog_die", {
    { f.death1 },
    { f.death2 },
    { f.death3 },
    { f.death4 },
    { f.death5 },
    { f.death6 },
    { f.death7 },
    { f.death8 },
    { f.death9 },
})

local dog_dieb = animation.hold("dog.dog_dieb", {
    { f.deathb1 },
    { f.deathb2 },
    { f.deathb3 },
    { f.deathb4 },
    { f.deathb5 },
    { f.deathb6 },
    { f.deathb7 },
    { f.deathb8 },
    { f.deathb9 },
})

---@param self entity
---@return nil
local dog_die_handler = quake.register_function("dog.dog_die_handler", function(self)
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
        dog_die(self)
    else
        dog_dieb(self)
    end
end)

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
local function spawn(self)
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

    self.th_stand = dog_stand
    self.th_walk = dog_walk
    self.th_run = dog_run
    self.th_pain = dog_pain_handler
    self.th_die = dog_die_handler
    self.th_melee = dog_atta
    self.th_missile = dog_leap
    monsters.walk_start(self)
end

quake.register_entity("monster_dog", spawn)

return M
