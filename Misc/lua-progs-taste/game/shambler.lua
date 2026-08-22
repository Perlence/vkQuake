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

local M = {}

--[[
==============================================================================

SHAMBLER

==============================================================================
]]

local sham_stand1, sham_stand2, sham_stand3, sham_stand4, sham_stand5, sham_stand6, sham_stand7, sham_stand8, sham_stand9, sham_stand10, sham_stand11, sham_stand12, sham_stand13, sham_stand14, sham_stand15, sham_stand16, sham_stand17

sham_stand1 = animation.frame("stand1", function() return sham_stand2 end, ai.stand)
sham_stand2 = animation.frame("stand2", function() return sham_stand3 end, ai.stand)
sham_stand3 = animation.frame("stand3", function() return sham_stand4 end, ai.stand)
sham_stand4 = animation.frame("stand4", function() return sham_stand5 end, ai.stand)
sham_stand5 = animation.frame("stand5", function() return sham_stand6 end, ai.stand)
sham_stand6 = animation.frame("stand6", function() return sham_stand7 end, ai.stand)
sham_stand7 = animation.frame("stand7", function() return sham_stand8 end, ai.stand)
sham_stand8 = animation.frame("stand8", function() return sham_stand9 end, ai.stand)
sham_stand9 = animation.frame("stand9", function() return sham_stand10 end, ai.stand)
sham_stand10 = animation.frame("stand10", function() return sham_stand11 end, ai.stand)
sham_stand11 = animation.frame("stand11", function() return sham_stand12 end, ai.stand)
sham_stand12 = animation.frame("stand12", function() return sham_stand13 end, ai.stand)
sham_stand13 = animation.frame("stand13", function() return sham_stand14 end, ai.stand)
sham_stand14 = animation.frame("stand14", function() return sham_stand15 end, ai.stand)
sham_stand15 = animation.frame("stand15", function() return sham_stand16 end, ai.stand)
sham_stand16 = animation.frame("stand16", function() return sham_stand17 end, ai.stand)
sham_stand17 = animation.frame("stand17", function() return sham_stand1 end, ai.stand)

local sham_walk1, sham_walk2, sham_walk3, sham_walk4, sham_walk5, sham_walk6, sham_walk7, sham_walk8, sham_walk9, sham_walk10, sham_walk11, sham_walk12

sham_walk1 = animation.frame("walk1", function() return sham_walk2 end, function(self) ai.walk(self, 10) end)
sham_walk2 = animation.frame("walk2", function() return sham_walk3 end, function(self) ai.walk(self, 9) end)
sham_walk3 = animation.frame("walk3", function() return sham_walk4 end, function(self) ai.walk(self, 9) end)
sham_walk4 = animation.frame("walk4", function() return sham_walk5 end, function(self) ai.walk(self, 5) end)
sham_walk5 = animation.frame("walk5", function() return sham_walk6 end, function(self) ai.walk(self, 6) end)
sham_walk6 = animation.frame("walk6", function() return sham_walk7 end, function(self) ai.walk(self, 12) end)
sham_walk7 = animation.frame("walk7", function() return sham_walk8 end, function(self) ai.walk(self, 8) end)
sham_walk8 = animation.frame("walk8", function() return sham_walk9 end, function(self) ai.walk(self, 3) end)
sham_walk9 = animation.frame("walk9", function() return sham_walk10 end, function(self) ai.walk(self, 13) end)
sham_walk10 = animation.frame("walk10", function() return sham_walk11 end, function(self) ai.walk(self, 9) end)
sham_walk11 = animation.frame("walk11", function() return sham_walk12 end, function(self) ai.walk(self, 7) end)
sham_walk12 = animation.frame("walk12", function() return sham_walk1 end, function(self) ai.walk(self, 7); if quake.random() > 0.8 then quake.sound(self, C.CHAN_VOICE, "shambler/sidle.wav", 1, C.ATTN_IDLE) end end)

local sham_run1, sham_run2, sham_run3, sham_run4, sham_run5, sham_run6

sham_run1 = animation.frame("run1", function() return sham_run2 end, function(self) ai.run(self, 20) end)
sham_run2 = animation.frame("run2", function() return sham_run3 end, function(self) ai.run(self, 24) end)
sham_run3 = animation.frame("run3", function() return sham_run4 end, function(self) ai.run(self, 20) end)
sham_run4 = animation.frame("run4", function() return sham_run5 end, function(self) ai.run(self, 20) end)
sham_run5 = animation.frame("run5", function() return sham_run6 end, function(self) ai.run(self, 24) end)
sham_run6 = animation.frame("run6", function() return sham_run1 end, function(self) ai.run(self, 20); if quake.random() > 0.8 then quake.sound(self, C.CHAN_VOICE, "shambler/sidle.wav", 1, C.ATTN_IDLE) end end)

local sham_smash1, sham_smash2, sham_smash3, sham_smash4, sham_smash5, sham_smash6, sham_smash7, sham_smash8, sham_smash9, sham_smash10, sham_smash11, sham_smash12

sham_smash1 = animation.frame("smash1", function() return sham_smash2 end, function(self) quake.sound(self, C.CHAN_VOICE, "shambler/melee1.wav", 1, C.ATTN_NORM); fight.charge(self, 2) end)
sham_smash2 = animation.frame("smash2", function() return sham_smash3 end, function(self) fight.charge(self, 6) end)
sham_smash3 = animation.frame("smash3", function() return sham_smash4 end, function(self) fight.charge(self, 6) end)
sham_smash4 = animation.frame("smash4", function() return sham_smash5 end, function(self) fight.charge(self, 5) end)
sham_smash5 = animation.frame("smash5", function() return sham_smash6 end, function(self) fight.charge(self, 4) end)
sham_smash6 = animation.frame("smash6", function() return sham_smash7 end, function(self) fight.charge(self, 1) end)
sham_smash7 = animation.frame("smash7", function() return sham_smash8 end, function(self) fight.charge(self, 0) end)
sham_smash8 = animation.frame("smash8", function() return sham_smash9 end, function(self) fight.charge(self, 0) end)
sham_smash9 = animation.frame("smash9", function() return sham_smash10 end, function(self) fight.charge(self, 0) end)
sham_smash10 = animation.frame("smash10", function() return sham_smash11 end, function(self)
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
end)
sham_smash11 = animation.frame("smash11", function() return sham_smash12 end, function(self) fight.charge(self, 5) end)
sham_smash12 = animation.frame("smash12", function() return sham_run1 end, function(self) fight.charge(self, 4) end)

local sham_swingr1

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

local sham_swingl1, sham_swingl2, sham_swingl3, sham_swingl4, sham_swingl5, sham_swingl6, sham_swingl7, sham_swingl8, sham_swingl9

sham_swingl1 = animation.frame("swingl1", function() return sham_swingl2 end, function(self) quake.sound(self, C.CHAN_VOICE, "shambler/melee2.wav", 1, C.ATTN_NORM); fight.charge(self, 5) end)
sham_swingl2 = animation.frame("swingl2", function() return sham_swingl3 end, function(self) fight.charge(self, 3) end)
sham_swingl3 = animation.frame("swingl3", function() return sham_swingl4 end, function(self) fight.charge(self, 7) end)
sham_swingl4 = animation.frame("swingl4", function() return sham_swingl5 end, function(self) fight.charge(self, 3) end)
sham_swingl5 = animation.frame("swingl5", function() return sham_swingl6 end, function(self) fight.charge(self, 7) end)
sham_swingl6 = animation.frame("swingl6", function() return sham_swingl7 end, function(self) fight.charge(self, 9) end)
sham_swingl7 = animation.frame("swingl7", function() return sham_swingl8 end, function(self) fight.charge(self, 5); sham_claw(self, 250) end)
sham_swingl8 = animation.frame("swingl8", function() return sham_swingl9 end, function(self) fight.charge(self, 4) end)
sham_swingl9 = animation.frame("swingl9", function() return sham_run1 end, function(self) fight.charge(self, 8); if quake.random() < 0.5 then self.think = sham_swingr1 end end)

local sham_swingr2, sham_swingr3, sham_swingr4, sham_swingr5, sham_swingr6, sham_swingr7, sham_swingr8, sham_swingr9

sham_swingr1 = animation.frame("swingr1", function() return sham_swingr2 end, function(self) quake.sound(self, C.CHAN_VOICE, "shambler/melee1.wav", 1, C.ATTN_NORM); fight.charge(self, 1) end)
sham_swingr2 = animation.frame("swingr2", function() return sham_swingr3 end, function(self) fight.charge(self, 8) end)
sham_swingr3 = animation.frame("swingr3", function() return sham_swingr4 end, function(self) fight.charge(self, 14) end)
sham_swingr4 = animation.frame("swingr4", function() return sham_swingr5 end, function(self) fight.charge(self, 7) end)
sham_swingr5 = animation.frame("swingr5", function() return sham_swingr6 end, function(self) fight.charge(self, 3) end)
sham_swingr6 = animation.frame("swingr6", function() return sham_swingr7 end, function(self) fight.charge(self, 6) end)
sham_swingr7 = animation.frame("swingr7", function() return sham_swingr8 end, function(self) fight.charge(self, 6); sham_claw(self, -250) end)
sham_swingr8 = animation.frame("swingr8", function() return sham_swingr9 end, function(self) fight.charge(self, 3) end)
sham_swingr9 = animation.frame("swingr9", function() return sham_run1 end, function(self) fight.charge(self, 1); fight.charge(self, 10); if quake.random() < 0.5 then self.think = sham_swingl1 end end)

---@param self entity
---@return nil
local function sham_melee(self)
    local chance = quake.random()
    if chance > 0.6 or self.health == 600 then sham_smash1(self)
    elseif chance > 0.3 then sham_swingr1(self)
    else sham_swingl1(self) end
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

local sham_magic1, sham_magic2, sham_magic3, sham_magic4, sham_magic5, sham_magic6
local sham_magic9, sham_magic10, sham_magic11, sham_magic12

sham_magic1 = animation.frame("magic1", function() return sham_magic2 end, function(self) fight.face(self); quake.sound(self, C.CHAN_WEAPON, "shambler/sattck1.wav", 1, C.ATTN_NORM) end)
sham_magic2 = animation.frame("magic2", function() return sham_magic3 end, fight.face)
sham_magic3 = animation.frame("magic3", function() return sham_magic4 end, function(self)
    fight.face(self)
    self.nextthink = self.nextthink + 0.2
    self.effects = self.effects | C.EF_MUZZLEFLASH
    fight.face(self)
    self.owner = quake.spawn()
    local o = self.owner
    quake.set_model(o, "progs/s_light.mdl")
    quake.set_origin(o, self.origin)
    o.angles = self.angles
    o.nextthink = quake.time() + 0.7
    o.think = subs.remove
end)
sham_magic4 = animation.frame("magic4", function() return sham_magic5 end, function(self) self.effects = self.effects | C.EF_MUZZLEFLASH; self.owner.frame = 1 end)
sham_magic5 = animation.frame("magic5", function() return sham_magic6 end, function(self) self.effects = self.effects | C.EF_MUZZLEFLASH; self.owner.frame = 2 end)
sham_magic6 = animation.frame("magic6", function() return sham_magic9 end, function(self) quake.remove(self.owner); cast_lightning(self); quake.sound(self, C.CHAN_WEAPON, "shambler/sboom.wav", 1, C.ATTN_NORM) end)
sham_magic9 = animation.frame("magic9", function() return sham_magic10 end, cast_lightning)
sham_magic10 = animation.frame("magic10", function() return sham_magic11 end, cast_lightning)
sham_magic11 = animation.frame("magic11", function() return sham_magic12 end, function(self) if quake.cvar("skill") == 3 then cast_lightning(self) end end)
sham_magic12 = animation.frame("magic12", function() return sham_run1 end)

local sham_pain1, sham_pain2, sham_pain3, sham_pain4, sham_pain5, sham_pain6

sham_pain1 = animation.frame("pain1", function() return sham_pain2 end)
sham_pain2 = animation.frame("pain2", function() return sham_pain3 end)
sham_pain3 = animation.frame("pain3", function() return sham_pain4 end)
sham_pain4 = animation.frame("pain4", function() return sham_pain5 end)
sham_pain5 = animation.frame("pain5", function() return sham_pain6 end)
sham_pain6 = animation.frame("pain6", function() return sham_run1 end)

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
    sham_pain1(self)
end

--============================================================================

local sham_death1, sham_death2, sham_death3, sham_death4, sham_death5, sham_death6, sham_death7, sham_death8, sham_death9, sham_death10, sham_death11

sham_death1 = animation.frame("death1", function() return sham_death2 end)
sham_death2 = animation.frame("death2", function() return sham_death3 end)
sham_death3 = animation.frame("death3", function() return sham_death4 end, function(self) self.solid = C.SOLID_NOT end)
sham_death4 = animation.frame("death4", function() return sham_death5 end)
sham_death5 = animation.frame("death5", function() return sham_death6 end)
sham_death6 = animation.frame("death6", function() return sham_death7 end)
sham_death7 = animation.frame("death7", function() return sham_death8 end)
sham_death8 = animation.frame("death8", function() return sham_death9 end)
sham_death9 = animation.frame("death9", function() return sham_death10 end)
sham_death10 = animation.frame("death10", function() return sham_death11 end)
sham_death11 = animation.frame("death11", function() return sham_death11 end)

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
    sham_death1(self)
end

--============================================================================

---QUAKED monster_shambler (1 0 0) (-32 -32 -24) (32 32 64) Ambush
---@param self entity
---@return nil
function M.spawn(self)
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
    self.th_stand = sham_stand1
    self.th_walk = sham_walk1
    self.th_run = sham_run1
    self.th_die = sham_die
    self.th_melee = sham_melee
    self.th_missile = sham_magic1
    self.th_pain = sham_pain_callback
    monsters.walk_start(self)
end

quake.register_entity("monster_shambler", M.spawn)

return M
