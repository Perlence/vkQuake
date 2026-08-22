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

local quake = require("quake")
local animation = require("game.animation")
local subs = require("game.subs")

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

-- running
-- standing
-- pain
-- death
-- attacks

local player_run
local player_stand1

player_stand1 = animation.frame("axstnd1", function() return player_stand1 end, function(self)
    self.weaponframe = 0
    if self.velocity.x ~= 0 or self.velocity.y ~= 0 then
        self.walkframe = 0
        player_run(self)
        return
    end
    if self.weapon == IT_AXE then
        if self.walkframe >= 12 then self.walkframe = 0 end
        self.frame = ("axstnd%d"):format(self.walkframe + 1)
    else
        if self.walkframe >= 5 then self.walkframe = 0 end
        self.frame = ("stand%d"):format(self.walkframe + 1)
    end
    self.walkframe = self.walkframe + 1
end)

player_run = animation.frame("rockrun1", function() return player_run end, function(self)
    self.weaponframe = 0
    if self.velocity.x == 0 and self.velocity.y == 0 then
        self.walkframe = 0
        player_stand1(self)
        return
    end
    if self.weapon == IT_AXE then
        if self.walkframe == 6 then self.walkframe = 0 end
        self.frame = ("axrun%d"):format(self.walkframe + 1)
    else
        if self.walkframe == 6 then self.walkframe = 0 end
        self.frame = self.frame + self.walkframe
    end
    self.walkframe = self.walkframe + 1
end)

local player_shot1, player_shot2, player_shot3, player_shot4, player_shot5, player_shot6
player_shot1 = animation.frame("shotatt1", function() return player_shot2 end, function(self) self.weaponframe = 1; self.effects = self.effects | EF_MUZZLEFLASH end)
player_shot2 = animation.frame("shotatt2", function() return player_shot3 end, function(self) self.weaponframe = 2 end)
player_shot3 = animation.frame("shotatt3", function() return player_shot4 end, function(self) self.weaponframe = 3 end)
player_shot4 = animation.frame("shotatt4", function() return player_shot5 end, function(self) self.weaponframe = 4 end)
player_shot5 = animation.frame("shotatt5", function() return player_shot6 end, function(self) self.weaponframe = 5 end)
player_shot6 = animation.frame("shotatt6", function() return player_run end, function(self) self.weaponframe = 6 end)

local player_axe1, player_axe2, player_axe3, player_axe4
player_axe1 = animation.frame("axatt1", function() return player_axe2 end, function(self) self.weaponframe = 1 end)
player_axe2 = animation.frame("axatt2", function() return player_axe3 end, function(self) self.weaponframe = 2 end)
player_axe3 = animation.frame("axatt3", function() return player_axe4 end, function(self) self.weaponframe = 3; require("game.weapons").fire_axe(self) end)
player_axe4 = animation.frame("axatt4", function() return player_run end, function(self) self.weaponframe = 4 end)

local player_axeb1, player_axeb2, player_axeb3, player_axeb4
player_axeb1 = animation.frame("axattb1", function() return player_axeb2 end, function(self) self.weaponframe = 5 end)
player_axeb2 = animation.frame("axattb2", function() return player_axeb3 end, function(self) self.weaponframe = 6 end)
player_axeb3 = animation.frame("axattb3", function() return player_axeb4 end, function(self) self.weaponframe = 7; require("game.weapons").fire_axe(self) end)
player_axeb4 = animation.frame("axattb4", function() return player_run end, function(self) self.weaponframe = 8 end)

local player_axec1, player_axec2, player_axec3, player_axec4
player_axec1 = animation.frame("axattc1", function() return player_axec2 end, function(self) self.weaponframe = 1 end)
player_axec2 = animation.frame("axattc2", function() return player_axec3 end, function(self) self.weaponframe = 2 end)
player_axec3 = animation.frame("axattc3", function() return player_axec4 end, function(self) self.weaponframe = 3; require("game.weapons").fire_axe(self) end)
player_axec4 = animation.frame("axattc4", function() return player_run end, function(self) self.weaponframe = 4 end)

local player_axed1, player_axed2, player_axed3, player_axed4
player_axed1 = animation.frame("axattd1", function() return player_axed2 end, function(self) self.weaponframe = 5 end)
player_axed2 = animation.frame("axattd2", function() return player_axed3 end, function(self) self.weaponframe = 6 end)
player_axed3 = animation.frame("axattd3", function() return player_axed4 end, function(self) self.weaponframe = 7; require("game.weapons").fire_axe(self) end)
player_axed4 = animation.frame("axattd4", function() return player_run end, function(self) self.weaponframe = 8 end)

--============================================================================
local player_nail1, player_nail2
player_nail1 = animation.frame("nailatt1", function() return player_nail2 end, function(self)
    self.effects = self.effects | EF_MUZZLEFLASH
    if self.button0 == 0 then player_run(self); return end
    self.weaponframe = self.weaponframe + 1
    if self.weaponframe == 9 then self.weaponframe = 1 end
    require("game.weapons").super_damage_sound(self)
    require("game.weapons").fire_spikes(self, 4)
    self.attack_finished = quake.time() + 0.2
end)
player_nail2 = animation.frame("nailatt2", function() return player_nail1 end, function(self)
    self.effects = self.effects | EF_MUZZLEFLASH
    if self.button0 == 0 then player_run(self); return end
    self.weaponframe = self.weaponframe + 1
    if self.weaponframe == 9 then self.weaponframe = 1 end
    require("game.weapons").super_damage_sound(self)
    require("game.weapons").fire_spikes(self, -4)
    self.attack_finished = quake.time() + 0.2
end)

--============================================================================
local player_light1, player_light2
player_light1 = animation.frame("light1", function() return player_light2 end, function(self)
    self.effects = self.effects | EF_MUZZLEFLASH
    if self.button0 == 0 then player_run(self); return end
    self.weaponframe = self.weaponframe + 1
    if self.weaponframe == 5 then self.weaponframe = 1 end
    require("game.weapons").super_damage_sound(self)
    require("game.weapons").fire_lightning(self)
    self.attack_finished = quake.time() + 0.2
end)
player_light2 = animation.frame("light2", function() return player_light1 end, function(self)
    self.effects = self.effects | EF_MUZZLEFLASH
    if self.button0 == 0 then player_run(self); return end
    self.weaponframe = self.weaponframe + 1
    if self.weaponframe == 5 then self.weaponframe = 1 end
    require("game.weapons").super_damage_sound(self)
    require("game.weapons").fire_lightning(self)
    self.attack_finished = quake.time() + 0.2
end)

--============================================================================
local player_rocket1, player_rocket2, player_rocket3, player_rocket4, player_rocket5, player_rocket6
player_rocket1 = animation.frame("rockatt1", function() return player_rocket2 end, function(self) self.weaponframe = 1; self.effects = self.effects | EF_MUZZLEFLASH end)
player_rocket2 = animation.frame("rockatt2", function() return player_rocket3 end, function(self) self.weaponframe = 2 end)
player_rocket3 = animation.frame("rockatt3", function() return player_rocket4 end, function(self) self.weaponframe = 3 end)
player_rocket4 = animation.frame("rockatt4", function() return player_rocket5 end, function(self) self.weaponframe = 4 end)
player_rocket5 = animation.frame("rockatt5", function() return player_rocket6 end, function(self) self.weaponframe = 5 end)
player_rocket6 = animation.frame("rockatt6", function() return player_run end, function(self) self.weaponframe = 6 end)

local death_bubbles
---@param self entity
---@return nil
local function pain_sound(self)
    local rs
    if self.health < 0 then return end
    if g.damage_attacker.classname == "teledeath" then quake.sound(self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE); return end

    -- water pain sounds
    if self.watertype == CONTENT_WATER and self.waterlevel == 3 then
        death_bubbles(self, 1)
        if quake.random() > 0.5 then quake.sound(self, CHAN_VOICE, "player/drown1.wav", 1, ATTN_NORM)
        else quake.sound(self, CHAN_VOICE, "player/drown2.wav", 1, ATTN_NORM) end
        return
    end
    -- slime pain sounds
    if self.watertype == CONTENT_SLIME then
        -- FIX ME put in some steam here
        if quake.random() > 0.5 then quake.sound(self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM)
        else quake.sound(self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM) end
        return
    end
    if self.watertype == CONTENT_LAVA then
        if quake.random() > 0.5 then quake.sound(self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM)
        else quake.sound(self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM) end
        return
    end
    if self.pain_finished > quake.time() then self.axhitme = 0; return end
    self.pain_finished = quake.time() + 0.5
    -- don't make multiple pain sounds right after each other
    -- ax pain sound
    if self.axhitme == 1 then self.axhitme = 0; quake.sound(self, CHAN_VOICE, "player/axhit1.wav", 1, ATTN_NORM); return end
    rs = math.floor(quake.random() * 5 + 1 + 0.5)
    self.noise = ""
    if rs == 1 then self.noise = "player/pain1.wav"
    elseif rs == 2 then self.noise = "player/pain2.wav"
    elseif rs == 3 then self.noise = "player/pain3.wav"
    elseif rs == 4 then self.noise = "player/pain4.wav"
    elseif rs == 5 then self.noise = "player/pain5.wav"
    else self.noise = "player/pain6.wav" end
    quake.sound(self, CHAN_VOICE, self.noise, 1, ATTN_NORM)
end

local player_pain1, player_pain2, player_pain3, player_pain4, player_pain5, player_pain6
player_pain1 = animation.frame("pain1", function() return player_pain2 end, function(self) pain_sound(self); self.weaponframe = 0 end)
player_pain2 = animation.frame("pain2", function() return player_pain3 end)
player_pain3 = animation.frame("pain3", function() return player_pain4 end)
player_pain4 = animation.frame("pain4", function() return player_pain5 end)
player_pain5 = animation.frame("pain5", function() return player_pain6 end)
player_pain6 = animation.frame("pain6", function() return player_run end)

local player_axpain1, player_axpain2, player_axpain3, player_axpain4, player_axpain5, player_axpain6
player_axpain1 = animation.frame("axpain1", function() return player_axpain2 end, function(self) pain_sound(self); self.weaponframe = 0 end)
player_axpain2 = animation.frame("axpain2", function() return player_axpain3 end)
player_axpain3 = animation.frame("axpain3", function() return player_axpain4 end)
player_axpain4 = animation.frame("axpain4", function() return player_axpain5 end)
player_axpain5 = animation.frame("axpain5", function() return player_axpain6 end)
player_axpain6 = animation.frame("axpain6", function() return player_run end)

---@param self entity
---@param _attacker entity
---@param _damage number
---@return nil
function M.player_pain(self, _attacker, _damage)
    if self.weaponframe ~= 0 then return end
    if self.invisible_finished > quake.time() then return end -- eyes don't have pain frames
    if self.weapon == IT_AXE then player_axpain1(self) else player_pain1(self) end
end

local player_diea1, player_diea2, player_diea3, player_diea4, player_diea5, player_diea6, player_diea7, player_diea8, player_diea9, player_diea10, player_diea11, player_dieb1, player_dieb2, player_dieb3, player_dieb4, player_dieb5, player_dieb6, player_dieb7, player_dieb8, player_dieb9, player_diec1, player_diec2, player_diec3, player_diec4, player_diec5, player_diec6, player_diec7, player_diec8, player_diec9, player_diec10, player_diec11, player_diec12, player_diec13, player_diec14, player_diec15, player_died1, player_died2, player_died3, player_died4, player_died5, player_died6, player_died7, player_died8, player_died9, player_diee1, player_diee2, player_diee3, player_diee4, player_diee5, player_diee6, player_diee7, player_diee8, player_diee9, player_die_ax1, player_die_ax2, player_die_ax3, player_die_ax4, player_die_ax5, player_die_ax6, player_die_ax7, player_die_ax8, player_die_ax9
local death_bubbles_spawn

---@param self entity
---@return nil
death_bubbles_spawn = function(self)
    local bubble
    if self.owner.waterlevel ~= 3 then return end
    bubble = quake.spawn()
    quake.set_model(bubble, "progs/s_bubble.spr")
    quake.set_origin(bubble, self.owner.origin + quake.vec3(0, 0, 24))
    bubble.movetype = MOVETYPE_NOCLIP
    bubble.solid = SOLID_NOT
    bubble.velocity = quake.vec3(0, 0, 15)
    bubble.nextthink = quake.time() + 0.5
    bubble.think = require("game.misc").bubble_bob
    bubble.classname = "bubble"
    bubble.frame = 0
    bubble.cnt = 0
    quake.set_size(bubble, quake.vec3(-8, -8, -8), quake.vec3(8, 8, 8))
    self.nextthink = quake.time() + 0.1
    self.think = death_bubbles_spawn
    self.air_finished = self.air_finished + 1
    if self.air_finished >= self.bubble_count then quake.remove(self) end
end

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
    local rs
    -- water death sounds
    if self.waterlevel == 3 then death_bubbles(self, 20); quake.sound(self, CHAN_VOICE, "player/h2odeath.wav", 1, ATTN_NONE); return end
    rs = math.floor(quake.random() * 4 + 1 + 0.5)
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
    local v
    -- check if the inflictor had velocity, e.g. like a rocket or explode box
    if g.damage_inflictor.velocity:length() > 0 then
        -- impact some of inflictor's velocity on the gibs
        v = g.damage_inflictor.velocity * 0.5
        v = v + (self.origin - g.damage_inflictor.origin):normalized() * 25
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
    throw_head(self, "progs/h_player.mdl", self.health)
    throw_gib(self, "progs/gib1.mdl", self.health)
    throw_gib(self, "progs/gib2.mdl", self.health)
    throw_gib(self, "progs/gib3.mdl", self.health)
    self.deadflag = DEAD_DEAD
    if g.damage_attacker.classname == "teledeath" then quake.sound(self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE); return end
    if g.damage_attacker.classname == "teledeath2" then quake.sound(self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE); return end
    if quake.random() < 0.5 then quake.sound(self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE)
    else quake.sound(self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE) end
end

---@param self entity
---@return nil
function M.player_die(self)
    local i
    self.items = self.items - (self.items & IT_INVISIBILITY)
    -- don't die as eyes
    self.invisible_finished = 0
    self.invincible_finished = 0
    self.super_damage_finished = 0
    self.radsuit_finished = 0
    -- don't use eyes
    self.modelindex = g.modelindex_player
    if g.deathmatch ~= 0 or g.coop ~= 0 then require("game.items").drop_backpack(self) end
    self.weaponmodel = ""
    self.view_ofs = quake.vec3(0, 0, -8)
    self.deadflag = DEAD_DYING
    self.solid = SOLID_NOT
    self.flags = self.flags - (self.flags & FL_ONGROUND)
    self.movetype = MOVETYPE_TOSS
    if self.velocity.z < 10 then self.velocity = quake.vec3(self.velocity.x, self.velocity.y, self.velocity.z + quake.random() * 300) end
    if self.health < -40 then gib_player(self); return end
    death_sound(self)
    self.angles = quake.vec3(0, self.angles.y, 0)
    if self.weapon == IT_AXE then player_die_ax1(self); return end
    i = quake.cvar("temp1")
    if i == 0 then i = 1 + math.floor(quake.random() * 6) end
    if i == 1 then player_diea1(self)
    elseif i == 2 then player_dieb1(self)
    elseif i == 3 then player_diec1(self)
    elseif i == 4 then player_died1(self)
    else player_diee1(self) end
end

---@param self entity
---@return nil
function M.set_suicide_frame(self)
    -- used by kill command and disconnect command
    if self.model ~= "progs/player.mdl" then return end -- already gibbed
    self.frame = "deatha11"
    self.solid = SOLID_NOT
    self.movetype = MOVETYPE_TOSS
    self.deadflag = DEAD_DEAD
    self.nextthink = -1
end

player_diea1 = animation.frame("deatha1", function() return player_diea2 end)
player_diea2 = animation.frame("deatha2", function() return player_diea3 end)
player_diea3 = animation.frame("deatha3", function() return player_diea4 end)
player_diea4 = animation.frame("deatha4", function() return player_diea5 end)
player_diea5 = animation.frame("deatha5", function() return player_diea6 end)
player_diea6 = animation.frame("deatha6", function() return player_diea7 end)
player_diea7 = animation.frame("deatha7", function() return player_diea8 end)
player_diea8 = animation.frame("deatha8", function() return player_diea9 end)
player_diea9 = animation.frame("deatha9", function() return player_diea10 end)
player_diea10 = animation.frame("deatha10", function() return player_diea11 end)
player_diea11 = animation.frame("deatha11", function() return player_diea11 end, player_dead)

player_dieb1 = animation.frame("deathb1", function() return player_dieb2 end)
player_dieb2 = animation.frame("deathb2", function() return player_dieb3 end)
player_dieb3 = animation.frame("deathb3", function() return player_dieb4 end)
player_dieb4 = animation.frame("deathb4", function() return player_dieb5 end)
player_dieb5 = animation.frame("deathb5", function() return player_dieb6 end)
player_dieb6 = animation.frame("deathb6", function() return player_dieb7 end)
player_dieb7 = animation.frame("deathb7", function() return player_dieb8 end)
player_dieb8 = animation.frame("deathb8", function() return player_dieb9 end)
player_dieb9 = animation.frame("deathb9", function() return player_dieb9 end, player_dead)

player_diec1 = animation.frame("deathc1", function() return player_diec2 end)
player_diec2 = animation.frame("deathc2", function() return player_diec3 end)
player_diec3 = animation.frame("deathc3", function() return player_diec4 end)
player_diec4 = animation.frame("deathc4", function() return player_diec5 end)
player_diec5 = animation.frame("deathc5", function() return player_diec6 end)
player_diec6 = animation.frame("deathc6", function() return player_diec7 end)
player_diec7 = animation.frame("deathc7", function() return player_diec8 end)
player_diec8 = animation.frame("deathc8", function() return player_diec9 end)
player_diec9 = animation.frame("deathc9", function() return player_diec10 end)
player_diec10 = animation.frame("deathc10", function() return player_diec11 end)
player_diec11 = animation.frame("deathc11", function() return player_diec12 end)
player_diec12 = animation.frame("deathc12", function() return player_diec13 end)
player_diec13 = animation.frame("deathc13", function() return player_diec14 end)
player_diec14 = animation.frame("deathc14", function() return player_diec15 end)
player_diec15 = animation.frame("deathc15", function() return player_diec15 end, player_dead)

player_died1 = animation.frame("deathd1", function() return player_died2 end)
player_died2 = animation.frame("deathd2", function() return player_died3 end)
player_died3 = animation.frame("deathd3", function() return player_died4 end)
player_died4 = animation.frame("deathd4", function() return player_died5 end)
player_died5 = animation.frame("deathd5", function() return player_died6 end)
player_died6 = animation.frame("deathd6", function() return player_died7 end)
player_died7 = animation.frame("deathd7", function() return player_died8 end)
player_died8 = animation.frame("deathd8", function() return player_died9 end)
player_died9 = animation.frame("deathd9", function() return player_died9 end, player_dead)

player_diee1 = animation.frame("deathe1", function() return player_diee2 end)
player_diee2 = animation.frame("deathe2", function() return player_diee3 end)
player_diee3 = animation.frame("deathe3", function() return player_diee4 end)
player_diee4 = animation.frame("deathe4", function() return player_diee5 end)
player_diee5 = animation.frame("deathe5", function() return player_diee6 end)
player_diee6 = animation.frame("deathe6", function() return player_diee7 end)
player_diee7 = animation.frame("deathe7", function() return player_diee8 end)
player_diee8 = animation.frame("deathe8", function() return player_diee9 end)
player_diee9 = animation.frame("deathe9", function() return player_diee9 end, player_dead)

player_die_ax1 = animation.frame("axdeth1", function() return player_die_ax2 end)
player_die_ax2 = animation.frame("axdeth2", function() return player_die_ax3 end)
player_die_ax3 = animation.frame("axdeth3", function() return player_die_ax4 end)
player_die_ax4 = animation.frame("axdeth4", function() return player_die_ax5 end)
player_die_ax5 = animation.frame("axdeth5", function() return player_die_ax6 end)
player_die_ax6 = animation.frame("axdeth6", function() return player_die_ax7 end)
player_die_ax7 = animation.frame("axdeth7", function() return player_die_ax8 end)
player_die_ax8 = animation.frame("axdeth8", function() return player_die_ax9 end)
player_die_ax9 = animation.frame("axdeth9", function() return player_die_ax9 end, player_dead)

M.player_stand1 = player_stand1
M.player_run = player_run
M.player_shot1 = player_shot1
M.player_axe1 = player_axe1
M.player_axeb1 = player_axeb1
M.player_axec1 = player_axec1
M.player_axed1 = player_axed1
M.player_nail1 = player_nail1
M.player_light1 = player_light1
M.player_rocket1 = player_rocket1

return M
