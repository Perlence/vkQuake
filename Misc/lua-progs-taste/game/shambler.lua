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
-- Port of shambler.qc from GPL-licensed CleanFixedQuakeC.
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
local weapons = require("game.weapons")

local count = animation.counter()
local f = {}

f.stand1, f.stand2, f.stand3, f.stand4, f.stand5, f.stand6,
    f.stand7, f.stand8, f.stand9, f.stand10, f.stand11, f.stand12,
    f.stand13, f.stand14, f.stand15, f.stand16, f.stand17 = count(17)

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
    f.walk7, f.walk8, f.walk9, f.walk10, f.walk11, f.walk12 = count(12)

f.run1, f.run2, f.run3, f.run4, f.run5, f.run6 = count(6)

f.smash1, f.smash2, f.smash3, f.smash4, f.smash5, f.smash6,
    f.smash7, f.smash8, f.smash9, f.smash10, f.smash11, f.smash12 = count(12)

f.swingr1, f.swingr2, f.swingr3, f.swingr4, f.swingr5, f.swingr6,
    f.swingr7, f.swingr8, f.swingr9 = count(9)

f.swingl1, f.swingl2, f.swingl3, f.swingl4, f.swingl5, f.swingl6,
    f.swingl7, f.swingl8, f.swingl9 = count(9)

f.magic1, f.magic2, f.magic3, f.magic4, f.magic5, f.magic6,
    f.magic7, f.magic8, f.magic9, f.magic10, f.magic11, f.magic12 = count(12)

f.pain1, f.pain2, f.pain3, f.pain4, f.pain5, f.pain6 = count(6)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
    f.death7, f.death8, f.death9, f.death10, f.death11 = count(11)

--[[
==============================================================================

SHAMBLER

==============================================================================
]]

local sham_stand = animation.loop({
    { f.stand1, ai.stand },
    { f.stand2, ai.stand },
    { f.stand3, ai.stand },
    { f.stand4, ai.stand },
    { f.stand5, ai.stand },
    { f.stand6, ai.stand },
    { f.stand7, ai.stand },
    { f.stand8, ai.stand },
    { f.stand9, ai.stand },
    { f.stand10, ai.stand },
    { f.stand11, ai.stand },
    { f.stand12, ai.stand },
    { f.stand13, ai.stand },
    { f.stand14, ai.stand },
    { f.stand15, ai.stand },
    { f.stand16, ai.stand },
    { f.stand17, ai.stand },
})

local sham_walk = animation.loop({
    { f.walk1, function(self) ai.walk(self, 10) end },
    { f.walk2, function(self) ai.walk(self, 9) end },
    { f.walk3, function(self) ai.walk(self, 9) end },
    { f.walk4, function(self) ai.walk(self, 5) end },
    { f.walk5, function(self) ai.walk(self, 6) end },
    { f.walk6, function(self) ai.walk(self, 12) end },
    { f.walk7, function(self) ai.walk(self, 8) end },
    { f.walk8, function(self) ai.walk(self, 3) end },
    { f.walk9, function(self) ai.walk(self, 13) end },
    { f.walk10, function(self) ai.walk(self, 9) end },
    { f.walk11, function(self) ai.walk(self, 7) end },
    { f.walk12, function(self) ai.walk(self, 7); if quake.random() > 0.8 then quake.sound(self, C.CHAN_VOICE, "shambler/sidle.wav", 1, C.ATTN_IDLE) end end },
})

local sham_run = animation.loop({
    { f.run1, function(self) ai.run(self, 20) end },
    { f.run2, function(self) ai.run(self, 24) end },
    { f.run3, function(self) ai.run(self, 20) end },
    { f.run4, function(self) ai.run(self, 20) end },
    { f.run5, function(self) ai.run(self, 24) end },
    { f.run6, function(self) ai.run(self, 20); if quake.random() > 0.8 then quake.sound(self, C.CHAN_VOICE, "shambler/sidle.wav", 1, C.ATTN_IDLE) end end },
})

local sham_smash = animation.sequence({
    { f.smash1, function(self) quake.sound(self, C.CHAN_VOICE, "shambler/melee1.wav", 1, C.ATTN_NORM); fight.charge(self, 2) end },
    { f.smash2, function(self) fight.charge(self, 6) end },
    { f.smash3, function(self) fight.charge(self, 6) end },
    { f.smash4, function(self) fight.charge(self, 5) end },
    { f.smash5, function(self) fight.charge(self, 4) end },
    { f.smash6, function(self) fight.charge(self, 1) end },
    { f.smash7, function(self) fight.charge(self, 0) end },
    { f.smash8, function(self) fight.charge(self, 0) end },
    { f.smash9, function(self) fight.charge(self, 0) end },
    { f.smash10, function(self)
        if not self.enemy then return end
        fight.charge(self, 0)
        local delta = self.enemy.origin - self.origin
        if delta:length() > 100 then return end
        if not combat.can_damage(self.enemy, self) then return end
        local ldmg = (quake.random() + quake.random() + quake.random()) * 40
        combat.damage(self.enemy, self, self, ldmg)
        quake.sound(self, C.CHAN_VOICE, "shambler/smack.wav", 1, C.ATTN_NORM)
        local vectors = quake.make_vectors(self.angles)
        weapons.spawn_meat_spray(self, self.origin + vectors.forward * 16, quake.crandom() * 100 * vectors.right)
        weapons.spawn_meat_spray(self, self.origin + vectors.forward * 16, quake.crandom() * 100 * vectors.right)
    end },
    { f.smash11, function(self) fight.charge(self, 5) end },
    { f.smash12, function(self) fight.charge(self, 4) end },
}, function() return sham_run end)

---@param self entity
---@param side number
---@return nil
local function sham_claw(self, side)
    if not self.enemy then return end
    fight.charge(self, 10)
    local delta = self.enemy.origin - self.origin
    if delta:length() > 100 then return end
    local ldmg = (quake.random() + quake.random() + quake.random()) * 20
    combat.damage(self.enemy, self, self, ldmg)
    quake.sound(self, C.CHAN_VOICE, "shambler/smack.wav", 1, C.ATTN_NORM)
    if side ~= 0 then
        local vectors = quake.make_vectors(self.angles)
        weapons.spawn_meat_spray(self, self.origin + vectors.forward * 16, side * vectors.right)
    end
end

local sham_swingr

local sham_swingl = animation.sequence({
    { f.swingl1, function(self) quake.sound(self, C.CHAN_VOICE, "shambler/melee2.wav", 1, C.ATTN_NORM); fight.charge(self, 5) end },
    { f.swingl2, function(self) fight.charge(self, 3) end },
    { f.swingl3, function(self) fight.charge(self, 7) end },
    { f.swingl4, function(self) fight.charge(self, 3) end },
    { f.swingl5, function(self) fight.charge(self, 7) end },
    { f.swingl6, function(self) fight.charge(self, 9) end },
    { f.swingl7, function(self) fight.charge(self, 5); sham_claw(self, 250) end },
    { f.swingl8, function(self) fight.charge(self, 4) end },
    { f.swingl9, function(self) fight.charge(self, 8); if quake.random() < 0.5 then self.think = sham_swingr end end },
}, function() return sham_run end)

sham_swingr = animation.sequence({
    { f.swingr1, function(self) quake.sound(self, C.CHAN_VOICE, "shambler/melee1.wav", 1, C.ATTN_NORM); fight.charge(self, 1) end },
    { f.swingr2, function(self) fight.charge(self, 8) end },
    { f.swingr3, function(self) fight.charge(self, 14) end },
    { f.swingr4, function(self) fight.charge(self, 7) end },
    { f.swingr5, function(self) fight.charge(self, 3) end },
    { f.swingr6, function(self) fight.charge(self, 6) end },
    { f.swingr7, function(self) fight.charge(self, 6); sham_claw(self, -250) end },
    { f.swingr8, function(self) fight.charge(self, 3) end },
    { f.swingr9, function(self) fight.charge(self, 1); fight.charge(self, 10); if quake.random() < 0.5 then self.think = sham_swingl end end },
}, function() return sham_run end)

---@param self entity
---@return nil
local function sham_melee(self)
    local chance = quake.random()
    if chance > 0.6 or self.health == 600 then sham_smash(self)
    elseif chance > 0.3 then sham_swingr(self)
    else sham_swingl(self) end
end

--============================================================================

---@param self entity
---@return nil
local function cast_lightning(self)
    self.effects = self.effects | C.EF_MUZZLEFLASH
    fight.face(self)
    local org = self.origin + quake.vec3(0, 0, 40)
    local dir = (self.enemy.origin + quake.vec3(0, 0, 16) - org):normalized()
    local trace = quake.trace_line(org, self.origin + dir * 600, true, self)
    quake.write_byte(C.MSG_BROADCAST, C.SVC_TEMPENTITY)
    quake.write_byte(C.MSG_BROADCAST, C.TE_LIGHTNING1)
    quake.write_entity(C.MSG_BROADCAST, self)
    quake.write_coord(C.MSG_BROADCAST, org.x)
    quake.write_coord(C.MSG_BROADCAST, org.y)
    quake.write_coord(C.MSG_BROADCAST, org.z)
    quake.write_coord(C.MSG_BROADCAST, trace.endpos.x)
    quake.write_coord(C.MSG_BROADCAST, trace.endpos.y)
    quake.write_coord(C.MSG_BROADCAST, trace.endpos.z)
    weapons.lightning_damage(self, org, trace.endpos, self, 10)
end

local sham_magic = animation.sequence({
    { f.magic1, function(self) fight.face(self); quake.sound(self, C.CHAN_WEAPON, "shambler/sattck1.wav", 1, C.ATTN_NORM) end },
    { f.magic2, fight.face },
    { f.magic3, function(self)
        fight.face(self)
        self.nextthink = self.nextthink + 0.2
        self.effects = self.effects | C.EF_MUZZLEFLASH
        fight.face(self)
        local o = quake.spawn()
        self.owner = o
        quake.set_model(o, "progs/s_light.mdl")
        quake.set_origin(o, self.origin)
        o.angles = self.angles
        o.nextthink = quake.time() + 0.7
        o.think = subs.remove
    end },
    { f.magic4, function(self) self.effects = self.effects | C.EF_MUZZLEFLASH; self.owner.frame = 1 end },
    { f.magic5, function(self) self.effects = self.effects | C.EF_MUZZLEFLASH; self.owner.frame = 2 end },
    { f.magic6, function(self) quake.remove(self.owner); cast_lightning(self); quake.sound(self, C.CHAN_WEAPON, "shambler/sboom.wav", 1, C.ATTN_NORM) end },
    { f.magic9, cast_lightning },
    { f.magic10, cast_lightning },
    { f.magic11, function(self) if quake.cvar("skill") == 3 then cast_lightning(self) end end },
    { f.magic12 },
}, function() return sham_run end)

local sham_pain = animation.sequence({
    { f.pain1 },
    { f.pain2 },
    { f.pain3 },
    { f.pain4 },
    { f.pain5 },
    { f.pain6 },
}, function() return sham_run end)

---@param self entity
---@param _attacker entity
---@param damage number
---@return nil
local function sham_pain_callback(self, _attacker, damage)
    quake.sound(self, C.CHAN_VOICE, "shambler/shurt2.wav", 1, C.ATTN_NORM)
    if self.health <= 0 then return end -- already dying, don't go into pain frame
    if quake.random() * 400 > damage then return end -- didn't flinch
    if self.pain_finished > quake.time() then return end
    self.pain_finished = quake.time() + 2
    sham_pain(self)
end

--============================================================================

local sham_death = animation.hold({
    { f.death1 },
    { f.death2 },
    { f.death3, function(self) self.solid = C.SOLID_NOT end },
    { f.death4 },
    { f.death5 },
    { f.death6 },
    { f.death7 },
    { f.death8 },
    { f.death9 },
    { f.death10 },
    { f.death11 },
})

---@param self entity
---@return nil
local function sham_die(self)
    -- check for gib
    if self.health < -60 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw_head(self, "progs/h_shams.mdl", self.health)
        gibs.throw(self, "progs/gib1.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        return
    end
    -- regular death
    quake.sound(self, C.CHAN_VOICE, "shambler/sdeath.wav", 1, C.ATTN_NORM)
    sham_death(self)
end

--============================================================================

---QUAKED monster_shambler (1 0 0) (-32 -32 -24) (32 32 64) Ambush
---@param self entity
---@return nil
local function spawn(self)
    if quake.cvar("deathmatch") ~= 0 then quake.remove(self); return end
    quake.precache_model("progs/shambler.mdl")
    quake.precache_model("progs/s_light.mdl")
    quake.precache_model("progs/h_shams.mdl")
    quake.precache_model("progs/bolt.mdl")
    quake.precache_sound("shambler/sattck1.wav")
    quake.precache_sound("shambler/sboom.wav")
    quake.precache_sound("shambler/sdeath.wav")
    quake.precache_sound("shambler/shurt2.wav")
    quake.precache_sound("shambler/sidle.wav")
    quake.precache_sound("shambler/ssight.wav")
    quake.precache_sound("shambler/melee1.wav")
    quake.precache_sound("shambler/melee2.wav")
    quake.precache_sound("shambler/smack.wav")
    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP
    quake.set_model(self, "progs/shambler.mdl")
    quake.set_size(self, C.VEC_HULL2_MIN, C.VEC_HULL2_MAX)
    self.health = 600
    self.th_stand = sham_stand
    self.th_walk = sham_walk
    self.th_run = sham_run
    self.th_die = sham_die
    self.th_melee = sham_melee
    self.th_missile = sham_magic
    self.th_pain = sham_pain_callback
    monsters.walk_start(self)
end

quake.register_entity("monster_shambler", spawn)
