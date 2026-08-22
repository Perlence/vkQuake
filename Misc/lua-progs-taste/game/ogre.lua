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

--[[
==============================================================================

OGRE

==============================================================================
]]

--=============================================================================

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

local function ogre_grenade_touch(self, other)
    if other == self.owner then return end -- don't explode on owner
    if other.takedamage == C.DAMAGE_AIM then ogre_grenade_explode(self); return end
    -- bounce sound
    quake.sound(self, C.CHAN_VOICE, "weapons/bounce.wav", 1, C.ATTN_NORM)
    if self.velocity == quake.vec3(0, 0, 0) then self.avelocity = quake.vec3(0, 0, 0) end
end

--[[
================
OgreFireGrenade
================
]]
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

--[[
================
chainsaw

FIXME
================
]]
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

local ogre_stand1, ogre_stand2, ogre_stand3, ogre_stand4, ogre_stand5, ogre_stand6, ogre_stand7, ogre_stand8, ogre_stand9

ogre_stand1 = animation.frame("stand1", function() return ogre_stand2 end, function(self) ai.stand(self) end)
ogre_stand2 = animation.frame("stand2", function() return ogre_stand3 end, function(self) ai.stand(self) end)
ogre_stand3 = animation.frame("stand3", function() return ogre_stand4 end, function(self) ai.stand(self) end)
ogre_stand4 = animation.frame("stand4", function() return ogre_stand5 end, function(self) ai.stand(self) end)
ogre_stand5 = animation.frame("stand5", function() return ogre_stand6 end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "ogre/ogidle.wav", 1, C.ATTN_IDLE) end; ai.stand(self) end)
ogre_stand6 = animation.frame("stand6", function() return ogre_stand7 end, function(self) ai.stand(self) end)
ogre_stand7 = animation.frame("stand7", function() return ogre_stand8 end, function(self) ai.stand(self) end)
ogre_stand8 = animation.frame("stand8", function() return ogre_stand9 end, function(self) ai.stand(self) end)
ogre_stand9 = animation.frame("stand9", function() return ogre_stand1 end, function(self) ai.stand(self) end)

local ogre_walk1, ogre_walk2, ogre_walk3, ogre_walk4, ogre_walk5, ogre_walk6, ogre_walk7, ogre_walk8, ogre_walk9, ogre_walk10, ogre_walk11, ogre_walk12, ogre_walk13, ogre_walk14, ogre_walk15, ogre_walk16

ogre_walk1 = animation.frame("walk1", function() return ogre_walk2 end, function(self) ai.walk(self, 3) end)
ogre_walk2 = animation.frame("walk2", function() return ogre_walk3 end, function(self) ai.walk(self, 2) end)
ogre_walk3 = animation.frame("walk3", function() return ogre_walk4 end, function(self) ai.walk(self, 2); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "ogre/ogidle.wav", 1, C.ATTN_IDLE) end end)
ogre_walk4 = animation.frame("walk4", function() return ogre_walk5 end, function(self) ai.walk(self, 2) end)
ogre_walk5 = animation.frame("walk5", function() return ogre_walk6 end, function(self) ai.walk(self, 2) end)
ogre_walk6 = animation.frame("walk6", function() return ogre_walk7 end, function(self) ai.walk(self, 5); if quake.random() < 0.1 then quake.sound(self, C.CHAN_VOICE, "ogre/ogdrag.wav", 1, C.ATTN_IDLE) end end)
ogre_walk7 = animation.frame("walk7", function() return ogre_walk8 end, function(self) ai.walk(self, 3) end)
ogre_walk8 = animation.frame("walk8", function() return ogre_walk9 end, function(self) ai.walk(self, 2) end)
ogre_walk9 = animation.frame("walk9", function() return ogre_walk10 end, function(self) ai.walk(self, 3) end)
ogre_walk10 = animation.frame("walk10", function() return ogre_walk11 end, function(self) ai.walk(self, 1) end)
ogre_walk11 = animation.frame("walk11", function() return ogre_walk12 end, function(self) ai.walk(self, 2) end)
ogre_walk12 = animation.frame("walk12", function() return ogre_walk13 end, function(self) ai.walk(self, 3) end)
ogre_walk13 = animation.frame("walk13", function() return ogre_walk14 end, function(self) ai.walk(self, 3) end)
ogre_walk14 = animation.frame("walk14", function() return ogre_walk15 end, function(self) ai.walk(self, 3) end)
ogre_walk15 = animation.frame("walk15", function() return ogre_walk16 end, function(self) ai.walk(self, 3) end)
ogre_walk16 = animation.frame("walk16", function() return ogre_walk1 end, function(self) ai.walk(self, 4) end)

local ogre_run1, ogre_run2, ogre_run3, ogre_run4, ogre_run5, ogre_run6, ogre_run7, ogre_run8

ogre_run1 = animation.frame("run1", function() return ogre_run2 end, function(self) ai.run(self, 9); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "ogre/ogidle2.wav", 1, C.ATTN_IDLE) end end)
ogre_run2 = animation.frame("run2", function() return ogre_run3 end, function(self) ai.run(self, 12) end)
ogre_run3 = animation.frame("run3", function() return ogre_run4 end, function(self) ai.run(self, 8) end)
ogre_run4 = animation.frame("run4", function() return ogre_run5 end, function(self) ai.run(self, 22) end)
ogre_run5 = animation.frame("run5", function() return ogre_run6 end, function(self) ai.run(self, 16) end)
ogre_run6 = animation.frame("run6", function() return ogre_run7 end, function(self) ai.run(self, 4) end)
ogre_run7 = animation.frame("run7", function() return ogre_run8 end, function(self) ai.run(self, 13) end)
ogre_run8 = animation.frame("run8", function() return ogre_run1 end, function(self) ai.run(self, 24) end)

local ogre_swing1, ogre_swing2, ogre_swing3, ogre_swing4, ogre_swing5, ogre_swing6, ogre_swing7, ogre_swing8, ogre_swing9, ogre_swing10, ogre_swing11, ogre_swing12, ogre_swing13, ogre_swing14

ogre_swing1 = animation.frame("swing1", function() return ogre_swing2 end, function(self) fight.charge(self, 11); quake.sound(self, C.CHAN_WEAPON, "ogre/ogsawatk.wav", 1, C.ATTN_NORM) end)
ogre_swing2 = animation.frame("swing2", function() return ogre_swing3 end, function(self) fight.charge(self, 1) end)
ogre_swing3 = animation.frame("swing3", function() return ogre_swing4 end, function(self) fight.charge(self, 4) end)
ogre_swing4 = animation.frame("swing4", function() return ogre_swing5 end, function(self) fight.charge(self, 13) end)
ogre_swing5 = animation.frame("swing5", function() return ogre_swing6 end, function(self) fight.charge(self, 9); chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing6 = animation.frame("swing6", function() return ogre_swing7 end, function(self) chainsaw(self, 200); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing7 = animation.frame("swing7", function() return ogre_swing8 end, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing8 = animation.frame("swing8", function() return ogre_swing9 end, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing9 = animation.frame("swing9", function() return ogre_swing10 end, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing10 = animation.frame("swing10", function() return ogre_swing11 end, function(self) chainsaw(self, -200); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing11 = animation.frame("swing11", function() return ogre_swing12 end, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end)
ogre_swing12 = animation.frame("swing12", function() return ogre_swing13 end, function(self) fight.charge(self, 3) end)
ogre_swing13 = animation.frame("swing13", function() return ogre_swing14 end, function(self) fight.charge(self, 8) end)
ogre_swing14 = animation.frame("swing14", function() return ogre_run1 end, function(self) fight.charge(self, 9) end)

local ogre_smash1, ogre_smash2, ogre_smash3, ogre_smash4, ogre_smash5, ogre_smash6, ogre_smash7, ogre_smash8, ogre_smash9, ogre_smash10, ogre_smash11, ogre_smash12, ogre_smash13, ogre_smash14

ogre_smash1 = animation.frame("smash1", function() return ogre_smash2 end, function(self) fight.charge(self, 6); quake.sound(self, C.CHAN_WEAPON, "ogre/ogsawatk.wav", 1, C.ATTN_NORM) end)
ogre_smash2 = animation.frame("smash2", function() return ogre_smash3 end, function(self) fight.charge(self, 0) end)
ogre_smash3 = animation.frame("smash3", function() return ogre_smash4 end, function(self) fight.charge(self, 0) end)
ogre_smash4 = animation.frame("smash4", function() return ogre_smash5 end, function(self) fight.charge(self, 1) end)
ogre_smash5 = animation.frame("smash5", function() return ogre_smash6 end, function(self) fight.charge(self, 4) end)
ogre_smash6 = animation.frame("smash6", function() return ogre_smash7 end, function(self) fight.charge(self, 4); chainsaw(self, 0) end)
ogre_smash7 = animation.frame("smash7", function() return ogre_smash8 end, function(self) fight.charge(self, 4); chainsaw(self, 0) end)
ogre_smash8 = animation.frame("smash8", function() return ogre_smash9 end, function(self) fight.charge(self, 10); chainsaw(self, 0) end)
ogre_smash9 = animation.frame("smash9", function() return ogre_smash10 end, function(self) fight.charge(self, 13); chainsaw(self, 0) end)
ogre_smash10 = animation.frame("smash10", function() return ogre_smash11 end, function(self) chainsaw(self, 1) end)
ogre_smash11 = animation.frame("smash11", function() return ogre_smash12 end, function(self) fight.charge(self, 2); chainsaw(self, 0); -- slight variation
        self.nextthink = self.nextthink + quake.random() * 0.2 end)
ogre_smash12 = animation.frame("smash12", function() return ogre_smash13 end, function(self) fight.charge(self, 0) end)
ogre_smash13 = animation.frame("smash13", function() return ogre_smash14 end, function(self) fight.charge(self, 4) end)
ogre_smash14 = animation.frame("smash14", function() return ogre_run1 end, function(self) fight.charge(self, 12) end)

local ogre_nail1, ogre_nail2, ogre_nail3, ogre_nail4, ogre_nail5, ogre_nail6, ogre_nail7

ogre_nail1 = animation.frame("shoot1", function() return ogre_nail2 end, function(self) fight.face(self) end)
ogre_nail2 = animation.frame("shoot2", function() return ogre_nail3 end, function(self) fight.face(self) end)
ogre_nail3 = animation.frame("shoot2", function() return ogre_nail4 end, function(self) fight.face(self) end)
ogre_nail4 = animation.frame("shoot3", function() return ogre_nail5 end, function(self) fight.face(self); ogre_fire_grenade(self) end)
ogre_nail5 = animation.frame("shoot4", function() return ogre_nail6 end, function(self) fight.face(self) end)
ogre_nail6 = animation.frame("shoot5", function() return ogre_nail7 end, function(self) fight.face(self) end)
ogre_nail7 = animation.frame("shoot6", function() return ogre_run1 end, function(self) fight.face(self) end)

local ogre_pain1, ogre_pain2, ogre_pain3, ogre_pain4, ogre_pain5

ogre_pain1 = animation.frame("pain1", function() return ogre_pain2 end)
ogre_pain2 = animation.frame("pain2", function() return ogre_pain3 end)
ogre_pain3 = animation.frame("pain3", function() return ogre_pain4 end)
ogre_pain4 = animation.frame("pain4", function() return ogre_pain5 end)
ogre_pain5 = animation.frame("pain5", function() return ogre_run1 end)

local ogre_painb1, ogre_painb2, ogre_painb3

ogre_painb1 = animation.frame("painb1", function() return ogre_painb2 end)
ogre_painb2 = animation.frame("painb2", function() return ogre_painb3 end)
ogre_painb3 = animation.frame("painb3", function() return ogre_run1 end)

local ogre_painc1, ogre_painc2, ogre_painc3, ogre_painc4, ogre_painc5, ogre_painc6

ogre_painc1 = animation.frame("painc1", function() return ogre_painc2 end)
ogre_painc2 = animation.frame("painc2", function() return ogre_painc3 end)
ogre_painc3 = animation.frame("painc3", function() return ogre_painc4 end)
ogre_painc4 = animation.frame("painc4", function() return ogre_painc5 end)
ogre_painc5 = animation.frame("painc5", function() return ogre_painc6 end)
ogre_painc6 = animation.frame("painc6", function() return ogre_run1 end)

local ogre_paind1, ogre_paind2, ogre_paind3, ogre_paind4, ogre_paind5, ogre_paind6, ogre_paind7, ogre_paind8, ogre_paind9, ogre_paind10, ogre_paind11, ogre_paind12, ogre_paind13, ogre_paind14, ogre_paind15, ogre_paind16

ogre_paind1 = animation.frame("paind1", function() return ogre_paind2 end)
ogre_paind2 = animation.frame("paind2", function() return ogre_paind3 end, function(self) ai.pain(self, 10) end)
ogre_paind3 = animation.frame("paind3", function() return ogre_paind4 end, function(self) ai.pain(self, 9) end)
ogre_paind4 = animation.frame("paind4", function() return ogre_paind5 end, function(self) ai.pain(self, 4) end)
ogre_paind5 = animation.frame("paind5", function() return ogre_paind6 end)
ogre_paind6 = animation.frame("paind6", function() return ogre_paind7 end)
ogre_paind7 = animation.frame("paind7", function() return ogre_paind8 end)
ogre_paind8 = animation.frame("paind8", function() return ogre_paind9 end)
ogre_paind9 = animation.frame("paind9", function() return ogre_paind10 end)
ogre_paind10 = animation.frame("paind10", function() return ogre_paind11 end)
ogre_paind11 = animation.frame("paind11", function() return ogre_paind12 end)
ogre_paind12 = animation.frame("paind12", function() return ogre_paind13 end)
ogre_paind13 = animation.frame("paind13", function() return ogre_paind14 end)
ogre_paind14 = animation.frame("paind14", function() return ogre_paind15 end)
ogre_paind15 = animation.frame("paind15", function() return ogre_paind16 end)
ogre_paind16 = animation.frame("paind16", function() return ogre_run1 end)

local ogre_paine1, ogre_paine2, ogre_paine3, ogre_paine4, ogre_paine5, ogre_paine6, ogre_paine7, ogre_paine8, ogre_paine9, ogre_paine10, ogre_paine11, ogre_paine12, ogre_paine13, ogre_paine14, ogre_paine15

ogre_paine1 = animation.frame("paine1", function() return ogre_paine2 end)
ogre_paine2 = animation.frame("paine2", function() return ogre_paine3 end, function(self) ai.pain(self, 10) end)
ogre_paine3 = animation.frame("paine3", function() return ogre_paine4 end, function(self) ai.pain(self, 9) end)
ogre_paine4 = animation.frame("paine4", function() return ogre_paine5 end, function(self) ai.pain(self, 4) end)
ogre_paine5 = animation.frame("paine5", function() return ogre_paine6 end)
ogre_paine6 = animation.frame("paine6", function() return ogre_paine7 end)
ogre_paine7 = animation.frame("paine7", function() return ogre_paine8 end)
ogre_paine8 = animation.frame("paine8", function() return ogre_paine9 end)
ogre_paine9 = animation.frame("paine9", function() return ogre_paine10 end)
ogre_paine10 = animation.frame("paine10", function() return ogre_paine11 end)
ogre_paine11 = animation.frame("paine11", function() return ogre_paine12 end)
ogre_paine12 = animation.frame("paine12", function() return ogre_paine13 end)
ogre_paine13 = animation.frame("paine13", function() return ogre_paine14 end)
ogre_paine14 = animation.frame("paine14", function() return ogre_paine15 end)
ogre_paine15 = animation.frame("paine15", function() return ogre_run1 end)

local function ogre_pain_callback(self, _attacker, _damage)
    -- don't make multiple pain sounds right after each other
    if self.pain_finished > quake.time() then return end
    quake.sound(self, C.CHAN_VOICE, "ogre/ogpain1.wav", 1, C.ATTN_NORM)
    local r = quake.random()
    if r < 0.25 then ogre_pain1(self); self.pain_finished = quake.time() + 1
    elseif r < 0.5 then ogre_painb1(self); self.pain_finished = quake.time() + 1
    elseif r < 0.75 then ogre_painc1(self); self.pain_finished = quake.time() + 1
    elseif r < 0.88 then ogre_paind1(self); self.pain_finished = quake.time() + 2
    else ogre_paine1(self); self.pain_finished = quake.time() + 2 end
end

local ogre_die1, ogre_die2, ogre_die3, ogre_die4, ogre_die5, ogre_die6, ogre_die7, ogre_die8, ogre_die9, ogre_die10, ogre_die11, ogre_die12, ogre_die13, ogre_die14

ogre_die1 = animation.frame("death1", function() return ogre_die2 end)
ogre_die2 = animation.frame("death2", function() return ogre_die3 end)
ogre_die3 = animation.frame("death3", function() return ogre_die4 end, function(self) self.solid = C.SOLID_NOT; self.ammo_rockets = 2; items.drop_backpack(self) end)
ogre_die4 = animation.frame("death4", function() return ogre_die5 end)
ogre_die5 = animation.frame("death5", function() return ogre_die6 end)
ogre_die6 = animation.frame("death6", function() return ogre_die7 end)
ogre_die7 = animation.frame("death7", function() return ogre_die8 end)
ogre_die8 = animation.frame("death8", function() return ogre_die9 end)
ogre_die9 = animation.frame("death9", function() return ogre_die10 end)
ogre_die10 = animation.frame("death10", function() return ogre_die11 end)
ogre_die11 = animation.frame("death11", function() return ogre_die12 end)
ogre_die12 = animation.frame("death12", function() return ogre_die13 end)
ogre_die13 = animation.frame("death13", function() return ogre_die14 end)
ogre_die14 = animation.frame("death14", function() return ogre_die14 end)

local ogre_bdie1, ogre_bdie2, ogre_bdie3, ogre_bdie4, ogre_bdie5, ogre_bdie6, ogre_bdie7, ogre_bdie8, ogre_bdie9, ogre_bdie10

ogre_bdie1 = animation.frame("bdeath1", function() return ogre_bdie2 end)
ogre_bdie2 = animation.frame("bdeath2", function() return ogre_bdie3 end, function(self) ai.forward(self, 5) end)
ogre_bdie3 = animation.frame("bdeath3", function() return ogre_bdie4 end, function(self) self.solid = C.SOLID_NOT; self.ammo_rockets = 2; items.drop_backpack(self) end)
ogre_bdie4 = animation.frame("bdeath4", function() return ogre_bdie5 end, function(self) ai.forward(self, 1) end)
ogre_bdie5 = animation.frame("bdeath5", function() return ogre_bdie6 end, function(self) ai.forward(self, 3) end)
ogre_bdie6 = animation.frame("bdeath6", function() return ogre_bdie7 end, function(self) ai.forward(self, 7) end)
ogre_bdie7 = animation.frame("bdeath7", function() return ogre_bdie8 end, function(self) ai.forward(self, 25) end)
ogre_bdie8 = animation.frame("bdeath8", function() return ogre_bdie9 end)
ogre_bdie9 = animation.frame("bdeath9", function() return ogre_bdie10 end)
ogre_bdie10 = animation.frame("bdeath10", function() return ogre_bdie10 end)

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
    if quake.random() < 0.5 then ogre_die1(self) else ogre_bdie1(self) end
end

local function ogre_melee(self)
    if quake.random() > 0.5 then ogre_smash1(self) else ogre_swing1(self) end
end

--[[QUAKED monster_ogre (1 0 0) (-32 -32 -24) (32 32 64) Ambush
]]
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
    self.th_stand = ogre_stand1
    self.th_walk = ogre_walk1
    self.th_run = ogre_run1
    self.th_die = ogre_die_callback
    self.th_melee = ogre_melee
    self.th_missile = ogre_nail1
    self.th_pain = ogre_pain_callback
    monsters.walk_start(self)
end

function M.spawn_marksman(self) M.spawn(self) end

quake.register_entity("monster_ogre", M.spawn)
quake.register_entity("monster_ogre_marksman", M.spawn_marksman)

return M
