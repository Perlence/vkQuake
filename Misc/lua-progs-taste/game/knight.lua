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
-- Port of knight.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local ai = require("game.ai")
local animation = require("game.animation")
local fight = require("game.fight")
local gibs = require("game.gibs")
local monsters = require("game.monsters")
local subs = require("game.subs")

local M = {}

--[[
==============================================================================

KNIGHT

==============================================================================
]]

local knight_stand1, knight_stand2, knight_stand3, knight_stand4, knight_stand5, knight_stand6, knight_stand7, knight_stand8, knight_stand9

knight_stand1 = animation.frame("stand1", function() return knight_stand2 end, ai.stand)
knight_stand2 = animation.frame("stand2", function() return knight_stand3 end, ai.stand)
knight_stand3 = animation.frame("stand3", function() return knight_stand4 end, ai.stand)
knight_stand4 = animation.frame("stand4", function() return knight_stand5 end, ai.stand)
knight_stand5 = animation.frame("stand5", function() return knight_stand6 end, ai.stand)
knight_stand6 = animation.frame("stand6", function() return knight_stand7 end, ai.stand)
knight_stand7 = animation.frame("stand7", function() return knight_stand8 end, ai.stand)
knight_stand8 = animation.frame("stand8", function() return knight_stand9 end, ai.stand)
knight_stand9 = animation.frame("stand9", function() return knight_stand1 end, ai.stand)

local knight_walk1, knight_walk2, knight_walk3, knight_walk4, knight_walk5, knight_walk6, knight_walk7, knight_walk8, knight_walk9, knight_walk10, knight_walk11, knight_walk12, knight_walk13, knight_walk14

knight_walk1 = animation.frame("walk1", function() return knight_walk2 end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "knight/idle.wav", 1, C.ATTN_IDLE) end; ai.walk(self, 3) end)
knight_walk2 = animation.frame("walk2", function() return knight_walk3 end, function(self) ai.walk(self, 2) end)
knight_walk3 = animation.frame("walk3", function() return knight_walk4 end, function(self) ai.walk(self, 3) end)
knight_walk4 = animation.frame("walk4", function() return knight_walk5 end, function(self) ai.walk(self, 4) end)
knight_walk5 = animation.frame("walk5", function() return knight_walk6 end, function(self) ai.walk(self, 3) end)
knight_walk6 = animation.frame("walk6", function() return knight_walk7 end, function(self) ai.walk(self, 3) end)
knight_walk7 = animation.frame("walk7", function() return knight_walk8 end, function(self) ai.walk(self, 3) end)
knight_walk8 = animation.frame("walk8", function() return knight_walk9 end, function(self) ai.walk(self, 4) end)
knight_walk9 = animation.frame("walk9", function() return knight_walk10 end, function(self) ai.walk(self, 3) end)
knight_walk10 = animation.frame("walk10", function() return knight_walk11 end, function(self) ai.walk(self, 3) end)
knight_walk11 = animation.frame("walk11", function() return knight_walk12 end, function(self) ai.walk(self, 2) end)
knight_walk12 = animation.frame("walk12", function() return knight_walk13 end, function(self) ai.walk(self, 3) end)
knight_walk13 = animation.frame("walk13", function() return knight_walk14 end, function(self) ai.walk(self, 4) end)
knight_walk14 = animation.frame("walk14", function() return knight_walk1 end, function(self) ai.walk(self, 3) end)

local knight_run1, knight_run2, knight_run3, knight_run4, knight_run5, knight_run6, knight_run7, knight_run8

knight_run1 = animation.frame("runb1", function() return knight_run2 end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "knight/idle.wav", 1, C.ATTN_IDLE) end; ai.run(self, 16) end)
knight_run2 = animation.frame("runb2", function() return knight_run3 end, function(self) ai.run(self, 20) end)
knight_run3 = animation.frame("runb3", function() return knight_run4 end, function(self) ai.run(self, 13) end)
knight_run4 = animation.frame("runb4", function() return knight_run5 end, function(self) ai.run(self, 7) end)
knight_run5 = animation.frame("runb5", function() return knight_run6 end, function(self) ai.run(self, 16) end)
knight_run6 = animation.frame("runb6", function() return knight_run7 end, function(self) ai.run(self, 20) end)
knight_run7 = animation.frame("runb7", function() return knight_run8 end, function(self) ai.run(self, 14) end)
knight_run8 = animation.frame("runb8", function() return knight_run1 end, function(self) ai.run(self, 6) end)

local knight_runatk1, knight_runatk2, knight_runatk3, knight_runatk4, knight_runatk5, knight_runatk6, knight_runatk7, knight_runatk8, knight_runatk9, knight_runatk10, knight_runatk11

knight_runatk1 = animation.frame("runattack1", function() return knight_runatk2 end, function(self) if quake.random() > 0.5 then quake.sound(self, C.CHAN_WEAPON, "knight/sword2.wav", 1, C.ATTN_NORM) else quake.sound(self, C.CHAN_WEAPON, "knight/sword1.wav", 1, C.ATTN_NORM) end; fight.charge(self, 20) end)
knight_runatk2 = animation.frame("runattack2", function() return knight_runatk3 end, function(self) fight.charge_side(self) end)
knight_runatk3 = animation.frame("runattack3", function() return knight_runatk4 end, function(self) fight.charge_side(self) end)
knight_runatk4 = animation.frame("runattack4", function() return knight_runatk5 end, function(self) fight.charge_side(self) end)
knight_runatk5 = animation.frame("runattack5", function() return knight_runatk6 end, function(self) fight.melee_side(self) end)
knight_runatk6 = animation.frame("runattack6", function() return knight_runatk7 end, function(self) fight.melee_side(self) end)
knight_runatk7 = animation.frame("runattack7", function() return knight_runatk8 end, function(self) fight.melee_side(self) end)
knight_runatk8 = animation.frame("runattack8", function() return knight_runatk9 end, function(self) fight.melee_side(self) end)
knight_runatk9 = animation.frame("runattack9", function() return knight_runatk10 end, function(self) fight.melee_side(self) end)
knight_runatk10 = animation.frame("runattack10", function() return knight_runatk11 end, function(self) fight.charge_side(self) end)
knight_runatk11 = animation.frame("runattack11", function() return knight_run1 end, function(self) fight.charge(self, 10) end)

local knight_atk1, knight_atk2, knight_atk3, knight_atk4, knight_atk5, knight_atk6, knight_atk7, knight_atk8, knight_atk9, knight_atk10

knight_atk1 = animation.frame("attackb1", function() return knight_atk2 end, function(self) quake.sound(self, C.CHAN_WEAPON, "knight/sword1.wav", 1, C.ATTN_NORM); fight.charge(self, 0) end)
knight_atk2 = animation.frame("attackb2", function() return knight_atk3 end, function(self) fight.charge(self, 7) end)
knight_atk3 = animation.frame("attackb3", function() return knight_atk4 end, function(self) fight.charge(self, 4) end)
knight_atk4 = animation.frame("attackb4", function() return knight_atk5 end, function(self) fight.charge(self, 0) end)
knight_atk5 = animation.frame("attackb5", function() return knight_atk6 end, function(self) fight.charge(self, 3) end)
knight_atk6 = animation.frame("attackb6", function() return knight_atk7 end, function(self) fight.charge(self, 4); fight.melee(self) end)
knight_atk7 = animation.frame("attackb7", function() return knight_atk8 end, function(self) fight.charge(self, 1); fight.melee(self) end)
knight_atk8 = animation.frame("attackb8", function() return knight_atk9 end, function(self) fight.charge(self, 3); fight.melee(self) end)
knight_atk9 = animation.frame("attackb9", function() return knight_atk10 end, function(self) fight.charge(self, 1) end)
knight_atk10 = animation.frame("attackb10", function() return knight_run1 end, function(self) fight.charge(self, 5) end)

--===========================================================================

local knight_pain1, knight_pain2, knight_pain3

knight_pain1 = animation.frame("pain1", function() return knight_pain2 end)
knight_pain2 = animation.frame("pain2", function() return knight_pain3 end)
knight_pain3 = animation.frame("pain3", function() return knight_run1 end)

local knight_painb1, knight_painb2, knight_painb3, knight_painb4, knight_painb5, knight_painb6, knight_painb7, knight_painb8, knight_painb9, knight_painb10, knight_painb11

knight_painb1 = animation.frame("painb1", function() return knight_painb2 end, function(self) ai.pain_forward(self, 0) end)
knight_painb2 = animation.frame("painb2", function() return knight_painb3 end, function(self) ai.pain_forward(self, 3) end)
knight_painb3 = animation.frame("painb3", function() return knight_painb4 end)
knight_painb4 = animation.frame("painb4", function() return knight_painb5 end)
knight_painb5 = animation.frame("painb5", function() return knight_painb6 end, function(self) ai.pain_forward(self, 2) end)
knight_painb6 = animation.frame("painb6", function() return knight_painb7 end, function(self) ai.pain_forward(self, 4) end)
knight_painb7 = animation.frame("painb7", function() return knight_painb8 end, function(self) ai.pain_forward(self, 2) end)
knight_painb8 = animation.frame("painb8", function() return knight_painb9 end, function(self) ai.pain_forward(self, 5) end)
knight_painb9 = animation.frame("painb9", function() return knight_painb10 end, function(self) ai.pain_forward(self, 5) end)
knight_painb10 = animation.frame("painb10", function() return knight_painb11 end, function(self) ai.pain_forward(self, 0) end)
knight_painb11 = animation.frame("painb11", function() return knight_run1 end)

local function knight_pain(self, _attacker, _damage)
    local r

    if self.pain_finished > quake.time() then return end
    r = quake.random()
    quake.sound(self, C.CHAN_VOICE, "knight/khurt.wav", 1, C.ATTN_NORM)
    if r < 0.85 then
        knight_pain1(self)
        self.pain_finished = quake.time() + 1
    else
        knight_painb1(self)
        self.pain_finished = quake.time() + 1
    end
end

--===========================================================================

local knight_bow1, knight_bow2, knight_bow3, knight_bow4, knight_bow5

knight_bow1 = animation.frame("kneel1", function() return knight_bow2 end, ai.turn)
knight_bow2 = animation.frame("kneel2", function() return knight_bow3 end, ai.turn)
knight_bow3 = animation.frame("kneel3", function() return knight_bow4 end, ai.turn)
knight_bow4 = animation.frame("kneel4", function() return knight_bow5 end, ai.turn)
knight_bow5 = animation.frame("kneel5", function() return knight_bow5 end, ai.turn)

local knight_bow6, knight_bow7, knight_bow8, knight_bow9, knight_bow10

knight_bow6 = animation.frame("kneel4", function() return knight_bow7 end, ai.turn)
knight_bow7 = animation.frame("kneel3", function() return knight_bow8 end, ai.turn)
knight_bow8 = animation.frame("kneel2", function() return knight_bow9 end, ai.turn)
knight_bow9 = animation.frame("kneel1", function() return knight_bow10 end, ai.turn)
knight_bow10 = animation.frame("walk1", function() return knight_walk1 end, ai.turn)

local knight_die1, knight_die2, knight_die3, knight_die4, knight_die5, knight_die6, knight_die7, knight_die8, knight_die9, knight_die10

knight_die1 = animation.frame("death1", function() return knight_die2 end)
knight_die2 = animation.frame("death2", function() return knight_die3 end)
knight_die3 = animation.frame("death3", function() return knight_die4 end, function(self) self.solid = C.SOLID_NOT end)
knight_die4 = animation.frame("death4", function() return knight_die5 end)
knight_die5 = animation.frame("death5", function() return knight_die6 end)
knight_die6 = animation.frame("death6", function() return knight_die7 end)
knight_die7 = animation.frame("death7", function() return knight_die8 end)
knight_die8 = animation.frame("death8", function() return knight_die9 end)
knight_die9 = animation.frame("death9", function() return knight_die10 end)
knight_die10 = animation.frame("death10", function() return knight_die10 end)

local knight_dieb1, knight_dieb2, knight_dieb3, knight_dieb4, knight_dieb5, knight_dieb6, knight_dieb7, knight_dieb8, knight_dieb9, knight_dieb10, knight_dieb11

knight_dieb1 = animation.frame("deathb1", function() return knight_dieb2 end)
knight_dieb2 = animation.frame("deathb2", function() return knight_dieb3 end)
knight_dieb3 = animation.frame("deathb3", function() return knight_dieb4 end, function(self) self.solid = C.SOLID_NOT end)
knight_dieb4 = animation.frame("deathb4", function() return knight_dieb5 end)
knight_dieb5 = animation.frame("deathb5", function() return knight_dieb6 end)
knight_dieb6 = animation.frame("deathb6", function() return knight_dieb7 end)
knight_dieb7 = animation.frame("deathb7", function() return knight_dieb8 end)
knight_dieb8 = animation.frame("deathb8", function() return knight_dieb9 end)
knight_dieb9 = animation.frame("deathb9", function() return knight_dieb10 end)
knight_dieb10 = animation.frame("deathb10", function() return knight_dieb11 end)
knight_dieb11 = animation.frame("deathb11", function() return knight_dieb11 end)

local function knight_die(self)
    -- check for gib
    if self.health < -40 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw_head(self, "progs/h_knight.mdl", self.health)
        gibs.throw(self, "progs/gib1.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        return
    end

    -- regular death
    quake.sound(self, C.CHAN_VOICE, "knight/kdeath.wav", 1, C.ATTN_NORM)
    if quake.random() < 0.5 then knight_die1(self) else knight_dieb1(self) end
end

--[[QUAKED monster_knight (1 0 0) (-16 -16 -24) (16 16 40) Ambush
]]
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then quake.remove(self); return end
    quake.precache_model("progs/knight.mdl")
    quake.precache_model("progs/h_knight.mdl")
    quake.precache_sound("knight/kdeath.wav")
    quake.precache_sound("knight/khurt.wav")
    quake.precache_sound("knight/ksight.wav")
    quake.precache_sound("knight/sword1.wav")
    quake.precache_sound("knight/sword2.wav")
    quake.precache_sound("knight/idle.wav")
    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP
    quake.set_model(self, "progs/knight.mdl")
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 40))
    self.health = 75
    self.th_stand = knight_stand1
    self.th_walk = knight_walk1
    self.th_run = knight_run1
    self.th_melee = knight_atk1
    self.th_pain = knight_pain
    self.th_die = knight_die
    monsters.walk_start(self)
end

M.atk1 = knight_atk1
M.runatk1 = knight_runatk1

quake.register_entity("monster_knight", M.spawn)

return M
