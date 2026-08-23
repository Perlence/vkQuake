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

local ogre_stand = animation.loop({
    { f.stand1, function(self) ai.stand(self) end },
    { f.stand2, function(self) ai.stand(self) end },
    { f.stand3, function(self) ai.stand(self) end },
    { f.stand4, function(self) ai.stand(self) end },
    { f.stand5, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "ogre/ogidle.wav", 1, C.ATTN_IDLE) end; ai.stand(self) end },
    { f.stand6, function(self) ai.stand(self) end },
    { f.stand7, function(self) ai.stand(self) end },
    { f.stand8, function(self) ai.stand(self) end },
    { f.stand9, function(self) ai.stand(self) end },
})

local ogre_walk = animation.loop({
    { f.walk1, function(self) ai.walk(self, 3) end },
    { f.walk2, function(self) ai.walk(self, 2) end },
    { f.walk3, function(self) ai.walk(self, 2); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "ogre/ogidle.wav", 1, C.ATTN_IDLE) end end },
    { f.walk4, function(self) ai.walk(self, 2) end },
    { f.walk5, function(self) ai.walk(self, 2) end },
    { f.walk6, function(self) ai.walk(self, 5); if quake.random() < 0.1 then quake.sound(self, C.CHAN_VOICE, "ogre/ogdrag.wav", 1, C.ATTN_IDLE) end end },
    { f.walk7, function(self) ai.walk(self, 3) end },
    { f.walk8, function(self) ai.walk(self, 2) end },
    { f.walk9, function(self) ai.walk(self, 3) end },
    { f.walk10, function(self) ai.walk(self, 1) end },
    { f.walk11, function(self) ai.walk(self, 2) end },
    { f.walk12, function(self) ai.walk(self, 3) end },
    { f.walk13, function(self) ai.walk(self, 3) end },
    { f.walk14, function(self) ai.walk(self, 3) end },
    { f.walk15, function(self) ai.walk(self, 3) end },
    { f.walk16, function(self) ai.walk(self, 4) end },
})

local ogre_run = animation.loop({
    { f.run1, function(self) ai.run(self, 9); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "ogre/ogidle2.wav", 1, C.ATTN_IDLE) end end },
    { f.run2, function(self) ai.run(self, 12) end },
    { f.run3, function(self) ai.run(self, 8) end },
    { f.run4, function(self) ai.run(self, 22) end },
    { f.run5, function(self) ai.run(self, 16) end },
    { f.run6, function(self) ai.run(self, 4) end },
    { f.run7, function(self) ai.run(self, 13) end },
    { f.run8, function(self) ai.run(self, 24) end },
})

local ogre_swing = animation.sequence({
    { f.swing1, function(self) fight.charge(self, 11); quake.sound(self, C.CHAN_WEAPON, "ogre/ogsawatk.wav", 1, C.ATTN_NORM) end },
    { f.swing2, function(self) fight.charge(self, 1) end },
    { f.swing3, function(self) fight.charge(self, 4) end },
    { f.swing4, function(self) fight.charge(self, 13) end },
    { f.swing5, function(self) fight.charge(self, 9); chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end },
    { f.swing6, function(self) chainsaw(self, 200); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end },
    { f.swing7, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end },
    { f.swing8, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end },
    { f.swing9, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end },
    { f.swing10, function(self) chainsaw(self, -200); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end },
    { f.swing11, function(self) chainsaw(self, 0); self.angles = quake.vec3(self.angles.x, self.angles.y + quake.random() * 25, self.angles.z) end },
    { f.swing12, function(self) fight.charge(self, 3) end },
    { f.swing13, function(self) fight.charge(self, 8) end },
    { f.swing14, function(self) fight.charge(self, 9) end },
}, function() return ogre_run end)

local ogre_smash = animation.sequence({
    { f.smash1, function(self) fight.charge(self, 6); quake.sound(self, C.CHAN_WEAPON, "ogre/ogsawatk.wav", 1, C.ATTN_NORM) end },
    { f.smash2, function(self) fight.charge(self, 0) end },
    { f.smash3, function(self) fight.charge(self, 0) end },
    { f.smash4, function(self) fight.charge(self, 1) end },
    { f.smash5, function(self) fight.charge(self, 4) end },
    { f.smash6, function(self) fight.charge(self, 4); chainsaw(self, 0) end },
    { f.smash7, function(self) fight.charge(self, 4); chainsaw(self, 0) end },
    { f.smash8, function(self) fight.charge(self, 10); chainsaw(self, 0) end },
    { f.smash9, function(self) fight.charge(self, 13); chainsaw(self, 0) end },
    { f.smash10, function(self) chainsaw(self, 1) end },
    { f.smash11, function(self) fight.charge(self, 2); chainsaw(self, 0); -- slight variation
        self.nextthink = self.nextthink + quake.random() * 0.2 end },
    { f.smash12, function(self) fight.charge(self, 0) end },
    { f.smash13, function(self) fight.charge(self, 4) end },
    { f.smash14, function(self) fight.charge(self, 12) end },
}, function() return ogre_run end)

local ogre_nail = animation.sequence({
    { f.shoot1, function(self) fight.face(self) end },
    { f.shoot2, function(self) fight.face(self) end },
    { f.shoot2, function(self) fight.face(self) end },
    { f.shoot3, function(self) fight.face(self); ogre_fire_grenade(self) end },
    { f.shoot4, function(self) fight.face(self) end },
    { f.shoot5, function(self) fight.face(self) end },
    { f.shoot6, function(self) fight.face(self) end },
}, function() return ogre_run end)

local ogre_pain = animation.sequence({
    { f.pain1 },
    { f.pain2 },
    { f.pain3 },
    { f.pain4 },
    { f.pain5 },
}, function() return ogre_run end)

local ogre_painb = animation.sequence({
    { f.painb1 },
    { f.painb2 },
    { f.painb3 },
}, function() return ogre_run end)

local ogre_painc = animation.sequence({
    { f.painc1 },
    { f.painc2 },
    { f.painc3 },
    { f.painc4 },
    { f.painc5 },
    { f.painc6 },
}, function() return ogre_run end)

local ogre_paind = animation.sequence({
    { f.paind1 },
    { f.paind2, function(self) ai.pain(self, 10) end },
    { f.paind3, function(self) ai.pain(self, 9) end },
    { f.paind4, function(self) ai.pain(self, 4) end },
    { f.paind5 },
    { f.paind6 },
    { f.paind7 },
    { f.paind8 },
    { f.paind9 },
    { f.paind10 },
    { f.paind11 },
    { f.paind12 },
    { f.paind13 },
    { f.paind14 },
    { f.paind15 },
    { f.paind16 },
}, function() return ogre_run end)

local ogre_paine = animation.sequence({
    { f.paine1 },
    { f.paine2, function(self) ai.pain(self, 10) end },
    { f.paine3, function(self) ai.pain(self, 9) end },
    { f.paine4, function(self) ai.pain(self, 4) end },
    { f.paine5 },
    { f.paine6 },
    { f.paine7 },
    { f.paine8 },
    { f.paine9 },
    { f.paine10 },
    { f.paine11 },
    { f.paine12 },
    { f.paine13 },
    { f.paine14 },
    { f.paine15 },
}, function() return ogre_run end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function ogre_pain_callback(self, _attacker, _damage)
    -- don't make multiple pain sounds right after each other
    if self.pain_finished > quake.time() then return end
    quake.sound(self, C.CHAN_VOICE, "ogre/ogpain1.wav", 1, C.ATTN_NORM)
    local r = quake.random()
    if r < 0.25 then ogre_pain(self); self.pain_finished = quake.time() + 1
    elseif r < 0.5 then ogre_painb(self); self.pain_finished = quake.time() + 1
    elseif r < 0.75 then ogre_painc(self); self.pain_finished = quake.time() + 1
    elseif r < 0.88 then ogre_paind(self); self.pain_finished = quake.time() + 2
    else ogre_paine(self); self.pain_finished = quake.time() + 2 end
end

local ogre_die = animation.hold({
    { f.death1 },
    { f.death2 },
    { f.death3, function(self) self.solid = C.SOLID_NOT; self.ammo_rockets = 2; items.drop_backpack(self) end },
    { f.death4 },
    { f.death5 },
    { f.death6 },
    { f.death7 },
    { f.death8 },
    { f.death9 },
    { f.death10 },
    { f.death11 },
    { f.death12 },
    { f.death13 },
    { f.death14 },
})

local ogre_bdie = animation.hold({
    { f.bdeath1 },
    { f.bdeath2, function(self) ai.forward(self, 5) end },
    { f.bdeath3, function(self) self.solid = C.SOLID_NOT; self.ammo_rockets = 2; items.drop_backpack(self) end },
    { f.bdeath4, function(self) ai.forward(self, 1) end },
    { f.bdeath5, function(self) ai.forward(self, 3) end },
    { f.bdeath6, function(self) ai.forward(self, 7) end },
    { f.bdeath7, function(self) ai.forward(self, 25) end },
    { f.bdeath8 },
    { f.bdeath9 },
    { f.bdeath10 },
})

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
    if quake.random() < 0.5 then ogre_die(self) else ogre_bdie(self) end
end

---@param self entity
---@return nil
local function ogre_melee(self)
    if quake.random() > 0.5 then ogre_smash(self) else ogre_swing(self) end
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
    self.th_stand = ogre_stand
    self.th_walk = ogre_walk
    self.th_run = ogre_run
    self.th_die = ogre_die_callback
    self.th_melee = ogre_melee
    self.th_missile = ogre_nail
    self.th_pain = ogre_pain_callback
    monsters.walk_start(self)
end

---@param self entity
---@return nil
function M.spawn_marksman(self) M.spawn(self) end

quake.register_entity("monster_ogre", M.spawn)
quake.register_entity("monster_ogre_marksman", M.spawn_marksman)

return M
