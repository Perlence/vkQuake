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

local C = require("game.constants")
local ai = require("game.ai")
local animation = require("game.animation")
local combat = require("game.combat")
local fight = require("game.fight")
local gibs = require("game.gibs")
local monsters = require("game.monsters")
local subs = require("game.subs")
local weapons = require("game.weapons")

local count = animation.counter()
local f = {}

f.attack1, f.attack2, f.attack3, f.attack4, f.attack5, f.attack6,
f.attack7, f.attack8, f.attack9, f.attack10, f.attack11 = count(11)

f.pain1, f.pain2, f.pain3, f.pain4, f.pain5 = count(5)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
f.death7 = count(7)

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
f.walk7, f.walk8, f.walk9, f.walk10, f.walk11, f.walk12 = count(12)

local ATTN_IDLE = 2
local CHAN_WEAPON = 1
local EF_MUZZLEFLASH = 2
local MOVETYPE_FLYMISSILE = 9
local SOLID_BBOX = 2

--[[
==============================================================================

SHAL-RATH (Vore)

==============================================================================
]]

local shal_stand1 = animation.loop("shalrath.shal_stand1", {
    { f.walk1, ai.stand },
})

local shal_walk = animation.loop("shalrath.shal_walk", {
    { f.walk2, function(self)
        if quake.random() < 0.2 then
            quake.sound(self, C.CHAN_VOICE, "shalrath/idle.wav", 1, ATTN_IDLE)
        end
        ai.walk(self, 6)
    end },
    { f.walk3, function(self) ai.walk(self, 4) end },
    { f.walk4, function(self) ai.walk(self, 0) end },
    { f.walk5, function(self) ai.walk(self, 0) end },
    { f.walk6, function(self) ai.walk(self, 0) end },
    { f.walk7, function(self) ai.walk(self, 0) end },
    { f.walk8, function(self) ai.walk(self, 5) end },
    { f.walk9, function(self) ai.walk(self, 6) end },
    { f.walk10, function(self) ai.walk(self, 5) end },
    { f.walk11, function(self) ai.walk(self, 0) end },
    { f.walk12, function(self) ai.walk(self, 4) end },
    { f.walk1, function(self) ai.walk(self, 5) end },
})

local shal_run = animation.loop("shalrath.shal_run", {
    { f.walk2, function(self)
        if quake.random() < 0.2 then
            quake.sound(self, C.CHAN_VOICE, "shalrath/idle.wav", 1, ATTN_IDLE)
        end
        ai.run(self, 6)
    end },
    { f.walk3, function(self) ai.run(self, 4) end },
    { f.walk4, function(self) ai.run(self, 0) end },
    { f.walk5, function(self) ai.run(self, 0) end },
    { f.walk6, function(self) ai.run(self, 0) end },
    { f.walk7, function(self) ai.run(self, 0) end },
    { f.walk8, function(self) ai.run(self, 5) end },
    { f.walk9, function(self) ai.run(self, 6) end },
    { f.walk10, function(self) ai.run(self, 5) end },
    { f.walk11, function(self) ai.run(self, 0) end },
    { f.walk12, function(self) ai.run(self, 4) end },
    { f.walk1, function(self) ai.run(self, 5) end },
})

local shal_missile

local shal_attack = animation.sequence("shalrath.shal_attack", {
    { f.attack1, function(self)
        quake.sound(self, C.CHAN_VOICE, "shalrath/attack.wav", 1, C.ATTN_NORM)
        fight.face(self)
    end },
    { f.attack2, fight.face },
    { f.attack3, fight.face },
    { f.attack4, fight.face },
    { f.attack5, fight.face },
    { f.attack6, fight.face },
    { f.attack7, fight.face },
    { f.attack8, fight.face },
    { f.attack9, function(self) shal_missile(self) end },
    { f.attack10, fight.face },
    { f.attack11 },
}, function() return shal_run end)

local shal_pain = animation.sequence("shalrath.shal_pain", {
    { f.pain1 },
    { f.pain2 },
    { f.pain3 },
    { f.pain4 },
    { f.pain5 },
}, function() return shal_run end)

local shal_death = animation.hold("shalrath.shal_death", {
    { f.death1 },
    { f.death2 },
    { f.death3 },
    { f.death4 },
    { f.death5 },
    { f.death6 },
    { f.death7 },
})

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local shalrath_pain = quake.register_function("shalrath.shalrath_pain", function(self, _attacker, _damage)
    if self.pain_finished > quake.time() then
        return
    end

    quake.sound(self, C.CHAN_VOICE, "shalrath/pain.wav", 1, C.ATTN_NORM)
    shal_pain(self)
    self.pain_finished = quake.time() + 3
end)

---@param self entity
---@return nil
local shalrath_die = quake.register_function("shalrath.shalrath_die", function(self)
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
    shal_death(self)
    self.solid = C.SOLID_NOT
end)

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
shal_home = quake.register_function("shalrath.shal_home", function(self)
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
end)

---@param self entity
---@param other entity
---@return nil
shal_missile_touch = quake.register_function("shalrath.shal_missile_touch", function(self, other)
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
end)

--=================================================================

---QUAKED monster_shalrath (1 0 0) (-32 -32 -24) (32 32 48) Ambush
---@param self entity
---@return nil
local function spawn(self)
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

    self.th_stand = shal_stand1
    self.th_walk = shal_walk
    self.th_run = shal_run
    self.th_die = shalrath_die
    self.th_pain = shalrath_pain
    self.th_missile = shal_attack

    self.think = monsters.walk_start
    self.nextthink = quake.time() + 0.1 + quake.random() * 0.1
end

quake.register_entity("monster_shalrath", spawn)
