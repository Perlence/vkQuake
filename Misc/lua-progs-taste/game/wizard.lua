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

local count = animation.counter()
local f = {}

f.hover1, f.hover2, f.hover3, f.hover4, f.hover5, f.hover6,
    f.hover7, f.hover8, f.hover9, f.hover10, f.hover11, f.hover12,
    f.hover13, f.hover14, f.hover15 = count(15)

f.fly1, f.fly2, f.fly3, f.fly4, f.fly5, f.fly6,
    f.fly7, f.fly8, f.fly9, f.fly10, f.fly11, f.fly12,
    f.fly13, f.fly14 = count(14)

f.magatt1, f.magatt2, f.magatt3, f.magatt4, f.magatt5, f.magatt6,
    f.magatt7, f.magatt8, f.magatt9, f.magatt10, f.magatt11, f.magatt12,
    f.magatt13 = count(13)

f.pain1, f.pain2, f.pain3, f.pain4 = count(4)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
    f.death7, f.death8 = count(8)

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

local wiz_run = {}
local wiz_side = {}

---@param self entity
---@return boolean
function M.check_attack(self)
    local enemy_range = quake.globals.enemy_range
    if quake.time() < self.attack_finished then return false end
    if not quake.globals.enemy_vis then return false end
    if enemy_range == C.RANGE_FAR then
        if self.attack_state ~= C.AS_STRAIGHT then self.attack_state = C.AS_STRAIGHT; wiz_run[1](self) end
        return false
    end
    local targ = assert(self.enemy, "monster has no enemy")
    -- see if any entities are in the way of the shot
    local spot1 = self.origin + self.view_ofs
    local spot2 = targ.origin + targ.view_ofs
    local trace = quake.trace_line(spot1, spot2, false, self)
    if trace.entity ~= targ then
        -- don't have a clear shot, so move to a side
        if self.attack_state ~= C.AS_STRAIGHT then self.attack_state = C.AS_STRAIGHT; wiz_run[1](self) end
        return false
    end
    local chance
    if enemy_range == C.RANGE_MELEE then chance = 0.9
    elseif enemy_range == C.RANGE_NEAR then chance = 0.6
    elseif enemy_range == C.RANGE_MID then chance = 0.2
    else chance = 0 end
    if quake.random() < chance then self.attack_state = C.AS_MISSILE; return true end
    if enemy_range == C.RANGE_MID then
        if self.attack_state ~= C.AS_STRAIGHT then self.attack_state = C.AS_STRAIGHT; wiz_run[1](self) end
    else
        if self.attack_state ~= C.AS_SLIDING then self.attack_state = C.AS_SLIDING; wiz_side[1](self) end
    end
    return false
end

---@param self entity
---@return nil
local function wizard_attack_finished(self)
    if quake.globals.enemy_range >= C.RANGE_MID or not quake.globals.enemy_vis then
        self.attack_state = C.AS_STRAIGHT
        self.think = wiz_run[1]
    else
        self.attack_state = C.AS_SLIDING
        self.think = wiz_side[1]
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

local wiz_stand = {}
wiz_stand[1] = animation.frame(f.hover1, function() return wiz_stand[2] end, ai.stand)
wiz_stand[2] = animation.frame(f.hover2, function() return wiz_stand[3] end, ai.stand)
wiz_stand[3] = animation.frame(f.hover3, function() return wiz_stand[4] end, ai.stand)
wiz_stand[4] = animation.frame(f.hover4, function() return wiz_stand[5] end, ai.stand)
wiz_stand[5] = animation.frame(f.hover5, function() return wiz_stand[6] end, ai.stand)
wiz_stand[6] = animation.frame(f.hover6, function() return wiz_stand[7] end, ai.stand)
wiz_stand[7] = animation.frame(f.hover7, function() return wiz_stand[8] end, ai.stand)
wiz_stand[8] = animation.frame(f.hover8, function() return wiz_stand[1] end, ai.stand)

local wiz_walk = {}
wiz_walk[1] = animation.frame(f.hover1, function() return wiz_walk[2] end, function(self) ai.walk(self, 8); wiz_idle_sound(self) end)
wiz_walk[2] = animation.frame(f.hover2, function() return wiz_walk[3] end, function(self) ai.walk(self, 8) end)
wiz_walk[3] = animation.frame(f.hover3, function() return wiz_walk[4] end, function(self) ai.walk(self, 8) end)
wiz_walk[4] = animation.frame(f.hover4, function() return wiz_walk[5] end, function(self) ai.walk(self, 8) end)
wiz_walk[5] = animation.frame(f.hover5, function() return wiz_walk[6] end, function(self) ai.walk(self, 8) end)
wiz_walk[6] = animation.frame(f.hover6, function() return wiz_walk[7] end, function(self) ai.walk(self, 8) end)
wiz_walk[7] = animation.frame(f.hover7, function() return wiz_walk[8] end, function(self) ai.walk(self, 8) end)
wiz_walk[8] = animation.frame(f.hover8, function() return wiz_walk[1] end, function(self) ai.walk(self, 8) end)

wiz_side[1] = animation.frame(f.hover1, function() return wiz_side[2] end, function(self) ai.run(self, 8); wiz_idle_sound(self) end)
wiz_side[2] = animation.frame(f.hover2, function() return wiz_side[3] end, function(self) ai.run(self, 8) end)
wiz_side[3] = animation.frame(f.hover3, function() return wiz_side[4] end, function(self) ai.run(self, 8) end)
wiz_side[4] = animation.frame(f.hover4, function() return wiz_side[5] end, function(self) ai.run(self, 8) end)
wiz_side[5] = animation.frame(f.hover5, function() return wiz_side[6] end, function(self) ai.run(self, 8) end)
wiz_side[6] = animation.frame(f.hover6, function() return wiz_side[7] end, function(self) ai.run(self, 8) end)
wiz_side[7] = animation.frame(f.hover7, function() return wiz_side[8] end, function(self) ai.run(self, 8) end)
wiz_side[8] = animation.frame(f.hover8, function() return wiz_side[1] end, function(self) ai.run(self, 8) end)

wiz_run[1] = animation.frame(f.fly1, function() return wiz_run[2] end, function(self) ai.run(self, 16); wiz_idle_sound(self) end)
wiz_run[2] = animation.frame(f.fly2, function() return wiz_run[3] end, function(self) ai.run(self, 16) end)
wiz_run[3] = animation.frame(f.fly3, function() return wiz_run[4] end, function(self) ai.run(self, 16) end)
wiz_run[4] = animation.frame(f.fly4, function() return wiz_run[5] end, function(self) ai.run(self, 16) end)
wiz_run[5] = animation.frame(f.fly5, function() return wiz_run[6] end, function(self) ai.run(self, 16) end)
wiz_run[6] = animation.frame(f.fly6, function() return wiz_run[7] end, function(self) ai.run(self, 16) end)
wiz_run[7] = animation.frame(f.fly7, function() return wiz_run[8] end, function(self) ai.run(self, 16) end)
wiz_run[8] = animation.frame(f.fly8, function() return wiz_run[9] end, function(self) ai.run(self, 16) end)
wiz_run[9] = animation.frame(f.fly9, function() return wiz_run[10] end, function(self) ai.run(self, 16) end)
wiz_run[10] = animation.frame(f.fly10, function() return wiz_run[11] end, function(self) ai.run(self, 16) end)
wiz_run[11] = animation.frame(f.fly11, function() return wiz_run[12] end, function(self) ai.run(self, 16) end)
wiz_run[12] = animation.frame(f.fly12, function() return wiz_run[13] end, function(self) ai.run(self, 16) end)
wiz_run[13] = animation.frame(f.fly13, function() return wiz_run[14] end, function(self) ai.run(self, 16) end)
wiz_run[14] = animation.frame(f.fly14, function() return wiz_run[1] end, function(self) ai.run(self, 16) end)

local wiz_fast = {}
wiz_fast[1] = animation.frame(f.magatt1, function() return wiz_fast[2] end, function(self) fight.face(self); wiz_start_fast(self) end)
wiz_fast[2] = animation.frame(f.magatt2, function() return wiz_fast[3] end, function(self) fight.face(self) end)
wiz_fast[3] = animation.frame(f.magatt3, function() return wiz_fast[4] end, function(self) fight.face(self) end)
wiz_fast[4] = animation.frame(f.magatt4, function() return wiz_fast[5] end, function(self) fight.face(self) end)
wiz_fast[5] = animation.frame(f.magatt5, function() return wiz_fast[6] end, function(self) fight.face(self) end)
wiz_fast[6] = animation.frame(f.magatt6, function() return wiz_fast[7] end, function(self) fight.face(self) end)
wiz_fast[7] = animation.frame(f.magatt5, function() return wiz_fast[8] end, function(self) fight.face(self) end)
wiz_fast[8] = animation.frame(f.magatt4, function() return wiz_fast[9] end, function(self) fight.face(self) end)
wiz_fast[9] = animation.frame(f.magatt3, function() return wiz_fast[10] end, function(self) fight.face(self) end)
wiz_fast[10] = animation.frame(f.magatt2, function() return wiz_run[1] end, function(self) fight.face(self); subs.attack_finished(self, 2); wizard_attack_finished(self) end)

local wiz_pain = {}
wiz_pain[1] = animation.frame(f.pain1, function() return wiz_pain[2] end)
wiz_pain[2] = animation.frame(f.pain2, function() return wiz_pain[3] end)
wiz_pain[3] = animation.frame(f.pain3, function() return wiz_pain[4] end)
wiz_pain[4] = animation.frame(f.pain4, function() return wiz_run[1] end)

local wiz_death = {}
wiz_death[1] = animation.frame(f.death1, function() return wiz_death[2] end, function(self) self.velocity = quake.vec3(-200 + 400 * quake.random(), -200 + 400 * quake.random(), 100 + 100 * quake.random()); self.flags = self.flags - (self.flags & C.FL_ONGROUND); quake.sound(self, C.CHAN_VOICE, "wizard/wdeath.wav", 1, C.ATTN_NORM) end)
wiz_death[2] = animation.frame(f.death2, function() return wiz_death[3] end)
wiz_death[3] = animation.frame(f.death3, function() return wiz_death[4] end, function(self) self.solid = C.SOLID_NOT end)
wiz_death[4] = animation.frame(f.death4, function() return wiz_death[5] end)
wiz_death[5] = animation.frame(f.death5, function() return wiz_death[6] end)
wiz_death[6] = animation.frame(f.death6, function() return wiz_death[7] end)
wiz_death[7] = animation.frame(f.death7, function() return wiz_death[8] end)
wiz_death[8] = animation.frame(f.death8, function() return wiz_death[8] end)

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
    wiz_death[1](self)
end

---@param self entity
---@param _attacker entity
---@param damage number
---@return nil
local function wiz_pain_callback(self, _attacker, damage)
    quake.sound(self, C.CHAN_VOICE, "wizard/wpain.wav", 1, C.ATTN_NORM)
    if quake.random() * 70 > damage then return end -- didn't flinch
    wiz_pain[1](self)
end

---@param self entity
---@return nil
local function wiz_missile(self) wiz_fast[1](self) end

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
    self.th_stand = wiz_stand[1]
    self.th_walk = wiz_walk[1]
    self.th_run = wiz_run[1]
    self.th_missile = wiz_missile
    self.th_pain = wiz_pain_callback
    self.th_die = wiz_die
    self.check_attack = M.check_attack
    monsters.fly_start(self)
end

quake.register_entity("monster_wizard", M.spawn)

return M
