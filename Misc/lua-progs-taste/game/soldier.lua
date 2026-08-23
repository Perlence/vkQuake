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
-- Port of soldier.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local ai = require("game.ai")
local animation = require("game.animation")
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
    f.stand7, f.stand8 = count(8)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
    f.death7, f.death8, f.death9, f.death10 = count(10)

f.deathc1, f.deathc2, f.deathc3, f.deathc4, f.deathc5, f.deathc6,
    f.deathc7, f.deathc8, f.deathc9, f.deathc10, f.deathc11 = count(11)

f.load1, f.load2, f.load3, f.load4, f.load5, f.load6,
    f.load7, f.load8, f.load9, f.load10, f.load11 = count(11)

f.pain1, f.pain2, f.pain3, f.pain4, f.pain5, f.pain6 = count(6)

f.painb1, f.painb2, f.painb3, f.painb4, f.painb5, f.painb6,
    f.painb7, f.painb8, f.painb9, f.painb10, f.painb11, f.painb12,
    f.painb13, f.painb14 = count(14)

f.painc1, f.painc2, f.painc3, f.painc4, f.painc5, f.painc6,
    f.painc7, f.painc8, f.painc9, f.painc10, f.painc11, f.painc12,
    f.painc13 = count(13)

f.run1, f.run2, f.run3, f.run4, f.run5, f.run6,
    f.run7, f.run8 = count(8)

f.shoot1, f.shoot2, f.shoot3, f.shoot4, f.shoot5, f.shoot6,
    f.shoot7, f.shoot8, f.shoot9 = count(9)

f.prowl_1, f.prowl_2, f.prowl_3, f.prowl_4, f.prowl_5, f.prowl_6,
    f.prowl_7, f.prowl_8, f.prowl_9, f.prowl_10, f.prowl_11, f.prowl_12,
    f.prowl_13, f.prowl_14, f.prowl_15, f.prowl_16, f.prowl_17, f.prowl_18,
    f.prowl_19, f.prowl_20, f.prowl_21, f.prowl_22, f.prowl_23, f.prowl_24 = count(24)

--[[
==============================================================================

SOLDIER / PLAYER (Grunt)

==============================================================================
]]

--[[
==============================================================================
SOLDIER CODE
==============================================================================
]]

local army_fire

local army_stand1, army_stand2, army_stand3, army_stand4, army_stand5, army_stand6, army_stand7, army_stand8

army_stand1 = animation.frame(f.stand1, function() return army_stand2 end, ai.stand)
army_stand2 = animation.frame(f.stand2, function() return army_stand3 end, ai.stand)
army_stand3 = animation.frame(f.stand3, function() return army_stand4 end, ai.stand)
army_stand4 = animation.frame(f.stand4, function() return army_stand5 end, ai.stand)
army_stand5 = animation.frame(f.stand5, function() return army_stand6 end, ai.stand)
army_stand6 = animation.frame(f.stand6, function() return army_stand7 end, ai.stand)
army_stand7 = animation.frame(f.stand7, function() return army_stand8 end, ai.stand)
army_stand8 = animation.frame(f.stand8, function() return army_stand1 end, ai.stand)

local army_walk1, army_walk2, army_walk3, army_walk4, army_walk5, army_walk6, army_walk7, army_walk8, army_walk9, army_walk10, army_walk11, army_walk12, army_walk13, army_walk14, army_walk15, army_walk16, army_walk17, army_walk18, army_walk19, army_walk20, army_walk21, army_walk22, army_walk23, army_walk24

army_walk1 = animation.frame(f.prowl_1, function() return army_walk2 end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "soldier/idle.wav", 1, C.ATTN_IDLE) end; ai.walk(self, 1) end)
army_walk2 = animation.frame(f.prowl_2, function() return army_walk3 end, function(self) ai.walk(self, 1) end)
army_walk3 = animation.frame(f.prowl_3, function() return army_walk4 end, function(self) ai.walk(self, 1) end)
army_walk4 = animation.frame(f.prowl_4, function() return army_walk5 end, function(self) ai.walk(self, 1) end)
army_walk5 = animation.frame(f.prowl_5, function() return army_walk6 end, function(self) ai.walk(self, 2) end)
army_walk6 = animation.frame(f.prowl_6, function() return army_walk7 end, function(self) ai.walk(self, 3) end)
army_walk7 = animation.frame(f.prowl_7, function() return army_walk8 end, function(self) ai.walk(self, 4) end)
army_walk8 = animation.frame(f.prowl_8, function() return army_walk9 end, function(self) ai.walk(self, 4) end)
army_walk9 = animation.frame(f.prowl_9, function() return army_walk10 end, function(self) ai.walk(self, 2) end)
army_walk10 = animation.frame(f.prowl_10, function() return army_walk11 end, function(self) ai.walk(self, 2) end)
army_walk11 = animation.frame(f.prowl_11, function() return army_walk12 end, function(self) ai.walk(self, 2) end)
army_walk12 = animation.frame(f.prowl_12, function() return army_walk13 end, function(self) ai.walk(self, 1) end)
army_walk13 = animation.frame(f.prowl_13, function() return army_walk14 end, function(self) ai.walk(self, 0) end)
army_walk14 = animation.frame(f.prowl_14, function() return army_walk15 end, function(self) ai.walk(self, 1) end)
army_walk15 = animation.frame(f.prowl_15, function() return army_walk16 end, function(self) ai.walk(self, 1) end)
army_walk16 = animation.frame(f.prowl_16, function() return army_walk17 end, function(self) ai.walk(self, 1) end)
army_walk17 = animation.frame(f.prowl_17, function() return army_walk18 end, function(self) ai.walk(self, 3) end)
army_walk18 = animation.frame(f.prowl_18, function() return army_walk19 end, function(self) ai.walk(self, 3) end)
army_walk19 = animation.frame(f.prowl_19, function() return army_walk20 end, function(self) ai.walk(self, 3) end)
army_walk20 = animation.frame(f.prowl_20, function() return army_walk21 end, function(self) ai.walk(self, 3) end)
army_walk21 = animation.frame(f.prowl_21, function() return army_walk22 end, function(self) ai.walk(self, 2) end)
army_walk22 = animation.frame(f.prowl_22, function() return army_walk23 end, function(self) ai.walk(self, 1) end)
army_walk23 = animation.frame(f.prowl_23, function() return army_walk24 end, function(self) ai.walk(self, 1) end)
army_walk24 = animation.frame(f.prowl_24, function() return army_walk1 end, function(self) ai.walk(self, 1) end)

local army_run1, army_run2, army_run3, army_run4, army_run5, army_run6, army_run7, army_run8

army_run1 = animation.frame(f.run1, function() return army_run2 end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "soldier/idle.wav", 1, C.ATTN_IDLE) end; ai.run(self, 11) end)
army_run2 = animation.frame(f.run2, function() return army_run3 end, function(self) ai.run(self, 15) end)
army_run3 = animation.frame(f.run3, function() return army_run4 end, function(self) ai.run(self, 10) end)
army_run4 = animation.frame(f.run4, function() return army_run5 end, function(self) ai.run(self, 10) end)
army_run5 = animation.frame(f.run5, function() return army_run6 end, function(self) ai.run(self, 8) end)
army_run6 = animation.frame(f.run6, function() return army_run7 end, function(self) ai.run(self, 15) end)
army_run7 = animation.frame(f.run7, function() return army_run8 end, function(self) ai.run(self, 10) end)
army_run8 = animation.frame(f.run8, function() return army_run1 end, function(self) ai.run(self, 8) end)

local army_atk1, army_atk2, army_atk3, army_atk4, army_atk5, army_atk6, army_atk7, army_atk8, army_atk9

army_atk1 = animation.frame(f.shoot1, function() return army_atk2 end, function(self) fight.face(self) end)
army_atk2 = animation.frame(f.shoot2, function() return army_atk3 end, function(self) fight.face(self) end)
army_atk3 = animation.frame(f.shoot3, function() return army_atk4 end, function(self) fight.face(self) end)
army_atk4 = animation.frame(f.shoot4, function() return army_atk5 end, function(self) fight.face(self) end)
army_atk5 = animation.frame(f.shoot5, function() return army_atk6 end, function(self) fight.face(self); army_fire(self); self.effects = self.effects | C.EF_MUZZLEFLASH end)
army_atk6 = animation.frame(f.shoot6, function() return army_atk7 end, function(self) fight.face(self) end)
army_atk7 = animation.frame(f.shoot7, function() return army_atk8 end, function(self) fight.face(self); subs.check_refire(self, army_atk1) end)
army_atk8 = animation.frame(f.shoot8, function() return army_atk9 end, function(self) fight.face(self) end)
army_atk9 = animation.frame(f.shoot9, function() return army_run1 end, function(self) fight.face(self) end)

local army_pain1, army_pain2, army_pain3, army_pain4, army_pain5, army_pain6

army_pain1 = animation.frame(f.pain1, function() return army_pain2 end)
army_pain2 = animation.frame(f.pain2, function() return army_pain3 end)
army_pain3 = animation.frame(f.pain3, function() return army_pain4 end)
army_pain4 = animation.frame(f.pain4, function() return army_pain5 end)
army_pain5 = animation.frame(f.pain5, function() return army_pain6 end)
army_pain6 = animation.frame(f.pain6, function() return army_run1 end, function(self) ai.pain(self, 1) end)

local army_painb1, army_painb2, army_painb3, army_painb4, army_painb5, army_painb6, army_painb7, army_painb8, army_painb9, army_painb10, army_painb11, army_painb12, army_painb13, army_painb14

army_painb1 = animation.frame(f.painb1, function() return army_painb2 end)
army_painb2 = animation.frame(f.painb2, function() return army_painb3 end, function(self) ai.pain_forward(self, 13) end)
army_painb3 = animation.frame(f.painb3, function() return army_painb4 end, function(self) ai.pain_forward(self, 9) end)
army_painb4 = animation.frame(f.painb4, function() return army_painb5 end)
army_painb5 = animation.frame(f.painb5, function() return army_painb6 end)
army_painb6 = animation.frame(f.painb6, function() return army_painb7 end)
army_painb7 = animation.frame(f.painb7, function() return army_painb8 end)
army_painb8 = animation.frame(f.painb8, function() return army_painb9 end)
army_painb9 = animation.frame(f.painb9, function() return army_painb10 end)
army_painb10 = animation.frame(f.painb10, function() return army_painb11 end)
army_painb11 = animation.frame(f.painb11, function() return army_painb12 end)
army_painb12 = animation.frame(f.painb12, function() return army_painb13 end, function(self) ai.pain(self, 2) end)
army_painb13 = animation.frame(f.painb13, function() return army_painb14 end)
army_painb14 = animation.frame(f.painb14, function() return army_run1 end)

local army_painc1, army_painc2, army_painc3, army_painc4, army_painc5, army_painc6, army_painc7, army_painc8, army_painc9, army_painc10, army_painc11, army_painc12, army_painc13

army_painc1 = animation.frame(f.painc1, function() return army_painc2 end)
army_painc2 = animation.frame(f.painc2, function() return army_painc3 end, function(self) ai.pain(self, 1) end)
army_painc3 = animation.frame(f.painc3, function() return army_painc4 end)
army_painc4 = animation.frame(f.painc4, function() return army_painc5 end)
army_painc5 = animation.frame(f.painc5, function() return army_painc6 end, function(self) ai.pain_forward(self, 1) end)
army_painc6 = animation.frame(f.painc6, function() return army_painc7 end, function(self) ai.pain_forward(self, 1) end)
army_painc7 = animation.frame(f.painc7, function() return army_painc8 end)
army_painc8 = animation.frame(f.painc8, function() return army_painc9 end, function(self) ai.pain(self, 1) end)
army_painc9 = animation.frame(f.painc9, function() return army_painc10 end, function(self) ai.pain_forward(self, 4) end)
army_painc10 = animation.frame(f.painc10, function() return army_painc11 end, function(self) ai.pain_forward(self, 3) end)
army_painc11 = animation.frame(f.painc11, function() return army_painc12 end, function(self) ai.pain_forward(self, 6) end)
army_painc12 = animation.frame(f.painc12, function() return army_painc13 end, function(self) ai.pain_forward(self, 8) end)
army_painc13 = animation.frame(f.painc13, function() return army_run1 end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function army_pain(self, _attacker, _damage)
    if self.pain_finished > quake.time() then return end
    local r = quake.random()
    if r < 0.2 then
        self.pain_finished = quake.time() + 0.6
        army_pain1(self)
        quake.sound(self, C.CHAN_VOICE, "soldier/pain1.wav", 1, C.ATTN_NORM)
    elseif r < 0.6 then
        self.pain_finished = quake.time() + 1.1
        army_painb1(self)
        quake.sound(self, C.CHAN_VOICE, "soldier/pain2.wav", 1, C.ATTN_NORM)
    else
        self.pain_finished = quake.time() + 1.1
        army_painc1(self)
        quake.sound(self, C.CHAN_VOICE, "soldier/pain2.wav", 1, C.ATTN_NORM)
    end
end

---@param self entity
---@return nil
function army_fire(self)
    fight.face(self)
    quake.sound(self, C.CHAN_WEAPON, "soldier/sattck1.wav", 1, C.ATTN_NORM)
    -- fire somewhat behind the player, so a dodging player is harder to hit
    local en = assert(self.enemy, "monster has no enemy")
    local dir = en.origin - en.velocity * 0.2
    dir = (dir - self.origin):normalized()
    weapons.fire_bullets(self, 4, dir, quake.vec3(0.1, 0.1, 0))
end

local army_die1, army_die2, army_die3, army_die4, army_die5, army_die6, army_die7, army_die8, army_die9, army_die10

army_die1 = animation.frame(f.death1, function() return army_die2 end)
army_die2 = animation.frame(f.death2, function() return army_die3 end)
army_die3 = animation.frame(f.death3, function() return army_die4 end, function(self) self.solid = C.SOLID_NOT; self.ammo_shells = 5; items.drop_backpack(self) end)
army_die4 = animation.frame(f.death4, function() return army_die5 end)
army_die5 = animation.frame(f.death5, function() return army_die6 end)
army_die6 = animation.frame(f.death6, function() return army_die7 end)
army_die7 = animation.frame(f.death7, function() return army_die8 end)
army_die8 = animation.frame(f.death8, function() return army_die9 end)
army_die9 = animation.frame(f.death9, function() return army_die10 end)
army_die10 = animation.frame(f.death10, function() return army_die10 end)

local army_cdie1, army_cdie2, army_cdie3, army_cdie4, army_cdie5, army_cdie6, army_cdie7, army_cdie8, army_cdie9, army_cdie10, army_cdie11

army_cdie1 = animation.frame(f.deathc1, function() return army_cdie2 end)
army_cdie2 = animation.frame(f.deathc2, function() return army_cdie3 end, function(self) ai.back(self, 5) end)
army_cdie3 = animation.frame(f.deathc3, function() return army_cdie4 end, function(self) self.solid = C.SOLID_NOT; self.ammo_shells = 5; items.drop_backpack(self); ai.back(self, 4) end)
army_cdie4 = animation.frame(f.deathc4, function() return army_cdie5 end, function(self) ai.back(self, 13) end)
army_cdie5 = animation.frame(f.deathc5, function() return army_cdie6 end, function(self) ai.back(self, 3) end)
army_cdie6 = animation.frame(f.deathc6, function() return army_cdie7 end, function(self) ai.back(self, 4) end)
army_cdie7 = animation.frame(f.deathc7, function() return army_cdie8 end)
army_cdie8 = animation.frame(f.deathc8, function() return army_cdie9 end)
army_cdie9 = animation.frame(f.deathc9, function() return army_cdie10 end)
army_cdie10 = animation.frame(f.deathc10, function() return army_cdie11 end)
army_cdie11 = animation.frame(f.deathc11, function() return army_cdie11 end)

---@param self entity
---@return nil
local function army_die(self)
    -- check for gib
    if self.health < -35 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw_head(self, "progs/h_guard.mdl", self.health)
        gibs.throw(self, "progs/gib1.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        return
    end
    -- regular death
    quake.sound(self, C.CHAN_VOICE, "soldier/death1.wav", 1, C.ATTN_NORM)
    if quake.random() < 0.5 then army_die1(self) else army_cdie1(self) end
end

---QUAKED monster_army (1 0 0) (-16 -16 -24) (16 16 40) Ambush
---@param self entity
---@return nil
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then quake.remove(self); return end
    quake.precache_model("progs/soldier.mdl")
    quake.precache_model("progs/h_guard.mdl")
    quake.precache_model("progs/gib1.mdl")
    quake.precache_model("progs/gib2.mdl")
    quake.precache_model("progs/gib3.mdl")
    quake.precache_sound("soldier/death1.wav")
    quake.precache_sound("soldier/idle.wav")
    quake.precache_sound("soldier/pain1.wav")
    quake.precache_sound("soldier/pain2.wav")
    quake.precache_sound("soldier/sattck1.wav")
    quake.precache_sound("soldier/sight1.wav")
    -- gib death
    quake.precache_sound("player/udeath.wav")
    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP
    quake.set_model(self, "progs/soldier.mdl")
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 40))
    self.health = 30
    self.th_stand = army_stand1
    self.th_walk = army_walk1
    self.th_run = army_run1
    self.th_missile = army_atk1
    self.th_pain = army_pain
    self.th_die = army_die
    monsters.walk_start(self)
end

quake.register_entity("monster_army", M.spawn)

return M
