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
-- Port of demon.qc from GPL-licensed CleanFixedQuakeC.
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
local weapons = require("game.weapons")

local M = {}

--[[
==============================================================================

DEMON (Fiend)

==============================================================================
]]

local demon_jump_touch, demon_melee

local demon1_stand1, demon1_stand2, demon1_stand3, demon1_stand4, demon1_stand5, demon1_stand6, demon1_stand7, demon1_stand8, demon1_stand9, demon1_stand10, demon1_stand11, demon1_stand12, demon1_stand13

demon1_stand1 = animation.frame("stand1", function() return demon1_stand2 end, ai.stand)
demon1_stand2 = animation.frame("stand2", function() return demon1_stand3 end, ai.stand)
demon1_stand3 = animation.frame("stand3", function() return demon1_stand4 end, ai.stand)
demon1_stand4 = animation.frame("stand4", function() return demon1_stand5 end, ai.stand)
demon1_stand5 = animation.frame("stand5", function() return demon1_stand6 end, ai.stand)
demon1_stand6 = animation.frame("stand6", function() return demon1_stand7 end, ai.stand)
demon1_stand7 = animation.frame("stand7", function() return demon1_stand8 end, ai.stand)
demon1_stand8 = animation.frame("stand8", function() return demon1_stand9 end, ai.stand)
demon1_stand9 = animation.frame("stand9", function() return demon1_stand10 end, ai.stand)
demon1_stand10 = animation.frame("stand10", function() return demon1_stand11 end, ai.stand)
demon1_stand11 = animation.frame("stand11", function() return demon1_stand12 end, ai.stand)
demon1_stand12 = animation.frame("stand12", function() return demon1_stand13 end, ai.stand)
demon1_stand13 = animation.frame("stand13", function() return demon1_stand1 end, ai.stand)

local demon1_walk1, demon1_walk2, demon1_walk3, demon1_walk4, demon1_walk5, demon1_walk6, demon1_walk7, demon1_walk8

demon1_walk1 = animation.frame("walk1", function() return demon1_walk2 end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "demon/idle1.wav", 1, C.ATTN_IDLE) end; ai.walk(self, 8) end)
demon1_walk2 = animation.frame("walk2", function() return demon1_walk3 end, function(self) ai.walk(self, 6) end)
demon1_walk3 = animation.frame("walk3", function() return demon1_walk4 end, function(self) ai.walk(self, 6) end)
demon1_walk4 = animation.frame("walk4", function() return demon1_walk5 end, function(self) ai.walk(self, 7) end)
demon1_walk5 = animation.frame("walk5", function() return demon1_walk6 end, function(self) ai.walk(self, 4) end)
demon1_walk6 = animation.frame("walk6", function() return demon1_walk7 end, function(self) ai.walk(self, 6) end)
demon1_walk7 = animation.frame("walk7", function() return demon1_walk8 end, function(self) ai.walk(self, 10) end)
demon1_walk8 = animation.frame("walk8", function() return demon1_walk1 end, function(self) ai.walk(self, 10) end)

local demon1_run1, demon1_run2, demon1_run3, demon1_run4, demon1_run5, demon1_run6

demon1_run1 = animation.frame("run1", function() return demon1_run2 end, function(self) if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "demon/idle1.wav", 1, C.ATTN_IDLE) end; ai.run(self, 20) end)
demon1_run2 = animation.frame("run2", function() return demon1_run3 end, function(self) ai.run(self, 15) end)
demon1_run3 = animation.frame("run3", function() return demon1_run4 end, function(self) ai.run(self, 36) end)
demon1_run4 = animation.frame("run4", function() return demon1_run5 end, function(self) ai.run(self, 20) end)
demon1_run5 = animation.frame("run5", function() return demon1_run6 end, function(self) ai.run(self, 15) end)
demon1_run6 = animation.frame("run6", function() return demon1_run1 end, function(self) ai.run(self, 36) end)

local demon1_jump1, demon1_jump2, demon1_jump3, demon1_jump4, demon1_jump5, demon1_jump6, demon1_jump7, demon1_jump8, demon1_jump9, demon1_jump10, demon1_jump11, demon1_jump12

demon1_jump1 = animation.frame("leap1", function() return demon1_jump2 end, fight.face)
demon1_jump2 = animation.frame("leap2", function() return demon1_jump3 end, fight.face)
demon1_jump3 = animation.frame("leap3", function() return demon1_jump4 end, fight.face)
demon1_jump4 = animation.frame("leap4", function() return demon1_jump5 end, function(self) fight.face(self); self.touch = demon_jump_touch; local vectors = quake.make_vectors(self.angles); self.origin = self.origin + quake.vec3(0, 0, 1); self.velocity = vectors.forward * 600 + quake.vec3(0, 0, 250); if (self.flags & C.FL_ONGROUND) ~= 0 then self.flags = self.flags - C.FL_ONGROUND end end)
demon1_jump5 = animation.frame("leap5", function() return demon1_jump6 end)
demon1_jump6 = animation.frame("leap6", function() return demon1_jump7 end)
demon1_jump7 = animation.frame("leap7", function() return demon1_jump8 end)
demon1_jump8 = animation.frame("leap8", function() return demon1_jump9 end)
demon1_jump9 = animation.frame("leap9", function() return demon1_jump10 end)
demon1_jump10 = animation.frame("leap10", function() return demon1_jump1 end, function(self)
    self.nextthink = quake.time() + 3
    -- if three seconds pass, assume demon is stuck and jump again
end)
demon1_jump11 = animation.frame("leap11", function() return demon1_jump12 end)
demon1_jump12 = animation.frame("leap12", function() return demon1_run1 end)

local demon1_atta1, demon1_atta2, demon1_atta3, demon1_atta4, demon1_atta5, demon1_atta6, demon1_atta7, demon1_atta8, demon1_atta9, demon1_atta10, demon1_atta11, demon1_atta12, demon1_atta13, demon1_atta14, demon1_atta15

demon1_atta1 = animation.frame("attacka1", function() return demon1_atta2 end, function(self) fight.charge(self, 4) end)
demon1_atta2 = animation.frame("attacka2", function() return demon1_atta3 end, function(self) fight.charge(self, 0) end)
demon1_atta3 = animation.frame("attacka3", function() return demon1_atta4 end, function(self) fight.charge(self, 0) end)
demon1_atta4 = animation.frame("attacka4", function() return demon1_atta5 end, function(self) fight.charge(self, 1) end)
demon1_atta5 = animation.frame("attacka5", function() return demon1_atta6 end, function(self) fight.charge(self, 2); demon_melee(self, 200) end)
demon1_atta6 = animation.frame("attacka6", function() return demon1_atta7 end, function(self) fight.charge(self, 1) end)
demon1_atta7 = animation.frame("attacka7", function() return demon1_atta8 end, function(self) fight.charge(self, 6) end)
demon1_atta8 = animation.frame("attacka8", function() return demon1_atta9 end, function(self) fight.charge(self, 8) end)
demon1_atta9 = animation.frame("attacka9", function() return demon1_atta10 end, function(self) fight.charge(self, 4) end)
demon1_atta10 = animation.frame("attacka10", function() return demon1_atta11 end, function(self) fight.charge(self, 2) end)
demon1_atta11 = animation.frame("attacka11", function() return demon1_atta12 end, function(self) demon_melee(self, -200) end)
demon1_atta12 = animation.frame("attacka12", function() return demon1_atta13 end, function(self) fight.charge(self, 5) end)
demon1_atta13 = animation.frame("attacka13", function() return demon1_atta14 end, function(self) fight.charge(self, 8) end)
demon1_atta14 = animation.frame("attacka14", function() return demon1_atta15 end, function(self) fight.charge(self, 4) end)
demon1_atta15 = animation.frame("attacka15", function() return demon1_run1 end, function(self) fight.charge(self, 4) end)

local demon1_pain1, demon1_pain2, demon1_pain3, demon1_pain4, demon1_pain5, demon1_pain6

demon1_pain1 = animation.frame("pain1", function() return demon1_pain2 end)
demon1_pain2 = animation.frame("pain2", function() return demon1_pain3 end)
demon1_pain3 = animation.frame("pain3", function() return demon1_pain4 end)
demon1_pain4 = animation.frame("pain4", function() return demon1_pain5 end)
demon1_pain5 = animation.frame("pain5", function() return demon1_pain6 end)
demon1_pain6 = animation.frame("pain6", function() return demon1_run1 end)

local function demon1_pain(self, _attacker, damage)
    if self.touch == demon_jump_touch then return end
    if self.pain_finished > quake.time() then return end
    self.pain_finished = quake.time() + 1
    quake.sound(self, C.CHAN_VOICE, "demon/dpain1.wav", 1, C.ATTN_NORM)
    if quake.random() * 200 > damage then return end -- didn't flinch
    demon1_pain1(self)
end

local demon1_die1, demon1_die2, demon1_die3, demon1_die4, demon1_die5, demon1_die6, demon1_die7, demon1_die8, demon1_die9

demon1_die1 = animation.frame("death1", function() return demon1_die2 end, function(self) quake.sound(self, C.CHAN_VOICE, "demon/ddeath.wav", 1, C.ATTN_NORM) end)
demon1_die2 = animation.frame("death2", function() return demon1_die3 end)
demon1_die3 = animation.frame("death3", function() return demon1_die4 end)
demon1_die4 = animation.frame("death4", function() return demon1_die5 end)
demon1_die5 = animation.frame("death5", function() return demon1_die6 end)
demon1_die6 = animation.frame("death6", function() return demon1_die7 end, function(self) self.solid = C.SOLID_NOT end)
demon1_die7 = animation.frame("death7", function() return demon1_die8 end)
demon1_die8 = animation.frame("death8", function() return demon1_die9 end)
demon1_die9 = animation.frame("death9", function() return demon1_die9 end)

local function demon_die(self)
    -- check for gib
    if self.health < -80 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw_head(self, "progs/h_demon.mdl", self.health)
        gibs.throw(self, "progs/gib1.mdl", self.health)
        gibs.throw(self, "progs/gib1.mdl", self.health)
        gibs.throw(self, "progs/gib1.mdl", self.health)
        return
    end
    -- regular death
    demon1_die1(self)
end

local function demon_melee_attack(self) demon1_atta1(self) end

--[[QUAKED monster_demon1 (1 0 0) (-32 -32 -24) (32 32 64) Ambush
]]
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then quake.remove(self); return end
    quake.precache_model("progs/demon.mdl")
    quake.precache_model("progs/h_demon.mdl")
    quake.precache_sound("demon/ddeath.wav")
    quake.precache_sound("demon/dhit2.wav")
    quake.precache_sound("demon/djump.wav")
    quake.precache_sound("demon/dpain1.wav")
    quake.precache_sound("demon/idle1.wav")
    quake.precache_sound("demon/sight2.wav")
    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP
    quake.set_model(self, "progs/demon.mdl")
    quake.set_size(self, C.VEC_HULL2_MIN, C.VEC_HULL2_MAX)
    self.health = 300
    self.th_stand = demon1_stand1
    self.th_walk = demon1_walk1
    self.th_run = demon1_run1
    self.th_die = demon_die
    self.th_melee = demon_melee_attack -- one of two attacks
    self.th_missile = demon1_jump1 -- jump attack
    self.th_pain = demon1_pain
    self.check_attack = M.check_attack
    monsters.walk_start(self)
end

--[[
==============================================================================

DEMON

==============================================================================
]]

--[[
==============
CheckDemonMelee

Returns TRUE if a melee attack would hit right now
==============
]]
local function check_demon_melee(self)
    if quake.globals.enemy_range == C.RANGE_MELEE then
        -- FIXME: check canreach
        self.attack_state = C.AS_MELEE
        return true
    end
    return false
end

--[[
==============
CheckDemonJump

==============
]]
local function check_demon_jump(self)
    if self.origin.z + self.mins.z > self.enemy.origin.z + self.enemy.mins.z + 0.75 * self.enemy.size.z then return false end
    if self.origin.z + self.maxs.z < self.enemy.origin.z + self.enemy.mins.z + 0.25 * self.enemy.size.z then return false end
    local dist = self.enemy.origin - self.origin
    dist = quake.vec3(dist.x, dist.y, 0)
    local d = dist:length()
    if d < 100 then return false end
    if d > 200 and quake.random() < 0.9 then return false end
    return true
end

function M.check_attack(self)
    -- if close enough for slashing, go for it
    if check_demon_melee(self) then self.attack_state = C.AS_MELEE; return true end
    if check_demon_jump(self) then
        self.attack_state = C.AS_MISSILE
        quake.sound(self, C.CHAN_VOICE, "demon/djump.wav", 1, C.ATTN_NORM)
        return true
    end
    return false
end

--===========================================================================

function demon_melee(self, side)
    fight.face(self)
    quake.walk_move(self, self.ideal_yaw, 12) -- allow a little closing
    local delta = self.enemy.origin - self.origin
    if delta:length() > 100 then return end
    if not combat.can_damage(self.enemy, self) then return end
    quake.sound(self, C.CHAN_WEAPON, "demon/dhit2.wav", 1, C.ATTN_NORM)
    local ldmg = 10 + 5 * quake.random()
    combat.damage(self.enemy, self, self, ldmg)
    local vectors = quake.make_vectors(self.angles)
    weapons.spawn_meat_spray(self, self.origin + vectors.forward * 16, side * vectors.right)
end

function demon_jump_touch(self, other)
    if self.health <= 0 then return end
    if other.takedamage ~= 0 and self.velocity:length() > 400 then
        local ldmg = 40 + 10 * quake.random()
        combat.damage(other, self, self, ldmg)
    end
    if not quake.check_bottom(self) then
        if (self.flags & C.FL_ONGROUND) ~= 0 then
            -- jump randomly to not get hung up
            self.touch = subs.null
            self.think = demon1_jump1
            self.nextthink = quake.time() + 0.1
        end
        return -- not on ground yet
    end
    self.touch = subs.null
    self.think = demon1_jump11
    self.nextthink = quake.time() + 0.1
end

quake.register_entity("monster_demon1", M.spawn)

return M
