-- Port of tarbaby.qc from GPL-licensed CleanFixedQuakeC.
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
local fight = require("game.fight")
local animation = require("game.animation")
local combat = require("game.combat")
local monsters = require("game.monsters")
local subs = require("game.subs")
local weapons = require("game.weapons")

local count = animation.counter()
local f = {}

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
    f.walk7, f.walk8, f.walk9, f.walk10, f.walk11, f.walk12,
    f.walk13, f.walk14, f.walk15, f.walk16, f.walk17, f.walk18,
    f.walk19, f.walk20, f.walk21, f.walk22, f.walk23, f.walk24,
    f.walk25 = count(25)

f.run1, f.run2, f.run3, f.run4, f.run5, f.run6,
    f.run7, f.run8, f.run9, f.run10, f.run11, f.run12,
    f.run13, f.run14, f.run15, f.run16, f.run17, f.run18,
    f.run19, f.run20, f.run21, f.run22, f.run23, f.run24,
    f.run25 = count(25)

f.jump1, f.jump2, f.jump3, f.jump4, f.jump5, f.jump6 = count(6)

f.fly1, f.fly2, f.fly3, f.fly4 = count(4)

f.exp = count(1)

local FL_ONGROUND = 512
local MOVETYPE_BOUNCE = 10

--[[
==============================================================================

BLOB (Spawn)

==============================================================================
]]

local tbaby_stand1 = animation.loop("tarbaby.tbaby_stand1", {
    { f.walk1, ai.stand },
})

local tbaby_hang1 = animation.loop("tarbaby.tbaby_hang1", {
    { f.walk1, ai.stand },
})

local tbaby_walk = animation.loop("tarbaby.tbaby_walk", {
    { f.walk1, ai.turn },
    { f.walk2, ai.turn },
    { f.walk3, ai.turn },
    { f.walk4, ai.turn },
    { f.walk5, ai.turn },
    { f.walk6, ai.turn },
    { f.walk7, ai.turn },
    { f.walk8, ai.turn },
    { f.walk9, ai.turn },
    { f.walk10, ai.turn },
    { f.walk11, function(self) ai.walk(self, 2) end },
    { f.walk12, function(self) ai.walk(self, 2) end },
    { f.walk13, function(self) ai.walk(self, 2) end },
    { f.walk14, function(self) ai.walk(self, 2) end },
    { f.walk15, function(self) ai.walk(self, 2) end },
    { f.walk16, function(self) ai.walk(self, 2) end },
    { f.walk17, function(self) ai.walk(self, 2) end },
    { f.walk18, function(self) ai.walk(self, 2) end },
    { f.walk19, function(self) ai.walk(self, 2) end },
    { f.walk20, function(self) ai.walk(self, 2) end },
    { f.walk21, function(self) ai.walk(self, 2) end },
    { f.walk22, function(self) ai.walk(self, 2) end },
    { f.walk23, function(self) ai.walk(self, 2) end },
    { f.walk24, function(self) ai.walk(self, 2) end },
    { f.walk25, function(self) ai.walk(self, 2) end },
})

local tbaby_run = animation.loop("tarbaby.tbaby_run", {
    { f.run1, fight.face },
    { f.run2, fight.face },
    { f.run3, fight.face },
    { f.run4, fight.face },
    { f.run5, fight.face },
    { f.run6, fight.face },
    { f.run7, fight.face },
    { f.run8, fight.face },
    { f.run9, fight.face },
    { f.run10, fight.face },
    { f.run11, function(self) ai.run(self, 2) end },
    { f.run12, function(self) ai.run(self, 2) end },
    { f.run13, function(self) ai.run(self, 2) end },
    { f.run14, function(self) ai.run(self, 2) end },
    { f.run15, function(self) ai.run(self, 2) end },
    { f.run16, function(self) ai.run(self, 2) end },
    { f.run17, function(self) ai.run(self, 2) end },
    { f.run18, function(self) ai.run(self, 2) end },
    { f.run19, function(self) ai.run(self, 2) end },
    { f.run20, function(self) ai.run(self, 2) end },
    { f.run21, function(self) ai.run(self, 2) end },
    { f.run22, function(self) ai.run(self, 2) end },
    { f.run23, function(self) ai.run(self, 2) end },
    { f.run24, function(self) ai.run(self, 2) end },
    { f.run25, function(self) ai.run(self, 2) end },
})

--============================================================================

local tbaby_jump
local tbaby_jump_air
---@param self entity
---@param other entity
---@return nil
local tar_jump_touch = quake.register_callback("tarbaby.tar_jump_touch", function(self, other)
    if other.takedamage ~= 0 and other.classname ~= self.classname then
        if self.velocity:length() > 400 then
            local ldmg = 10 + 10 * quake.random()
            combat.damage(other, self, self, ldmg)
            quake.sound(self, 1, "blob/hit1.wav", 1, C.ATTN_NORM)
        end
    else
        quake.sound(self, 1, "blob/land1.wav", 1, C.ATTN_NORM)
    end

    if not quake.check_bottom(self) then
        if (self.flags & FL_ONGROUND) ~= 0 then
            -- jump randomly to not get hung up
            self.touch = subs.null
            self.think = tbaby_run
            self.movetype = C.MOVETYPE_STEP
            self.nextthink = quake.time() + 0.1
        end
        return -- not on ground yet
    end

    self.touch = subs.null
    self.think = tbaby_jump
    self.nextthink = quake.time() + 0.1
end)

local tbaby_fly = animation.loop("tarbaby.tbaby_fly", {
    { f.fly1 },
    { f.fly2 },
    { f.fly3 },
    { f.fly4, function(self)
        self.cnt = self.cnt + 1
        if self.cnt == 4 then
            tbaby_jump_air(self)
        end
    end },
})

tbaby_jump = animation.sequence("tarbaby.tbaby_jump", {
    { f.jump1, fight.face },
    { f.jump2, fight.face },
    { f.jump3, fight.face },
    { f.jump4, fight.face },
}, function() return tbaby_jump_air end)
tbaby_jump_air = animation.sequence("tarbaby.tbaby_jump_air", {
    { f.jump5, function(self)
        self.movetype = MOVETYPE_BOUNCE
        self.touch = tar_jump_touch
        local vectors = quake.make_vectors(self.angles)
        self.origin = self.origin + quake.vec3(0, 0, 1)
        self.velocity = vectors.forward * 600 + quake.vec3(0, 0, 200)
        self.velocity = self.velocity + quake.vec3(0, 0, quake.random() * 150)
        if (self.flags & FL_ONGROUND) ~= 0 then
            self.flags = self.flags - FL_ONGROUND
        end
        self.cnt = 0
    end },
    { f.jump6 },
}, function() return tbaby_fly end)

--============================================================================

local tbaby_die = animation.sequence("tarbaby.tbaby_die", {
    { f.exp, function(self)
        self.takedamage = C.DAMAGE_NO
    end },
    { f.exp, function(self)
        combat.radius_damage(self, self, 120, quake.world)

        quake.sound(self, C.CHAN_VOICE, "blob/death1.wav", 1, C.ATTN_NORM)
        self.origin = self.origin - self.velocity:normalized() * 8

        quake.write_byte(0, 23)
        quake.write_byte(0, 11)
        quake.write_coord(0, self.origin.x)
        quake.write_coord(0, self.origin.y)
        quake.write_coord(0, self.origin.z)

        weapons.become_explosion(self)
    end },
}, function() return tbaby_run end)

--============================================================================

---QUAKED monster_tarbaby (1 0 0) (-16 -16 -24) (16 16 24) Ambush
---@param self entity
---@return nil
local function spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end
    quake.precache_model2("progs/tarbaby.mdl")

    quake.precache_sound2("blob/death1.wav")
    quake.precache_sound2("blob/hit1.wav")
    quake.precache_sound2("blob/land1.wav")
    quake.precache_sound2("blob/sight1.wav")

    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP

    quake.set_model(self, "progs/tarbaby.mdl")

    quake.set_size(self, quake.vec3(-16, -16, -24), quake.vec3(16, 16, 40))
    self.health = 80

    self.th_stand = tbaby_stand1
    self.th_walk = tbaby_walk
    self.th_run = tbaby_run
    self.th_missile = tbaby_jump
    self.th_melee = tbaby_jump
    self.th_die = tbaby_die

    monsters.walk_start(self)
end

quake.register_entity("monster_tarbaby", spawn)
