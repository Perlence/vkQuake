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

army_stand1 = animation.frame("stand1", function() return army_stand2 end, ai.stand)
army_stand2 = animation.frame("stand2", function() return army_stand3 end, ai.stand)
army_stand3 = animation.frame("stand3", function() return army_stand4 end, ai.stand)
army_stand4 = animation.frame("stand4", function() return army_stand5 end, ai.stand)
army_stand5 = animation.frame("stand5", function() return army_stand6 end, ai.stand)
army_stand6 = animation.frame("stand6", function() return army_stand7 end, ai.stand)
army_stand7 = animation.frame("stand7", function() return army_stand8 end, ai.stand)
army_stand8 = animation.frame("stand8", function() return army_stand1 end, ai.stand)

local army_walk1, army_walk2, army_walk3, army_walk4, army_walk5, army_walk6, army_walk7, army_walk8, army_walk9, army_walk10, army_walk11, army_walk12, army_walk13, army_walk14, army_walk15, army_walk16, army_walk17, army_walk18, army_walk19, army_walk20, army_walk21, army_walk22, army_walk23, army_walk24

army_walk1 = animation.frame("prowl_1", function() return army_walk2 end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "soldier/idle.wav", 1, C.ATTN_IDLE) end; ai.walk(self, 1) end)
army_walk2 = animation.frame("prowl_2", function() return army_walk3 end, function(self) ai.walk(self, 1) end)
army_walk3 = animation.frame("prowl_3", function() return army_walk4 end, function(self) ai.walk(self, 1) end)
army_walk4 = animation.frame("prowl_4", function() return army_walk5 end, function(self) ai.walk(self, 1) end)
army_walk5 = animation.frame("prowl_5", function() return army_walk6 end, function(self) ai.walk(self, 2) end)
army_walk6 = animation.frame("prowl_6", function() return army_walk7 end, function(self) ai.walk(self, 3) end)
army_walk7 = animation.frame("prowl_7", function() return army_walk8 end, function(self) ai.walk(self, 4) end)
army_walk8 = animation.frame("prowl_8", function() return army_walk9 end, function(self) ai.walk(self, 4) end)
army_walk9 = animation.frame("prowl_9", function() return army_walk10 end, function(self) ai.walk(self, 2) end)
army_walk10 = animation.frame("prowl_10", function() return army_walk11 end, function(self) ai.walk(self, 2) end)
army_walk11 = animation.frame("prowl_11", function() return army_walk12 end, function(self) ai.walk(self, 2) end)
army_walk12 = animation.frame("prowl_12", function() return army_walk13 end, function(self) ai.walk(self, 1) end)
army_walk13 = animation.frame("prowl_13", function() return army_walk14 end, function(self) ai.walk(self, 0) end)
army_walk14 = animation.frame("prowl_14", function() return army_walk15 end, function(self) ai.walk(self, 1) end)
army_walk15 = animation.frame("prowl_15", function() return army_walk16 end, function(self) ai.walk(self, 1) end)
army_walk16 = animation.frame("prowl_16", function() return army_walk17 end, function(self) ai.walk(self, 1) end)
army_walk17 = animation.frame("prowl_17", function() return army_walk18 end, function(self) ai.walk(self, 3) end)
army_walk18 = animation.frame("prowl_18", function() return army_walk19 end, function(self) ai.walk(self, 3) end)
army_walk19 = animation.frame("prowl_19", function() return army_walk20 end, function(self) ai.walk(self, 3) end)
army_walk20 = animation.frame("prowl_20", function() return army_walk21 end, function(self) ai.walk(self, 3) end)
army_walk21 = animation.frame("prowl_21", function() return army_walk22 end, function(self) ai.walk(self, 2) end)
army_walk22 = animation.frame("prowl_22", function() return army_walk23 end, function(self) ai.walk(self, 1) end)
army_walk23 = animation.frame("prowl_23", function() return army_walk24 end, function(self) ai.walk(self, 1) end)
army_walk24 = animation.frame("prowl_24", function() return army_walk1 end, function(self) ai.walk(self, 1) end)

local army_run1, army_run2, army_run3, army_run4, army_run5, army_run6, army_run7, army_run8

army_run1 = animation.frame("run1", function() return army_run2 end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "soldier/idle.wav", 1, C.ATTN_IDLE) end; ai.run(self, 11) end)
army_run2 = animation.frame("run2", function() return army_run3 end, function(self) ai.run(self, 15) end)
army_run3 = animation.frame("run3", function() return army_run4 end, function(self) ai.run(self, 10) end)
army_run4 = animation.frame("run4", function() return army_run5 end, function(self) ai.run(self, 10) end)
army_run5 = animation.frame("run5", function() return army_run6 end, function(self) ai.run(self, 8) end)
army_run6 = animation.frame("run6", function() return army_run7 end, function(self) ai.run(self, 15) end)
army_run7 = animation.frame("run7", function() return army_run8 end, function(self) ai.run(self, 10) end)
army_run8 = animation.frame("run8", function() return army_run1 end, function(self) ai.run(self, 8) end)

local army_atk1, army_atk2, army_atk3, army_atk4, army_atk5, army_atk6, army_atk7, army_atk8, army_atk9

army_atk1 = animation.frame("shoot1", function() return army_atk2 end, function(self) fight.face(self) end)
army_atk2 = animation.frame("shoot2", function() return army_atk3 end, function(self) fight.face(self) end)
army_atk3 = animation.frame("shoot3", function() return army_atk4 end, function(self) fight.face(self) end)
army_atk4 = animation.frame("shoot4", function() return army_atk5 end, function(self) fight.face(self) end)
army_atk5 = animation.frame("shoot5", function() return army_atk6 end, function(self) fight.face(self); army_fire(self); self.effects = self.effects | C.EF_MUZZLEFLASH end)
army_atk6 = animation.frame("shoot6", function() return army_atk7 end, function(self) fight.face(self) end)
army_atk7 = animation.frame("shoot7", function() return army_atk8 end, function(self) fight.face(self); subs.check_refire(self, army_atk1) end)
army_atk8 = animation.frame("shoot8", function() return army_atk9 end, function(self) fight.face(self) end)
army_atk9 = animation.frame("shoot9", function() return army_run1 end, function(self) fight.face(self) end)

local army_pain1, army_pain2, army_pain3, army_pain4, army_pain5, army_pain6

army_pain1 = animation.frame("pain1", function() return army_pain2 end)
army_pain2 = animation.frame("pain2", function() return army_pain3 end)
army_pain3 = animation.frame("pain3", function() return army_pain4 end)
army_pain4 = animation.frame("pain4", function() return army_pain5 end)
army_pain5 = animation.frame("pain5", function() return army_pain6 end)
army_pain6 = animation.frame("pain6", function() return army_run1 end, function(self) ai.pain(self, 1) end)

local army_painb1, army_painb2, army_painb3, army_painb4, army_painb5, army_painb6, army_painb7, army_painb8, army_painb9, army_painb10, army_painb11, army_painb12, army_painb13, army_painb14

army_painb1 = animation.frame("painb1", function() return army_painb2 end)
army_painb2 = animation.frame("painb2", function() return army_painb3 end, function(self) ai.pain_forward(self, 13) end)
army_painb3 = animation.frame("painb3", function() return army_painb4 end, function(self) ai.pain_forward(self, 9) end)
army_painb4 = animation.frame("painb4", function() return army_painb5 end)
army_painb5 = animation.frame("painb5", function() return army_painb6 end)
army_painb6 = animation.frame("painb6", function() return army_painb7 end)
army_painb7 = animation.frame("painb7", function() return army_painb8 end)
army_painb8 = animation.frame("painb8", function() return army_painb9 end)
army_painb9 = animation.frame("painb9", function() return army_painb10 end)
army_painb10 = animation.frame("painb10", function() return army_painb11 end)
army_painb11 = animation.frame("painb11", function() return army_painb12 end)
army_painb12 = animation.frame("painb12", function() return army_painb13 end, function(self) ai.pain(self, 2) end)
army_painb13 = animation.frame("painb13", function() return army_painb14 end)
army_painb14 = animation.frame("painb14", function() return army_run1 end)

local army_painc1, army_painc2, army_painc3, army_painc4, army_painc5, army_painc6, army_painc7, army_painc8, army_painc9, army_painc10, army_painc11, army_painc12, army_painc13

army_painc1 = animation.frame("painc1", function() return army_painc2 end)
army_painc2 = animation.frame("painc2", function() return army_painc3 end, function(self) ai.pain(self, 1) end)
army_painc3 = animation.frame("painc3", function() return army_painc4 end)
army_painc4 = animation.frame("painc4", function() return army_painc5 end)
army_painc5 = animation.frame("painc5", function() return army_painc6 end, function(self) ai.pain_forward(self, 1) end)
army_painc6 = animation.frame("painc6", function() return army_painc7 end, function(self) ai.pain_forward(self, 1) end)
army_painc7 = animation.frame("painc7", function() return army_painc8 end)
army_painc8 = animation.frame("painc8", function() return army_painc9 end, function(self) ai.pain(self, 1) end)
army_painc9 = animation.frame("painc9", function() return army_painc10 end, function(self) ai.pain_forward(self, 4) end)
army_painc10 = animation.frame("painc10", function() return army_painc11 end, function(self) ai.pain_forward(self, 3) end)
army_painc11 = animation.frame("painc11", function() return army_painc12 end, function(self) ai.pain_forward(self, 6) end)
army_painc12 = animation.frame("painc12", function() return army_painc13 end, function(self) ai.pain_forward(self, 8) end)
army_painc13 = animation.frame("painc13", function() return army_run1 end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function army_pain(self, _attacker, _damage)
    local r
    if self.pain_finished > quake.time() then return end
    r = quake.random()
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
    local dir
    local en
    fight.face(self)
    quake.sound(self, C.CHAN_WEAPON, "soldier/sattck1.wav", 1, C.ATTN_NORM)
    -- fire somewhat behind the player, so a dodging player is harder to hit
    en = self.enemy
    dir = en.origin - en.velocity * 0.2
    dir = (dir - self.origin):normalized()
    weapons.fire_bullets(self, 4, dir, quake.vec3(0.1, 0.1, 0))
end

local army_die1, army_die2, army_die3, army_die4, army_die5, army_die6, army_die7, army_die8, army_die9, army_die10

army_die1 = animation.frame("death1", function() return army_die2 end)
army_die2 = animation.frame("death2", function() return army_die3 end)
army_die3 = animation.frame("death3", function() return army_die4 end, function(self) self.solid = C.SOLID_NOT; self.ammo_shells = 5; items.drop_backpack(self) end)
army_die4 = animation.frame("death4", function() return army_die5 end)
army_die5 = animation.frame("death5", function() return army_die6 end)
army_die6 = animation.frame("death6", function() return army_die7 end)
army_die7 = animation.frame("death7", function() return army_die8 end)
army_die8 = animation.frame("death8", function() return army_die9 end)
army_die9 = animation.frame("death9", function() return army_die10 end)
army_die10 = animation.frame("death10", function() return army_die10 end)

local army_cdie1, army_cdie2, army_cdie3, army_cdie4, army_cdie5, army_cdie6, army_cdie7, army_cdie8, army_cdie9, army_cdie10, army_cdie11

army_cdie1 = animation.frame("deathc1", function() return army_cdie2 end)
army_cdie2 = animation.frame("deathc2", function() return army_cdie3 end, function(self) ai.back(self, 5) end)
army_cdie3 = animation.frame("deathc3", function() return army_cdie4 end, function(self) self.solid = C.SOLID_NOT; self.ammo_shells = 5; items.drop_backpack(self); ai.back(self, 4) end)
army_cdie4 = animation.frame("deathc4", function() return army_cdie5 end, function(self) ai.back(self, 13) end)
army_cdie5 = animation.frame("deathc5", function() return army_cdie6 end, function(self) ai.back(self, 3) end)
army_cdie6 = animation.frame("deathc6", function() return army_cdie7 end, function(self) ai.back(self, 4) end)
army_cdie7 = animation.frame("deathc7", function() return army_cdie8 end)
army_cdie8 = animation.frame("deathc8", function() return army_cdie9 end)
army_cdie9 = animation.frame("deathc9", function() return army_cdie10 end)
army_cdie10 = animation.frame("deathc10", function() return army_cdie11 end)
army_cdie11 = animation.frame("deathc11", function() return army_cdie11 end)

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
