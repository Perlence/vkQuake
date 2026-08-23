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

local boss_missile

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

local boss_missile1

local boss_rise1, boss_rise2, boss_rise3, boss_rise4, boss_rise5, boss_rise6
local boss_rise7, boss_rise8, boss_rise9, boss_rise10, boss_rise11, boss_rise12
local boss_rise13, boss_rise14, boss_rise15, boss_rise16, boss_rise17

boss_rise1 = animation.frame("rise1", function() return boss_rise2 end, function(self) quake.sound(self, CHAN_WEAPON, "boss1/out1.wav", 1, C.ATTN_NORM) end)
boss_rise2 = animation.frame("rise2", function() return boss_rise3 end, function(self) quake.sound(self, C.CHAN_VOICE, "boss1/sight1.wav", 1, C.ATTN_NORM) end)
boss_rise3 = animation.frame("rise3", function() return boss_rise4 end)
boss_rise4 = animation.frame("rise4", function() return boss_rise5 end)
boss_rise5 = animation.frame("rise5", function() return boss_rise6 end)
boss_rise6 = animation.frame("rise6", function() return boss_rise7 end)
boss_rise7 = animation.frame("rise7", function() return boss_rise8 end)
boss_rise8 = animation.frame("rise8", function() return boss_rise9 end)
boss_rise9 = animation.frame("rise9", function() return boss_rise10 end)
boss_rise10 = animation.frame("rise10", function() return boss_rise11 end)
boss_rise11 = animation.frame("rise11", function() return boss_rise12 end)
boss_rise12 = animation.frame("rise12", function() return boss_rise13 end)
boss_rise13 = animation.frame("rise13", function() return boss_rise14 end)
boss_rise14 = animation.frame("rise14", function() return boss_rise15 end)
boss_rise15 = animation.frame("rise15", function() return boss_rise16 end)
boss_rise16 = animation.frame("rise16", function() return boss_rise17 end)
boss_rise17 = animation.frame("rise17", function() return boss_missile1 end)

local boss_idle1, boss_idle2, boss_idle3, boss_idle4, boss_idle5, boss_idle6
local boss_idle7, boss_idle8, boss_idle9, boss_idle10, boss_idle11, boss_idle12
local boss_idle13, boss_idle14, boss_idle15, boss_idle16, boss_idle17, boss_idle18
local boss_idle19, boss_idle20, boss_idle21, boss_idle22, boss_idle23, boss_idle24
local boss_idle25, boss_idle26, boss_idle27, boss_idle28, boss_idle29, boss_idle30
local boss_idle31

boss_idle1 = animation.frame("walk1", function() return boss_idle2 end, function(_self)
    -- look for other players
end)
boss_idle2 = animation.frame("walk2", function() return boss_idle3 end, boss_face)
boss_idle3 = animation.frame("walk3", function() return boss_idle4 end, boss_face)
boss_idle4 = animation.frame("walk4", function() return boss_idle5 end, boss_face)
boss_idle5 = animation.frame("walk5", function() return boss_idle6 end, boss_face)
boss_idle6 = animation.frame("walk6", function() return boss_idle7 end, boss_face)
boss_idle7 = animation.frame("walk7", function() return boss_idle8 end, boss_face)
boss_idle8 = animation.frame("walk8", function() return boss_idle9 end, boss_face)
boss_idle9 = animation.frame("walk9", function() return boss_idle10 end, boss_face)
boss_idle10 = animation.frame("walk10", function() return boss_idle11 end, boss_face)
boss_idle11 = animation.frame("walk11", function() return boss_idle12 end, boss_face)
boss_idle12 = animation.frame("walk12", function() return boss_idle13 end, boss_face)
boss_idle13 = animation.frame("walk13", function() return boss_idle14 end, boss_face)
boss_idle14 = animation.frame("walk14", function() return boss_idle15 end, boss_face)
boss_idle15 = animation.frame("walk15", function() return boss_idle16 end, boss_face)
boss_idle16 = animation.frame("walk16", function() return boss_idle17 end, boss_face)
boss_idle17 = animation.frame("walk17", function() return boss_idle18 end, boss_face)
boss_idle18 = animation.frame("walk18", function() return boss_idle19 end, boss_face)
boss_idle19 = animation.frame("walk19", function() return boss_idle20 end, boss_face)
boss_idle20 = animation.frame("walk20", function() return boss_idle21 end, boss_face)
boss_idle21 = animation.frame("walk21", function() return boss_idle22 end, boss_face)
boss_idle22 = animation.frame("walk22", function() return boss_idle23 end, boss_face)
boss_idle23 = animation.frame("walk23", function() return boss_idle24 end, boss_face)
boss_idle24 = animation.frame("walk24", function() return boss_idle25 end, boss_face)
boss_idle25 = animation.frame("walk25", function() return boss_idle26 end, boss_face)
boss_idle26 = animation.frame("walk26", function() return boss_idle27 end, boss_face)
boss_idle27 = animation.frame("walk27", function() return boss_idle28 end, boss_face)
boss_idle28 = animation.frame("walk28", function() return boss_idle29 end, boss_face)
boss_idle29 = animation.frame("walk29", function() return boss_idle30 end, boss_face)
boss_idle30 = animation.frame("walk30", function() return boss_idle31 end, boss_face)
boss_idle31 = animation.frame("walk31", function() return boss_idle1 end, boss_face)

local boss_missile2, boss_missile3, boss_missile4, boss_missile5, boss_missile6, boss_missile7
local boss_missile8, boss_missile9, boss_missile10, boss_missile11, boss_missile12, boss_missile13
local boss_missile14, boss_missile15, boss_missile16, boss_missile17, boss_missile18, boss_missile19
local boss_missile20, boss_missile21, boss_missile22, boss_missile23

boss_missile1 = animation.frame("attack1", function() return boss_missile2 end, boss_face)
boss_missile2 = animation.frame("attack2", function() return boss_missile3 end, boss_face)
boss_missile3 = animation.frame("attack3", function() return boss_missile4 end, boss_face)
boss_missile4 = animation.frame("attack4", function() return boss_missile5 end, boss_face)
boss_missile5 = animation.frame("attack5", function() return boss_missile6 end, boss_face)
boss_missile6 = animation.frame("attack6", function() return boss_missile7 end, boss_face)
boss_missile7 = animation.frame("attack7", function() return boss_missile8 end, boss_face)
boss_missile8 = animation.frame("attack8", function() return boss_missile9 end, boss_face)
boss_missile9 = animation.frame("attack9", function() return boss_missile10 end, function(self) boss_missile(self, quake.vec3(100, 100, 200)) end)
boss_missile10 = animation.frame("attack10", function() return boss_missile11 end, boss_face)
boss_missile11 = animation.frame("attack11", function() return boss_missile12 end, boss_face)
boss_missile12 = animation.frame("attack12", function() return boss_missile13 end, boss_face)
boss_missile13 = animation.frame("attack13", function() return boss_missile14 end, boss_face)
boss_missile14 = animation.frame("attack14", function() return boss_missile15 end, boss_face)
boss_missile15 = animation.frame("attack15", function() return boss_missile16 end, boss_face)
boss_missile16 = animation.frame("attack16", function() return boss_missile17 end, boss_face)
boss_missile17 = animation.frame("attack17", function() return boss_missile18 end, boss_face)
boss_missile18 = animation.frame("attack18", function() return boss_missile19 end, boss_face)
boss_missile19 = animation.frame("attack19", function() return boss_missile20 end, boss_face)
boss_missile20 = animation.frame("attack20", function() return boss_missile21 end, function(self) boss_missile(self, quake.vec3(100, -100, 200)) end)
boss_missile21 = animation.frame("attack21", function() return boss_missile22 end, boss_face)
boss_missile22 = animation.frame("attack22", function() return boss_missile23 end, boss_face)
boss_missile23 = animation.frame("attack23", function() return boss_missile1 end, boss_face)

local boss_shocka1, boss_shocka2, boss_shocka3, boss_shocka4, boss_shocka5, boss_shocka6
local boss_shocka7, boss_shocka8, boss_shocka9, boss_shocka10

boss_shocka1 = animation.frame("shocka1", function() return boss_shocka2 end)
boss_shocka2 = animation.frame("shocka2", function() return boss_shocka3 end)
boss_shocka3 = animation.frame("shocka3", function() return boss_shocka4 end)
boss_shocka4 = animation.frame("shocka4", function() return boss_shocka5 end)
boss_shocka5 = animation.frame("shocka5", function() return boss_shocka6 end)
boss_shocka6 = animation.frame("shocka6", function() return boss_shocka7 end)
boss_shocka7 = animation.frame("shocka7", function() return boss_shocka8 end)
boss_shocka8 = animation.frame("shocka8", function() return boss_shocka9 end)
boss_shocka9 = animation.frame("shocka9", function() return boss_shocka10 end)
boss_shocka10 = animation.frame("shocka10", function() return boss_missile1 end)

local boss_shockb1, boss_shockb2, boss_shockb3, boss_shockb4, boss_shockb5, boss_shockb6
local boss_shockb7, boss_shockb8, boss_shockb9, boss_shockb10

boss_shockb1 = animation.frame("shockb1", function() return boss_shockb2 end)
boss_shockb2 = animation.frame("shockb2", function() return boss_shockb3 end)
boss_shockb3 = animation.frame("shockb3", function() return boss_shockb4 end)
boss_shockb4 = animation.frame("shockb4", function() return boss_shockb5 end)
boss_shockb5 = animation.frame("shockb5", function() return boss_shockb6 end)
boss_shockb6 = animation.frame("shockb6", function() return boss_shockb7 end)
boss_shockb7 = animation.frame("shockb1", function() return boss_shockb8 end)
boss_shockb8 = animation.frame("shockb2", function() return boss_shockb9 end)
boss_shockb9 = animation.frame("shockb3", function() return boss_shockb10 end)
boss_shockb10 = animation.frame("shockb4", function() return boss_missile1 end)

local boss_death1

local boss_shockc1, boss_shockc2, boss_shockc3, boss_shockc4, boss_shockc5, boss_shockc6
local boss_shockc7, boss_shockc8, boss_shockc9, boss_shockc10

boss_shockc1 = animation.frame("shockc1", function() return boss_shockc2 end)
boss_shockc2 = animation.frame("shockc2", function() return boss_shockc3 end)
boss_shockc3 = animation.frame("shockc3", function() return boss_shockc4 end)
boss_shockc4 = animation.frame("shockc4", function() return boss_shockc5 end)
boss_shockc5 = animation.frame("shockc5", function() return boss_shockc6 end)
boss_shockc6 = animation.frame("shockc6", function() return boss_shockc7 end)
boss_shockc7 = animation.frame("shockc7", function() return boss_shockc8 end)
boss_shockc8 = animation.frame("shockc8", function() return boss_shockc9 end)
boss_shockc9 = animation.frame("shockc9", function() return boss_shockc10 end)
boss_shockc10 = animation.frame("shockc10", function() return boss_death1 end)

local boss_death2, boss_death3, boss_death4, boss_death5, boss_death6, boss_death7
local boss_death8, boss_death9, boss_death10

boss_death1 = animation.frame("death1", function() return boss_death2 end, function(self) quake.sound(self, C.CHAN_VOICE, "boss1/death.wav", 1, C.ATTN_NORM) end)
boss_death2 = animation.frame("death2", function() return boss_death3 end)
boss_death3 = animation.frame("death3", function() return boss_death4 end)
boss_death4 = animation.frame("death4", function() return boss_death5 end)
boss_death5 = animation.frame("death5", function() return boss_death6 end)
boss_death6 = animation.frame("death6", function() return boss_death7 end)
boss_death7 = animation.frame("death7", function() return boss_death8 end)
boss_death8 = animation.frame("death8", function() return boss_death9 end)
boss_death9 = animation.frame("death9", function() return boss_death10 end, function(self)
    quake.sound(self, CHAN_BODY, "boss1/out1.wav", 1, C.ATTN_NORM)
    quake.write_byte(MSG_BROADCAST, SVC_TEMPENTITY)
    quake.write_byte(MSG_BROADCAST, TE_LAVASPLASH)
    quake.write_coord(MSG_BROADCAST, self.origin.x)
    quake.write_coord(MSG_BROADCAST, self.origin.y)
    quake.write_coord(MSG_BROADCAST, self.origin.z)
end)
boss_death10 = animation.frame("death9", function() return boss_death10 end, function(self)
    quake.globals.killed_monsters = quake.globals.killed_monsters + 1
    quake.write_byte(C.MSG_ALL, C.SVC_KILLEDMONSTER) -- FIXME: reliable broadcast
    subs.use_targets(self, quake.globals.activator)
    quake.remove(self)
end)

---@param self entity
---@param p vec3
---@return nil
boss_missile = function(self, p)
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
        boss_idle1(self)
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
    boss_rise1(self)
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
            boss_shocka1(boss)
        elseif boss.health == 1 then
            boss_shockb1(boss)
        elseif boss.health == 0 then
            boss_shockc1(boss)
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
