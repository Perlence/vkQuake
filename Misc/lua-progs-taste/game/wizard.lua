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
-- Port of wizard.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

local quake = require("quake")
local C = require("game.constants")
local ai = require("game.ai")
local animation = require("game.animation")
local fight = require("game.fight")
local gibs = require("game.gibs")
local monsters = require("game.monsters")
local subs = require("game.subs")
local weapons = require("game.weapons")

local M = {}

--[[
==============================================================================

WIZARD (Scrag)

==============================================================================
]]

--[[
==============================================================================

WIZARD

If the player moves behind cover before the missile is launched, launch it
at the last visible spot with no velocity leading, in hopes that the player
will duck back out and catch it.
==============================================================================
]]

---Sets the given entities velocity and angles so that it will hit self.enemy
---if self.enemy maintains it's current velocity
---0.1 is moderately accurate, 0.0 is totally accurate
---@param self entity
---@param missile entity
---@param mspeed number
---@param accuracy number
---@return nil
local function launch_missile(self, missile, mspeed, accuracy)
    local vectors = quake.make_vectors(self.angles)
    -- set missile speed
    local vec = self.enemy.origin + self.enemy.mins + self.enemy.size * 0.7 - missile.origin
    -- calc approximate time for missile to reach vec
    local fly = vec:length() / mspeed
    -- get the entities xy velocity
    local move = quake.vec3(self.enemy.velocity.x, self.enemy.velocity.y, 0)
    -- project the target forward in time
    vec = vec + move * fly
    vec = vec:normalized()
    vec = vec + accuracy * vectors.up * (quake.random() - 0.5) + accuracy * vectors.right * (quake.random() - 0.5)
    missile.velocity = vec * mspeed
    missile.angles = quake.vec3(0, quake.vector_to_yaw(missile.velocity), 0)
    -- set missile duration
    missile.nextthink = quake.time() + 5
    missile.think = subs.remove
end

local wiz_run1, wiz_side1

---@param self entity
---@return boolean
function M.check_attack(self)
    local enemy_range = quake.globals.enemy_range
    if quake.time() < self.attack_finished then return false end
    if not quake.globals.enemy_vis then return false end
    if enemy_range == C.RANGE_FAR then
        if self.attack_state ~= C.AS_STRAIGHT then self.attack_state = C.AS_STRAIGHT; wiz_run1(self) end
        return false
    end
    local targ = assert(self.enemy, "monster has no enemy")
    -- see if any entities are in the way of the shot
    local spot1 = self.origin + self.view_ofs
    local spot2 = targ.origin + targ.view_ofs
    local trace = quake.trace_line(spot1, spot2, false, self)
    if trace.entity ~= targ then
        -- don't have a clear shot, so move to a side
        if self.attack_state ~= C.AS_STRAIGHT then self.attack_state = C.AS_STRAIGHT; wiz_run1(self) end
        return false
    end
    local chance
    if enemy_range == C.RANGE_MELEE then chance = 0.9
    elseif enemy_range == C.RANGE_NEAR then chance = 0.6
    elseif enemy_range == C.RANGE_MID then chance = 0.2
    else chance = 0 end
    if quake.random() < chance then self.attack_state = C.AS_MISSILE; return true end
    if enemy_range == C.RANGE_MID then
        if self.attack_state ~= C.AS_STRAIGHT then self.attack_state = C.AS_STRAIGHT; wiz_run1(self) end
    else
        if self.attack_state ~= C.AS_SLIDING then self.attack_state = C.AS_SLIDING; wiz_side1(self) end
    end
    return false
end

---@param self entity
---@return nil
local function wizard_attack_finished(self)
    if quake.globals.enemy_range >= C.RANGE_MID or not quake.globals.enemy_vis then
        self.attack_state = C.AS_STRAIGHT
        self.think = wiz_run1
    else
        self.attack_state = C.AS_SLIDING
        self.think = wiz_side1
    end
end

--[[
==============================================================================

FAST ATTACKS

==============================================================================
]]

---@param self entity
---@return nil
local function wiz_fast_fire(self)
    if self.owner.health > 0 then
        self.owner.effects = self.owner.effects | C.EF_MUZZLEFLASH
        quake.make_vectors(self.enemy.angles)
        local dst = self.enemy.origin - 13 * self.movedir
        local vec = (dst - self.origin):normalized()
        quake.sound(self, C.CHAN_WEAPON, "wizard/wattack.wav", 1, C.ATTN_NORM)
        local newmis = weapons.launch_spike(self, self.origin, vec)
        newmis.velocity = vec * 600
        newmis.owner = self.owner
        newmis.classname = "wizspike"
        quake.set_model(newmis, "progs/w_spike.mdl")
        quake.set_size(newmis, C.VEC_ORIGIN, C.VEC_ORIGIN)
    end
    quake.remove(self)
end

---@param self entity
---@return nil
local function wiz_start_fast(self)
    quake.sound(self, C.CHAN_WEAPON, "wizard/wattack.wav", 1, C.ATTN_NORM)
    self.v_angle = self.angles
    local vectors = quake.make_vectors(self.angles)
    local missile = quake.spawn()
    missile.owner = self
    missile.nextthink = quake.time() + 0.6
    quake.set_size(missile, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    quake.set_origin(missile, self.origin + quake.vec3(0, 0, 30) + vectors.forward * 14 + vectors.right * 14)
    missile.enemy = self.enemy
    missile.nextthink = quake.time() + 0.8
    missile.think = wiz_fast_fire
    missile.movedir = vectors.right
    missile = quake.spawn()
    missile.owner = self
    missile.nextthink = quake.time() + 1
    quake.set_size(missile, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    quake.set_origin(missile, self.origin + quake.vec3(0, 0, 30) + vectors.forward * 14 + vectors.right * -14)
    missile.enemy = self.enemy
    missile.nextthink = quake.time() + 0.3
    missile.think = wiz_fast_fire
    missile.movedir = C.VEC_ORIGIN - vectors.right
end

---@param self entity
---@return nil
local function wiz_idle_sound(self)
    local wr = quake.random() * 5
    if self.waitmin < quake.time() then
        self.waitmin = quake.time() + 2
        if wr > 4.5 then quake.sound(self, C.CHAN_VOICE, "wizard/widle1.wav", 1, C.ATTN_IDLE) end
        if wr < 1.5 then quake.sound(self, C.CHAN_VOICE, "wizard/widle2.wav", 1, C.ATTN_IDLE) end
    end
    return
end

local wiz_stand1, wiz_stand2, wiz_stand3, wiz_stand4, wiz_stand5, wiz_stand6, wiz_stand7, wiz_stand8

wiz_stand1 = animation.frame("hover1", function() return wiz_stand2 end, ai.stand)
wiz_stand2 = animation.frame("hover2", function() return wiz_stand3 end, ai.stand)
wiz_stand3 = animation.frame("hover3", function() return wiz_stand4 end, ai.stand)
wiz_stand4 = animation.frame("hover4", function() return wiz_stand5 end, ai.stand)
wiz_stand5 = animation.frame("hover5", function() return wiz_stand6 end, ai.stand)
wiz_stand6 = animation.frame("hover6", function() return wiz_stand7 end, ai.stand)
wiz_stand7 = animation.frame("hover7", function() return wiz_stand8 end, ai.stand)
wiz_stand8 = animation.frame("hover8", function() return wiz_stand1 end, ai.stand)

local wiz_walk1, wiz_walk2, wiz_walk3, wiz_walk4, wiz_walk5, wiz_walk6, wiz_walk7, wiz_walk8

wiz_walk1 = animation.frame("hover1", function() return wiz_walk2 end, function(self) ai.walk(self, 8); wiz_idle_sound(self) end)
wiz_walk2 = animation.frame("hover2", function() return wiz_walk3 end, function(self) ai.walk(self, 8) end)
wiz_walk3 = animation.frame("hover3", function() return wiz_walk4 end, function(self) ai.walk(self, 8) end)
wiz_walk4 = animation.frame("hover4", function() return wiz_walk5 end, function(self) ai.walk(self, 8) end)
wiz_walk5 = animation.frame("hover5", function() return wiz_walk6 end, function(self) ai.walk(self, 8) end)
wiz_walk6 = animation.frame("hover6", function() return wiz_walk7 end, function(self) ai.walk(self, 8) end)
wiz_walk7 = animation.frame("hover7", function() return wiz_walk8 end, function(self) ai.walk(self, 8) end)
wiz_walk8 = animation.frame("hover8", function() return wiz_walk1 end, function(self) ai.walk(self, 8) end)

local wiz_side2, wiz_side3, wiz_side4, wiz_side5, wiz_side6, wiz_side7, wiz_side8

wiz_side1 = animation.frame("hover1", function() return wiz_side2 end, function(self) ai.run(self, 8); wiz_idle_sound(self) end)
wiz_side2 = animation.frame("hover2", function() return wiz_side3 end, function(self) ai.run(self, 8) end)
wiz_side3 = animation.frame("hover3", function() return wiz_side4 end, function(self) ai.run(self, 8) end)
wiz_side4 = animation.frame("hover4", function() return wiz_side5 end, function(self) ai.run(self, 8) end)
wiz_side5 = animation.frame("hover5", function() return wiz_side6 end, function(self) ai.run(self, 8) end)
wiz_side6 = animation.frame("hover6", function() return wiz_side7 end, function(self) ai.run(self, 8) end)
wiz_side7 = animation.frame("hover7", function() return wiz_side8 end, function(self) ai.run(self, 8) end)
wiz_side8 = animation.frame("hover8", function() return wiz_side1 end, function(self) ai.run(self, 8) end)

local wiz_run2, wiz_run3, wiz_run4, wiz_run5, wiz_run6, wiz_run7, wiz_run8, wiz_run9, wiz_run10, wiz_run11, wiz_run12, wiz_run13, wiz_run14

wiz_run1 = animation.frame("fly1", function() return wiz_run2 end, function(self) ai.run(self, 16); wiz_idle_sound(self) end)
wiz_run2 = animation.frame("fly2", function() return wiz_run3 end, function(self) ai.run(self, 16) end)
wiz_run3 = animation.frame("fly3", function() return wiz_run4 end, function(self) ai.run(self, 16) end)
wiz_run4 = animation.frame("fly4", function() return wiz_run5 end, function(self) ai.run(self, 16) end)
wiz_run5 = animation.frame("fly5", function() return wiz_run6 end, function(self) ai.run(self, 16) end)
wiz_run6 = animation.frame("fly6", function() return wiz_run7 end, function(self) ai.run(self, 16) end)
wiz_run7 = animation.frame("fly7", function() return wiz_run8 end, function(self) ai.run(self, 16) end)
wiz_run8 = animation.frame("fly8", function() return wiz_run9 end, function(self) ai.run(self, 16) end)
wiz_run9 = animation.frame("fly9", function() return wiz_run10 end, function(self) ai.run(self, 16) end)
wiz_run10 = animation.frame("fly10", function() return wiz_run11 end, function(self) ai.run(self, 16) end)
wiz_run11 = animation.frame("fly11", function() return wiz_run12 end, function(self) ai.run(self, 16) end)
wiz_run12 = animation.frame("fly12", function() return wiz_run13 end, function(self) ai.run(self, 16) end)
wiz_run13 = animation.frame("fly13", function() return wiz_run14 end, function(self) ai.run(self, 16) end)
wiz_run14 = animation.frame("fly14", function() return wiz_run1 end, function(self) ai.run(self, 16) end)

local wiz_fast1, wiz_fast2, wiz_fast3, wiz_fast4, wiz_fast5, wiz_fast6, wiz_fast7, wiz_fast8, wiz_fast9, wiz_fast10

wiz_fast1 = animation.frame("magatt1", function() return wiz_fast2 end, function(self) fight.face(self); wiz_start_fast(self) end)
wiz_fast2 = animation.frame("magatt2", function() return wiz_fast3 end, function(self) fight.face(self) end)
wiz_fast3 = animation.frame("magatt3", function() return wiz_fast4 end, function(self) fight.face(self) end)
wiz_fast4 = animation.frame("magatt4", function() return wiz_fast5 end, function(self) fight.face(self) end)
wiz_fast5 = animation.frame("magatt5", function() return wiz_fast6 end, function(self) fight.face(self) end)
wiz_fast6 = animation.frame("magatt6", function() return wiz_fast7 end, function(self) fight.face(self) end)
wiz_fast7 = animation.frame("magatt5", function() return wiz_fast8 end, function(self) fight.face(self) end)
wiz_fast8 = animation.frame("magatt4", function() return wiz_fast9 end, function(self) fight.face(self) end)
wiz_fast9 = animation.frame("magatt3", function() return wiz_fast10 end, function(self) fight.face(self) end)
wiz_fast10 = animation.frame("magatt2", function() return wiz_run1 end, function(self) fight.face(self); subs.attack_finished(self, 2); wizard_attack_finished(self) end)

local wiz_pain1, wiz_pain2, wiz_pain3, wiz_pain4

wiz_pain1 = animation.frame("pain1", function() return wiz_pain2 end)
wiz_pain2 = animation.frame("pain2", function() return wiz_pain3 end)
wiz_pain3 = animation.frame("pain3", function() return wiz_pain4 end)
wiz_pain4 = animation.frame("pain4", function() return wiz_run1 end)

local wiz_death1, wiz_death2, wiz_death3, wiz_death4, wiz_death5, wiz_death6, wiz_death7, wiz_death8

wiz_death1 = animation.frame("death1", function() return wiz_death2 end, function(self) self.velocity = quake.vec3(-200 + 400 * quake.random(), -200 + 400 * quake.random(), 100 + 100 * quake.random()); self.flags = self.flags - (self.flags & C.FL_ONGROUND); quake.sound(self, C.CHAN_VOICE, "wizard/wdeath.wav", 1, C.ATTN_NORM) end)
wiz_death2 = animation.frame("death2", function() return wiz_death3 end)
wiz_death3 = animation.frame("death3", function() return wiz_death4 end, function(self) self.solid = C.SOLID_NOT end)
wiz_death4 = animation.frame("death4", function() return wiz_death5 end)
wiz_death5 = animation.frame("death5", function() return wiz_death6 end)
wiz_death6 = animation.frame("death6", function() return wiz_death7 end)
wiz_death7 = animation.frame("death7", function() return wiz_death8 end)
wiz_death8 = animation.frame("death8", function() return wiz_death8 end)

---@param self entity
---@return nil
local function wiz_die(self)
    -- check for gib
    if self.health < -40 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw_head(self, "progs/h_wizard.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        return
    end
    wiz_death1(self)
end

---@param self entity
---@param _attacker entity
---@param damage number
---@return nil
local function wiz_pain_callback(self, _attacker, damage)
    quake.sound(self, C.CHAN_VOICE, "wizard/wpain.wav", 1, C.ATTN_NORM)
    if quake.random() * 70 > damage then return end -- didn't flinch
    wiz_pain1(self)
end

---@param self entity
---@return nil
local function wiz_missile(self) wiz_fast1(self) end

---QUAKED monster_wizard (1 0 0) (-16 -16 -24) (16 16 40) Ambush
---@param self entity
---@return nil
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then quake.remove(self); return end
    quake.precache_model("progs/wizard.mdl")
    quake.precache_model("progs/h_wizard.mdl")
    quake.precache_model("progs/w_spike.mdl")
    -- used by c code
    quake.precache_sound("wizard/hit.wav")
    quake.precache_sound("wizard/wattack.wav")
    quake.precache_sound("wizard/wdeath.wav")
    quake.precache_sound("wizard/widle1.wav")
    quake.precache_sound("wizard/widle2.wav")
    quake.precache_sound("wizard/wpain.wav")
    quake.precache_sound("wizard/wsight.wav")
    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP
    quake.set_model(self, "progs/wizard.mdl")
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 40))
    self.health = 80
    self.th_stand = wiz_stand1
    self.th_walk = wiz_walk1
    self.th_run = wiz_run1
    self.th_missile = wiz_missile
    self.th_pain = wiz_pain_callback
    self.th_die = wiz_die
    self.check_attack = M.check_attack
    monsters.fly_start(self)
end

quake.register_entity("monster_wizard", M.spawn)

return M
