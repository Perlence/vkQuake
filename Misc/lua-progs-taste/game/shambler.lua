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

local sham_stand = {}
sham_stand[1] = animation.frame(f.stand1, function() return sham_stand[2] end, ai.stand)
sham_stand[2] = animation.frame(f.stand2, function() return sham_stand[3] end, ai.stand)
sham_stand[3] = animation.frame(f.stand3, function() return sham_stand[4] end, ai.stand)
sham_stand[4] = animation.frame(f.stand4, function() return sham_stand[5] end, ai.stand)
sham_stand[5] = animation.frame(f.stand5, function() return sham_stand[6] end, ai.stand)
sham_stand[6] = animation.frame(f.stand6, function() return sham_stand[7] end, ai.stand)
sham_stand[7] = animation.frame(f.stand7, function() return sham_stand[8] end, ai.stand)
sham_stand[8] = animation.frame(f.stand8, function() return sham_stand[9] end, ai.stand)
sham_stand[9] = animation.frame(f.stand9, function() return sham_stand[10] end, ai.stand)
sham_stand[10] = animation.frame(f.stand10, function() return sham_stand[11] end, ai.stand)
sham_stand[11] = animation.frame(f.stand11, function() return sham_stand[12] end, ai.stand)
sham_stand[12] = animation.frame(f.stand12, function() return sham_stand[13] end, ai.stand)
sham_stand[13] = animation.frame(f.stand13, function() return sham_stand[14] end, ai.stand)
sham_stand[14] = animation.frame(f.stand14, function() return sham_stand[15] end, ai.stand)
sham_stand[15] = animation.frame(f.stand15, function() return sham_stand[16] end, ai.stand)
sham_stand[16] = animation.frame(f.stand16, function() return sham_stand[17] end, ai.stand)
sham_stand[17] = animation.frame(f.stand17, function() return sham_stand[1] end, ai.stand)

local sham_walk = {}
sham_walk[1] = animation.frame(f.walk1, function() return sham_walk[2] end, function(self) ai.walk(self, 10) end)
sham_walk[2] = animation.frame(f.walk2, function() return sham_walk[3] end, function(self) ai.walk(self, 9) end)
sham_walk[3] = animation.frame(f.walk3, function() return sham_walk[4] end, function(self) ai.walk(self, 9) end)
sham_walk[4] = animation.frame(f.walk4, function() return sham_walk[5] end, function(self) ai.walk(self, 5) end)
sham_walk[5] = animation.frame(f.walk5, function() return sham_walk[6] end, function(self) ai.walk(self, 6) end)
sham_walk[6] = animation.frame(f.walk6, function() return sham_walk[7] end, function(self) ai.walk(self, 12) end)
sham_walk[7] = animation.frame(f.walk7, function() return sham_walk[8] end, function(self) ai.walk(self, 8) end)
sham_walk[8] = animation.frame(f.walk8, function() return sham_walk[9] end, function(self) ai.walk(self, 3) end)
sham_walk[9] = animation.frame(f.walk9, function() return sham_walk[10] end, function(self) ai.walk(self, 13) end)
sham_walk[10] = animation.frame(f.walk10, function() return sham_walk[11] end, function(self) ai.walk(self, 9) end)
sham_walk[11] = animation.frame(f.walk11, function() return sham_walk[12] end, function(self) ai.walk(self, 7) end)
sham_walk[12] = animation.frame(f.walk12, function() return sham_walk[1] end, function(self) ai.walk(self, 7); if quake.random() > 0.8 then quake.sound(self, C.CHAN_VOICE, "shambler/sidle.wav", 1, C.ATTN_IDLE) end end)

local sham_run = {}
sham_run[1] = animation.frame(f.run1, function() return sham_run[2] end, function(self) ai.run(self, 20) end)
sham_run[2] = animation.frame(f.run2, function() return sham_run[3] end, function(self) ai.run(self, 24) end)
sham_run[3] = animation.frame(f.run3, function() return sham_run[4] end, function(self) ai.run(self, 20) end)
sham_run[4] = animation.frame(f.run4, function() return sham_run[5] end, function(self) ai.run(self, 20) end)
sham_run[5] = animation.frame(f.run5, function() return sham_run[6] end, function(self) ai.run(self, 24) end)
sham_run[6] = animation.frame(f.run6, function() return sham_run[1] end, function(self) ai.run(self, 20); if quake.random() > 0.8 then quake.sound(self, C.CHAN_VOICE, "shambler/sidle.wav", 1, C.ATTN_IDLE) end end)

local sham_smash = {}
sham_smash[1] = animation.frame(f.smash1, function() return sham_smash[2] end, function(self) quake.sound(self, C.CHAN_VOICE, "shambler/melee1.wav", 1, C.ATTN_NORM); fight.charge(self, 2) end)
sham_smash[2] = animation.frame(f.smash2, function() return sham_smash[3] end, function(self) fight.charge(self, 6) end)
sham_smash[3] = animation.frame(f.smash3, function() return sham_smash[4] end, function(self) fight.charge(self, 6) end)
sham_smash[4] = animation.frame(f.smash4, function() return sham_smash[5] end, function(self) fight.charge(self, 5) end)
sham_smash[5] = animation.frame(f.smash5, function() return sham_smash[6] end, function(self) fight.charge(self, 4) end)
sham_smash[6] = animation.frame(f.smash6, function() return sham_smash[7] end, function(self) fight.charge(self, 1) end)
sham_smash[7] = animation.frame(f.smash7, function() return sham_smash[8] end, function(self) fight.charge(self, 0) end)
sham_smash[8] = animation.frame(f.smash8, function() return sham_smash[9] end, function(self) fight.charge(self, 0) end)
sham_smash[9] = animation.frame(f.smash9, function() return sham_smash[10] end, function(self) fight.charge(self, 0) end)
sham_smash[10] = animation.frame(f.smash10, function() return sham_smash[11] end, function(self)
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
sham_smash[11] = animation.frame(f.smash11, function() return sham_smash[12] end, function(self) fight.charge(self, 5) end)
sham_smash[12] = animation.frame(f.smash12, function() return sham_run[1] end, function(self) fight.charge(self, 4) end)

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

local sham_swingr = {}

local sham_swingl = {}
sham_swingl[1] = animation.frame(f.swingl1, function() return sham_swingl[2] end, function(self) quake.sound(self, C.CHAN_VOICE, "shambler/melee2.wav", 1, C.ATTN_NORM); fight.charge(self, 5) end)
sham_swingl[2] = animation.frame(f.swingl2, function() return sham_swingl[3] end, function(self) fight.charge(self, 3) end)
sham_swingl[3] = animation.frame(f.swingl3, function() return sham_swingl[4] end, function(self) fight.charge(self, 7) end)
sham_swingl[4] = animation.frame(f.swingl4, function() return sham_swingl[5] end, function(self) fight.charge(self, 3) end)
sham_swingl[5] = animation.frame(f.swingl5, function() return sham_swingl[6] end, function(self) fight.charge(self, 7) end)
sham_swingl[6] = animation.frame(f.swingl6, function() return sham_swingl[7] end, function(self) fight.charge(self, 9) end)
sham_swingl[7] = animation.frame(f.swingl7, function() return sham_swingl[8] end, function(self) fight.charge(self, 5); sham_claw(self, 250) end)
sham_swingl[8] = animation.frame(f.swingl8, function() return sham_swingl[9] end, function(self) fight.charge(self, 4) end)
sham_swingl[9] = animation.frame(f.swingl9, function() return sham_run[1] end, function(self) fight.charge(self, 8); if quake.random() < 0.5 then self.think = sham_swingr[1] end end)

sham_swingr[1] = animation.frame(f.swingr1, function() return sham_swingr[2] end, function(self) quake.sound(self, C.CHAN_VOICE, "shambler/melee1.wav", 1, C.ATTN_NORM); fight.charge(self, 1) end)
sham_swingr[2] = animation.frame(f.swingr2, function() return sham_swingr[3] end, function(self) fight.charge(self, 8) end)
sham_swingr[3] = animation.frame(f.swingr3, function() return sham_swingr[4] end, function(self) fight.charge(self, 14) end)
sham_swingr[4] = animation.frame(f.swingr4, function() return sham_swingr[5] end, function(self) fight.charge(self, 7) end)
sham_swingr[5] = animation.frame(f.swingr5, function() return sham_swingr[6] end, function(self) fight.charge(self, 3) end)
sham_swingr[6] = animation.frame(f.swingr6, function() return sham_swingr[7] end, function(self) fight.charge(self, 6) end)
sham_swingr[7] = animation.frame(f.swingr7, function() return sham_swingr[8] end, function(self) fight.charge(self, 6); sham_claw(self, -250) end)
sham_swingr[8] = animation.frame(f.swingr8, function() return sham_swingr[9] end, function(self) fight.charge(self, 3) end)
sham_swingr[9] = animation.frame(f.swingr9, function() return sham_run[1] end, function(self) fight.charge(self, 1); fight.charge(self, 10); if quake.random() < 0.5 then self.think = sham_swingl[1] end end)

---@param self entity
---@return nil
local function sham_melee(self)
    local chance = quake.random()
    if chance > 0.6 or self.health == 600 then sham_smash[1](self)
    elseif chance > 0.3 then sham_swingr[1](self)
    else sham_swingl[1](self) end
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

local sham_magic = {}

sham_magic[1] = animation.frame(f.magic1, function() return sham_magic[2] end, function(self) fight.face(self); quake.sound(self, C.CHAN_WEAPON, "shambler/sattck1.wav", 1, C.ATTN_NORM) end)
sham_magic[2] = animation.frame(f.magic2, function() return sham_magic[3] end, fight.face)
sham_magic[3] = animation.frame(f.magic3, function() return sham_magic[4] end, function(self)
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
sham_magic[4] = animation.frame(f.magic4, function() return sham_magic[5] end, function(self) self.effects = self.effects | C.EF_MUZZLEFLASH; self.owner.frame = 1 end)
sham_magic[5] = animation.frame(f.magic5, function() return sham_magic[6] end, function(self) self.effects = self.effects | C.EF_MUZZLEFLASH; self.owner.frame = 2 end)
sham_magic[6] = animation.frame(f.magic6, function() return sham_magic[9] end, function(self) quake.remove(self.owner); cast_lightning(self); quake.sound(self, C.CHAN_WEAPON, "shambler/sboom.wav", 1, C.ATTN_NORM) end)
sham_magic[9] = animation.frame(f.magic9, function() return sham_magic[10] end, cast_lightning)
sham_magic[10] = animation.frame(f.magic10, function() return sham_magic[11] end, cast_lightning)
sham_magic[11] = animation.frame(f.magic11, function() return sham_magic[12] end, function(self) if quake.cvar("skill") == 3 then cast_lightning(self) end end)
sham_magic[12] = animation.frame(f.magic12, function() return sham_run[1] end)

local sham_pain = {}
sham_pain[1] = animation.frame(f.pain1, function() return sham_pain[2] end)
sham_pain[2] = animation.frame(f.pain2, function() return sham_pain[3] end)
sham_pain[3] = animation.frame(f.pain3, function() return sham_pain[4] end)
sham_pain[4] = animation.frame(f.pain4, function() return sham_pain[5] end)
sham_pain[5] = animation.frame(f.pain5, function() return sham_pain[6] end)
sham_pain[6] = animation.frame(f.pain6, function() return sham_run[1] end)

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
    sham_pain[1](self)
end

--============================================================================

local sham_death = {}
sham_death[1] = animation.frame(f.death1, function() return sham_death[2] end)
sham_death[2] = animation.frame(f.death2, function() return sham_death[3] end)
sham_death[3] = animation.frame(f.death3, function() return sham_death[4] end, function(self) self.solid = C.SOLID_NOT end)
sham_death[4] = animation.frame(f.death4, function() return sham_death[5] end)
sham_death[5] = animation.frame(f.death5, function() return sham_death[6] end)
sham_death[6] = animation.frame(f.death6, function() return sham_death[7] end)
sham_death[7] = animation.frame(f.death7, function() return sham_death[8] end)
sham_death[8] = animation.frame(f.death8, function() return sham_death[9] end)
sham_death[9] = animation.frame(f.death9, function() return sham_death[10] end)
sham_death[10] = animation.frame(f.death10, function() return sham_death[11] end)
sham_death[11] = animation.frame(f.death11, function() return sham_death[11] end)

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
    sham_death[1](self)
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
    self.th_stand = sham_stand[1]
    self.th_walk = sham_walk[1]
    self.th_run = sham_run[1]
    self.th_die = sham_die
    self.th_melee = sham_melee
    self.th_missile = sham_magic[1]
    self.th_pain = sham_pain_callback
    monsters.walk_start(self)
end

quake.register_entity("monster_shambler", M.spawn)

return M
