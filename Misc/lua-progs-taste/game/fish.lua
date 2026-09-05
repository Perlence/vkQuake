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

local C = require("constants")
local ai = require("ai")
local animation = require("animation")
local combat = require("combat")
local fight = require("fight")
local gibs = require("gibs")
local monsters = require("monsters")
local subs = require("subs")

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

local f_stand = animation.loop("fish.f_stand", {
    { f.swim1, ai.stand },
    { f.swim2, ai.stand },
    { f.swim3, ai.stand },
    { f.swim4, ai.stand },
    { f.swim5, ai.stand },
    { f.swim6, ai.stand },
    { f.swim7, ai.stand },
    { f.swim8, ai.stand },
    { f.swim9, ai.stand },
    { f.swim10, ai.stand },
    { f.swim11, ai.stand },
    { f.swim12, ai.stand },
    { f.swim13, ai.stand },
    { f.swim14, ai.stand },
    { f.swim15, ai.stand },
    { f.swim16, ai.stand },
    { f.swim17, ai.stand },
    { f.swim18, ai.stand },
})

local f_walk = animation.loop("fish.f_walk", {
    { f.swim1, function(self) ai.walk(self, 8) end },
    { f.swim2, function(self) ai.walk(self, 8) end },
    { f.swim3, function(self) ai.walk(self, 8) end },
    { f.swim4, function(self) ai.walk(self, 8) end },
    { f.swim5, function(self) ai.walk(self, 8) end },
    { f.swim6, function(self) ai.walk(self, 8) end },
    { f.swim7, function(self) ai.walk(self, 8) end },
    { f.swim8, function(self) ai.walk(self, 8) end },
    { f.swim9, function(self) ai.walk(self, 8) end },
    { f.swim10, function(self) ai.walk(self, 8) end },
    { f.swim11, function(self) ai.walk(self, 8) end },
    { f.swim12, function(self) ai.walk(self, 8) end },
    { f.swim13, function(self) ai.walk(self, 8) end },
    { f.swim14, function(self) ai.walk(self, 8) end },
    { f.swim15, function(self) ai.walk(self, 8) end },
    { f.swim16, function(self) ai.walk(self, 8) end },
    { f.swim17, function(self) ai.walk(self, 8) end },
    { f.swim18, function(self) ai.walk(self, 8) end },
})

local f_run = animation.loop("fish.f_run", {
    { f.swim1, function(self)
        ai.run(self, 12)
        if quake.random() < 0.5 then
            quake.sound(self, C.CHAN_VOICE, "fish/idle.wav", 1, C.ATTN_NORM)
        end
    end },
    { f.swim3, function(self) ai.run(self, 12) end },
    { f.swim5, function(self) ai.run(self, 12) end },
    { f.swim7, function(self) ai.run(self, 12) end },
    { f.swim9, function(self) ai.run(self, 12) end },
    { f.swim11, function(self) ai.run(self, 12) end },
    { f.swim13, function(self) ai.run(self, 12) end },
    { f.swim15, function(self) ai.run(self, 12) end },
    { f.swim17, function(self) ai.run(self, 12) end },
})

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

local f_attack = animation.sequence("fish.f_attack", {
    { f.attack1, function(self) fight.charge(self, 10) end },
    { f.attack2, function(self) fight.charge(self, 10) end },
    { f.attack3, fish_melee },
    { f.attack4, function(self) fight.charge(self, 10) end },
    { f.attack5, function(self) fight.charge(self, 10) end },
    { f.attack6, function(self) fight.charge(self, 10) end },
    { f.attack7, function(self) fight.charge(self, 10) end },
    { f.attack8, function(self) fight.charge(self, 10) end },
    { f.attack9, fish_melee },
    { f.attack10, function(self) fight.charge(self, 10) end },
    { f.attack11, function(self) fight.charge(self, 10) end },
    { f.attack12, function(self) fight.charge(self, 10) end },
    { f.attack13, function(self) fight.charge(self, 10) end },
    { f.attack14, function(self) fight.charge(self, 10) end },
    { f.attack15, fish_melee },
    { f.attack16, function(self) fight.charge(self, 10) end },
    { f.attack17, function(self) fight.charge(self, 10) end },
    { f.attack18, function(self) fight.charge(self, 10) end },
}, function() return f_run end)

local f_death = animation.hold("fish.f_death", {
    { f.death1, function(self)
        quake.sound(self, C.CHAN_VOICE, "fish/death.wav", 1, C.ATTN_NORM)
    end },
    { f.death2, function(self) self.solid = C.SOLID_NOT end },
    { f.death3 },
    { f.death4 },
    { f.death5 },
    { f.death6 },
    { f.death7 },
    { f.death8 },
    { f.death9 },
    { f.death10 },
    { f.death11 },
    { f.death12 },
    { f.death13 },
    { f.death14 },
    { f.death15 },
    { f.death16 },
    { f.death17 },
    { f.death18 },
    { f.death19 },
    { f.death20 },
    { f.death21 },
})

-- Handle fish death, either die animation or gib.
---@param self entity
---@return nil
local fish_die = quake.register_function("fish.fish_die", function(self)
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
    f_death(self)
end)

local f_pain = animation.sequence("fish.f_pain", {
    { f.pain1 },
    { f.pain2, function(self) ai.pain(self, 6) end },
    { f.pain3, function(self) ai.pain(self, 6) end },
    { f.pain4, function(self) ai.pain(self, 6) end },
    { f.pain5, function(self) ai.pain(self, 6) end },
    { f.pain6, function(self) ai.pain(self, 6) end },
    { f.pain7, function(self) ai.pain(self, 6) end },
    { f.pain8, function(self) ai.pain(self, 6) end },
    { f.pain9, function(self) ai.pain(self, 6) end },
}, function() return f_run end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local fish_pain = quake.register_function("fish.fish_pain", function(self, _attacker, _damage)
    -- Fish always do pain frames.
    f_pain(self)
end)

---QUAKED monster_fish (1 0 0) (-16 -16 -24) (16 16 24) Ambush
---@param self entity
---@return nil
local function spawn(self)
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

    self.th_stand = f_stand
    self.th_walk = f_walk
    self.th_run = f_run
    self.th_die = fish_die
    self.th_pain = fish_pain
    self.th_melee = f_attack

    monsters.swim_start(self)
end

quake.register_entity("monster_fish", spawn)
