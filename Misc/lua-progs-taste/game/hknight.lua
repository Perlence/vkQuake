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

local hknight_char_a

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
    hknight_char_a(self)
end

local hknight_run

---@param self entity
---@return nil
local function check_continue_charge(self)
    if quake.time() > self.attack_finished then
        subs.attack_finished(self, 3)
        hknight_run(self)
        return -- done charging
    end
    if quake.random() > 0.5 then
        quake.sound(self, CHAN_WEAPON, "knight/sword2.wav", 1, C.ATTN_NORM)
    else
        quake.sound(self, CHAN_WEAPON, "knight/sword1.wav", 1, C.ATTN_NORM)
    end
end

--===========================================================================

local hknight_stand = animation.loop("hknight.hknight_stand", {
    { f.stand1, ai.stand },
    { f.stand2, ai.stand },
    { f.stand3, ai.stand },
    { f.stand4, ai.stand },
    { f.stand5, ai.stand },
    { f.stand6, ai.stand },
    { f.stand7, ai.stand },
    { f.stand8, ai.stand },
    { f.stand9, ai.stand },
})

--===========================================================================

local hk_idle_sound
local hknight_walk = animation.loop("hknight.hknight_walk", {
    { f.walk1, function(self)
        hk_idle_sound(self)
        ai.walk(self, 2)
    end },
    { f.walk2, function(self) ai.walk(self, 5) end },
    { f.walk3, function(self) ai.walk(self, 5) end },
    { f.walk4, function(self) ai.walk(self, 4) end },
    { f.walk5, function(self) ai.walk(self, 4) end },
    { f.walk6, function(self) ai.walk(self, 2) end },
    { f.walk7, function(self) ai.walk(self, 2) end },
    { f.walk8, function(self) ai.walk(self, 3) end },
    { f.walk9, function(self) ai.walk(self, 3) end },
    { f.walk10, function(self) ai.walk(self, 4) end },
    { f.walk11, function(self) ai.walk(self, 3) end },
    { f.walk12, function(self) ai.walk(self, 4) end },
    { f.walk13, function(self) ai.walk(self, 6) end },
    { f.walk14, function(self) ai.walk(self, 2) end },
    { f.walk15, function(self) ai.walk(self, 2) end },
    { f.walk16, function(self) ai.walk(self, 4) end },
    { f.walk17, function(self) ai.walk(self, 3) end },
    { f.walk18, function(self) ai.walk(self, 3) end },
    { f.walk19, function(self) ai.walk(self, 3) end },
    { f.walk20, function(self) ai.walk(self, 2) end },
})

--===========================================================================

hknight_run = animation.loop("hknight.hknight_run", {
    { f.run1, function(self)
        hk_idle_sound(self)
        ai.run(self, 20)
        check_for_charge(self)
    end },
    { f.run2, function(self) ai.run(self, 25) end },
    { f.run3, function(self) ai.run(self, 18) end },
    { f.run4, function(self) ai.run(self, 16) end },
    { f.run5, function(self) ai.run(self, 14) end },
    { f.run6, function(self) ai.run(self, 25) end },
    { f.run7, function(self) ai.run(self, 21) end },
    { f.run8, function(self) ai.run(self, 13) end },
})

--============================================================================

local hknight_pain = animation.sequence("hknight.hknight_pain", {
    { f.pain1, function(self) quake.sound(self, C.CHAN_VOICE, "hknight/pain1.wav", 1, C.ATTN_NORM) end },
    { f.pain2 },
    { f.pain3 },
    { f.pain4 },
    { f.pain5 },
}, function() return hknight_run end)

--============================================================================

local hknight_die = animation.hold("hknight.hknight_die", {
    { f.death1, function(self) quake.walk_move(self, self.angles.y, 10) end },
    { f.death2, function(self) quake.walk_move(self, self.angles.y, 8) end },
    { f.death3, function(self)
        self.solid = C.SOLID_NOT
        quake.walk_move(self, self.angles.y, 7)
    end },
    { f.death4 },
    { f.death5 },
    { f.death6 },
    { f.death7 },
    { f.death8, function(self) quake.walk_move(self, self.angles.y, 10) end },
    { f.death9, function(self) quake.walk_move(self, self.angles.y, 11) end },
    { f.death10 },
    { f.death11 },
    { f.death12 },
})

local hknight_dieb = animation.hold("hknight.hknight_dieb", {
    { f.deathb1 },
    { f.deathb2 },
    { f.deathb3, function(self) self.solid = C.SOLID_NOT end },
    { f.deathb4 },
    { f.deathb5 },
    { f.deathb6 },
    { f.deathb7 },
    { f.deathb8 },
    { f.deathb9 },
})

---@param self entity
---@return nil
local hknight_die_handler = quake.register_function("hknight.hknight_die_handler", function(self)
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
        hknight_die(self)
    else
        hknight_dieb(self)
    end
end)

--============================================================================

animation.sequence("hknight.hknight_magica", {
    { f.magica1, fight.face },
    { f.magica2, fight.face },
    { f.magica3, fight.face },
    { f.magica4, fight.face },
    { f.magica5, fight.face },
    { f.magica6, fight.face },
    { f.magica7, function(self) hknight_shot(self, -2) end },
    { f.magica8, function(self) hknight_shot(self, -1) end },
    { f.magica9, function(self) hknight_shot(self, 0) end },
    { f.magica10, function(self) hknight_shot(self, 1) end },
    { f.magica11, function(self) hknight_shot(self, 2) end },
    { f.magica12, function(self) hknight_shot(self, 3) end },
    { f.magica13, fight.face },
    { f.magica14, fight.face },
}, function() return hknight_run end)

--============================================================================

animation.sequence("hknight.hknight_magicb", {
    { f.magicb1, fight.face },
    { f.magicb2, fight.face },
    { f.magicb3, fight.face },
    { f.magicb4, fight.face },
    { f.magicb5, fight.face },
    { f.magicb6, fight.face },
    { f.magicb7, function(self) hknight_shot(self, -2) end },
    { f.magicb8, function(self) hknight_shot(self, -1) end },
    { f.magicb9, function(self) hknight_shot(self, 0) end },
    { f.magicb10, function(self) hknight_shot(self, 1) end },
    { f.magicb11, function(self) hknight_shot(self, 2) end },
    { f.magicb12, function(self) hknight_shot(self, 3) end },
    { f.magicb13, fight.face },
}, function() return hknight_run end)

--============================================================================

local hknight_magicc = animation.sequence("hknight.hknight_magicc", {
    { f.magicc1, fight.face },
    { f.magicc2, fight.face },
    { f.magicc3, fight.face },
    { f.magicc4, fight.face },
    { f.magicc5, fight.face },
    { f.magicc6, function(self) hknight_shot(self, -2) end },
    { f.magicc7, function(self) hknight_shot(self, -1) end },
    { f.magicc8, function(self) hknight_shot(self, 0) end },
    { f.magicc9, function(self) hknight_shot(self, 1) end },
    { f.magicc10, function(self) hknight_shot(self, 2) end },
    { f.magicc11, function(self) hknight_shot(self, 3) end },
}, function() return hknight_run end)

--===========================================================================

hknight_char_a = animation.sequence("hknight.hknight_char_a", {
    { f.char_a1, function(self) fight.charge(self, 20) end },
    { f.char_a2, function(self) fight.charge(self, 25) end },
    { f.char_a3, function(self) fight.charge(self, 18) end },
    { f.char_a4, function(self) fight.charge(self, 16) end },
    { f.char_a5, function(self) fight.charge(self, 14) end },
    { f.char_a6, function(self)
        fight.charge(self, 20); fight.melee(self)
    end },
    { f.char_a7, function(self)
        fight.charge(self, 21); fight.melee(self)
    end },
    { f.char_a8, function(self)
        fight.charge(self, 13); fight.melee(self)
    end },
    { f.char_a9, function(self)
        fight.charge(self, 20); fight.melee(self)
    end },
    { f.char_a10, function(self)
        fight.charge(self, 20); fight.melee(self)
    end },
    { f.char_a11, function(self)
        fight.charge(self, 18); fight.melee(self)
    end },
    { f.char_a12, function(self) fight.charge(self, 16) end },
    { f.char_a13, function(self) fight.charge(self, 14) end },
    { f.char_a14, function(self) fight.charge(self, 25) end },
    { f.char_a15, function(self) fight.charge(self, 21) end },
    { f.char_a16, function(self) fight.charge(self, 13) end },
}, function() return hknight_run end)

--===========================================================================

animation.loop("hknight.hknight_char_b", {
    { f.char_b1, function(self)
        check_continue_charge(self)
        fight.charge(self, 23)
        fight.melee(self)
    end },
    { f.char_b2, function(self)
        fight.charge(self, 17); fight.melee(self)
    end },
    { f.char_b3, function(self)
        fight.charge(self, 12); fight.melee(self)
    end },
    { f.char_b4, function(self)
        fight.charge(self, 22); fight.melee(self)
    end },
    { f.char_b5, function(self)
        fight.charge(self, 18); fight.melee(self)
    end },
    { f.char_b6, function(self)
        fight.charge(self, 8); fight.melee(self)
    end },
})

--===========================================================================

local hknight_slice = animation.sequence("hknight.hknight_slice", {
    { f.slice1, function(self) fight.charge(self, 9) end },
    { f.slice2, function(self) fight.charge(self, 6) end },
    { f.slice3, function(self) fight.charge(self, 13) end },
    { f.slice4, function(self) fight.charge(self, 4) end },
    { f.slice5, function(self)
        fight.charge(self, 7); fight.melee(self)
    end },
    { f.slice6, function(self)
        fight.charge(self, 15); fight.melee(self)
    end },
    { f.slice7, function(self)
        fight.charge(self, 8); fight.melee(self)
    end },
    { f.slice8, function(self)
        fight.charge(self, 2); fight.melee(self)
    end },
    { f.slice9, function(self) fight.melee(self) end },
    { f.slice10, function(self) fight.charge(self, 3) end },
}, function() return hknight_run end)

--===========================================================================

local hknight_smash = animation.sequence("hknight.hknight_smash", {
    { f.smash1, function(self) fight.charge(self, 1) end },
    { f.smash2, function(self) fight.charge(self, 13) end },
    { f.smash3, function(self) fight.charge(self, 9) end },
    { f.smash4, function(self) fight.charge(self, 11) end },
    { f.smash5, function(self)
        fight.charge(self, 10); fight.melee(self)
    end },
    { f.smash6, function(self)
        fight.charge(self, 7); fight.melee(self)
    end },
    { f.smash7, function(self)
        fight.charge(self, 12); fight.melee(self)
    end },
    { f.smash8, function(self)
        fight.charge(self, 2); fight.melee(self)
    end },
    { f.smash9, function(self)
        fight.charge(self, 3); fight.melee(self)
    end },
    { f.smash10, function(self) fight.charge(self, 0) end },
    { f.smash11, function(self) fight.charge(self, 0) end },
}, function() return hknight_run end)

--============================================================================

local hknight_watk = animation.sequence("hknight.hknight_watk", {
    { f.w_attack1, function(self) fight.charge(self, 2) end },
    { f.w_attack2, function(self) fight.charge(self, 0) end },
    { f.w_attack3, function(self) fight.charge(self, 0) end },
    { f.w_attack4, function(self) fight.melee(self) end },
    { f.w_attack5, function(self) fight.melee(self) end },
    { f.w_attack6, function(self) fight.melee(self) end },
    { f.w_attack7, function(self) fight.charge(self, 1) end },
    { f.w_attack8, function(self) fight.charge(self, 4) end },
    { f.w_attack9, function(self) fight.charge(self, 5) end },
    { f.w_attack10, function(self)
        fight.charge(self, 3); fight.melee(self)
    end },
    { f.w_attack11, function(self)
        fight.charge(self, 2); fight.melee(self)
    end },
    { f.w_attack12, function(self)
        fight.charge(self, 2); fight.melee(self)
    end },
    { f.w_attack13, function(self) fight.charge(self, 0) end },
    { f.w_attack14, function(self) fight.charge(self, 0) end },
    { f.w_attack15, function(self) fight.charge(self, 0) end },
    { f.w_attack16, function(self) fight.charge(self, 1) end },
    { f.w_attack17, function(self)
        fight.charge(self, 1); fight.melee(self)
    end },
    { f.w_attack18, function(self)
        fight.charge(self, 3); fight.melee(self)
    end },
    { f.w_attack19, function(self)
        fight.charge(self, 4); fight.melee(self)
    end },
    { f.w_attack20, function(self) fight.charge(self, 6) end },
    { f.w_attack21, function(self) fight.charge(self, 7) end },
    { f.w_attack22, function(self) fight.charge(self, 3) end },
}, function() return hknight_run end)

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
local hknight_pain_handler = quake.register_function("hknight.hknight_pain_handler", function(self, _attacker, damage)
    if self.pain_finished > quake.time() then
        return
    end

    quake.sound(self, C.CHAN_VOICE, "hknight/pain1.wav", 1, C.ATTN_NORM)

    if quake.time() - self.pain_finished > 5 then
        -- always go into pain frame if it has been a while
        hknight_pain(self)
        self.pain_finished = quake.time() + 1
        return
    end

    if quake.random() * 30 > damage then
        -- didn't flinch
        return
    end

    self.pain_finished = quake.time() + 1
    hknight_pain(self)
end)

---@param self entity
---@return nil
local hknight_melee = quake.register_function("hknight.hknight_melee", function(self)
    quake.globals.hknight_type = quake.globals.hknight_type + 1

    quake.sound(self, CHAN_WEAPON, "hknight/slash1.wav", 1, C.ATTN_NORM)
    if quake.globals.hknight_type == 1 then
        hknight_slice(self)
    elseif quake.globals.hknight_type == 2 then
        hknight_smash(self)
    elseif quake.globals.hknight_type == 3 then
        hknight_watk(self)
        quake.globals.hknight_type = 0
    end
end)

---QUAKED monster_hell_knight (1 0 0) (-16 -16 -24) (16 16 40) Ambush
---@param self entity
---@return nil
local function spawn(self)
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

    self.th_stand = hknight_stand
    self.th_walk = hknight_walk
    self.th_run = hknight_run
    self.th_melee = hknight_melee
    self.th_missile = hknight_magicc
    self.th_pain = hknight_pain_handler
    self.th_die = hknight_die_handler

    monsters.walk_start(self)
end

quake.register_entity("monster_hell_knight", spawn)
