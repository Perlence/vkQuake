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

local C = require("constants")
local ai = require("ai")
local animation = require("animation")
local fight = require("fight")
local gibs = require("gibs")
local monsters = require("monsters")

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

local knight_stand = animation.loop("knight.knight_stand", {
    { f.stand1, ai.stand },
    { f.stand2, ai.stand },
    { f.stand3, ai.stand },
    { f.stand4, ai.stand },
    { f.stand5, ai.stand },
    { f.stand6, ai.stand },
    { f.stand7, ai.stand },
    { f.stand8, ai.stand },
    { f.stand9, ai.stand },
})

local knight_walk = animation.loop("knight.knight_walk", {
    { f.walk1, function(self)
        if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "knight/idle.wav", 1, C.ATTN_IDLE) end; ai.walk(
            self, 3)
    end },
    { f.walk2, function(self) ai.walk(self, 2) end },
    { f.walk3, function(self) ai.walk(self, 3) end },
    { f.walk4, function(self) ai.walk(self, 4) end },
    { f.walk5, function(self) ai.walk(self, 3) end },
    { f.walk6, function(self) ai.walk(self, 3) end },
    { f.walk7, function(self) ai.walk(self, 3) end },
    { f.walk8, function(self) ai.walk(self, 4) end },
    { f.walk9, function(self) ai.walk(self, 3) end },
    { f.walk10, function(self) ai.walk(self, 3) end },
    { f.walk11, function(self) ai.walk(self, 2) end },
    { f.walk12, function(self) ai.walk(self, 3) end },
    { f.walk13, function(self) ai.walk(self, 4) end },
    { f.walk14, function(self) ai.walk(self, 3) end },
})

local knight_run = animation.loop("knight.knight_run", {
    { f.runb1, function(self)
        if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "knight/idle.wav", 1, C.ATTN_IDLE) end; ai.run(self,
            16)
    end },
    { f.runb2, function(self) ai.run(self, 20) end },
    { f.runb3, function(self) ai.run(self, 13) end },
    { f.runb4, function(self) ai.run(self, 7) end },
    { f.runb5, function(self) ai.run(self, 16) end },
    { f.runb6, function(self) ai.run(self, 20) end },
    { f.runb7, function(self) ai.run(self, 14) end },
    { f.runb8, function(self) ai.run(self, 6) end },
})

local knight_runatk = animation.sequence("knight.knight_runatk", {
    { f.runattack1, function(self)
        if quake.random() > 0.5 then
            quake.sound(self, C.CHAN_WEAPON, "knight/sword2.wav", 1, C.ATTN_NORM)
        else
            quake
                .sound(self, C.CHAN_WEAPON, "knight/sword1.wav", 1, C.ATTN_NORM)
        end; fight.charge(self, 20)
    end },
    { f.runattack2, function(self) fight.charge_side(self) end },
    { f.runattack3, function(self) fight.charge_side(self) end },
    { f.runattack4, function(self) fight.charge_side(self) end },
    { f.runattack5, function(self) fight.melee_side(self) end },
    { f.runattack6, function(self) fight.melee_side(self) end },
    { f.runattack7, function(self) fight.melee_side(self) end },
    { f.runattack8, function(self) fight.melee_side(self) end },
    { f.runattack9, function(self) fight.melee_side(self) end },
    { f.runattack10, function(self) fight.charge_side(self) end },
    { f.runattack11, function(self) fight.charge(self, 10) end },
}, function() return knight_run end)

local knight_atk = animation.sequence("knight.knight_atk", {
    { f.attackb1, function(self)
        quake.sound(self, C.CHAN_WEAPON, "knight/sword1.wav", 1, C.ATTN_NORM); fight.charge(self, 0)
    end },
    { f.attackb2, function(self) fight.charge(self, 7) end },
    { f.attackb3, function(self) fight.charge(self, 4) end },
    { f.attackb4, function(self) fight.charge(self, 0) end },
    { f.attackb5, function(self) fight.charge(self, 3) end },
    { f.attackb6, function(self)
        fight.charge(self, 4); fight.melee(self)
    end },
    { f.attackb7, function(self)
        fight.charge(self, 1); fight.melee(self)
    end },
    { f.attackb8, function(self)
        fight.charge(self, 3); fight.melee(self)
    end },
    { f.attackb9, function(self) fight.charge(self, 1) end },
    { f.attackb10, function(self) fight.charge(self, 5) end },
}, function() return knight_run end)

--===========================================================================

local knight_pain = animation.sequence("knight.knight_pain", {
    { f.pain1 },
    { f.pain2 },
    { f.pain3 },
}, function() return knight_run end)

local knight_painb = animation.sequence("knight.knight_painb", {
    { f.painb1, function(self) ai.pain_forward(self, 0) end },
    { f.painb2, function(self) ai.pain_forward(self, 3) end },
    { f.painb3 },
    { f.painb4 },
    { f.painb5, function(self) ai.pain_forward(self, 2) end },
    { f.painb6, function(self) ai.pain_forward(self, 4) end },
    { f.painb7, function(self) ai.pain_forward(self, 2) end },
    { f.painb8, function(self) ai.pain_forward(self, 5) end },
    { f.painb9, function(self) ai.pain_forward(self, 5) end },
    { f.painb10, function(self) ai.pain_forward(self, 0) end },
    { f.painb11 },
}, function() return knight_run end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local knight_pain_handler = quake.register_function("knight.knight_pain_handler", function(self, _attacker, _damage)
    if self.pain_finished > quake.time() then return end
    local r = quake.random()
    quake.sound(self, C.CHAN_VOICE, "knight/khurt.wav", 1, C.ATTN_NORM)
    if r < 0.85 then
        knight_pain(self)
        self.pain_finished = quake.time() + 1
    else
        knight_painb(self)
        self.pain_finished = quake.time() + 1
    end
end)

--===========================================================================

animation.hold("knight.knight_bow", {
    { f.kneel1, ai.turn },
    { f.kneel2, ai.turn },
    { f.kneel3, ai.turn },
    { f.kneel4, ai.turn },
    { f.kneel5, ai.turn },
})

animation.sequence("knight.knight_bow_up", {
    { f.kneel4, ai.turn },
    { f.kneel3, ai.turn },
    { f.kneel2, ai.turn },
    { f.kneel1, ai.turn },
    { f.walk1, ai.turn },
}, function() return knight_walk end)

local knight_die = animation.hold("knight.knight_die", {
    { f.death1 },
    { f.death2 },
    { f.death3, function(self) self.solid = C.SOLID_NOT end },
    { f.death4 },
    { f.death5 },
    { f.death6 },
    { f.death7 },
    { f.death8 },
    { f.death9 },
    { f.death10 },
})

local knight_dieb = animation.hold("knight.knight_dieb", {
    { f.deathb1 },
    { f.deathb2 },
    { f.deathb3, function(self) self.solid = C.SOLID_NOT end },
    { f.deathb4 },
    { f.deathb5 },
    { f.deathb6 },
    { f.deathb7 },
    { f.deathb8 },
    { f.deathb9 },
    { f.deathb10 },
    { f.deathb11 },
})

---@param self entity
---@return nil
local knight_die_handler = quake.register_function("knight.knight_die_handler", function(self)
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
    if quake.random() < 0.5 then knight_die(self) else knight_dieb(self) end
end)

---QUAKED monster_knight (1 0 0) (-16 -16 -24) (16 16 40) Ambush
---@param self entity
---@return nil
local function spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self); return
    end
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
    self.th_stand = knight_stand
    self.th_walk = knight_walk
    self.th_run = knight_run
    self.th_melee = knight_atk
    self.th_pain = knight_pain_handler
    self.th_die = knight_die_handler
    monsters.walk_start(self)
end

M.atk1 = knight_atk
M.runatk1 = knight_runatk

quake.register_entity("monster_knight", spawn)

return M
