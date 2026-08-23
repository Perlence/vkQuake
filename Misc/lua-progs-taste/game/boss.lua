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

local M = {}

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

local boss_launch_missile

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

local boss_missile = {}

local boss_rise = {}
boss_rise[1] = animation.frame(f.rise1, function() return boss_rise[2] end, function(self) quake.sound(self, CHAN_WEAPON, "boss1/out1.wav", 1, C.ATTN_NORM) end)
boss_rise[2] = animation.frame(f.rise2, function() return boss_rise[3] end, function(self) quake.sound(self, C.CHAN_VOICE, "boss1/sight1.wav", 1, C.ATTN_NORM) end)
boss_rise[3] = animation.frame(f.rise3, function() return boss_rise[4] end)
boss_rise[4] = animation.frame(f.rise4, function() return boss_rise[5] end)
boss_rise[5] = animation.frame(f.rise5, function() return boss_rise[6] end)
boss_rise[6] = animation.frame(f.rise6, function() return boss_rise[7] end)
boss_rise[7] = animation.frame(f.rise7, function() return boss_rise[8] end)
boss_rise[8] = animation.frame(f.rise8, function() return boss_rise[9] end)
boss_rise[9] = animation.frame(f.rise9, function() return boss_rise[10] end)
boss_rise[10] = animation.frame(f.rise10, function() return boss_rise[11] end)
boss_rise[11] = animation.frame(f.rise11, function() return boss_rise[12] end)
boss_rise[12] = animation.frame(f.rise12, function() return boss_rise[13] end)
boss_rise[13] = animation.frame(f.rise13, function() return boss_rise[14] end)
boss_rise[14] = animation.frame(f.rise14, function() return boss_rise[15] end)
boss_rise[15] = animation.frame(f.rise15, function() return boss_rise[16] end)
boss_rise[16] = animation.frame(f.rise16, function() return boss_rise[17] end)
boss_rise[17] = animation.frame(f.rise17, function() return boss_missile[1] end)

local boss_idle = {}
boss_idle[1] = animation.frame(f.walk1, function() return boss_idle[2] end, function(_self)
    -- look for other players
end)
boss_idle[2] = animation.frame(f.walk2, function() return boss_idle[3] end, boss_face)
boss_idle[3] = animation.frame(f.walk3, function() return boss_idle[4] end, boss_face)
boss_idle[4] = animation.frame(f.walk4, function() return boss_idle[5] end, boss_face)
boss_idle[5] = animation.frame(f.walk5, function() return boss_idle[6] end, boss_face)
boss_idle[6] = animation.frame(f.walk6, function() return boss_idle[7] end, boss_face)
boss_idle[7] = animation.frame(f.walk7, function() return boss_idle[8] end, boss_face)
boss_idle[8] = animation.frame(f.walk8, function() return boss_idle[9] end, boss_face)
boss_idle[9] = animation.frame(f.walk9, function() return boss_idle[10] end, boss_face)
boss_idle[10] = animation.frame(f.walk10, function() return boss_idle[11] end, boss_face)
boss_idle[11] = animation.frame(f.walk11, function() return boss_idle[12] end, boss_face)
boss_idle[12] = animation.frame(f.walk12, function() return boss_idle[13] end, boss_face)
boss_idle[13] = animation.frame(f.walk13, function() return boss_idle[14] end, boss_face)
boss_idle[14] = animation.frame(f.walk14, function() return boss_idle[15] end, boss_face)
boss_idle[15] = animation.frame(f.walk15, function() return boss_idle[16] end, boss_face)
boss_idle[16] = animation.frame(f.walk16, function() return boss_idle[17] end, boss_face)
boss_idle[17] = animation.frame(f.walk17, function() return boss_idle[18] end, boss_face)
boss_idle[18] = animation.frame(f.walk18, function() return boss_idle[19] end, boss_face)
boss_idle[19] = animation.frame(f.walk19, function() return boss_idle[20] end, boss_face)
boss_idle[20] = animation.frame(f.walk20, function() return boss_idle[21] end, boss_face)
boss_idle[21] = animation.frame(f.walk21, function() return boss_idle[22] end, boss_face)
boss_idle[22] = animation.frame(f.walk22, function() return boss_idle[23] end, boss_face)
boss_idle[23] = animation.frame(f.walk23, function() return boss_idle[24] end, boss_face)
boss_idle[24] = animation.frame(f.walk24, function() return boss_idle[25] end, boss_face)
boss_idle[25] = animation.frame(f.walk25, function() return boss_idle[26] end, boss_face)
boss_idle[26] = animation.frame(f.walk26, function() return boss_idle[27] end, boss_face)
boss_idle[27] = animation.frame(f.walk27, function() return boss_idle[28] end, boss_face)
boss_idle[28] = animation.frame(f.walk28, function() return boss_idle[29] end, boss_face)
boss_idle[29] = animation.frame(f.walk29, function() return boss_idle[30] end, boss_face)
boss_idle[30] = animation.frame(f.walk30, function() return boss_idle[31] end, boss_face)
boss_idle[31] = animation.frame(f.walk31, function() return boss_idle[1] end, boss_face)

boss_missile[1] = animation.frame(f.attack1, function() return boss_missile[2] end, boss_face)
boss_missile[2] = animation.frame(f.attack2, function() return boss_missile[3] end, boss_face)
boss_missile[3] = animation.frame(f.attack3, function() return boss_missile[4] end, boss_face)
boss_missile[4] = animation.frame(f.attack4, function() return boss_missile[5] end, boss_face)
boss_missile[5] = animation.frame(f.attack5, function() return boss_missile[6] end, boss_face)
boss_missile[6] = animation.frame(f.attack6, function() return boss_missile[7] end, boss_face)
boss_missile[7] = animation.frame(f.attack7, function() return boss_missile[8] end, boss_face)
boss_missile[8] = animation.frame(f.attack8, function() return boss_missile[9] end, boss_face)
boss_missile[9] = animation.frame(f.attack9, function() return boss_missile[10] end, function(self) boss_launch_missile(self, quake.vec3(100, 100, 200)) end)
boss_missile[10] = animation.frame(f.attack10, function() return boss_missile[11] end, boss_face)
boss_missile[11] = animation.frame(f.attack11, function() return boss_missile[12] end, boss_face)
boss_missile[12] = animation.frame(f.attack12, function() return boss_missile[13] end, boss_face)
boss_missile[13] = animation.frame(f.attack13, function() return boss_missile[14] end, boss_face)
boss_missile[14] = animation.frame(f.attack14, function() return boss_missile[15] end, boss_face)
boss_missile[15] = animation.frame(f.attack15, function() return boss_missile[16] end, boss_face)
boss_missile[16] = animation.frame(f.attack16, function() return boss_missile[17] end, boss_face)
boss_missile[17] = animation.frame(f.attack17, function() return boss_missile[18] end, boss_face)
boss_missile[18] = animation.frame(f.attack18, function() return boss_missile[19] end, boss_face)
boss_missile[19] = animation.frame(f.attack19, function() return boss_missile[20] end, boss_face)
boss_missile[20] = animation.frame(f.attack20, function() return boss_missile[21] end, function(self) boss_launch_missile(self, quake.vec3(100, -100, 200)) end)
boss_missile[21] = animation.frame(f.attack21, function() return boss_missile[22] end, boss_face)
boss_missile[22] = animation.frame(f.attack22, function() return boss_missile[23] end, boss_face)
boss_missile[23] = animation.frame(f.attack23, function() return boss_missile[1] end, boss_face)

local boss_shocka = {}
boss_shocka[1] = animation.frame(f.shocka1, function() return boss_shocka[2] end)
boss_shocka[2] = animation.frame(f.shocka2, function() return boss_shocka[3] end)
boss_shocka[3] = animation.frame(f.shocka3, function() return boss_shocka[4] end)
boss_shocka[4] = animation.frame(f.shocka4, function() return boss_shocka[5] end)
boss_shocka[5] = animation.frame(f.shocka5, function() return boss_shocka[6] end)
boss_shocka[6] = animation.frame(f.shocka6, function() return boss_shocka[7] end)
boss_shocka[7] = animation.frame(f.shocka7, function() return boss_shocka[8] end)
boss_shocka[8] = animation.frame(f.shocka8, function() return boss_shocka[9] end)
boss_shocka[9] = animation.frame(f.shocka9, function() return boss_shocka[10] end)
boss_shocka[10] = animation.frame(f.shocka10, function() return boss_missile[1] end)

local boss_shockb = {}
boss_shockb[1] = animation.frame(f.shockb1, function() return boss_shockb[2] end)
boss_shockb[2] = animation.frame(f.shockb2, function() return boss_shockb[3] end)
boss_shockb[3] = animation.frame(f.shockb3, function() return boss_shockb[4] end)
boss_shockb[4] = animation.frame(f.shockb4, function() return boss_shockb[5] end)
boss_shockb[5] = animation.frame(f.shockb5, function() return boss_shockb[6] end)
boss_shockb[6] = animation.frame(f.shockb6, function() return boss_shockb[7] end)
boss_shockb[7] = animation.frame(f.shockb1, function() return boss_shockb[8] end)
boss_shockb[8] = animation.frame(f.shockb2, function() return boss_shockb[9] end)
boss_shockb[9] = animation.frame(f.shockb3, function() return boss_shockb[10] end)
boss_shockb[10] = animation.frame(f.shockb4, function() return boss_missile[1] end)

local boss_death = {}

local boss_shockc = {}
boss_shockc[1] = animation.frame(f.shockc1, function() return boss_shockc[2] end)
boss_shockc[2] = animation.frame(f.shockc2, function() return boss_shockc[3] end)
boss_shockc[3] = animation.frame(f.shockc3, function() return boss_shockc[4] end)
boss_shockc[4] = animation.frame(f.shockc4, function() return boss_shockc[5] end)
boss_shockc[5] = animation.frame(f.shockc5, function() return boss_shockc[6] end)
boss_shockc[6] = animation.frame(f.shockc6, function() return boss_shockc[7] end)
boss_shockc[7] = animation.frame(f.shockc7, function() return boss_shockc[8] end)
boss_shockc[8] = animation.frame(f.shockc8, function() return boss_shockc[9] end)
boss_shockc[9] = animation.frame(f.shockc9, function() return boss_shockc[10] end)
boss_shockc[10] = animation.frame(f.shockc10, function() return boss_death[1] end)

boss_death[1] = animation.frame(f.death1, function() return boss_death[2] end, function(self) quake.sound(self, C.CHAN_VOICE, "boss1/death.wav", 1, C.ATTN_NORM) end)
boss_death[2] = animation.frame(f.death2, function() return boss_death[3] end)
boss_death[3] = animation.frame(f.death3, function() return boss_death[4] end)
boss_death[4] = animation.frame(f.death4, function() return boss_death[5] end)
boss_death[5] = animation.frame(f.death5, function() return boss_death[6] end)
boss_death[6] = animation.frame(f.death6, function() return boss_death[7] end)
boss_death[7] = animation.frame(f.death7, function() return boss_death[8] end)
boss_death[8] = animation.frame(f.death8, function() return boss_death[9] end)
boss_death[9] = animation.frame(f.death9, function() return boss_death[10] end, function(self)
    quake.sound(self, CHAN_BODY, "boss1/out1.wav", 1, C.ATTN_NORM)
    quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
    quake.write_byte(MSG_BROADCAST, TE_LAVASPLASH)
    quake.write_coord(MSG_BROADCAST, self.origin.x)
    quake.write_coord(MSG_BROADCAST, self.origin.y)
    quake.write_coord(MSG_BROADCAST, self.origin.z)
end)
boss_death[10] = animation.frame(f.death9, function() return boss_death[10] end, function(self)
    quake.globals.killed_monsters = quake.globals.killed_monsters + 1
    quake.write_byte(C.MSG_ALL, C.SVC_KILLEDMONSTER) -- FIXME: reliable broadcast
    subs.use_targets(self, quake.globals.activator)
    quake.remove(self)
end)

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
        boss_idle[1](self)
    end
end

---@param self entity
---@param activator entity
---@return nil
local function boss_awake(self, activator)
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
    boss_rise[1](self)
end

---QUAKED monster_boss (1 0 0) (-128 -128 -24) (128 128 256)
---@param self entity
---@return nil
function M.spawn(self)
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

---@param self entity
---@param activator entity
---@return nil
local function lightning_use(self, activator)
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
            boss_shocka[1](boss)
        elseif boss.health == 1 then
            boss_shockb[1](boss)
        elseif boss.health == 0 then
            boss_shockc[1](boss)
        end
    end
end

---QUAKED event_lightning (0 1 1) (-16 -16 -16) (16 16 16)
---Just for boss level.
---@param self entity
---@return nil
function M.spawn_lightning(self)
    self.use = lightning_use
end

quake.register_entity("monster_boss", M.spawn)
quake.register_entity("event_lightning", M.spawn_lightning)

return M
