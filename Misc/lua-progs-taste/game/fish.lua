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
-- Port of fish.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local ai = require("game.ai")
local animation = require("game.animation")
local combat = require("game.combat")
local fight = require("game.fight")
local gibs = require("game.gibs")
local monsters = require("game.monsters")
local subs = require("game.subs")

local M = {}

local count = animation.counter()
local f = {}

f.attack1, f.attack2, f.attack3, f.attack4, f.attack5, f.attack6,
    f.attack7, f.attack8, f.attack9, f.attack10, f.attack11, f.attack12,
    f.attack13, f.attack14, f.attack15, f.attack16, f.attack17, f.attack18 = count(18)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
    f.death7, f.death8, f.death9, f.death10, f.death11, f.death12,
    f.death13, f.death14, f.death15, f.death16, f.death17, f.death18,
    f.death19, f.death20, f.death21 = count(21)

f.swim1, f.swim2, f.swim3, f.swim4, f.swim5, f.swim6,
    f.swim7, f.swim8, f.swim9, f.swim10, f.swim11, f.swim12,
    f.swim13, f.swim14, f.swim15, f.swim16, f.swim17, f.swim18 = count(18)

f.pain1, f.pain2, f.pain3, f.pain4, f.pain5, f.pain6,
    f.pain7, f.pain8, f.pain9 = count(9)

--[[
==============================================================================

FISH (Rotfish)

==============================================================================
]]

local f_stand = {}
f_stand[1] = animation.frame(f.swim1, function() return f_stand[2] end, ai.stand)
f_stand[2] = animation.frame(f.swim2, function() return f_stand[3] end, ai.stand)
f_stand[3] = animation.frame(f.swim3, function() return f_stand[4] end, ai.stand)
f_stand[4] = animation.frame(f.swim4, function() return f_stand[5] end, ai.stand)
f_stand[5] = animation.frame(f.swim5, function() return f_stand[6] end, ai.stand)
f_stand[6] = animation.frame(f.swim6, function() return f_stand[7] end, ai.stand)
f_stand[7] = animation.frame(f.swim7, function() return f_stand[8] end, ai.stand)
f_stand[8] = animation.frame(f.swim8, function() return f_stand[9] end, ai.stand)
f_stand[9] = animation.frame(f.swim9, function() return f_stand[10] end, ai.stand)
f_stand[10] = animation.frame(f.swim10, function() return f_stand[11] end, ai.stand)
f_stand[11] = animation.frame(f.swim11, function() return f_stand[12] end, ai.stand)
f_stand[12] = animation.frame(f.swim12, function() return f_stand[13] end, ai.stand)
f_stand[13] = animation.frame(f.swim13, function() return f_stand[14] end, ai.stand)
f_stand[14] = animation.frame(f.swim14, function() return f_stand[15] end, ai.stand)
f_stand[15] = animation.frame(f.swim15, function() return f_stand[16] end, ai.stand)
f_stand[16] = animation.frame(f.swim16, function() return f_stand[17] end, ai.stand)
f_stand[17] = animation.frame(f.swim17, function() return f_stand[18] end, ai.stand)
f_stand[18] = animation.frame(f.swim18, function() return f_stand[1] end, ai.stand)

local f_walk = {}
f_walk[1] = animation.frame(f.swim1, function() return f_walk[2] end, function(self) ai.walk(self, 8) end)
f_walk[2] = animation.frame(f.swim2, function() return f_walk[3] end, function(self) ai.walk(self, 8) end)
f_walk[3] = animation.frame(f.swim3, function() return f_walk[4] end, function(self) ai.walk(self, 8) end)
f_walk[4] = animation.frame(f.swim4, function() return f_walk[5] end, function(self) ai.walk(self, 8) end)
f_walk[5] = animation.frame(f.swim5, function() return f_walk[6] end, function(self) ai.walk(self, 8) end)
f_walk[6] = animation.frame(f.swim6, function() return f_walk[7] end, function(self) ai.walk(self, 8) end)
f_walk[7] = animation.frame(f.swim7, function() return f_walk[8] end, function(self) ai.walk(self, 8) end)
f_walk[8] = animation.frame(f.swim8, function() return f_walk[9] end, function(self) ai.walk(self, 8) end)
f_walk[9] = animation.frame(f.swim9, function() return f_walk[10] end, function(self) ai.walk(self, 8) end)
f_walk[10] = animation.frame(f.swim10, function() return f_walk[11] end, function(self) ai.walk(self, 8) end)
f_walk[11] = animation.frame(f.swim11, function() return f_walk[12] end, function(self) ai.walk(self, 8) end)
f_walk[12] = animation.frame(f.swim12, function() return f_walk[13] end, function(self) ai.walk(self, 8) end)
f_walk[13] = animation.frame(f.swim13, function() return f_walk[14] end, function(self) ai.walk(self, 8) end)
f_walk[14] = animation.frame(f.swim14, function() return f_walk[15] end, function(self) ai.walk(self, 8) end)
f_walk[15] = animation.frame(f.swim15, function() return f_walk[16] end, function(self) ai.walk(self, 8) end)
f_walk[16] = animation.frame(f.swim16, function() return f_walk[17] end, function(self) ai.walk(self, 8) end)
f_walk[17] = animation.frame(f.swim17, function() return f_walk[18] end, function(self) ai.walk(self, 8) end)
f_walk[18] = animation.frame(f.swim18, function() return f_walk[1] end, function(self) ai.walk(self, 8) end)

local f_run = {}
f_run[1] = animation.frame(f.swim1, function() return f_run[2] end, function(self)
    ai.run(self, 12)
    if quake.random() < 0.5 then
        quake.sound(self, C.CHAN_VOICE, "fish/idle.wav", 1, C.ATTN_NORM)
    end
end)
f_run[2] = animation.frame(f.swim3, function() return f_run[3] end, function(self) ai.run(self, 12) end)
f_run[3] = animation.frame(f.swim5, function() return f_run[4] end, function(self) ai.run(self, 12) end)
f_run[4] = animation.frame(f.swim7, function() return f_run[5] end, function(self) ai.run(self, 12) end)
f_run[5] = animation.frame(f.swim9, function() return f_run[6] end, function(self) ai.run(self, 12) end)
f_run[6] = animation.frame(f.swim11, function() return f_run[7] end, function(self) ai.run(self, 12) end)
f_run[7] = animation.frame(f.swim13, function() return f_run[8] end, function(self) ai.run(self, 12) end)
f_run[8] = animation.frame(f.swim15, function() return f_run[9] end, function(self) ai.run(self, 12) end)
f_run[9] = animation.frame(f.swim17, function() return f_run[1] end, function(self) ai.run(self, 12) end)

---@param self entity
---@return nil
local function fish_melee(self)
    if not self.enemy then
        return
    end
    if (self.enemy.origin - self.origin):length() > 60 then
        return
    end

    quake.sound(self, C.CHAN_VOICE, "fish/bite.wav", 1, C.ATTN_NORM)
    local damage = (quake.random() + quake.random()) * 3
    combat.damage(self.enemy, self, self, damage)
end

local f_attack = {}
f_attack[1] = animation.frame(f.attack1, function() return f_attack[2] end, function(self) fight.charge(self, 10) end)
f_attack[2] = animation.frame(f.attack2, function() return f_attack[3] end, function(self) fight.charge(self, 10) end)
f_attack[3] = animation.frame(f.attack3, function() return f_attack[4] end, fish_melee)
f_attack[4] = animation.frame(f.attack4, function() return f_attack[5] end, function(self) fight.charge(self, 10) end)
f_attack[5] = animation.frame(f.attack5, function() return f_attack[6] end, function(self) fight.charge(self, 10) end)
f_attack[6] = animation.frame(f.attack6, function() return f_attack[7] end, function(self) fight.charge(self, 10) end)
f_attack[7] = animation.frame(f.attack7, function() return f_attack[8] end, function(self) fight.charge(self, 10) end)
f_attack[8] = animation.frame(f.attack8, function() return f_attack[9] end, function(self) fight.charge(self, 10) end)
f_attack[9] = animation.frame(f.attack9, function() return f_attack[10] end, fish_melee)
f_attack[10] = animation.frame(f.attack10, function() return f_attack[11] end, function(self) fight.charge(self, 10) end)
f_attack[11] = animation.frame(f.attack11, function() return f_attack[12] end, function(self) fight.charge(self, 10) end)
f_attack[12] = animation.frame(f.attack12, function() return f_attack[13] end, function(self) fight.charge(self, 10) end)
f_attack[13] = animation.frame(f.attack13, function() return f_attack[14] end, function(self) fight.charge(self, 10) end)
f_attack[14] = animation.frame(f.attack14, function() return f_attack[15] end, function(self) fight.charge(self, 10) end)
f_attack[15] = animation.frame(f.attack15, function() return f_attack[16] end, fish_melee)
f_attack[16] = animation.frame(f.attack16, function() return f_attack[17] end, function(self) fight.charge(self, 10) end)
f_attack[17] = animation.frame(f.attack17, function() return f_attack[18] end, function(self) fight.charge(self, 10) end)
f_attack[18] = animation.frame(f.attack18, function() return f_run[1] end, function(self) fight.charge(self, 10) end)

local f_death = {}
f_death[1] = animation.frame(f.death1, function() return f_death[2] end, function(self)
    quake.sound(self, C.CHAN_VOICE, "fish/death.wav", 1, C.ATTN_NORM)
end)
f_death[2] = animation.frame(f.death2, function() return f_death[3] end, function(self) self.solid = C.SOLID_NOT end)
f_death[3] = animation.frame(f.death3, function() return f_death[4] end)
f_death[4] = animation.frame(f.death4, function() return f_death[5] end)
f_death[5] = animation.frame(f.death5, function() return f_death[6] end)
f_death[6] = animation.frame(f.death6, function() return f_death[7] end)
f_death[7] = animation.frame(f.death7, function() return f_death[8] end)
f_death[8] = animation.frame(f.death8, function() return f_death[9] end)
f_death[9] = animation.frame(f.death9, function() return f_death[10] end)
f_death[10] = animation.frame(f.death10, function() return f_death[11] end)
f_death[11] = animation.frame(f.death11, function() return f_death[12] end)
f_death[12] = animation.frame(f.death12, function() return f_death[13] end)
f_death[13] = animation.frame(f.death13, function() return f_death[14] end)
f_death[14] = animation.frame(f.death14, function() return f_death[15] end)
f_death[15] = animation.frame(f.death15, function() return f_death[16] end)
f_death[16] = animation.frame(f.death16, function() return f_death[17] end)
f_death[17] = animation.frame(f.death17, function() return f_death[18] end)
f_death[18] = animation.frame(f.death18, function() return f_death[19] end)
f_death[19] = animation.frame(f.death19, function() return f_death[20] end)
f_death[20] = animation.frame(f.death20, function() return f_death[21] end)
f_death[21] = animation.frame(f.death21, function() return f_death[21] end)

-- Handle fish death, either die animation or gib.
---@param self entity
---@return nil
local function fish_die(self)
    -- Check for gib death.
    if self.health < -20 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        -- Can't call ThrowHead so remove the entity on the next think.
        self.think = subs.remove
        self.nextthink = quake.time() + 0.1
        -- Throw some normal gibs.
        gibs.throw(self, "progs/gib1.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        return
    end

    -- Run normal death animation.
    f_death[1](self)
end

local f_pain = {}
f_pain[1] = animation.frame(f.pain1, function() return f_pain[2] end)
f_pain[2] = animation.frame(f.pain2, function() return f_pain[3] end, function(self) ai.pain(self, 6) end)
f_pain[3] = animation.frame(f.pain3, function() return f_pain[4] end, function(self) ai.pain(self, 6) end)
f_pain[4] = animation.frame(f.pain4, function() return f_pain[5] end, function(self) ai.pain(self, 6) end)
f_pain[5] = animation.frame(f.pain5, function() return f_pain[6] end, function(self) ai.pain(self, 6) end)
f_pain[6] = animation.frame(f.pain6, function() return f_pain[7] end, function(self) ai.pain(self, 6) end)
f_pain[7] = animation.frame(f.pain7, function() return f_pain[8] end, function(self) ai.pain(self, 6) end)
f_pain[8] = animation.frame(f.pain8, function() return f_pain[9] end, function(self) ai.pain(self, 6) end)
f_pain[9] = animation.frame(f.pain9, function() return f_run[1] end, function(self) ai.pain(self, 6) end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function fish_pain(self, _attacker, _damage)
    -- Fish always do pain frames.
    f_pain[1](self)
end

---QUAKED monster_fish (1 0 0) (-16 -16 -24) (16 16 24) Ambush
---@param self entity
---@return nil
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end

    quake.precache_model("progs/fish.mdl")
    quake.precache_sound("fish/death.wav")
    quake.precache_sound("fish/bite.wav")
    quake.precache_sound("fish/idle.wav")

    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP
    quake.set_model(self, "progs/fish.mdl")
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 24))
    self.health = 25

    self.th_stand = f_stand[1]
    self.th_walk = f_walk[1]
    self.th_run = f_run[1]
    self.th_die = fish_die
    self.th_pain = fish_pain
    self.th_melee = f_attack[1]

    monsters.swim_start(self)
end

quake.register_entity("monster_fish", M.spawn)

return M
