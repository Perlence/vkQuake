-- Port of enforcer.qc from GPL-licensed CleanFixedQuakeC.
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
local items = require("game.items")
local monsters = require("game.monsters")
local subs = require("game.subs")
local weapons = require("game.weapons")

local M = {}

local count = animation.counter()
local f = {}

f.stand1, f.stand2, f.stand3, f.stand4, f.stand5, f.stand6,
    f.stand7 = count(7)

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
    f.walk7, f.walk8, f.walk9, f.walk10, f.walk11, f.walk12,
    f.walk13, f.walk14, f.walk15, f.walk16 = count(16)

f.run1, f.run2, f.run3, f.run4, f.run5, f.run6,
    f.run7, f.run8 = count(8)

f.attack1, f.attack2, f.attack3, f.attack4, f.attack5, f.attack6,
    f.attack7, f.attack8, f.attack9, f.attack10 = count(10)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
    f.death7, f.death8, f.death9, f.death10, f.death11, f.death12,
    f.death13, f.death14 = count(14)

f.fdeath1, f.fdeath2, f.fdeath3, f.fdeath4, f.fdeath5, f.fdeath6,
    f.fdeath7, f.fdeath8, f.fdeath9, f.fdeath10, f.fdeath11 = count(11)

f.paina1, f.paina2, f.paina3, f.paina4 = count(4)

f.painb1, f.painb2, f.painb3, f.painb4, f.painb5 = count(5)

f.painc1, f.painc2, f.painc3, f.painc4, f.painc5, f.painc6,
    f.painc7, f.painc8 = count(8)

f.paind1, f.paind2, f.paind3, f.paind4, f.paind5, f.paind6,
    f.paind7, f.paind8, f.paind9, f.paind10, f.paind11, f.paind12,
    f.paind13, f.paind14, f.paind15, f.paind16, f.paind17, f.paind18,
    f.paind19 = count(19)

local ATTN_IDLE = 2
local ATTN_STATIC = 3
local CHAN_WEAPON = 1
local CONTENT_SKY = -6
local EF_DIMLIGHT = 8
local EF_MUZZLEFLASH = 2
local MOVETYPE_FLY = 5
local SOLID_BBOX = 2

--[[
==============================================================================

SOLDIER / PLAYER (Enforcer)

==============================================================================
]]

---@param self entity
---@param other entity
---@return nil
local function laser_touch(self, other)
    if other == self.owner then
        -- don't explode on owner
        return
    end

    if quake.point_contents(self.origin) == CONTENT_SKY then
        quake.remove(self)
        return
    end

    quake.sound(self, CHAN_WEAPON, "enforcer/enfstop.wav", 1, ATTN_STATIC)
    local org = self.origin - self.velocity:normalized() * 8

    if other.health ~= 0 then
        weapons.spawn_blood(org, self.velocity * 0.2, 15)
        combat.damage(other, self, self.owner, 15)
    else
        quake.write_byte(0, 23)
        quake.write_byte(0, 2)
        quake.write_coord(0, org.x)
        quake.write_coord(0, org.y)
        quake.write_coord(0, org.z)
    end

    quake.remove(self)
end

---@param self entity
---@param org vec3
---@param vec vec3
---@return entity
local function launch_laser(self, org, vec)
    if self.classname == "monster_enforcer" then
        quake.sound(self, CHAN_WEAPON, "enforcer/enfire.wav", 1, C.ATTN_NORM)
    end

    local new_vec = vec:normalized()

    local newmis = quake.spawn()
    newmis.owner = self
    newmis.movetype = MOVETYPE_FLY
    newmis.solid = SOLID_BBOX
    newmis.effects = EF_DIMLIGHT

    quake.set_model(newmis, "progs/laser.mdl")
    quake.set_size(newmis, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))

    quake.set_origin(newmis, org)

    newmis.velocity = new_vec * 600
    newmis.angles = quake.vector_to_angles(newmis.velocity)

    newmis.nextthink = quake.time() + 5
    newmis.think = subs.remove
    newmis.touch = laser_touch
    return newmis
end

---@param self entity
---@return nil
local function enforcer_fire(self)
    self.effects = self.effects | EF_MUZZLEFLASH
    local vectors = quake.make_vectors(self.angles)

    local org = self.origin + vectors.forward * 30 + vectors.right * 8.5 + quake.vec3(0, 0, 16)

    launch_laser(self, org, self.enemy.origin - self.origin)
end

--============================================================================

local enf_stand1, enf_stand2, enf_stand3, enf_stand4, enf_stand5, enf_stand6
local enf_stand7

enf_stand1 = animation.frame(f.stand1, function() return enf_stand2 end, ai.stand)
enf_stand2 = animation.frame(f.stand2, function() return enf_stand3 end, ai.stand)
enf_stand3 = animation.frame(f.stand3, function() return enf_stand4 end, ai.stand)
enf_stand4 = animation.frame(f.stand4, function() return enf_stand5 end, ai.stand)
enf_stand5 = animation.frame(f.stand5, function() return enf_stand6 end, ai.stand)
enf_stand6 = animation.frame(f.stand6, function() return enf_stand7 end, ai.stand)
enf_stand7 = animation.frame(f.stand7, function() return enf_stand1 end, ai.stand)

local enf_walk1, enf_walk2, enf_walk3, enf_walk4, enf_walk5, enf_walk6
local enf_walk7, enf_walk8, enf_walk9, enf_walk10, enf_walk11, enf_walk12
local enf_walk13, enf_walk14, enf_walk15, enf_walk16

enf_walk1 = animation.frame(f.walk1, function() return enf_walk2 end, function(self)
    if quake.random() < 0.2 then
        quake.sound(self, C.CHAN_VOICE, "enforcer/idle1.wav", 1, ATTN_IDLE)
    end
    ai.walk(self, 2)
end)
enf_walk2 = animation.frame(f.walk2, function() return enf_walk3 end, function(self) ai.walk(self, 4) end)
enf_walk3 = animation.frame(f.walk3, function() return enf_walk4 end, function(self) ai.walk(self, 4) end)
enf_walk4 = animation.frame(f.walk4, function() return enf_walk5 end, function(self) ai.walk(self, 3) end)
enf_walk5 = animation.frame(f.walk5, function() return enf_walk6 end, function(self) ai.walk(self, 1) end)
enf_walk6 = animation.frame(f.walk6, function() return enf_walk7 end, function(self) ai.walk(self, 2) end)
enf_walk7 = animation.frame(f.walk7, function() return enf_walk8 end, function(self) ai.walk(self, 2) end)
enf_walk8 = animation.frame(f.walk8, function() return enf_walk9 end, function(self) ai.walk(self, 1) end)
enf_walk9 = animation.frame(f.walk9, function() return enf_walk10 end, function(self) ai.walk(self, 2) end)
enf_walk10 = animation.frame(f.walk10, function() return enf_walk11 end, function(self) ai.walk(self, 4) end)
enf_walk11 = animation.frame(f.walk11, function() return enf_walk12 end, function(self) ai.walk(self, 4) end)
enf_walk12 = animation.frame(f.walk12, function() return enf_walk13 end, function(self) ai.walk(self, 1) end)
enf_walk13 = animation.frame(f.walk13, function() return enf_walk14 end, function(self) ai.walk(self, 2) end)
enf_walk14 = animation.frame(f.walk14, function() return enf_walk15 end, function(self) ai.walk(self, 3) end)
enf_walk15 = animation.frame(f.walk15, function() return enf_walk16 end, function(self) ai.walk(self, 4) end)
enf_walk16 = animation.frame(f.walk16, function() return enf_walk1 end, function(self) ai.walk(self, 2) end)

local enf_run1, enf_run2, enf_run3, enf_run4, enf_run5, enf_run6
local enf_run7, enf_run8

enf_run1 = animation.frame(f.run1, function() return enf_run2 end, function(self)
    if quake.random() < 0.2 then
        quake.sound(self, C.CHAN_VOICE, "enforcer/idle1.wav", 1, ATTN_IDLE)
    end
    ai.run(self, 18)
end)
enf_run2 = animation.frame(f.run2, function() return enf_run3 end, function(self) ai.run(self, 14) end)
enf_run3 = animation.frame(f.run3, function() return enf_run4 end, function(self) ai.run(self, 7) end)
enf_run4 = animation.frame(f.run4, function() return enf_run5 end, function(self) ai.run(self, 12) end)
enf_run5 = animation.frame(f.run5, function() return enf_run6 end, function(self) ai.run(self, 14) end)
enf_run6 = animation.frame(f.run6, function() return enf_run7 end, function(self) ai.run(self, 14) end)
enf_run7 = animation.frame(f.run7, function() return enf_run8 end, function(self) ai.run(self, 7) end)
enf_run8 = animation.frame(f.run8, function() return enf_run1 end, function(self) ai.run(self, 11) end)

local enf_atk1, enf_atk2, enf_atk3, enf_atk4, enf_atk5, enf_atk6
local enf_atk7, enf_atk8, enf_atk9, enf_atk10, enf_atk11, enf_atk12
local enf_atk13, enf_atk14

enf_atk1 = animation.frame(f.attack1, function() return enf_atk2 end, fight.face)
enf_atk2 = animation.frame(f.attack2, function() return enf_atk3 end, fight.face)
enf_atk3 = animation.frame(f.attack3, function() return enf_atk4 end, fight.face)
enf_atk4 = animation.frame(f.attack4, function() return enf_atk5 end, fight.face)
enf_atk5 = animation.frame(f.attack5, function() return enf_atk6 end, fight.face)
enf_atk6 = animation.frame(f.attack6, function() return enf_atk7 end, enforcer_fire)
enf_atk7 = animation.frame(f.attack7, function() return enf_atk8 end, fight.face)
enf_atk8 = animation.frame(f.attack8, function() return enf_atk9 end, fight.face)
enf_atk9 = animation.frame(f.attack5, function() return enf_atk10 end, fight.face)
enf_atk10 = animation.frame(f.attack6, function() return enf_atk11 end, enforcer_fire)
enf_atk11 = animation.frame(f.attack7, function() return enf_atk12 end, fight.face)
enf_atk12 = animation.frame(f.attack8, function() return enf_atk13 end, fight.face)
enf_atk13 = animation.frame(f.attack9, function() return enf_atk14 end, fight.face)
enf_atk14 = animation.frame(f.attack10, function() return enf_run1 end, function(self)
    fight.face(self)
    subs.check_refire(self, enf_atk1)
end)

local enf_paina1, enf_paina2, enf_paina3, enf_paina4

enf_paina1 = animation.frame(f.paina1, function() return enf_paina2 end)
enf_paina2 = animation.frame(f.paina2, function() return enf_paina3 end)
enf_paina3 = animation.frame(f.paina3, function() return enf_paina4 end)
enf_paina4 = animation.frame(f.paina4, function() return enf_run1 end)

local enf_painb1, enf_painb2, enf_painb3, enf_painb4, enf_painb5

enf_painb1 = animation.frame(f.painb1, function() return enf_painb2 end)
enf_painb2 = animation.frame(f.painb2, function() return enf_painb3 end)
enf_painb3 = animation.frame(f.painb3, function() return enf_painb4 end)
enf_painb4 = animation.frame(f.painb4, function() return enf_painb5 end)
enf_painb5 = animation.frame(f.painb5, function() return enf_run1 end)

local enf_painc1, enf_painc2, enf_painc3, enf_painc4, enf_painc5, enf_painc6
local enf_painc7, enf_painc8

enf_painc1 = animation.frame(f.painc1, function() return enf_painc2 end)
enf_painc2 = animation.frame(f.painc2, function() return enf_painc3 end)
enf_painc3 = animation.frame(f.painc3, function() return enf_painc4 end)
enf_painc4 = animation.frame(f.painc4, function() return enf_painc5 end)
enf_painc5 = animation.frame(f.painc5, function() return enf_painc6 end)
enf_painc6 = animation.frame(f.painc6, function() return enf_painc7 end)
enf_painc7 = animation.frame(f.painc7, function() return enf_painc8 end)
enf_painc8 = animation.frame(f.painc8, function() return enf_run1 end)

local enf_paind1, enf_paind2, enf_paind3, enf_paind4, enf_paind5, enf_paind6
local enf_paind7, enf_paind8, enf_paind9, enf_paind10, enf_paind11, enf_paind12
local enf_paind13, enf_paind14, enf_paind15, enf_paind16, enf_paind17, enf_paind18
local enf_paind19

enf_paind1 = animation.frame(f.paind1, function() return enf_paind2 end)
enf_paind2 = animation.frame(f.paind2, function() return enf_paind3 end)
enf_paind3 = animation.frame(f.paind3, function() return enf_paind4 end)
enf_paind4 = animation.frame(f.paind4, function() return enf_paind5 end, function(self) quake.walk_move(self, self.ideal_yaw, 2) end)
enf_paind5 = animation.frame(f.paind5, function() return enf_paind6 end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind6 = animation.frame(f.paind6, function() return enf_paind7 end)
enf_paind7 = animation.frame(f.paind7, function() return enf_paind8 end)
enf_paind8 = animation.frame(f.paind8, function() return enf_paind9 end)
enf_paind9 = animation.frame(f.paind9, function() return enf_paind10 end)
enf_paind10 = animation.frame(f.paind10, function() return enf_paind11 end)
enf_paind11 = animation.frame(f.paind11, function() return enf_paind12 end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind12 = animation.frame(f.paind12, function() return enf_paind13 end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind13 = animation.frame(f.paind13, function() return enf_paind14 end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind14 = animation.frame(f.paind14, function() return enf_paind15 end)
enf_paind15 = animation.frame(f.paind15, function() return enf_paind16 end)
enf_paind16 = animation.frame(f.paind16, function() return enf_paind17 end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind17 = animation.frame(f.paind17, function() return enf_paind18 end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind18 = animation.frame(f.paind18, function() return enf_paind19 end)
enf_paind19 = animation.frame(f.paind19, function() return enf_run1 end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function enf_pain(self, _attacker, _damage)
    local r = quake.random()
    if self.pain_finished > quake.time() then
        return
    end

    if r < 0.5 then
        quake.sound(self, C.CHAN_VOICE, "enforcer/pain1.wav", 1, C.ATTN_NORM)
    else
        quake.sound(self, C.CHAN_VOICE, "enforcer/pain2.wav", 1, C.ATTN_NORM)
    end

    if r < 0.2 then
        self.pain_finished = quake.time() + 1
        enf_paina1(self)
    elseif r < 0.4 then
        self.pain_finished = quake.time() + 1
        enf_painb1(self)
    elseif r < 0.7 then
        self.pain_finished = quake.time() + 1
        enf_painc1(self)
    else
        self.pain_finished = quake.time() + 2
        enf_paind1(self)
    end
end

--============================================================================

local enf_die1, enf_die2, enf_die3, enf_die4, enf_die5, enf_die6
local enf_die7, enf_die8, enf_die9, enf_die10, enf_die11, enf_die12
local enf_die13, enf_die14

enf_die1 = animation.frame(f.death1, function() return enf_die2 end)
enf_die2 = animation.frame(f.death2, function() return enf_die3 end)
enf_die3 = animation.frame(f.death3, function() return enf_die4 end, function(self)
    self.solid = C.SOLID_NOT
    self.ammo_cells = 5
    items.drop_backpack(self)
end)
enf_die4 = animation.frame(f.death4, function() return enf_die5 end, function(self) quake.walk_move(self, self.angles.y, 14) end)
enf_die5 = animation.frame(f.death5, function() return enf_die6 end, function(self) quake.walk_move(self, self.angles.y, 2) end)
enf_die6 = animation.frame(f.death6, function() return enf_die7 end)
enf_die7 = animation.frame(f.death7, function() return enf_die8 end)
enf_die8 = animation.frame(f.death8, function() return enf_die9 end)
enf_die9 = animation.frame(f.death9, function() return enf_die10 end, function(self) quake.walk_move(self, self.angles.y, 3) end)
enf_die10 = animation.frame(f.death10, function() return enf_die11 end, function(self) quake.walk_move(self, self.angles.y, 5) end)
enf_die11 = animation.frame(f.death11, function() return enf_die12 end, function(self) quake.walk_move(self, self.angles.y, 5) end)
enf_die12 = animation.frame(f.death12, function() return enf_die13 end, function(self) quake.walk_move(self, self.angles.y, 5) end)
enf_die13 = animation.frame(f.death13, function() return enf_die14 end)
enf_die14 = animation.frame(f.death14, function() return enf_die14 end)

local enf_fdie1, enf_fdie2, enf_fdie3, enf_fdie4, enf_fdie5, enf_fdie6
local enf_fdie7, enf_fdie8, enf_fdie9, enf_fdie10, enf_fdie11

enf_fdie1 = animation.frame(f.fdeath1, function() return enf_fdie2 end)
enf_fdie2 = animation.frame(f.fdeath2, function() return enf_fdie3 end)
enf_fdie3 = animation.frame(f.fdeath3, function() return enf_fdie4 end, function(self)
    self.solid = C.SOLID_NOT
    self.ammo_cells = 5
    items.drop_backpack(self)
end)
enf_fdie4 = animation.frame(f.fdeath4, function() return enf_fdie5 end)
enf_fdie5 = animation.frame(f.fdeath5, function() return enf_fdie6 end)
enf_fdie6 = animation.frame(f.fdeath6, function() return enf_fdie7 end)
enf_fdie7 = animation.frame(f.fdeath7, function() return enf_fdie8 end)
enf_fdie8 = animation.frame(f.fdeath8, function() return enf_fdie9 end)
enf_fdie9 = animation.frame(f.fdeath9, function() return enf_fdie10 end)
enf_fdie10 = animation.frame(f.fdeath10, function() return enf_fdie11 end)
enf_fdie11 = animation.frame(f.fdeath11, function() return enf_fdie11 end)

---@param self entity
---@return nil
local function enf_die(self)
    -- check for gib
    if self.health < -35 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw_head(self, "progs/h_mega.mdl", self.health)
        gibs.throw(self, "progs/gib1.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        return
    end

    -- regular death
    quake.sound(self, C.CHAN_VOICE, "enforcer/death1.wav", 1, C.ATTN_NORM)
    if quake.random() > 0.5 then
        enf_die1(self)
    else
        enf_fdie1(self)
    end
end

---QUAKED monster_enforcer (1 0 0) (-16 -16 -24) (16 16 40) Ambush
---@param self entity
---@return nil
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end
    quake.precache_model2("progs/enforcer.mdl")
    quake.precache_model2("progs/h_mega.mdl")
    quake.precache_model2("progs/laser.mdl")

    quake.precache_sound2("enforcer/death1.wav")
    quake.precache_sound2("enforcer/enfire.wav")
    quake.precache_sound2("enforcer/enfstop.wav")
    quake.precache_sound2("enforcer/idle1.wav")
    quake.precache_sound2("enforcer/pain1.wav")
    quake.precache_sound2("enforcer/pain2.wav")
    quake.precache_sound2("enforcer/sight1.wav")
    quake.precache_sound2("enforcer/sight2.wav")
    quake.precache_sound2("enforcer/sight3.wav")
    quake.precache_sound2("enforcer/sight4.wav")

    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP

    quake.set_model(self, "progs/enforcer.mdl")

    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 40))
    self.health = 80

    self.th_stand = enf_stand1
    self.th_walk = enf_walk1
    self.th_run = enf_run1
    self.th_pain = enf_pain
    self.th_die = enf_die
    self.th_missile = enf_atk1

    monsters.walk_start(self)
end

M.launch_laser = launch_laser

quake.register_entity("monster_enforcer", M.spawn)

return M
