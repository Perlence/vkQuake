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

local enf_stand = animation.loop({
    { f.stand1, ai.stand },
    { f.stand2, ai.stand },
    { f.stand3, ai.stand },
    { f.stand4, ai.stand },
    { f.stand5, ai.stand },
    { f.stand6, ai.stand },
    { f.stand7, ai.stand },
})

local enf_walk = animation.loop({
    { f.walk1, function(self)
        if quake.random() < 0.2 then
            quake.sound(self, C.CHAN_VOICE, "enforcer/idle1.wav", 1, ATTN_IDLE)
        end
        ai.walk(self, 2)
    end },
    { f.walk2, function(self) ai.walk(self, 4) end },
    { f.walk3, function(self) ai.walk(self, 4) end },
    { f.walk4, function(self) ai.walk(self, 3) end },
    { f.walk5, function(self) ai.walk(self, 1) end },
    { f.walk6, function(self) ai.walk(self, 2) end },
    { f.walk7, function(self) ai.walk(self, 2) end },
    { f.walk8, function(self) ai.walk(self, 1) end },
    { f.walk9, function(self) ai.walk(self, 2) end },
    { f.walk10, function(self) ai.walk(self, 4) end },
    { f.walk11, function(self) ai.walk(self, 4) end },
    { f.walk12, function(self) ai.walk(self, 1) end },
    { f.walk13, function(self) ai.walk(self, 2) end },
    { f.walk14, function(self) ai.walk(self, 3) end },
    { f.walk15, function(self) ai.walk(self, 4) end },
    { f.walk16, function(self) ai.walk(self, 2) end },
})

local enf_run = animation.loop({
    { f.run1, function(self)
        if quake.random() < 0.2 then
            quake.sound(self, C.CHAN_VOICE, "enforcer/idle1.wav", 1, ATTN_IDLE)
        end
        ai.run(self, 18)
    end },
    { f.run2, function(self) ai.run(self, 14) end },
    { f.run3, function(self) ai.run(self, 7) end },
    { f.run4, function(self) ai.run(self, 12) end },
    { f.run5, function(self) ai.run(self, 14) end },
    { f.run6, function(self) ai.run(self, 14) end },
    { f.run7, function(self) ai.run(self, 7) end },
    { f.run8, function(self) ai.run(self, 11) end },
})

local enf_atk
enf_atk = animation.sequence({
    { f.attack1, fight.face },
    { f.attack2, fight.face },
    { f.attack3, fight.face },
    { f.attack4, fight.face },
    { f.attack5, fight.face },
    { f.attack6, enforcer_fire },
    { f.attack7, fight.face },
    { f.attack8, fight.face },
    { f.attack5, fight.face },
    { f.attack6, enforcer_fire },
    { f.attack7, fight.face },
    { f.attack8, fight.face },
    { f.attack9, fight.face },
    { f.attack10, function(self)
        fight.face(self)
        subs.check_refire(self, enf_atk)
    end },
}, function() return enf_run end)

local enf_paina = animation.sequence({
    { f.paina1 },
    { f.paina2 },
    { f.paina3 },
    { f.paina4 },
}, function() return enf_run end)

local enf_painb = animation.sequence({
    { f.painb1 },
    { f.painb2 },
    { f.painb3 },
    { f.painb4 },
    { f.painb5 },
}, function() return enf_run end)

local enf_painc = animation.sequence({
    { f.painc1 },
    { f.painc2 },
    { f.painc3 },
    { f.painc4 },
    { f.painc5 },
    { f.painc6 },
    { f.painc7 },
    { f.painc8 },
}, function() return enf_run end)

local enf_paind = animation.sequence({
    { f.paind1 },
    { f.paind2 },
    { f.paind3 },
    { f.paind4, function(self) quake.walk_move(self, self.ideal_yaw, 2) end },
    { f.paind5, function(self) quake.walk_move(self, self.ideal_yaw, 1) end },
    { f.paind6 },
    { f.paind7 },
    { f.paind8 },
    { f.paind9 },
    { f.paind10 },
    { f.paind11, function(self) quake.walk_move(self, self.ideal_yaw, 1) end },
    { f.paind12, function(self) quake.walk_move(self, self.ideal_yaw, 1) end },
    { f.paind13, function(self) quake.walk_move(self, self.ideal_yaw, 1) end },
    { f.paind14 },
    { f.paind15 },
    { f.paind16, function(self) quake.walk_move(self, self.ideal_yaw, 1) end },
    { f.paind17, function(self) quake.walk_move(self, self.ideal_yaw, 1) end },
    { f.paind18 },
    { f.paind19 },
}, function() return enf_run end)

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
        enf_paina(self)
    elseif r < 0.4 then
        self.pain_finished = quake.time() + 1
        enf_painb(self)
    elseif r < 0.7 then
        self.pain_finished = quake.time() + 1
        enf_painc(self)
    else
        self.pain_finished = quake.time() + 2
        enf_paind(self)
    end
end

--============================================================================

local enf_die = animation.hold({
    { f.death1 },
    { f.death2 },
    { f.death3, function(self)
        self.solid = C.SOLID_NOT
        self.ammo_cells = 5
        items.drop_backpack(self)
    end },
    { f.death4, function(self) quake.walk_move(self, self.angles.y, 14) end },
    { f.death5, function(self) quake.walk_move(self, self.angles.y, 2) end },
    { f.death6 },
    { f.death7 },
    { f.death8 },
    { f.death9, function(self) quake.walk_move(self, self.angles.y, 3) end },
    { f.death10, function(self) quake.walk_move(self, self.angles.y, 5) end },
    { f.death11, function(self) quake.walk_move(self, self.angles.y, 5) end },
    { f.death12, function(self) quake.walk_move(self, self.angles.y, 5) end },
    { f.death13 },
    { f.death14 },
})

local enf_fdie = animation.hold({
    { f.fdeath1 },
    { f.fdeath2 },
    { f.fdeath3, function(self)
        self.solid = C.SOLID_NOT
        self.ammo_cells = 5
        items.drop_backpack(self)
    end },
    { f.fdeath4 },
    { f.fdeath5 },
    { f.fdeath6 },
    { f.fdeath7 },
    { f.fdeath8 },
    { f.fdeath9 },
    { f.fdeath10 },
    { f.fdeath11 },
})

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
        enf_die(self)
    else
        enf_fdie(self)
    end
end

---QUAKED monster_enforcer (1 0 0) (-16 -16 -24) (16 16 40) Ambush
---@param self entity
---@return nil
local function spawn(self)
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

    self.th_stand = enf_stand
    self.th_walk = enf_walk
    self.th_run = enf_run
    self.th_pain = enf_pain
    self.th_die = enf_die_handler
    self.th_missile = enf_atk

    monsters.walk_start(self)
end

M.launch_laser = launch_laser

quake.register_entity("monster_enforcer", spawn)

return M
