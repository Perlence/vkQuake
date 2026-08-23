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

local army_stand = {}
army_stand[1] = animation.frame(f.stand1, function() return army_stand[2] end, ai.stand)
army_stand[2] = animation.frame(f.stand2, function() return army_stand[3] end, ai.stand)
army_stand[3] = animation.frame(f.stand3, function() return army_stand[4] end, ai.stand)
army_stand[4] = animation.frame(f.stand4, function() return army_stand[5] end, ai.stand)
army_stand[5] = animation.frame(f.stand5, function() return army_stand[6] end, ai.stand)
army_stand[6] = animation.frame(f.stand6, function() return army_stand[7] end, ai.stand)
army_stand[7] = animation.frame(f.stand7, function() return army_stand[8] end, ai.stand)
army_stand[8] = animation.frame(f.stand8, function() return army_stand[1] end, ai.stand)

local army_walk = {}
army_walk[1] = animation.frame(f.prowl_1, function() return army_walk[2] end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "soldier/idle.wav", 1, C.ATTN_IDLE) end; ai.walk(self, 1) end)
army_walk[2] = animation.frame(f.prowl_2, function() return army_walk[3] end, function(self) ai.walk(self, 1) end)
army_walk[3] = animation.frame(f.prowl_3, function() return army_walk[4] end, function(self) ai.walk(self, 1) end)
army_walk[4] = animation.frame(f.prowl_4, function() return army_walk[5] end, function(self) ai.walk(self, 1) end)
army_walk[5] = animation.frame(f.prowl_5, function() return army_walk[6] end, function(self) ai.walk(self, 2) end)
army_walk[6] = animation.frame(f.prowl_6, function() return army_walk[7] end, function(self) ai.walk(self, 3) end)
army_walk[7] = animation.frame(f.prowl_7, function() return army_walk[8] end, function(self) ai.walk(self, 4) end)
army_walk[8] = animation.frame(f.prowl_8, function() return army_walk[9] end, function(self) ai.walk(self, 4) end)
army_walk[9] = animation.frame(f.prowl_9, function() return army_walk[10] end, function(self) ai.walk(self, 2) end)
army_walk[10] = animation.frame(f.prowl_10, function() return army_walk[11] end, function(self) ai.walk(self, 2) end)
army_walk[11] = animation.frame(f.prowl_11, function() return army_walk[12] end, function(self) ai.walk(self, 2) end)
army_walk[12] = animation.frame(f.prowl_12, function() return army_walk[13] end, function(self) ai.walk(self, 1) end)
army_walk[13] = animation.frame(f.prowl_13, function() return army_walk[14] end, function(self) ai.walk(self, 0) end)
army_walk[14] = animation.frame(f.prowl_14, function() return army_walk[15] end, function(self) ai.walk(self, 1) end)
army_walk[15] = animation.frame(f.prowl_15, function() return army_walk[16] end, function(self) ai.walk(self, 1) end)
army_walk[16] = animation.frame(f.prowl_16, function() return army_walk[17] end, function(self) ai.walk(self, 1) end)
army_walk[17] = animation.frame(f.prowl_17, function() return army_walk[18] end, function(self) ai.walk(self, 3) end)
army_walk[18] = animation.frame(f.prowl_18, function() return army_walk[19] end, function(self) ai.walk(self, 3) end)
army_walk[19] = animation.frame(f.prowl_19, function() return army_walk[20] end, function(self) ai.walk(self, 3) end)
army_walk[20] = animation.frame(f.prowl_20, function() return army_walk[21] end, function(self) ai.walk(self, 3) end)
army_walk[21] = animation.frame(f.prowl_21, function() return army_walk[22] end, function(self) ai.walk(self, 2) end)
army_walk[22] = animation.frame(f.prowl_22, function() return army_walk[23] end, function(self) ai.walk(self, 1) end)
army_walk[23] = animation.frame(f.prowl_23, function() return army_walk[24] end, function(self) ai.walk(self, 1) end)
army_walk[24] = animation.frame(f.prowl_24, function() return army_walk[1] end, function(self) ai.walk(self, 1) end)

local army_run = {}
army_run[1] = animation.frame(f.run1, function() return army_run[2] end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "soldier/idle.wav", 1, C.ATTN_IDLE) end; ai.run(self, 11) end)
army_run[2] = animation.frame(f.run2, function() return army_run[3] end, function(self) ai.run(self, 15) end)
army_run[3] = animation.frame(f.run3, function() return army_run[4] end, function(self) ai.run(self, 10) end)
army_run[4] = animation.frame(f.run4, function() return army_run[5] end, function(self) ai.run(self, 10) end)
army_run[5] = animation.frame(f.run5, function() return army_run[6] end, function(self) ai.run(self, 8) end)
army_run[6] = animation.frame(f.run6, function() return army_run[7] end, function(self) ai.run(self, 15) end)
army_run[7] = animation.frame(f.run7, function() return army_run[8] end, function(self) ai.run(self, 10) end)
army_run[8] = animation.frame(f.run8, function() return army_run[1] end, function(self) ai.run(self, 8) end)

local army_atk = {}
army_atk[1] = animation.frame(f.shoot1, function() return army_atk[2] end, function(self) fight.face(self) end)
army_atk[2] = animation.frame(f.shoot2, function() return army_atk[3] end, function(self) fight.face(self) end)
army_atk[3] = animation.frame(f.shoot3, function() return army_atk[4] end, function(self) fight.face(self) end)
army_atk[4] = animation.frame(f.shoot4, function() return army_atk[5] end, function(self) fight.face(self) end)
army_atk[5] = animation.frame(f.shoot5, function() return army_atk[6] end, function(self) fight.face(self); army_fire(self); self.effects = self.effects | C.EF_MUZZLEFLASH end)
army_atk[6] = animation.frame(f.shoot6, function() return army_atk[7] end, function(self) fight.face(self) end)
army_atk[7] = animation.frame(f.shoot7, function() return army_atk[8] end, function(self) fight.face(self); subs.check_refire(self, army_atk[1]) end)
army_atk[8] = animation.frame(f.shoot8, function() return army_atk[9] end, function(self) fight.face(self) end)
army_atk[9] = animation.frame(f.shoot9, function() return army_run[1] end, function(self) fight.face(self) end)

local army_pain = {}
army_pain[1] = animation.frame(f.pain1, function() return army_pain[2] end)
army_pain[2] = animation.frame(f.pain2, function() return army_pain[3] end)
army_pain[3] = animation.frame(f.pain3, function() return army_pain[4] end)
army_pain[4] = animation.frame(f.pain4, function() return army_pain[5] end)
army_pain[5] = animation.frame(f.pain5, function() return army_pain[6] end)
army_pain[6] = animation.frame(f.pain6, function() return army_run[1] end, function(self) ai.pain(self, 1) end)

local army_painb = {}
army_painb[1] = animation.frame(f.painb1, function() return army_painb[2] end)
army_painb[2] = animation.frame(f.painb2, function() return army_painb[3] end, function(self) ai.pain_forward(self, 13) end)
army_painb[3] = animation.frame(f.painb3, function() return army_painb[4] end, function(self) ai.pain_forward(self, 9) end)
army_painb[4] = animation.frame(f.painb4, function() return army_painb[5] end)
army_painb[5] = animation.frame(f.painb5, function() return army_painb[6] end)
army_painb[6] = animation.frame(f.painb6, function() return army_painb[7] end)
army_painb[7] = animation.frame(f.painb7, function() return army_painb[8] end)
army_painb[8] = animation.frame(f.painb8, function() return army_painb[9] end)
army_painb[9] = animation.frame(f.painb9, function() return army_painb[10] end)
army_painb[10] = animation.frame(f.painb10, function() return army_painb[11] end)
army_painb[11] = animation.frame(f.painb11, function() return army_painb[12] end)
army_painb[12] = animation.frame(f.painb12, function() return army_painb[13] end, function(self) ai.pain(self, 2) end)
army_painb[13] = animation.frame(f.painb13, function() return army_painb[14] end)
army_painb[14] = animation.frame(f.painb14, function() return army_run[1] end)

local army_painc = {}
army_painc[1] = animation.frame(f.painc1, function() return army_painc[2] end)
army_painc[2] = animation.frame(f.painc2, function() return army_painc[3] end, function(self) ai.pain(self, 1) end)
army_painc[3] = animation.frame(f.painc3, function() return army_painc[4] end)
army_painc[4] = animation.frame(f.painc4, function() return army_painc[5] end)
army_painc[5] = animation.frame(f.painc5, function() return army_painc[6] end, function(self) ai.pain_forward(self, 1) end)
army_painc[6] = animation.frame(f.painc6, function() return army_painc[7] end, function(self) ai.pain_forward(self, 1) end)
army_painc[7] = animation.frame(f.painc7, function() return army_painc[8] end)
army_painc[8] = animation.frame(f.painc8, function() return army_painc[9] end, function(self) ai.pain(self, 1) end)
army_painc[9] = animation.frame(f.painc9, function() return army_painc[10] end, function(self) ai.pain_forward(self, 4) end)
army_painc[10] = animation.frame(f.painc10, function() return army_painc[11] end, function(self) ai.pain_forward(self, 3) end)
army_painc[11] = animation.frame(f.painc11, function() return army_painc[12] end, function(self) ai.pain_forward(self, 6) end)
army_painc[12] = animation.frame(f.painc12, function() return army_painc[13] end, function(self) ai.pain_forward(self, 8) end)
army_painc[13] = animation.frame(f.painc13, function() return army_run[1] end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
local function army_pain_handler(self, _attacker, _damage)
    if self.pain_finished > quake.time() then return end
    local r = quake.random()
    if r < 0.2 then
        self.pain_finished = quake.time() + 0.6
        army_pain[1](self)
        quake.sound(self, C.CHAN_VOICE, "soldier/pain1.wav", 1, C.ATTN_NORM)
    elseif r < 0.6 then
        self.pain_finished = quake.time() + 1.1
        army_painb[1](self)
        quake.sound(self, C.CHAN_VOICE, "soldier/pain2.wav", 1, C.ATTN_NORM)
    else
        self.pain_finished = quake.time() + 1.1
        army_painc[1](self)
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

local army_die = {}
army_die[1] = animation.frame(f.death1, function() return army_die[2] end)
army_die[2] = animation.frame(f.death2, function() return army_die[3] end)
army_die[3] = animation.frame(f.death3, function() return army_die[4] end, function(self) self.solid = C.SOLID_NOT; self.ammo_shells = 5; items.drop_backpack(self) end)
army_die[4] = animation.frame(f.death4, function() return army_die[5] end)
army_die[5] = animation.frame(f.death5, function() return army_die[6] end)
army_die[6] = animation.frame(f.death6, function() return army_die[7] end)
army_die[7] = animation.frame(f.death7, function() return army_die[8] end)
army_die[8] = animation.frame(f.death8, function() return army_die[9] end)
army_die[9] = animation.frame(f.death9, function() return army_die[10] end)
army_die[10] = animation.frame(f.death10, function() return army_die[10] end)

local army_cdie = {}
army_cdie[1] = animation.frame(f.deathc1, function() return army_cdie[2] end)
army_cdie[2] = animation.frame(f.deathc2, function() return army_cdie[3] end, function(self) ai.back(self, 5) end)
army_cdie[3] = animation.frame(f.deathc3, function() return army_cdie[4] end, function(self) self.solid = C.SOLID_NOT; self.ammo_shells = 5; items.drop_backpack(self); ai.back(self, 4) end)
army_cdie[4] = animation.frame(f.deathc4, function() return army_cdie[5] end, function(self) ai.back(self, 13) end)
army_cdie[5] = animation.frame(f.deathc5, function() return army_cdie[6] end, function(self) ai.back(self, 3) end)
army_cdie[6] = animation.frame(f.deathc6, function() return army_cdie[7] end, function(self) ai.back(self, 4) end)
army_cdie[7] = animation.frame(f.deathc7, function() return army_cdie[8] end)
army_cdie[8] = animation.frame(f.deathc8, function() return army_cdie[9] end)
army_cdie[9] = animation.frame(f.deathc9, function() return army_cdie[10] end)
army_cdie[10] = animation.frame(f.deathc10, function() return army_cdie[11] end)
army_cdie[11] = animation.frame(f.deathc11, function() return army_cdie[11] end)

---@param self entity
---@return nil
local function army_die_handler(self)
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
    if quake.random() < 0.5 then army_die[1](self) else army_cdie[1](self) end
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
    self.th_stand = army_stand[1]
    self.th_walk = army_walk[1]
    self.th_run = army_run[1]
    self.th_missile = army_atk[1]
    self.th_pain = army_pain_handler
    self.th_die = army_die_handler
    monsters.walk_start(self)
end

quake.register_entity("monster_army", M.spawn)

return M
