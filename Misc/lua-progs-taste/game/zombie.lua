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

local M = {}

--[[
==============================================================================

ZOMBIE

==============================================================================
]]

local SPAWN_CRUCIFIED = 1

--=============================================================================

local zombie_stand1

do
    local zombie_stand2, zombie_stand3, zombie_stand4, zombie_stand5, zombie_stand6, zombie_stand7, zombie_stand8, zombie_stand9, zombie_stand10, zombie_stand11, zombie_stand12, zombie_stand13, zombie_stand14, zombie_stand15

zombie_stand1 = animation.frame("stand1", function() return zombie_stand2 end, ai.stand)
zombie_stand2 = animation.frame("stand2", function() return zombie_stand3 end, ai.stand)
zombie_stand3 = animation.frame("stand3", function() return zombie_stand4 end, ai.stand)
zombie_stand4 = animation.frame("stand4", function() return zombie_stand5 end, ai.stand)
zombie_stand5 = animation.frame("stand5", function() return zombie_stand6 end, ai.stand)
zombie_stand6 = animation.frame("stand6", function() return zombie_stand7 end, ai.stand)
zombie_stand7 = animation.frame("stand7", function() return zombie_stand8 end, ai.stand)
zombie_stand8 = animation.frame("stand8", function() return zombie_stand9 end, ai.stand)
zombie_stand9 = animation.frame("stand9", function() return zombie_stand10 end, ai.stand)
zombie_stand10 = animation.frame("stand10", function() return zombie_stand11 end, ai.stand)
zombie_stand11 = animation.frame("stand11", function() return zombie_stand12 end, ai.stand)
zombie_stand12 = animation.frame("stand12", function() return zombie_stand13 end, ai.stand)
zombie_stand13 = animation.frame("stand13", function() return zombie_stand14 end, ai.stand)
zombie_stand14 = animation.frame("stand14", function() return zombie_stand15 end, ai.stand)
zombie_stand15 = animation.frame("stand15", function() return zombie_stand1 end, ai.stand)

end

local zombie_cruc1

do
    local zombie_cruc2, zombie_cruc3, zombie_cruc4, zombie_cruc5, zombie_cruc6

zombie_cruc1 = animation.frame("cruc_1", function() return zombie_cruc2 end, function(self) if quake.random() < 0.1 then quake.sound(self, C.CHAN_VOICE, "zombie/idle_w2.wav", 1, C.ATTN_STATIC) end end)
zombie_cruc2 = animation.frame("cruc_2", function() return zombie_cruc3 end, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end)
zombie_cruc3 = animation.frame("cruc_3", function() return zombie_cruc4 end, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end)
zombie_cruc4 = animation.frame("cruc_4", function() return zombie_cruc5 end, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end)
zombie_cruc5 = animation.frame("cruc_5", function() return zombie_cruc6 end, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end)
zombie_cruc6 = animation.frame("cruc_6", function() return zombie_cruc1 end, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end)

end

local zombie_walk1

do
    local zombie_walk2, zombie_walk3, zombie_walk4, zombie_walk5, zombie_walk6, zombie_walk7, zombie_walk8, zombie_walk9, zombie_walk10, zombie_walk11, zombie_walk12, zombie_walk13, zombie_walk14, zombie_walk15, zombie_walk16, zombie_walk17, zombie_walk18, zombie_walk19

zombie_walk1 = animation.frame("walk1", function() return zombie_walk2 end, function(self) ai.walk(self, 0) end)
zombie_walk2 = animation.frame("walk2", function() return zombie_walk3 end, function(self) ai.walk(self, 2) end)
zombie_walk3 = animation.frame("walk3", function() return zombie_walk4 end, function(self) ai.walk(self, 3) end)
zombie_walk4 = animation.frame("walk4", function() return zombie_walk5 end, function(self) ai.walk(self, 2) end)
zombie_walk5 = animation.frame("walk5", function() return zombie_walk6 end, function(self) ai.walk(self, 1) end)
zombie_walk6 = animation.frame("walk6", function() return zombie_walk7 end, function(self) ai.walk(self, 0) end)
zombie_walk7 = animation.frame("walk7", function() return zombie_walk8 end, function(self) ai.walk(self, 0) end)
zombie_walk8 = animation.frame("walk8", function() return zombie_walk9 end, function(self) ai.walk(self, 0) end)
zombie_walk9 = animation.frame("walk9", function() return zombie_walk10 end, function(self) ai.walk(self, 0) end)
zombie_walk10 = animation.frame("walk10", function() return zombie_walk11 end, function(self) ai.walk(self, 0) end)
zombie_walk11 = animation.frame("walk11", function() return zombie_walk12 end, function(self) ai.walk(self, 2) end)
zombie_walk12 = animation.frame("walk12", function() return zombie_walk13 end, function(self) ai.walk(self, 2) end)
zombie_walk13 = animation.frame("walk13", function() return zombie_walk14 end, function(self) ai.walk(self, 1) end)
zombie_walk14 = animation.frame("walk14", function() return zombie_walk15 end, function(self) ai.walk(self, 0) end)
zombie_walk15 = animation.frame("walk15", function() return zombie_walk16 end, function(self) ai.walk(self, 0) end)
zombie_walk16 = animation.frame("walk16", function() return zombie_walk17 end, function(self) ai.walk(self, 0) end)
zombie_walk17 = animation.frame("walk17", function() return zombie_walk18 end, function(self) ai.walk(self, 0) end)
zombie_walk18 = animation.frame("walk18", function() return zombie_walk19 end, function(self) ai.walk(self, 0) end)
zombie_walk19 = animation.frame("walk19", function() return zombie_walk1 end, function(self) ai.walk(self, 0); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "zombie/z_idle.wav", 1, C.ATTN_IDLE) end end)

end

local zombie_run1

do
    local zombie_run2, zombie_run3, zombie_run4, zombie_run5, zombie_run6, zombie_run7, zombie_run8, zombie_run9, zombie_run10, zombie_run11, zombie_run12, zombie_run13, zombie_run14, zombie_run15, zombie_run16, zombie_run17, zombie_run18

zombie_run1 = animation.frame("run1", function() return zombie_run2 end, function(self) ai.run(self, 1); self.inpain = 0 end)
zombie_run2 = animation.frame("run2", function() return zombie_run3 end, function(self) ai.run(self, 1) end)
zombie_run3 = animation.frame("run3", function() return zombie_run4 end, function(self) ai.run(self, 0) end)
zombie_run4 = animation.frame("run4", function() return zombie_run5 end, function(self) ai.run(self, 1) end)
zombie_run5 = animation.frame("run5", function() return zombie_run6 end, function(self) ai.run(self, 2) end)
zombie_run6 = animation.frame("run6", function() return zombie_run7 end, function(self) ai.run(self, 3) end)
zombie_run7 = animation.frame("run7", function() return zombie_run8 end, function(self) ai.run(self, 4) end)
zombie_run8 = animation.frame("run8", function() return zombie_run9 end, function(self) ai.run(self, 4) end)
zombie_run9 = animation.frame("run9", function() return zombie_run10 end, function(self) ai.run(self, 2) end)
zombie_run10 = animation.frame("run10", function() return zombie_run11 end, function(self) ai.run(self, 0) end)
zombie_run11 = animation.frame("run11", function() return zombie_run12 end, function(self) ai.run(self, 0) end)
zombie_run12 = animation.frame("run12", function() return zombie_run13 end, function(self) ai.run(self, 0) end)
zombie_run13 = animation.frame("run13", function() return zombie_run14 end, function(self) ai.run(self, 2) end)
zombie_run14 = animation.frame("run14", function() return zombie_run15 end, function(self) ai.run(self, 4) end)
zombie_run15 = animation.frame("run15", function() return zombie_run16 end, function(self) ai.run(self, 6) end)
zombie_run16 = animation.frame("run16", function() return zombie_run17 end, function(self) ai.run(self, 7) end)
zombie_run17 = animation.frame("run17", function() return zombie_run18 end, function(self) ai.run(self, 3) end)
zombie_run18 = animation.frame("run18", function() return zombie_run1 end, function(self) ai.run(self, 8); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "zombie/z_idle.wav", 1, C.ATTN_IDLE) end; if quake.random() > 0.8 then quake.sound(self, C.CHAN_VOICE, "zombie/z_idle1.wav", 1, C.ATTN_IDLE) end end)

end

--[[
=============================================================================

ATTACKS

=============================================================================
]]

local function zombie_grenade_touch(self, other)
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
end

--[[
================
ZombieFireGrenade
================
]]
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

local zombie_atta1

do
    local zombie_atta2, zombie_atta3, zombie_atta4, zombie_atta5, zombie_atta6, zombie_atta7, zombie_atta8, zombie_atta9, zombie_atta10, zombie_atta11, zombie_atta12, zombie_atta13

zombie_atta1 = animation.frame("atta1", function() return zombie_atta2 end, function(self) fight.face(self) end)
zombie_atta2 = animation.frame("atta2", function() return zombie_atta3 end, function(self) fight.face(self) end)
zombie_atta3 = animation.frame("atta3", function() return zombie_atta4 end, function(self) fight.face(self) end)
zombie_atta4 = animation.frame("atta4", function() return zombie_atta5 end, function(self) fight.face(self) end)
zombie_atta5 = animation.frame("atta5", function() return zombie_atta6 end, function(self) fight.face(self) end)
zombie_atta6 = animation.frame("atta6", function() return zombie_atta7 end, function(self) fight.face(self) end)
zombie_atta7 = animation.frame("atta7", function() return zombie_atta8 end, function(self) fight.face(self) end)
zombie_atta8 = animation.frame("atta8", function() return zombie_atta9 end, function(self) fight.face(self) end)
zombie_atta9 = animation.frame("atta9", function() return zombie_atta10 end, function(self) fight.face(self) end)
zombie_atta10 = animation.frame("atta10", function() return zombie_atta11 end, function(self) fight.face(self) end)
zombie_atta11 = animation.frame("atta11", function() return zombie_atta12 end, function(self) fight.face(self) end)
zombie_atta12 = animation.frame("atta12", function() return zombie_atta13 end, function(self) fight.face(self) end)
zombie_atta13 = animation.frame("atta13", function() return zombie_run1 end, function(self) fight.face(self); zombie_fire_grenade(self, quake.vec3(-10, -22, 30)) end)

end

local zombie_attb1

do
    local zombie_attb2, zombie_attb3, zombie_attb4, zombie_attb5, zombie_attb6, zombie_attb7, zombie_attb8, zombie_attb9, zombie_attb10, zombie_attb11, zombie_attb12, zombie_attb13, zombie_attb14

zombie_attb1 = animation.frame("attb1", function() return zombie_attb2 end, function(self) fight.face(self) end)
zombie_attb2 = animation.frame("attb2", function() return zombie_attb3 end, function(self) fight.face(self) end)
zombie_attb3 = animation.frame("attb3", function() return zombie_attb4 end, function(self) fight.face(self) end)
zombie_attb4 = animation.frame("attb4", function() return zombie_attb5 end, function(self) fight.face(self) end)
zombie_attb5 = animation.frame("attb5", function() return zombie_attb6 end, function(self) fight.face(self) end)
zombie_attb6 = animation.frame("attb6", function() return zombie_attb7 end, function(self) fight.face(self) end)
zombie_attb7 = animation.frame("attb7", function() return zombie_attb8 end, function(self) fight.face(self) end)
zombie_attb8 = animation.frame("attb8", function() return zombie_attb9 end, function(self) fight.face(self) end)
zombie_attb9 = animation.frame("attb9", function() return zombie_attb10 end, function(self) fight.face(self) end)
zombie_attb10 = animation.frame("attb10", function() return zombie_attb11 end, function(self) fight.face(self) end)
zombie_attb11 = animation.frame("attb11", function() return zombie_attb12 end, function(self) fight.face(self) end)
zombie_attb12 = animation.frame("attb12", function() return zombie_attb13 end, function(self) fight.face(self) end)
zombie_attb13 = animation.frame("attb13", function() return zombie_attb14 end, function(self) fight.face(self) end)
zombie_attb14 = animation.frame("attb13", function() return zombie_run1 end, function(self) fight.face(self); zombie_fire_grenade(self, quake.vec3(-10, -24, 29)) end)

end

local zombie_attc1

do
    local zombie_attc2, zombie_attc3, zombie_attc4, zombie_attc5, zombie_attc6, zombie_attc7, zombie_attc8, zombie_attc9, zombie_attc10, zombie_attc11, zombie_attc12

zombie_attc1 = animation.frame("attc1", function() return zombie_attc2 end, function(self) fight.face(self) end)
zombie_attc2 = animation.frame("attc2", function() return zombie_attc3 end, function(self) fight.face(self) end)
zombie_attc3 = animation.frame("attc3", function() return zombie_attc4 end, function(self) fight.face(self) end)
zombie_attc4 = animation.frame("attc4", function() return zombie_attc5 end, function(self) fight.face(self) end)
zombie_attc5 = animation.frame("attc5", function() return zombie_attc6 end, function(self) fight.face(self) end)
zombie_attc6 = animation.frame("attc6", function() return zombie_attc7 end, function(self) fight.face(self) end)
zombie_attc7 = animation.frame("attc7", function() return zombie_attc8 end, function(self) fight.face(self) end)
zombie_attc8 = animation.frame("attc8", function() return zombie_attc9 end, function(self) fight.face(self) end)
zombie_attc9 = animation.frame("attc9", function() return zombie_attc10 end, function(self) fight.face(self) end)
zombie_attc10 = animation.frame("attc10", function() return zombie_attc11 end, function(self) fight.face(self) end)
zombie_attc11 = animation.frame("attc11", function() return zombie_attc12 end, function(self) fight.face(self) end)
zombie_attc12 = animation.frame("attc12", function() return zombie_run1 end, function(self) fight.face(self); zombie_fire_grenade(self, quake.vec3(-12, -19, 29)) end)

end

local function zombie_missile(self)
    local r = quake.random()
    if r < 0.3 then zombie_atta1(self)
    elseif r < 0.6 then zombie_attb1(self)
    else zombie_attc1(self) end
end

--[[
=============================================================================

PAIN

=============================================================================
]]

local zombie_paina1

do
    local zombie_paina2, zombie_paina3, zombie_paina4, zombie_paina5, zombie_paina6, zombie_paina7, zombie_paina8, zombie_paina9, zombie_paina10, zombie_paina11, zombie_paina12

zombie_paina1 = animation.frame("paina1", function() return zombie_paina2 end, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain.wav", 1, C.ATTN_NORM) end)
zombie_paina2 = animation.frame("paina2", function() return zombie_paina3 end, function(self) ai.pain_forward(self, 3) end)
zombie_paina3 = animation.frame("paina3", function() return zombie_paina4 end, function(self) ai.pain_forward(self, 1) end)
zombie_paina4 = animation.frame("paina4", function() return zombie_paina5 end, function(self) ai.pain(self, 1) end)
zombie_paina5 = animation.frame("paina5", function() return zombie_paina6 end, function(self) ai.pain(self, 3) end)
zombie_paina6 = animation.frame("paina6", function() return zombie_paina7 end, function(self) ai.pain(self, 1) end)
zombie_paina7 = animation.frame("paina7", function() return zombie_paina8 end)
zombie_paina8 = animation.frame("paina8", function() return zombie_paina9 end)
zombie_paina9 = animation.frame("paina9", function() return zombie_paina10 end)
zombie_paina10 = animation.frame("paina10", function() return zombie_paina11 end)
zombie_paina11 = animation.frame("paina11", function() return zombie_paina12 end)
zombie_paina12 = animation.frame("paina12", function() return zombie_run1 end)

end

local zombie_painb1

do
    local zombie_painb2, zombie_painb3, zombie_painb4, zombie_painb5, zombie_painb6, zombie_painb7, zombie_painb8, zombie_painb9, zombie_painb10, zombie_painb11, zombie_painb12, zombie_painb13, zombie_painb14, zombie_painb15, zombie_painb16, zombie_painb17, zombie_painb18, zombie_painb19, zombie_painb20, zombie_painb21, zombie_painb22, zombie_painb23, zombie_painb24, zombie_painb25, zombie_painb26, zombie_painb27, zombie_painb28

zombie_painb1 = animation.frame("painb1", function() return zombie_painb2 end, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain1.wav", 1, C.ATTN_NORM) end)
zombie_painb2 = animation.frame("painb2", function() return zombie_painb3 end, function(self) ai.pain(self, 2) end)
zombie_painb3 = animation.frame("painb3", function() return zombie_painb4 end, function(self) ai.pain(self, 8) end)
zombie_painb4 = animation.frame("painb4", function() return zombie_painb5 end, function(self) ai.pain(self, 6) end)
zombie_painb5 = animation.frame("painb5", function() return zombie_painb6 end, function(self) ai.pain(self, 2) end)
zombie_painb6 = animation.frame("painb6", function() return zombie_painb7 end)
zombie_painb7 = animation.frame("painb7", function() return zombie_painb8 end)
zombie_painb8 = animation.frame("painb8", function() return zombie_painb9 end)
zombie_painb9 = animation.frame("painb9", function() return zombie_painb10 end, function(self) quake.sound(self, C.CHAN_BODY, "zombie/z_fall.wav", 1, C.ATTN_NORM) end)
zombie_painb10 = animation.frame("painb10", function() return zombie_painb11 end)
zombie_painb11 = animation.frame("painb11", function() return zombie_painb12 end)
zombie_painb12 = animation.frame("painb12", function() return zombie_painb13 end)
zombie_painb13 = animation.frame("painb13", function() return zombie_painb14 end)
zombie_painb14 = animation.frame("painb14", function() return zombie_painb15 end)
zombie_painb15 = animation.frame("painb15", function() return zombie_painb16 end)
zombie_painb16 = animation.frame("painb16", function() return zombie_painb17 end)
zombie_painb17 = animation.frame("painb17", function() return zombie_painb18 end)
zombie_painb18 = animation.frame("painb18", function() return zombie_painb19 end)
zombie_painb19 = animation.frame("painb19", function() return zombie_painb20 end)
zombie_painb20 = animation.frame("painb20", function() return zombie_painb21 end)
zombie_painb21 = animation.frame("painb21", function() return zombie_painb22 end)
zombie_painb22 = animation.frame("painb22", function() return zombie_painb23 end)
zombie_painb23 = animation.frame("painb23", function() return zombie_painb24 end)
zombie_painb24 = animation.frame("painb24", function() return zombie_painb25 end)
zombie_painb25 = animation.frame("painb25", function() return zombie_painb26 end, function(self) ai.pain_forward(self, 1) end)
zombie_painb26 = animation.frame("painb26", function() return zombie_painb27 end)
zombie_painb27 = animation.frame("painb27", function() return zombie_painb28 end)
zombie_painb28 = animation.frame("painb28", function() return zombie_run1 end)

end

local zombie_painc1

do
    local zombie_painc2, zombie_painc3, zombie_painc4, zombie_painc5, zombie_painc6, zombie_painc7, zombie_painc8, zombie_painc9, zombie_painc10, zombie_painc11, zombie_painc12, zombie_painc13, zombie_painc14, zombie_painc15, zombie_painc16, zombie_painc17, zombie_painc18

zombie_painc1 = animation.frame("painc1", function() return zombie_painc2 end, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain1.wav", 1, C.ATTN_NORM) end)
zombie_painc2 = animation.frame("painc2", function() return zombie_painc3 end)
zombie_painc3 = animation.frame("painc3", function() return zombie_painc4 end, function(self) ai.pain(self, 3) end)
zombie_painc4 = animation.frame("painc4", function() return zombie_painc5 end, function(self) ai.pain(self, 1) end)
zombie_painc5 = animation.frame("painc5", function() return zombie_painc6 end)
zombie_painc6 = animation.frame("painc6", function() return zombie_painc7 end)
zombie_painc7 = animation.frame("painc7", function() return zombie_painc8 end)
zombie_painc8 = animation.frame("painc8", function() return zombie_painc9 end)
zombie_painc9 = animation.frame("painc9", function() return zombie_painc10 end)
zombie_painc10 = animation.frame("painc10", function() return zombie_painc11 end)
zombie_painc11 = animation.frame("painc11", function() return zombie_painc12 end, function(self) ai.pain_forward(self, 1) end)
zombie_painc12 = animation.frame("painc12", function() return zombie_painc13 end, function(self) ai.pain_forward(self, 1) end)
zombie_painc13 = animation.frame("painc13", function() return zombie_painc14 end)
zombie_painc14 = animation.frame("painc14", function() return zombie_painc15 end)
zombie_painc15 = animation.frame("painc15", function() return zombie_painc16 end)
zombie_painc16 = animation.frame("painc16", function() return zombie_painc17 end)
zombie_painc17 = animation.frame("painc17", function() return zombie_painc18 end)
zombie_painc18 = animation.frame("painc18", function() return zombie_run1 end)

end

local zombie_paind1

do
    local zombie_paind2, zombie_paind3, zombie_paind4, zombie_paind5, zombie_paind6, zombie_paind7, zombie_paind8, zombie_paind9, zombie_paind10, zombie_paind11, zombie_paind12, zombie_paind13

zombie_paind1 = animation.frame("paind1", function() return zombie_paind2 end, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain.wav", 1, C.ATTN_NORM) end)
zombie_paind2 = animation.frame("paind2", function() return zombie_paind3 end)
zombie_paind3 = animation.frame("paind3", function() return zombie_paind4 end)
zombie_paind4 = animation.frame("paind4", function() return zombie_paind5 end)
zombie_paind5 = animation.frame("paind5", function() return zombie_paind6 end)
zombie_paind6 = animation.frame("paind6", function() return zombie_paind7 end)
zombie_paind7 = animation.frame("paind7", function() return zombie_paind8 end)
zombie_paind8 = animation.frame("paind8", function() return zombie_paind9 end)
zombie_paind9 = animation.frame("paind9", function() return zombie_paind10 end, function(self) ai.pain(self, 1) end)
zombie_paind10 = animation.frame("paind10", function() return zombie_paind11 end)
zombie_paind11 = animation.frame("paind11", function() return zombie_paind12 end)
zombie_paind12 = animation.frame("paind12", function() return zombie_paind13 end)
zombie_paind13 = animation.frame("paind13", function() return zombie_run1 end)

end

local zombie_paine1

do
    local zombie_paine2, zombie_paine3, zombie_paine4, zombie_paine5, zombie_paine6, zombie_paine7, zombie_paine8, zombie_paine9, zombie_paine10, zombie_paine11, zombie_paine12, zombie_paine13, zombie_paine14, zombie_paine15, zombie_paine16, zombie_paine17, zombie_paine18, zombie_paine19, zombie_paine20, zombie_paine21, zombie_paine22, zombie_paine23, zombie_paine24, zombie_paine25, zombie_paine26, zombie_paine27, zombie_paine28, zombie_paine29, zombie_paine30

zombie_paine1 = animation.frame("paine1", function() return zombie_paine2 end, function(self)
        quake.sound(self, C.CHAN_VOICE, "zombie/z_pain.wav", 1, C.ATTN_NORM)
        self.health = 60
    end)
zombie_paine2 = animation.frame("paine2", function() return zombie_paine3 end, function(self)
        ai.pain(self, 8)
    end)
zombie_paine3 = animation.frame("paine3", function() return zombie_paine4 end, function(self)
        ai.pain(self, 5)
    end)
zombie_paine4 = animation.frame("paine4", function() return zombie_paine5 end, function(self)
        ai.pain(self, 3)
    end)
zombie_paine5 = animation.frame("paine5", function() return zombie_paine6 end, function(self)
        ai.pain(self, 1)
    end)
zombie_paine6 = animation.frame("paine6", function() return zombie_paine7 end, function(self)
        ai.pain(self, 2)
    end)
zombie_paine7 = animation.frame("paine7", function() return zombie_paine8 end, function(self)
        ai.pain(self, 1)
    end)
zombie_paine8 = animation.frame("paine8", function() return zombie_paine9 end, function(self)
        ai.pain(self, 1)
    end)
zombie_paine9 = animation.frame("paine9", function() return zombie_paine10 end, function(self)
        ai.pain(self, 2)
    end)
zombie_paine10 = animation.frame("paine10", function() return zombie_paine11 end, function(self)
        quake.sound(self, C.CHAN_BODY, "zombie/z_fall.wav", 1, C.ATTN_NORM)
        self.solid = C.SOLID_NOT
    end)
zombie_paine11 = animation.frame("paine11", function() return zombie_paine12 end, function(self)
        self.nextthink = self.nextthink + 5
        self.health = 60
    end)
zombie_paine12 = animation.frame("paine12", function() return zombie_paine13 end, function(self)
        -- see if ok to stand up
        self.health = 60
        quake.sound(self, C.CHAN_VOICE, "zombie/z_idle.wav", 1, C.ATTN_IDLE)
        self.solid = C.SOLID_SLIDEBOX
        if not quake.walk_move(self, 0, 0) then self.think = zombie_paine11; self.solid = C.SOLID_NOT; return end
    end)
zombie_paine13 = animation.frame("paine13", function() return zombie_paine14 end)
zombie_paine14 = animation.frame("paine14", function() return zombie_paine15 end)
zombie_paine15 = animation.frame("paine15", function() return zombie_paine16 end)
zombie_paine16 = animation.frame("paine16", function() return zombie_paine17 end)
zombie_paine17 = animation.frame("paine17", function() return zombie_paine18 end)
zombie_paine18 = animation.frame("paine18", function() return zombie_paine19 end)
zombie_paine19 = animation.frame("paine19", function() return zombie_paine20 end)
zombie_paine20 = animation.frame("paine20", function() return zombie_paine21 end)
zombie_paine21 = animation.frame("paine21", function() return zombie_paine22 end)
zombie_paine22 = animation.frame("paine22", function() return zombie_paine23 end)
zombie_paine23 = animation.frame("paine23", function() return zombie_paine24 end)
zombie_paine24 = animation.frame("paine24", function() return zombie_paine25 end)
zombie_paine25 = animation.frame("paine25", function() return zombie_paine26 end, function(self)
        ai.pain_forward(self, 5)
    end)
zombie_paine26 = animation.frame("paine26", function() return zombie_paine27 end, function(self)
        ai.pain_forward(self, 3)
    end)
zombie_paine27 = animation.frame("paine27", function() return zombie_paine28 end, function(self)
        ai.pain_forward(self, 1)
    end)
zombie_paine28 = animation.frame("paine28", function() return zombie_paine29 end, function(self)
        ai.pain(self, 1)
    end)
zombie_paine29 = animation.frame("paine29", function() return zombie_paine30 end)
zombie_paine30 = animation.frame("paine30", function() return zombie_run1 end)

end

local function zombie_die(self)
    quake.sound(self, C.CHAN_VOICE, "zombie/z_gib.wav", 1, C.ATTN_NORM)
    gibs.throw_head(self, "progs/h_zombie.mdl", self.health)
    gibs.throw(self, "progs/gib1.mdl", self.health)
    gibs.throw(self, "progs/gib2.mdl", self.health)
    gibs.throw(self, "progs/gib3.mdl", self.health)
end

--[[
=================
zombie_pain

Zombies can only be killed (gibbed) by doing 60 hit points of damage
in a single frame (rockets, grenades, quad shotgun, quad nailgun).

A hit of 25 points or more (super shotgun, quad nailgun) will always put it
down to the ground.

A hit of from 10 to 40 points in one frame will cause it to go down if it
has been twice in two seconds, otherwise it goes into one of the four
fast pain frames.

A hit of less than 10 points of damage (winged by a shotgun) will be ignored.

FIXME: don't use pain_finished because of nightmare hack
=================
]]
local function zombie_pain(self, _attacker, take)
    -- always reset health
    self.health = 60
    if take < 9 then return end -- totally ignore
    if self.inpain == 2 then return end -- down on ground, so don't reset any counters
    -- go down immediately if a big enough hit
    if take >= 25 then self.inpain = 2; zombie_paine1(self); return end
    if self.inpain ~= 0 then
        -- if hit again in next gre seconds while not in pain frames, definitely drop
        self.pain_finished = quake.time() + 3
        -- currently going through an animation, don't change
        return
    end
    if self.pain_finished > quake.time() then
        -- hit again, so drop down
        self.inpain = 2
        zombie_paine1(self)
        return
    end
    -- gp into one of the fast pain animations
    self.inpain = 1
    local r = quake.random()
    if r < 0.25 then zombie_paina1(self)
    elseif r < 0.5 then zombie_painb1(self)
    elseif r < 0.75 then zombie_painc1(self)
    else zombie_paind1(self) end
end

--============================================================================

--[[QUAKED monster_zombie (1 0 0) (-16 -16 -24) (16 16 32) Crucified ambush

If crucified, stick the bounding box 12 pixels back into a wall to look right.
]]
function M.spawn(self)
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
    self.th_stand = zombie_stand1
    self.th_walk = zombie_walk1
    self.th_run = zombie_run1
    self.th_pain = zombie_pain
    self.th_die = zombie_die
    self.th_missile = zombie_missile
    if (self.spawnflags & SPAWN_CRUCIFIED) ~= 0 then
        self.movetype = C.MOVETYPE_NONE
        zombie_cruc1(self)
    else
        monsters.walk_start(self)
    end
end

quake.register_entity("monster_zombie", M.spawn)

return M
