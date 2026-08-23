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

local enf_stand = {}
enf_stand[1] = animation.frame(f.stand1, function() return enf_stand[2] end, ai.stand)
enf_stand[2] = animation.frame(f.stand2, function() return enf_stand[3] end, ai.stand)
enf_stand[3] = animation.frame(f.stand3, function() return enf_stand[4] end, ai.stand)
enf_stand[4] = animation.frame(f.stand4, function() return enf_stand[5] end, ai.stand)
enf_stand[5] = animation.frame(f.stand5, function() return enf_stand[6] end, ai.stand)
enf_stand[6] = animation.frame(f.stand6, function() return enf_stand[7] end, ai.stand)
enf_stand[7] = animation.frame(f.stand7, function() return enf_stand[1] end, ai.stand)

local enf_walk = {}
enf_walk[1] = animation.frame(f.walk1, function() return enf_walk[2] end, function(self)
    if quake.random() < 0.2 then
        quake.sound(self, C.CHAN_VOICE, "enforcer/idle1.wav", 1, ATTN_IDLE)
    end
    ai.walk(self, 2)
end)
enf_walk[2] = animation.frame(f.walk2, function() return enf_walk[3] end, function(self) ai.walk(self, 4) end)
enf_walk[3] = animation.frame(f.walk3, function() return enf_walk[4] end, function(self) ai.walk(self, 4) end)
enf_walk[4] = animation.frame(f.walk4, function() return enf_walk[5] end, function(self) ai.walk(self, 3) end)
enf_walk[5] = animation.frame(f.walk5, function() return enf_walk[6] end, function(self) ai.walk(self, 1) end)
enf_walk[6] = animation.frame(f.walk6, function() return enf_walk[7] end, function(self) ai.walk(self, 2) end)
enf_walk[7] = animation.frame(f.walk7, function() return enf_walk[8] end, function(self) ai.walk(self, 2) end)
enf_walk[8] = animation.frame(f.walk8, function() return enf_walk[9] end, function(self) ai.walk(self, 1) end)
enf_walk[9] = animation.frame(f.walk9, function() return enf_walk[10] end, function(self) ai.walk(self, 2) end)
enf_walk[10] = animation.frame(f.walk10, function() return enf_walk[11] end, function(self) ai.walk(self, 4) end)
enf_walk[11] = animation.frame(f.walk11, function() return enf_walk[12] end, function(self) ai.walk(self, 4) end)
enf_walk[12] = animation.frame(f.walk12, function() return enf_walk[13] end, function(self) ai.walk(self, 1) end)
enf_walk[13] = animation.frame(f.walk13, function() return enf_walk[14] end, function(self) ai.walk(self, 2) end)
enf_walk[14] = animation.frame(f.walk14, function() return enf_walk[15] end, function(self) ai.walk(self, 3) end)
enf_walk[15] = animation.frame(f.walk15, function() return enf_walk[16] end, function(self) ai.walk(self, 4) end)
enf_walk[16] = animation.frame(f.walk16, function() return enf_walk[1] end, function(self) ai.walk(self, 2) end)

local enf_run = {}
enf_run[1] = animation.frame(f.run1, function() return enf_run[2] end, function(self)
    if quake.random() < 0.2 then
        quake.sound(self, C.CHAN_VOICE, "enforcer/idle1.wav", 1, ATTN_IDLE)
    end
    ai.run(self, 18)
end)
enf_run[2] = animation.frame(f.run2, function() return enf_run[3] end, function(self) ai.run(self, 14) end)
enf_run[3] = animation.frame(f.run3, function() return enf_run[4] end, function(self) ai.run(self, 7) end)
enf_run[4] = animation.frame(f.run4, function() return enf_run[5] end, function(self) ai.run(self, 12) end)
enf_run[5] = animation.frame(f.run5, function() return enf_run[6] end, function(self) ai.run(self, 14) end)
enf_run[6] = animation.frame(f.run6, function() return enf_run[7] end, function(self) ai.run(self, 14) end)
enf_run[7] = animation.frame(f.run7, function() return enf_run[8] end, function(self) ai.run(self, 7) end)
enf_run[8] = animation.frame(f.run8, function() return enf_run[1] end, function(self) ai.run(self, 11) end)

local enf_atk = {}
enf_atk[1] = animation.frame(f.attack1, function() return enf_atk[2] end, fight.face)
enf_atk[2] = animation.frame(f.attack2, function() return enf_atk[3] end, fight.face)
enf_atk[3] = animation.frame(f.attack3, function() return enf_atk[4] end, fight.face)
enf_atk[4] = animation.frame(f.attack4, function() return enf_atk[5] end, fight.face)
enf_atk[5] = animation.frame(f.attack5, function() return enf_atk[6] end, fight.face)
enf_atk[6] = animation.frame(f.attack6, function() return enf_atk[7] end, enforcer_fire)
enf_atk[7] = animation.frame(f.attack7, function() return enf_atk[8] end, fight.face)
enf_atk[8] = animation.frame(f.attack8, function() return enf_atk[9] end, fight.face)
enf_atk[9] = animation.frame(f.attack5, function() return enf_atk[10] end, fight.face)
enf_atk[10] = animation.frame(f.attack6, function() return enf_atk[11] end, enforcer_fire)
enf_atk[11] = animation.frame(f.attack7, function() return enf_atk[12] end, fight.face)
enf_atk[12] = animation.frame(f.attack8, function() return enf_atk[13] end, fight.face)
enf_atk[13] = animation.frame(f.attack9, function() return enf_atk[14] end, fight.face)
enf_atk[14] = animation.frame(f.attack10, function() return enf_run[1] end, function(self)
    fight.face(self)
    subs.check_refire(self, enf_atk[1])
end)

local enf_paina = {}
enf_paina[1] = animation.frame(f.paina1, function() return enf_paina[2] end)
enf_paina[2] = animation.frame(f.paina2, function() return enf_paina[3] end)
enf_paina[3] = animation.frame(f.paina3, function() return enf_paina[4] end)
enf_paina[4] = animation.frame(f.paina4, function() return enf_run[1] end)

local enf_painb = {}
enf_painb[1] = animation.frame(f.painb1, function() return enf_painb[2] end)
enf_painb[2] = animation.frame(f.painb2, function() return enf_painb[3] end)
enf_painb[3] = animation.frame(f.painb3, function() return enf_painb[4] end)
enf_painb[4] = animation.frame(f.painb4, function() return enf_painb[5] end)
enf_painb[5] = animation.frame(f.painb5, function() return enf_run[1] end)

local enf_painc = {}
enf_painc[1] = animation.frame(f.painc1, function() return enf_painc[2] end)
enf_painc[2] = animation.frame(f.painc2, function() return enf_painc[3] end)
enf_painc[3] = animation.frame(f.painc3, function() return enf_painc[4] end)
enf_painc[4] = animation.frame(f.painc4, function() return enf_painc[5] end)
enf_painc[5] = animation.frame(f.painc5, function() return enf_painc[6] end)
enf_painc[6] = animation.frame(f.painc6, function() return enf_painc[7] end)
enf_painc[7] = animation.frame(f.painc7, function() return enf_painc[8] end)
enf_painc[8] = animation.frame(f.painc8, function() return enf_run[1] end)

local enf_paind = {}
enf_paind[1] = animation.frame(f.paind1, function() return enf_paind[2] end)
enf_paind[2] = animation.frame(f.paind2, function() return enf_paind[3] end)
enf_paind[3] = animation.frame(f.paind3, function() return enf_paind[4] end)
enf_paind[4] = animation.frame(f.paind4, function() return enf_paind[5] end, function(self) quake.walk_move(self, self.ideal_yaw, 2) end)
enf_paind[5] = animation.frame(f.paind5, function() return enf_paind[6] end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind[6] = animation.frame(f.paind6, function() return enf_paind[7] end)
enf_paind[7] = animation.frame(f.paind7, function() return enf_paind[8] end)
enf_paind[8] = animation.frame(f.paind8, function() return enf_paind[9] end)
enf_paind[9] = animation.frame(f.paind9, function() return enf_paind[10] end)
enf_paind[10] = animation.frame(f.paind10, function() return enf_paind[11] end)
enf_paind[11] = animation.frame(f.paind11, function() return enf_paind[12] end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind[12] = animation.frame(f.paind12, function() return enf_paind[13] end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind[13] = animation.frame(f.paind13, function() return enf_paind[14] end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind[14] = animation.frame(f.paind14, function() return enf_paind[15] end)
enf_paind[15] = animation.frame(f.paind15, function() return enf_paind[16] end)
enf_paind[16] = animation.frame(f.paind16, function() return enf_paind[17] end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind[17] = animation.frame(f.paind17, function() return enf_paind[18] end, function(self) quake.walk_move(self, self.ideal_yaw, 1) end)
enf_paind[18] = animation.frame(f.paind18, function() return enf_paind[19] end)
enf_paind[19] = animation.frame(f.paind19, function() return enf_run[1] end)

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
        enf_paina[1](self)
    elseif r < 0.4 then
        self.pain_finished = quake.time() + 1
        enf_painb[1](self)
    elseif r < 0.7 then
        self.pain_finished = quake.time() + 1
        enf_painc[1](self)
    else
        self.pain_finished = quake.time() + 2
        enf_paind[1](self)
    end
end

--============================================================================

local enf_die = {}
enf_die[1] = animation.frame(f.death1, function() return enf_die[2] end)
enf_die[2] = animation.frame(f.death2, function() return enf_die[3] end)
enf_die[3] = animation.frame(f.death3, function() return enf_die[4] end, function(self)
    self.solid = C.SOLID_NOT
    self.ammo_cells = 5
    items.drop_backpack(self)
end)
enf_die[4] = animation.frame(f.death4, function() return enf_die[5] end, function(self) quake.walk_move(self, self.angles.y, 14) end)
enf_die[5] = animation.frame(f.death5, function() return enf_die[6] end, function(self) quake.walk_move(self, self.angles.y, 2) end)
enf_die[6] = animation.frame(f.death6, function() return enf_die[7] end)
enf_die[7] = animation.frame(f.death7, function() return enf_die[8] end)
enf_die[8] = animation.frame(f.death8, function() return enf_die[9] end)
enf_die[9] = animation.frame(f.death9, function() return enf_die[10] end, function(self) quake.walk_move(self, self.angles.y, 3) end)
enf_die[10] = animation.frame(f.death10, function() return enf_die[11] end, function(self) quake.walk_move(self, self.angles.y, 5) end)
enf_die[11] = animation.frame(f.death11, function() return enf_die[12] end, function(self) quake.walk_move(self, self.angles.y, 5) end)
enf_die[12] = animation.frame(f.death12, function() return enf_die[13] end, function(self) quake.walk_move(self, self.angles.y, 5) end)
enf_die[13] = animation.frame(f.death13, function() return enf_die[14] end)
enf_die[14] = animation.frame(f.death14, function() return enf_die[14] end)

local enf_fdie = {}
enf_fdie[1] = animation.frame(f.fdeath1, function() return enf_fdie[2] end)
enf_fdie[2] = animation.frame(f.fdeath2, function() return enf_fdie[3] end)
enf_fdie[3] = animation.frame(f.fdeath3, function() return enf_fdie[4] end, function(self)
    self.solid = C.SOLID_NOT
    self.ammo_cells = 5
    items.drop_backpack(self)
end)
enf_fdie[4] = animation.frame(f.fdeath4, function() return enf_fdie[5] end)
enf_fdie[5] = animation.frame(f.fdeath5, function() return enf_fdie[6] end)
enf_fdie[6] = animation.frame(f.fdeath6, function() return enf_fdie[7] end)
enf_fdie[7] = animation.frame(f.fdeath7, function() return enf_fdie[8] end)
enf_fdie[8] = animation.frame(f.fdeath8, function() return enf_fdie[9] end)
enf_fdie[9] = animation.frame(f.fdeath9, function() return enf_fdie[10] end)
enf_fdie[10] = animation.frame(f.fdeath10, function() return enf_fdie[11] end)
enf_fdie[11] = animation.frame(f.fdeath11, function() return enf_fdie[11] end)

---@param self entity
---@return nil
local function enf_die_handler(self)
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
        enf_die[1](self)
    else
        enf_fdie[1](self)
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

    self.th_stand = enf_stand[1]
    self.th_walk = enf_walk[1]
    self.th_run = enf_run[1]
    self.th_pain = enf_pain
    self.th_die = enf_die_handler
    self.th_missile = enf_atk[1]

    monsters.walk_start(self)
end

M.launch_laser = launch_laser

quake.register_entity("monster_enforcer", M.spawn)

return M
