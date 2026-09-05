-- Port of player.qc from GPL-licensed CleanFixedQuakeC.
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

local animation = require("animation")
local subs = require("subs")

local M = {}
local g = quake.globals

local IT_AXE = 4096
local IT_INVISIBILITY = 524288
local EF_MUZZLEFLASH = 2
local CHAN_VOICE, ATTN_NONE, ATTN_NORM = 2, 0, 1
local CONTENT_WATER, CONTENT_SLIME, CONTENT_LAVA = -3, -4, -5
local MOVETYPE_NONE, MOVETYPE_TOSS, MOVETYPE_NOCLIP, MOVETYPE_BOUNCE = 0, 6, 8, 10
local SOLID_NOT, DAMAGE_NO, DEAD_DYING, DEAD_DEAD = 0, 0, 1, 2
local FL_ONGROUND = 512

--[[
==============================================================================

PLAYER

==============================================================================
]]

local count = animation.counter()
local f = {}

-- running
f.axrun1, f.axrun2, f.axrun3, f.axrun4, f.axrun5, f.axrun6 = count(6)
f.rockrun1, f.rockrun2, f.rockrun3, f.rockrun4, f.rockrun5, f.rockrun6 = count(6)

-- standing
f.stand1, f.stand2, f.stand3, f.stand4, f.stand5 = count(5)
f.axstnd1, f.axstnd2, f.axstnd3, f.axstnd4, f.axstnd5, f.axstnd6,
f.axstnd7, f.axstnd8, f.axstnd9, f.axstnd10, f.axstnd11, f.axstnd12 = count(12)

-- pain
f.axpain1, f.axpain2, f.axpain3, f.axpain4, f.axpain5, f.axpain6 = count(6)
f.pain1, f.pain2, f.pain3, f.pain4, f.pain5, f.pain6 = count(6)

-- death
f.axdeth1, f.axdeth2, f.axdeth3, f.axdeth4, f.axdeth5, f.axdeth6,
f.axdeth7, f.axdeth8, f.axdeth9 = count(9)
f.deatha1, f.deatha2, f.deatha3, f.deatha4, f.deatha5, f.deatha6,
f.deatha7, f.deatha8, f.deatha9, f.deatha10, f.deatha11 = count(11)
f.deathb1, f.deathb2, f.deathb3, f.deathb4, f.deathb5, f.deathb6,
f.deathb7, f.deathb8, f.deathb9 = count(9)
f.deathc1, f.deathc2, f.deathc3, f.deathc4, f.deathc5, f.deathc6,
f.deathc7, f.deathc8, f.deathc9, f.deathc10, f.deathc11, f.deathc12,
f.deathc13, f.deathc14, f.deathc15 = count(15)
f.deathd1, f.deathd2, f.deathd3, f.deathd4, f.deathd5, f.deathd6,
f.deathd7, f.deathd8, f.deathd9 = count(9)
f.deathe1, f.deathe2, f.deathe3, f.deathe4, f.deathe5, f.deathe6,
f.deathe7, f.deathe8, f.deathe9 = count(9)

-- attacks
f.nailatt1, f.nailatt2 = count(2)
f.light1, f.light2 = count(2)
f.rockatt1, f.rockatt2, f.rockatt3, f.rockatt4, f.rockatt5, f.rockatt6 = count(6)
f.shotatt1, f.shotatt2, f.shotatt3, f.shotatt4, f.shotatt5, f.shotatt6 = count(6)
f.axatt1, f.axatt2, f.axatt3, f.axatt4, f.axatt5, f.axatt6 = count(6)
f.axattb1, f.axattb2, f.axattb3, f.axattb4, f.axattb5, f.axattb6 = count(6)
f.axattc1, f.axattc2, f.axattc3, f.axattc4, f.axattc5, f.axattc6 = count(6)
f.axattd1, f.axattd2, f.axattd3, f.axattd4, f.axattd5, f.axattd6 = count(6)

local player_run1
local player_stand1 = animation.loop("player.player_stand1", {
    { f.axstnd1, function(self)
        self.weaponframe = 0
        if self.velocity.x ~= 0 or self.velocity.y ~= 0 then
            self.walkframe = 0
            player_run1(self)
            return
        end
        if self.weapon == IT_AXE then
            if self.walkframe >= 12 then self.walkframe = 0 end
            self.frame = f.axstnd1 + self.walkframe
        else
            if self.walkframe >= 5 then self.walkframe = 0 end
            self.frame = f.stand1 + self.walkframe
        end
        self.walkframe = self.walkframe + 1
    end },
})

player_run1 = animation.loop("player.player_run1", {
    { f.rockrun1, function(self)
        self.weaponframe = 0
        if self.velocity.x == 0 and self.velocity.y == 0 then
            self.walkframe = 0
            player_stand1(self)
            return
        end
        if self.weapon == IT_AXE then
            if self.walkframe == 6 then self.walkframe = 0 end
            self.frame = f.axrun1 + self.walkframe
        else
            if self.walkframe == 6 then self.walkframe = 0 end
            self.frame = f.rockrun1 + self.walkframe
        end
        self.walkframe = self.walkframe + 1
    end },
})

local player_shot = animation.sequence("player.player_shot", {
    { f.shotatt1, function(self)
        self.weaponframe = 1; self.effects = self.effects | EF_MUZZLEFLASH
    end },
    { f.shotatt2, function(self) self.weaponframe = 2 end },
    { f.shotatt3, function(self) self.weaponframe = 3 end },
    { f.shotatt4, function(self) self.weaponframe = 4 end },
    { f.shotatt5, function(self) self.weaponframe = 5 end },
    { f.shotatt6, function(self) self.weaponframe = 6 end },
}, function() return player_run1 end)

local player_axe = animation.sequence("player.player_axe", {
    { f.axatt1, function(self) self.weaponframe = 1 end },
    { f.axatt2, function(self) self.weaponframe = 2 end },
    { f.axatt3, function(self)
        local weapons = require("weapons")

        self.weaponframe = 3
        weapons.fire_axe(self)
    end },
    { f.axatt4, function(self) self.weaponframe = 4 end },
}, function() return player_run1 end)

local player_axeb = animation.sequence("player.player_axeb", {
    { f.axattb1, function(self) self.weaponframe = 5 end },
    { f.axattb2, function(self) self.weaponframe = 6 end },
    { f.axattb3, function(self)
        local weapons = require("weapons")

        self.weaponframe = 7
        weapons.fire_axe(self)
    end },
    { f.axattb4, function(self) self.weaponframe = 8 end },
}, function() return player_run1 end)

local player_axec = animation.sequence("player.player_axec", {
    { f.axattc1, function(self) self.weaponframe = 1 end },
    { f.axattc2, function(self) self.weaponframe = 2 end },
    { f.axattc3, function(self)
        local weapons = require("weapons")

        self.weaponframe = 3
        weapons.fire_axe(self)
    end },
    { f.axattc4, function(self) self.weaponframe = 4 end },
}, function() return player_run1 end)

local player_axed = animation.sequence("player.player_axed", {
    { f.axattd1, function(self) self.weaponframe = 5 end },
    { f.axattd2, function(self) self.weaponframe = 6 end },
    { f.axattd3, function(self)
        local weapons = require("weapons")

        self.weaponframe = 7
        weapons.fire_axe(self)
    end },
    { f.axattd4, function(self) self.weaponframe = 8 end },
}, function() return player_run1 end)

--============================================================================

local player_nail = animation.loop("player.player_nail", {
    { f.nailatt1, function(self)
        local weapons = require("weapons")

        self.effects = self.effects | EF_MUZZLEFLASH
        if not self.button0 then
            player_run1(self); return
        end
        self.weaponframe = self.weaponframe + 1
        if self.weaponframe == 9 then self.weaponframe = 1 end
        weapons.super_damage_sound(self)
        weapons.fire_spikes(self, 4)
        self.attack_finished = quake.time() + 0.2
    end },
    { f.nailatt2, function(self)
        local weapons = require("weapons")

        self.effects = self.effects | EF_MUZZLEFLASH
        if not self.button0 then
            player_run1(self); return
        end
        self.weaponframe = self.weaponframe + 1
        if self.weaponframe == 9 then self.weaponframe = 1 end
        weapons.super_damage_sound(self)
        weapons.fire_spikes(self, -4)
        self.attack_finished = quake.time() + 0.2
    end },
})

--============================================================================

local player_light = animation.loop("player.player_light", {
    { f.light1, function(self)
        local weapons = require("weapons")

        self.effects = self.effects | EF_MUZZLEFLASH
        if not self.button0 then
            player_run1(self); return
        end
        self.weaponframe = self.weaponframe + 1
        if self.weaponframe == 5 then self.weaponframe = 1 end
        weapons.super_damage_sound(self)
        weapons.fire_lightning(self)
        self.attack_finished = quake.time() + 0.2
    end },
    { f.light2, function(self)
        local weapons = require("weapons")

        self.effects = self.effects | EF_MUZZLEFLASH
        if not self.button0 then
            player_run1(self); return
        end
        self.weaponframe = self.weaponframe + 1
        if self.weaponframe == 5 then self.weaponframe = 1 end
        weapons.super_damage_sound(self)
        weapons.fire_lightning(self)
        self.attack_finished = quake.time() + 0.2
    end },
})

--============================================================================

local player_rocket = animation.sequence("player.player_rocket", {
    { f.rockatt1, function(self)
        self.weaponframe = 1; self.effects = self.effects | EF_MUZZLEFLASH
    end },
    { f.rockatt2, function(self) self.weaponframe = 2 end },
    { f.rockatt3, function(self) self.weaponframe = 3 end },
    { f.rockatt4, function(self) self.weaponframe = 4 end },
    { f.rockatt5, function(self) self.weaponframe = 5 end },
    { f.rockatt6, function(self) self.weaponframe = 6 end },
}, function() return player_run1 end)

local death_bubbles
---@param self entity
---@return nil
local function pain_sound(self)
    local attacker = g.damage_attacker or quake.world
    if self.health < 0 then return end
    if attacker.classname == "teledeath" then
        quake.sound(self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE); return
    end

    -- water pain sounds
    if self.watertype == CONTENT_WATER and self.waterlevel == 3 then
        death_bubbles(self, 1)
        if quake.random() > 0.5 then
            quake.sound(self, CHAN_VOICE, "player/drown1.wav", 1, ATTN_NORM)
        else
            quake.sound(self, CHAN_VOICE, "player/drown2.wav", 1, ATTN_NORM)
        end
        return
    end
    -- slime pain sounds
    if self.watertype == CONTENT_SLIME then
        -- FIX ME put in some steam here
        if quake.random() > 0.5 then
            quake.sound(self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM)
        else
            quake.sound(self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM)
        end
        return
    end
    if self.watertype == CONTENT_LAVA then
        if quake.random() > 0.5 then
            quake.sound(self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM)
        else
            quake.sound(self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM)
        end
        return
    end
    if self.pain_finished > quake.time() then
        self.axhitme = 0; return
    end
    self.pain_finished = quake.time() + 0.5
    -- don't make multiple pain sounds right after each other
    -- ax pain sound
    if self.axhitme == 1 then
        self.axhitme = 0; quake.sound(self, CHAN_VOICE, "player/axhit1.wav", 1, ATTN_NORM); return
    end
    local rs = math.floor(quake.random() * 5 + 1 + 0.5)
    self.noise = ""
    if rs == 1 then
        self.noise = "player/pain1.wav"
    elseif rs == 2 then
        self.noise = "player/pain2.wav"
    elseif rs == 3 then
        self.noise = "player/pain3.wav"
    elseif rs == 4 then
        self.noise = "player/pain4.wav"
    elseif rs == 5 then
        self.noise = "player/pain5.wav"
    else
        self.noise = "player/pain6.wav"
    end
    quake.sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM)
end

local player_pain = animation.sequence("player.player_pain", {
    { f.pain1, function(self)
        pain_sound(self); self.weaponframe = 0
    end },
    { f.pain2 },
    { f.pain3 },
    { f.pain4 },
    { f.pain5 },
    { f.pain6 },
}, function() return player_run1 end)

local player_axpain = animation.sequence("player.player_axpain", {
    { f.axpain1, function(self)
        pain_sound(self); self.weaponframe = 0
    end },
    { f.axpain2 },
    { f.axpain3 },
    { f.axpain4 },
    { f.axpain5 },
    { f.axpain6 },
}, function() return player_run1 end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
M.player_pain = quake.register_function("player.player_pain", function(self, _attacker, _damage)
    if self.weaponframe ~= 0 then return end
    if self.invisible_finished > quake.time() then return end -- eyes don't have pain frames
    if self.weapon == IT_AXE then player_axpain(self) else player_pain(self) end
end)

---@param self entity
---@return nil
local function death_bubbles_spawn(self)
    local misc = require("misc")

    if self.owner.waterlevel ~= 3 then return end
    local bubble = quake.spawn()
    quake.set_model(bubble, "progs/s_bubble.spr")
    quake.set_origin(bubble, self.owner.origin + quake.vec3(0, 0, 24))
    bubble.movetype = MOVETYPE_NOCLIP
    bubble.solid = SOLID_NOT
    bubble.velocity = quake.vec3(0, 0, 15)
    bubble.nextthink = quake.time() + 0.5
    bubble.think = misc.bubble_bob
    bubble.classname = "bubble"
    bubble.frame = 0
    bubble.cnt = 0
    quake.set_size(bubble, quake.vec3(-8, -8, -8), quake.vec3(8, 8, 8))
    self.nextthink = quake.time() + 0.1
    self.think = death_bubbles_spawn
    self.air_finished = self.air_finished + 1
    if self.air_finished >= self.bubble_count then quake.remove(self) end
end
quake.register_function("player.death_bubbles_spawn", death_bubbles_spawn)

---@param self entity
---@param num_bubbles integer
---@return nil
function death_bubbles(self, num_bubbles)
    local bubble_spawner = quake.spawn()
    quake.set_origin(bubble_spawner, self.origin)
    bubble_spawner.movetype = MOVETYPE_NONE
    bubble_spawner.solid = SOLID_NOT
    bubble_spawner.nextthink = quake.time() + 0.1
    bubble_spawner.think = death_bubbles_spawn
    bubble_spawner.air_finished = 0
    bubble_spawner.owner = self
    bubble_spawner.bubble_count = num_bubbles
end

---@param self entity
---@return nil
local function death_sound(self)
    -- water death sounds
    if self.waterlevel == 3 then
        death_bubbles(self, 20); quake.sound(self, CHAN_VOICE, "player/h2odeath.wav", 1, ATTN_NONE); return
    end
    local rs = math.floor(quake.random() * 4 + 1 + 0.5)
    if rs == 1 then self.noise = "player/death1.wav" end
    if rs == 2 then self.noise = "player/death2.wav" end
    if rs == 3 then self.noise = "player/death3.wav" end
    if rs == 4 then self.noise = "player/death4.wav" end
    if rs == 5 then self.noise = "player/death5.wav" end
    quake.sound(self, CHAN_VOICE, self.noise, 1, ATTN_NONE)
end

---@param self entity
---@return nil
local function player_dead(self)
    self.nextthink = -1
    -- allow respawn after a certain time
    self.deadflag = DEAD_DEAD
end

---@param self entity
---@param dm number
---@return vec3
local function velocity_for_damage(self, dm)
    local inflictor = g.damage_inflictor or quake.world
    local v
    -- check if the inflictor had velocity, e.g. like a rocket or explode box
    if inflictor.velocity:length() > 0 then
        -- impact some of inflictor's velocity on the gibs
        v = inflictor.velocity * 0.5
        v = v + (self.origin - inflictor.origin):normalized() * 25
        v = quake.vec3(v.x + 50 * quake.crandom(), v.y + 50 * quake.crandom(), 100 + 100 * quake.random())
    else
        -- use a random velocity for the gibs
        v = quake.vec3(100 * quake.crandom(), 100 * quake.crandom(), 200 + 100 * quake.random())
    end
    if dm > -50 then v = v * 0.7 elseif dm > -200 then v = v * 2 else v = v * 10 end
    return v
end

---@param self entity
---@param gibname string
---@param dm number
---@return nil
local function throw_gib(self, gibname, dm)
    local new = quake.spawn()
    new.origin = self.origin
    quake.set_model(new, gibname)
    quake.set_size(new, quake.vec3(0, 0, 0), quake.vec3(0, 0, 0))
    new.velocity = velocity_for_damage(self, dm)
    new.movetype = MOVETYPE_BOUNCE
    new.solid = SOLID_NOT
    new.avelocity = quake.vec3(quake.random() * 600, quake.random() * 600, quake.random() * 600)
    new.think = subs.remove
    new.ltime = quake.time()
    new.nextthink = quake.time() + 10 + quake.random() * 10
    new.frame = 0
    new.flags = 0
end

---@param self entity
---@param gibname string
---@param dm number
---@return nil
local function throw_head(self, gibname, dm)
    quake.set_model(self, gibname)
    self.frame = 0
    self.nextthink = -1
    self.movetype = MOVETYPE_BOUNCE
    self.takedamage = DAMAGE_NO
    self.solid = SOLID_NOT
    self.view_ofs = quake.vec3(0, 0, 8)
    quake.set_size(self, quake.vec3(-16, -16, 0), quake.vec3(16, 16, 56))
    self.velocity = velocity_for_damage(self, dm)
    self.origin = quake.vec3(self.origin.x, self.origin.y, self.origin.z - 24)
    self.flags = self.flags - (self.flags & FL_ONGROUND)
    self.avelocity = quake.vec3(0, 600, 0) * quake.crandom()
end

---@param self entity
---@return nil
local function gib_player(self)
    local attacker = g.damage_attacker or quake.world
    throw_head(self, "progs/h_player.mdl", self.health)
    throw_gib(self, "progs/gib1.mdl", self.health)
    throw_gib(self, "progs/gib2.mdl", self.health)
    throw_gib(self, "progs/gib3.mdl", self.health)
    self.deadflag = DEAD_DEAD
    if attacker.classname == "teledeath" then
        quake.sound(self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE); return
    end
    if attacker.classname == "teledeath2" then
        quake.sound(self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE); return
    end
    if quake.random() < 0.5 then
        quake.sound(self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE)
    else
        quake.sound(self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE)
    end
end

local player_diea, player_dieb, player_diec, player_died, player_diee, player_die_ax

---@param self entity
---@return nil
M.player_die = quake.register_function("player.player_die", function(self)
    local items = require("items")

    self.items = self.items - (self.items & IT_INVISIBILITY)
    -- don't die as eyes
    self.invisible_finished = 0
    self.invincible_finished = 0
    self.super_damage_finished = 0
    self.radsuit_finished = 0
    -- don't use eyes
    self.modelindex = g.modelindex_player
    if g.deathmatch ~= 0 or g.coop then items.drop_backpack(self) end
    self.weaponmodel = ""
    self.view_ofs = quake.vec3(0, 0, -8)
    self.deadflag = DEAD_DYING
    self.solid = SOLID_NOT
    self.flags = self.flags - (self.flags & FL_ONGROUND)
    self.movetype = MOVETYPE_TOSS
    if self.velocity.z < 10 then
        self.velocity = quake.vec3(self.velocity.x, self.velocity.y,
            self.velocity.z + quake.random() * 300)
    end
    if self.health < -40 then
        gib_player(self); return
    end
    death_sound(self)
    self.angles = quake.vec3(0, self.angles.y, 0)
    if self.weapon == IT_AXE then
        player_die_ax(self); return
    end
    local i = quake.cvar("temp1")
    if i == 0 then i = 1 + math.floor(quake.random() * 6) end
    if i == 1 then
        player_diea(self)
    elseif i == 2 then
        player_dieb(self)
    elseif i == 3 then
        player_diec(self)
    elseif i == 4 then
        player_died(self)
    else
        player_diee(self)
    end
end)

---@param self entity
---@return nil
function M.set_suicide_frame(self)
    -- used by kill command and disconnect command
    if self.model ~= "progs/player.mdl" then return end -- already gibbed
    self.frame = f.deatha11
    self.solid = SOLID_NOT
    self.movetype = MOVETYPE_TOSS
    self.deadflag = DEAD_DEAD
    self.nextthink = -1
end

player_diea = animation.hold("player.player_diea", {
    { f.deatha1 },
    { f.deatha2 },
    { f.deatha3 },
    { f.deatha4 },
    { f.deatha5 },
    { f.deatha6 },
    { f.deatha7 },
    { f.deatha8 },
    { f.deatha9 },
    { f.deatha10 },
    { f.deatha11, player_dead },
})

player_dieb = animation.hold("player.player_dieb", {
    { f.deathb1 },
    { f.deathb2 },
    { f.deathb3 },
    { f.deathb4 },
    { f.deathb5 },
    { f.deathb6 },
    { f.deathb7 },
    { f.deathb8 },
    { f.deathb9, player_dead },
})

player_diec = animation.hold("player.player_diec", {
    { f.deathc1 },
    { f.deathc2 },
    { f.deathc3 },
    { f.deathc4 },
    { f.deathc5 },
    { f.deathc6 },
    { f.deathc7 },
    { f.deathc8 },
    { f.deathc9 },
    { f.deathc10 },
    { f.deathc11 },
    { f.deathc12 },
    { f.deathc13 },
    { f.deathc14 },
    { f.deathc15, player_dead },
})

player_died = animation.hold("player.player_died", {
    { f.deathd1 },
    { f.deathd2 },
    { f.deathd3 },
    { f.deathd4 },
    { f.deathd5 },
    { f.deathd6 },
    { f.deathd7 },
    { f.deathd8 },
    { f.deathd9, player_dead },
})

player_diee = animation.hold("player.player_diee", {
    { f.deathe1 },
    { f.deathe2 },
    { f.deathe3 },
    { f.deathe4 },
    { f.deathe5 },
    { f.deathe6 },
    { f.deathe7 },
    { f.deathe8 },
    { f.deathe9, player_dead },
})

player_die_ax = animation.hold("player.player_die_ax", {
    { f.axdeth1 },
    { f.axdeth2 },
    { f.axdeth3 },
    { f.axdeth4 },
    { f.axdeth5 },
    { f.axdeth6 },
    { f.axdeth7 },
    { f.axdeth8 },
    { f.axdeth9, player_dead },
})

M.player_stand1 = player_stand1
M.player_run = player_run1
M.player_shot1 = player_shot
M.player_axe1 = player_axe
M.player_axeb1 = player_axeb
M.player_axec1 = player_axec
M.player_axed1 = player_axed
M.player_nail1 = player_nail
M.player_light1 = player_light
M.player_rocket1 = player_rocket

return M
