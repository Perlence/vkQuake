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

local f_stand1, f_stand2, f_stand3, f_stand4, f_stand5, f_stand6
local f_stand7, f_stand8, f_stand9, f_stand10, f_stand11, f_stand12
local f_stand13, f_stand14, f_stand15, f_stand16, f_stand17, f_stand18

f_stand1 = animation.frame(f.swim1, function() return f_stand2 end, ai.stand)
f_stand2 = animation.frame(f.swim2, function() return f_stand3 end, ai.stand)
f_stand3 = animation.frame(f.swim3, function() return f_stand4 end, ai.stand)
f_stand4 = animation.frame(f.swim4, function() return f_stand5 end, ai.stand)
f_stand5 = animation.frame(f.swim5, function() return f_stand6 end, ai.stand)
f_stand6 = animation.frame(f.swim6, function() return f_stand7 end, ai.stand)
f_stand7 = animation.frame(f.swim7, function() return f_stand8 end, ai.stand)
f_stand8 = animation.frame(f.swim8, function() return f_stand9 end, ai.stand)
f_stand9 = animation.frame(f.swim9, function() return f_stand10 end, ai.stand)
f_stand10 = animation.frame(f.swim10, function() return f_stand11 end, ai.stand)
f_stand11 = animation.frame(f.swim11, function() return f_stand12 end, ai.stand)
f_stand12 = animation.frame(f.swim12, function() return f_stand13 end, ai.stand)
f_stand13 = animation.frame(f.swim13, function() return f_stand14 end, ai.stand)
f_stand14 = animation.frame(f.swim14, function() return f_stand15 end, ai.stand)
f_stand15 = animation.frame(f.swim15, function() return f_stand16 end, ai.stand)
f_stand16 = animation.frame(f.swim16, function() return f_stand17 end, ai.stand)
f_stand17 = animation.frame(f.swim17, function() return f_stand18 end, ai.stand)
f_stand18 = animation.frame(f.swim18, function() return f_stand1 end, ai.stand)

local f_walk1, f_walk2, f_walk3, f_walk4, f_walk5, f_walk6
local f_walk7, f_walk8, f_walk9, f_walk10, f_walk11, f_walk12
local f_walk13, f_walk14, f_walk15, f_walk16, f_walk17, f_walk18

f_walk1 = animation.frame(f.swim1, function() return f_walk2 end, function(self) ai.walk(self, 8) end)
f_walk2 = animation.frame(f.swim2, function() return f_walk3 end, function(self) ai.walk(self, 8) end)
f_walk3 = animation.frame(f.swim3, function() return f_walk4 end, function(self) ai.walk(self, 8) end)
f_walk4 = animation.frame(f.swim4, function() return f_walk5 end, function(self) ai.walk(self, 8) end)
f_walk5 = animation.frame(f.swim5, function() return f_walk6 end, function(self) ai.walk(self, 8) end)
f_walk6 = animation.frame(f.swim6, function() return f_walk7 end, function(self) ai.walk(self, 8) end)
f_walk7 = animation.frame(f.swim7, function() return f_walk8 end, function(self) ai.walk(self, 8) end)
f_walk8 = animation.frame(f.swim8, function() return f_walk9 end, function(self) ai.walk(self, 8) end)
f_walk9 = animation.frame(f.swim9, function() return f_walk10 end, function(self) ai.walk(self, 8) end)
f_walk10 = animation.frame(f.swim10, function() return f_walk11 end, function(self) ai.walk(self, 8) end)
f_walk11 = animation.frame(f.swim11, function() return f_walk12 end, function(self) ai.walk(self, 8) end)
f_walk12 = animation.frame(f.swim12, function() return f_walk13 end, function(self) ai.walk(self, 8) end)
f_walk13 = animation.frame(f.swim13, function() return f_walk14 end, function(self) ai.walk(self, 8) end)
f_walk14 = animation.frame(f.swim14, function() return f_walk15 end, function(self) ai.walk(self, 8) end)
f_walk15 = animation.frame(f.swim15, function() return f_walk16 end, function(self) ai.walk(self, 8) end)
f_walk16 = animation.frame(f.swim16, function() return f_walk17 end, function(self) ai.walk(self, 8) end)
f_walk17 = animation.frame(f.swim17, function() return f_walk18 end, function(self) ai.walk(self, 8) end)
f_walk18 = animation.frame(f.swim18, function() return f_walk1 end, function(self) ai.walk(self, 8) end)

local f_run1, f_run2, f_run3, f_run4, f_run5, f_run6, f_run7, f_run8, f_run9

f_run1 = animation.frame(f.swim1, function() return f_run2 end, function(self)
    ai.run(self, 12)
    if quake.random() < 0.5 then
        quake.sound(self, C.CHAN_VOICE, "fish/idle.wav", 1, C.ATTN_NORM)
    end
end)
f_run2 = animation.frame(f.swim3, function() return f_run3 end, function(self) ai.run(self, 12) end)
f_run3 = animation.frame(f.swim5, function() return f_run4 end, function(self) ai.run(self, 12) end)
f_run4 = animation.frame(f.swim7, function() return f_run5 end, function(self) ai.run(self, 12) end)
f_run5 = animation.frame(f.swim9, function() return f_run6 end, function(self) ai.run(self, 12) end)
f_run6 = animation.frame(f.swim11, function() return f_run7 end, function(self) ai.run(self, 12) end)
f_run7 = animation.frame(f.swim13, function() return f_run8 end, function(self) ai.run(self, 12) end)
f_run8 = animation.frame(f.swim15, function() return f_run9 end, function(self) ai.run(self, 12) end)
f_run9 = animation.frame(f.swim17, function() return f_run1 end, function(self) ai.run(self, 12) end)

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

local f_attack1, f_attack2, f_attack3, f_attack4, f_attack5, f_attack6
local f_attack7, f_attack8, f_attack9, f_attack10, f_attack11, f_attack12
local f_attack13, f_attack14, f_attack15, f_attack16, f_attack17, f_attack18

f_attack1 = animation.frame(f.attack1, function() return f_attack2 end, function(self) fight.charge(self, 10) end)
f_attack2 = animation.frame(f.attack2, function() return f_attack3 end, function(self) fight.charge(self, 10) end)
f_attack3 = animation.frame(f.attack3, function() return f_attack4 end, fish_melee)
f_attack4 = animation.frame(f.attack4, function() return f_attack5 end, function(self) fight.charge(self, 10) end)
f_attack5 = animation.frame(f.attack5, function() return f_attack6 end, function(self) fight.charge(self, 10) end)
f_attack6 = animation.frame(f.attack6, function() return f_attack7 end, function(self) fight.charge(self, 10) end)
f_attack7 = animation.frame(f.attack7, function() return f_attack8 end, function(self) fight.charge(self, 10) end)
f_attack8 = animation.frame(f.attack8, function() return f_attack9 end, function(self) fight.charge(self, 10) end)
f_attack9 = animation.frame(f.attack9, function() return f_attack10 end, fish_melee)
f_attack10 = animation.frame(f.attack10, function() return f_attack11 end, function(self) fight.charge(self, 10) end)
f_attack11 = animation.frame(f.attack11, function() return f_attack12 end, function(self) fight.charge(self, 10) end)
f_attack12 = animation.frame(f.attack12, function() return f_attack13 end, function(self) fight.charge(self, 10) end)
f_attack13 = animation.frame(f.attack13, function() return f_attack14 end, function(self) fight.charge(self, 10) end)
f_attack14 = animation.frame(f.attack14, function() return f_attack15 end, function(self) fight.charge(self, 10) end)
f_attack15 = animation.frame(f.attack15, function() return f_attack16 end, fish_melee)
f_attack16 = animation.frame(f.attack16, function() return f_attack17 end, function(self) fight.charge(self, 10) end)
f_attack17 = animation.frame(f.attack17, function() return f_attack18 end, function(self) fight.charge(self, 10) end)
f_attack18 = animation.frame(f.attack18, function() return f_run1 end, function(self) fight.charge(self, 10) end)

local f_death1, f_death2, f_death3, f_death4, f_death5, f_death6, f_death7
local f_death8, f_death9, f_death10, f_death11, f_death12, f_death13, f_death14
local f_death15, f_death16, f_death17, f_death18, f_death19, f_death20, f_death21

f_death1 = animation.frame(f.death1, function() return f_death2 end, function(self)
    quake.sound(self, C.CHAN_VOICE, "fish/death.wav", 1, C.ATTN_NORM)
end)
f_death2 = animation.frame(f.death2, function() return f_death3 end, function(self) self.solid = C.SOLID_NOT end)
f_death3 = animation.frame(f.death3, function() return f_death4 end)
f_death4 = animation.frame(f.death4, function() return f_death5 end)
f_death5 = animation.frame(f.death5, function() return f_death6 end)
f_death6 = animation.frame(f.death6, function() return f_death7 end)
f_death7 = animation.frame(f.death7, function() return f_death8 end)
f_death8 = animation.frame(f.death8, function() return f_death9 end)
f_death9 = animation.frame(f.death9, function() return f_death10 end)
f_death10 = animation.frame(f.death10, function() return f_death11 end)
f_death11 = animation.frame(f.death11, function() return f_death12 end)
f_death12 = animation.frame(f.death12, function() return f_death13 end)
f_death13 = animation.frame(f.death13, function() return f_death14 end)
f_death14 = animation.frame(f.death14, function() return f_death15 end)
f_death15 = animation.frame(f.death15, function() return f_death16 end)
f_death16 = animation.frame(f.death16, function() return f_death17 end)
f_death17 = animation.frame(f.death17, function() return f_death18 end)
f_death18 = animation.frame(f.death18, function() return f_death19 end)
f_death19 = animation.frame(f.death19, function() return f_death20 end)
f_death20 = animation.frame(f.death20, function() return f_death21 end)
f_death21 = animation.frame(f.death21, function() return f_death21 end)

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
    f_death1(self)
end

local f_pain1, f_pain2, f_pain3, f_pain4, f_pain5, f_pain6, f_pain7, f_pain8, f_pain9

f_pain1 = animation.frame(f.pain1, function() return f_pain2 end)
f_pain2 = animation.frame(f.pain2, function() return f_pain3 end, function(self) ai.pain(self, 6) end)
f_pain3 = animation.frame(f.pain3, function() return f_pain4 end, function(self) ai.pain(self, 6) end)
f_pain4 = animation.frame(f.pain4, function() return f_pain5 end, function(self) ai.pain(self, 6) end)
f_pain5 = animation.frame(f.pain5, function() return f_pain6 end, function(self) ai.pain(self, 6) end)
f_pain6 = animation.frame(f.pain6, function() return f_pain7 end, function(self) ai.pain(self, 6) end)
f_pain7 = animation.frame(f.pain7, function() return f_pain8 end, function(self) ai.pain(self, 6) end)
f_pain8 = animation.frame(f.pain8, function() return f_pain9 end, function(self) ai.pain(self, 6) end)
f_pain9 = animation.frame(f.pain9, function() return f_run1 end, function(self) ai.pain(self, 6) end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function fish_pain(self, _attacker, _damage)
    -- Fish always do pain frames.
    f_pain1(self)
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

    self.th_stand = f_stand1
    self.th_walk = f_walk1
    self.th_run = f_run1
    self.th_die = fish_die
    self.th_pain = fish_pain
    self.th_melee = f_attack1

    monsters.swim_start(self)
end

quake.register_entity("monster_fish", M.spawn)

return M
