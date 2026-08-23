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

local hknight_char_a1
local hknight_run1
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
    hknight_char_a1(self)
end

---@param self entity
---@return nil
local function check_continue_charge(self)
    if quake.time() > self.attack_finished then
        subs.attack_finished(self, 3)
        hknight_run1(self)
        return -- done charging
    end
    if quake.random() > 0.5 then
        quake.sound(self, CHAN_WEAPON, "knight/sword2.wav", 1, C.ATTN_NORM)
    else
        quake.sound(self, CHAN_WEAPON, "knight/sword1.wav", 1, C.ATTN_NORM)
    end
end

--===========================================================================

local hknight_stand1, hknight_stand2, hknight_stand3, hknight_stand4, hknight_stand5, hknight_stand6
local hknight_stand7, hknight_stand8, hknight_stand9

hknight_stand1 = animation.frame(f.stand1, function() return hknight_stand2 end, ai.stand)
hknight_stand2 = animation.frame(f.stand2, function() return hknight_stand3 end, ai.stand)
hknight_stand3 = animation.frame(f.stand3, function() return hknight_stand4 end, ai.stand)
hknight_stand4 = animation.frame(f.stand4, function() return hknight_stand5 end, ai.stand)
hknight_stand5 = animation.frame(f.stand5, function() return hknight_stand6 end, ai.stand)
hknight_stand6 = animation.frame(f.stand6, function() return hknight_stand7 end, ai.stand)
hknight_stand7 = animation.frame(f.stand7, function() return hknight_stand8 end, ai.stand)
hknight_stand8 = animation.frame(f.stand8, function() return hknight_stand9 end, ai.stand)
hknight_stand9 = animation.frame(f.stand9, function() return hknight_stand1 end, ai.stand)

--===========================================================================

local hknight_walk1, hknight_walk2, hknight_walk3, hknight_walk4, hknight_walk5, hknight_walk6
local hknight_walk7, hknight_walk8, hknight_walk9, hknight_walk10, hknight_walk11, hknight_walk12
local hknight_walk13, hknight_walk14, hknight_walk15, hknight_walk16, hknight_walk17, hknight_walk18
local hknight_walk19, hknight_walk20

hknight_walk1 = animation.frame(f.walk1, function() return hknight_walk2 end, function(self)
    hk_idle_sound(self)
    ai.walk(self, 2)
end)
hknight_walk2 = animation.frame(f.walk2, function() return hknight_walk3 end, function(self) ai.walk(self, 5) end)
hknight_walk3 = animation.frame(f.walk3, function() return hknight_walk4 end, function(self) ai.walk(self, 5) end)
hknight_walk4 = animation.frame(f.walk4, function() return hknight_walk5 end, function(self) ai.walk(self, 4) end)
hknight_walk5 = animation.frame(f.walk5, function() return hknight_walk6 end, function(self) ai.walk(self, 4) end)
hknight_walk6 = animation.frame(f.walk6, function() return hknight_walk7 end, function(self) ai.walk(self, 2) end)
hknight_walk7 = animation.frame(f.walk7, function() return hknight_walk8 end, function(self) ai.walk(self, 2) end)
hknight_walk8 = animation.frame(f.walk8, function() return hknight_walk9 end, function(self) ai.walk(self, 3) end)
hknight_walk9 = animation.frame(f.walk9, function() return hknight_walk10 end, function(self) ai.walk(self, 3) end)
hknight_walk10 = animation.frame(f.walk10, function() return hknight_walk11 end, function(self) ai.walk(self, 4) end)
hknight_walk11 = animation.frame(f.walk11, function() return hknight_walk12 end, function(self) ai.walk(self, 3) end)
hknight_walk12 = animation.frame(f.walk12, function() return hknight_walk13 end, function(self) ai.walk(self, 4) end)
hknight_walk13 = animation.frame(f.walk13, function() return hknight_walk14 end, function(self) ai.walk(self, 6) end)
hknight_walk14 = animation.frame(f.walk14, function() return hknight_walk15 end, function(self) ai.walk(self, 2) end)
hknight_walk15 = animation.frame(f.walk15, function() return hknight_walk16 end, function(self) ai.walk(self, 2) end)
hknight_walk16 = animation.frame(f.walk16, function() return hknight_walk17 end, function(self) ai.walk(self, 4) end)
hknight_walk17 = animation.frame(f.walk17, function() return hknight_walk18 end, function(self) ai.walk(self, 3) end)
hknight_walk18 = animation.frame(f.walk18, function() return hknight_walk19 end, function(self) ai.walk(self, 3) end)
hknight_walk19 = animation.frame(f.walk19, function() return hknight_walk20 end, function(self) ai.walk(self, 3) end)
hknight_walk20 = animation.frame(f.walk20, function() return hknight_walk1 end, function(self) ai.walk(self, 2) end)

--===========================================================================

local hknight_run2, hknight_run3, hknight_run4, hknight_run5, hknight_run6, hknight_run7
local hknight_run8

hknight_run1 = animation.frame(f.run1, function() return hknight_run2 end, function(self)
    hk_idle_sound(self)
    ai.run(self, 20)
    check_for_charge(self)
end)
hknight_run2 = animation.frame(f.run2, function() return hknight_run3 end, function(self) ai.run(self, 25) end)
hknight_run3 = animation.frame(f.run3, function() return hknight_run4 end, function(self) ai.run(self, 18) end)
hknight_run4 = animation.frame(f.run4, function() return hknight_run5 end, function(self) ai.run(self, 16) end)
hknight_run5 = animation.frame(f.run5, function() return hknight_run6 end, function(self) ai.run(self, 14) end)
hknight_run6 = animation.frame(f.run6, function() return hknight_run7 end, function(self) ai.run(self, 25) end)
hknight_run7 = animation.frame(f.run7, function() return hknight_run8 end, function(self) ai.run(self, 21) end)
hknight_run8 = animation.frame(f.run8, function() return hknight_run1 end, function(self) ai.run(self, 13) end)

--============================================================================

local hknight_pain1, hknight_pain2, hknight_pain3, hknight_pain4, hknight_pain5

hknight_pain1 = animation.frame(f.pain1, function() return hknight_pain2 end, function(self) quake.sound(self, C.CHAN_VOICE, "hknight/pain1.wav", 1, C.ATTN_NORM) end)
hknight_pain2 = animation.frame(f.pain2, function() return hknight_pain3 end)
hknight_pain3 = animation.frame(f.pain3, function() return hknight_pain4 end)
hknight_pain4 = animation.frame(f.pain4, function() return hknight_pain5 end)
hknight_pain5 = animation.frame(f.pain5, function() return hknight_run1 end)

--============================================================================

local hknight_die1, hknight_die2, hknight_die3, hknight_die4, hknight_die5, hknight_die6
local hknight_die7, hknight_die8, hknight_die9, hknight_die10, hknight_die11, hknight_die12

hknight_die1 = animation.frame(f.death1, function() return hknight_die2 end, function(self) quake.walk_move(self, self.angles.y, 10) end)
hknight_die2 = animation.frame(f.death2, function() return hknight_die3 end, function(self) quake.walk_move(self, self.angles.y, 8) end)
hknight_die3 = animation.frame(f.death3, function() return hknight_die4 end, function(self)
    self.solid = C.SOLID_NOT
    quake.walk_move(self, self.angles.y, 7)
end)
hknight_die4 = animation.frame(f.death4, function() return hknight_die5 end)
hknight_die5 = animation.frame(f.death5, function() return hknight_die6 end)
hknight_die6 = animation.frame(f.death6, function() return hknight_die7 end)
hknight_die7 = animation.frame(f.death7, function() return hknight_die8 end)
hknight_die8 = animation.frame(f.death8, function() return hknight_die9 end, function(self) quake.walk_move(self, self.angles.y, 10) end)
hknight_die9 = animation.frame(f.death9, function() return hknight_die10 end, function(self) quake.walk_move(self, self.angles.y, 11) end)
hknight_die10 = animation.frame(f.death10, function() return hknight_die11 end)
hknight_die11 = animation.frame(f.death11, function() return hknight_die12 end)
hknight_die12 = animation.frame(f.death12, function() return hknight_die12 end)

local hknight_dieb1, hknight_dieb2, hknight_dieb3, hknight_dieb4, hknight_dieb5, hknight_dieb6
local hknight_dieb7, hknight_dieb8, hknight_dieb9

hknight_dieb1 = animation.frame(f.deathb1, function() return hknight_dieb2 end)
hknight_dieb2 = animation.frame(f.deathb2, function() return hknight_dieb3 end)
hknight_dieb3 = animation.frame(f.deathb3, function() return hknight_dieb4 end, function(self) self.solid = C.SOLID_NOT end)
hknight_dieb4 = animation.frame(f.deathb4, function() return hknight_dieb5 end)
hknight_dieb5 = animation.frame(f.deathb5, function() return hknight_dieb6 end)
hknight_dieb6 = animation.frame(f.deathb6, function() return hknight_dieb7 end)
hknight_dieb7 = animation.frame(f.deathb7, function() return hknight_dieb8 end)
hknight_dieb8 = animation.frame(f.deathb8, function() return hknight_dieb9 end)
hknight_dieb9 = animation.frame(f.deathb9, function() return hknight_dieb9 end)

---@param self entity
---@return nil
local function hknight_die(self)
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
        hknight_die1(self)
    else
        hknight_dieb1(self)
    end
end

--============================================================================

local hknight_magica1, hknight_magica2, hknight_magica3, hknight_magica4, hknight_magica5, hknight_magica6
local hknight_magica7, hknight_magica8, hknight_magica9, hknight_magica10, hknight_magica11, hknight_magica12
local hknight_magica13, hknight_magica14

hknight_magica1 = animation.frame(f.magica1, function() return hknight_magica2 end, fight.face)
hknight_magica2 = animation.frame(f.magica2, function() return hknight_magica3 end, fight.face)
hknight_magica3 = animation.frame(f.magica3, function() return hknight_magica4 end, fight.face)
hknight_magica4 = animation.frame(f.magica4, function() return hknight_magica5 end, fight.face)
hknight_magica5 = animation.frame(f.magica5, function() return hknight_magica6 end, fight.face)
hknight_magica6 = animation.frame(f.magica6, function() return hknight_magica7 end, fight.face)
hknight_magica7 = animation.frame(f.magica7, function() return hknight_magica8 end, function(self) hknight_shot(self, -2) end)
hknight_magica8 = animation.frame(f.magica8, function() return hknight_magica9 end, function(self) hknight_shot(self, -1) end)
hknight_magica9 = animation.frame(f.magica9, function() return hknight_magica10 end, function(self) hknight_shot(self, 0) end)
hknight_magica10 = animation.frame(f.magica10, function() return hknight_magica11 end, function(self) hknight_shot(self, 1) end)
hknight_magica11 = animation.frame(f.magica11, function() return hknight_magica12 end, function(self) hknight_shot(self, 2) end)
hknight_magica12 = animation.frame(f.magica12, function() return hknight_magica13 end, function(self) hknight_shot(self, 3) end)
hknight_magica13 = animation.frame(f.magica13, function() return hknight_magica14 end, fight.face)
hknight_magica14 = animation.frame(f.magica14, function() return hknight_run1 end, fight.face)

--============================================================================

local hknight_magicb1, hknight_magicb2, hknight_magicb3, hknight_magicb4, hknight_magicb5, hknight_magicb6
local hknight_magicb7, hknight_magicb8, hknight_magicb9, hknight_magicb10, hknight_magicb11, hknight_magicb12
local hknight_magicb13

hknight_magicb1 = animation.frame(f.magicb1, function() return hknight_magicb2 end, fight.face)
hknight_magicb2 = animation.frame(f.magicb2, function() return hknight_magicb3 end, fight.face)
hknight_magicb3 = animation.frame(f.magicb3, function() return hknight_magicb4 end, fight.face)
hknight_magicb4 = animation.frame(f.magicb4, function() return hknight_magicb5 end, fight.face)
hknight_magicb5 = animation.frame(f.magicb5, function() return hknight_magicb6 end, fight.face)
hknight_magicb6 = animation.frame(f.magicb6, function() return hknight_magicb7 end, fight.face)
hknight_magicb7 = animation.frame(f.magicb7, function() return hknight_magicb8 end, function(self) hknight_shot(self, -2) end)
hknight_magicb8 = animation.frame(f.magicb8, function() return hknight_magicb9 end, function(self) hknight_shot(self, -1) end)
hknight_magicb9 = animation.frame(f.magicb9, function() return hknight_magicb10 end, function(self) hknight_shot(self, 0) end)
hknight_magicb10 = animation.frame(f.magicb10, function() return hknight_magicb11 end, function(self) hknight_shot(self, 1) end)
hknight_magicb11 = animation.frame(f.magicb11, function() return hknight_magicb12 end, function(self) hknight_shot(self, 2) end)
hknight_magicb12 = animation.frame(f.magicb12, function() return hknight_magicb13 end, function(self) hknight_shot(self, 3) end)
hknight_magicb13 = animation.frame(f.magicb13, function() return hknight_run1 end, fight.face)

--============================================================================

local hknight_magicc1, hknight_magicc2, hknight_magicc3, hknight_magicc4, hknight_magicc5, hknight_magicc6
local hknight_magicc7, hknight_magicc8, hknight_magicc9, hknight_magicc10, hknight_magicc11

hknight_magicc1 = animation.frame(f.magicc1, function() return hknight_magicc2 end, fight.face)
hknight_magicc2 = animation.frame(f.magicc2, function() return hknight_magicc3 end, fight.face)
hknight_magicc3 = animation.frame(f.magicc3, function() return hknight_magicc4 end, fight.face)
hknight_magicc4 = animation.frame(f.magicc4, function() return hknight_magicc5 end, fight.face)
hknight_magicc5 = animation.frame(f.magicc5, function() return hknight_magicc6 end, fight.face)
hknight_magicc6 = animation.frame(f.magicc6, function() return hknight_magicc7 end, function(self) hknight_shot(self, -2) end)
hknight_magicc7 = animation.frame(f.magicc7, function() return hknight_magicc8 end, function(self) hknight_shot(self, -1) end)
hknight_magicc8 = animation.frame(f.magicc8, function() return hknight_magicc9 end, function(self) hknight_shot(self, 0) end)
hknight_magicc9 = animation.frame(f.magicc9, function() return hknight_magicc10 end, function(self) hknight_shot(self, 1) end)
hknight_magicc10 = animation.frame(f.magicc10, function() return hknight_magicc11 end, function(self) hknight_shot(self, 2) end)
hknight_magicc11 = animation.frame(f.magicc11, function() return hknight_run1 end, function(self) hknight_shot(self, 3) end)

--===========================================================================

local hknight_char_a2, hknight_char_a3, hknight_char_a4, hknight_char_a5, hknight_char_a6, hknight_char_a7
local hknight_char_a8, hknight_char_a9, hknight_char_a10, hknight_char_a11, hknight_char_a12, hknight_char_a13
local hknight_char_a14, hknight_char_a15, hknight_char_a16

hknight_char_a1 = animation.frame(f.char_a1, function() return hknight_char_a2 end, function(self) fight.charge(self, 20) end)
hknight_char_a2 = animation.frame(f.char_a2, function() return hknight_char_a3 end, function(self) fight.charge(self, 25) end)
hknight_char_a3 = animation.frame(f.char_a3, function() return hknight_char_a4 end, function(self) fight.charge(self, 18) end)
hknight_char_a4 = animation.frame(f.char_a4, function() return hknight_char_a5 end, function(self) fight.charge(self, 16) end)
hknight_char_a5 = animation.frame(f.char_a5, function() return hknight_char_a6 end, function(self) fight.charge(self, 14) end)
hknight_char_a6 = animation.frame(f.char_a6, function() return hknight_char_a7 end, function(self) fight.charge(self, 20); fight.melee(self) end)
hknight_char_a7 = animation.frame(f.char_a7, function() return hknight_char_a8 end, function(self) fight.charge(self, 21); fight.melee(self) end)
hknight_char_a8 = animation.frame(f.char_a8, function() return hknight_char_a9 end, function(self) fight.charge(self, 13); fight.melee(self) end)
hknight_char_a9 = animation.frame(f.char_a9, function() return hknight_char_a10 end, function(self) fight.charge(self, 20); fight.melee(self) end)
hknight_char_a10 = animation.frame(f.char_a10, function() return hknight_char_a11 end, function(self) fight.charge(self, 20); fight.melee(self) end)
hknight_char_a11 = animation.frame(f.char_a11, function() return hknight_char_a12 end, function(self) fight.charge(self, 18); fight.melee(self) end)
hknight_char_a12 = animation.frame(f.char_a12, function() return hknight_char_a13 end, function(self) fight.charge(self, 16) end)
hknight_char_a13 = animation.frame(f.char_a13, function() return hknight_char_a14 end, function(self) fight.charge(self, 14) end)
hknight_char_a14 = animation.frame(f.char_a14, function() return hknight_char_a15 end, function(self) fight.charge(self, 25) end)
hknight_char_a15 = animation.frame(f.char_a15, function() return hknight_char_a16 end, function(self) fight.charge(self, 21) end)
hknight_char_a16 = animation.frame(f.char_a16, function() return hknight_run1 end, function(self) fight.charge(self, 13) end)

--===========================================================================

local hknight_char_b1, hknight_char_b2, hknight_char_b3, hknight_char_b4, hknight_char_b5, hknight_char_b6

hknight_char_b1 = animation.frame(f.char_b1, function() return hknight_char_b2 end, function(self)
    check_continue_charge(self)
    fight.charge(self, 23)
    fight.melee(self)
end)
hknight_char_b2 = animation.frame(f.char_b2, function() return hknight_char_b3 end, function(self) fight.charge(self, 17); fight.melee(self) end)
hknight_char_b3 = animation.frame(f.char_b3, function() return hknight_char_b4 end, function(self) fight.charge(self, 12); fight.melee(self) end)
hknight_char_b4 = animation.frame(f.char_b4, function() return hknight_char_b5 end, function(self) fight.charge(self, 22); fight.melee(self) end)
hknight_char_b5 = animation.frame(f.char_b5, function() return hknight_char_b6 end, function(self) fight.charge(self, 18); fight.melee(self) end)
hknight_char_b6 = animation.frame(f.char_b6, function() return hknight_char_b1 end, function(self) fight.charge(self, 8); fight.melee(self) end)

--===========================================================================

local hknight_slice1, hknight_slice2, hknight_slice3, hknight_slice4, hknight_slice5, hknight_slice6
local hknight_slice7, hknight_slice8, hknight_slice9, hknight_slice10

hknight_slice1 = animation.frame(f.slice1, function() return hknight_slice2 end, function(self) fight.charge(self, 9) end)
hknight_slice2 = animation.frame(f.slice2, function() return hknight_slice3 end, function(self) fight.charge(self, 6) end)
hknight_slice3 = animation.frame(f.slice3, function() return hknight_slice4 end, function(self) fight.charge(self, 13) end)
hknight_slice4 = animation.frame(f.slice4, function() return hknight_slice5 end, function(self) fight.charge(self, 4) end)
hknight_slice5 = animation.frame(f.slice5, function() return hknight_slice6 end, function(self) fight.charge(self, 7); fight.melee(self) end)
hknight_slice6 = animation.frame(f.slice6, function() return hknight_slice7 end, function(self) fight.charge(self, 15); fight.melee(self) end)
hknight_slice7 = animation.frame(f.slice7, function() return hknight_slice8 end, function(self) fight.charge(self, 8); fight.melee(self) end)
hknight_slice8 = animation.frame(f.slice8, function() return hknight_slice9 end, function(self) fight.charge(self, 2); fight.melee(self) end)
hknight_slice9 = animation.frame(f.slice9, function() return hknight_slice10 end, function(self) fight.melee(self) end)
hknight_slice10 = animation.frame(f.slice10, function() return hknight_run1 end, function(self) fight.charge(self, 3) end)

--===========================================================================

local hknight_smash1, hknight_smash2, hknight_smash3, hknight_smash4, hknight_smash5, hknight_smash6
local hknight_smash7, hknight_smash8, hknight_smash9, hknight_smash10, hknight_smash11

hknight_smash1 = animation.frame(f.smash1, function() return hknight_smash2 end, function(self) fight.charge(self, 1) end)
hknight_smash2 = animation.frame(f.smash2, function() return hknight_smash3 end, function(self) fight.charge(self, 13) end)
hknight_smash3 = animation.frame(f.smash3, function() return hknight_smash4 end, function(self) fight.charge(self, 9) end)
hknight_smash4 = animation.frame(f.smash4, function() return hknight_smash5 end, function(self) fight.charge(self, 11) end)
hknight_smash5 = animation.frame(f.smash5, function() return hknight_smash6 end, function(self) fight.charge(self, 10); fight.melee(self) end)
hknight_smash6 = animation.frame(f.smash6, function() return hknight_smash7 end, function(self) fight.charge(self, 7); fight.melee(self) end)
hknight_smash7 = animation.frame(f.smash7, function() return hknight_smash8 end, function(self) fight.charge(self, 12); fight.melee(self) end)
hknight_smash8 = animation.frame(f.smash8, function() return hknight_smash9 end, function(self) fight.charge(self, 2); fight.melee(self) end)
hknight_smash9 = animation.frame(f.smash9, function() return hknight_smash10 end, function(self) fight.charge(self, 3); fight.melee(self) end)
hknight_smash10 = animation.frame(f.smash10, function() return hknight_smash11 end, function(self) fight.charge(self, 0) end)
hknight_smash11 = animation.frame(f.smash11, function() return hknight_run1 end, function(self) fight.charge(self, 0) end)

--============================================================================

local hknight_watk1, hknight_watk2, hknight_watk3, hknight_watk4, hknight_watk5, hknight_watk6
local hknight_watk7, hknight_watk8, hknight_watk9, hknight_watk10, hknight_watk11, hknight_watk12
local hknight_watk13, hknight_watk14, hknight_watk15, hknight_watk16, hknight_watk17, hknight_watk18
local hknight_watk19, hknight_watk20, hknight_watk21, hknight_watk22

hknight_watk1 = animation.frame(f.w_attack1, function() return hknight_watk2 end, function(self) fight.charge(self, 2) end)
hknight_watk2 = animation.frame(f.w_attack2, function() return hknight_watk3 end, function(self) fight.charge(self, 0) end)
hknight_watk3 = animation.frame(f.w_attack3, function() return hknight_watk4 end, function(self) fight.charge(self, 0) end)
hknight_watk4 = animation.frame(f.w_attack4, function() return hknight_watk5 end, function(self) fight.melee(self) end)
hknight_watk5 = animation.frame(f.w_attack5, function() return hknight_watk6 end, function(self) fight.melee(self) end)
hknight_watk6 = animation.frame(f.w_attack6, function() return hknight_watk7 end, function(self) fight.melee(self) end)
hknight_watk7 = animation.frame(f.w_attack7, function() return hknight_watk8 end, function(self) fight.charge(self, 1) end)
hknight_watk8 = animation.frame(f.w_attack8, function() return hknight_watk9 end, function(self) fight.charge(self, 4) end)
hknight_watk9 = animation.frame(f.w_attack9, function() return hknight_watk10 end, function(self) fight.charge(self, 5) end)
hknight_watk10 = animation.frame(f.w_attack10, function() return hknight_watk11 end, function(self) fight.charge(self, 3); fight.melee(self) end)
hknight_watk11 = animation.frame(f.w_attack11, function() return hknight_watk12 end, function(self) fight.charge(self, 2); fight.melee(self) end)
hknight_watk12 = animation.frame(f.w_attack12, function() return hknight_watk13 end, function(self) fight.charge(self, 2); fight.melee(self) end)
hknight_watk13 = animation.frame(f.w_attack13, function() return hknight_watk14 end, function(self) fight.charge(self, 0) end)
hknight_watk14 = animation.frame(f.w_attack14, function() return hknight_watk15 end, function(self) fight.charge(self, 0) end)
hknight_watk15 = animation.frame(f.w_attack15, function() return hknight_watk16 end, function(self) fight.charge(self, 0) end)
hknight_watk16 = animation.frame(f.w_attack16, function() return hknight_watk17 end, function(self) fight.charge(self, 1) end)
hknight_watk17 = animation.frame(f.w_attack17, function() return hknight_watk18 end, function(self) fight.charge(self, 1); fight.melee(self) end)
hknight_watk18 = animation.frame(f.w_attack18, function() return hknight_watk19 end, function(self) fight.charge(self, 3); fight.melee(self) end)
hknight_watk19 = animation.frame(f.w_attack19, function() return hknight_watk20 end, function(self) fight.charge(self, 4); fight.melee(self) end)
hknight_watk20 = animation.frame(f.w_attack20, function() return hknight_watk21 end, function(self) fight.charge(self, 6) end)
hknight_watk21 = animation.frame(f.w_attack21, function() return hknight_watk22 end, function(self) fight.charge(self, 7) end)
hknight_watk22 = animation.frame(f.w_attack22, function() return hknight_run1 end, function(self) fight.charge(self, 3) end)

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
local function hknight_pain(self, _attacker, damage)
    if self.pain_finished > quake.time() then
        return
    end

    quake.sound(self, C.CHAN_VOICE, "hknight/pain1.wav", 1, C.ATTN_NORM)

    if quake.time() - self.pain_finished > 5 then
        -- always go into pain frame if it has been a while
        hknight_pain1(self)
        self.pain_finished = quake.time() + 1
        return
    end

    if quake.random() * 30 > damage then
        -- didn't flinch
        return
    end

    self.pain_finished = quake.time() + 1
    hknight_pain1(self)
end

---@param self entity
---@return nil
local function hknight_melee(self)
    quake.globals.hknight_type = quake.globals.hknight_type + 1

    quake.sound(self, CHAN_WEAPON, "hknight/slash1.wav", 1, C.ATTN_NORM)
    if quake.globals.hknight_type == 1 then
        hknight_slice1(self)
    elseif quake.globals.hknight_type == 2 then
        hknight_smash1(self)
    elseif quake.globals.hknight_type == 3 then
        hknight_watk1(self)
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

    self.th_stand = hknight_stand1
    self.th_walk = hknight_walk1
    self.th_run = hknight_run1
    self.th_melee = hknight_melee
    self.th_missile = hknight_magicc1
    self.th_pain = hknight_pain
    self.th_die = hknight_die

    monsters.walk_start(self)
end

quake.register_entity("monster_hell_knight", M.spawn)

return M
