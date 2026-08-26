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

local wiz_run
local wiz_side

---@param self entity
---@return boolean
local check_attack = quake.register_function("wizard.check_attack", function(self)
    local enemy_range = quake.globals.enemy_range
    if quake.time() < self.attack_finished then return false end
    if not quake.globals.enemy_vis then return false end
    if enemy_range == C.RANGE_FAR then
        if self.attack_state ~= C.AS_STRAIGHT then self.attack_state = C.AS_STRAIGHT; wiz_run(self) end
        return false
    end
    local targ = assert(self.enemy, "monster has no enemy")
    -- see if any entities are in the way of the shot
    local spot1 = self.origin + self.view_ofs
    local spot2 = targ.origin + targ.view_ofs
    local trace = quake.trace_line(spot1, spot2, false, self)
    if trace.entity ~= targ then
        -- don't have a clear shot, so move to a side
        if self.attack_state ~= C.AS_STRAIGHT then self.attack_state = C.AS_STRAIGHT; wiz_run(self) end
        return false
    end
    local chance
    if enemy_range == C.RANGE_MELEE then chance = 0.9
    elseif enemy_range == C.RANGE_NEAR then chance = 0.6
    elseif enemy_range == C.RANGE_MID then chance = 0.2
    else chance = 0 end
    if quake.random() < chance then self.attack_state = C.AS_MISSILE; return true end
    if enemy_range == C.RANGE_MID then
        if self.attack_state ~= C.AS_STRAIGHT then self.attack_state = C.AS_STRAIGHT; wiz_run(self) end
    else
        if self.attack_state ~= C.AS_SLIDING then self.attack_state = C.AS_SLIDING; wiz_side(self) end
    end
    return false
end)

---@param self entity
---@return nil
local function wizard_attack_finished(self)
    if quake.globals.enemy_range >= C.RANGE_MID or not quake.globals.enemy_vis then
        self.attack_state = C.AS_STRAIGHT
        self.think = wiz_run
    else
        self.attack_state = C.AS_SLIDING
        self.think = wiz_side
    end
end

--[[
==============================================================================

FAST ATTACKS

==============================================================================
]]

---@param self entity
---@return nil
local wiz_fast_fire = quake.register_function("wizard.wiz_fast_fire", function(self)
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
end)

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

local wiz_stand = animation.loop("wizard.wiz_stand", {
    { f.hover1, ai.stand },
    { f.hover2, ai.stand },
    { f.hover3, ai.stand },
    { f.hover4, ai.stand },
    { f.hover5, ai.stand },
    { f.hover6, ai.stand },
    { f.hover7, ai.stand },
    { f.hover8, ai.stand },
})

local wiz_walk = animation.loop("wizard.wiz_walk", {
    { f.hover1, function(self) ai.walk(self, 8); wiz_idle_sound(self) end },
    { f.hover2, function(self) ai.walk(self, 8) end },
    { f.hover3, function(self) ai.walk(self, 8) end },
    { f.hover4, function(self) ai.walk(self, 8) end },
    { f.hover5, function(self) ai.walk(self, 8) end },
    { f.hover6, function(self) ai.walk(self, 8) end },
    { f.hover7, function(self) ai.walk(self, 8) end },
    { f.hover8, function(self) ai.walk(self, 8) end },
})

wiz_side = animation.loop("wizard.wiz_side", {
    { f.hover1, function(self) ai.run(self, 8); wiz_idle_sound(self) end },
    { f.hover2, function(self) ai.run(self, 8) end },
    { f.hover3, function(self) ai.run(self, 8) end },
    { f.hover4, function(self) ai.run(self, 8) end },
    { f.hover5, function(self) ai.run(self, 8) end },
    { f.hover6, function(self) ai.run(self, 8) end },
    { f.hover7, function(self) ai.run(self, 8) end },
    { f.hover8, function(self) ai.run(self, 8) end },
})

wiz_run = animation.loop("wizard.wiz_run", {
    { f.fly1, function(self) ai.run(self, 16); wiz_idle_sound(self) end },
    { f.fly2, function(self) ai.run(self, 16) end },
    { f.fly3, function(self) ai.run(self, 16) end },
    { f.fly4, function(self) ai.run(self, 16) end },
    { f.fly5, function(self) ai.run(self, 16) end },
    { f.fly6, function(self) ai.run(self, 16) end },
    { f.fly7, function(self) ai.run(self, 16) end },
    { f.fly8, function(self) ai.run(self, 16) end },
    { f.fly9, function(self) ai.run(self, 16) end },
    { f.fly10, function(self) ai.run(self, 16) end },
    { f.fly11, function(self) ai.run(self, 16) end },
    { f.fly12, function(self) ai.run(self, 16) end },
    { f.fly13, function(self) ai.run(self, 16) end },
    { f.fly14, function(self) ai.run(self, 16) end },
})

local wiz_fast = animation.sequence("wizard.wiz_fast", {
    { f.magatt1, function(self) fight.face(self); wiz_start_fast(self) end },
    { f.magatt2, function(self) fight.face(self) end },
    { f.magatt3, function(self) fight.face(self) end },
    { f.magatt4, function(self) fight.face(self) end },
    { f.magatt5, function(self) fight.face(self) end },
    { f.magatt6, function(self) fight.face(self) end },
    { f.magatt5, function(self) fight.face(self) end },
    { f.magatt4, function(self) fight.face(self) end },
    { f.magatt3, function(self) fight.face(self) end },
    { f.magatt2, function(self) fight.face(self); subs.attack_finished(self, 2); wizard_attack_finished(self) end },
}, function() return wiz_run end)

local wiz_pain = animation.sequence("wizard.wiz_pain", {
    { f.pain1 },
    { f.pain2 },
    { f.pain3 },
    { f.pain4 },
}, function() return wiz_run end)

local wiz_death = animation.hold("wizard.wiz_death", {
    { f.death1, function(self) self.velocity = quake.vec3(-200 + 400 * quake.random(), -200 + 400 * quake.random(), 100 + 100 * quake.random()); self.flags = self.flags - (self.flags & C.FL_ONGROUND); quake.sound(self, C.CHAN_VOICE, "wizard/wdeath.wav", 1, C.ATTN_NORM) end },
    { f.death2 },
    { f.death3, function(self) self.solid = C.SOLID_NOT end },
    { f.death4 },
    { f.death5 },
    { f.death6 },
    { f.death7 },
    { f.death8 },
})

---@param self entity
---@return nil
local wiz_die = quake.register_function("wizard.wiz_die", function(self)
    -- check for gib
    if self.health < -40 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw_head(self, "progs/h_wizard.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        return
    end
    wiz_death(self)
end)

---@param self entity
---@param _attacker entity
---@param damage number
---@return nil
local wiz_pain_callback = quake.register_function("wizard.wiz_pain_callback", function(self, _attacker, damage)
    quake.sound(self, C.CHAN_VOICE, "wizard/wpain.wav", 1, C.ATTN_NORM)
    if quake.random() * 70 > damage then return end -- didn't flinch
    wiz_pain(self)
end)

---@param self entity
---@return nil
local wiz_missile = quake.register_function("wizard.wiz_missile", function(self) wiz_fast(self) end)

---QUAKED monster_wizard (1 0 0) (-16 -16 -24) (16 16 40) Ambush
---@param self entity
---@return nil
local function spawn(self)
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
    self.th_stand = wiz_stand
    self.th_walk = wiz_walk
    self.th_run = wiz_run
    self.th_missile = wiz_missile
    self.th_pain = wiz_pain_callback
    self.th_die = wiz_die
    self.check_attack = check_attack
    monsters.fly_start(self)
end

quake.register_entity("monster_wizard", spawn)
