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

local count = animation.counter()
local f = {}

f.stand1, f.stand2, f.stand3, f.stand4, f.stand5, f.stand6,
    f.stand7, f.stand8, f.stand9 = count(9)

f.runb1, f.runb2, f.runb3, f.runb4, f.runb5, f.runb6,
    f.runb7, f.runb8 = count(8)

f.runattack1, f.runattack2, f.runattack3, f.runattack4, f.runattack5, f.runattack6,
    f.runattack7, f.runattack8, f.runattack9, f.runattack10, f.runattack11 = count(11)

f.pain1, f.pain2, f.pain3 = count(3)

f.painb1, f.painb2, f.painb3, f.painb4, f.painb5, f.painb6,
    f.painb7, f.painb8, f.painb9, f.painb10, f.painb11 = count(11)

f.attackb1, f.attackb2, f.attackb3, f.attackb4, f.attackb5, f.attackb6,
    f.attackb7, f.attackb8, f.attackb9, f.attackb10, f.attackb11 = count(11)

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
    f.walk7, f.walk8, f.walk9, f.walk10, f.walk11, f.walk12,
    f.walk13, f.walk14 = count(14)

f.kneel1, f.kneel2, f.kneel3, f.kneel4, f.kneel5 = count(5)

f.standing2, f.standing3, f.standing4, f.standing5 = count(4)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
    f.death7, f.death8, f.death9, f.death10 = count(10)

f.deathb1, f.deathb2, f.deathb3, f.deathb4, f.deathb5, f.deathb6,
    f.deathb7, f.deathb8, f.deathb9, f.deathb10, f.deathb11 = count(11)

--[[
==============================================================================

KNIGHT

==============================================================================
]]

local knight_stand = {}
knight_stand[1] = animation.frame(f.stand1, function() return knight_stand[2] end, ai.stand)
knight_stand[2] = animation.frame(f.stand2, function() return knight_stand[3] end, ai.stand)
knight_stand[3] = animation.frame(f.stand3, function() return knight_stand[4] end, ai.stand)
knight_stand[4] = animation.frame(f.stand4, function() return knight_stand[5] end, ai.stand)
knight_stand[5] = animation.frame(f.stand5, function() return knight_stand[6] end, ai.stand)
knight_stand[6] = animation.frame(f.stand6, function() return knight_stand[7] end, ai.stand)
knight_stand[7] = animation.frame(f.stand7, function() return knight_stand[8] end, ai.stand)
knight_stand[8] = animation.frame(f.stand8, function() return knight_stand[9] end, ai.stand)
knight_stand[9] = animation.frame(f.stand9, function() return knight_stand[1] end, ai.stand)

local knight_walk = {}
knight_walk[1] = animation.frame(f.walk1, function() return knight_walk[2] end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "knight/idle.wav", 1, C.ATTN_IDLE) end; ai.walk(self, 3) end)
knight_walk[2] = animation.frame(f.walk2, function() return knight_walk[3] end, function(self) ai.walk(self, 2) end)
knight_walk[3] = animation.frame(f.walk3, function() return knight_walk[4] end, function(self) ai.walk(self, 3) end)
knight_walk[4] = animation.frame(f.walk4, function() return knight_walk[5] end, function(self) ai.walk(self, 4) end)
knight_walk[5] = animation.frame(f.walk5, function() return knight_walk[6] end, function(self) ai.walk(self, 3) end)
knight_walk[6] = animation.frame(f.walk6, function() return knight_walk[7] end, function(self) ai.walk(self, 3) end)
knight_walk[7] = animation.frame(f.walk7, function() return knight_walk[8] end, function(self) ai.walk(self, 3) end)
knight_walk[8] = animation.frame(f.walk8, function() return knight_walk[9] end, function(self) ai.walk(self, 4) end)
knight_walk[9] = animation.frame(f.walk9, function() return knight_walk[10] end, function(self) ai.walk(self, 3) end)
knight_walk[10] = animation.frame(f.walk10, function() return knight_walk[11] end, function(self) ai.walk(self, 3) end)
knight_walk[11] = animation.frame(f.walk11, function() return knight_walk[12] end, function(self) ai.walk(self, 2) end)
knight_walk[12] = animation.frame(f.walk12, function() return knight_walk[13] end, function(self) ai.walk(self, 3) end)
knight_walk[13] = animation.frame(f.walk13, function() return knight_walk[14] end, function(self) ai.walk(self, 4) end)
knight_walk[14] = animation.frame(f.walk14, function() return knight_walk[1] end, function(self) ai.walk(self, 3) end)

local knight_run = {}
knight_run[1] = animation.frame(f.runb1, function() return knight_run[2] end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "knight/idle.wav", 1, C.ATTN_IDLE) end; ai.run(self, 16) end)
knight_run[2] = animation.frame(f.runb2, function() return knight_run[3] end, function(self) ai.run(self, 20) end)
knight_run[3] = animation.frame(f.runb3, function() return knight_run[4] end, function(self) ai.run(self, 13) end)
knight_run[4] = animation.frame(f.runb4, function() return knight_run[5] end, function(self) ai.run(self, 7) end)
knight_run[5] = animation.frame(f.runb5, function() return knight_run[6] end, function(self) ai.run(self, 16) end)
knight_run[6] = animation.frame(f.runb6, function() return knight_run[7] end, function(self) ai.run(self, 20) end)
knight_run[7] = animation.frame(f.runb7, function() return knight_run[8] end, function(self) ai.run(self, 14) end)
knight_run[8] = animation.frame(f.runb8, function() return knight_run[1] end, function(self) ai.run(self, 6) end)

local knight_runatk = {}
knight_runatk[1] = animation.frame(f.runattack1, function() return knight_runatk[2] end, function(self) if quake.random() > 0.5 then quake.sound(self, C.CHAN_WEAPON, "knight/sword2.wav", 1, C.ATTN_NORM) else quake.sound(self, C.CHAN_WEAPON, "knight/sword1.wav", 1, C.ATTN_NORM) end; fight.charge(self, 20) end)
knight_runatk[2] = animation.frame(f.runattack2, function() return knight_runatk[3] end, function(self) fight.charge_side(self) end)
knight_runatk[3] = animation.frame(f.runattack3, function() return knight_runatk[4] end, function(self) fight.charge_side(self) end)
knight_runatk[4] = animation.frame(f.runattack4, function() return knight_runatk[5] end, function(self) fight.charge_side(self) end)
knight_runatk[5] = animation.frame(f.runattack5, function() return knight_runatk[6] end, function(self) fight.melee_side(self) end)
knight_runatk[6] = animation.frame(f.runattack6, function() return knight_runatk[7] end, function(self) fight.melee_side(self) end)
knight_runatk[7] = animation.frame(f.runattack7, function() return knight_runatk[8] end, function(self) fight.melee_side(self) end)
knight_runatk[8] = animation.frame(f.runattack8, function() return knight_runatk[9] end, function(self) fight.melee_side(self) end)
knight_runatk[9] = animation.frame(f.runattack9, function() return knight_runatk[10] end, function(self) fight.melee_side(self) end)
knight_runatk[10] = animation.frame(f.runattack10, function() return knight_runatk[11] end, function(self) fight.charge_side(self) end)
knight_runatk[11] = animation.frame(f.runattack11, function() return knight_run[1] end, function(self) fight.charge(self, 10) end)

local knight_atk = {}
knight_atk[1] = animation.frame(f.attackb1, function() return knight_atk[2] end, function(self) quake.sound(self, C.CHAN_WEAPON, "knight/sword1.wav", 1, C.ATTN_NORM); fight.charge(self, 0) end)
knight_atk[2] = animation.frame(f.attackb2, function() return knight_atk[3] end, function(self) fight.charge(self, 7) end)
knight_atk[3] = animation.frame(f.attackb3, function() return knight_atk[4] end, function(self) fight.charge(self, 4) end)
knight_atk[4] = animation.frame(f.attackb4, function() return knight_atk[5] end, function(self) fight.charge(self, 0) end)
knight_atk[5] = animation.frame(f.attackb5, function() return knight_atk[6] end, function(self) fight.charge(self, 3) end)
knight_atk[6] = animation.frame(f.attackb6, function() return knight_atk[7] end, function(self) fight.charge(self, 4); fight.melee(self) end)
knight_atk[7] = animation.frame(f.attackb7, function() return knight_atk[8] end, function(self) fight.charge(self, 1); fight.melee(self) end)
knight_atk[8] = animation.frame(f.attackb8, function() return knight_atk[9] end, function(self) fight.charge(self, 3); fight.melee(self) end)
knight_atk[9] = animation.frame(f.attackb9, function() return knight_atk[10] end, function(self) fight.charge(self, 1) end)
knight_atk[10] = animation.frame(f.attackb10, function() return knight_run[1] end, function(self) fight.charge(self, 5) end)

--===========================================================================

local knight_pain = {}
knight_pain[1] = animation.frame(f.pain1, function() return knight_pain[2] end)
knight_pain[2] = animation.frame(f.pain2, function() return knight_pain[3] end)
knight_pain[3] = animation.frame(f.pain3, function() return knight_run[1] end)

local knight_painb = {}
knight_painb[1] = animation.frame(f.painb1, function() return knight_painb[2] end, function(self) ai.pain_forward(self, 0) end)
knight_painb[2] = animation.frame(f.painb2, function() return knight_painb[3] end, function(self) ai.pain_forward(self, 3) end)
knight_painb[3] = animation.frame(f.painb3, function() return knight_painb[4] end)
knight_painb[4] = animation.frame(f.painb4, function() return knight_painb[5] end)
knight_painb[5] = animation.frame(f.painb5, function() return knight_painb[6] end, function(self) ai.pain_forward(self, 2) end)
knight_painb[6] = animation.frame(f.painb6, function() return knight_painb[7] end, function(self) ai.pain_forward(self, 4) end)
knight_painb[7] = animation.frame(f.painb7, function() return knight_painb[8] end, function(self) ai.pain_forward(self, 2) end)
knight_painb[8] = animation.frame(f.painb8, function() return knight_painb[9] end, function(self) ai.pain_forward(self, 5) end)
knight_painb[9] = animation.frame(f.painb9, function() return knight_painb[10] end, function(self) ai.pain_forward(self, 5) end)
knight_painb[10] = animation.frame(f.painb10, function() return knight_painb[11] end, function(self) ai.pain_forward(self, 0) end)
knight_painb[11] = animation.frame(f.painb11, function() return knight_run[1] end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function knight_pain_handler(self, _attacker, _damage)
    if self.pain_finished > quake.time() then return end
    local r = quake.random()
    quake.sound(self, C.CHAN_VOICE, "knight/khurt.wav", 1, C.ATTN_NORM)
    if r < 0.85 then
        knight_pain[1](self)
        self.pain_finished = quake.time() + 1
    else
        knight_painb[1](self)
        self.pain_finished = quake.time() + 1
    end
end

--===========================================================================

local knight_bow = {}
knight_bow[1] = animation.frame(f.kneel1, function() return knight_bow[2] end, ai.turn)
knight_bow[2] = animation.frame(f.kneel2, function() return knight_bow[3] end, ai.turn)
knight_bow[3] = animation.frame(f.kneel3, function() return knight_bow[4] end, ai.turn)
knight_bow[4] = animation.frame(f.kneel4, function() return knight_bow[5] end, ai.turn)
knight_bow[5] = animation.frame(f.kneel5, function() return knight_bow[5] end, ai.turn)
knight_bow[6] = animation.frame(f.kneel4, function() return knight_bow[7] end, ai.turn)
knight_bow[7] = animation.frame(f.kneel3, function() return knight_bow[8] end, ai.turn)
knight_bow[8] = animation.frame(f.kneel2, function() return knight_bow[9] end, ai.turn)
knight_bow[9] = animation.frame(f.kneel1, function() return knight_bow[10] end, ai.turn)
knight_bow[10] = animation.frame(f.walk1, function() return knight_walk[1] end, ai.turn)

local knight_die = {}
knight_die[1] = animation.frame(f.death1, function() return knight_die[2] end)
knight_die[2] = animation.frame(f.death2, function() return knight_die[3] end)
knight_die[3] = animation.frame(f.death3, function() return knight_die[4] end, function(self) self.solid = C.SOLID_NOT end)
knight_die[4] = animation.frame(f.death4, function() return knight_die[5] end)
knight_die[5] = animation.frame(f.death5, function() return knight_die[6] end)
knight_die[6] = animation.frame(f.death6, function() return knight_die[7] end)
knight_die[7] = animation.frame(f.death7, function() return knight_die[8] end)
knight_die[8] = animation.frame(f.death8, function() return knight_die[9] end)
knight_die[9] = animation.frame(f.death9, function() return knight_die[10] end)
knight_die[10] = animation.frame(f.death10, function() return knight_die[10] end)

local knight_dieb = {}
knight_dieb[1] = animation.frame(f.deathb1, function() return knight_dieb[2] end)
knight_dieb[2] = animation.frame(f.deathb2, function() return knight_dieb[3] end)
knight_dieb[3] = animation.frame(f.deathb3, function() return knight_dieb[4] end, function(self) self.solid = C.SOLID_NOT end)
knight_dieb[4] = animation.frame(f.deathb4, function() return knight_dieb[5] end)
knight_dieb[5] = animation.frame(f.deathb5, function() return knight_dieb[6] end)
knight_dieb[6] = animation.frame(f.deathb6, function() return knight_dieb[7] end)
knight_dieb[7] = animation.frame(f.deathb7, function() return knight_dieb[8] end)
knight_dieb[8] = animation.frame(f.deathb8, function() return knight_dieb[9] end)
knight_dieb[9] = animation.frame(f.deathb9, function() return knight_dieb[10] end)
knight_dieb[10] = animation.frame(f.deathb10, function() return knight_dieb[11] end)
knight_dieb[11] = animation.frame(f.deathb11, function() return knight_dieb[11] end)

---@param self entity
---@return nil
local function knight_die_handler(self)
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
    if quake.random() < 0.5 then knight_die[1](self) else knight_dieb[1](self) end
end

---QUAKED monster_knight (1 0 0) (-16 -16 -24) (16 16 40) Ambush
---@param self entity
---@return nil
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
    self.th_stand = knight_stand[1]
    self.th_walk = knight_walk[1]
    self.th_run = knight_run[1]
    self.th_melee = knight_atk[1]
    self.th_pain = knight_pain_handler
    self.th_die = knight_die_handler
    monsters.walk_start(self)
end

M.atk1 = knight_atk[1]
M.runatk1 = knight_runatk[1]

quake.register_entity("monster_knight", M.spawn)

return M
