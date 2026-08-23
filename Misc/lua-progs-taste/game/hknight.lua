-- Port of hknight.qc from GPL-licensed CleanFixedQuakeC.
-- SPDX-License-Identifier: GPL-2.0-or-later

--[[  Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
]]

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

f.stand1, f.stand2, f.stand3, f.stand4, f.stand5, f.stand6,
    f.stand7, f.stand8, f.stand9 = count(9)

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
    f.walk7, f.walk8, f.walk9, f.walk10, f.walk11, f.walk12,
    f.walk13, f.walk14, f.walk15, f.walk16, f.walk17, f.walk18,
    f.walk19, f.walk20 = count(20)

f.run1, f.run2, f.run3, f.run4, f.run5, f.run6,
    f.run7, f.run8 = count(8)

f.pain1, f.pain2, f.pain3, f.pain4, f.pain5 = count(5)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
    f.death7, f.death8, f.death9, f.death10, f.death11, f.death12 = count(12)

f.deathb1, f.deathb2, f.deathb3, f.deathb4, f.deathb5, f.deathb6,
    f.deathb7, f.deathb8, f.deathb9 = count(9)

f.char_a1, f.char_a2, f.char_a3, f.char_a4, f.char_a5, f.char_a6,
    f.char_a7, f.char_a8, f.char_a9, f.char_a10, f.char_a11, f.char_a12,
    f.char_a13, f.char_a14, f.char_a15, f.char_a16 = count(16)

f.magica1, f.magica2, f.magica3, f.magica4, f.magica5, f.magica6,
    f.magica7, f.magica8, f.magica9, f.magica10, f.magica11, f.magica12,
    f.magica13, f.magica14 = count(14)

f.magicb1, f.magicb2, f.magicb3, f.magicb4, f.magicb5, f.magicb6,
    f.magicb7, f.magicb8, f.magicb9, f.magicb10, f.magicb11, f.magicb12,
    f.magicb13 = count(13)

f.char_b1, f.char_b2, f.char_b3, f.char_b4, f.char_b5, f.char_b6 = count(6)

f.slice1, f.slice2, f.slice3, f.slice4, f.slice5, f.slice6,
    f.slice7, f.slice8, f.slice9, f.slice10 = count(10)

f.smash1, f.smash2, f.smash3, f.smash4, f.smash5, f.smash6,
    f.smash7, f.smash8, f.smash9, f.smash10, f.smash11 = count(11)

f.w_attack1, f.w_attack2, f.w_attack3, f.w_attack4, f.w_attack5, f.w_attack6,
    f.w_attack7, f.w_attack8, f.w_attack9, f.w_attack10, f.w_attack11, f.w_attack12,
    f.w_attack13, f.w_attack14, f.w_attack15, f.w_attack16, f.w_attack17, f.w_attack18,
    f.w_attack19, f.w_attack20, f.w_attack21, f.w_attack22 = count(22)

f.magicc1, f.magicc2, f.magicc3, f.magicc4, f.magicc5, f.magicc6,
    f.magicc7, f.magicc8, f.magicc9, f.magicc10, f.magicc11 = count(11)

local CHAN_WEAPON = 1

--[[
==============================================================================

KNIGHT (Hell Knight)

==============================================================================
]]

local hknight_char_a = {}
local hknight_run = {}
local hk_idle_sound

---@param self entity
---@param offset number
---@return nil
local function hknight_shot(self, offset)
    local offang = quake.vector_to_angles(self.enemy.origin - self.origin)
    offang = quake.vec3(offang.x, offang.y + offset * 6, offang.z)

    local vectors = quake.make_vectors(offang)

    local org = self.origin + self.mins + self.size * 0.5 + vectors.forward * 20

    -- set missile speed
    local vec = vectors.forward:normalized()
    vec = quake.vec3(vec.x, vec.y, 0 - vec.z + (quake.random() - 0.5) * 0.1)

    local newmis = weapons.launch_spike(self, org, vec)
    newmis.classname = "knightspike"
    quake.set_model(newmis, "progs/k_spike.mdl")
    quake.set_size(newmis, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    newmis.velocity = vec * 300
    quake.sound(self, CHAN_WEAPON, "hknight/attack1.wav", 1, C.ATTN_NORM)
end

---@param self entity
---@return nil
local function check_for_charge(self)
    -- check for mad charge
    if not quake.globals.enemy_vis then
        return
    end
    if quake.time() < self.attack_finished then
        return
    end
    if math.abs(self.origin.z - self.enemy.origin.z) > 20 then
        -- too much height change
        return
    end
    if (self.origin - self.enemy.origin):length() < 80 then
        -- use regular attack
        return
    end

    -- charge
    subs.attack_finished(self, 2)
    hknight_char_a[1](self)
end

---@param self entity
---@return nil
local function check_continue_charge(self)
    if quake.time() > self.attack_finished then
        subs.attack_finished(self, 3)
        hknight_run[1](self)
        return -- done charging
    end
    if quake.random() > 0.5 then
        quake.sound(self, CHAN_WEAPON, "knight/sword2.wav", 1, C.ATTN_NORM)
    else
        quake.sound(self, CHAN_WEAPON, "knight/sword1.wav", 1, C.ATTN_NORM)
    end
end

--===========================================================================

local hknight_stand = {}
hknight_stand[1] = animation.frame(f.stand1, function() return hknight_stand[2] end, ai.stand)
hknight_stand[2] = animation.frame(f.stand2, function() return hknight_stand[3] end, ai.stand)
hknight_stand[3] = animation.frame(f.stand3, function() return hknight_stand[4] end, ai.stand)
hknight_stand[4] = animation.frame(f.stand4, function() return hknight_stand[5] end, ai.stand)
hknight_stand[5] = animation.frame(f.stand5, function() return hknight_stand[6] end, ai.stand)
hknight_stand[6] = animation.frame(f.stand6, function() return hknight_stand[7] end, ai.stand)
hknight_stand[7] = animation.frame(f.stand7, function() return hknight_stand[8] end, ai.stand)
hknight_stand[8] = animation.frame(f.stand8, function() return hknight_stand[9] end, ai.stand)
hknight_stand[9] = animation.frame(f.stand9, function() return hknight_stand[1] end, ai.stand)

--===========================================================================

local hknight_walk = {}
hknight_walk[1] = animation.frame(f.walk1, function() return hknight_walk[2] end, function(self)
    hk_idle_sound(self)
    ai.walk(self, 2)
end)
hknight_walk[2] = animation.frame(f.walk2, function() return hknight_walk[3] end, function(self) ai.walk(self, 5) end)
hknight_walk[3] = animation.frame(f.walk3, function() return hknight_walk[4] end, function(self) ai.walk(self, 5) end)
hknight_walk[4] = animation.frame(f.walk4, function() return hknight_walk[5] end, function(self) ai.walk(self, 4) end)
hknight_walk[5] = animation.frame(f.walk5, function() return hknight_walk[6] end, function(self) ai.walk(self, 4) end)
hknight_walk[6] = animation.frame(f.walk6, function() return hknight_walk[7] end, function(self) ai.walk(self, 2) end)
hknight_walk[7] = animation.frame(f.walk7, function() return hknight_walk[8] end, function(self) ai.walk(self, 2) end)
hknight_walk[8] = animation.frame(f.walk8, function() return hknight_walk[9] end, function(self) ai.walk(self, 3) end)
hknight_walk[9] = animation.frame(f.walk9, function() return hknight_walk[10] end, function(self) ai.walk(self, 3) end)
hknight_walk[10] = animation.frame(f.walk10, function() return hknight_walk[11] end, function(self) ai.walk(self, 4) end)
hknight_walk[11] = animation.frame(f.walk11, function() return hknight_walk[12] end, function(self) ai.walk(self, 3) end)
hknight_walk[12] = animation.frame(f.walk12, function() return hknight_walk[13] end, function(self) ai.walk(self, 4) end)
hknight_walk[13] = animation.frame(f.walk13, function() return hknight_walk[14] end, function(self) ai.walk(self, 6) end)
hknight_walk[14] = animation.frame(f.walk14, function() return hknight_walk[15] end, function(self) ai.walk(self, 2) end)
hknight_walk[15] = animation.frame(f.walk15, function() return hknight_walk[16] end, function(self) ai.walk(self, 2) end)
hknight_walk[16] = animation.frame(f.walk16, function() return hknight_walk[17] end, function(self) ai.walk(self, 4) end)
hknight_walk[17] = animation.frame(f.walk17, function() return hknight_walk[18] end, function(self) ai.walk(self, 3) end)
hknight_walk[18] = animation.frame(f.walk18, function() return hknight_walk[19] end, function(self) ai.walk(self, 3) end)
hknight_walk[19] = animation.frame(f.walk19, function() return hknight_walk[20] end, function(self) ai.walk(self, 3) end)
hknight_walk[20] = animation.frame(f.walk20, function() return hknight_walk[1] end, function(self) ai.walk(self, 2) end)

--===========================================================================

hknight_run[1] = animation.frame(f.run1, function() return hknight_run[2] end, function(self)
    hk_idle_sound(self)
    ai.run(self, 20)
    check_for_charge(self)
end)
hknight_run[2] = animation.frame(f.run2, function() return hknight_run[3] end, function(self) ai.run(self, 25) end)
hknight_run[3] = animation.frame(f.run3, function() return hknight_run[4] end, function(self) ai.run(self, 18) end)
hknight_run[4] = animation.frame(f.run4, function() return hknight_run[5] end, function(self) ai.run(self, 16) end)
hknight_run[5] = animation.frame(f.run5, function() return hknight_run[6] end, function(self) ai.run(self, 14) end)
hknight_run[6] = animation.frame(f.run6, function() return hknight_run[7] end, function(self) ai.run(self, 25) end)
hknight_run[7] = animation.frame(f.run7, function() return hknight_run[8] end, function(self) ai.run(self, 21) end)
hknight_run[8] = animation.frame(f.run8, function() return hknight_run[1] end, function(self) ai.run(self, 13) end)

--============================================================================

local hknight_pain = {}
hknight_pain[1] = animation.frame(f.pain1, function() return hknight_pain[2] end, function(self) quake.sound(self, C.CHAN_VOICE, "hknight/pain1.wav", 1, C.ATTN_NORM) end)
hknight_pain[2] = animation.frame(f.pain2, function() return hknight_pain[3] end)
hknight_pain[3] = animation.frame(f.pain3, function() return hknight_pain[4] end)
hknight_pain[4] = animation.frame(f.pain4, function() return hknight_pain[5] end)
hknight_pain[5] = animation.frame(f.pain5, function() return hknight_run[1] end)

--============================================================================

local hknight_die = {}
hknight_die[1] = animation.frame(f.death1, function() return hknight_die[2] end, function(self) quake.walk_move(self, self.angles.y, 10) end)
hknight_die[2] = animation.frame(f.death2, function() return hknight_die[3] end, function(self) quake.walk_move(self, self.angles.y, 8) end)
hknight_die[3] = animation.frame(f.death3, function() return hknight_die[4] end, function(self)
    self.solid = C.SOLID_NOT
    quake.walk_move(self, self.angles.y, 7)
end)
hknight_die[4] = animation.frame(f.death4, function() return hknight_die[5] end)
hknight_die[5] = animation.frame(f.death5, function() return hknight_die[6] end)
hknight_die[6] = animation.frame(f.death6, function() return hknight_die[7] end)
hknight_die[7] = animation.frame(f.death7, function() return hknight_die[8] end)
hknight_die[8] = animation.frame(f.death8, function() return hknight_die[9] end, function(self) quake.walk_move(self, self.angles.y, 10) end)
hknight_die[9] = animation.frame(f.death9, function() return hknight_die[10] end, function(self) quake.walk_move(self, self.angles.y, 11) end)
hknight_die[10] = animation.frame(f.death10, function() return hknight_die[11] end)
hknight_die[11] = animation.frame(f.death11, function() return hknight_die[12] end)
hknight_die[12] = animation.frame(f.death12, function() return hknight_die[12] end)

local hknight_dieb = {}
hknight_dieb[1] = animation.frame(f.deathb1, function() return hknight_dieb[2] end)
hknight_dieb[2] = animation.frame(f.deathb2, function() return hknight_dieb[3] end)
hknight_dieb[3] = animation.frame(f.deathb3, function() return hknight_dieb[4] end, function(self) self.solid = C.SOLID_NOT end)
hknight_dieb[4] = animation.frame(f.deathb4, function() return hknight_dieb[5] end)
hknight_dieb[5] = animation.frame(f.deathb5, function() return hknight_dieb[6] end)
hknight_dieb[6] = animation.frame(f.deathb6, function() return hknight_dieb[7] end)
hknight_dieb[7] = animation.frame(f.deathb7, function() return hknight_dieb[8] end)
hknight_dieb[8] = animation.frame(f.deathb8, function() return hknight_dieb[9] end)
hknight_dieb[9] = animation.frame(f.deathb9, function() return hknight_dieb[9] end)

---@param self entity
---@return nil
local function hknight_die_handler(self)
    -- check for gib
    if self.health < -40 then
        quake.sound(self, C.CHAN_VOICE, "player/udeath.wav", 1, C.ATTN_NORM)
        gibs.throw_head(self, "progs/h_hellkn.mdl", self.health)
        gibs.throw(self, "progs/gib1.mdl", self.health)
        gibs.throw(self, "progs/gib2.mdl", self.health)
        gibs.throw(self, "progs/gib3.mdl", self.health)
        return
    end

    -- regular death
    quake.sound(self, C.CHAN_VOICE, "hknight/death1.wav", 1, C.ATTN_NORM)
    if quake.random() > 0.5 then
        hknight_die[1](self)
    else
        hknight_dieb[1](self)
    end
end

--============================================================================

local hknight_magica = {}
hknight_magica[1] = animation.frame(f.magica1, function() return hknight_magica[2] end, fight.face)
hknight_magica[2] = animation.frame(f.magica2, function() return hknight_magica[3] end, fight.face)
hknight_magica[3] = animation.frame(f.magica3, function() return hknight_magica[4] end, fight.face)
hknight_magica[4] = animation.frame(f.magica4, function() return hknight_magica[5] end, fight.face)
hknight_magica[5] = animation.frame(f.magica5, function() return hknight_magica[6] end, fight.face)
hknight_magica[6] = animation.frame(f.magica6, function() return hknight_magica[7] end, fight.face)
hknight_magica[7] = animation.frame(f.magica7, function() return hknight_magica[8] end, function(self) hknight_shot(self, -2) end)
hknight_magica[8] = animation.frame(f.magica8, function() return hknight_magica[9] end, function(self) hknight_shot(self, -1) end)
hknight_magica[9] = animation.frame(f.magica9, function() return hknight_magica[10] end, function(self) hknight_shot(self, 0) end)
hknight_magica[10] = animation.frame(f.magica10, function() return hknight_magica[11] end, function(self) hknight_shot(self, 1) end)
hknight_magica[11] = animation.frame(f.magica11, function() return hknight_magica[12] end, function(self) hknight_shot(self, 2) end)
hknight_magica[12] = animation.frame(f.magica12, function() return hknight_magica[13] end, function(self) hknight_shot(self, 3) end)
hknight_magica[13] = animation.frame(f.magica13, function() return hknight_magica[14] end, fight.face)
hknight_magica[14] = animation.frame(f.magica14, function() return hknight_run[1] end, fight.face)

--============================================================================

local hknight_magicb = {}
hknight_magicb[1] = animation.frame(f.magicb1, function() return hknight_magicb[2] end, fight.face)
hknight_magicb[2] = animation.frame(f.magicb2, function() return hknight_magicb[3] end, fight.face)
hknight_magicb[3] = animation.frame(f.magicb3, function() return hknight_magicb[4] end, fight.face)
hknight_magicb[4] = animation.frame(f.magicb4, function() return hknight_magicb[5] end, fight.face)
hknight_magicb[5] = animation.frame(f.magicb5, function() return hknight_magicb[6] end, fight.face)
hknight_magicb[6] = animation.frame(f.magicb6, function() return hknight_magicb[7] end, fight.face)
hknight_magicb[7] = animation.frame(f.magicb7, function() return hknight_magicb[8] end, function(self) hknight_shot(self, -2) end)
hknight_magicb[8] = animation.frame(f.magicb8, function() return hknight_magicb[9] end, function(self) hknight_shot(self, -1) end)
hknight_magicb[9] = animation.frame(f.magicb9, function() return hknight_magicb[10] end, function(self) hknight_shot(self, 0) end)
hknight_magicb[10] = animation.frame(f.magicb10, function() return hknight_magicb[11] end, function(self) hknight_shot(self, 1) end)
hknight_magicb[11] = animation.frame(f.magicb11, function() return hknight_magicb[12] end, function(self) hknight_shot(self, 2) end)
hknight_magicb[12] = animation.frame(f.magicb12, function() return hknight_magicb[13] end, function(self) hknight_shot(self, 3) end)
hknight_magicb[13] = animation.frame(f.magicb13, function() return hknight_run[1] end, fight.face)

--============================================================================

local hknight_magicc = {}
hknight_magicc[1] = animation.frame(f.magicc1, function() return hknight_magicc[2] end, fight.face)
hknight_magicc[2] = animation.frame(f.magicc2, function() return hknight_magicc[3] end, fight.face)
hknight_magicc[3] = animation.frame(f.magicc3, function() return hknight_magicc[4] end, fight.face)
hknight_magicc[4] = animation.frame(f.magicc4, function() return hknight_magicc[5] end, fight.face)
hknight_magicc[5] = animation.frame(f.magicc5, function() return hknight_magicc[6] end, fight.face)
hknight_magicc[6] = animation.frame(f.magicc6, function() return hknight_magicc[7] end, function(self) hknight_shot(self, -2) end)
hknight_magicc[7] = animation.frame(f.magicc7, function() return hknight_magicc[8] end, function(self) hknight_shot(self, -1) end)
hknight_magicc[8] = animation.frame(f.magicc8, function() return hknight_magicc[9] end, function(self) hknight_shot(self, 0) end)
hknight_magicc[9] = animation.frame(f.magicc9, function() return hknight_magicc[10] end, function(self) hknight_shot(self, 1) end)
hknight_magicc[10] = animation.frame(f.magicc10, function() return hknight_magicc[11] end, function(self) hknight_shot(self, 2) end)
hknight_magicc[11] = animation.frame(f.magicc11, function() return hknight_run[1] end, function(self) hknight_shot(self, 3) end)

--===========================================================================

hknight_char_a[1] = animation.frame(f.char_a1, function() return hknight_char_a[2] end, function(self) fight.charge(self, 20) end)
hknight_char_a[2] = animation.frame(f.char_a2, function() return hknight_char_a[3] end, function(self) fight.charge(self, 25) end)
hknight_char_a[3] = animation.frame(f.char_a3, function() return hknight_char_a[4] end, function(self) fight.charge(self, 18) end)
hknight_char_a[4] = animation.frame(f.char_a4, function() return hknight_char_a[5] end, function(self) fight.charge(self, 16) end)
hknight_char_a[5] = animation.frame(f.char_a5, function() return hknight_char_a[6] end, function(self) fight.charge(self, 14) end)
hknight_char_a[6] = animation.frame(f.char_a6, function() return hknight_char_a[7] end, function(self) fight.charge(self, 20); fight.melee(self) end)
hknight_char_a[7] = animation.frame(f.char_a7, function() return hknight_char_a[8] end, function(self) fight.charge(self, 21); fight.melee(self) end)
hknight_char_a[8] = animation.frame(f.char_a8, function() return hknight_char_a[9] end, function(self) fight.charge(self, 13); fight.melee(self) end)
hknight_char_a[9] = animation.frame(f.char_a9, function() return hknight_char_a[10] end, function(self) fight.charge(self, 20); fight.melee(self) end)
hknight_char_a[10] = animation.frame(f.char_a10, function() return hknight_char_a[11] end, function(self) fight.charge(self, 20); fight.melee(self) end)
hknight_char_a[11] = animation.frame(f.char_a11, function() return hknight_char_a[12] end, function(self) fight.charge(self, 18); fight.melee(self) end)
hknight_char_a[12] = animation.frame(f.char_a12, function() return hknight_char_a[13] end, function(self) fight.charge(self, 16) end)
hknight_char_a[13] = animation.frame(f.char_a13, function() return hknight_char_a[14] end, function(self) fight.charge(self, 14) end)
hknight_char_a[14] = animation.frame(f.char_a14, function() return hknight_char_a[15] end, function(self) fight.charge(self, 25) end)
hknight_char_a[15] = animation.frame(f.char_a15, function() return hknight_char_a[16] end, function(self) fight.charge(self, 21) end)
hknight_char_a[16] = animation.frame(f.char_a16, function() return hknight_run[1] end, function(self) fight.charge(self, 13) end)

--===========================================================================

local hknight_char_b = {}
hknight_char_b[1] = animation.frame(f.char_b1, function() return hknight_char_b[2] end, function(self)
    check_continue_charge(self)
    fight.charge(self, 23)
    fight.melee(self)
end)
hknight_char_b[2] = animation.frame(f.char_b2, function() return hknight_char_b[3] end, function(self) fight.charge(self, 17); fight.melee(self) end)
hknight_char_b[3] = animation.frame(f.char_b3, function() return hknight_char_b[4] end, function(self) fight.charge(self, 12); fight.melee(self) end)
hknight_char_b[4] = animation.frame(f.char_b4, function() return hknight_char_b[5] end, function(self) fight.charge(self, 22); fight.melee(self) end)
hknight_char_b[5] = animation.frame(f.char_b5, function() return hknight_char_b[6] end, function(self) fight.charge(self, 18); fight.melee(self) end)
hknight_char_b[6] = animation.frame(f.char_b6, function() return hknight_char_b[1] end, function(self) fight.charge(self, 8); fight.melee(self) end)

--===========================================================================

local hknight_slice = {}
hknight_slice[1] = animation.frame(f.slice1, function() return hknight_slice[2] end, function(self) fight.charge(self, 9) end)
hknight_slice[2] = animation.frame(f.slice2, function() return hknight_slice[3] end, function(self) fight.charge(self, 6) end)
hknight_slice[3] = animation.frame(f.slice3, function() return hknight_slice[4] end, function(self) fight.charge(self, 13) end)
hknight_slice[4] = animation.frame(f.slice4, function() return hknight_slice[5] end, function(self) fight.charge(self, 4) end)
hknight_slice[5] = animation.frame(f.slice5, function() return hknight_slice[6] end, function(self) fight.charge(self, 7); fight.melee(self) end)
hknight_slice[6] = animation.frame(f.slice6, function() return hknight_slice[7] end, function(self) fight.charge(self, 15); fight.melee(self) end)
hknight_slice[7] = animation.frame(f.slice7, function() return hknight_slice[8] end, function(self) fight.charge(self, 8); fight.melee(self) end)
hknight_slice[8] = animation.frame(f.slice8, function() return hknight_slice[9] end, function(self) fight.charge(self, 2); fight.melee(self) end)
hknight_slice[9] = animation.frame(f.slice9, function() return hknight_slice[10] end, function(self) fight.melee(self) end)
hknight_slice[10] = animation.frame(f.slice10, function() return hknight_run[1] end, function(self) fight.charge(self, 3) end)

--===========================================================================

local hknight_smash = {}
hknight_smash[1] = animation.frame(f.smash1, function() return hknight_smash[2] end, function(self) fight.charge(self, 1) end)
hknight_smash[2] = animation.frame(f.smash2, function() return hknight_smash[3] end, function(self) fight.charge(self, 13) end)
hknight_smash[3] = animation.frame(f.smash3, function() return hknight_smash[4] end, function(self) fight.charge(self, 9) end)
hknight_smash[4] = animation.frame(f.smash4, function() return hknight_smash[5] end, function(self) fight.charge(self, 11) end)
hknight_smash[5] = animation.frame(f.smash5, function() return hknight_smash[6] end, function(self) fight.charge(self, 10); fight.melee(self) end)
hknight_smash[6] = animation.frame(f.smash6, function() return hknight_smash[7] end, function(self) fight.charge(self, 7); fight.melee(self) end)
hknight_smash[7] = animation.frame(f.smash7, function() return hknight_smash[8] end, function(self) fight.charge(self, 12); fight.melee(self) end)
hknight_smash[8] = animation.frame(f.smash8, function() return hknight_smash[9] end, function(self) fight.charge(self, 2); fight.melee(self) end)
hknight_smash[9] = animation.frame(f.smash9, function() return hknight_smash[10] end, function(self) fight.charge(self, 3); fight.melee(self) end)
hknight_smash[10] = animation.frame(f.smash10, function() return hknight_smash[11] end, function(self) fight.charge(self, 0) end)
hknight_smash[11] = animation.frame(f.smash11, function() return hknight_run[1] end, function(self) fight.charge(self, 0) end)

--============================================================================

local hknight_watk = {}
hknight_watk[1] = animation.frame(f.w_attack1, function() return hknight_watk[2] end, function(self) fight.charge(self, 2) end)
hknight_watk[2] = animation.frame(f.w_attack2, function() return hknight_watk[3] end, function(self) fight.charge(self, 0) end)
hknight_watk[3] = animation.frame(f.w_attack3, function() return hknight_watk[4] end, function(self) fight.charge(self, 0) end)
hknight_watk[4] = animation.frame(f.w_attack4, function() return hknight_watk[5] end, function(self) fight.melee(self) end)
hknight_watk[5] = animation.frame(f.w_attack5, function() return hknight_watk[6] end, function(self) fight.melee(self) end)
hknight_watk[6] = animation.frame(f.w_attack6, function() return hknight_watk[7] end, function(self) fight.melee(self) end)
hknight_watk[7] = animation.frame(f.w_attack7, function() return hknight_watk[8] end, function(self) fight.charge(self, 1) end)
hknight_watk[8] = animation.frame(f.w_attack8, function() return hknight_watk[9] end, function(self) fight.charge(self, 4) end)
hknight_watk[9] = animation.frame(f.w_attack9, function() return hknight_watk[10] end, function(self) fight.charge(self, 5) end)
hknight_watk[10] = animation.frame(f.w_attack10, function() return hknight_watk[11] end, function(self) fight.charge(self, 3); fight.melee(self) end)
hknight_watk[11] = animation.frame(f.w_attack11, function() return hknight_watk[12] end, function(self) fight.charge(self, 2); fight.melee(self) end)
hknight_watk[12] = animation.frame(f.w_attack12, function() return hknight_watk[13] end, function(self) fight.charge(self, 2); fight.melee(self) end)
hknight_watk[13] = animation.frame(f.w_attack13, function() return hknight_watk[14] end, function(self) fight.charge(self, 0) end)
hknight_watk[14] = animation.frame(f.w_attack14, function() return hknight_watk[15] end, function(self) fight.charge(self, 0) end)
hknight_watk[15] = animation.frame(f.w_attack15, function() return hknight_watk[16] end, function(self) fight.charge(self, 0) end)
hknight_watk[16] = animation.frame(f.w_attack16, function() return hknight_watk[17] end, function(self) fight.charge(self, 1) end)
hknight_watk[17] = animation.frame(f.w_attack17, function() return hknight_watk[18] end, function(self) fight.charge(self, 1); fight.melee(self) end)
hknight_watk[18] = animation.frame(f.w_attack18, function() return hknight_watk[19] end, function(self) fight.charge(self, 3); fight.melee(self) end)
hknight_watk[19] = animation.frame(f.w_attack19, function() return hknight_watk[20] end, function(self) fight.charge(self, 4); fight.melee(self) end)
hknight_watk[20] = animation.frame(f.w_attack20, function() return hknight_watk[21] end, function(self) fight.charge(self, 6) end)
hknight_watk[21] = animation.frame(f.w_attack21, function() return hknight_watk[22] end, function(self) fight.charge(self, 7) end)
hknight_watk[22] = animation.frame(f.w_attack22, function() return hknight_run[1] end, function(self) fight.charge(self, 3) end)

--============================================================================

---@param self entity
---@return nil
function hk_idle_sound(self)
    if quake.random() < 0.2 then
        quake.sound(self, C.CHAN_VOICE, "hknight/idle.wav", 1, C.ATTN_NORM)
    end
end

---@param self entity
---@param _attacker entity
---@param damage number
---@return nil
local function hknight_pain_handler(self, _attacker, damage)
    if self.pain_finished > quake.time() then
        return
    end

    quake.sound(self, C.CHAN_VOICE, "hknight/pain1.wav", 1, C.ATTN_NORM)

    if quake.time() - self.pain_finished > 5 then
        -- always go into pain frame if it has been a while
        hknight_pain[1](self)
        self.pain_finished = quake.time() + 1
        return
    end

    if quake.random() * 30 > damage then
        -- didn't flinch
        return
    end

    self.pain_finished = quake.time() + 1
    hknight_pain[1](self)
end

---@param self entity
---@return nil
local function hknight_melee(self)
    quake.globals.hknight_type = quake.globals.hknight_type + 1

    quake.sound(self, CHAN_WEAPON, "hknight/slash1.wav", 1, C.ATTN_NORM)
    if quake.globals.hknight_type == 1 then
        hknight_slice[1](self)
    elseif quake.globals.hknight_type == 2 then
        hknight_smash[1](self)
    elseif quake.globals.hknight_type == 3 then
        hknight_watk[1](self)
        quake.globals.hknight_type = 0
    end
end

---QUAKED monster_hell_knight (1 0 0) (-16 -16 -24) (16 16 40) Ambush
---@param self entity
---@return nil
function M.spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end
    quake.precache_model2("progs/hknight.mdl")
    quake.precache_model2("progs/k_spike.mdl")
    quake.precache_model2("progs/h_hellkn.mdl")

    quake.precache_sound2("hknight/attack1.wav")
    quake.precache_sound2("hknight/death1.wav")
    quake.precache_sound2("hknight/pain1.wav")
    quake.precache_sound2("hknight/sight1.wav")
    quake.precache_sound("hknight/hit.wav") -- used by C code, so don't sound2
    quake.precache_sound2("hknight/slash1.wav")
    quake.precache_sound2("hknight/idle.wav")
    quake.precache_sound2("hknight/grunt.wav")

    quake.precache_sound("knight/sword1.wav")
    quake.precache_sound("knight/sword2.wav")

    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP

    quake.set_model(self, "progs/hknight.mdl")

    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 40))
    self.health = 250

    self.th_stand = hknight_stand[1]
    self.th_walk = hknight_walk[1]
    self.th_run = hknight_run[1]
    self.th_melee = hknight_melee
    self.th_missile = hknight_magicc[1]
    self.th_pain = hknight_pain_handler
    self.th_die = hknight_die_handler

    monsters.walk_start(self)
end

quake.register_entity("monster_hell_knight", M.spawn)

return M
