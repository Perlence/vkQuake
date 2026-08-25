-- Port of boss.qc from GPL-licensed CleanFixedQuakeC.
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
local animation = require("game.animation")
local fight = require("game.fight")
local subs = require("game.subs")
local weapons = require("game.weapons")
local doors = require("game.doors")

local count = animation.counter()
local f = {}

f.rise1, f.rise2, f.rise3, f.rise4, f.rise5, f.rise6,
    f.rise7, f.rise8, f.rise9, f.rise10, f.rise11, f.rise12,
    f.rise13, f.rise14, f.rise15, f.rise16, f.rise17 = count(17)

f.walk1, f.walk2, f.walk3, f.walk4, f.walk5, f.walk6,
    f.walk7, f.walk8, f.walk9, f.walk10, f.walk11, f.walk12,
    f.walk13, f.walk14, f.walk15, f.walk16, f.walk17, f.walk18,
    f.walk19, f.walk20, f.walk21, f.walk22, f.walk23, f.walk24,
    f.walk25, f.walk26, f.walk27, f.walk28, f.walk29, f.walk30,
    f.walk31 = count(31)

f.death1, f.death2, f.death3, f.death4, f.death5, f.death6,
    f.death7, f.death8, f.death9 = count(9)

f.attack1, f.attack2, f.attack3, f.attack4, f.attack5, f.attack6,
    f.attack7, f.attack8, f.attack9, f.attack10, f.attack11, f.attack12,
    f.attack13, f.attack14, f.attack15, f.attack16, f.attack17, f.attack18,
    f.attack19, f.attack20, f.attack21, f.attack22, f.attack23 = count(23)

f.shocka1, f.shocka2, f.shocka3, f.shocka4, f.shocka5, f.shocka6,
    f.shocka7, f.shocka8, f.shocka9, f.shocka10 = count(10)

f.shockb1, f.shockb2, f.shockb3, f.shockb4, f.shockb5, f.shockb6 = count(6)

f.shockc1, f.shockc2, f.shockc3, f.shockc4, f.shockc5, f.shockc6,
    f.shockc7, f.shockc8, f.shockc9, f.shockc10 = count(10)

local CHAN_WEAPON = 1
local CHAN_BODY = 4
local MSG_BROADCAST = 0
local SVC_TEMPENTITY = 23
local TE_LAVASPLASH = 10
local TE_LIGHTNING3 = 9
local STATE_TOP = 0
local STATE_BOTTOM = 1

--[[
==============================================================================

BOSS-ONE (Chthon)

==============================================================================
]]

---@param self entity
---@return nil
local function boss_face(self)
    -- go for another player if multi player
    if self.enemy.health <= 0 or quake.random() < 0.02 then
        self.enemy = quake.find(self.enemy, "classname", "player")
        if not self.enemy then
            self.enemy = quake.find(self.enemy, "classname", "player")
        end
    end
    fight.face(self)
end

local boss_missile

local boss_rise = animation.sequence({
    { f.rise1, function(self) quake.sound(self, CHAN_WEAPON, "boss1/out1.wav", 1, C.ATTN_NORM) end },
    { f.rise2, function(self) quake.sound(self, C.CHAN_VOICE, "boss1/sight1.wav", 1, C.ATTN_NORM) end },
    { f.rise3 },
    { f.rise4 },
    { f.rise5 },
    { f.rise6 },
    { f.rise7 },
    { f.rise8 },
    { f.rise9 },
    { f.rise10 },
    { f.rise11 },
    { f.rise12 },
    { f.rise13 },
    { f.rise14 },
    { f.rise15 },
    { f.rise16 },
    { f.rise17 },
}, function() return boss_missile end)

local boss_idle = animation.loop({
    { f.walk1, function(_self)
        -- look for other players
    end },
    { f.walk2, boss_face },
    { f.walk3, boss_face },
    { f.walk4, boss_face },
    { f.walk5, boss_face },
    { f.walk6, boss_face },
    { f.walk7, boss_face },
    { f.walk8, boss_face },
    { f.walk9, boss_face },
    { f.walk10, boss_face },
    { f.walk11, boss_face },
    { f.walk12, boss_face },
    { f.walk13, boss_face },
    { f.walk14, boss_face },
    { f.walk15, boss_face },
    { f.walk16, boss_face },
    { f.walk17, boss_face },
    { f.walk18, boss_face },
    { f.walk19, boss_face },
    { f.walk20, boss_face },
    { f.walk21, boss_face },
    { f.walk22, boss_face },
    { f.walk23, boss_face },
    { f.walk24, boss_face },
    { f.walk25, boss_face },
    { f.walk26, boss_face },
    { f.walk27, boss_face },
    { f.walk28, boss_face },
    { f.walk29, boss_face },
    { f.walk30, boss_face },
    { f.walk31, boss_face },
})

local boss_launch_missile

boss_missile = animation.loop({
    { f.attack1, boss_face },
    { f.attack2, boss_face },
    { f.attack3, boss_face },
    { f.attack4, boss_face },
    { f.attack5, boss_face },
    { f.attack6, boss_face },
    { f.attack7, boss_face },
    { f.attack8, boss_face },
    { f.attack9, function(self) boss_launch_missile(self, quake.vec3(100, 100, 200)) end },
    { f.attack10, boss_face },
    { f.attack11, boss_face },
    { f.attack12, boss_face },
    { f.attack13, boss_face },
    { f.attack14, boss_face },
    { f.attack15, boss_face },
    { f.attack16, boss_face },
    { f.attack17, boss_face },
    { f.attack18, boss_face },
    { f.attack19, boss_face },
    { f.attack20, function(self) boss_launch_missile(self, quake.vec3(100, -100, 200)) end },
    { f.attack21, boss_face },
    { f.attack22, boss_face },
    { f.attack23, boss_face },
})

local boss_shocka = animation.sequence({
    { f.shocka1 },
    { f.shocka2 },
    { f.shocka3 },
    { f.shocka4 },
    { f.shocka5 },
    { f.shocka6 },
    { f.shocka7 },
    { f.shocka8 },
    { f.shocka9 },
    { f.shocka10 },
}, function() return boss_missile end)

local boss_shockb = animation.sequence({
    { f.shockb1 },
    { f.shockb2 },
    { f.shockb3 },
    { f.shockb4 },
    { f.shockb5 },
    { f.shockb6 },
    { f.shockb1 },
    { f.shockb2 },
    { f.shockb3 },
    { f.shockb4 },
}, function() return boss_missile end)

local boss_death

local boss_shockc = animation.sequence({
    { f.shockc1 },
    { f.shockc2 },
    { f.shockc3 },
    { f.shockc4 },
    { f.shockc5 },
    { f.shockc6 },
    { f.shockc7 },
    { f.shockc8 },
    { f.shockc9 },
    { f.shockc10 },
}, function() return boss_death end)

boss_death = animation.hold({
    { f.death1, function(self) quake.sound(self, C.CHAN_VOICE, "boss1/death.wav", 1, C.ATTN_NORM) end },
    { f.death2 },
    { f.death3 },
    { f.death4 },
    { f.death5 },
    { f.death6 },
    { f.death7 },
    { f.death8 },
    { f.death9, function(self)
        quake.sound(self, CHAN_BODY, "boss1/out1.wav", 1, C.ATTN_NORM)
        quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
        quake.write_byte(MSG_BROADCAST, TE_LAVASPLASH)
        quake.write_coord(MSG_BROADCAST, self.origin.x)
        quake.write_coord(MSG_BROADCAST, self.origin.y)
        quake.write_coord(MSG_BROADCAST, self.origin.z)
    end },
    { f.death9, function(self)
        quake.globals.killed_monsters = quake.globals.killed_monsters + 1
        quake.write_byte(C.MSG_ALL, C.SVC_KILLEDMONSTER) -- FIXME: reliable broadcast
        subs.use_targets(self, quake.globals.activator)
        quake.remove(self)
    end },
})

---@param self entity
---@param p vec3
---@return nil
function boss_launch_missile(self, p)
    local offang = quake.vector_to_angles(self.enemy.origin - self.origin)
    local vectors = quake.make_vectors(offang)

    local org = self.origin + vectors.forward * p.x + vectors.right * p.y + quake.vec3(0, 0, p.z)
    local d

    -- lead the player on hard mode
    if quake.cvar("skill") > 1 then
        local t = (self.enemy.origin - org):length() / 300
        local vec = self.enemy.velocity
        vec = quake.vec3(vec.x, vec.y, 0)
        d = self.enemy.origin + vec * t
    else
        d = self.enemy.origin
    end

    local vec = (d - org):normalized()

    local newmis = weapons.launch_spike(self, org, vec)
    quake.set_model(newmis, "progs/lavaball.mdl")
    newmis.avelocity = quake.vec3(200, 100, 300)
    quake.set_size(newmis, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    newmis.velocity = vec * 300
    newmis.touch = weapons.missile_touch -- rocket explosion
    quake.sound(self, CHAN_WEAPON, "boss1/throw.wav", 1, C.ATTN_NORM)

    -- check for dead enemy
    if self.enemy.health <= 0 then
        boss_idle(self)
    end
end

---@param self entity
---@param activator entity
---@return nil
local boss_awake = quake.register_callback("boss.boss_awake", function(self, activator)
    self.solid = C.SOLID_SLIDEBOX
    self.movetype = C.MOVETYPE_STEP
    self.takedamage = C.DAMAGE_NO

    quake.set_model(self, "progs/boss.mdl")
    quake.set_size(self, quake.vec3(-128, -128, -24), quake.vec3(128, 128, 256))

    if quake.cvar("skill") == 0 then
        self.health = 1
    else
        self.health = 3
    end

    self.enemy = activator

    quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
    quake.write_byte(MSG_BROADCAST, TE_LAVASPLASH)
    quake.write_coord(MSG_BROADCAST, self.origin.x)
    quake.write_coord(MSG_BROADCAST, self.origin.y)
    quake.write_coord(MSG_BROADCAST, self.origin.z)

    self.yaw_speed = 20
    boss_rise(self)
end)

---QUAKED monster_boss (1 0 0) (-128 -128 -24) (128 128 256)
---@param self entity
---@return nil
local function spawn(self)
    if quake.cvar("deathmatch") ~= 0 then
        quake.remove(self)
        return
    end
    quake.precache_model("progs/boss.mdl")
    quake.precache_model("progs/lavaball.mdl")

    quake.precache_sound("weapons/rocket1i.wav")
    quake.precache_sound("boss1/out1.wav")
    quake.precache_sound("boss1/sight1.wav")
    quake.precache_sound("misc/power.wav")
    quake.precache_sound("boss1/throw.wav")
    quake.precache_sound("boss1/pain.wav")
    quake.precache_sound("boss1/death.wav")

    quake.globals.total_monsters = quake.globals.total_monsters + 1

    self.use = boss_awake
end

--===========================================================================

---@param self entity
---@return nil
local function lightning_fire(self)
    local le1 = assert(quake.globals.le1, "first lightning endpoint is missing")
    local le2 = assert(quake.globals.le2, "second lightning endpoint is missing")
    if quake.time() >= quake.globals.lightning_end then
        -- done here, put the terminals back up
        doors.go_down(le1)
        doors.go_down(le2)
        return
    end

    local p1 = (le1.mins + le1.maxs) * 0.5
    p1 = quake.vec3(p1.x, p1.y, le1.absmin.z - 16)

    local p2 = (le2.mins + le2.maxs) * 0.5
    p2 = quake.vec3(p2.x, p2.y, le2.absmin.z - 16)

    -- compensate for length of bolt
    p2 = p2 - (p2 - p1):normalized() * 100

    self.nextthink = quake.time() + 0.1
    self.think = lightning_fire

    quake.write_byte(C.MSG_ALL, SVC_TEMPENTITY)
    quake.write_byte(C.MSG_ALL, TE_LIGHTNING3)
    quake.write_entity(C.MSG_ALL, quake.world)
    quake.write_coord(C.MSG_ALL, p1.x)
    quake.write_coord(C.MSG_ALL, p1.y)
    quake.write_coord(C.MSG_ALL, p1.z)
    quake.write_coord(C.MSG_ALL, p2.x)
    quake.write_coord(C.MSG_ALL, p2.y)
    quake.write_coord(C.MSG_ALL, p2.z)
end
quake.register_callback("boss.lightning_fire", lightning_fire)

---@param self entity
---@param activator entity
---@return nil
local lightning_use = quake.register_callback("boss.lightning_use", function(self, activator)
    if quake.globals.lightning_end >= quake.time() + 1 then
        return
    end

    local le1 = quake.find(quake.world, "target", "lightning")
    local le2 = quake.find(le1, "target", "lightning")
    quake.globals.le1 = le1
    quake.globals.le2 = le2
    if not le1 or not le2 then
        quake.dprint("missing lightning targets\n")
        return
    end

    if (le1.state ~= STATE_TOP and le1.state ~= STATE_BOTTOM)
        or (le2.state ~= STATE_TOP and le2.state ~= STATE_BOTTOM)
        or le1.state ~= le2.state then
        return
    end

    -- don't let the electrodes go back up until the bolt is done
    le1.nextthink = -1
    le2.nextthink = -1
    quake.globals.lightning_end = quake.time() + 1

    quake.sound(self, C.CHAN_VOICE, "misc/power.wav", 1, C.ATTN_NORM)
    lightning_fire(self)

    -- advance the boss pain if down
    local boss = quake.find(quake.world, "classname", "monster_boss")
    if not boss then
        return
    end
    boss.enemy = activator
    if le1.state == STATE_TOP and boss.health > 0 then
        quake.sound(boss, C.CHAN_VOICE, "boss1/pain.wav", 1, C.ATTN_NORM)
        boss.health = boss.health - 1
        if boss.health >= 2 then
            boss_shocka(boss)
        elseif boss.health == 1 then
            boss_shockb(boss)
        elseif boss.health == 0 then
            boss_shockc(boss)
        end
    end
end)

---QUAKED event_lightning (0 1 1) (-16 -16 -16) (16 16 16)
---Just for boss level.
---@param self entity
---@return nil
local function spawn_lightning(self)
    self.use = lightning_use
end

quake.register_entity("monster_boss", spawn)
quake.register_entity("event_lightning", spawn_lightning)
