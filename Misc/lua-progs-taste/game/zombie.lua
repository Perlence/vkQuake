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
-- Port of zombie.qc from GPL-licensed CleanFixedQuakeC.
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

local count = animation.counter()
local f = {}

f.stand1, f.stand2, f.stand3, f.stand4, f.stand5, f.stand6,
    f.stand7, f.stand8, f.stand9, f.stand10, f.stand11, f.stand12,
    f.stand13, f.stand14, f.stand15 = count(15)

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
    f.walk7, f.walk8, f.walk9, f.walk10, f.walk11, f.walk12,
    f.walk13, f.walk14, f.walk15, f.walk16, f.walk17, f.walk18,
    f.walk19 = count(19)

f.run1, f.run2, f.run3, f.run4, f.run5, f.run6,
    f.run7, f.run8, f.run9, f.run10, f.run11, f.run12,
    f.run13, f.run14, f.run15, f.run16, f.run17, f.run18 = count(18)

f.atta1, f.atta2, f.atta3, f.atta4, f.atta5, f.atta6,
    f.atta7, f.atta8, f.atta9, f.atta10, f.atta11, f.atta12,
    f.atta13 = count(13)

f.attb1, f.attb2, f.attb3, f.attb4, f.attb5, f.attb6,
    f.attb7, f.attb8, f.attb9, f.attb10, f.attb11, f.attb12,
    f.attb13, f.attb14 = count(14)

f.attc1, f.attc2, f.attc3, f.attc4, f.attc5, f.attc6,
    f.attc7, f.attc8, f.attc9, f.attc10, f.attc11, f.attc12 = count(12)

f.paina1, f.paina2, f.paina3, f.paina4, f.paina5, f.paina6,
    f.paina7, f.paina8, f.paina9, f.paina10, f.paina11, f.paina12 = count(12)

f.painb1, f.painb2, f.painb3, f.painb4, f.painb5, f.painb6,
    f.painb7, f.painb8, f.painb9, f.painb10, f.painb11, f.painb12,
    f.painb13, f.painb14, f.painb15, f.painb16, f.painb17, f.painb18,
    f.painb19, f.painb20, f.painb21, f.painb22, f.painb23, f.painb24,
    f.painb25, f.painb26, f.painb27, f.painb28 = count(28)

f.painc1, f.painc2, f.painc3, f.painc4, f.painc5, f.painc6,
    f.painc7, f.painc8, f.painc9, f.painc10, f.painc11, f.painc12,
    f.painc13, f.painc14, f.painc15, f.painc16, f.painc17, f.painc18 = count(18)

f.paind1, f.paind2, f.paind3, f.paind4, f.paind5, f.paind6,
    f.paind7, f.paind8, f.paind9, f.paind10, f.paind11, f.paind12,
    f.paind13 = count(13)

f.paine1, f.paine2, f.paine3, f.paine4, f.paine5, f.paine6,
    f.paine7, f.paine8, f.paine9, f.paine10, f.paine11, f.paine12,
    f.paine13, f.paine14, f.paine15, f.paine16, f.paine17, f.paine18,
    f.paine19, f.paine20, f.paine21, f.paine22, f.paine23, f.paine24,
    f.paine25, f.paine26, f.paine27, f.paine28, f.paine29, f.paine30 = count(30)

f.cruc_1, f.cruc_2, f.cruc_3, f.cruc_4, f.cruc_5, f.cruc_6 = count(6)

--[[
==============================================================================

ZOMBIE

==============================================================================
]]

local SPAWN_CRUCIFIED = 1

--=============================================================================

local zombie_stand = animation.loop("zombie.zombie_stand", {
    { f.stand1, ai.stand },
    { f.stand2, ai.stand },
    { f.stand3, ai.stand },
    { f.stand4, ai.stand },
    { f.stand5, ai.stand },
    { f.stand6, ai.stand },
    { f.stand7, ai.stand },
    { f.stand8, ai.stand },
    { f.stand9, ai.stand },
    { f.stand10, ai.stand },
    { f.stand11, ai.stand },
    { f.stand12, ai.stand },
    { f.stand13, ai.stand },
    { f.stand14, ai.stand },
    { f.stand15, ai.stand },
})

local zombie_cruc = animation.loop("zombie.zombie_cruc", {
    { f.cruc_1, function(self) if quake.random() < 0.1 then quake.sound(self, C.CHAN_VOICE, "zombie/idle_w2.wav", 1, C.ATTN_STATIC) end end },
    { f.cruc_2, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end },
    { f.cruc_3, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end },
    { f.cruc_4, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end },
    { f.cruc_5, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end },
    { f.cruc_6, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end },
})

local zombie_walk = animation.loop("zombie.zombie_walk", {
    { f.walk1, function(self) ai.walk(self, 0) end },
    { f.walk2, function(self) ai.walk(self, 2) end },
    { f.walk3, function(self) ai.walk(self, 3) end },
    { f.walk4, function(self) ai.walk(self, 2) end },
    { f.walk5, function(self) ai.walk(self, 1) end },
    { f.walk6, function(self) ai.walk(self, 0) end },
    { f.walk7, function(self) ai.walk(self, 0) end },
    { f.walk8, function(self) ai.walk(self, 0) end },
    { f.walk9, function(self) ai.walk(self, 0) end },
    { f.walk10, function(self) ai.walk(self, 0) end },
    { f.walk11, function(self) ai.walk(self, 2) end },
    { f.walk12, function(self) ai.walk(self, 2) end },
    { f.walk13, function(self) ai.walk(self, 1) end },
    { f.walk14, function(self) ai.walk(self, 0) end },
    { f.walk15, function(self) ai.walk(self, 0) end },
    { f.walk16, function(self) ai.walk(self, 0) end },
    { f.walk17, function(self) ai.walk(self, 0) end },
    { f.walk18, function(self) ai.walk(self, 0) end },
    { f.walk19, function(self) ai.walk(self, 0); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "zombie/z_idle.wav", 1, C.ATTN_IDLE) end end },
})

local zombie_run = animation.loop("zombie.zombie_run", {
    { f.run1, function(self) ai.run(self, 1); self.inpain = 0 end },
    { f.run2, function(self) ai.run(self, 1) end },
    { f.run3, function(self) ai.run(self, 0) end },
    { f.run4, function(self) ai.run(self, 1) end },
    { f.run5, function(self) ai.run(self, 2) end },
    { f.run6, function(self) ai.run(self, 3) end },
    { f.run7, function(self) ai.run(self, 4) end },
    { f.run8, function(self) ai.run(self, 4) end },
    { f.run9, function(self) ai.run(self, 2) end },
    { f.run10, function(self) ai.run(self, 0) end },
    { f.run11, function(self) ai.run(self, 0) end },
    { f.run12, function(self) ai.run(self, 0) end },
    { f.run13, function(self) ai.run(self, 2) end },
    { f.run14, function(self) ai.run(self, 4) end },
    { f.run15, function(self) ai.run(self, 6) end },
    { f.run16, function(self) ai.run(self, 7) end },
    { f.run17, function(self) ai.run(self, 3) end },
    { f.run18, function(self) ai.run(self, 8); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "zombie/z_idle.wav", 1, C.ATTN_IDLE) end; if quake.random() > 0.8 then quake.sound(self, C.CHAN_VOICE, "zombie/z_idle1.wav", 1, C.ATTN_IDLE) end end },
})

--[[
=============================================================================

ATTACKS

=============================================================================
]]

---@param self entity
---@param other entity
---@return nil
local zombie_grenade_touch = quake.register_function("zombie.zombie_grenade_touch", function(self, other)
    if other == self.owner then return end -- don't explode on owner
    if other.takedamage ~= 0 then
        combat.damage(other, self, self.owner, 10)
        quake.sound(self, C.CHAN_WEAPON, "zombie/z_hit.wav", 1, C.ATTN_NORM)
        quake.remove(self)
        return
    end
    -- bounce sound
    quake.sound(self, C.CHAN_WEAPON, "zombie/z_miss.wav", 1, C.ATTN_NORM)
    self.velocity = quake.vec3(0, 0, 0)
    self.avelocity = quake.vec3(0, 0, 0)
    self.touch = subs.remove
end)

---@param self entity
---@param st vec3
---@return nil
local function zombie_fire_grenade(self, st)
    quake.sound(self, C.CHAN_WEAPON, "zombie/z_shot1.wav", 1, C.ATTN_NORM)
    local missile = quake.spawn()
    missile.owner = self
    missile.movetype = C.MOVETYPE_BOUNCE
    missile.solid = C.SOLID_BBOX
    -- calc org
    local vectors = quake.make_vectors(self.angles)
    local org = self.origin + st.x * vectors.forward + st.y * vectors.right + (st.z - 24) * vectors.up
    -- set missile speed
    vectors = quake.make_vectors(self.angles)
    missile.velocity = (self.enemy.origin - org):normalized()
    missile.velocity = missile.velocity * 600
    missile.velocity = quake.vec3(missile.velocity.x, missile.velocity.y, 200)
    missile.avelocity = quake.vec3(3000, 1000, 2000)
    missile.touch = zombie_grenade_touch
    -- set missile duration
    missile.nextthink = quake.time() + 2.5
    missile.think = subs.remove
    quake.set_model(missile, "progs/zom_gib.mdl")
    quake.set_size(missile, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    quake.set_origin(missile, org)
end

local zombie_atta = animation.sequence("zombie.zombie_atta", {
    { f.atta1, function(self) fight.face(self) end },
    { f.atta2, function(self) fight.face(self) end },
    { f.atta3, function(self) fight.face(self) end },
    { f.atta4, function(self) fight.face(self) end },
    { f.atta5, function(self) fight.face(self) end },
    { f.atta6, function(self) fight.face(self) end },
    { f.atta7, function(self) fight.face(self) end },
    { f.atta8, function(self) fight.face(self) end },
    { f.atta9, function(self) fight.face(self) end },
    { f.atta10, function(self) fight.face(self) end },
    { f.atta11, function(self) fight.face(self) end },
    { f.atta12, function(self) fight.face(self) end },
    { f.atta13, function(self) fight.face(self); zombie_fire_grenade(self, quake.vec3(-10, -22, 30)) end },
}, function() return zombie_run end)

local zombie_attb = animation.sequence("zombie.zombie_attb", {
    { f.attb1, function(self) fight.face(self) end },
    { f.attb2, function(self) fight.face(self) end },
    { f.attb3, function(self) fight.face(self) end },
    { f.attb4, function(self) fight.face(self) end },
    { f.attb5, function(self) fight.face(self) end },
    { f.attb6, function(self) fight.face(self) end },
    { f.attb7, function(self) fight.face(self) end },
    { f.attb8, function(self) fight.face(self) end },
    { f.attb9, function(self) fight.face(self) end },
    { f.attb10, function(self) fight.face(self) end },
    { f.attb11, function(self) fight.face(self) end },
    { f.attb12, function(self) fight.face(self) end },
    { f.attb13, function(self) fight.face(self) end },
    { f.attb13, function(self) fight.face(self); zombie_fire_grenade(self, quake.vec3(-10, -24, 29)) end },
}, function() return zombie_run end)

local zombie_attc = animation.sequence("zombie.zombie_attc", {
    { f.attc1, function(self) fight.face(self) end },
    { f.attc2, function(self) fight.face(self) end },
    { f.attc3, function(self) fight.face(self) end },
    { f.attc4, function(self) fight.face(self) end },
    { f.attc5, function(self) fight.face(self) end },
    { f.attc6, function(self) fight.face(self) end },
    { f.attc7, function(self) fight.face(self) end },
    { f.attc8, function(self) fight.face(self) end },
    { f.attc9, function(self) fight.face(self) end },
    { f.attc10, function(self) fight.face(self) end },
    { f.attc11, function(self) fight.face(self) end },
    { f.attc12, function(self) fight.face(self); zombie_fire_grenade(self, quake.vec3(-12, -19, 29)) end },
}, function() return zombie_run end)

---@param self entity
---@return nil
local zombie_missile = quake.register_function("zombie.zombie_missile", function(self)
    local r = quake.random()
    if r < 0.3 then zombie_atta(self)
    elseif r < 0.6 then zombie_attb(self)
    else zombie_attc(self) end
end)

--[[
=============================================================================

PAIN

=============================================================================
]]

local zombie_paina = animation.sequence("zombie.zombie_paina", {
    { f.paina1, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain.wav", 1, C.ATTN_NORM) end },
    { f.paina2, function(self) ai.pain_forward(self, 3) end },
    { f.paina3, function(self) ai.pain_forward(self, 1) end },
    { f.paina4, function(self) ai.pain(self, 1) end },
    { f.paina5, function(self) ai.pain(self, 3) end },
    { f.paina6, function(self) ai.pain(self, 1) end },
    { f.paina7 },
    { f.paina8 },
    { f.paina9 },
    { f.paina10 },
    { f.paina11 },
    { f.paina12 },
}, function() return zombie_run end)

local zombie_painb = animation.sequence("zombie.zombie_painb", {
    { f.painb1, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain1.wav", 1, C.ATTN_NORM) end },
    { f.painb2, function(self) ai.pain(self, 2) end },
    { f.painb3, function(self) ai.pain(self, 8) end },
    { f.painb4, function(self) ai.pain(self, 6) end },
    { f.painb5, function(self) ai.pain(self, 2) end },
    { f.painb6 },
    { f.painb7 },
    { f.painb8 },
    { f.painb9, function(self) quake.sound(self, C.CHAN_BODY, "zombie/z_fall.wav", 1, C.ATTN_NORM) end },
    { f.painb10 },
    { f.painb11 },
    { f.painb12 },
    { f.painb13 },
    { f.painb14 },
    { f.painb15 },
    { f.painb16 },
    { f.painb17 },
    { f.painb18 },
    { f.painb19 },
    { f.painb20 },
    { f.painb21 },
    { f.painb22 },
    { f.painb23 },
    { f.painb24 },
    { f.painb25, function(self) ai.pain_forward(self, 1) end },
    { f.painb26 },
    { f.painb27 },
    { f.painb28 },
}, function() return zombie_run end)

local zombie_painc = animation.sequence("zombie.zombie_painc", {
    { f.painc1, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain1.wav", 1, C.ATTN_NORM) end },
    { f.painc2 },
    { f.painc3, function(self) ai.pain(self, 3) end },
    { f.painc4, function(self) ai.pain(self, 1) end },
    { f.painc5 },
    { f.painc6 },
    { f.painc7 },
    { f.painc8 },
    { f.painc9 },
    { f.painc10 },
    { f.painc11, function(self) ai.pain_forward(self, 1) end },
    { f.painc12, function(self) ai.pain_forward(self, 1) end },
    { f.painc13 },
    { f.painc14 },
    { f.painc15 },
    { f.painc16 },
    { f.painc17 },
    { f.painc18 },
}, function() return zombie_run end)

local zombie_paind = animation.sequence("zombie.zombie_paind", {
    { f.paind1, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain.wav", 1, C.ATTN_NORM) end },
    { f.paind2 },
    { f.paind3 },
    { f.paind4 },
    { f.paind5 },
    { f.paind6 },
    { f.paind7 },
    { f.paind8 },
    { f.paind9, function(self) ai.pain(self, 1) end },
    { f.paind10 },
    { f.paind11 },
    { f.paind12 },
    { f.paind13 },
}, function() return zombie_run end)

local zombie_paine_recover
local zombie_paine = animation.sequence("zombie.zombie_paine", {
    { f.paine1, function(self)
        quake.sound(self, C.CHAN_VOICE, "zombie/z_pain.wav", 1, C.ATTN_NORM)
        self.health = 60
    end },
    { f.paine2, function(self)
        ai.pain(self, 8)
    end },
    { f.paine3, function(self)
        ai.pain(self, 5)
    end },
    { f.paine4, function(self)
        ai.pain(self, 3)
    end },
    { f.paine5, function(self)
        ai.pain(self, 1)
    end },
    { f.paine6, function(self)
        ai.pain(self, 2)
    end },
    { f.paine7, function(self)
        ai.pain(self, 1)
    end },
    { f.paine8, function(self)
        ai.pain(self, 1)
    end },
    { f.paine9, function(self)
        ai.pain(self, 2)
    end },
    { f.paine10, function(self)
        quake.sound(self, C.CHAN_BODY, "zombie/z_fall.wav", 1, C.ATTN_NORM)
        self.solid = C.SOLID_NOT
    end },
}, function() return zombie_paine_recover end)
zombie_paine_recover = animation.sequence("zombie.zombie_paine_recover", {
    { f.paine11, function(self)
        self.nextthink = self.nextthink + 5
        self.health = 60
    end },
    { f.paine12, function(self)
        -- see if ok to stand up
        self.health = 60
        quake.sound(self, C.CHAN_VOICE, "zombie/z_idle.wav", 1, C.ATTN_IDLE)
        self.solid = C.SOLID_SLIDEBOX
        if not quake.walk_move(self, 0, 0) then self.think = zombie_paine_recover; self.solid = C.SOLID_NOT; return end
    end },
    { f.paine13 },
    { f.paine14 },
    { f.paine15 },
    { f.paine16 },
    { f.paine17 },
    { f.paine18 },
    { f.paine19 },
    { f.paine20 },
    { f.paine21 },
    { f.paine22 },
    { f.paine23 },
    { f.paine24 },
    { f.paine25, function(self)
        ai.pain_forward(self, 5)
    end },
    { f.paine26, function(self)
        ai.pain_forward(self, 3)
    end },
    { f.paine27, function(self)
        ai.pain_forward(self, 1)
    end },
    { f.paine28, function(self)
        ai.pain(self, 1)
    end },
    { f.paine29 },
    { f.paine30 },
}, function() return zombie_run end)

---@param self entity
---@return nil
local zombie_die = quake.register_function("zombie.zombie_die", function(self)
    quake.sound(self, C.CHAN_VOICE, "zombie/z_gib.wav", 1, C.ATTN_NORM)
    gibs.throw_head(self, "progs/h_zombie.mdl", self.health)
    gibs.throw(self, "progs/gib1.mdl", self.health)
    gibs.throw(self, "progs/gib2.mdl", self.health)
    gibs.throw(self, "progs/gib3.mdl", self.health)
end)

---Zombies can only be killed (gibbed) by doing 60 hit points of damage
---in a single frame (rockets, grenades, quad shotgun, quad nailgun).
---
---A hit of 25 points or more (super shotgun, quad nailgun) will always put it
---down to the ground.
---
---A hit of from 10 to 40 points in one frame will cause it to go down if it
---has been twice in two seconds, otherwise it goes into one of the four
---fast pain frames.
---
---A hit of less than 10 points of damage (winged by a shotgun) will be ignored.
---
---FIXME: don't use pain_finished because of nightmare hack
---@param self entity
---@param _attacker entity
---@param take number
---@return nil
local zombie_pain = quake.register_function("zombie.zombie_pain", function(self, _attacker, take)
    -- always reset health
    self.health = 60
    if take < 9 then return end -- totally ignore
    if self.inpain == 2 then return end -- down on ground, so don't reset any counters
    -- go down immediately if a big enough hit
    if take >= 25 then self.inpain = 2; zombie_paine(self); return end
    if self.inpain ~= 0 then
        -- if hit again in next gre seconds while not in pain frames, definitely drop
        self.pain_finished = quake.time() + 3
        -- currently going through an animation, don't change
        return
    end
    if self.pain_finished > quake.time() then
        -- hit again, so drop down
        self.inpain = 2
        zombie_paine(self)
        return
    end
    -- gp into one of the fast pain animations
    self.inpain = 1
    local r = quake.random()
    if r < 0.25 then zombie_paina(self)
    elseif r < 0.5 then zombie_painb(self)
    elseif r < 0.75 then zombie_painc(self)
    else zombie_paind(self) end
end)

--============================================================================

---QUAKED monster_zombie (1 0 0) (-16 -16 -24) (16 16 32) Crucified ambush
---
---If crucified, stick the bounding box 12 pixels back into a wall to look right.
---@param self entity
---@return nil
local function spawn(self)
    if quake.cvar("deathmatch") ~= 0 then quake.remove(self); return end
    quake.precache_model("progs/zombie.mdl")
    quake.precache_model("progs/h_zombie.mdl")
    quake.precache_model("progs/zom_gib.mdl")
    quake.precache_sound("zombie/z_idle.wav")
    quake.precache_sound("zombie/z_idle1.wav")
    quake.precache_sound("zombie/z_shot1.wav")
    quake.precache_sound("zombie/z_gib.wav")
    quake.precache_sound("zombie/z_pain.wav")
    quake.precache_sound("zombie/z_pain1.wav")
    quake.precache_sound("zombie/z_fall.wav")
    quake.precache_sound("zombie/z_miss.wav")
    quake.precache_sound("zombie/z_hit.wav")
    quake.precache_sound("zombie/idle_w2.wav")
    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP
    quake.set_model(self, "progs/zombie.mdl")
    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 40))
    self.health = 60
    self.th_stand = zombie_stand
    self.th_walk = zombie_walk
    self.th_run = zombie_run
    self.th_pain = zombie_pain
    self.th_die = zombie_die
    self.th_missile = zombie_missile
    if (self.spawnflags & SPAWN_CRUCIFIED) ~= 0 then
        self.movetype = C.MOVETYPE_NONE
        zombie_cruc(self)
    else
        monsters.walk_start(self)
    end
end

quake.register_entity("monster_zombie", spawn)
