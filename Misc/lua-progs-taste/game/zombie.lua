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

local zombie_stand = {}
zombie_stand[1] = animation.frame(f.stand1, function() return zombie_stand[2] end, ai.stand)
zombie_stand[2] = animation.frame(f.stand2, function() return zombie_stand[3] end, ai.stand)
zombie_stand[3] = animation.frame(f.stand3, function() return zombie_stand[4] end, ai.stand)
zombie_stand[4] = animation.frame(f.stand4, function() return zombie_stand[5] end, ai.stand)
zombie_stand[5] = animation.frame(f.stand5, function() return zombie_stand[6] end, ai.stand)
zombie_stand[6] = animation.frame(f.stand6, function() return zombie_stand[7] end, ai.stand)
zombie_stand[7] = animation.frame(f.stand7, function() return zombie_stand[8] end, ai.stand)
zombie_stand[8] = animation.frame(f.stand8, function() return zombie_stand[9] end, ai.stand)
zombie_stand[9] = animation.frame(f.stand9, function() return zombie_stand[10] end, ai.stand)
zombie_stand[10] = animation.frame(f.stand10, function() return zombie_stand[11] end, ai.stand)
zombie_stand[11] = animation.frame(f.stand11, function() return zombie_stand[12] end, ai.stand)
zombie_stand[12] = animation.frame(f.stand12, function() return zombie_stand[13] end, ai.stand)
zombie_stand[13] = animation.frame(f.stand13, function() return zombie_stand[14] end, ai.stand)
zombie_stand[14] = animation.frame(f.stand14, function() return zombie_stand[15] end, ai.stand)
zombie_stand[15] = animation.frame(f.stand15, function() return zombie_stand[1] end, ai.stand)

local zombie_cruc = {}
zombie_cruc[1] = animation.frame(f.cruc_1, function() return zombie_cruc[2] end, function(self) if quake.random() < 0.1 then quake.sound(self, C.CHAN_VOICE, "zombie/idle_w2.wav", 1, C.ATTN_STATIC) end end)
zombie_cruc[2] = animation.frame(f.cruc_2, function() return zombie_cruc[3] end, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end)
zombie_cruc[3] = animation.frame(f.cruc_3, function() return zombie_cruc[4] end, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end)
zombie_cruc[4] = animation.frame(f.cruc_4, function() return zombie_cruc[5] end, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end)
zombie_cruc[5] = animation.frame(f.cruc_5, function() return zombie_cruc[6] end, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end)
zombie_cruc[6] = animation.frame(f.cruc_6, function() return zombie_cruc[1] end, function(self) self.nextthink = quake.time() + 0.1 + quake.random() * 0.1 end)

local zombie_walk = {}
zombie_walk[1] = animation.frame(f.walk1, function() return zombie_walk[2] end, function(self) ai.walk(self, 0) end)
zombie_walk[2] = animation.frame(f.walk2, function() return zombie_walk[3] end, function(self) ai.walk(self, 2) end)
zombie_walk[3] = animation.frame(f.walk3, function() return zombie_walk[4] end, function(self) ai.walk(self, 3) end)
zombie_walk[4] = animation.frame(f.walk4, function() return zombie_walk[5] end, function(self) ai.walk(self, 2) end)
zombie_walk[5] = animation.frame(f.walk5, function() return zombie_walk[6] end, function(self) ai.walk(self, 1) end)
zombie_walk[6] = animation.frame(f.walk6, function() return zombie_walk[7] end, function(self) ai.walk(self, 0) end)
zombie_walk[7] = animation.frame(f.walk7, function() return zombie_walk[8] end, function(self) ai.walk(self, 0) end)
zombie_walk[8] = animation.frame(f.walk8, function() return zombie_walk[9] end, function(self) ai.walk(self, 0) end)
zombie_walk[9] = animation.frame(f.walk9, function() return zombie_walk[10] end, function(self) ai.walk(self, 0) end)
zombie_walk[10] = animation.frame(f.walk10, function() return zombie_walk[11] end, function(self) ai.walk(self, 0) end)
zombie_walk[11] = animation.frame(f.walk11, function() return zombie_walk[12] end, function(self) ai.walk(self, 2) end)
zombie_walk[12] = animation.frame(f.walk12, function() return zombie_walk[13] end, function(self) ai.walk(self, 2) end)
zombie_walk[13] = animation.frame(f.walk13, function() return zombie_walk[14] end, function(self) ai.walk(self, 1) end)
zombie_walk[14] = animation.frame(f.walk14, function() return zombie_walk[15] end, function(self) ai.walk(self, 0) end)
zombie_walk[15] = animation.frame(f.walk15, function() return zombie_walk[16] end, function(self) ai.walk(self, 0) end)
zombie_walk[16] = animation.frame(f.walk16, function() return zombie_walk[17] end, function(self) ai.walk(self, 0) end)
zombie_walk[17] = animation.frame(f.walk17, function() return zombie_walk[18] end, function(self) ai.walk(self, 0) end)
zombie_walk[18] = animation.frame(f.walk18, function() return zombie_walk[19] end, function(self) ai.walk(self, 0) end)
zombie_walk[19] = animation.frame(f.walk19, function() return zombie_walk[1] end, function(self) ai.walk(self, 0); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "zombie/z_idle.wav", 1, C.ATTN_IDLE) end end)

local zombie_run = {}
zombie_run[1] = animation.frame(f.run1, function() return zombie_run[2] end, function(self) ai.run(self, 1); self.inpain = 0 end)
zombie_run[2] = animation.frame(f.run2, function() return zombie_run[3] end, function(self) ai.run(self, 1) end)
zombie_run[3] = animation.frame(f.run3, function() return zombie_run[4] end, function(self) ai.run(self, 0) end)
zombie_run[4] = animation.frame(f.run4, function() return zombie_run[5] end, function(self) ai.run(self, 1) end)
zombie_run[5] = animation.frame(f.run5, function() return zombie_run[6] end, function(self) ai.run(self, 2) end)
zombie_run[6] = animation.frame(f.run6, function() return zombie_run[7] end, function(self) ai.run(self, 3) end)
zombie_run[7] = animation.frame(f.run7, function() return zombie_run[8] end, function(self) ai.run(self, 4) end)
zombie_run[8] = animation.frame(f.run8, function() return zombie_run[9] end, function(self) ai.run(self, 4) end)
zombie_run[9] = animation.frame(f.run9, function() return zombie_run[10] end, function(self) ai.run(self, 2) end)
zombie_run[10] = animation.frame(f.run10, function() return zombie_run[11] end, function(self) ai.run(self, 0) end)
zombie_run[11] = animation.frame(f.run11, function() return zombie_run[12] end, function(self) ai.run(self, 0) end)
zombie_run[12] = animation.frame(f.run12, function() return zombie_run[13] end, function(self) ai.run(self, 0) end)
zombie_run[13] = animation.frame(f.run13, function() return zombie_run[14] end, function(self) ai.run(self, 2) end)
zombie_run[14] = animation.frame(f.run14, function() return zombie_run[15] end, function(self) ai.run(self, 4) end)
zombie_run[15] = animation.frame(f.run15, function() return zombie_run[16] end, function(self) ai.run(self, 6) end)
zombie_run[16] = animation.frame(f.run16, function() return zombie_run[17] end, function(self) ai.run(self, 7) end)
zombie_run[17] = animation.frame(f.run17, function() return zombie_run[18] end, function(self) ai.run(self, 3) end)
zombie_run[18] = animation.frame(f.run18, function() return zombie_run[1] end, function(self) ai.run(self, 8); if quake.random() < 0.2 then quake.sound(self, C.CHAN_VOICE, "zombie/z_idle.wav", 1, C.ATTN_IDLE) end; if quake.random() > 0.8 then quake.sound(self, C.CHAN_VOICE, "zombie/z_idle1.wav", 1, C.ATTN_IDLE) end end)

--[[
=============================================================================

ATTACKS

=============================================================================
]]

---@param self entity
---@param other entity
---@return nil
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

local zombie_atta = {}
zombie_atta[1] = animation.frame(f.atta1, function() return zombie_atta[2] end, function(self) fight.face(self) end)
zombie_atta[2] = animation.frame(f.atta2, function() return zombie_atta[3] end, function(self) fight.face(self) end)
zombie_atta[3] = animation.frame(f.atta3, function() return zombie_atta[4] end, function(self) fight.face(self) end)
zombie_atta[4] = animation.frame(f.atta4, function() return zombie_atta[5] end, function(self) fight.face(self) end)
zombie_atta[5] = animation.frame(f.atta5, function() return zombie_atta[6] end, function(self) fight.face(self) end)
zombie_atta[6] = animation.frame(f.atta6, function() return zombie_atta[7] end, function(self) fight.face(self) end)
zombie_atta[7] = animation.frame(f.atta7, function() return zombie_atta[8] end, function(self) fight.face(self) end)
zombie_atta[8] = animation.frame(f.atta8, function() return zombie_atta[9] end, function(self) fight.face(self) end)
zombie_atta[9] = animation.frame(f.atta9, function() return zombie_atta[10] end, function(self) fight.face(self) end)
zombie_atta[10] = animation.frame(f.atta10, function() return zombie_atta[11] end, function(self) fight.face(self) end)
zombie_atta[11] = animation.frame(f.atta11, function() return zombie_atta[12] end, function(self) fight.face(self) end)
zombie_atta[12] = animation.frame(f.atta12, function() return zombie_atta[13] end, function(self) fight.face(self) end)
zombie_atta[13] = animation.frame(f.atta13, function() return zombie_run[1] end, function(self) fight.face(self); zombie_fire_grenade(self, quake.vec3(-10, -22, 30)) end)

local zombie_attb = {}
zombie_attb[1] = animation.frame(f.attb1, function() return zombie_attb[2] end, function(self) fight.face(self) end)
zombie_attb[2] = animation.frame(f.attb2, function() return zombie_attb[3] end, function(self) fight.face(self) end)
zombie_attb[3] = animation.frame(f.attb3, function() return zombie_attb[4] end, function(self) fight.face(self) end)
zombie_attb[4] = animation.frame(f.attb4, function() return zombie_attb[5] end, function(self) fight.face(self) end)
zombie_attb[5] = animation.frame(f.attb5, function() return zombie_attb[6] end, function(self) fight.face(self) end)
zombie_attb[6] = animation.frame(f.attb6, function() return zombie_attb[7] end, function(self) fight.face(self) end)
zombie_attb[7] = animation.frame(f.attb7, function() return zombie_attb[8] end, function(self) fight.face(self) end)
zombie_attb[8] = animation.frame(f.attb8, function() return zombie_attb[9] end, function(self) fight.face(self) end)
zombie_attb[9] = animation.frame(f.attb9, function() return zombie_attb[10] end, function(self) fight.face(self) end)
zombie_attb[10] = animation.frame(f.attb10, function() return zombie_attb[11] end, function(self) fight.face(self) end)
zombie_attb[11] = animation.frame(f.attb11, function() return zombie_attb[12] end, function(self) fight.face(self) end)
zombie_attb[12] = animation.frame(f.attb12, function() return zombie_attb[13] end, function(self) fight.face(self) end)
zombie_attb[13] = animation.frame(f.attb13, function() return zombie_attb[14] end, function(self) fight.face(self) end)
zombie_attb[14] = animation.frame(f.attb13, function() return zombie_run[1] end, function(self) fight.face(self); zombie_fire_grenade(self, quake.vec3(-10, -24, 29)) end)

local zombie_attc = {}
zombie_attc[1] = animation.frame(f.attc1, function() return zombie_attc[2] end, function(self) fight.face(self) end)
zombie_attc[2] = animation.frame(f.attc2, function() return zombie_attc[3] end, function(self) fight.face(self) end)
zombie_attc[3] = animation.frame(f.attc3, function() return zombie_attc[4] end, function(self) fight.face(self) end)
zombie_attc[4] = animation.frame(f.attc4, function() return zombie_attc[5] end, function(self) fight.face(self) end)
zombie_attc[5] = animation.frame(f.attc5, function() return zombie_attc[6] end, function(self) fight.face(self) end)
zombie_attc[6] = animation.frame(f.attc6, function() return zombie_attc[7] end, function(self) fight.face(self) end)
zombie_attc[7] = animation.frame(f.attc7, function() return zombie_attc[8] end, function(self) fight.face(self) end)
zombie_attc[8] = animation.frame(f.attc8, function() return zombie_attc[9] end, function(self) fight.face(self) end)
zombie_attc[9] = animation.frame(f.attc9, function() return zombie_attc[10] end, function(self) fight.face(self) end)
zombie_attc[10] = animation.frame(f.attc10, function() return zombie_attc[11] end, function(self) fight.face(self) end)
zombie_attc[11] = animation.frame(f.attc11, function() return zombie_attc[12] end, function(self) fight.face(self) end)
zombie_attc[12] = animation.frame(f.attc12, function() return zombie_run[1] end, function(self) fight.face(self); zombie_fire_grenade(self, quake.vec3(-12, -19, 29)) end)

---@param self entity
---@return nil
local function zombie_missile(self)
    local r = quake.random()
    if r < 0.3 then zombie_atta[1](self)
    elseif r < 0.6 then zombie_attb[1](self)
    else zombie_attc[1](self) end
end

--[[
=============================================================================

PAIN

=============================================================================
]]

local zombie_paina = {}
zombie_paina[1] = animation.frame(f.paina1, function() return zombie_paina[2] end, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain.wav", 1, C.ATTN_NORM) end)
zombie_paina[2] = animation.frame(f.paina2, function() return zombie_paina[3] end, function(self) ai.pain_forward(self, 3) end)
zombie_paina[3] = animation.frame(f.paina3, function() return zombie_paina[4] end, function(self) ai.pain_forward(self, 1) end)
zombie_paina[4] = animation.frame(f.paina4, function() return zombie_paina[5] end, function(self) ai.pain(self, 1) end)
zombie_paina[5] = animation.frame(f.paina5, function() return zombie_paina[6] end, function(self) ai.pain(self, 3) end)
zombie_paina[6] = animation.frame(f.paina6, function() return zombie_paina[7] end, function(self) ai.pain(self, 1) end)
zombie_paina[7] = animation.frame(f.paina7, function() return zombie_paina[8] end)
zombie_paina[8] = animation.frame(f.paina8, function() return zombie_paina[9] end)
zombie_paina[9] = animation.frame(f.paina9, function() return zombie_paina[10] end)
zombie_paina[10] = animation.frame(f.paina10, function() return zombie_paina[11] end)
zombie_paina[11] = animation.frame(f.paina11, function() return zombie_paina[12] end)
zombie_paina[12] = animation.frame(f.paina12, function() return zombie_run[1] end)

local zombie_painb = {}
zombie_painb[1] = animation.frame(f.painb1, function() return zombie_painb[2] end, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain1.wav", 1, C.ATTN_NORM) end)
zombie_painb[2] = animation.frame(f.painb2, function() return zombie_painb[3] end, function(self) ai.pain(self, 2) end)
zombie_painb[3] = animation.frame(f.painb3, function() return zombie_painb[4] end, function(self) ai.pain(self, 8) end)
zombie_painb[4] = animation.frame(f.painb4, function() return zombie_painb[5] end, function(self) ai.pain(self, 6) end)
zombie_painb[5] = animation.frame(f.painb5, function() return zombie_painb[6] end, function(self) ai.pain(self, 2) end)
zombie_painb[6] = animation.frame(f.painb6, function() return zombie_painb[7] end)
zombie_painb[7] = animation.frame(f.painb7, function() return zombie_painb[8] end)
zombie_painb[8] = animation.frame(f.painb8, function() return zombie_painb[9] end)
zombie_painb[9] = animation.frame(f.painb9, function() return zombie_painb[10] end, function(self) quake.sound(self, C.CHAN_BODY, "zombie/z_fall.wav", 1, C.ATTN_NORM) end)
zombie_painb[10] = animation.frame(f.painb10, function() return zombie_painb[11] end)
zombie_painb[11] = animation.frame(f.painb11, function() return zombie_painb[12] end)
zombie_painb[12] = animation.frame(f.painb12, function() return zombie_painb[13] end)
zombie_painb[13] = animation.frame(f.painb13, function() return zombie_painb[14] end)
zombie_painb[14] = animation.frame(f.painb14, function() return zombie_painb[15] end)
zombie_painb[15] = animation.frame(f.painb15, function() return zombie_painb[16] end)
zombie_painb[16] = animation.frame(f.painb16, function() return zombie_painb[17] end)
zombie_painb[17] = animation.frame(f.painb17, function() return zombie_painb[18] end)
zombie_painb[18] = animation.frame(f.painb18, function() return zombie_painb[19] end)
zombie_painb[19] = animation.frame(f.painb19, function() return zombie_painb[20] end)
zombie_painb[20] = animation.frame(f.painb20, function() return zombie_painb[21] end)
zombie_painb[21] = animation.frame(f.painb21, function() return zombie_painb[22] end)
zombie_painb[22] = animation.frame(f.painb22, function() return zombie_painb[23] end)
zombie_painb[23] = animation.frame(f.painb23, function() return zombie_painb[24] end)
zombie_painb[24] = animation.frame(f.painb24, function() return zombie_painb[25] end)
zombie_painb[25] = animation.frame(f.painb25, function() return zombie_painb[26] end, function(self) ai.pain_forward(self, 1) end)
zombie_painb[26] = animation.frame(f.painb26, function() return zombie_painb[27] end)
zombie_painb[27] = animation.frame(f.painb27, function() return zombie_painb[28] end)
zombie_painb[28] = animation.frame(f.painb28, function() return zombie_run[1] end)

local zombie_painc = {}
zombie_painc[1] = animation.frame(f.painc1, function() return zombie_painc[2] end, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain1.wav", 1, C.ATTN_NORM) end)
zombie_painc[2] = animation.frame(f.painc2, function() return zombie_painc[3] end)
zombie_painc[3] = animation.frame(f.painc3, function() return zombie_painc[4] end, function(self) ai.pain(self, 3) end)
zombie_painc[4] = animation.frame(f.painc4, function() return zombie_painc[5] end, function(self) ai.pain(self, 1) end)
zombie_painc[5] = animation.frame(f.painc5, function() return zombie_painc[6] end)
zombie_painc[6] = animation.frame(f.painc6, function() return zombie_painc[7] end)
zombie_painc[7] = animation.frame(f.painc7, function() return zombie_painc[8] end)
zombie_painc[8] = animation.frame(f.painc8, function() return zombie_painc[9] end)
zombie_painc[9] = animation.frame(f.painc9, function() return zombie_painc[10] end)
zombie_painc[10] = animation.frame(f.painc10, function() return zombie_painc[11] end)
zombie_painc[11] = animation.frame(f.painc11, function() return zombie_painc[12] end, function(self) ai.pain_forward(self, 1) end)
zombie_painc[12] = animation.frame(f.painc12, function() return zombie_painc[13] end, function(self) ai.pain_forward(self, 1) end)
zombie_painc[13] = animation.frame(f.painc13, function() return zombie_painc[14] end)
zombie_painc[14] = animation.frame(f.painc14, function() return zombie_painc[15] end)
zombie_painc[15] = animation.frame(f.painc15, function() return zombie_painc[16] end)
zombie_painc[16] = animation.frame(f.painc16, function() return zombie_painc[17] end)
zombie_painc[17] = animation.frame(f.painc17, function() return zombie_painc[18] end)
zombie_painc[18] = animation.frame(f.painc18, function() return zombie_run[1] end)

local zombie_paind = {}
zombie_paind[1] = animation.frame(f.paind1, function() return zombie_paind[2] end, function(self) quake.sound(self, C.CHAN_VOICE, "zombie/z_pain.wav", 1, C.ATTN_NORM) end)
zombie_paind[2] = animation.frame(f.paind2, function() return zombie_paind[3] end)
zombie_paind[3] = animation.frame(f.paind3, function() return zombie_paind[4] end)
zombie_paind[4] = animation.frame(f.paind4, function() return zombie_paind[5] end)
zombie_paind[5] = animation.frame(f.paind5, function() return zombie_paind[6] end)
zombie_paind[6] = animation.frame(f.paind6, function() return zombie_paind[7] end)
zombie_paind[7] = animation.frame(f.paind7, function() return zombie_paind[8] end)
zombie_paind[8] = animation.frame(f.paind8, function() return zombie_paind[9] end)
zombie_paind[9] = animation.frame(f.paind9, function() return zombie_paind[10] end, function(self) ai.pain(self, 1) end)
zombie_paind[10] = animation.frame(f.paind10, function() return zombie_paind[11] end)
zombie_paind[11] = animation.frame(f.paind11, function() return zombie_paind[12] end)
zombie_paind[12] = animation.frame(f.paind12, function() return zombie_paind[13] end)
zombie_paind[13] = animation.frame(f.paind13, function() return zombie_run[1] end)

local zombie_paine = {}
zombie_paine[1] = animation.frame(f.paine1, function() return zombie_paine[2] end, function(self)
        quake.sound(self, C.CHAN_VOICE, "zombie/z_pain.wav", 1, C.ATTN_NORM)
        self.health = 60
    end)
zombie_paine[2] = animation.frame(f.paine2, function() return zombie_paine[3] end, function(self)
        ai.pain(self, 8)
    end)
zombie_paine[3] = animation.frame(f.paine3, function() return zombie_paine[4] end, function(self)
        ai.pain(self, 5)
    end)
zombie_paine[4] = animation.frame(f.paine4, function() return zombie_paine[5] end, function(self)
        ai.pain(self, 3)
    end)
zombie_paine[5] = animation.frame(f.paine5, function() return zombie_paine[6] end, function(self)
        ai.pain(self, 1)
    end)
zombie_paine[6] = animation.frame(f.paine6, function() return zombie_paine[7] end, function(self)
        ai.pain(self, 2)
    end)
zombie_paine[7] = animation.frame(f.paine7, function() return zombie_paine[8] end, function(self)
        ai.pain(self, 1)
    end)
zombie_paine[8] = animation.frame(f.paine8, function() return zombie_paine[9] end, function(self)
        ai.pain(self, 1)
    end)
zombie_paine[9] = animation.frame(f.paine9, function() return zombie_paine[10] end, function(self)
        ai.pain(self, 2)
    end)
zombie_paine[10] = animation.frame(f.paine10, function() return zombie_paine[11] end, function(self)
        quake.sound(self, C.CHAN_BODY, "zombie/z_fall.wav", 1, C.ATTN_NORM)
        self.solid = C.SOLID_NOT
    end)
zombie_paine[11] = animation.frame(f.paine11, function() return zombie_paine[12] end, function(self)
        self.nextthink = self.nextthink + 5
        self.health = 60
    end)
zombie_paine[12] = animation.frame(f.paine12, function() return zombie_paine[13] end, function(self)
        -- see if ok to stand up
        self.health = 60
        quake.sound(self, C.CHAN_VOICE, "zombie/z_idle.wav", 1, C.ATTN_IDLE)
        self.solid = C.SOLID_SLIDEBOX
        if not quake.walk_move(self, 0, 0) then self.think = zombie_paine[11]; self.solid = C.SOLID_NOT; return end
    end)
zombie_paine[13] = animation.frame(f.paine13, function() return zombie_paine[14] end)
zombie_paine[14] = animation.frame(f.paine14, function() return zombie_paine[15] end)
zombie_paine[15] = animation.frame(f.paine15, function() return zombie_paine[16] end)
zombie_paine[16] = animation.frame(f.paine16, function() return zombie_paine[17] end)
zombie_paine[17] = animation.frame(f.paine17, function() return zombie_paine[18] end)
zombie_paine[18] = animation.frame(f.paine18, function() return zombie_paine[19] end)
zombie_paine[19] = animation.frame(f.paine19, function() return zombie_paine[20] end)
zombie_paine[20] = animation.frame(f.paine20, function() return zombie_paine[21] end)
zombie_paine[21] = animation.frame(f.paine21, function() return zombie_paine[22] end)
zombie_paine[22] = animation.frame(f.paine22, function() return zombie_paine[23] end)
zombie_paine[23] = animation.frame(f.paine23, function() return zombie_paine[24] end)
zombie_paine[24] = animation.frame(f.paine24, function() return zombie_paine[25] end)
zombie_paine[25] = animation.frame(f.paine25, function() return zombie_paine[26] end, function(self)
        ai.pain_forward(self, 5)
    end)
zombie_paine[26] = animation.frame(f.paine26, function() return zombie_paine[27] end, function(self)
        ai.pain_forward(self, 3)
    end)
zombie_paine[27] = animation.frame(f.paine27, function() return zombie_paine[28] end, function(self)
        ai.pain_forward(self, 1)
    end)
zombie_paine[28] = animation.frame(f.paine28, function() return zombie_paine[29] end, function(self)
        ai.pain(self, 1)
    end)
zombie_paine[29] = animation.frame(f.paine29, function() return zombie_paine[30] end)
zombie_paine[30] = animation.frame(f.paine30, function() return zombie_run[1] end)

---@param self entity
---@return nil
local function zombie_die(self)
    quake.sound(self, C.CHAN_VOICE, "zombie/z_gib.wav", 1, C.ATTN_NORM)
    gibs.throw_head(self, "progs/h_zombie.mdl", self.health)
    gibs.throw(self, "progs/gib1.mdl", self.health)
    gibs.throw(self, "progs/gib2.mdl", self.health)
    gibs.throw(self, "progs/gib3.mdl", self.health)
end

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
local function zombie_pain(self, _attacker, take)
    -- always reset health
    self.health = 60
    if take < 9 then return end -- totally ignore
    if self.inpain == 2 then return end -- down on ground, so don't reset any counters
    -- go down immediately if a big enough hit
    if take >= 25 then self.inpain = 2; zombie_paine[1](self); return end
    if self.inpain ~= 0 then
        -- if hit again in next gre seconds while not in pain frames, definitely drop
        self.pain_finished = quake.time() + 3
        -- currently going through an animation, don't change
        return
    end
    if self.pain_finished > quake.time() then
        -- hit again, so drop down
        self.inpain = 2
        zombie_paine[1](self)
        return
    end
    -- gp into one of the fast pain animations
    self.inpain = 1
    local r = quake.random()
    if r < 0.25 then zombie_paina[1](self)
    elseif r < 0.5 then zombie_painb[1](self)
    elseif r < 0.75 then zombie_painc[1](self)
    else zombie_paind[1](self) end
end

--============================================================================

---QUAKED monster_zombie (1 0 0) (-16 -16 -24) (16 16 32) Crucified ambush
---
---If crucified, stick the bounding box 12 pixels back into a wall to look right.
---@param self entity
---@return nil
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
    self.th_stand = zombie_stand[1]
    self.th_walk = zombie_walk[1]
    self.th_run = zombie_run[1]
    self.th_pain = zombie_pain
    self.th_die = zombie_die
    self.th_missile = zombie_missile
    if (self.spawnflags & SPAWN_CRUCIFIED) ~= 0 then
        self.movetype = C.MOVETYPE_NONE
        zombie_cruc[1](self)
    else
        monsters.walk_start(self)
    end
end

quake.register_entity("monster_zombie", M.spawn)

return M
