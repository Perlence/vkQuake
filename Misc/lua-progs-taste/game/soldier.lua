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

local C = require("game.constants")
local ai = require("game.ai")
local animation = require("game.animation")
local fight = require("game.fight")
local gibs = require("game.gibs")
local items = require("game.items")
local monsters = require("game.monsters")
local subs = require("game.subs")
local weapons = require("game.weapons")

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

local army_stand = animation.loop("soldier.army_stand", {
    { f.stand1, ai.stand },
    { f.stand2, ai.stand },
    { f.stand3, ai.stand },
    { f.stand4, ai.stand },
    { f.stand5, ai.stand },
    { f.stand6, ai.stand },
    { f.stand7, ai.stand },
    { f.stand8, ai.stand },
})

local army_walk = animation.loop("soldier.army_walk", {
    { f.prowl_1, function(self)
        if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "soldier/idle.wav", 1, C.ATTN_IDLE) end; ai.walk(
            self, 1)
    end },
    { f.prowl_2, function(self) ai.walk(self, 1) end },
    { f.prowl_3, function(self) ai.walk(self, 1) end },
    { f.prowl_4, function(self) ai.walk(self, 1) end },
    { f.prowl_5, function(self) ai.walk(self, 2) end },
    { f.prowl_6, function(self) ai.walk(self, 3) end },
    { f.prowl_7, function(self) ai.walk(self, 4) end },
    { f.prowl_8, function(self) ai.walk(self, 4) end },
    { f.prowl_9, function(self) ai.walk(self, 2) end },
    { f.prowl_10, function(self) ai.walk(self, 2) end },
    { f.prowl_11, function(self) ai.walk(self, 2) end },
    { f.prowl_12, function(self) ai.walk(self, 1) end },
    { f.prowl_13, function(self) ai.walk(self, 0) end },
    { f.prowl_14, function(self) ai.walk(self, 1) end },
    { f.prowl_15, function(self) ai.walk(self, 1) end },
    { f.prowl_16, function(self) ai.walk(self, 1) end },
    { f.prowl_17, function(self) ai.walk(self, 3) end },
    { f.prowl_18, function(self) ai.walk(self, 3) end },
    { f.prowl_19, function(self) ai.walk(self, 3) end },
    { f.prowl_20, function(self) ai.walk(self, 3) end },
    { f.prowl_21, function(self) ai.walk(self, 2) end },
    { f.prowl_22, function(self) ai.walk(self, 1) end },
    { f.prowl_23, function(self) ai.walk(self, 1) end },
    { f.prowl_24, function(self) ai.walk(self, 1) end },
})

local army_run = animation.loop("soldier.army_run", {
    { f.run1, function(self)
        if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "soldier/idle.wav", 1, C.ATTN_IDLE) end; ai.run(
            self, 11)
    end },
    { f.run2, function(self) ai.run(self, 15) end },
    { f.run3, function(self) ai.run(self, 10) end },
    { f.run4, function(self) ai.run(self, 10) end },
    { f.run5, function(self) ai.run(self, 8) end },
    { f.run6, function(self) ai.run(self, 15) end },
    { f.run7, function(self) ai.run(self, 10) end },
    { f.run8, function(self) ai.run(self, 8) end },
})

local army_atk, army_fire
army_atk = animation.sequence("soldier.army_atk", {
    { f.shoot1, function(self) fight.face(self) end },
    { f.shoot2, function(self) fight.face(self) end },
    { f.shoot3, function(self) fight.face(self) end },
    { f.shoot4, function(self) fight.face(self) end },
    { f.shoot5, function(self)
        fight.face(self); army_fire(self); self.effects = self.effects | C.EF_MUZZLEFLASH
    end },
    { f.shoot6, function(self) fight.face(self) end },
    { f.shoot7, function(self)
        fight.face(self); subs.check_refire(self, army_atk)
    end },
    { f.shoot8, function(self) fight.face(self) end },
    { f.shoot9, function(self) fight.face(self) end },
}, function() return army_run end)

local army_pain = animation.sequence("soldier.army_pain", {
    { f.pain1 },
    { f.pain2 },
    { f.pain3 },
    { f.pain4 },
    { f.pain5 },
    { f.pain6, function(self) ai.pain(self, 1) end },
}, function() return army_run end)

local army_painb = animation.sequence("soldier.army_painb", {
    { f.painb1 },
    { f.painb2, function(self) ai.pain_forward(self, 13) end },
    { f.painb3, function(self) ai.pain_forward(self, 9) end },
    { f.painb4 },
    { f.painb5 },
    { f.painb6 },
    { f.painb7 },
    { f.painb8 },
    { f.painb9 },
    { f.painb10 },
    { f.painb11 },
    { f.painb12, function(self) ai.pain(self, 2) end },
    { f.painb13 },
    { f.painb14 },
}, function() return army_run end)

local army_painc = animation.sequence("soldier.army_painc", {
    { f.painc1 },
    { f.painc2, function(self) ai.pain(self, 1) end },
    { f.painc3 },
    { f.painc4 },
    { f.painc5, function(self) ai.pain_forward(self, 1) end },
    { f.painc6, function(self) ai.pain_forward(self, 1) end },
    { f.painc7 },
    { f.painc8, function(self) ai.pain(self, 1) end },
    { f.painc9, function(self) ai.pain_forward(self, 4) end },
    { f.painc10, function(self) ai.pain_forward(self, 3) end },
    { f.painc11, function(self) ai.pain_forward(self, 6) end },
    { f.painc12, function(self) ai.pain_forward(self, 8) end },
    { f.painc13 },
}, function() return army_run end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local army_pain_handler = quake.register_function("soldier.army_pain_handler", function(self, _attacker, _damage)
    if self.pain_finished > quake.time() then return end
    local r = quake.random()
    if r < 0.2 then
        self.pain_finished = quake.time() + 0.6
        army_pain(self)
        quake.sound(self, C.CHAN_VOICE, "soldier/pain1.wav", 1, C.ATTN_NORM)
    elseif r < 0.6 then
        self.pain_finished = quake.time() + 1.1
        army_painb(self)
        quake.sound(self, C.CHAN_VOICE, "soldier/pain2.wav", 1, C.ATTN_NORM)
    else
        self.pain_finished = quake.time() + 1.1
        army_painc(self)
        quake.sound(self, C.CHAN_VOICE, "soldier/pain2.wav", 1, C.ATTN_NORM)
    end
end)

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

local army_die = animation.hold("soldier.army_die", {
    { f.death1 },
    { f.death2 },
    { f.death3, function(self)
        self.solid = C.SOLID_NOT; self.ammo_shells = 5; items.drop_backpack(self)
    end },
    { f.death4 },
    { f.death5 },
    { f.death6 },
    { f.death7 },
    { f.death8 },
    { f.death9 },
    { f.death10 },
})

local army_cdie = animation.hold("soldier.army_cdie", {
    { f.deathc1 },
    { f.deathc2, function(self) ai.back(self, 5) end },
    { f.deathc3, function(self)
        self.solid = C.SOLID_NOT; self.ammo_shells = 5; items.drop_backpack(self); ai.back(self, 4)
    end },
    { f.deathc4, function(self) ai.back(self, 13) end },
    { f.deathc5, function(self) ai.back(self, 3) end },
    { f.deathc6, function(self) ai.back(self, 4) end },
    { f.deathc7 },
    { f.deathc8 },
    { f.deathc9 },
    { f.deathc10 },
    { f.deathc11 },
})

---@param self entity
---@return nil
local army_die_handler = quake.register_function("soldier.army_die_handler", function(self)
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
    if quake.random() < 0.5 then army_die(self) else army_cdie(self) end
end)

---QUAKED monster_army (1 0 0) (-16 -16 -24) (16 16 40) Ambush
---@param self entity
---@return nil
local function spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self); return
    end
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
    self.th_stand = army_stand
    self.th_walk = army_walk
    self.th_run = army_run
    self.th_missile = army_atk
    self.th_pain = army_pain_handler
    self.th_die = army_die_handler
    monsters.walk_start(self)
end

quake.register_entity("monster_army", spawn)
