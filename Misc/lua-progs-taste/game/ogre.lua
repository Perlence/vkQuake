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
-- Port of ogre.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local ai = require("game.ai")
local animation = require("game.animation")
local combat = require("game.combat")
local fight = require("game.fight")
local gibs = require("game.gibs")
local items = require("game.items")
local monsters = require("game.monsters")
local subs = require("game.subs")
local weapons = require("game.weapons")

local M = {}

local count = animation.counter()
local f = {}

f.stand1, f.stand2, f.stand3, f.stand4, f.stand5, f.stand6,
    f.stand7, f.stand8, f.stand9 = count(9)

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
    f.walk7, f.walk8, f.walk9, f.walk10, f.walk11, f.walk12,
    f.walk13, f.walk14, f.walk15, f.walk16 = count(16)

f.run1, f.run2, f.run3, f.run4, f.run5, f.run6,
    f.run7, f.run8 = count(8)

f.swing1, f.swing2, f.swing3, f.swing4, f.swing5, f.swing6,
    f.swing7, f.swing8, f.swing9, f.swing10, f.swing11, f.swing12,
    f.swing13, f.swing14 = count(14)

f.smash1, f.smash2, f.smash3, f.smash4, f.smash5, f.smash6,
    f.smash7, f.smash8, f.smash9, f.smash10, f.smash11, f.smash12,
    f.smash13, f.smash14 = count(14)

f.shoot1, f.shoot2, f.shoot3, f.shoot4, f.shoot5, f.shoot6 = count(6)

f.pain1, f.pain2, f.pain3, f.pain4, f.pain5 = count(5)

f.painb1, f.painb2, f.painb3 = count(3)

f.painc1, f.painc2, f.painc3, f.painc4, f.painc5, f.painc6 = count(6)

f.paind1, f.paind2, f.paind3, f.paind4, f.paind5, f.paind6,
    f.paind7, f.paind8, f.paind9, f.paind10, f.paind11, f.paind12,
    f.paind13, f.paind14, f.paind15, f.paind16 = count(16)

f.paine1, f.paine2, f.paine3, f.paine4, f.paine5, f.paine6,
    f.paine7, f.paine8, f.paine9, f.paine10, f.paine11, f.paine12,
    f.paine13, f.paine14, f.paine15 = count(15)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
    f.death7, f.death8, f.death9, f.death10, f.death11, f.death12,
    f.death13, f.death14 = count(14)

f.bdeath1, f.bdeath2, f.bdeath3, f.bdeath4, f.bdeath5, f.bdeath6,
    f.bdeath7, f.bdeath8, f.bdeath9, f.bdeath10 = count(10)

f.pull1, f.pull2, f.pull3, f.pull4, f.pull5, f.pull6,
    f.pull7, f.pull8, f.pull9, f.pull10, f.pull11 = count(11)

--[[
==============================================================================

OGRE

==============================================================================
]]

--=============================================================================

---@param self entity
---@return nil
local function ogre_grenade_explode(self)
    combat.radius_damage(self, self.owner, 40, quake.world)
    quake.sound(self, C.CHAN_VOICE, "weapons/r_exp3.wav", 1, C.ATTN_NORM)
    quake.write_byte(C.MSG_BROADCAST, C.SVC_TEMPENTITY)
    quake.write_byte(C.MSG_BROADCAST, C.TE_EXPLOSION)
    quake.write_coord(C.MSG_BROADCAST, self.origin.x)
    quake.write_coord(C.MSG_BROADCAST, self.origin.y)
    quake.write_coord(C.MSG_BROADCAST, self.origin.z)
    self.velocity = quake.vec3(0, 0, 0)
    self.touch = subs.null
    quake.set_model(self, "progs/s_explod.spr")
    self.solid = C.SOLID_NOT
    weapons.explode(self)
end

---@param self entity
---@param other entity
---@return nil
local function ogre_grenade_touch(self, other)
    if other == self.owner then return end -- don't explode on owner
    if other.takedamage == C.DAMAGE_AIM then ogre_grenade_explode(self); return end
    -- bounce sound
    quake.sound(self, C.CHAN_VOICE, "weapons/bounce.wav", 1, C.ATTN_NORM)
    if self.velocity == quake.vec3(0, 0, 0) then self.avelocity = quake.vec3(0, 0, 0) end
end

---@param self entity
---@return nil
local function ogre_fire_grenade(self)
    self.effects = self.effects | C.EF_MUZZLEFLASH
    quake.sound(self, C.CHAN_WEAPON, "weapons/grenade.wav", 1, C.ATTN_NORM)
    local missile = quake.spawn()
    missile.owner = self
    missile.movetype = C.MOVETYPE_BOUNCE
    missile.solid = C.SOLID_BBOX
    -- set missile speed
    quake.make_vectors(self.angles)
    missile.velocity = (self.enemy.origin - self.origin):normalized()
    missile.velocity = missile.velocity * 600
    missile.velocity = quake.vec3(missile.velocity.x, missile.velocity.y, 200)
    missile.avelocity = quake.vec3(300, 300, 300)
    missile.angles = quake.vector_to_angles(missile.velocity)
    missile.touch = ogre_grenade_touch
    -- set missile duration
    missile.nextthink = quake.time() + 2.5
    missile.think = ogre_grenade_explode
    quake.set_model(missile, "progs/grenade.mdl")
    quake.set_size(missile, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    quake.set_origin(missile, self.origin)
end

--=============================================================================

---FIXME
---@param self entity
---@param side number
---@return nil
local function chainsaw(self, side)
    if not self.enemy then return end
    if not combat.can_damage(self.enemy, self) then return end
    fight.charge(self, 10)
    local delta = self.enemy.origin - self.origin
    if delta:length() > 100 then return end
    local ldmg = (quake.random() + quake.random() + quake.random()) * 4
    combat.damage(self.enemy, self, self, ldmg)
    if side ~= 0 then
        local vectors = quake.make_vectors(self.angles)
        if side == 1 then weapons.spawn_meat_spray(self, self.origin + vectors.forward * 16, quake.crandom() * 100 * vectors.right)
        else weapons.spawn_meat_spray(self, self.origin + vectors.forward * 16, side * vectors.right) end
    end
end

local ogre_stand = {}
ogre_stand[1] = animation.frame(f.stand1, function() return ogre_stand[2] end, function(self) ai.stand(self) end)
ogre_stand[2] = animation.frame(f.stand2, function() return ogre_stand[3] end, function(self) ai.stand(self) end)
ogre_stand[3] = animation.frame(f.stand3, function() return ogre_stand[4] end, function(self) ai.stand(self) end)
ogre_stand[4] = animation.frame(f.stand4, function() return ogre_stand[5] end, function(self) ai.stand(self) end)
ogre_stand[5] = animation.frame(f.stand5, function() return ogre_stand[6] end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "ogre/ogidle.wav", 1, C.ATTN_IDLE) end; ai.stand(self) end)
ogre_stand[6] = animation.frame(f.stand6, function() return ogre_stand[7] end, function(self) ai.stand(self) end)
ogre_stand[7] = animation.frame(f.stand7, function() return ogre_stand[8] end, function(self) ai.stand(self) end)
ogre_stand[8] = animation.frame(f.stand8, function() return ogre_stand[9] end, function(self) ai.stand(self) end)
ogre_stand[9] = animation.frame(f.stand9, function() return ogre_stand[1] end, function(self) ai.stand(self) end)

local ogre_walk = {}
ogre_walk[1] = animation.frame(f.walk1, function() return ogre_walk[2] end, function(self) ai.walk(self, 3) end)
ogre_walk[2] = animation.frame(f.walk2, function() return ogre_walk[3] end, function(self) ai.walk(self, 2) end)
ogre_walk[3] = animation.frame(f.walk3, function() return ogre_walk[4] end, function(self) ai.walk(self, 2); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "ogre/ogidle.wav", 1, C.ATTN_IDLE) end end)
ogre_walk[4] = animation.frame(f.walk4, function() return ogre_walk[5] end, function(self) ai.walk(self, 2) end)
ogre_walk[5] = animation.frame(f.walk5, function() return ogre_walk[6] end, function(self) ai.walk(self, 2) end)
ogre_walk[6] = animation.frame(f.walk6, function() return ogre_walk[7] end, function(self) ai.walk(self, 5); if quake.random() < 0.1 then quake.sound(self, C.CHAN_VOICE, "ogre/ogdrag.wav", 1, C.ATTN_IDLE) end end)
ogre_walk[7] = animation.frame(f.walk7, function() return ogre_walk[8] end, function(self) ai.walk(self, 3) end)
ogre_walk[8] = animation.frame(f.walk8, function() return ogre_walk[9] end, function(self) ai.walk(self, 2) end)
ogre_walk[9] = animation.frame(f.walk9, function() return ogre_walk[10] end, function(self) ai.walk(self, 3) end)
ogre_walk[10] = animation.frame(f.walk10, function() return ogre_walk[11] end, function(self) ai.walk(self, 1) end)
ogre_walk[11] = animation.frame(f.walk11, function() return ogre_walk[12] end, function(self) ai.walk(self, 2) end)
ogre_walk[12] = animation.frame(f.walk12, function() return ogre_walk[13] end, function(self) ai.walk(self, 3) end)
ogre_walk[13] = animation.frame(f.walk13, function() return ogre_walk[14] end, function(self) ai.walk(self, 3) end)
ogre_walk[14] = animation.frame(f.walk14, function() return ogre_walk[15] end, function(self) ai.walk(self, 3) end)
ogre_walk[15] = animation.frame(f.walk15, function() return ogre_walk[16] end, function(self) ai.walk(self, 3) end)
ogre_walk[16] = animation.frame(f.walk16, function() return ogre_walk[1] end, function(self) ai.walk(self, 4) end)

local ogre_run = {}
ogre_run[1] = animation.frame(f.run1, function() return ogre_run[2] end, function(self) ai.run(self, 9); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "ogre/ogidle2.wav", 1, C.ATTN_IDLE) end end)
ogre_run[2] = animation.frame(f.run2, function() return ogre_run[3] end, function(self) ai.run(self, 12) end)
ogre_run[3] = animation.frame(f.run3, function() return ogre_run[4] end, function(self) ai.run(self, 8) end)
ogre_run[4] = animation.frame(f.run4, function() return ogre_run[5] end, function(self) ai.run(self, 22) end)
ogre_run[5] = animation.frame(f.run5, function() return ogre_run[6] end, function(self) ai.run(self, 16) end)
ogre_run[6] = animation.frame(f.run6, function() return ogre_run[7] end, function(self) ai.run(self, 4) end)
ogre_run[7] = animation.frame(f.run7, function() return ogre_run[8] end, function(self) ai.run(self, 13) end)
ogre_run[8] = animation.frame(f.run8, function() return ogre_run[1] end, function(self) ai.run(self, 24) end)

local ogre_swing = {}
ogre_swing[1] = animation.frame(f.swing1, function() return ogre_swing[2] end, function(self) fight.charge(self, 11); quake.sound(self, C.CHAN_WEAPON, "ogre/ogsawatk.wav", 1, C.ATTN_NORM) end)
ogre_swing[2] = animation.frame(f.swing2, function() return ogre_swing[3] end, function(self) fight.charge(self, 1) end)
ogre_swing[3] = animation.frame(f.swing3, function() return ogre_swing[4] end, function(self) fight.charge(self, 4) end)
ogre_swing[4] = animation.frame(f.swing4, function() return ogre_swing[5] end, function(self) fight.charge(self, 13) end)
ogre_swing[5] = animation.frame(f.swing5, function() return ogre_swing[6] end, function(self) fight.charge(self, 9); chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing[6] = animation.frame(f.swing6, function() return ogre_swing[7] end, function(self) chainsaw(self, 200); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing[7] = animation.frame(f.swing7, function() return ogre_swing[8] end, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing[8] = animation.frame(f.swing8, function() return ogre_swing[9] end, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing[9] = animation.frame(f.swing9, function() return ogre_swing[10] end, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing[10] = animation.frame(f.swing10, function() return ogre_swing[11] end, function(self) chainsaw(self, -200); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing[11] = animation.frame(f.swing11, function() return ogre_swing[12] end, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing[12] = animation.frame(f.swing12, function() return ogre_swing[13] end, function(self) fight.charge(self, 3) end)
ogre_swing[13] = animation.frame(f.swing13, function() return ogre_swing[14] end, function(self) fight.charge(self, 8) end)
ogre_swing[14] = animation.frame(f.swing14, function() return ogre_run[1] end, function(self) fight.charge(self, 9) end)

local ogre_smash = {}
ogre_smash[1] = animation.frame(f.smash1, function() return ogre_smash[2] end, function(self) fight.charge(self, 6); quake.sound(self, C.CHAN_WEAPON, "ogre/ogsawatk.wav", 1, C.ATTN_NORM) end)
ogre_smash[2] = animation.frame(f.smash2, function() return ogre_smash[3] end, function(self) fight.charge(self, 0) end)
ogre_smash[3] = animation.frame(f.smash3, function() return ogre_smash[4] end, function(self) fight.charge(self, 0) end)
ogre_smash[4] = animation.frame(f.smash4, function() return ogre_smash[5] end, function(self) fight.charge(self, 1) end)
ogre_smash[5] = animation.frame(f.smash5, function() return ogre_smash[6] end, function(self) fight.charge(self, 4) end)
ogre_smash[6] = animation.frame(f.smash6, function() return ogre_smash[7] end, function(self) fight.charge(self, 4); chainsaw(self, 0) end)
ogre_smash[7] = animation.frame(f.smash7, function() return ogre_smash[8] end, function(self) fight.charge(self, 4); chainsaw(self, 0) end)
ogre_smash[8] = animation.frame(f.smash8, function() return ogre_smash[9] end, function(self) fight.charge(self, 10); chainsaw(self, 0) end)
ogre_smash[9] = animation.frame(f.smash9, function() return ogre_smash[10] end, function(self) fight.charge(self, 13); chainsaw(self, 0) end)
ogre_smash[10] = animation.frame(f.smash10, function() return ogre_smash[11] end, function(self) chainsaw(self, 1) end)
ogre_smash[11] = animation.frame(f.smash11, function() return ogre_smash[12] end, function(self) fight.charge(self, 2); chainsaw(self, 0); -- slight variation
        self.nextthink = self.nextthink + quake.random() * 0.2 end)
ogre_smash[12] = animation.frame(f.smash12, function() return ogre_smash[13] end, function(self) fight.charge(self, 0) end)
ogre_smash[13] = animation.frame(f.smash13, function() return ogre_smash[14] end, function(self) fight.charge(self, 4) end)
ogre_smash[14] = animation.frame(f.smash14, function() return ogre_run[1] end, function(self) fight.charge(self, 12) end)

local ogre_nail = {}
ogre_nail[1] = animation.frame(f.shoot1, function() return ogre_nail[2] end, function(self) fight.face(self) end)
ogre_nail[2] = animation.frame(f.shoot2, function() return ogre_nail[3] end, function(self) fight.face(self) end)
ogre_nail[3] = animation.frame(f.shoot2, function() return ogre_nail[4] end, function(self) fight.face(self) end)
ogre_nail[4] = animation.frame(f.shoot3, function() return ogre_nail[5] end, function(self) fight.face(self); ogre_fire_grenade(self) end)
ogre_nail[5] = animation.frame(f.shoot4, function() return ogre_nail[6] end, function(self) fight.face(self) end)
ogre_nail[6] = animation.frame(f.shoot5, function() return ogre_nail[7] end, function(self) fight.face(self) end)
ogre_nail[7] = animation.frame(f.shoot6, function() return ogre_run[1] end, function(self) fight.face(self) end)

local ogre_pain = {}
ogre_pain[1] = animation.frame(f.pain1, function() return ogre_pain[2] end)
ogre_pain[2] = animation.frame(f.pain2, function() return ogre_pain[3] end)
ogre_pain[3] = animation.frame(f.pain3, function() return ogre_pain[4] end)
ogre_pain[4] = animation.frame(f.pain4, function() return ogre_pain[5] end)
ogre_pain[5] = animation.frame(f.pain5, function() return ogre_run[1] end)

local ogre_painb = {}
ogre_painb[1] = animation.frame(f.painb1, function() return ogre_painb[2] end)
ogre_painb[2] = animation.frame(f.painb2, function() return ogre_painb[3] end)
ogre_painb[3] = animation.frame(f.painb3, function() return ogre_run[1] end)

local ogre_painc = {}
ogre_painc[1] = animation.frame(f.painc1, function() return ogre_painc[2] end)
ogre_painc[2] = animation.frame(f.painc2, function() return ogre_painc[3] end)
ogre_painc[3] = animation.frame(f.painc3, function() return ogre_painc[4] end)
ogre_painc[4] = animation.frame(f.painc4, function() return ogre_painc[5] end)
ogre_painc[5] = animation.frame(f.painc5, function() return ogre_painc[6] end)
ogre_painc[6] = animation.frame(f.painc6, function() return ogre_run[1] end)

local ogre_paind = {}
ogre_paind[1] = animation.frame(f.paind1, function() return ogre_paind[2] end)
ogre_paind[2] = animation.frame(f.paind2, function() return ogre_paind[3] end, function(self) ai.pain(self, 10) end)
ogre_paind[3] = animation.frame(f.paind3, function() return ogre_paind[4] end, function(self) ai.pain(self, 9) end)
ogre_paind[4] = animation.frame(f.paind4, function() return ogre_paind[5] end, function(self) ai.pain(self, 4) end)
ogre_paind[5] = animation.frame(f.paind5, function() return ogre_paind[6] end)
ogre_paind[6] = animation.frame(f.paind6, function() return ogre_paind[7] end)
ogre_paind[7] = animation.frame(f.paind7, function() return ogre_paind[8] end)
ogre_paind[8] = animation.frame(f.paind8, function() return ogre_paind[9] end)
ogre_paind[9] = animation.frame(f.paind9, function() return ogre_paind[10] end)
ogre_paind[10] = animation.frame(f.paind10, function() return ogre_paind[11] end)
ogre_paind[11] = animation.frame(f.paind11, function() return ogre_paind[12] end)
ogre_paind[12] = animation.frame(f.paind12, function() return ogre_paind[13] end)
ogre_paind[13] = animation.frame(f.paind13, function() return ogre_paind[14] end)
ogre_paind[14] = animation.frame(f.paind14, function() return ogre_paind[15] end)
ogre_paind[15] = animation.frame(f.paind15, function() return ogre_paind[16] end)
ogre_paind[16] = animation.frame(f.paind16, function() return ogre_run[1] end)

local ogre_paine = {}
ogre_paine[1] = animation.frame(f.paine1, function() return ogre_paine[2] end)
ogre_paine[2] = animation.frame(f.paine2, function() return ogre_paine[3] end, function(self) ai.pain(self, 10) end)
ogre_paine[3] = animation.frame(f.paine3, function() return ogre_paine[4] end, function(self) ai.pain(self, 9) end)
ogre_paine[4] = animation.frame(f.paine4, function() return ogre_paine[5] end, function(self) ai.pain(self, 4) end)
ogre_paine[5] = animation.frame(f.paine5, function() return ogre_paine[6] end)
ogre_paine[6] = animation.frame(f.paine6, function() return ogre_paine[7] end)
ogre_paine[7] = animation.frame(f.paine7, function() return ogre_paine[8] end)
ogre_paine[8] = animation.frame(f.paine8, function() return ogre_paine[9] end)
ogre_paine[9] = animation.frame(f.paine9, function() return ogre_paine[10] end)
ogre_paine[10] = animation.frame(f.paine10, function() return ogre_paine[11] end)
ogre_paine[11] = animation.frame(f.paine11, function() return ogre_paine[12] end)
ogre_paine[12] = animation.frame(f.paine12, function() return ogre_paine[13] end)
ogre_paine[13] = animation.frame(f.paine13, function() return ogre_paine[14] end)
ogre_paine[14] = animation.frame(f.paine14, function() return ogre_paine[15] end)
ogre_paine[15] = animation.frame(f.paine15, function() return ogre_run[1] end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function ogre_pain_callback(self, _attacker, _damage)
    -- don't make multiple pain sounds right after each other
    if self.pain_finished > quake.time() then return end
    quake.sound(self, C.CHAN_VOICE, "ogre/ogpain1.wav", 1, C.ATTN_NORM)
    local r = quake.random()
    if r < 0.25 then ogre_pain[1](self); self.pain_finished = quake.time() + 1
    elseif r < 0.5 then ogre_painb[1](self); self.pain_finished = quake.time() + 1
    elseif r < 0.75 then ogre_painc[1](self); self.pain_finished = quake.time() + 1
    elseif r < 0.88 then ogre_paind[1](self); self.pain_finished = quake.time() + 2
    else ogre_paine[1](self); self.pain_finished = quake.time() + 2 end
end

local ogre_die = {}
ogre_die[1] = animation.frame(f.death1, function() return ogre_die[2] end)
ogre_die[2] = animation.frame(f.death2, function() return ogre_die[3] end)
ogre_die[3] = animation.frame(f.death3, function() return ogre_die[4] end, function(self) self.solid = C.SOLID_NOT; self.ammo_rockets = 2; items.drop_backpack(self) end)
ogre_die[4] = animation.frame(f.death4, function() return ogre_die[5] end)
ogre_die[5] = animation.frame(f.death5, function() return ogre_die[6] end)
ogre_die[6] = animation.frame(f.death6, function() return ogre_die[7] end)
ogre_die[7] = animation.frame(f.death7, function() return ogre_die[8] end)
ogre_die[8] = animation.frame(f.death8, function() return ogre_die[9] end)
ogre_die[9] = animation.frame(f.death9, function() return ogre_die[10] end)
ogre_die[10] = animation.frame(f.death10, function() return ogre_die[11] end)
ogre_die[11] = animation.frame(f.death11, function() return ogre_die[12] end)
ogre_die[12] = animation.frame(f.death12, function() return ogre_die[13] end)
ogre_die[13] = animation.frame(f.death13, function() return ogre_die[14] end)
ogre_die[14] = animation.frame(f.death14, function() return ogre_die[14] end)

local ogre_bdie = {}
ogre_bdie[1] = animation.frame(f.bdeath1, function() return ogre_bdie[2] end)
ogre_bdie[2] = animation.frame(f.bdeath2, function() return ogre_bdie[3] end, function(self) ai.forward(self, 5) end)
ogre_bdie[3] = animation.frame(f.bdeath3, function() return ogre_bdie[4] end, function(self) self.solid = C.SOLID_NOT; self.ammo_rockets = 2; items.drop_backpack(self) end)
ogre_bdie[4] = animation.frame(f.bdeath4, function() return ogre_bdie[5] end, function(self) ai.forward(self, 1) end)
ogre_bdie[5] = animation.frame(f.bdeath5, function() return ogre_bdie[6] end, function(self) ai.forward(self, 3) end)
ogre_bdie[6] = animation.frame(f.bdeath6, function() return ogre_bdie[7] end, function(self) ai.forward(self, 7) end)
ogre_bdie[7] = animation.frame(f.bdeath7, function() return ogre_bdie[8] end, function(self) ai.forward(self, 25) end)
ogre_bdie[8] = animation.frame(f.bdeath8, function() return ogre_bdie[9] end)
ogre_bdie[9] = animation.frame(f.bdeath9, function() return ogre_bdie[10] end)
ogre_bdie[10] = animation.frame(f.bdeath10, function() return ogre_bdie[10] end)

---@param self entity
---@return nil
local function ogre_die_callback(self)
    -- check for gib
    if self.health < -80 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw_head(self, "progs/h_ogre.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        return
    end
    quake.sound(self, C.CHAN_VOICE, "ogre/ogdth.wav", 1, C.ATTN_NORM)
    if quake.random() < 0.5 then ogre_die[1](self) else ogre_bdie[1](self) end
end

---@param self entity
---@return nil
local function ogre_melee(self)
    if quake.random() > 0.5 then ogre_smash[1](self) else ogre_swing[1](self) end
end

---QUAKED monster_ogre (1 0 0) (-32 -32 -24) (32 32 64) Ambush
---@param self entity
---@return nil
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then quake.remove(self); return end
    quake.precache_model("progs/ogre.mdl")
    quake.precache_model("progs/h_ogre.mdl")
    quake.precache_model("progs/grenade.mdl")
    quake.precache_sound("ogre/ogdrag.wav")
    quake.precache_sound("ogre/ogdth.wav")
    quake.precache_sound("ogre/ogidle.wav")
    quake.precache_sound("ogre/ogidle2.wav")
    quake.precache_sound("ogre/ogpain1.wav")
    quake.precache_sound("ogre/ogsawatk.wav")
    quake.precache_sound("ogre/ogwake.wav")
    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP
    quake.set_model(self, "progs/ogre.mdl")
    quake.set_size(self, C.VEC_HULL2_MIN, C.VEC_HULL2_MAX)
    self.health = 200
    self.th_stand = ogre_stand[1]
    self.th_walk = ogre_walk[1]
    self.th_run = ogre_run[1]
    self.th_die = ogre_die_callback
    self.th_melee = ogre_melee
    self.th_missile = ogre_nail[1]
    self.th_pain = ogre_pain_callback
    monsters.walk_start(self)
end

---@param self entity
---@return nil
function M.spawn_marksman(self) M.spawn(self) end

quake.register_entity("monster_ogre", M.spawn)
quake.register_entity("monster_ogre_marksman", M.spawn_marksman)

return M
